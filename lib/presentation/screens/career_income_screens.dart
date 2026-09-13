import 'package:flutter/material.dart';

import '../../application/app_controller.dart';
import '../../domain/career.dart';
import '../../domain/models.dart';
import '../widgets/common.dart';
import 'record_editor.dart';
import 'strategy_screens.dart';

class CareerWorkspaceScreen extends StatelessWidget {
  final AppController app;
  final String missionId;

  const CareerWorkspaceScreen(this.app, this.missionId, {super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Career workspace')),
    body: ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final w = app.workspace;
        final mission = w.record('missions', missionId);
        if (mission == null) {
          return const Center(child: Text('Mission is no longer available.'));
        }
        final jobs = w
            .records('jobs')
            .where((job) => job.ref('mission_id') == missionId)
            .toList();
        final demands = skillDemandForMission(w, missionId);
        final priorities = w
            .records('learning_priorities')
            .where((priority) => priority.ref('mission_id') == missionId)
            .toList();
        final jobIds = jobs.map((job) => job.id).toSet();
        final applications = w
            .records('applications')
            .where((application) => jobIds.contains(application.ref('job_id')))
            .toList();
        final applicationIds = applications.map((item) => item.id).toSet();
        final interviews = w
            .records('interviews')
            .where(
              (interview) =>
                  applicationIds.contains(interview.ref('application_id')),
            )
            .toList();
        final interviewedApplications = {
          ...interviews.map((interview) => interview.ref('application_id')),
          ...applications
              .where(
                (application) =>
                    ['Interview', 'Offer'].contains(application.text('status')),
              )
              .map((application) => application.id),
        }..remove(null);
        final offers = applications
            .where((application) => application.text('status') == 'Offer')
            .length;
        final appliedJobs = applications
            .map((application) => application.ref('job_id'))
            .whereType<String>()
            .toSet()
            .length;
        final salaryJobs = jobs
            .where(
              (job) =>
                  job.data['salary_min'] != null ||
                  job.data['salary_max'] != null,
            )
            .toList();
        final weaknesses = <String, int>{};
        for (final interview in interviews) {
          for (final term
              in interview
                  .text('weaknesses')
                  .split(RegExp(r'[,;\n]'))
                  .map((term) => term.trim())
                  .where((term) => term.isNotEmpty)) {
            weaknesses.update(term, (count) => count + 1, ifAbsent: () => 1);
          }
        }
        final weaknessEntries = weaknesses.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return ListView(
          padding: const EdgeInsets.all(28),
          children: [
            PageHeading(
              mission.title,
              'Market demand → interview evidence → learning priorities',
              action: FilledButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => _JobImportDialog(app, missionId),
                ),
                icon: const Icon(Icons.content_paste_go_outlined),
                label: const Text('Paste job descriptions'),
              ),
            ),
            Section(
              'Skill demand vs readiness',
              trailing: Text('${jobs.length} jobs analyzed'),
              child: Panel(
                child: demands.isEmpty
                    ? const Text(
                        'Add skills to the mission, then paste job descriptions.',
                      )
                    : Column(
                        children: [
                          for (final demand in demands)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text(demand.skill.title)),
                                      Text(
                                        '${demand.jobCount}/${demand.totalJobs} jobs · ${demand.readiness.round()}% ready',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 7),
                                  LinearProgressIndicator(value: demand.demand),
                                  if (demand.jobCount > 0 &&
                                      demand.readiness < 70)
                                    Text(
                                      'Priority gap ${(demand.priorityGap).round()} · local rule: frequent demand with lower readiness ranks first.',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            Section(
              'Job pipeline',
              trailing: TextButton(
                onPressed: () => editStrategyRecord(
                  context,
                  app,
                  'jobs',
                  initial: {'mission_id': missionId},
                ),
                child: const Text('Add job manually'),
              ),
              child: jobs.isEmpty
                  ? const Panel(
                      child: Text(
                        'Separate pasted jobs with a line containing ---. Add optional “Title:” and “Company:” lines to preserve those fields.',
                      ),
                    )
                  : Column(
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _MetricCard('Jobs', jobs.length),
                            for (final status in [
                              'Applied',
                              'Screening',
                              'Interview',
                              'Offer',
                            ])
                              _MetricCard(
                                status,
                                applications
                                    .where(
                                      (application) =>
                                          application.text('status') == status,
                                    )
                                    .length,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...jobs.map((job) => _JobCard(app, missionId, job)),
                      ],
                    ),
            ),
            Section(
              'Career funnel and market signals',
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _FunnelMetric(
                          label: 'Job → application',
                          numerator: appliedJobs,
                          denominator: jobs.length,
                        ),
                        _FunnelMetric(
                          label: 'Application → interview',
                          numerator: interviewedApplications.length,
                          denominator: applications.length,
                        ),
                        _FunnelMetric(
                          label: 'Interview → offer',
                          numerator: offers,
                          denominator: interviewedApplications.length,
                        ),
                        _FunnelMetric(
                          label: 'Interview pass',
                          numerator: interviews
                              .where(
                                (interview) =>
                                    interview.text('result') == 'Pass',
                              )
                              .length,
                          denominator: interviews
                              .where(
                                (interview) =>
                                    interview.text('result') != 'Pending',
                              )
                              .length,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      salaryJobs.isEmpty
                          ? 'Salary sample: no ranges recorded.'
                          : 'Salary sample: ${salaryJobs.length} job${salaryJobs.length == 1 ? '' : 's'} · ${_salaryRange(salaryJobs)}. Compare only jobs using the same currency and period.',
                    ),
                    const SizedBox(height: 10),
                    Text(
                      weaknessEntries.isEmpty
                          ? 'Interview weakness clusters: no structured weakness notes yet.'
                          : 'Interview weakness clusters: ${weaknessEntries.take(5).map((entry) => '${entry.key} (${entry.value})').join(' · ')}.',
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Role clusters: ${_topCounts(jobs, 'seniority')} · domains: ${_topCounts(jobs, 'domain')} · companies: ${_topCounts(jobs, 'company')}.',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Percentages show observed records only. Small samples are displayed rather than treated as certainty.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            Section(
              'Learning priorities from interviews',
              child: priorities.isEmpty
                  ? const Panel(
                      child: Text(
                        'Failed or partial interview questions can be converted into traceable learning priorities.',
                      ),
                    )
                  : Column(
                      children: priorities
                          .map(
                            (priority) => Card(
                              child: ListTile(
                                title: Text(priority.title),
                                subtitle: Text(
                                  '${priority.text('status')} · ${priority.text('reason')}',
                                ),
                                trailing: IconButton(
                                  tooltip: 'Plan a session from this priority',
                                  onPressed: () => editRecord(
                                    context,
                                    app,
                                    'sessions',
                                    initial: {
                                      'title': priority.title,
                                      'why': priority.text('reason'),
                                      'priority': 1,
                                    },
                                  ),
                                  icon: const Icon(
                                    Icons.event_available_outlined,
                                  ),
                                ),
                                onTap: () => editStrategyRecord(
                                  context,
                                  app,
                                  'learning_priorities',
                                  record: priority,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        );
      },
    ),
  );

  String _salaryRange(List<StrategyRecord> jobs) {
    final currencies = jobs
        .map((job) => job.text('currency'))
        .where((currency) => currency.isNotEmpty)
        .toSet();
    if (currencies.length > 1) return 'mixed currencies';
    final lows = jobs
        .map((job) => job.data['salary_min'] ?? job.data['salary_max'])
        .whereType<num>()
        .map((value) => value.toDouble())
        .toList();
    final highs = jobs
        .map((job) => job.data['salary_max'] ?? job.data['salary_min'])
        .whereType<num>()
        .map((value) => value.toDouble())
        .toList();
    if (lows.isEmpty || highs.isEmpty) return 'incomplete ranges';
    final low = lows.reduce((a, b) => a + b) / lows.length;
    final high = highs.reduce((a, b) => a + b) / highs.length;
    final currency = currencies.firstOrNull ?? '';
    return 'average ${low.toStringAsFixed(0)}–${high.toStringAsFixed(0)} $currency';
  }

  String _topCounts(List<StrategyRecord> jobs, String field) {
    final counts = <String, int>{};
    for (final job in jobs) {
      final value = job.text(field).trim();
      if (value.isNotEmpty) {
        counts.update(value, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.isEmpty
        ? 'no data'
        : sorted
              .take(4)
              .map((entry) => '${entry.key} (${entry.value})')
              .join(', ');
  }
}

class _JobCard extends StatelessWidget {
  final AppController app;
  final String missionId;
  final StrategyRecord job;

  const _JobCard(this.app, this.missionId, this.job);

  @override
  Widget build(BuildContext context) {
    final w = app.workspace;
    final applications = w
        .records('applications')
        .where((application) => application.ref('job_id') == job.id)
        .toList();
    final requirements = w
        .records('job_requirements')
        .where((requirement) => requirement.ref('job_id') == job.id)
        .toList();
    return Card(
      child: ExpansionTile(
        title: Text(job.title),
        subtitle: Text(
          '${job.text('company').isEmpty ? 'Company not set' : job.text('company')} · ${job.text('status')}${_salary(job)}${job.text('domain').isEmpty ? '' : ' · ${job.text('domain')}'}${job.text('seniority').isEmpty ? '' : ' · ${job.text('seniority')}'} · ${requirements.isEmpty ? 'No mission skill detected' : requirements.map(_requirementLabel).join(', ')}',
        ),
        children: [
          if (job.text('description').isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(job.text('description')),
            ),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: () =>
                    editStrategyRecord(context, app, 'jobs', record: job),
                child: const Text('Edit job'),
              ),
              TextButton(
                onPressed: () => editStrategyRecord(
                  context,
                  app,
                  'applications',
                  initial: {'job_id': job.id},
                ),
                child: const Text('Add application'),
              ),
            ],
          ),
          for (final application in applications)
            _ApplicationTile(app, missionId, application),
        ],
      ),
    );
  }

  String _salary(StrategyRecord job) {
    final minimum = job.data['salary_min'];
    final maximum = job.data['salary_max'];
    if (minimum == null && maximum == null) return '';
    final range = minimum != null && maximum != null
        ? '$minimum–$maximum'
        : '${minimum ?? maximum}';
    return ' · $range ${job.text('currency')}'.trimRight();
  }

  String _requirementLabel(StrategyRecord requirement) {
    final years = requirement.data['years_required'] as num?;
    return '${requirement.text('skill_name')} (${requirement.text('requirement_type')}${years == null ? '' : ', ${years.toString()}y'})';
  }
}

class _ApplicationTile extends StatelessWidget {
  final AppController app;
  final String missionId;
  final StrategyRecord application;

  const _ApplicationTile(this.app, this.missionId, this.application);

  @override
  Widget build(BuildContext context) {
    final interviews = app.workspace
        .records('interviews')
        .where((interview) => interview.ref('application_id') == application.id)
        .toList();
    return ExpansionTile(
      leading: const Icon(Icons.work_outline),
      title: Text('Application · ${application.text('status')}'),
      subtitle: Text(application.text('notes')),
      children: [
        Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: () => editStrategyRecord(
                context,
                app,
                'applications',
                record: application,
              ),
              child: const Text('Update application'),
            ),
            TextButton(
              onPressed: () => editStrategyRecord(
                context,
                app,
                'interviews',
                initial: {'application_id': application.id},
              ),
              child: const Text('Add interview'),
            ),
          ],
        ),
        for (final interview in interviews)
          _InterviewTile(app, missionId, interview),
      ],
    );
  }
}

class _InterviewTile extends StatelessWidget {
  final AppController app;
  final String missionId;
  final StrategyRecord interview;

  const _InterviewTile(this.app, this.missionId, this.interview);

  @override
  Widget build(BuildContext context) {
    final questions = app.workspace
        .records('interview_questions')
        .where((question) => question.ref('interview_id') == interview.id)
        .toList();
    return ExpansionTile(
      title: Text(
        '${interview.text('round').isEmpty ? 'Interview' : interview.text('round')} · ${interview.text('result')}',
      ),
      subtitle: Text(
        '${interview.text('date')} ${interview.text('weaknesses')}'.trim(),
      ),
      children: [
        Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: () => editStrategyRecord(
                context,
                app,
                'interviews',
                record: interview,
              ),
              child: const Text('Edit interview'),
            ),
            TextButton(
              onPressed: () => editStrategyRecord(
                context,
                app,
                'interview_questions',
                initial: {'interview_id': interview.id},
              ),
              child: const Text('Add question'),
            ),
          ],
        ),
        for (final question in questions)
          ListTile(
            title: Text(question.title),
            subtitle: Text(
              '${question.text('result')} · ${question.text('notes')}',
            ),
            trailing:
                ['Fail', 'Partial'].contains(question.text('result')) &&
                    question.data['converted_at'] == null
                ? FilledButton.tonal(
                    onPressed: () async {
                      try {
                        await app.convertInterviewQuestionToPriority(
                          question.id,
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('$e')));
                        }
                      }
                    },
                    child: const Text('Make priority'),
                  )
                : question.data['converted_at'] != null
                ? const Tag('Priority created')
                : null,
            onTap: () => editStrategyRecord(
              context,
              app,
              'interview_questions',
              record: question,
            ),
          ),
      ],
    );
  }
}

class _JobImportDialog extends StatefulWidget {
  final AppController app;
  final String missionId;

