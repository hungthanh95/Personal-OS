import 'package:flutter/material.dart';

import '../../application/app_controller.dart';
import '../../domain/models.dart';
import '../widgets/common.dart';

class StrategyMapScreen extends StatefulWidget {
  final AppController app;

  const StrategyMapScreen(this.app, {super.key});

  @override
  State<StrategyMapScreen> createState() => _StrategyMapScreenState();
}

class _StrategyMapScreenState extends State<StrategyMapScreen> {
  String? horizonId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Strategy hierarchy')),
    body: ListenableBuilder(
      listenable: widget.app,
      builder: (context, _) {
        final workspace = widget.app.workspace;
        final horizons = workspace.records('horizons');
        final strategies = workspace
            .records('strategies')
            .where(
              (strategy) =>
                  horizonId == null || strategy.ref('horizon_id') == horizonId,
            );
        return ListView(
          padding: const EdgeInsets.all(28),
          children: [
            const PageHeading(
              'Strategy hierarchy',
              'Inspect the causal path from a time horizon to execution evidence.',
            ),
            DropdownButtonFormField<String?>(
              initialValue: horizonId,
              decoration: const InputDecoration(labelText: 'Zoom to horizon'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All horizons'),
                ),
                ...horizons.map(
                  (horizon) => DropdownMenuItem<String?>(
                    value: horizon.id,
                    child: Text(horizon.title),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => horizonId = value),
            ),
            const SizedBox(height: 20),
            if (strategies.isEmpty)
              const Panel(
                child: Text('No strategy is linked to this horizon.'),
              ),
            for (final strategy in strategies)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _StrategyBranch(
                  workspace: workspace,
                  strategy: strategy,
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _StrategyBranch extends StatelessWidget {
  final Workspace workspace;
  final StrategyRecord strategy;

  const _StrategyBranch({required this.workspace, required this.strategy});

  @override
  Widget build(BuildContext context) {
    final horizon = workspace.record('horizons', strategy.ref('horizon_id'));
    final vision = workspace.record('visions', strategy.ref('vision_id'));
    final missions = workspace
        .records('missions')
        .where((mission) => mission.ref('strategy_id') == strategy.id);
    final assumptions = workspace
        .records('assumptions')
        .where((assumption) => assumption.ref('strategy_id') == strategy.id);
    return Panel(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.account_tree_outlined),
        title: Text(strategy.title),
        subtitle: Text(
          '${vision?.title ?? 'No vision'} → ${horizon?.title ?? 'No horizon'} · ${strategy.text('engine')} / ${strategy.text('allocation')}',
        ),
        onExpansionChanged: (_) {},
        children: [
          _InspectTile(
            icon: Icons.explore_outlined,
            label: 'Strategy',
            entity: strategy,
          ),
          for (final assumption in assumptions)
            _InspectTile(
              icon: Icons.help_outline,
              label: 'Assumption',
              entity: assumption,
            ),
          for (final mission in missions)
            _MissionBranch(workspace: workspace, mission: mission),
        ],
      ),
    );
  }
}

class _MissionBranch extends StatelessWidget {
  final Workspace workspace;
  final StrategyRecord mission;

  const _MissionBranch({required this.workspace, required this.mission});

  @override
  Widget build(BuildContext context) {
    final outcomes = workspace
        .records('outcomes')
        .where((outcome) => outcome.ref('mission_id') == mission.id);
    final missionProjects = workspace.projects.where((project) {
      final initiative = workspace.record('initiatives', project.initiativeId);
      final outcome = workspace.record('outcomes', project.outcomeId);
      return initiative?.ref('mission_id') == mission.id ||
          outcome?.ref('mission_id') == mission.id ||
          (mission.ref('goal_id') != null &&
              project.goalId == mission.ref('goal_id'));
    });
    final linkedProjectIds = <String>{};
    return ExpansionTile(
      leading: const Icon(Icons.flag_outlined),
      title: Text(mission.title),
      subtitle: Text(
        '${mission.text('status')} · ${(workspace.missionProgress(mission.id) * 100).round()}% outcome attainment',
      ),
      childrenPadding: const EdgeInsets.only(left: 20),
      children: [
        _InspectTile(
          label: 'Mission',
          entity: mission,
          icon: Icons.info_outline,
        ),
        for (final outcome in outcomes)
          _OutcomeBranch(
            workspace: workspace,
            outcome: outcome,
            linkedProjectIds: linkedProjectIds,
          ),
        for (final project in missionProjects)
          if (linkedProjectIds.add(project.id))
            _ProjectBranch(workspace: workspace, project: project),
        for (final skill
            in workspace
                .records('skills')
                .where((skill) => skill.ref('mission_id') == mission.id))
          _SkillBranch(workspace: workspace, skill: skill),
      ],
    );
  }
}

class _OutcomeBranch extends StatelessWidget {
  final Workspace workspace;
  final StrategyRecord outcome;
  final Set<String> linkedProjectIds;

  const _OutcomeBranch({
    required this.workspace,
    required this.outcome,
    required this.linkedProjectIds,
  });

  @override
  Widget build(BuildContext context) {
    final initiatives = workspace
        .records('initiatives')
        .where((initiative) => initiative.ref('outcome_id') == outcome.id);
    return ExpansionTile(
      leading: const Icon(Icons.track_changes_outlined),
      title: Text(outcome.title),
      subtitle: Text(
        '${outcome.number('current_value')} / ${outcome.number('target')} ${outcome.text('unit')}',
      ),
      childrenPadding: const EdgeInsets.only(left: 20),
      children: [
        _InspectTile(
          label: 'Outcome',
          entity: outcome,
          icon: Icons.info_outline,
        ),
        for (final initiative in initiatives)
          _InitiativeBranch(
            workspace: workspace,
            initiative: initiative,
            linkedProjectIds: linkedProjectIds,
          ),
        for (final project in workspace.projects.where(
          (project) => project.outcomeId == outcome.id,
        ))
          if (linkedProjectIds.add(project.id))
            _ProjectBranch(workspace: workspace, project: project),
      ],
    );
  }
}

class _InitiativeBranch extends StatelessWidget {
  final Workspace workspace;
  final StrategyRecord initiative;
  final Set<String> linkedProjectIds;

  const _InitiativeBranch({
    required this.workspace,
    required this.initiative,
    required this.linkedProjectIds,
  });

  @override
  Widget build(BuildContext context) => ExpansionTile(
    leading: const Icon(Icons.route_outlined),
    title: Text(initiative.title),
    subtitle: Text(
      '${initiative.text('status')} · ${initiative.number('weekly_budget_minutes')} min/week',
    ),
    childrenPadding: const EdgeInsets.only(left: 20),
    children: [
      _InspectTile(
        label: 'Initiative',
        entity: initiative,
        icon: Icons.info_outline,
      ),
      for (final project in workspace.projects.where(
        (project) => project.initiativeId == initiative.id,
      ))
        if (linkedProjectIds.add(project.id))
          _ProjectBranch(workspace: workspace, project: project),
    ],
  );
}

class _ProjectBranch extends StatelessWidget {
  final Workspace workspace;
  final Project project;

  const _ProjectBranch({required this.workspace, required this.project});

  @override
  Widget build(BuildContext context) => ExpansionTile(
    leading: const Icon(Icons.folder_outlined),
    title: Text(project.title),
    subtitle: Text('${project.status.name} · ${project.nextAction}'),
    childrenPadding: const EdgeInsets.only(left: 20),
    children: [
      _InspectTile(label: 'Project', entity: project, icon: Icons.info_outline),
      for (final task in workspace.tasks.where(
        (task) => task.ref('project_id') == project.id,
      ))
        _InspectTile(
          label: 'Task',
          entity: task,
          icon: Icons.check_box_outlined,
        ),
      for (final session in workspace.sessions.where(
        (session) => session.projectId == project.id,
      ))
        ExpansionTile(
          leading: const Icon(Icons.timer_outlined),
          title: Text(session.title),
          subtitle: Text(
            '${session.status.label} · ${dateField(session.plannedStart)} ${timeLabel(session.plannedStart)}',
          ),
          childrenPadding: const EdgeInsets.only(left: 20),
          children: [
            _InspectTile(
              label: 'Session',
              entity: session,
              icon: Icons.info_outline,
            ),
            for (final output in workspace.outputs.where(
              (output) => output.sessionId == session.id,
            ))
              _InspectTile(
                label: 'Output evidence',
                entity: output,
                icon: Icons.inventory_2_outlined,
              ),
          ],
        ),
    ],
  );
}

class _SkillBranch extends StatelessWidget {
  final Workspace workspace;
  final StrategyRecord skill;

  const _SkillBranch({required this.workspace, required this.skill});

  @override
  Widget build(BuildContext context) => ExpansionTile(
    leading: const Icon(Icons.psychology_outlined),
    title: Text(skill.title),
    subtitle: Text(
      '${workspace.readiness(skill.id).toStringAsFixed(1)}% ready',
    ),
    childrenPadding: const EdgeInsets.only(left: 20),
    children: [
      for (final evidence
          in workspace
              .records('evidence')
              .where((record) => record.ref('skill_id') == skill.id))
        _InspectTile(
          label: 'Evidence',
          entity: evidence,
          icon: Icons.fact_check_outlined,
        ),
    ],
  );
}

class _InspectTile extends StatelessWidget {
  final String label;
  final Entity entity;
  final IconData icon;

  const _InspectTile({
    required this.label,
    required this.entity,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    leading: Icon(icon),
    title: Text(entity.title.isEmpty ? label : entity.title),
    subtitle: Text(label),
    onTap: () => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$label · ${entity.title}'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: SelectableText(
              entity.data.entries
                  .where(
                    (entry) =>
                        entry.key != 'id' &&
                        entry.key != 'created_at' &&
                        entry.value != null &&
                        entry.value.toString().trim().isNotEmpty,
                  )
                  .map(
                    (entry) =>
                        '${entry.key.replaceAll('_', ' ')}: ${entry.value}',
                  )
                  .join('\n\n'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    ),
  );
}
