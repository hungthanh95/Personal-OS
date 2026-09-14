import 'package:flutter/material.dart';
import '../../application/app_controller.dart';
import '../../domain/models.dart';
import '../../domain/insights.dart';
import '../widgets/common.dart';
import 'record_editor.dart';
import 'schedule_screen.dart';
import 'session_screen.dart';

class TodayScreen extends StatelessWidget {
  final AppController app;
  const TodayScreen(this.app, {super.key});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now(), w = app.workspace;
    final sessions = w.today(now), metrics = WeeklyMetrics.calculate(w, now);
    final focus = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Section(
          "Today's focus",
          trailing: Text(
            '${sessions.where((s) => !s.status.terminal).length} remaining',
          ),
          child: sessions.isEmpty
              ? EmptyState(
                  'Make room for meaningful work',
                  'Plan one session and define what you want to produce.',
                  'Plan a session',
                  () => editRecord(context, app, 'sessions'),
                )
              : Column(
                  children: [
                    for (final s in sessions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SessionTile(app, s),
                      ),
                  ],
                ),
        ),
        Section(
          'PERSONAL INSIGHT',
          child: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    const Text('A moment to step back'),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  app.insights.first.message,
                  style: const TextStyle(fontSize: 16, height: 1.6),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Rule-based · your schedule stays in your control',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    final contextPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Section(
          'CURRENT MISSION',
          child: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(w.activeMission?.title ?? 'No active mission'),
                const SizedBox(height: 12),
                Text(
                  w.activeMission?.text('success_criteria') ??
                      'Create your vision, strategy and mission to connect today to your direction.',
                ),
                if (w.activeMission != null) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: w.missionProgress(w.activeMission!.id),
                  ),
                  Text(
                    '${(w.missionProgress(w.activeMission!.id) * 100).round()}% outcome attainment',
                  ),
                  if (w.missionExecutionProgress(w.activeMission!.id)
                      case final execution?) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: execution),
                    Text('${(execution * 100).round()}% task execution'),
                  ],
                ],
              ],
            ),
          ),
        ),
        Section(
          'THIS WEEK',
          child: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${metrics.completed} / ${metrics.planned}',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text('planned sessions completed'),
                const Divider(),
                _stat('Planned time', '${metrics.scheduledMinutes} min'),
                _stat('Awaiting result', '${metrics.pending}'),
                _stat('Outputs produced', '${metrics.outputCount}'),
                _stat(
                  'Goals with confirmed sessions',
                  '${metrics.goalIds.length}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Since ${dayLabel(metrics.start)}',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        PageHeading(
          'Good ${now.hour < 12
              ? 'morning'
              : now.hour < 18
              ? 'afternoon'
              : 'evening'}${w.settings['name']?.isNotEmpty == true ? ', ${w.settings['name']}' : ''}',
          '${dayLabel(now)} · Turn intention into evidence.',
          action: Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => ScheduleScreen(app)),
                ),
                icon: const Icon(Icons.event_repeat_outlined, size: 18),
                label: const Text('Recurring plan'),
              ),
              FilledButton.icon(
                onPressed: () => editRecord(context, app, 'sessions'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Plan session'),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, c) => c.maxWidth >= 900
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: focus),
                    const SizedBox(width: 28),
                    SizedBox(width: 280, child: contextPanel),
                  ],
                )
              : Column(children: [focus, contextPanel]),
        ),
      ],
    );
  }

  Widget _stat(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class SessionTile extends StatelessWidget {
  final AppController app;
  final Session session;
  const SessionTile(this.app, this.session, {super.key});
  @override
  Widget build(BuildContext context) {
    final s = session, w = app.workspace;
    final p = w.project(s.projectId), g = w.sessionGoal(s);
    final overdue =
        !s.status.terminal &&
        s.plannedStart.isBefore(DateTime.now()) &&
        s.status != SessionStatus.active;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => openSession(context, app, s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${timeLabel(s.plannedStart)}–${timeLabel(s.plannedStart.add(Duration(minutes: s.plannedMinutes)))} · ${s.plannedMinutes} min${overdue ? ' · Overdue ${dayLabel(s.plannedStart)}' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!s.status.terminal)
                PopupMenuButton<String>(
                  tooltip: 'Session actions',
                  onSelected: (value) {
                    switch (value) {
                      case 'check':
                        attempt(context, app.reconcileSessions);
                      case 'skip':
                        attempt(
                          context,
                          () => app.setSessionDisposition(s, 'skipped'),
                        );
                      case 'reschedule':
                        rescheduleDialog(context, app, s);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'check',
                      child: Text('Check Obsidian result'),
                    ),
                    const PopupMenuItem(value: 'skip', child: Text('Skip')),
                    if (s.status != SessionStatus.active)
                      const PopupMenuItem(
                        value: 'reschedule',
                        child: Text('Reschedule'),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${g?.title ?? 'No goal linked'}${p != null ? '  /  ${p.title}' : ''}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Tag(s.status.label),
              Tag('P${s.priority}'),
              OutlinedButton.icon(
                onPressed: () => attempt(context, () => app.openSessionNote(s)),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Open note'),
              ),
              TextButton(
                onPressed: () => openSession(context, app, s),
                child: const Text('View details'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
