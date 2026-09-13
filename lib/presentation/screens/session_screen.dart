import 'dart:async';
import 'package:flutter/material.dart';
import '../../application/app_controller.dart';
import '../../domain/models.dart';
import '../widgets/common.dart';
import 'record_editor.dart';
import 'library_screen.dart';

Future<void> openSession(
  BuildContext context,
  AppController app,
  Session session,
) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (_) => SessionScreen(app: app, id: session.id),
  ),
);
Future<void> reviewSession(
  BuildContext context,
  AppController app,
  Session session, {
  SessionStatus status = SessionStatus.done,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) =>
      SessionReviewDialog(app: app, session: session, initialStatus: status),
);

class SessionScreen extends StatefulWidget {
  final AppController app;
  final String id;
  const SessionScreen({required this.app, required this.id, super.key});
  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  Timer? timer;
  List<KnowledgeSearchHit> relatedKnowledge = const [];
  bool loadingKnowledge = true;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    loadRelatedKnowledge();
  }

  Future<void> loadRelatedKnowledge() async {
    final session = widget.app.workspace.sessions
        .where((item) => item.id == widget.id)
        .firstOrNull;
    if (session == null) return;
    try {
      final results = await widget.app.searchKnowledge(
        '${session.title} ${session.text('input')} ${session.text('target')}',
      );
      if (mounted) {
        setState(() {
          relatedKnowledge = results.take(5).toList();
          loadingKnowledge = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loadingKnowledge = false);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.app,
    builder: (context, _) {
      final w = widget.app.workspace;
      final s = w.sessions.where((s) => s.id == widget.id).firstOrNull;
      if (s == null) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(
            child: Text('This session is no longer available.'),
          ),
        );
      }
      final p = w.project(s.projectId), g = w.sessionGoal(s);
      final why =
          '${w.whyPath(s)}\n\n${s.text('why').isNotEmpty ? s.text('why') : g?.text('why') ?? 'Define why this work matters when planning your next session.'}';
      return Scaffold(
        appBar: AppBar(
          title: const Text('Focus session'),
          actions: [
            if (s.status == SessionStatus.planned)
              TextButton.icon(
                onPressed: () =>
                    editRecord(context, widget.app, 'sessions', entity: s),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit plan'),
              ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: ListView(
              padding: const EdgeInsets.all(32),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Tag(s.status.label),
                    if (p != null) Tag(p.title),
                    if (g != null) Tag(g.title),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  s.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  '${dayLabel(s.plannedStart)} · ${timeLabel(s.plannedStart)} · ${s.plannedMinutes} min planned',
                ),
                const SizedBox(height: 32),
                Section(
                  'WHY',
                  child: Text(
                    why,
                    style: const TextStyle(fontSize: 17, height: 1.6),
                  ),
                ),
                Section(
                  'INPUT',
                  child: SelectableText(
                    s.text('input').isEmpty
                        ? 'No reference material attached.'
                        : s.text('input'),
                  ),
                ),
                Section(
                  'RELATED KNOWLEDGE',
                  child: Panel(
                    child: loadingKnowledge
                        ? const Text('Searching local Knowledge…')
                        : relatedKnowledge.isEmpty
                        ? const Text(
                            'No related local Knowledge found for this session objective.',
                          )
                        : Column(
                            children: [
                              for (final hit in relatedKnowledge)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.menu_book_outlined),
                                  title: Text(hit.item.title),
                                  subtitle: Text(
                                    '${hit.snippet}\n${hit.relationship}${hit.sectionTitle == null ? '' : ' · ${hit.sectionTitle} @ ${hit.startOffset ?? 0}'}',
                                  ),
                                  onTap: () => openEvidence(
                                    context,
                                    widget.app,
                                    hit.item,
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
                Section(
                  "TODAY’S TARGET",
                  child: Panel(
                    child: Text(
                      s.text('target').isEmpty
                          ? 'Produce one concrete result worth recording.'
                          : s.text('target'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                if (s.status == SessionStatus.active) ...[
                  Text(
                    durationLabel(s.elapsedSeconds(DateTime.now())),
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const Text(
                    'Elapsed time · continues while the app is closed',
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => reviewSession(context, widget.app, s),
                    icon: const Icon(Icons.check),
                    label: const Text('Finish & record result'),
                  ),
                ] else if (!s.status.terminal)
                  FilledButton.icon(
                    onPressed: () =>
                        attempt(context, () => widget.app.start(s)),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      s.status == SessionStatus.inProgress
                          ? 'Resume session'
                          : s.status == SessionStatus.blocked
                          ? 'Resolve blocker & resume'
                          : 'Start session',
                    ),
                  ),
                if (s.status.terminal ||
                    s.status == SessionStatus.inProgress ||
                    s.status == SessionStatus.blocked) ...[
                  const SizedBox(height: 24),
                  Section(
                    'RECORDED RESULT',
                    child: Text(
                      '${s.status.label} · ${durationLabel(s.actualSeconds)} recorded',
                    ),
                  ),
                  if (s.text('next_action').isNotEmpty)
                    Section('NEXT ACTION', child: Text(s.text('next_action'))),
                  if (s.status == SessionStatus.blocked &&
                      s.blockedReason.isNotEmpty)
                    Section('BLOCKER', child: Text(s.blockedReason)),
                  ...w.outputs
                      .where((o) => o.sessionId == s.id)
                      .map(
                        (o) => Section(
                          o.title,
                          child: SelectableText(o.text('description')),
                        ),
                      ),
                  ...w.knowledge
                      .where((k) => k.ref('session_id') == s.id)
                      .map(
                        (k) => Section(
                          'LEARNING',
                          child: SelectableText(k.text('content')),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

class SessionReviewDialog extends StatefulWidget {
  final AppController app;
  final Session session;
  final SessionStatus initialStatus;
  const SessionReviewDialog({
    required this.app,
    required this.session,
    required this.initialStatus,
    super.key,
  });
  @override
  State<SessionReviewDialog> createState() => _SessionReviewDialogState();
}

class _SessionReviewDialogState extends State<SessionReviewDialog> {
  final output = TextEditingController(),
      learning = TextEditingController(),
      next = TextEditingController(),
      link = TextEditingController(),
      minutes = TextEditingController();
  late SessionStatus status;
  bool saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    status = widget.initialStatus;
    next.text = widget.session.text('next_action');
  }

  @override
  void dispose() {
    for (final c in [output, learning, next, link, minutes]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget field(TextEditingController c, String label, {int lines = 3}) =>
      Padding(
        padding: const EdgeInsets.only(top: 16),
        child: TextField(
          controller: c,
          minLines: lines,
          maxLines: lines + 2,
          decoration: InputDecoration(labelText: label),
        ),
      );
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('What did this session produce?'),
    content: SizedBox(
      width: 590,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.session.title),
            const SizedBox(height: 20),
            DropdownButtonFormField<SessionStatus>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'Status'),
              items:
                  [
                        SessionStatus.done,
                        SessionStatus.inProgress,
                        SessionStatus.blocked,
                        SessionStatus.skipped,
                        SessionStatus.cancelled,
                      ]
                      .where((s) => widget.session.status.canTransitionTo(s))
                      .map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                      )
                      .toList(),
              onChanged: saving ? null : (v) => setState(() => status = v!),
            ),
            field(output, 'Actual output · evidence of useful work'),
            field(learning, 'What did I learn?'),
            field(next, 'Next action'),
            if (status == SessionStatus.inProgress ||
                status == SessionStatus.blocked)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Record the blocker or a concrete next action to make restarting easier.',
                ),
              ),
            field(link, 'Output link / local file path', lines: 1),
            field(
              minutes,
              'Correct total focused minutes (optional)',
              lines: 1,
            ),
            const SizedBox(height: 8),
            const Text(
              'Leave duration blank to use the timer. Manual corrections are attributed to this review date.',
              style: TextStyle(fontSize: 12),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('Back'),
      ),
      FilledButton(
        onPressed: saving ? null : save,
        child: Text(saving ? 'Saving…' : 'Save review'),
      ),
    ],
  );
  Future<void> save() async {
    final duration = minutes.text.trim().isEmpty
        ? null
        : double.tryParse(minutes.text);
    if (minutes.text.trim().isNotEmpty &&
        (duration == null || !duration.isFinite || duration < 0)) {
      setState(() => error = 'Enter a non-negative number of minutes.');
      return;
    }
    if (status == SessionStatus.blocked && next.text.trim().isEmpty) {
      setState(() => error = 'Describe the blocker in Next action.');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.app.review(
        widget.session,
        status,
        output: output.text,
        learning: learning.text,
        nextAction: next.text,
        link: link.text,
        seconds: duration == null ? null : (duration * 60).round(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          saving = false;
          error = '$e';
        });
      }
    }
  }
}

Future<void> rescheduleDialog(
  BuildContext context,
  AppController app,
  Session s,
) async {
  final day = await showDatePicker(
    context: context,
    initialDate: s.plannedStart,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );
  if (day == null || !context.mounted) return;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(s.plannedStart),
  );
  if (time == null || !context.mounted) return;
  await attempt(
    context,
    () => app.reschedule(
      s,
      DateTime(day.year, day.month, day.day, time.hour, time.minute),
      s.plannedMinutes,
    ),
  );
}
