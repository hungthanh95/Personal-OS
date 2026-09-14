import 'package:flutter/material.dart';
import '../../application/app_controller.dart';
import '../../domain/models.dart';
import '../widgets/common.dart';
import 'record_editor.dart';
import 'career_income_screens.dart';
import 'today_screen.dart';
import 'library_screen.dart';

void openGoal(BuildContext context, AppController app, Goal goal) =>
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DirectionDetail(app: app, id: goal.id, isGoal: true),
      ),
    );
void openProject(BuildContext context, AppController app, Project project) =>
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            DirectionDetail(app: app, id: project.id, isGoal: false),
      ),
    );

class GoalsScreen extends StatelessWidget {
  final AppController app;
  const GoalsScreen(this.app, {super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
          child: PageHeading(
            'Goals',
            'Keep the reason connected to the work.',
            action: FilledButton.icon(
              onPressed: () => editRecord(context, app, 'goals'),
              icon: const Icon(Icons.add),
              label: const Text('New goal'),
            ),
          ),
        ),
        const TabBar(
          tabs: [
            Tab(text: 'All goals'),
            Tab(text: 'Life Map'),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              ListView(
                padding: const EdgeInsets.all(28),
                children: app.workspace.goals.isEmpty
                    ? [
                        EmptyState(
                          'Choose a direction',
                          'Goals connect everyday effort to something that matters.',
                          'Create first goal',
                          () => editRecord(context, app, 'goals'),
                        ),
                      ]
                    : app.workspace.goals
                          .map(
                            (g) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Panel(
                                child: InkWell(
                                  onTap: () => openGoal(context, app, g),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              g.title,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleLarge,
                                            ),
                                          ),
                                          Tag(g.status.name),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(g.text('why')),
                                      const SizedBox(height: 18),
                                      ProgressValue(
                                        app.workspace.goalProgress(g.id),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        '${app.workspace.projects.where((p) => p.goalId == g.id).length} projects · ${app.workspace.areas.where((a) => a.id == g.areaId).firstOrNull?.title ?? 'Unassigned area'}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
              ),
              LifeMap(app),
            ],
          ),
        ),
      ],
    ),
  );
}

class ProjectsScreen extends StatelessWidget {
  final AppController app;
  const ProjectsScreen(this.app, {super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(28),
    children: [
      PageHeading(
        'Projects',
        'Meaningful initiatives, concrete next steps.',
        action: Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => IncomeLabScreen(app)),
              ),
              icon: const Icon(Icons.science_outlined),
              label: const Text('Income Lab'),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => OwnershipCapitalScreen(app),
                ),
              ),
              icon: const Icon(Icons.account_balance_outlined),
              label: const Text('Ownership & Capital'),
            ),
            FilledButton.icon(
              onPressed: () => editRecord(context, app, 'projects'),
              icon: const Icon(Icons.add),
              label: const Text('New project'),
            ),
          ],
        ),
      ),
      if (app.workspace.projects.isEmpty)
        EmptyState(
          'Turn a goal into an initiative',
          'Projects give your ambitions a place to become real.',
          'Create first project',
          () => editRecord(context, app, 'projects'),
        ),
      ...app.workspace.projects.map(
        (p) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: ProjectCard(app, p),
        ),
      ),
    ],
  );
}

class ProjectCard extends StatelessWidget {
  final AppController app;
  final Project project;
  const ProjectCard(this.app, this.project, {super.key});
  @override
  Widget build(BuildContext context) => Panel(
    child: InkWell(
      onTap: () => openProject(context, app, project),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  project.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Tag(project.status.name),
              const SizedBox(width: 8),
              Tag('P${project.priority}'),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            app.workspace.goal(project.goalId)?.title ?? 'No goal linked',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 18),
          const Text('Task execution', style: TextStyle(fontSize: 12)),
          ProgressValue(app.workspace.projectExecutionProgress(project.id)),
          const SizedBox(height: 10),
          const Text('Milestones', style: TextStyle(fontSize: 12)),
          ProgressValue(app.workspace.projectProgress(project.id)),
          const SizedBox(height: 16),
          Text(
            'NEXT  ${project.nextAction.isEmpty ? 'Define your next action' : project.nextAction}',
          ),
        ],
      ),
    ),
  );
}

