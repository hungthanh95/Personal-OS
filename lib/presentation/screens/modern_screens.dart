import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/app_controller.dart';
import '../../domain/insights.dart';
import '../../domain/models.dart';
import '../dashboard_data.dart';
import '../widgets/common.dart';
import 'career_income_screens.dart';
import 'direction_screens.dart';
import 'knowledge_import.dart';
import 'library_screen.dart';
import 'record_editor.dart';
import 'strategy_screens.dart';
import 'trajectory_screen.dart';
import 'utilities.dart';

class MissionOverviewScreen extends StatelessWidget {
  final AppController app;
  final String? missionId;
  const MissionOverviewScreen(this.app, {this.missionId, super.key});

  @override
  Widget build(BuildContext context) {
    final w = app.workspace;
    final mission = missionId == null
        ? w.activeMission
        : w.record('missions', missionId);
    if (mission == null) {
      return ListView(
        padding: const EdgeInsets.all(28),
        children: [
          const PageHeading(
            'Missions',
            'Measurable outcomes that give daily work a direction.',
          ),
          EmptyState(
            'No active mission yet',
            'A mission connects daily work to a measurable outcome.\n\nExample: Job Switch 2027',
            'Create mission',
            () => editStrategyRecord(context, app, 'missions'),
            icon: Icons.flag_outlined,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Goals & life map')),
                    body: GoalsScreen(app),
                  ),
                ),
              ),
              child: const Text('Manage existing goals & project links'),
            ),
          ),
        ],
      );
    }
    final progress = w.missionProgress(mission.id);
    final outcomes = w
        .records('outcomes')
        .where((item) => item.ref('mission_id') == mission.id)
        .toList();
    final skills =
        w
            .records('skills')
            .where((item) => item.ref('mission_id') == mission.id)
            .toList()
          ..sort((a, b) => w.readiness(a.id).compareTo(w.readiness(b.id)));
    final skillIds = skills.map((skill) => skill.id).toSet();
    final evidence =
        w
            .records('evidence')
            .where(
              (item) =>
                  skillIds.contains(item.ref('skill_id')) &&
                  item.number('verified') == 1,
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final careerPipeline = MissionCareerPipeline.calculate(w, mission.id);

    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        PageHeading(
          mission.title,
          mission.text('description').isNotEmpty
              ? mission.text('description')
              : 'Your active mission and the evidence needed to complete it.',
          action: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => attempt(
                  context,
                  () => app.openMarkdownRecord('missions', mission.id),
                ),
                icon: const Icon(Icons.description_outlined, size: 18),
                label: const Text('Open note'),
              ),
              FilledButton.icon(
                onPressed: () => editRecord(
                  context,
                  app,
                  'sessions',
                  initial: {
                    'title': skills.isEmpty
                        ? 'Mission progress session'
                        : 'Close gap: ${skills.first.title}',
                    'goal_id': mission.ref('goal_id'),
                  },
                ),
                icon: const Icon(Icons.add_task, size: 18),
                label: const Text('Plan biggest gap'),
              ),
            ],
          ),
        ),
        Panel(
          child: LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 28,
              runSpacing: 20,
              children: [
                _missionStat(
                  'Status',
                  mission.text('status').isEmpty
                      ? 'Active'
                      : mission.text('status'),
                  const Color(0xff26956a),
                ),
                _missionStat(
                  'Progress',
                  '${(progress * 100).round()}%',
                  const Color(0xff3978e6),
                ),
                _missionStat(
                  'Confidence',
                  '${mission.number('confidence')}%',
                  const Color(0xff815ac7),
                ),
                _missionStat(
                  'Target',
                  mission.text('target_date').isEmpty
                      ? 'Not set'
                      : mission.text('target_date'),
                  const Color(0xffc58a19),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final currentTarget = _currentTarget(context, outcomes);
            final gaps = _gaps(context, skills);
            if (constraints.maxWidth < 850) {
              return Column(
                children: [currentTarget, const SizedBox(height: 18), gaps],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: currentTarget),
                const SizedBox(width: 18),
                Expanded(flex: 2, child: gaps),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final recent = _recentEvidence(context, evidence.take(5).toList());
            final pipelinePanel = _pipeline(
              context,
              careerPipeline.jobs,
              careerPipeline.applications,
              careerPipeline.interviews,
              careerPipeline.offers,
            );
            if (constraints.maxWidth < 850) {
              return Column(
                children: [recent, const SizedBox(height: 18), pipelinePanel],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: recent),
                const SizedBox(width: 18),
                Expanded(flex: 2, child: pipelinePanel),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        ExpansionTile(
          title: const Text('Details & related workspaces'),
          subtitle: const Text(
            'Edit metadata, inspect trajectory, or open specialist tools.',
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => CareerWorkspaceScreen(app, mission.id),
                    ),
                  ),
                  child: const Text('Career workspace'),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => TrajectoryScreen(app, mission.id),
                    ),
                  ),
                  child: const Text('Trajectory'),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Goals & life map')),
                        body: GoalsScreen(app),
                      ),
                    ),
                  ),
                  child: const Text('Manage existing goals & project links'),
                ),
                TextButton(
                  onPressed: () => editStrategyRecord(
                    context,
                    app,
                    'missions',
                    record: mission,
                  ),
                  child: const Text('Edit mission'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _missionStat(String label, String value, Color color) => SizedBox(
    width: 150,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );

  Widget _currentTarget(
    BuildContext context,
    List<StrategyRecord> outcomes,
  ) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Current → target'),
        const SizedBox(height: 18),
        if (outcomes.isEmpty)
          const Text(
            'Add measurable outcomes to make mission progress explainable.',
          )
        else
          for (final item in outcomes)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${item.number('current_value')}  →  ${item.number('target')} ${item.text('unit')}',
                  ),
                ],
              ),
            ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => editStrategyRecord(
              context,
              app,
              'outcomes',
              initial: {'mission_id': app.workspace.activeMission!.id},
            ),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add outcome'),
          ),
        ),
      ],
    ),
  );

  Widget _gaps(BuildContext context, List<StrategyRecord> skills) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Top gaps'),
        const SizedBox(height: 14),
        if (skills.isEmpty)
          const Text('Add 4–6 mission-critical skills to rank your gaps.')
        else
          for (var i = 0; i < skills.take(4).length; i++)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 13,
                child: Text('${i + 1}', style: const TextStyle(fontSize: 11)),
              ),
              title: Text(skills[i].title),
              trailing: Text(
                '${app.workspace.readiness(skills[i].id).round()}%',
              ),
            ),
        TextButton.icon(
          onPressed: () => editStrategyRecord(
            context,
            app,
            'skills',
            initial: {'mission_id': app.workspace.activeMission!.id},
          ),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add skill'),
        ),
      ],
    ),
  );

  Widget _recentEvidence(BuildContext context, List<StrategyRecord> evidence) =>
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionLabel('Recent evidence'),
            const SizedBox(height: 14),
            if (evidence.isEmpty)
              const Text(
                'Verified outputs linked to mission skills will appear here.',
              )
            else
              for (final item in evidence)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.verified_outlined,
                    color: Color(0xff26956a),
                  ),
                  title: Text(item.title),
                  subtitle: Text(
                    '${item.text('dimension')} · ${item.number('score')}%',
                  ),
                ),
          ],
        ),
      );

  Widget _pipeline(
    BuildContext context,
    int jobs,
    int applied,
    int interviews,
    int offers,
  ) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Career pipeline'),
        const SizedBox(height: 16),
        _pipelineRow('Jobs reviewed', jobs),
        _pipelineRow('Applied', applied),
        _pipelineRow('Interviews', interviews),
        _pipelineRow('Offers', offers),
      ],
    ),
  );

  Widget _pipelineRow(String label, int value) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class StrategyOverviewScreen extends StatefulWidget {
  final AppController app;
  const StrategyOverviewScreen(this.app, {super.key});
  @override
  State<StrategyOverviewScreen> createState() => _StrategyOverviewScreenState();
}

