import 'package:flutter/material.dart';
import '../../application/app_controller.dart';
import '../../domain/career.dart';
import '../../domain/insights.dart';
import '../widgets/common.dart';
import 'direction_screens.dart';

class ReviewScreen extends StatefulWidget {
  final AppController app;
  const ReviewScreen(this.app, {super.key});
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late DateTime week;
  final reflection = TextEditingController(), next = TextEditingController();
  bool dirty = false, saving = false;
  String? message;
  @override
  void initState() {
    super.initState();
    week = weekStart(DateTime.now());
    load();
  }

  void load() {
    final review = widget.app.workspace.reviews
        .where((r) => r.id == dateField(week))
        .firstOrNull;
    reflection.text = review?.text('reflection') ?? '';
    next.text = review?.text('next_action') ?? '';
    dirty = false;
    message = null;
  }

  @override
  void dispose() {
    reflection.dispose();
    next.dispose();
    super.dispose();
  }

  Future<void> shift(int days) async {
    if (dirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard unsaved reflection?'),
          content: const Text(
            'Save this week before switching, or discard the changes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep editing'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (discard != true) return;
    }
    setState(() {
      week = DateTime(week.year, week.month, week.day + days);
      load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.app.workspace,
        m = WeeklyMetrics.calculate(widget.app.workspace, week);
    final previous = WeeklyMetrics.calculate(
      w,
      DateTime(week.year, week.month, week.day - 7),
    );
    final end = weekEnd(week), now = DateTime.now();
    final asOf = end.isAfter(now) ? now : end;
    final historical = end.isBefore(now);
    final lessons = w.knowledge.where(
      (k) =>
          within(k.createdAt, week, end) &&
          ['Learning', 'Lesson Learned', 'Decision'].contains(k.text('type')),
    );
    final mission = w.activeMission;
    final prioritySuggestions = mission == null
        ? const <PrioritySuggestion>[]
        : widget.app.intelligenceProvider.recommendNextWeek(w, mission.id);
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const PageHeading(
          'Weekly review',
          'Look at the evidence. Choose what happens next.',
        ),
        Row(
          children: [
            IconButton(
              tooltip: 'Previous week',
              onPressed: saving ? null : () => shift(-7),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                '${dayLabel(week)} – ${dayLabel(end.subtract(const Duration(days: 1)))}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: 'Next week',
              onPressed: weekStart(now).isAfter(week) && !saving
                  ? () => shift(7)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Panel(
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(),
              2: FlexColumnWidth(),
            },
            children: [
              _row('MEASURE', 'THIS WEEK', 'PREVIOUS'),
              _row(
                'Sessions completed',
                '${m.completed} / ${m.planned}',
                '${previous.completed} / ${previous.planned}',
              ),
              _row(
                'Completion',
                m.completion == null
                    ? '—'
                    : '${(m.completion! * 100).round()}%',
                previous.completion == null
                    ? '—'
                    : '${(previous.completion! * 100).round()}%',
              ),
              _row(
                'Planned time',
                '${m.scheduledMinutes} min',
                '${previous.scheduledMinutes} min',
              ),
              _row('Awaiting result', '${m.pending}', '${previous.pending}'),
              _row(
                'Outputs produced',
                '${m.outputCount}',
                '${previous.outputCount}',
              ),
              _row(
                'Goals with confirmed sessions',
                '${m.goalIds.length}',
                '${previous.goalIds.length}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Section(
          'Goal attention',
          child: Panel(
            child: Column(
              children: w.goals.isEmpty
                  ? [
                      const Text(
                        'Create a goal to connect scheduled work to a direction.',
                      ),
                    ]
                  : w.goals
                        .map(
                          (g) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(g.title),
                            subtitle: Text(
                              m.goalIds.contains(g.id)
                                  ? 'Received attention'
                                  : 'No recorded session this week',
                            ),
                            trailing: Icon(
                              m.goalIds.contains(g.id)
                                  ? Icons.check_circle_outline
                                  : Icons.remove_circle_outline,
                            ),
                            onTap: () => openGoal(context, widget.app, g),
                          ),
                        )
                        .toList(),
            ),
          ),
        ),
        Section(
          'Projects with outputs',
          child: Text(
            m.outputProjectIds.isEmpty
                ? 'No project outputs recorded this week.'
                : m.outputProjectIds
                      .map((id) => w.project(id)?.title ?? '')
                      .join(' · '),
          ),
        ),
        Section(
          'Activity without output',
          child: Text(
            m.activityProjectIds.difference(m.outputProjectIds).isEmpty
                ? 'No active projects missing outputs this week.'
                : m.activityProjectIds
                      .difference(m.outputProjectIds)
                      .map((id) => w.project(id)?.title ?? '')
                      .join(' · '),
          ),
        ),
        if (!historical)
          Section(
            'Projects neglected · 21+ days',
            child: Text(
              inactiveProjects(w, asOf).isEmpty
                  ? 'No active project has crossed the inactivity threshold.'
                  : inactiveProjects(w, asOf).map((p) => p.title).join(' · '),
            ),
          ),
        if (!historical)
          Section(
            'Generated next-week priorities',
            trailing: prioritySuggestions.isEmpty || mission == null
                ? const Text('Local rules · evidence shown')
                : FilledButton.tonalIcon(
                    onPressed: () => attempt(context, () async {
                      await widget.app.createWeeklyPlanPreview(mission.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Plan preview created. Review and apply it in Strategy.',
                            ),
                          ),
                        );
                      }
                    }),
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text('Create plan preview'),
                  ),
            child: prioritySuggestions.isEmpty
                ? const Text(
                    'Add verified readiness, target-job descriptions or interview priorities to generate evidence-based suggestions.',
                  )
                : Column(
                    children: prioritySuggestions
                        .map(
                          (suggestion) => Card(
                            child: ListTile(
                              title: Text(suggestion.title),
                              subtitle: Text(
                                '${suggestion.reason}\nConfidence ${(suggestion.confidence * 100).round()}%',
                              ),
                              trailing: TextButton(
                                onPressed: () {
                                  final line =
                                      '${suggestion.title} — ${suggestion.reason}';
                                  setState(() {
                                    next.text = next.text.trim().isEmpty
                                        ? line
                                        : '${next.text.trim()}\n$line';
                                    dirty = true;
                                  });
                                },
                                child: const Text('Add to intention'),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        Section(
          'Important lessons',
          child: Text(
            lessons.isEmpty
                ? 'No distilled learning recorded in this week yet.'
                : lessons
                      .map((k) => '• ${k.title}\n${k.text('content')}')
                      .join('\n\n'),
          ),
        ),
        if (!historical)
          Section(
            'Recommended next actions · current',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.app.insights
                  .map(
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(i.message),
                    ),
                  )
                  .toList(),
            ),
          ),
        Section(
          'Your reflection',
          child: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: reflection,
                  minLines: 4,
                  maxLines: 8,
                  onChanged: (_) => dirty = true,
                  decoration: const InputDecoration(
                    labelText: 'What mattered? What should change?',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: next,
                  minLines: 2,
                  maxLines: 5,
                  onChanged: (_) => dirty = true,
                  decoration: const InputDecoration(
                    labelText: 'Next week’s intention',
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: saving ? null : save,
                    child: Text(saving ? 'Saving…' : 'Save weekly review'),
                  ),
                ),
                if (message != null) Text(message!),
              ],
            ),
          ),
        ),
        const Text(
          'Weeks start Monday. Planned time is calendar allocation only. Completion requires status: done plus a concrete Output in the Obsidian session note; overdue sessions awaiting a result are shown separately.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  TableRow _row(String label, String current, String previous) => TableRow(
    children: [label, current, previous]
        .map(
          (s) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Text(s),
          ),
        )
        .toList(),
  );
  Future<void> save() async {
    setState(() => saving = true);
    try {
      await widget.app.save('weekly_reviews', {
        'id': dateField(week),
        'reflection': reflection.text,
        'next_action': next.text,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
      if (mounted) {
        setState(() {
          dirty = false;
          message = 'Review saved locally.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => message = 'Could not save: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