  const _JobImportDialog(this.app, this.missionId);

  @override
  State<_JobImportDialog> createState() => _JobImportDialogState();
}

class _JobImportDialogState extends State<_JobImportDialog> {
  final controller = TextEditingController();
  bool saving = false;
  String? error;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Paste job descriptions'),
    content: SizedBox(
      width: 700,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Separate jobs with a line containing ---. Optional first lines: “Title:” and “Company:”. Matching uses only skills already linked to this mission; review the detected demand after import.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            minLines: 12,
            maxLines: 20,
            decoration: const InputDecoration(
              hintText:
                  'Title: Embedded Linux Engineer\nCompany: Example\nC++, Linux, networking...\n---\nTitle: Systems Engineer\n...',
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: saving
            ? null
            : () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                setState(() {
                  saving = true;
                  error = null;
                });
                try {
                  final count = await widget.app.importJobDescriptions(
                    widget.missionId,
                    controller.text,
                  );
                  if (mounted) {
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(content: Text('$count jobs imported locally.')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() {
                      error = '$e';
                      saving = false;
                    });
                  }
                }
              },
        child: Text(saving ? 'Importing…' : 'Import'),
      ),
    ],
  );
}

class IncomeLabScreen extends StatelessWidget {
  final AppController app;

  const IncomeLabScreen(this.app, {super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Income Lab')),
    body: ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final experiments = app.workspace.records('experiments').toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final active = experiments
            .where(
              (experiment) =>
                  !['Complete', 'Killed'].contains(experiment.text('status')),
            )
            .length;
        final promising = experiments
            .where(
              (experiment) => [
                'Promising',
                'Strong',
                'Revenue',
              ].contains(experiment.text('signal')),
            )
            .length;
        return ListView(
          padding: const EdgeInsets.all(28),
          children: [
            PageHeading(
              'Income Lab',
              'Idea → Research → Hypothesis → Experiment → Signal → Decision',
              action: FilledButton.icon(
                onPressed: () =>
                    editStrategyRecord(context, app, 'experiments'),
                icon: const Icon(Icons.science_outlined),
                label: const Text('New experiment'),
              ),
            ),
            if (experiments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricCard('Experiments', experiments.length),
                    _MetricCard('Active', active),
                    _MetricCard('Promising+', promising),
                    _MetricCard(
                      'Killed',
                      experiments
                          .where(
                            (experiment) =>
                                experiment.text('status') == 'Killed',
                          )
                          .length,
                    ),
                  ],
                ),
              ),
            if (experiments.isEmpty)
              const Panel(
                child: Text(
                  'Run a bounded market experiment. Every live experiment needs a concrete next action; otherwise explicitly kill it.',
                ),
              ),
            for (final experiment in experiments)
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(18),
                  title: Text(experiment.title),
                  subtitle: Text(
                    'Hypothesis: ${experiment.text('hypothesis')}\nExperiment: ${experiment.text('experiment')}\nResult: ${experiment.text('result')}\nNext: ${experiment.text('next_action')}',
                  ),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Tag(experiment.text('signal')),
                      Text(experiment.text('status')),
                    ],
                  ),
                  onTap: () => editStrategyRecord(
                    context,
                    app,
                    'experiments',
                    record: experiment,
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class OwnershipCapitalScreen extends StatelessWidget {
  final AppController app;

  const OwnershipCapitalScreen(this.app, {super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ownership & Capital')),
    body: ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final workspace = app.workspace;
        final allocations = workspace.records('engine_allocations');
        final discoveries = workspace.records('customer_discoveries').toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final revenue = workspace.records('revenue_entries').toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final distribution = workspace.records('distribution_events').toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final capital = workspace.records('capital_contributions').toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final netWorth = workspace.records('net_worth_snapshots').toList()
          ..sort(
            (a, b) => (b.data['observed_at'] as int).compareTo(
              a.data['observed_at'] as int,
            ),
          );
        final revenueTotal = revenue.fold<double>(
          0,
          (sum, record) => sum + (record.data['amount'] as num).toDouble(),
        );
        final netContributions = capital.fold<double>(0, (sum, record) {
          final amount = (record.data['amount'] as num).toDouble();
          return sum + (record.text('type') == 'Withdrawal' ? -amount : amount);
        });
        final latestNetWorth = netWorth.firstOrNull;
        return ListView(
          padding: const EdgeInsets.all(28),
          children: [
            const PageHeading(
              'Ownership & Capital',
              'Review engine allocation, product signals and manually recorded wealth trajectory.',
            ),
            Section(
              'Engine allocation',
              trailing: TextButton(
                onPressed: () =>
                    editStrategyRecord(context, app, 'engine_allocations'),
                child: const Text('Set engine'),
              ),
              child: allocations.isEmpty
                  ? const Panel(
                      child: Text(
                        'Define Career, Ownership and Capital modes with weekly budgets. Review changes before updating an allocation.',
                      ),
                    )
                  : Panel(
                      child: Column(
                        children: [
                          for (final allocation in allocations)
                            ListTile(
                              leading: Icon(switch (allocation.text('engine')) {
                                'Career' => Icons.work_outline,
                                'Ownership' => Icons.rocket_launch_outlined,
                                _ => Icons.savings_outlined,
                              }),
                              title: Text(allocation.text('engine')),
                              subtitle: Text(
                                '${allocation.number('weekly_budget_min')}–${allocation.number('weekly_budget_max')} min/week · ${allocation.text('current_objective').isEmpty ? 'No current objective' : allocation.text('current_objective')}',
                              ),
                              trailing: Tag(allocation.text('mode')),
                              onTap: () => editStrategyRecord(
                                context,
                                app,
                                'engine_allocations',
                                record: allocation,
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
            Section(
              'Ownership signals',
              child: Column(
                children: [
                  Panel(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _MetricCard('Discoveries', discoveries.length),
                        _MetricCard(
                          'Strong signals',
                          discoveries
                              .where(
                                (item) => [
                                  'Promising',
                                  'Strong',
                                ].contains(item.text('signal')),
                              )
                              .length,
                        ),
                        _MetricCard('Distribution', distribution.length),
                        _MetricCard(
                          'Leads',
                          distribution.fold(
                            0,
                            (sum, item) => sum + item.number('leads'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Panel(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () => editStrategyRecord(
                            context,
                            app,
                            'customer_discoveries',
                          ),
                          icon: const Icon(Icons.forum_outlined),
                          label: const Text('Log discovery'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => editStrategyRecord(
                            context,
                            app,
                            'revenue_entries',
                          ),
                          icon: const Icon(Icons.payments_outlined),
                          label: const Text('Log revenue'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => editStrategyRecord(
                            context,
                            app,
                            'distribution_events',
                          ),
                          icon: const Icon(Icons.campaign_outlined),
                          label: const Text('Log distribution'),
                        ),
                      ],
                    ),
                  ),
                  for (final discovery in discoveries.take(8))
                    Card(
                      child: ListTile(
                        title: Text(discovery.text('problem')),
                        subtitle: Text(
                          '${discovery.text('segment')} · Evidence: ${discovery.text('evidence')}\nNext: ${discovery.text('next_action')}',
                        ),
                        trailing: Tag(discovery.text('signal')),
                        onTap: () => editStrategyRecord(
                          context,
                          app,
                          'customer_discoveries',
                          record: discovery,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Section(
              'Capital trajectory',
              child: Column(
                children: [
                  Panel(
                    child: Wrap(
                      spacing: 24,
                      runSpacing: 12,
                      children: [
                        _ValueMetric(
                          label: 'Recorded revenue',
                          value: revenueTotal,
                          suffix: revenue.firstOrNull?.text('currency') ?? '',
                        ),
                        _ValueMetric(
                          label: 'Net contributions',
                          value: netContributions,
                          suffix: capital.firstOrNull?.text('currency') ?? '',
                        ),
                        _ValueMetric(
                          label: 'Latest net worth',
                          value: latestNetWorth == null
                              ? null
                              : (latestNetWorth.data['value'] as num)
                                    .toDouble(),
                          suffix: latestNetWorth?.text('currency') ?? '',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Panel(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () => editStrategyRecord(
                            context,
                            app,
                            'capital_contributions',
                          ),
                          icon: const Icon(Icons.add_card_outlined),
                          label: const Text('Log contribution'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => editStrategyRecord(
                            context,
                            app,
                            'net_worth_snapshots',
                          ),
                          icon: const Icon(Icons.show_chart),
                          label: const Text('Record net worth'),
                        ),
                      ],
                    ),
                  ),
                  for (final snapshot in netWorth.take(6))
                    ListTile(
                      title: Text(
                        '${(snapshot.data['value'] as num).toStringAsFixed(2)} ${snapshot.text('currency')}',
                      ),
                      subtitle: Text(
                        '${dateField(snapshot.at('observed_at'))} · ${snapshot.text('source')}',
                      ),
                      onTap: () => editStrategyRecord(
                        context,
                        app,
                        'net_worth_snapshots',
                        record: snapshot,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _ValueMetric extends StatelessWidget {
  final String label;
  final double? value;
  final String suffix;

  const _ValueMetric({
    required this.label,
    required this.value,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 190,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value == null ? '—' : '${value!.toStringAsFixed(2)} $suffix',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(label),
      ],
    ),
  );
}

class _FunnelMetric extends StatelessWidget {
  final String label;
  final int numerator;
  final int denominator;

  const _FunnelMetric({
    required this.label,
    required this.numerator,
    required this.denominator,
  });

  @override
  Widget build(BuildContext context) {
    final percent = denominator == 0 ? null : numerator / denominator * 100;
    return Container(
      width: 190,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            percent == null ? '—' : '${percent.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(label),
          Text(
            '$numerator / $denominator observed',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final int value;

  const _MetricCard(this.label, this.value);

  @override
  Widget build(BuildContext context) => Container(
    width: 128,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$value', style: Theme.of(context).textTheme.headlineSmall),
        Text(label),
      ],
    ),
  );
}