class _StrategyOverviewScreenState extends State<StrategyOverviewScreen> {
  StrategyRecord? selected;

  Future<void> _loadStarter(BuildContext context) async {
    try {
      final raw =
          jsonDecode(
                await rootBundle.loadString('assets/strategy_starter.json'),
              )
              as Map<String, dynamic>;
      await widget.app.repository.installStrategyTemplate(
        raw.map(
          (key, value) => MapEntry(
            key,
            (value as List)
                .map((row) => Map<String, Object?>.from(row as Map))
                .toList(),
          ),
        ),
      );
      await widget.app.refresh();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load starter: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final w = app.workspace;
    final visions = w.records('visions');
    if (visions.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(28),
        children: [
          const PageHeading(
            'Strategy',
            'A read-first map from long-term direction to current missions.',
          ),
          EmptyState(
            'Build your strategy map',
            'Start from your own vision, or load the editable Career / Ownership / Capital example.',
            'Load starter strategy',
            () => _loadStarter(context),
            icon: Icons.account_tree_outlined,
          ),
        ],
      );
    }
    selected ??= w.activeMission ?? visions.first;
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        PageHeading(
          'Strategy',
          'A clear hierarchy from vision to the work that matters now.',
          action: PopupMenuButton<String>(
            tooltip: 'Add strategy item',
            onSelected: (table) => editStrategyRecord(context, app, table),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'visions', child: Text('Vision')),
              PopupMenuItem(value: 'strategies', child: Text('Strategy')),
              PopupMenuItem(value: 'missions', child: Text('Mission')),
              PopupMenuItem(value: 'assumptions', child: Text('Assumption')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final map = _strategyMap(context, w, visions);
            final detail = _selectedDetail(context, w);
            return constraints.maxWidth >= 900
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: map),
                      const SizedBox(width: 18),
                      Expanded(flex: 2, child: detail),
                    ],
                  )
                : Column(children: [map, const SizedBox(height: 18), detail]);
          },
        ),
        const SizedBox(height: 20),
        ExpansionTile(
          title: const Text('Advanced strategy tools'),
          subtitle: const Text(
            'Assumptions, recommendations, planning previews and history.',
          ),
          childrenPadding: const EdgeInsets.only(bottom: 16),
          children: [
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Advanced strategy')),
                    body: StrategyScreen(app),
                  ),
                ),
              ),
              icon: const Icon(Icons.tune),
              label: const Text('Open advanced strategy'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _strategyMap(
    BuildContext context,
    Workspace w,
    List<StrategyRecord> visions,
  ) => Panel(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Strategy map'),
        const SizedBox(height: 20),
        for (final vision in visions) ...[
          _node(
            context,
            vision,
            Icons.north_east,
            const Color(0xff3978e6),
            large: true,
          ),
          for (final strategy
              in w
                  .records('strategies')
                  .where((item) => item.ref('vision_id') == vision.id)) ...[
            _connector(),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: _node(
                context,
                strategy,
                switch (strategy.text('engine').toLowerCase()) {
                  'ownership' => Icons.widgets_outlined,
                  'capital' => Icons.savings_outlined,
                  _ => Icons.work_outline,
                },
                switch (strategy.text('engine').toLowerCase()) {
                  'ownership' => const Color(0xff815ac7),
                  'capital' => const Color(0xffc58a19),
                  _ => const Color(0xff3978e6),
                },
              ),
            ),
            for (final mission
                in w
                    .records('missions')
                    .where(
                      (item) => item.ref('strategy_id') == strategy.id,
                    )) ...[
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: _connector(),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 56),
                child: _node(
                  context,
                  mission,
                  Icons.flag_outlined,
                  const Color(0xff26956a),
                ),
              ),
              if (mission.id == w.activeMission?.id)
                Padding(
                  padding: const EdgeInsets.fromLTRB(84, 8, 8, 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final skill
                          in w
                              .records('skills')
                              .where(
                                (item) => item.ref('mission_id') == mission.id,
                              )
                              .take(6))
                        ActionChip(
                          label: Text(skill.title),
                          onPressed: () => setState(() => selected = skill),
                        ),
                    ],
                  ),
                ),
            ],
          ],
          const SizedBox(height: 14),
        ],
      ],
    ),
  );

  Widget _node(
    BuildContext context,
    StrategyRecord record,
    IconData icon,
    Color color, {
    bool large = false,
  }) => Material(
    color: selected?.id == record.id
        ? color.withValues(alpha: .12)
        : Colors.transparent,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => selected = record),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                record.title,
                style: TextStyle(
                  fontSize: large ? 19 : 15,
                  fontWeight: large ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    ),
  );

  Widget _connector() => Container(
    margin: const EdgeInsets.only(left: 47),
    width: 2,
    height: 16,
    color: Theme.of(context).colorScheme.outlineVariant,
  );

  Widget _selectedDetail(BuildContext context, Workspace w) {
    final item = selected!;
    final kind = w.records('missions').any((x) => x.id == item.id)
        ? 'Mission'
        : w.records('skills').any((x) => x.id == item.id)
        ? 'Skill'
        : w.records('strategies').any((x) => x.id == item.id)
        ? 'Strategy'
        : 'Vision';
    final evidenceCount = kind == 'Skill'
        ? w
              .records('evidence')
              .where((e) => e.ref('skill_id') == item.id)
              .length
        : kind == 'Mission'
        ? w
              .records('skills')
              .where((skill) => skill.ref('mission_id') == item.id)
              .fold<int>(
                0,
                (sum, skill) =>
                    sum +
                    w
                        .records('evidence')
                        .where((e) => e.ref('skill_id') == skill.id)
                        .length,
              )
        : 0;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatusPill(label: kind, color: const Color(0xff3978e6)),
          const SizedBox(height: 16),
          Text(item.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          const SectionLabel('Purpose'),
          const SizedBox(height: 7),
          Text(
            item.text('description').isNotEmpty
                ? item.text('description')
                : item.text('success_criteria').isNotEmpty
                ? item.text('success_criteria')
                : 'Give this item a concise purpose.',
          ),
          const SizedBox(height: 18),
          _detailRow(
            'Status',
            item.text('status').isEmpty ? 'Active' : item.text('status'),
          ),
          _detailRow('Evidence', '$evidenceCount items'),
          if (kind == 'Strategy')
            _detailRow(
              'Assumptions',
              '${w.records('assumptions').where((a) => a.ref('strategy_id') == item.id).length}',
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (kind == 'Mission')
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Mission')),
                        body: MissionOverviewScreen(
                          widget.app,
                          missionId: item.id,
                        ),
                      ),
                    ),
                  ),
                  child: const Text('Open mission'),
                ),
              TextButton(
                onPressed: () => editStrategyRecord(
                  context,
                  widget.app,
                  '${kind.toLowerCase()}s',
                  record: item,
                ),
                child: const Text('Edit'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class ProjectsOverviewScreen extends StatelessWidget {
  final AppController app;
  const ProjectsOverviewScreen(this.app, {super.key});
  @override
  Widget build(BuildContext context) {
    final projects = app.workspace.projects.toList()
      ..sort((a, b) {
        final active = (a.status == ProjectStatus.active ? 0 : 1).compareTo(
          b.status == ProjectStatus.active ? 0 : 1,
        );
        return active == 0 ? a.priority.compareTo(b.priority) : active;
      });
    final active = projects
        .where((p) => p.status == ProjectStatus.active)
        .toList();
    final later = projects
        .where((p) => p.status != ProjectStatus.active)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        PageHeading(
          'Projects',
          'Active work, visible progress and one concrete next action.',
          action: FilledButton.icon(
            onPressed: () => editRecord(context, app, 'projects'),
            icon: const Icon(Icons.add),
            label: const Text('New project'),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => IncomeLabScreen(app)),
              ),
              icon: const Icon(Icons.science_outlined),
              label: const Text('Income Lab'),
            ),
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => OwnershipCapitalScreen(app),
                ),
              ),
              icon: const Icon(Icons.account_balance_outlined),
              label: const Text('Ownership & Capital'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const SectionLabel('Active projects'),
        const SizedBox(height: 12),
        if (active.isEmpty)
          EmptyState(
            'No active projects',
            'A project turns your mission into a concrete body of work.',
            'Create project',
            () => editRecord(context, app, 'projects'),
            icon: Icons.folder_outlined,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth >= 900
                  ? (constraints.maxWidth - 18) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 18,
                runSpacing: 18,
                children: [
                  for (final project in active)
                    SizedBox(
                      width: width,
                      child: _ProjectOverviewCard(app, project),
                    ),
                ],
              );
            },
          ),
        if (later.isNotEmpty) ...[
          const SizedBox(height: 28),
          ExpansionTile(
            title: Text('Paused & completed (${later.length})'),
            children: [
              for (final project in later)
                ListTile(
                  title: Text(project.title),
                  subtitle: Text(project.status.name),
                  onTap: () => openProject(context, app, project),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ProjectOverviewCard extends StatelessWidget {
  final AppController app;
  final Project project;
  const _ProjectOverviewCard(this.app, this.project);
  @override
  Widget build(BuildContext context) {
    final execution = app.workspace.projectExecutionProgress(project.id);
    final milestones = app.workspace.projectProgress(project.id);
    final mission = app.workspace
        .records('missions')
        .where(
          (candidate) =>
              projectSupportsMission(app.workspace, project, candidate),
        )
        .firstOrNull;
    final storedType = project.text('project_type');
    final type = storedType.isEmpty
        ? 'Unclassified'
        : storedType == 'IncomeExperiment'
        ? 'Experiment'
        : storedType;
    return InkWell(
      onTap: () => openProject(context, app, project),
      borderRadius: BorderRadius.circular(16),
      child: Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    project.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    StatusPill(label: type, color: const Color(0xff3978e6)),
                    StatusPill(
                      label: project.status.name,
                      color: project.status == ProjectStatus.active
                          ? const Color(0xff26956a)
                          : const Color(0xff687386),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            const SectionLabel('Task execution'),
            const SizedBox(height: 6),
            ProgressValue(execution),
            const SizedBox(height: 10),
            const SectionLabel('Milestones'),
            const SizedBox(height: 6),
            ProgressValue(milestones),
            const SizedBox(height: 18),
            const SectionLabel('Next action'),
            const SizedBox(height: 6),
            Text(
              project.nextAction.isEmpty
                  ? 'Define the next concrete action'
                  : project.nextAction,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            Text(
              'Linked mission: ${mission?.title ?? app.workspace.goal(project.goalId)?.title ?? 'Not linked'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Continue →',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xff3978e6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KnowledgeOverviewScreen extends StatelessWidget {
  final AppController app;
  const KnowledgeOverviewScreen(this.app, {super.key});
  @override
  Widget build(BuildContext context) {
    final recent = app.workspace.knowledge.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final mission = app.workspace.activeMission;
    final missionSkills = mission == null
        ? <String>[]
        : app.workspace
              .records('skills')
              .where((s) => s.ref('mission_id') == mission.id)
              .map((s) => s.title.toLowerCase())
              .toList();
    final relevant = recent
        .where((item) {
          final haystack =
              '${item.title} ${item.text('tags')} ${item.text('content')}'
                  .toLowerCase();
          return missionSkills.any(
            (skill) => skill
                .split(RegExp(r'[/ ]'))
                .where((part) => part.length > 2)
                .any(haystack.contains),
          );
        })
        .take(5)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        PageHeading(
          'Knowledge',
          'Find the right idea, reference or evidence when you need it.',
          action: OutlinedButton.icon(
            onPressed: () => importKnowledge(context, app),
            icon: const Icon(Icons.file_open_outlined),
            label: const Text('Import'),
          ),
        ),
        Semantics(
          button: true,
          label: 'Search your knowledge',
          child: TextField(
            readOnly: true,
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => KnowledgeSearchDialog(app),
            ),
            decoration: const InputDecoration(
              hintText: 'Search your knowledge…',
              prefixIcon: Icon(Icons.search),
              suffixIcon: Icon(Icons.arrow_forward),
            ),
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final recentPanel = _knowledgeList(
              context,
              'Recent',
              recent.take(6).toList(),
            );
            final relevantPanel = _knowledgeList(
              context,
              'Relevant to current mission',
              relevant,
            );
            return constraints.maxWidth >= 850
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: recentPanel),
                      const SizedBox(width: 18),
                      Expanded(child: relevantPanel),
                    ],
                  )
                : Column(
                    children: [
                      recentPanel,
                      const SizedBox(height: 18),
                      relevantPanel,
                    ],
                  );
          },
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => editRecord(context, app, 'knowledge'),
            icon: const Icon(Icons.add, size: 17),
            label: const Text('Create note'),
          ),
        ),
        ExpansionTile(
          title: const Text('Advanced knowledge tools'),
          subtitle: const Text(
            'Output library, concept graph, duplicates and freshness.',
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => KnowledgeAdvancedScreen(app),
                  ),
                ),
                child: const Text('Open advanced tools'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _knowledgeList(
    BuildContext context,
    String title,
    List<KnowledgeItem> items,
  ) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(title),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Text(
            title == 'Recent'
                ? 'Capture or import your first useful note.'
                : 'Link knowledge to mission work to see it here.',
          )
        else
          for (final item in items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(item.title),
              subtitle: Text(
                item.text('type').isEmpty ? 'Knowledge' : item.text('type'),
              ),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => openEvidence(context, app, item),
            ),
      ],
    ),
  );
}

class ReviewOverviewScreen extends StatefulWidget {
  final AppController app;
  const ReviewOverviewScreen(this.app, {super.key});
  @override
  State<ReviewOverviewScreen> createState() => _ReviewOverviewScreenState();
}

class _ReviewOverviewScreenState extends State<ReviewOverviewScreen> {
  final wentWell = TextEditingController();
  final slipped = TextEditingController();
  final learning = TextEditingController();
  final carry = TextEditingController();
  final focus = TextEditingController();
  bool saving = false;
  String? saveError;

  @override
  void initState() {
    super.initState();
    _loadCurrentReview();
  }

  void _loadCurrentReview() {
    final reviewId = dateField(weekStart(DateTime.now()));
    final existing = widget.app.workspace.reviews
        .where((review) => review.id == reviewId)
        .firstOrNull;
    if (existing == null) return;
    final reflection = existing.text('reflection');
    wentWell.text = _reviewAnswer(
      reflection,
      'What went well?',
      'What slipped?',
    );
    slipped.text = _reviewAnswer(
      reflection,
      'What slipped?',
      'Biggest learning?',
    );
    learning.text = _reviewAnswer(
      reflection,
      'Biggest learning?',
      'Carry forward',
    );
    carry.text = _reviewAnswer(reflection, 'Carry forward', null);
    focus.text = existing.text('next_action');
  }

  String _reviewAnswer(String source, String heading, String? nextHeading) {
    final start = source.indexOf('$heading\n');
    if (start < 0) return '';
    final contentStart = start + heading.length + 1;
    final end = nextHeading == null
        ? source.length
        : source.indexOf('\n\n$nextHeading\n', contentStart);
    return source.substring(contentStart, end < 0 ? source.length : end).trim();
  }

  @override
  void dispose() {
    for (final controller in [wentWell, slipped, learning, carry, focus]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final metrics = WeeklyMetrics.calculate(widget.app.workspace, now);
    final blocked = widget.app.workspace.sessions
        .where(
          (s) =>
              s.status == SessionStatus.blocked &&
              within(s.plannedStart, weekStart(now), weekEnd(weekStart(now))),
        )
        .length;
    final mission = widget.app.workspace.activeMission;
    final gaps =
        mission == null
              ? <StrategyRecord>[]
              : widget.app.workspace
                    .records('skills')
                    .where((skill) => skill.ref('mission_id') == mission.id)
                    .toList()
          ..sort(
            (a, b) => widget.app.workspace
                .readiness(a.id)
                .compareTo(widget.app.workspace.readiness(b.id)),
          );
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const PageHeading(
          'Weekly review',
          'A guided check-in designed to finish in ten minutes.',
        ),
        Panel(
          child: Wrap(
            spacing: 20,
            runSpacing: 18,
            children: [
              _reviewStat('Planned', metrics.planned, const Color(0xff3978e6)),
              _reviewStat(
                'Completed',
                metrics.completed,
                const Color(0xff26956a),
              ),
              _reviewStat(
                'Evidence',
                metrics.outputCount,
                const Color(0xff815ac7),
              ),
              _reviewStat(
                'Blocked',
                blocked,
                blocked > 0 ? const Color(0xffc45151) : const Color(0xff687386),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (gaps.isNotEmpty) ...[
          Panel(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.track_changes_outlined),
              title: const Text('Biggest current mission gap'),
              subtitle: Text(
                '${gaps.first.title} · ${widget.app.workspace.readiness(gaps.first.id)}% readiness',
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _reviewField(wentWell, 'What went well?'),
              _reviewField(slipped, 'What slipped?'),
              _reviewField(learning, 'Biggest learning?'),
              _reviewField(carry, 'Carry forward'),
              _reviewField(focus, 'Next-week focus'),
              if (saveError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    saveError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: saving ? null : _save,
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(saving ? 'Saving…' : 'Complete review'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ExpansionTile(
          title: const Text('Quarterly & advanced reviews'),
          subtitle: const Text(
            'Revisit mission fit, assumptions, market changes and resource allocation.',
          ),
          childrenPadding: const EdgeInsets.only(bottom: 16),
          children: [
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => QuarterlyReviewScreen(widget.app),
                ),
              ),
              icon: const Icon(Icons.calendar_view_month_outlined),
              label: const Text('Start quarterly review'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Review history')),
                    body: AdaptiveReviewScreen(widget.app),
                  ),
                ),
              ),
              child: const Text('Review history'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _reviewStat(String label, int value, Color color) => SizedBox(
    width: 150,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(label),
      ],
    ),
  );
  Widget _reviewField(TextEditingController controller, String label) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(labelText: label),
        ),
      );
  Future<void> _save() async {
    setState(() {
      saving = true;
      saveError = null;
    });
    final week = weekStart(DateTime.now());
    final reflection = [
      'What went well?\n${wentWell.text.trim()}',
      'What slipped?\n${slipped.text.trim()}',
      'Biggest learning?\n${learning.text.trim()}',
      'Carry forward\n${carry.text.trim()}',
    ].join('\n\n');
    try {
      await widget.app.save('weekly_reviews', {
        'id': dateField(week),
        'reflection': reflection,
        'next_action': focus.text.trim(),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weekly review completed locally.')),
        );
      }
    } catch (error) {
      if (mounted) setState(() => saveError = 'Could not save review: $error');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

class QuarterlyReviewScreen extends StatefulWidget {
  final AppController app;
  const QuarterlyReviewScreen(this.app, {super.key});

  @override
  State<QuarterlyReviewScreen> createState() => _QuarterlyReviewScreenState();
}

class _QuarterlyReviewScreenState extends State<QuarterlyReviewScreen> {
  final missionFit = TextEditingController();
  final assumptions = TextEditingController();
  final market = TextEditingController();
  final skills = TextEditingController();
  final allocation = TextEditingController();
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    final existing = widget.app.workspace
        .records('period_reviews')
        .where((review) => review.id == _reviewId(DateTime.now()))
        .firstOrNull;
    if (existing != null) _load(existing.text('summary'));
  }

  void _load(String source) {
    final controllers = [missionFit, assumptions, market, skills, allocation];
    const headings = [
      'Is the current mission still correct?',
      'Which assumptions changed?',
      'What changed in market?',
      'Which skill deserves more/less attention?',
      'Should resource allocation change?',
    ];
    for (var index = 0; index < headings.length; index++) {
      final start = source.indexOf('${headings[index]}\n');
      if (start < 0) continue;
      final contentStart = start + headings[index].length + 1;
      final end = index == headings.length - 1
          ? source.length
          : source.indexOf('\n\n${headings[index + 1]}\n', contentStart);
      controllers[index].text = source
          .substring(contentStart, end < 0 ? source.length : end)
          .trim();
    }
  }

  static DateTime _quarterStart(DateTime now) =>
      DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1);
  static String _reviewId(DateTime now) =>
      'quarterly-${now.year}-Q${((now.month - 1) ~/ 3) + 1}';

  @override
  void dispose() {
    for (final controller in [
      missionFit,
      assumptions,
      market,
      skills,
      allocation,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Quarterly review')),
    body: ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const PageHeading(
          'Quarterly review',
          'Reassess direction before changing execution.',
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _field(missionFit, 'Is the current mission still correct?'),
              _field(assumptions, 'Which assumptions changed?'),
              _field(market, 'What changed in market?'),
              _field(skills, 'Which skill deserves more/less attention?'),
              _field(allocation, 'Should resource allocation change?'),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: saving ? null : _save,
                  icon: const Icon(Icons.check),
                  label: Text(saving ? 'Saving…' : 'Complete quarterly review'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _field(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: TextField(
      controller: controller,
      minLines: 3,
      maxLines: 6,
      decoration: InputDecoration(labelText: label, alignLabelWithHint: true),
    ),
  );

  Future<void> _save() async {
    final answers = [missionFit, assumptions, market, skills, allocation];
    if (answers.any((controller) => controller.text.trim().isEmpty)) {
      setState(() => error = 'Answer all five questions before completing.');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final now = DateTime.now();
    final start = _quarterStart(now);
    final end = DateTime(start.year, start.month + 3, 0);
    const headings = [
      'Is the current mission still correct?',
      'Which assumptions changed?',
      'What changed in market?',
      'Which skill deserves more/less attention?',
      'Should resource allocation change?',
    ];
    final summary = List.generate(
      headings.length,
      (index) => '${headings[index]}\n${answers[index].text.trim()}',
    ).join('\n\n');
    try {
      await widget.app.save('period_reviews', {
        'id': _reviewId(now),
        'title':
            'Quarterly review — ${now.year} Q${((now.month - 1) ~/ 3) + 1}',
        'type': 'Quarterly',
        'period_start': dateField(start),
        'period_end': dateField(end),
        'summary': summary,
        'evidence_context': widget.app.workspace.activeMission?.title ?? '',
        'next_action': allocation.text.trim(),
        'created_at': now.millisecondsSinceEpoch,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quarterly review saved locally.')),
        );
      }
    } catch (saveError) {
      if (mounted) setState(() => error = 'Could not save review: $saveError');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

class SettingsOverviewScreen extends StatelessWidget {
  final AppController app;
  final String databasePath;
  final Future<void> Function(String path)? onRestore;
  const SettingsOverviewScreen(
    this.app,
    this.databasePath, {
    this.onRestore,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    final boundary = app.intelligenceContext;
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const PageHeading(
          'Settings',
          'A calm home for workspace preferences and controls.',
        ),
        Section(
          'Appearance',
          child: Panel(
            child: DropdownButtonFormField<String>(
              initialValue: app.workspace.settings['theme'] ?? 'system',
              decoration: const InputDecoration(labelText: 'Theme'),
              items: const [
                DropdownMenuItem(value: 'system', child: Text('Follow system')),
                DropdownMenuItem(value: 'light', child: Text('Light')),
                DropdownMenuItem(value: 'dark', child: Text('Dark')),
              ],
              onChanged: (value) => attempt(
                context,
                () => app.save('settings', {'key': 'theme', 'value': value!}),
              ),
            ),
          ),
        ),
        Section(
          'Data',
          child: Panel(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.storage_outlined),
              title: const Text('Local-first workspace'),
              subtitle: const Text(
                'Your core workspace is stored on this device. Backup and restore controls are under Advanced.',
              ),
            ),
          ),
        ),
        Section(
          'Privacy',
          child: Panel(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                boundary.sendsDataOffDevice
                    ? Icons.cloud_outlined
                    : Icons.lock_outline,
              ),
              title: Text(boundary.mode),
              subtitle: Text(boundary.explanation),
            ),
          ),
        ),
        Section(
          'Readiness',
          child: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Readiness uses verified evidence across six weighted dimensions.',
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry
                        in app.workspace.configuredReadinessWeights.entries)
                      Chip(
                        label: Text(
                          '${entry.key} ${(entry.value * 100).round()}%',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Section(
          'Advanced',
          child: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Database path, import/export, diagnostics, readiness weights and personal data controls.',
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => Scaffold(
                          appBar: AppBar(
                            title: const Text('Advanced settings'),
                          ),
                          body: SettingsScreen(
                            app,
                            databasePath,
                            onRestore: onRestore,
                          ),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.tune),
                    label: const Text('Open advanced settings'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