class DirectionDetail extends StatelessWidget {
  final AppController app;
  final String id;
  final bool isGoal;
  const DirectionDetail({
    required this.app,
    required this.id,
    required this.isGoal,
    super.key,
  });
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: app,
    builder: (context, _) {
      final w = app.workspace;
      final Entity? entity = isGoal ? w.goal(id) : w.project(id);
      if (entity == null) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('This item is no longer available.')),
        );
      }
      final projects = isGoal
          ? w.projects.where((p) => p.goalId == id).toList()
          : [w.project(id)!];
      final ids = projects.map((p) => p.id).toSet();
      final milestones = w.milestones
          .where((m) => ids.contains(m.projectId))
          .toList();
      final sessions =
          w.sessions
              .where(
                (s) => ids.contains(s.projectId) || (isGoal && s.goalId == id),
              )
              .toList()
            ..sort((a, b) => b.plannedStart.compareTo(a.plannedStart));
      final outputs = w.outputs
          .where(
            (o) =>
                ids.contains(o.projectId) ||
                (isGoal &&
                    w.sessions.any(
                      (s) => s.id == o.sessionId && w.sessionGoal(s)?.id == id,
                    )),
          )
          .toList();
      final knowledge = w.knowledge
          .where((k) => ids.contains(k.projectId) || (isGoal && k.goalId == id))
          .toList();
      final pendingMilestone = milestones
          .where((m) => !m.completed)
          .firstOrNull;
      return Scaffold(
        appBar: AppBar(
          title: Text(isGoal ? 'Goal' : 'Project'),
          actions: [
            if (!isGoal)
              TextButton.icon(
                onPressed: () => attempt(
                  context,
                  () => app.openMarkdownRecord('projects', id),
                ),
                icon: const Icon(Icons.description_outlined),
                label: const Text('Open note'),
              ),
            TextButton.icon(
              onPressed: () => editRecord(
                context,
                app,
                isGoal ? 'goals' : 'projects',
                entity: entity,
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: ListView(
              padding: const EdgeInsets.all(28),
              children: [
                PageHeading(
                  entity.title,
                  isGoal
                      ? entity.text('why')
                      : w.goal(w.project(id)?.goalId)?.title ??
                            'No goal linked',
                ),
                if (entity.text('description').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(entity.text('description')),
                  ),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    Tag(entity.text('status')),
                    Tag('P${entity.number('priority', 2)}'),
                    if (entity.at('start_at') != null)
                      Tag('Started ${dateField(entity.at('start_at'))}'),
                    if (entity.at('target_at') != null)
                      Tag('Target ${dateField(entity.at('target_at'))}'),
                  ],
                ),
                const SizedBox(height: 24),
                Section(
                  'Progress',
                  child: Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isGoal)
                          ProgressValue(w.goalProgress(id))
                        else ...[
                          const Text('Task execution'),
                          ProgressValue(w.projectExecutionProgress(id)),
                          const SizedBox(height: 12),
                          const Text('Milestone progress'),
                          ProgressValue(w.projectProgress(id)),
                        ],
                        const SizedBox(height: 18),
                        Text(
                          'NEXT MILESTONE  ${pendingMilestone?.title ?? 'Define the next meaningful milestone'}',
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isGoal)
                  Section(
                    'NEXT ACTION',
                    child: Panel(
                      child: Text(
                        w.project(id)!.nextAction.isEmpty
                            ? 'Add a concrete next action using Edit.'
                            : w.project(id)!.nextAction,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                if (isGoal)
                  Section(
                    'Related projects',
                    trailing: TextButton(
                      onPressed: () => editRecord(
                        context,
                        app,
                        'projects',
                        initial: {'goal_id': id},
                      ),
                      child: const Text('Add project'),
                    ),
                    child: projects.isEmpty
                        ? const Text(
                            'Create a project to connect this goal to execution.',
                          )
                        : Column(
                            children: projects
                                .map(
                                  (p) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: ProjectCard(app, p),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                if (!isGoal)
                  Section(
                    'Milestones & experiments',
                    trailing: TextButton(
                      onPressed: () => editRecord(
                        context,
                        app,
                        'milestones',
                        initial: {'project_id': id},
                      ),
                      child: const Text('Add milestone'),
                    ),
                    child: milestones.isEmpty
                        ? const Text(
                            'Define an observable result. Progress will follow completed milestones.',
                          )
                        : Panel(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: milestones
                                  .map(
                                    (m) => CheckboxListTile(
                                      value: m.completed,
                                      onChanged: (done) => attempt(
                                        context,
                                        () => app.save(
                                          'milestones',
                                          m.patch({
                                            'completed_at': done!
                                                ? DateTime.now()
                                                      .millisecondsSinceEpoch
                                                : null,
                                          }),
                                        ),
                                      ),
                                      title: Text(m.title),
                                      subtitle: Text(
                                        '${m.text('kind')}${m.text('description').isEmpty ? '' : ' · ${m.text('description')}'}',
                                      ),
                                      secondary: IconButton(
                                        tooltip: 'Edit milestone',
                                        onPressed: () => editRecord(
                                          context,
                                          app,
                                          'milestones',
                                          entity: m,
                                        ),
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                  ),
                if (!isGoal)
                  Section(
                    'Tasks',
                    trailing: TextButton(
                      onPressed: () => editRecord(
                        context,
                        app,
                        'tasks',
                        initial: {'project_id': id},
                      ),
                      child: const Text('Add task'),
                    ),
                    child: Column(
                      children: [
                        if (!w.tasks.any((t) => t.ref('project_id') == id))
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Use tasks for small steps; plan sessions for scheduled execution.',
                            ),
                          ),
                        ...w.tasks
                            .where((t) => t.ref('project_id') == id)
                            .map(
                              (t) => CheckboxListTile(
                                value: t.done,
                                onChanged: (done) => attempt(
                                  context,
                                  () => app.save(
                                    'tasks',
                                    t.patch({
                                      'status': done! ? 'Done' : 'Backlog',
                                    }),
                                  ),
                                ),
                                title: Text(t.title),
                                subtitle: Text(
                                  '${t.text('status')} · P${t.number('priority', 2)}${t.text('description').isEmpty ? '' : '\n${t.text('description')}'}',
                                ),
                                secondary: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Open task note',
                                      onPressed: () => attempt(
                                        context,
                                        () => app.openMarkdownRecord(
                                          'tasks',
                                          t.id,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.description_outlined,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Edit task',
                                      onPressed: () => editRecord(
                                        context,
                                        app,
                                        'tasks',
                                        entity: t,
                                      ),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                Section(
                  'Sessions',
                  trailing: TextButton(
                    onPressed: () => editRecord(
                      context,
                      app,
                      'sessions',
                      initial: {isGoal ? 'goal_id' : 'project_id': id},
                    ),
                    child: const Text('Plan session'),
                  ),
                  child: sessions.isEmpty
                      ? const Text(
                          'Schedule a session to move this initiative forward.',
                        )
                      : Column(
                          children: sessions
                              .map(
                                (s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: SessionTile(app, s),
                                ),
                              )
                              .toList(),
                        ),
                ),
                Section(
                  'Recent outputs',
                  trailing: !isGoal
                      ? TextButton(
                          onPressed: () => editRecord(
                            context,
                            app,
                            'outputs',
                            initial: {'project_id': id},
                          ),
                          child: const Text('Record output'),
                        )
                      : null,
                  child: outputs.isEmpty
                      ? const Text(
                          'Outputs are evidence of progress. Record a concrete result after a session.',
                        )
                      : Column(
                          children: outputs
                              .map((o) => EvidenceTile(app, o))
                              .toList(),
                        ),
                ),
                Section(
                  'Knowledge',
                  trailing: TextButton(
                    onPressed: () => editRecord(
                      context,
                      app,
                      'knowledge',
                      initial: {isGoal ? 'goal_id' : 'project_id': id},
                    ),
                    child: const Text('Create note'),
                  ),
                  child: knowledge.isEmpty
                      ? const Text('Capture something worth remembering.')
                      : Column(
                          children: knowledge
                              .map((k) => EvidenceTile(app, k))
                              .toList(),
                        ),
                ),
                if (!isGoal)
                  Section(
                    'Activity timeline',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Created ${dayLabel(entity.createdAt)}'),
                        ...sessions
                            .where(
                              (s) =>
                                  s.status == SessionStatus.done &&
                                  (s.confirmedAt ?? s.at('actual_end')) != null,
                            )
                            .take(8)
                            .map(
                              (s) => Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  '${dayLabel(s.confirmedAt ?? s.at('actual_end')!)} · ${s.status.label} · ${s.title}',
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                Section(
                  'Personal insights',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final insight in app.insights.where(
                        (i) => i.goalId == id || ids.contains(i.projectId),
                      ))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(insight.message),
                        ),
                      const Text(
                        'Keep your next action small enough to start.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class LifeMap extends StatelessWidget {
  final AppController app;
  const LifeMap(this.app, {super.key});
  @override
  Widget build(BuildContext context) {
    final w = app.workspace;
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const Text('Life area → Goal → Project → Milestone / Experiment'),
        const SizedBox(height: 20),
        ...[...w.areas.map((a) => (a.id, a.title)), ('', 'Unassigned')]
            .where(
              (a) =>
                  a.$1.isNotEmpty ||
                  w.goals.any((g) => g.areaId == null) ||
                  w.projects.any((p) => p.goalId == null),
            )
            .map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Panel(
                  padding: const EdgeInsets.all(10),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    title: Text(
                      a.$2,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    children: [
                      ...w.goals
                          .where((g) => (g.areaId ?? '') == a.$1)
                          .map(
                            (g) => ExpansionTile(
                              title: Text(g.title),
                              leading: const Icon(Icons.flag_outlined),
                              trailing: IconButton(
                                tooltip: 'Open goal',
                                onPressed: () => openGoal(context, app, g),
                                icon: const Icon(Icons.arrow_outward, size: 18),
                              ),
                              children: w.projects
                                  .where((p) => p.goalId == g.id)
                                  .map((p) => _project(context, p))
                                  .toList(),
                            ),
                          ),
                      if (a.$1 == '')
                        ...w.projects
                            .where((p) => p.goalId == null)
                            .map((p) => _project(context, p)),
                      if (!w.goals.any((g) => g.areaId == a.$1) && a.$1 != '')
                        const ListTile(
                          title: Text('No goals in this area yet.'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }

  Widget _project(BuildContext context, Project p) => Padding(
    padding: const EdgeInsets.only(left: 20),
    child: ExpansionTile(
      title: Text(p.title),
      leading: const Icon(Icons.folder_outlined),
      trailing: IconButton(
        tooltip: 'Open project',
        onPressed: () => openProject(context, app, p),
        icon: const Icon(Icons.arrow_outward, size: 18),
      ),
      children: app.workspace.milestones
          .where((m) => m.projectId == p.id)
          .map(
            (m) => ListTile(
              contentPadding: const EdgeInsets.only(left: 40),
              leading: Icon(
                m.completed
                    ? Icons.check_circle_outline
                    : m.text('kind') == 'experiment'
                    ? Icons.science_outlined
                    : Icons.radio_button_unchecked,
                size: 18,
              ),
              title: Text(m.title),
              subtitle: Text(m.text('kind')),
            ),
          )
          .toList(),
    ),
  );
}
