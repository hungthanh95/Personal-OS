import 'package:flutter/material.dart';

import '../../application/app_controller.dart';
import '../../domain/insights.dart';
import '../../domain/models.dart';
import '../widgets/common.dart';
import 'record_editor.dart';
import 'schedule_screen.dart';
import 'session_screen.dart';

class TodayOverviewScreen extends StatelessWidget {
  final AppController app;
  const TodayOverviewScreen(this.app, {super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final sessions = app.workspace.today(now);
    final actionable = sessions
        .where((session) => !session.status.terminal)
        .toList();
    final primary = actionable.firstOrNull;
    final later = sessions
        .where((session) => session.id != primary?.id)
        .toList();
    final metrics = WeeklyMetrics.calculate(app.workspace, now);
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        PageHeading(
          'Today',
          '${dayLabel(now)} · Start the most important work without friction.',
          action: OutlinedButton.icon(
            onPressed: () => editRecord(context, app, 'sessions'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Plan session'),
          ),
        ),
        const SectionLabel('Primary focus'),
        const SizedBox(height: 12),
        if (primary == null)
          EmptyState(
            'Make room for meaningful work',
            'Plan one focused session and define what you want to produce.',
            'Plan a session',
            () => editRecord(context, app, 'sessions'),
            icon: Icons.play_circle_outline,
          )
        else
          _PrimaryFocus(app, primary),
        if (later.isNotEmpty) ...[
          const SizedBox(height: 28),
          const SectionLabel('Later today'),
          const SizedBox(height: 12),
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Column(
              children: [
                for (final session in later)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: SizedBox(
                      width: 52,
                      child: Text(
                        timeLabel(session.plannedStart),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    title: Text(session.title),
                    subtitle: Text(
                      '${session.plannedMinutes} min · ${session.status.label}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => openSession(context, app, session),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 28),
        const SectionLabel('This week'),
        const SizedBox(height: 12),
        Panel(
          child: LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 24,
              runSpacing: 18,
              children: [
                _weekStat(
                  '${metrics.completed} / ${metrics.planned}',
                  'sessions',
                ),
                _weekStat(durationLabel(metrics.focusedSeconds), 'focused'),
                _weekStat('${metrics.outputCount}', 'evidence items'),
                _weekStat('${metrics.goalIds.length}', 'goals touched'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => ScheduleScreen(app)),
            ),
            icon: const Icon(Icons.event_repeat_outlined, size: 17),
            label: const Text('Recurring plan'),
          ),
        ),
      ],
    );
  }

  Widget _weekStat(String value, String label) => SizedBox(
    width: 150,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
        ),
        Text(label),
      ],
    ),
  );
}

class _PrimaryFocus extends StatelessWidget {
  final AppController app;
  final Session session;
  const _PrimaryFocus(this.app, this.session);
  @override
  Widget build(BuildContext context) {
    final workspace = app.workspace;
    final goal = workspace.sessionGoal(session);
    final project = workspace.project(session.projectId);
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .18),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0b17345c),
            blurRadius: 22,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StatusPill(
                label: session.status.label,
                color: const Color(0xff3978e6),
              ),
              const Spacer(),
              Text(
                '${timeLabel(session.plannedStart)}–${timeLabel(session.plannedStart.add(Duration(minutes: session.plannedMinutes)))}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            session.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 18),
          const SectionLabel('Why'),
          const SizedBox(height: 7),
          Text(
            [project?.title, goal?.title].whereType<String>().join(' → '),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          const SectionLabel('Target'),
          const SizedBox(height: 7),
          Text(
            session.text('target').isEmpty
                ? 'Complete one concrete, recordable result.'
                : session.text('target'),
            style: const TextStyle(fontSize: 16, height: 1.45),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => openSession(context, app, session),
                icon: Icon(
                  session.status == SessionStatus.active
                      ? Icons.open_in_full
                      : Icons.play_arrow,
                ),
                label: Text(
                  session.status == SessionStatus.active
                      ? 'Return to focus'
                      : 'Start session',
                ),
              ),
              TextButton(
                onPressed: () => rescheduleDialog(context, app, session),
                child: const Text('Reschedule'),
              ),
              PopupMenuButton<String>(
                tooltip: 'More session actions',
                onSelected: (value) {
                  if (value == 'skip') {
                    reviewSession(
                      context,
                      app,
                      session,
                      status: SessionStatus.skipped,
                    );
                  }
                  if (value == 'edit') {
                    editRecord(context, app, 'sessions', entity: session);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit plan')),
                  PopupMenuItem(value: 'skip', child: Text('Skip session')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
