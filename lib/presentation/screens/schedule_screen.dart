import 'package:flutter/material.dart';

import '../../application/app_controller.dart';
import '../../domain/models.dart';
import '../widgets/common.dart';
import 'strategy_screens.dart';

class ScheduleScreen extends StatelessWidget {
  final AppController app;

  const ScheduleScreen(this.app, {super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Recurring schedule')),
    body: ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final templates = app.workspace.records('session_templates');
        final schedules = app.workspace.records('recurring_schedules');
        return ListView(
          padding: const EdgeInsets.all(28),
          children: [
            PageHeading(
              'Weekly operating rhythm',
              'Templates define the work. Schedules create planned sessions for selected weekdays.',
              action: FilledButton.icon(
                onPressed: templates.isEmpty
                    ? null
                    : () => editStrategyRecord(
                        context,
                        app,
                        'recurring_schedules',
                        initial: {'template_id': templates.first.id},
                      ),
                icon: const Icon(Icons.repeat),
                label: const Text('New schedule'),
              ),
            ),
            Section(
              'Session templates',
              trailing: TextButton.icon(
                onPressed: () =>
                    editStrategyRecord(context, app, 'session_templates'),
                icon: const Icon(Icons.add),
                label: const Text('New template'),
              ),
              child: templates.isEmpty
                  ? const Panel(
                      child: Text(
                        'Create a reusable session template, then attach a weekly schedule.',
                      ),
                    )
                  : Column(
                      children: templates
                          .map(
                            (template) => Card(
                              child: ListTile(
                                leading: const Icon(Icons.copy_outlined),
                                title: Text(template.title),
                                subtitle: Text(
                                  '${template.number('planned_minutes', 60)} min · P${template.number('priority', 2)}',
                                ),
                                trailing: const Icon(Icons.edit_outlined),
                                onTap: () => editStrategyRecord(
                                  context,
                                  app,
                                  'session_templates',
                                  record: template,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
            Section(
              'Recurring schedules',
              trailing: OutlinedButton.icon(
                onPressed: schedules.isEmpty ? null : () => _generate(context),
                icon: const Icon(Icons.event_repeat_outlined),
                label: const Text('Generate 12 weeks'),
              ),
              child: schedules.isEmpty
                  ? const Panel(
                      child: Text(
                        'No recurrence yet. Weekdays use ISO numbers: Monday 1 through Sunday 7.',
                      ),
                    )
                  : Column(
                      children: schedules
                          .map((schedule) => _scheduleTile(context, schedule))
                          .toList(),
                    ),
            ),
            const Panel(
              child: Text(
                'The app keeps the next 21 days planned automatically. Generation is idempotent. Editing or pausing a recurrence affects newly generated occurrences; existing occurrence notes remain user-owned history.',
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _scheduleTile(BuildContext context, StrategyRecord schedule) {
    final template = app.workspace.record(
      'session_templates',
      schedule.ref('template_id'),
    );
    final streak = app.workspace.sessionStreak(schedule.id, DateTime.now());
    return Card(
      child: ListTile(
        leading: Icon(
          schedule.number('enabled', 1) == 1
              ? Icons.repeat
              : Icons.pause_circle_outline,
        ),
        title: Text(schedule.title),
        subtitle: Text(
          '${template?.title ?? 'Missing template'} · days ${schedule.text('weekdays')} at ${schedule.text('local_time')} · ${schedule.number('enabled', 1) == 1 ? 'Enabled' : 'Paused'}\nStreak ${streak.confirmed}${streak.pending == 0 ? '' : ' · ${streak.pending} awaiting result'}',
        ),
        trailing: const Icon(Icons.edit_outlined),
        onTap: () => editStrategyRecord(
          context,
          app,
          'recurring_schedules',
          record: schedule,
        ),
      ),
    );
  }

  Future<void> _generate(BuildContext context) async {
    try {
      final count = await app.generateRecurringSessions(
        DateTime.now().add(const Duration(days: 84)),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count new planned sessions generated.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }
}
