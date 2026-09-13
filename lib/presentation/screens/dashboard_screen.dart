import 'package:flutter/material.dart';

import '../../application/app_controller.dart';
import '../../domain/models.dart';
import '../dashboard_data.dart';
import '../widgets/common.dart';
import 'session_screen.dart';

class DashboardScreen extends StatelessWidget {
  final AppController app;
  final VoidCallback onToday;
  final VoidCallback onMission;
  final VoidCallback onProjects;
  final VoidCallback onKnowledge;

  const DashboardScreen(
    this.app, {
    required this.onToday,
    required this.onMission,
    required this.onProjects,
    required this.onKnowledge,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final workspace = app.workspace;
    final mission = workspace.activeMission;
    final metrics = mission == null
        ? null
        : MissionWeeklySummary.calculate(workspace, mission, now);
    final skills =
        mission == null
              ? <StrategyRecord>[]
              : workspace
                    .records('skills')
                    .where((skill) => skill.ref('mission_id') == mission.id)
                    .toList()
          ..sort(
            (a, b) =>
                workspace.readiness(a.id).compareTo(workspace.readiness(b.id)),
          );
    final today = workspace.today(now);
    final priorities = dashboardPriorities(workspace, mission, now);
    final wins = dashboardWins(workspace, mission);

    return LayoutBuilder(
      builder: (context, constraints) {
        final showRail = constraints.maxWidth >= 1080;
        final page = _mainColumn(
          context,
          mission,
          skills.take(5).toList(),
          metrics,
        );
        final rail = _rightRail(
          context,
          today,
          priorities.take(4).toList(),
          wins.take(3).toList(),
        );
        return ListView(
          padding: EdgeInsets.fromLTRB(
            constraints.maxWidth < 700 ? 18 : 26,
            24,
            constraints.maxWidth < 700 ? 18 : 26,
            36,
          ),
          children: [
            _dashboardHeading(context, now),
            if (showRail)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: page),
                  const SizedBox(width: 18),
                  SizedBox(width: 320, child: rail),
                ],
              )
            else ...[
              page,
              const SizedBox(height: 18),
              rail,
            ],
          ],
        );
      },
    );
  }

  Widget _dashboardHeading(BuildContext context, DateTime now) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 5),
              Text(
                '${dayLabel(now)} · Your mission, progress and next move.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        StatusPill(
          label: app.workspace.settings['demo'] == 'true'
              ? 'Demo workspace'
              : 'Local workspace',
          color: Theme.of(context).colorScheme.secondary,
        ),
      ],
    ),
  );

  Widget _mainColumn(
    BuildContext context,
    StrategyRecord? mission,
    List<StrategyRecord> skills,
    MissionWeeklySummary? metrics,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _missionHero(context, mission),
      const SizedBox(height: 18),
      _engineSummary(context, mission),
      const SizedBox(height: 18),
      LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth >= 720
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _skills(context, skills)),
                  const SizedBox(width: 18),
                  Expanded(child: _week(context, metrics)),
                ],
              )
            : Column(
                children: [
                  _skills(context, skills),
                  const SizedBox(height: 18),
                  _week(context, metrics),
                ],
              ),
      ),
    ],
  );

  Widget _missionHero(BuildContext context, StrategyRecord? mission) {
    final scheme = Theme.of(context).colorScheme;
    if (mission == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EmptyState(
            'No active mission yet',
            'A mission connects daily work to a measurable outcome.\nExample: Job Switch 2027',
            'Create mission',
            onMission,
            icon: Icons.flag_outlined,
          ),
          const SizedBox(height: 10),
          const Text(
            'Make room for meaningful work',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ],
      );
    }
    final progress = app.workspace.missionProgress(mission.id);
    final subtitle = mission.text('description').isNotEmpty
        ? mission.text('description')
        : mission.text('success_criteria');
    final rawStatus = mission.text('status').trim();
    final status = rawStatus.isEmpty ? 'Active' : rawStatus;
    final healthy = !RegExp(
      r'paused|blocked|risk|attention',
      caseSensitive: false,
    ).hasMatch(status);
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            scheme.primaryContainer.withValues(alpha: .82),
            scheme.secondaryContainer.withValues(alpha: .48),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: scheme.primary.withValues(alpha: .12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVE MISSION',
            style: TextStyle(
              color: scheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          Text(mission.title, style: Theme.of(context).textTheme.displaySmall),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),
          Row(
            children: [
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 16),
              StatusPill(
                label: status,
                color: healthy
                    ? const Color(0xff26956a)
                    : const Color(0xffc47b17),
              ),
            ],
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onMission,
            icon: const Icon(Icons.arrow_forward, size: 17),
            label: const Text('Open mission'),
          ),
        ],
      ),
    );
  }

  Widget _engineSummary(BuildContext context, StrategyRecord? mission) {
    final items = engineSummaries(app.workspace, mission);
    const colors = [Color(0xff3978e6), Color(0xff815ac7), Color(0xffc58a19)];
    const icons = [
      Icons.work_outline,
      Icons.widgets_outlined,
      Icons.savings_outlined,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Engine summary'),
        const SizedBox(height: 12),
        Panel(
          padding: const EdgeInsets.all(10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth >= 720
                  ? (constraints.maxWidth - 24) / 3
                  : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var index = 0; index < items.length; index++)
                    SizedBox(
                      width: width,
                      child: _EngineCard(
                        title: '${items[index].engine} Engine',
                        purpose: items[index].purpose,
                        value: items[index].progress,
                        color: colors[index],
                        icon: icons[index],
                        status: items[index].status,
                        detail: items[index].detail,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _skills(BuildContext context, List<StrategyRecord> skills) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: SectionLabel('Skill readiness')),
            TextButton(
              onPressed: onMission,
              child: const Text('View details →'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (skills.isEmpty)
          const Text(
            'Add mission skills and verified evidence to see readiness.',
          )
        else
          for (final skill in skills)
            MetricBar(
              label: skill.title,
              value: app.workspace.readiness(skill.id) / 100,
              color: const Color(0xff3978e6),
            ),
      ],
    ),
  );

  Widget _week(BuildContext context, MissionWeeklySummary? metrics) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Weekly progress'),
        const SizedBox(height: 18),
        MetricBar(
          label: 'Sessions',
          value: metrics?.completion ?? 0,
          valueLabel: metrics == null
              ? 'No active mission'
              : '${metrics.completed} / ${metrics.planned}',
          color: const Color(0xff26956a),
        ),
        _compactStat(
          Icons.timer_outlined,
          'Focused',
          durationLabel(metrics?.focusedSeconds ?? 0),
        ),
        _compactStat(
          Icons.inventory_2_outlined,
          'Outputs',
          '${metrics?.outputCount ?? 0}',
        ),
        _compactStat(
          Icons.send_outlined,
          'Applications / interviews',
          '${metrics?.applicationCount ?? 0} / ${metrics?.interviewCount ?? 0}',
        ),
      ],
    ),
  );

  Widget _rightRail(
    BuildContext context,
    List<Session> sessions,
    List<DashboardPriority> priorities,
    List<DashboardWin> wins,
  ) => Column(
    children: [
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(child: SectionLabel('Today')),
                TextButton(onPressed: onToday, child: const Text('Open →')),
              ],
            ),
            const SizedBox(height: 8),
            if (sessions.isEmpty)
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Make room for meaningful work',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 5),
                  Text('Plan one focused session and define a clear target.'),
                ],
              )
            else
              for (final session in sessions.take(4))
                _TimelineItem(
                  session: session,
                  onTap: () => openSession(context, app, session),
                ),
            if (sessions
                    .where((session) => !session.status.terminal)
                    .firstOrNull
                case final session?) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => openSession(context, app, session),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Start session'),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 18),
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionLabel('Top priorities'),
            const SizedBox(height: 12),
            if (priorities.isEmpty)
              const Text('No active project priorities yet.')
            else
              for (var i = 0; i < priorities.length; i++)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 13,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  title: Text(
                    priorities[i].project.nextAction.isEmpty
                        ? priorities[i].project.title
                        : priorities[i].project.nextAction,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${priorities[i].project.title}\n${priorities[i].explanation}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: onProjects,
                ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(child: SectionLabel('Recent wins')),
                Icon(
                  Icons.auto_awesome,
                  size: 17,
                  color: const Color(0xffc58a19),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (wins.isEmpty)
              const Text(
                'Finished outputs will appear here as evidence-based wins.',
              )
            else
              for (final win in wins)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 18,
                        color: Color(0xff26956a),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${win.output.title}\nVerified · ${win.skill}',
                        ),
                      ),
                    ],
                  ),
                ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onKnowledge,
                child: const Text('Open evidence →'),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _compactStat(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 13),
    child: Row(
      children: [
        Icon(icon, size: 17),
        const SizedBox(width: 9),
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _EngineCard extends StatelessWidget {
  final String title, purpose, status, detail;
  final double? value;
  final Color color;
  final IconData icon;
  const _EngineCard({
    required this.title,
    required this.purpose,
    required this.status,
    required this.detail,
    required this.value,
    required this.color,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 19, color: color),
        ),
        const SizedBox(height: 15),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(purpose, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        if (value != null)
          LinearProgressIndicator(
            value: value!.clamp(0, 1),
            color: color,
            minHeight: 5,
            borderRadius: BorderRadius.circular(5),
          )
        else
          Text('Not measured', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(status, style: Theme.of(context).textTheme.bodySmall),
            ),
            Text(
              value == null ? '—' : '${(value! * 100).round()}%',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(detail, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _TimelineItem extends StatelessWidget {
  final Session session;
  final VoidCallback onTap;
  const _TimelineItem({required this.session, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 46,
            child: Text(
              timeLabel(session.plannedStart),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: session.status == SessionStatus.done
                      ? const Color(0xff26956a)
                      : Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 1,
                height: 37,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${session.plannedMinutes} min',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
