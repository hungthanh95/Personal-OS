import 'package:flutter/material.dart';

import '../../application/app_controller.dart';
import '../../domain/models.dart';
import '../widgets/common.dart';
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

class SessionScreen extends StatefulWidget {
  final AppController app;
  final String id;
  const SessionScreen({required this.app, required this.id, super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  List<KnowledgeSearchHit> relatedKnowledge = const [];
  bool loadingKnowledge = true;

  @override
  void initState() {
    super.initState();
    _loadRelatedKnowledge();
  }

  Future<void> _loadRelatedKnowledge() async {
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
          relatedKnowledge = results
              .where((hit) => hit.item.ref('session_id') != session.id)
              .take(5)
              .toList();
          loadingKnowledge = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loadingKnowledge = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.app,
    builder: (context, _) {
      final workspace = widget.app.workspace;
      final session = workspace.sessions
          .where((item) => item.id == widget.id)
          .firstOrNull;
      if (session == null) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(
            child: Text('This scheduled session is unavailable.'),
          ),
        );
      }
      final project = workspace.project(session.projectId);
      final goal = workspace.sessionGoal(session);
      final now = DateTime.now();
      return Scaffold(
        appBar: AppBar(title: const Text('Scheduled learning / work')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: ListView(
              padding: const EdgeInsets.all(32),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Tag(_stateLabel(session, now)),
                    if (project != null) Tag(project.title),
                    if (goal != null) Tag(goal.title),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  session.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  '${dayLabel(session.plannedStart)} · ${timeLabel(session.plannedStart)}–${timeLabel(session.plannedEnd)} · ${session.plannedMinutes} min planned',
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: () => attempt(
                        context,
                        () => widget.app.openSessionNote(session),
                      ),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open note'),
                    ),
                    OutlinedButton.icon(
                      onPressed: widget.app.reconciling
                          ? null
                          : () => attempt(context, () async {
                              final result = await widget.app
                                  .reconcileSessions();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Checked ${result.scanned} sessions · ${result.pending} awaiting result · ${result.errors} issues.',
                                    ),
                                  ),
                                );
                              }
                            }),
                      icon: const Icon(Icons.sync),
                      label: Text(
                        widget.app.reconciling ? 'Checking…' : 'Check result',
                      ),
                    ),
                    if (!session.status.terminal)
                      OutlinedButton.icon(
                        onPressed: () =>
                            rescheduleDialog(context, widget.app, session),
                        icon: const Icon(Icons.event_repeat_outlined),
                        label: const Text('Reschedule'),
                      ),
                    if (!session.status.terminal)
                      TextButton.icon(
                        onPressed: () => attempt(
                          context,
                          () => widget.app.setSessionDisposition(
                            session,
                            'skipped',
                          ),
                        ),
                        icon: const Icon(Icons.skip_next_outlined),
                        label: const Text('Skip'),
                      ),
                    if (!session.status.terminal)
                      TextButton.icon(
                        onPressed: () => attempt(
                          context,
                          () => widget.app.setSessionDisposition(
                            session,
                            'cancelled',
                          ),
                        ),
                        icon: const Icon(Icons.event_busy_outlined),
                        label: const Text('Cancel'),
                      ),
                  ],
                ),
                if (session.hasReconciliationError) ...[
                  const SizedBox(height: 20),
                  MaterialBanner(
                    content: Text(session.reconciliationError),
                    leading: const Icon(Icons.warning_amber_outlined),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            attempt(context, widget.app.reconcileSessions),
                        child: const Text('Check again'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 28),
                Section(
                  'HOW COMPLETION WORKS',
                  child: Panel(
                    child: Text(
                      session.status == SessionStatus.done
                          ? 'Confirmed from the Obsidian note: status is done and Output contains a result.'
                          : session.isAwaitingResult(now)
                          ? 'The scheduled time has ended. Add status: done and a concrete Output in the Obsidian note, then check again.'
                          : 'The app waits until ${timeLabel(session.plannedEnd)}, then checks the Obsidian note for status: done and a concrete Output. Planned time is never treated as time worked.',
                    ),
                  ),
                ),
                Section(
                  'WHY',
                  child: Text(
                    '${workspace.whyPath(session)}\n\n${session.text('why').isNotEmpty ? session.text('why') : goal?.text('why') ?? 'Define why this scheduled work matters.'}',
                    style: const TextStyle(fontSize: 17, height: 1.6),
                  ),
                ),
                Section(
                  'GOAL',
                  child: SelectableText(
                    session.text('target').isEmpty
                        ? 'Produce one concrete result worth recording.'
                        : session.text('target'),
                  ),
                ),
                Section(
                  'INPUT',
                  child: SelectableText(
                    session.text('input').isEmpty
                        ? 'No reference material attached.'
                        : session.text('input'),
                  ),
                ),
                if (session.outputMarkdown.isNotEmpty)
                  Section(
                    'OUTPUT FROM OBSIDIAN',
                    child: SelectableText(session.outputMarkdown),
                  ),
                if (session.learningMarkdown.isNotEmpty)
                  Section(
                    'LEARNING FROM OBSIDIAN',
                    child: SelectableText(session.learningMarkdown),
                  ),
                if (session.text('next_action').isNotEmpty)
                  Section(
                    'NEXT ACTION FROM OBSIDIAN',
                    child: SelectableText(session.text('next_action')),
                  ),
                Section(
                  'RELATED KNOWLEDGE',
                  child: Panel(
                    child: loadingKnowledge
                        ? const Text('Searching local Knowledge…')
                        : relatedKnowledge.isEmpty
                        ? const Text('No related Knowledge found.')
                        : Column(
                            children: [
                              for (final hit in relatedKnowledge)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.menu_book_outlined),
                                  title: Text(hit.item.title),
                                  subtitle: Text(hit.snippet),
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
                if (session.notePath.isNotEmpty)
                  Section(
                    'SOURCE NOTE',
                    child: SelectableText(session.notePath),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

String _stateLabel(Session session, DateTime now) {
  if (session.isMissingOutput) return 'Missing output';
  if (session.hasReconciliationError) return 'Needs attention';
  if (session.status == SessionStatus.done) return 'Completed from Obsidian';
  if (session.status == SessionStatus.skipped) return 'Skipped';
  if (session.status == SessionStatus.cancelled) return 'Cancelled';
  if (session.isAwaitingResult(now)) return 'Awaiting result';
  if (!now.isBefore(session.plannedStart) && now.isBefore(session.plannedEnd)) {
    return 'Scheduled now';
  }
  return 'Planned';
}

Future<void> rescheduleDialog(
  BuildContext context,
  AppController app,
  Session session,
) async {
  final day = await showDatePicker(
    context: context,
    initialDate: session.plannedStart,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );
  if (day == null || !context.mounted) return;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(session.plannedStart),
  );
  if (time == null || !context.mounted) return;
  await attempt(
    context,
    () => app.reschedule(
      session,
      DateTime(day.year, day.month, day.day, time.hour, time.minute),
      session.plannedMinutes,
    ),
  );
}
