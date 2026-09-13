import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../../application/app_controller.dart';
import '../../domain/models.dart';
import '../widgets/common.dart';
import 'career_income_screens.dart';
import 'direction_screens.dart';
import 'review_screen.dart';
import 'trajectory_screen.dart';
import 'strategy_map_screen.dart';

const fields = <String, List<String>>{
  'visions': ['title', 'description', 'target_date'],
  'horizons': [
    'title',
    'vision_id',
    'description',
    'start_date',
    'end_date',
    'status',
    'sort_order',
  ],
  'strategies': [
    'title',
    'vision_id',
    'horizon_id',
    'description',
    'engine',
    'allocation',
    'priority',
    'status',
    'effective_from',
    'effective_to',
  ],
  'missions': [
    'title',
    'strategy_id',
    'goal_id',
    'description',
    'success_criteria',
    'status',
    'priority',
    'confidence',
    'start_date',
    'target_date',
  ],
  'outcomes': [
    'title',
    'mission_id',
    'target',
    'current_value',
    'unit',
    'weight',
    'status',
  ],
  'initiatives': [
    'title',
    'mission_id',
    'outcome_id',
    'description',
    'status',
    'priority',
    'weekly_budget_minutes',
  ],
  'skills': ['title', 'mission_id'],
  'evidence': [
    'title',
    'skill_id',
    'output_id',
    'type',
    'dimension',
    'score',
    'verified',
    'confidence',
    'description',
    'source',
    'source_uri',
  ],
  'assumptions': [
    'title',
    'strategy_id',
    'status',
    'confidence',
    'evidence_context',
  ],
  'strategy_proposals': [
    'title',
    'strategy_id',
    'description',
    'reason',
    'engine',
    'allocation',
    'evidence_context',
    'confidence',
  ],
  'period_reviews': [
    'title',
    'type',
    'period_start',
    'period_end',
    'summary',
    'evidence_context',
    'next_action',
  ],
  'jobs': [
    'title',
    'mission_id',
    'company',
    'location',
    'domain',
    'seniority',
    'employment_type',
    'salary_min',
    'salary_max',
    'currency',
    'source_url',
    'status',
    'fit_score',
    'description',
  ],
  'applications': ['job_id', 'status', 'applied_at', 'notes'],
  'interviews': [
    'application_id',
    'date',
    'round',
    'result',
    'strengths',
    'weaknesses',
    'new_learning_priorities',
  ],
  'interview_questions': [
    'title',
    'interview_id',
    'skill_id',
    'result',
    'notes',
  ],
  'learning_priorities': [
    'title',
    'mission_id',
    'skill_id',
    'reason',
    'status',
  ],
  'experiments': [
    'title',
    'project_id',
    'hypothesis',
    'market',
    'time_budget',
    'status',
    'input',
    'experiment',
    'result',
    'signal',
    'next_action',
  ],
  'session_templates': [
    'title',
    'project_id',
    'goal_id',
    'milestone_id',
    'why',
    'input',
    'target',
    'priority',
    'planned_minutes',
  ],
  'recurring_schedules': [
    'title',
    'template_id',
    'weekdays',
    'local_time',
    'enabled',
    'start_date',
    'end_date',
  ],
  'recommendations': [
    'title',
    'type',
    'reason',
    'fact_basis',
    'inference',
    'expected_benefit',
    'risk',
    'confidence',
    'suggested_action',
    'status',
    'requires_user_approval',
  ],
  'metrics': ['title', 'category', 'unit', 'direction', 'target_value'],
  'metric_snapshots': [
    'metric_id',
    'value',
    'source',
    'source_uri',
    'confidence',
    'observed_at',
    'notes',
  ],
  'strategy_events': [
    'title',
    'type',
    'description',
    'impact',
    'occurred_at',
    'review_recommended',
  ],
  'engine_allocations': [
    'engine',
    'mode',
    'weekly_budget_min',
    'weekly_budget_max',
    'current_objective',
    'effective_from',
  ],
  'customer_discoveries': [
    'project_id',
    'contact',
    'segment',
    'problem',
    'evidence',
    'signal',
    'next_action',
    'happened_at',
  ],
  'revenue_entries': [
    'project_id',
    'amount',
    'currency',
    'source',
    'occurred_at',
    'notes',
  ],
  'distribution_events': [
    'project_id',
    'channel',
    'kind',
    'reach',
    'leads',
    'occurred_at',
    'notes',
  ],
  'capital_contributions': [
    'account',
    'amount',
    'currency',
    'type',
    'occurred_at',
    'notes',
  ],
  'net_worth_snapshots': [
    'value',
    'currency',
    'observed_at',
    'source',
    'notes',
  ],
};
const references = {
  'vision_id': 'visions',
  'horizon_id': 'horizons',
  'strategy_id': 'strategies',
  'mission_id': 'missions',
  'outcome_id': 'outcomes',
  'skill_id': 'skills',
  'goal_id': 'goals',
  'output_id': 'outputs',
  'project_id': 'projects',
  'job_id': 'jobs',
  'application_id': 'applications',
  'interview_id': 'interviews',
  'milestone_id': 'milestones',
  'template_id': 'session_templates',
  'metric_id': 'metrics',
};

Future<void> editStrategyRecord(
  BuildContext context,
  AppController app,
  String table, {
  StrategyRecord? record,
  DataRowMap initial = const {},
}) => showDialog<void>(
  context: context,
  builder: (_) => _Editor(app, table, record, initial),
);

class _Editor extends StatefulWidget {
  final AppController app;
  final String table;
  final StrategyRecord? record;
  final DataRowMap initial;
  const _Editor(this.app, this.table, this.record, this.initial);
  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  final form = GlobalKey<FormState>();
  final controllers = <String, TextEditingController>{};
  final selected = <String, String?>{};
  bool saving = false;
  String? error;
  bool optionalReference(String key) =>
      key == 'goal_id' ||
      key == 'horizon_id' ||
      (key == 'outcome_id' && widget.table == 'initiatives') ||
      (key == 'project_id' &&
          ['experiments', 'session_templates'].contains(widget.table)) ||
      (key == 'milestone_id' && widget.table == 'session_templates') ||
      (key == 'skill_id' &&
          [
            'interview_questions',
            'learning_priorities',
          ].contains(widget.table));
  List<Entity> choices(String key) {
    final w = widget.app.workspace;
    return switch (references[key]) {
      'goals' => w.goals,
      'outputs' => w.outputs,
      'projects' => w.projects,
      'milestones' =>
        w.milestones
            .where((milestone) => milestone.projectId == selected['project_id'])
            .toList(),
      'outcomes' =>
        w
            .records('outcomes')
            .where(
              (outcome) =>
                  selected['mission_id'] == null ||
                  outcome.ref('mission_id') == selected['mission_id'],
            )
            .toList(),
      final String table => w.records(table),
      _ => [],
    };
  }

  List<String>? options(String key) => switch (key) {
    'engine' => [
      if (widget.table == 'strategy_proposals') 'Unchanged',
      'Career',
      'Ownership',
      'Capital',
    ],
    'allocation' => [
      if (widget.table == 'strategy_proposals') 'Unchanged',
      'Primary',
      'Maintenance',
      'Continuous',
    ],
    'mode' => ['Primary', 'Maintenance', 'Continuous', 'Paused', 'Archived'],
    'kind' => [
      'Published',
      'Launch',
      'Newsletter',
      'Talk',
      'Community',
      'Other',
    ],
    'dimension' => readinessWeights.keys.toList(),
    'verified' => ['0', '1'],
    'requires_user_approval' => ['1', '0'],
    'review_recommended' => ['1', '0'],
    'enabled' => ['1', '0'],
    'status' => switch (widget.table) {
      'horizons' => ['Planned', 'Active', 'Completed', 'Archived'],
      'strategies' => ['Planned', 'Active', 'Paused', 'Completed', 'Archived'],
      'missions' => ['Active', 'Paused', 'Completed', 'Archived'],
      'outcomes' => ['Planned', 'Active', 'Achieved', 'Missed', 'Archived'],
      'initiatives' => ['Planned', 'Active', 'Paused', 'Completed', 'Archived'],
      'jobs' => ['Saved', 'Applied', 'Closed'],
      'applications' => [
        'Saved',
        'Applied',
        'Screening',
        'Interview',
        'Offer',
        'Rejected',
        'Withdrawn',
      ],
      'experiments' => ['Idea', 'Research', 'Running', 'Complete', 'Killed'],
      'learning_priorities' => ['Active', 'Planned', 'Done', 'Dismissed'],
      'recommendations' => [
        'Proposed',
        'Accepted',
        'Modified',
        'Rejected',
        'Applied',
        'Expired',
      ],
      _ => ['Unverified', 'Supported', 'Validated', 'Weakening', 'Invalidated'],
    },
    'result' =>
      widget.table == 'experiments'
          ? null
          : ['Pending', 'Pass', 'Partial', 'Fail'],
    'signal' => [
      'Unknown',
      'Negative',
      'Weak',
      'Promising',
      'Strong',
      'Revenue',
    ],
    'type' => switch (widget.table) {
      'evidence' => [
        'Code',
        'TestPass',
        'GitCommit',
        'Artifact',
        'InterviewAnswer',
        'InterviewResult',
        'Benchmark',
        'Diagram',
        'Note',
        'ExternalFeedback',
        'JobMarketSignal',
        'RevenueSignal',
        'PublishedContent',
        'ManualVerification',
      ],
      'recommendations' => [
        'Planning',
        'Review',
        'Knowledge',
        'Career',
        'Strategy',
        'Assumption',
      ],
      'strategy_events' => [
        'JobOffer',
        'MissionCompleted',
        'JobLoss',
        'SalaryChange',
        'FirstCustomer',
        'RevenueThreshold',
        'AICapabilityShift',
        'MarketContraction',
        'Manual',
      ],
      'capital_contributions' => ['Contribution', 'Withdrawal', 'Return'],
      _ => ['Monthly', 'Quarterly', 'Annual', 'EventDriven'],
    },
    'category' => [
      'Mission',
      'Skill',
      'Career',
      'Ownership',
      'Capital',
      'Product',
      'Usage',
    ],
    'direction' => ['HigherIsBetter', 'LowerIsBetter', 'Neutral'],
    _ => null,
  };
  @override
  void initState() {
    super.initState();
    for (final key in fields[widget.table]!) {
      final value = (widget.record?.data[key] ?? widget.initial[key])
          ?.toString();
      if (references.containsKey(key)) {
        selected[key] = value;
      } else if (options(key) != null) {
        selected[key] = value ?? options(key)!.first;
      } else {
        if (key == 'occurred_at' ||
            key == 'observed_at' ||
            key == 'happened_at') {
          final occurred = value == null
              ? DateTime.now()
              : DateTime.fromMillisecondsSinceEpoch(int.parse(value));
          controllers[key] = TextEditingController(text: dateField(occurred));
          continue;
        }
        controllers[key] = TextEditingController(
          text:
              value ??
              (key == 'time_budget' || key == 'planned_minutes'
                  ? '60'
                  : key == 'priority' && widget.table == 'session_templates'
                  ? '2'
                  : key == 'weight' || key == 'target'
                  ? '1'
                  : [
                      'priority',
                      'confidence',
                      'current_value',
                      'score',
                      'time_budget',
                      'planned_minutes',
                      'sort_order',
                      'weekly_budget_minutes',
                      'weekly_budget_min',
                      'weekly_budget_max',
                      'reach',
                      'leads',
                    ].contains(key)
                  ? '0'
                  : ''),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      final row = <String, Object?>{
        'id': widget.record?.id ?? newId(),
        'created_at':
            widget.record?.data['created_at'] ??
            DateTime.now().millisecondsSinceEpoch,
      };
      for (final key in fields[widget.table]!) {
        final value = controllers[key]?.text.trim() ?? selected[key];
        const nullableNumbers = {
          'salary_min',
          'salary_max',
          'fit_score',
          'target_value',
        };
        const decimalNumbers = {'target_value', 'value', 'amount'};
        final numeric = [
          'priority',
          'confidence',
          'current_value',
          'score',
          'weight',
          'target',
          'verified',
          'time_budget',
          'planned_minutes',
          'sort_order',
          'weekly_budget_minutes',
          'weekly_budget_min',
          'weekly_budget_max',
          'reach',
          'leads',
          'requires_user_approval',
          'review_recommended',
          ...decimalNumbers,
          ...nullableNumbers,
        ].contains(key);
        row[key] =
            key == 'occurred_at' || key == 'observed_at' || key == 'happened_at'
            ? DateTime.parse(value!).millisecondsSinceEpoch
            : numeric
            ? (nullableNumbers.contains(key) && (value == null || value.isEmpty)
                  ? null
                  : decimalNumbers.contains(key)
                  ? double.parse(value!)
                  : int.parse(value!))
            : value;
      }
      await widget.app.save(widget.table, row);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          error = '$e';
          saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      '${widget.record == null ? 'Create' : 'Edit'} ${widget.table.replaceAll('_', ' ')}',
    ),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final key in fields[widget.table]!)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: references.containsKey(key) || options(key) != null
                      ? DropdownButtonFormField<String>(
                          key: ValueKey(
                            '$key-${selected[key]}-${references.containsKey(key) ? choices(key).length : options(key)!.length}',
                          ),
                          initialValue: selected[key],
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: key.replaceAll('_', ' '),
                          ),
                          items: [
                            if (optionalReference(key))
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Not linked'),
                              ),
                            if (references.containsKey(key))
                              ...choices(key).map(
                                (e) => DropdownMenuItem(
                                  value: e.id,
                                  child: Text(
                                    e.title,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                            else
                              ...options(key)!.map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text(
                                    key == 'verified'
                                        ? (v == '1'
                                              ? 'I verified this evidence'
                                              : 'Unverified')
                                        : v,
                                  ),
                                ),
                              ),
                          ],
                          onChanged: saving
                              ? null
                              : (v) => setState(() {
                                  selected[key] = v;
                                  if (widget.table == 'session_templates' &&
                                      key == 'project_id') {
                                    selected['goal_id'] = null;
                                    selected['milestone_id'] = null;
                                  }
                                  if (widget.table == 'session_templates' &&
                                      key == 'goal_id' &&
                                      v != null) {
                                    selected['project_id'] = null;
                                    selected['milestone_id'] = null;
                                  }
                                }),
                          validator: (v) => v == null && !optionalReference(key)
                              ? 'Select a linked record first'
                              : null,
                        )
                      : TextFormField(
                          controller: controllers[key],
                          decoration: InputDecoration(
                            labelText: key.replaceAll('_', ' '),
                          ),
                          minLines: 1,
                          maxLines:
                              [
                                'description',
                                'summary',
                                'reason',
                                'success_criteria',
                                'evidence_context',
                                'next_action',
                                'hypothesis',
                                'experiment',
                                'result',
                                'notes',
                                'strengths',
                                'weaknesses',
                                'new_learning_priorities',
                              ].contains(key)
                              ? 4
                              : 1,
                          validator: (v) {
                            final value = v!.trim();
                            if ([
                                  'title',
                                  'summary',
                                  'reason',
                                  'hypothesis',
                                  'experiment',
                                ].contains(key) &&
                                value.isEmpty) {
                              return 'Required';
                            }
                            if ([
                              'priority',
                              'confidence',
                              'current_value',
                              'score',
                              'weight',
                              'target',
                              'time_budget',
                              'planned_minutes',
                              'sort_order',
                              'weekly_budget_minutes',
                              'observed_at',
                              'salary_min',
                              'salary_max',
                              'fit_score',
                            ].contains(key)) {
                              if ([
                                    'salary_min',
                                    'salary_max',
                                    'fit_score',
                                  ].contains(key) &&
                                  value.isEmpty) {
                                return null;
                              }
                              if (key == 'observed_at' && value.isEmpty) {
                                return null;
                              }
                              final n = int.tryParse(value);
                              if (n == null || n < 0) {
                                return 'Enter a non-negative integer';
                              }
                              if (['weight', 'target'].contains(key) &&
                                  n == 0) {
                                return 'Must be positive';
                              }
                              if ([
                                    'time_budget',
                                    'planned_minutes',
                                  ].contains(key) &&
                                  n == 0) {
                                return 'Must be positive';
                              }
                              if ([
                                    'confidence',
                                    'score',
                                    'fit_score',
                                  ].contains(key) &&
                                  n > 100) {
                                return 'Maximum 100';
                              }
                              if (key == 'priority' && n > 3) {
                                return 'Use P0 to P3';
                              }
                            }
                            if (['target_value', 'value'].contains(key)) {
                              if (key == 'target_value' && value.isEmpty) {
                                return null;
                              }
                              if (double.tryParse(value) == null) {
                                return 'Enter a number';
                              }
                            }
                            if (key == 'weekdays') {
                              final days = value
                                  .split(',')
                                  .map((day) => int.tryParse(day.trim()))
                                  .toList();
                              if (days.isEmpty ||
                                  days.any(
                                    (day) => day == null || day < 1 || day > 7,
                                  )) {
                                return 'Use comma-separated weekdays 1–7';
                              }
                            }
                            if (key == 'local_time' &&
                                !RegExp(
                                  r'^(?:[01]\d|2[0-3]):[0-5]\d$',
                                ).hasMatch(value)) {
                              return 'Use HH:mm (24-hour time)';
                            }
                            if (key == 'next_action' &&
                                selected['status'] != 'Killed' &&
                                value.isEmpty) {
                              return 'Enter a next action or choose Killed';
                            }
                            if ([
                                  'period_start',
                                  'period_end',
                                  'target_date',
                                  'date',
                                  'applied_at',
                                  'start_date',
                                  'end_date',
                                  'occurred_at',
                                ].contains(key) &&
                                value.isNotEmpty &&
                                DateTime.tryParse(value) == null) {
                              return 'Use YYYY-MM-DD';
                            }
                            return null;
                          },
                        ),
                ),
              if (error != null)
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (widget.table == 'evidence')
                const Text(
                  'Score is your assessment of this dimension (0–100). Only verified evidence contributes. The latest verified assessment replaces the prior score for that dimension.',
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: saving ? null : save,
        child: Text(saving ? 'Saving…' : 'Save'),
      ),
    ],
  );
}

class MissionScreen extends StatelessWidget {
  final AppController app;
  const MissionScreen(this.app, {super.key});
  @override
  Widget build(BuildContext context) {
    final w = app.workspace;
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        PageHeading(
          'Mission',
          'Connect measurable outcomes to the work you do today.',
          action: FilledButton(
            onPressed: () => editStrategyRecord(context, app, 'missions'),
            child: const Text('New mission'),
          ),
        ),
        TextButton(
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
        TextButton.icon(
          onPressed: w.activeMission == null
              ? null
              : () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => TrajectoryScreen(app, w.activeMission!.id),
                  ),
                ),
          icon: const Icon(Icons.show_chart),
          label: const Text('Open active mission trajectory'),
        ),
        if (w.records('missions').isEmpty)
          const Panel(
            child: Text(
              'Create a Vision and Strategy in Strategy, then create your mission. Link an existing goal to connect its projects and sessions.',
            ),
          ),
        for (final m in w.records('missions'))
          Section(
            m.title,
            trailing: TextButton(
              onPressed: () =>
                  editStrategyRecord(context, app, 'missions', record: m),
              child: const Text('Edit'),
            ),
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${m.text('status')} · P${m.number('priority')} · Confidence ${m.number('confidence')}% · Target ${m.text('target_date')}',
                  ),
                  const SizedBox(height: 12),
                  Text(m.text('success_criteria')),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: w.missionProgress(m.id)),
                  Text(
                    '${(w.missionProgress(m.id) * 100).round()}% · weighted outcome attainment',
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => editStrategyRecord(
                          context,
                          app,
                          'outcomes',
                          initial: {'mission_id': m.id},
                        ),
                        child: const Text('Add outcome'),
                      ),
                      TextButton(
                        onPressed: () => editStrategyRecord(
                          context,
                          app,
                          'initiatives',
                          initial: {'mission_id': m.id},
                        ),
                        child: const Text('Add initiative'),
                      ),
                      TextButton(
                        onPressed: () => editStrategyRecord(
                          context,
                          app,
                          'skills',
                          initial: {'mission_id': m.id},
                        ),
                        child: const Text('Add skill'),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => CareerWorkspaceScreen(app, m.id),
                          ),
                        ),
                        icon: const Icon(Icons.work_outline),
                        label: const Text('Career workspace'),
                      ),
                    ],
                  ),
                  for (final o
                      in w
                          .records('outcomes')
                          .where((r) => r.ref('mission_id') == m.id))
                    ListTile(
                      title: Text(o.title),
                      subtitle: Text(
                        '${o.number('current_value')} / ${o.number('target')} ${o.text('unit')} · weight ${o.number('weight')}',
                      ),
                      onTap: () => editStrategyRecord(
                        context,
                        app,
                        'outcomes',
                        record: o,
                      ),
                    ),
                  for (final initiative
                      in w
                          .records('initiatives')
                          .where((r) => r.ref('mission_id') == m.id))
                    ListTile(
                      leading: const Icon(Icons.route_outlined),
                      title: Text(initiative.title),
                      subtitle: Text(
                        '${initiative.text('status')} · P${initiative.number('priority')} · ${initiative.number('weekly_budget_minutes')} min/week\n${w.record('outcomes', initiative.ref('outcome_id'))?.title ?? 'Mission-level initiative'}',
                      ),
                      onTap: () => editStrategyRecord(
                        context,
                        app,
                        'initiatives',
                        record: initiative,
                      ),
                    ),
                  for (final skill
                      in w
                          .records('skills')
                          .where((r) => r.ref('mission_id') == m.id))
                    ExpansionTile(
                      title: Text(skill.title),
                      subtitle: Text(
                        '${w.readiness(skill.id).round()}% readiness · verified assessments',
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            '${w.configuredReadinessWeights.entries.map((entry) => '${entry.key} ${(entry.value * 100).round()}%').join(' · ')}. Missing dimensions count as zero. Time spent does not change readiness.',
                          ),
                        ),
                        for (final dimension in w.readinessBreakdown(skill.id))
                          ListTile(
                            dense: true,
                            leading: SizedBox(
                              width: 92,
                              child: LinearProgressIndicator(
                                value: dimension.score / 100,
                                minHeight: 7,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            title: Text(
                              '${dimension.name}: ${dimension.score}% × ${(dimension.weight * 100).round()}% = ${dimension.contribution.toStringAsFixed(1)} points',
                            ),
                            subtitle: Text(
                              dimension.evidence == null
                                  ? 'No verified assessment yet.'
                                  : dimension.assessmentDelta == null
                                  ? 'First verified assessment · ${dimension.evidence!.title}'
                                  : '${dimension.assessmentDelta! >= 0 ? '+' : ''}${dimension.assessmentDelta} since previous assessment · ${dimension.evidence!.title}',
                            ),
                          ),
                        TextButton(
                          onPressed: () => editStrategyRecord(
                            context,
                            app,
                            'evidence',
                            initial: {'skill_id': skill.id},
                          ),
                          child: const Text('Link output & assess dimension'),
                        ),
                        for (final e
                            in w
                                .records('evidence')
                                .where((r) => r.ref('skill_id') == skill.id))
                          ListTile(
                            title: Text(
                              '${e.text('dimension')} · ${e.number('score')}% · ${e.number('verified') == 1 ? 'Verified' : 'Unverified'}',
                            ),
                            subtitle: Text(
                              w.outputs
                                      .where((o) => o.id == e.ref('output_id'))
                                      .firstOrNull
                                      ?.title ??
                                  '',
                            ),
                            onTap: () => editStrategyRecord(
                              context,
                              app,
                              'evidence',
                              initial: {
                                'skill_id': skill.id,
                                'output_id': e.ref('output_id'),
                                'dimension': e.text('dimension'),
                                'score': e.number('score'),
                              },
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class StrategyScreen extends StatelessWidget {
  final AppController app;
  const StrategyScreen(this.app, {super.key});

  Map<String, String> versionChanges(
    Workspace workspace,
    StrategyRecord version,
  ) {
    final previous = workspace.record(
      'strategy_versions',
      version.ref('previous_version_id'),
    );
    if (previous == null) {
      return const {'Baseline': 'Initial recorded strategy'};
    }
    final before = Map<String, Object?>.from(
      jsonDecode(previous.text('snapshot_json')) as Map,
    );
    final after = Map<String, Object?>.from(
      jsonDecode(version.text('snapshot_json')) as Map,
    );
    final result = <String, String>{};
    for (final key in ['title', 'description', 'engine', 'allocation']) {
      if (before[key] != after[key]) {
        result[key] = '${before[key] ?? '—'} → ${after[key] ?? '—'}';
      }
    }
    return result.isEmpty
        ? const {'Change': 'No tracked field changed'}
        : result;
  }

  Future<void> decide(
    BuildContext context,
    StrategyRecord p,
    String status,
  ) async {
    try {
      await app.save('strategy_proposals', {'id': p.id, 'status': status});
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> decideRecommendation(
    BuildContext context,
    StrategyRecord recommendation,
    String status,
  ) async {
    try {
      await app.save('recommendations', {
        'id': recommendation.id,
        'status': status,
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = app.workspace;
    final versions = w.records('strategy_versions').toList()
      ..sort(
        (a, b) =>
            b.number('version_number').compareTo(a.number('version_number')),
      );
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        if (w.records('visions').isEmpty)
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Start from your own vision, or load the editable Career / Ownership / Capital example. Existing projects and sessions stay intact.',
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      final raw =
                          jsonDecode(
                                await rootBundle.loadString(
                                  'assets/strategy_starter.json',
                                ),
                              )
                              as Map<String, dynamic>;
                      await app.repository.installStrategyTemplate(
                        raw.map(
                          (key, value) => MapEntry(
                            key,
                            (value as List)
                                .map((r) => Map<String, Object?>.from(r as Map))
                                .toList(),
                          ),
                        ),
                      );
                      await app.refresh();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    }
                  },
                  child: const Text('Load editable starter strategy'),
                ),
              ],
            ),
          ),
        const PageHeading(
          'Strategy',
          'Vision → Strategy → Mission → Project → Session → Evidence',
        ),
        Wrap(
          spacing: 12,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => StrategyMapScreen(app)),
              ),
              icon: const Icon(Icons.account_tree_outlined),
              label: const Text('Explore hierarchy'),
            ),
            for (final table in [
              'visions',
              'horizons',
              'strategies',
              'assumptions',
              'strategy_proposals',
              'recommendations',
            ])
              OutlinedButton(
                onPressed: () => editStrategyRecord(context, app, table),
                child: Text('New ${table.replaceAll('_', ' ')}'),
              ),
          ],
        ),
        const SizedBox(height: 24),
        for (final v in w.records('visions'))
          Section(
            v.title,
            trailing: TextButton(
              onPressed: () =>
                  editStrategyRecord(context, app, 'visions', record: v),
              child: const Text('Edit vision'),
            ),
            child: Column(
              children: [
                Text('${v.text('description')} · ${v.text('target_date')}'),
                for (final horizon
                    in w
                        .records('horizons')
                        .where((r) => r.ref('vision_id') == v.id))
                  ListTile(
                    leading: const Icon(Icons.timelapse_outlined),
                    title: Text(horizon.title),
                    subtitle: Text(
                      '${horizon.text('status')} · ${horizon.text('start_date')} → ${horizon.text('end_date')}\n${horizon.text('description')}',
                    ),
                    onTap: () => editStrategyRecord(
                      context,
                      app,
                      'horizons',
                      record: horizon,
                    ),
                  ),
                for (final s
                    in w
                        .records('strategies')
                        .where((r) => r.ref('vision_id') == v.id))
                  Card(
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      title: Text(s.title),
                      subtitle: Text(
                        '${s.text('engine')} · ${s.text('allocation')} · ${w.record('horizons', s.ref('horizon_id'))?.title ?? 'No horizon'}',
                      ),
                      children: [
                        ListTile(title: Text(s.text('description'))),
                        for (final m
                            in w
                                .records('missions')
                                .where((r) => r.ref('strategy_id') == s.id))
                          ListTile(
                            leading: const Icon(Icons.flag_outlined),
                            title: Text(m.title),
                            subtitle: Text(
                              w.projects
                                  .where(
                                    (p) =>
                                        p.goalId != null &&
                                        p.goalId == m.ref('goal_id'),
                                  )
                                  .map((p) => p.title)
                                  .join(' · '),
                            ),
                          ),
                        for (final a
                            in w
                                .records('assumptions')
                                .where((r) => r.ref('strategy_id') == s.id))
                          ListTile(
                            title: Text(a.title),
                            subtitle: Text(
                              '${a.text('status')} · ${a.number('confidence')}%\n${a.text('evidence_context')}',
                            ),
                            onTap: () => editStrategyRecord(
                              context,
                              app,
                              'assumptions',
                              record: a,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        const Text(
          'Structured recommendations',
          style: TextStyle(fontSize: 20),
        ),
        for (final recommendation in w.records('recommendations'))
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${recommendation.title} · ${recommendation.text('status')}',
                  style: const TextStyle(fontSize: 18),
                ),
                Text('Reason: ${recommendation.text('reason')}'),
                if (recommendation.text('fact_basis').isNotEmpty)
                  Text('Facts: ${recommendation.text('fact_basis')}'),
                if (recommendation.text('inference').isNotEmpty)
                  Text('Inference: ${recommendation.text('inference')}'),
                Text(
                  'Expected benefit: ${recommendation.text('expected_benefit')}',
                ),
                Text('Risk: ${recommendation.text('risk')}'),
                Text('Confidence: ${recommendation.number('confidence')}%'),
                Text(
                  'Suggested action: ${recommendation.text('suggested_action')}',
                ),
                if (recommendation.text('status') == 'Proposed')
                  Wrap(
                    spacing: 12,
                    children: [
                      FilledButton(
                        onPressed: () => decideRecommendation(
                          context,
                          recommendation,
                          'Accepted',
                        ),
                        child: const Text('Accept'),
                      ),
                      TextButton(
                        onPressed: () => editStrategyRecord(
                          context,
                          app,
                          'recommendations',
                          record: recommendation,
                        ),
                        child: const Text('Modify'),
                      ),
                      TextButton(
                        onPressed: () => decideRecommendation(
                          context,
                          recommendation,
                          'Rejected',
                        ),
                        child: const Text('Reject'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        const Text(
          'Planning propagation previews',
          style: TextStyle(fontSize: 20),
        ),
        for (final set in w.records('planning_change_sets'))
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${set.title} · ${set.text('status')}',
                  style: const TextStyle(fontSize: 18),
                ),
                const Text(
                  'Review every proposed change below. No future session changes until this preview is approved and applied.',
                ),
                for (final change
                    in w
                        .records('planning_changes')
                        .where(
                          (change) => change.ref('change_set_id') == set.id,
                        ))
                  Builder(
                    builder: (context) {
                      final payload = Map<String, Object?>.from(
                        jsonDecode(change.text('payload_json')) as Map,
                      );
                      return ListTile(
                        leading: const Icon(Icons.event_outlined),
                        title: Text(
                          '${change.text('action')} · ${payload['title'] ?? change.ref('target_id') ?? ''}',
                        ),
                        subtitle: Text(
                          '${date(payload['planned_start']) == null ? '' : '${dateField(date(payload['planned_start']))} ${timeLabel(date(payload['planned_start'])!)} · '}'
                          '${payload['planned_minutes'] ?? ''} min\n${payload['target'] ?? ''}',
                        ),
                      );
                    },
                  ),
                if (set.text('status') == 'Draft')
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton(
                        onPressed: () => attempt(
                          context,
                          () => app.decidePlanningChangeSet(
                            set.id,
                            approve: true,
                          ),
                        ),
                        child: const Text('Approve preview'),
                      ),
                      TextButton(
                        onPressed: () => attempt(
                          context,
                          () => app.decidePlanningChangeSet(
                            set.id,
                            approve: false,
                          ),
                        ),
                        child: const Text('Reject preview'),
                      ),
                    ],
                  ),
                if (set.text('status') == 'Approved')
                  FilledButton.icon(
                    onPressed: () => attempt(context, () async {
                      await app.applyPlanningChangeSet(set.id);
                    }),
                    icon: const Icon(Icons.playlist_add_check),
                    label: const Text('Apply to future plan'),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        const Text('Proposed changes', style: TextStyle(fontSize: 20)),
        for (final p in w.records('strategy_proposals'))
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${p.title} · ${p.text('status')}',
                  style: const TextStyle(fontSize: 18),
                ),
                Text(p.text('description')),
                Text('Reason: ${p.text('reason')}'),
                Text(
                  'Engine: ${p.text('engine')} · Allocation: ${p.text('allocation')}',
                ),
                Text(
                  'Evidence / affected assumptions / benefits / risks: ${p.text('evidence_context')}',
                ),
                Text(
                  'Confidence: ${p.number('confidence')}% · User-authored proposal',
                ),
                if (p.text('status') == 'Pending')
                  Wrap(
                    spacing: 12,
                    children: [
                      FilledButton(
                        onPressed: () => decide(context, p, 'Accepted'),
                        child: const Text('Accept strategy change'),
                      ),
                      TextButton(
                        onPressed: () => editStrategyRecord(
                          context,
                          app,
                          'strategy_proposals',
                          record: p,
                        ),
                        child: const Text('Modify'),
                      ),
                      TextButton(
                        onPressed: () => decide(context, p, 'Rejected'),
                        child: const Text('Reject'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        const Text('Strategy history', style: TextStyle(fontSize: 20)),
        for (final v in versions)
          ExpansionTile(
            title: Text('v${v.number('version_number')} · ${v.title}'),
            subtitle: Text('${v.createdAt} · ${v.text('change_reason')}'),
            children: [
              for (final change in versionChanges(w, v).entries)
                ListTile(
                  dense: true,
                  title: Text(change.key),
                  subtitle: Text(change.value),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(v.text('snapshot_json')),
              ),
            ],
          ),
      ],
    );
  }
}

class AdaptiveReviewScreen extends StatelessWidget {
  final AppController app;
  const AdaptiveReviewScreen(this.app, {super.key});

  ({DateTime start, DateTime end}) period(String type) {
    final now = DateTime.now();
    return switch (type) {
      'Monthly' => (
        start: DateTime(now.year, now.month),
        end: DateTime(now.year, now.month + 1),
      ),
      'Quarterly' => (
        start: DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1),
        end: DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 4),
      ),
      'Annual' => (start: DateTime(now.year), end: DateTime(now.year + 1)),
      _ => (
        start: DateTime(now.year, now.month, now.day - 30),
        end: DateTime(now.year, now.month, now.day + 1),
      ),
    };
  }

  List<String> list(StrategyRecord review, String key) {
    try {
      return (jsonDecode(review.text(key)) as List)
          .map((value) => value.toString())
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> generate(BuildContext context, String type) async {
    final selected = period(type);
    try {
      await app.generateAdaptiveReview(
        type: type,
        periodStart: selected.start,
        periodEnd: selected.end,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$type review draft saved with local evidence-based recommendations.',
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate review: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 5,
    child: Column(
      children: [
        const TabBar(
          isScrollable: true,
          tabs: [
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
            Tab(text: 'Quarterly'),
            Tab(text: 'Annual'),
            Tab(text: 'Event-Driven'),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              ReviewScreen(app),
              for (final type in [
                'Monthly',
                'Quarterly',
                'Annual',
                'EventDriven',
              ])
                ListView(
                  padding: const EdgeInsets.all(28),
                  children: [
                    PageHeading(
                      '$type review',
                      'What changed? Which assumptions still hold? What should change next?',
                      action: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (type == 'EventDriven')
                            OutlinedButton.icon(
                              onPressed: () => editStrategyRecord(
                                context,
                                app,
                                'strategy_events',
                              ),
                              icon: const Icon(Icons.bolt_outlined),
                              label: const Text('Record event'),
                            ),
                          OutlinedButton.icon(
                            onPressed: () => generate(context, type),
                            icon: const Icon(Icons.auto_awesome_outlined),
                            label: const Text('Generate local draft'),
                          ),
                          FilledButton(
                            onPressed: () => editStrategyRecord(
                              context,
                              app,
                              'period_reviews',
                              initial: {'type': type},
                            ),
                            child: const Text('Record review'),
                          ),
                        ],
                      ),
                    ),
                    Panel(
                      child: Text(
                        'Active mission: ${app.workspace.activeMission?.title ?? 'None'}\nEvidence captured: ${app.workspace.records('evidence').length}\nAssumptions to revisit: ${app.workspace.records('assumptions').where((a) => ['Weakening', 'Invalidated', 'Unverified'].contains(a.text('status'))).map((a) => a.title).join(', ')}\nRecord evidence and decisions below. Propose strategic changes in Strategy; each requires acceptance.',
                      ),
                    ),
                    if (type == 'EventDriven')
                      Section(
                        'Recorded events',
                        child: Column(
                          children: [
                            if (app.workspace
                                .records('strategy_events')
                                .isEmpty)
                              const Text(
                                'Record a material event to inspect affected assumptions before reviewing strategy.',
                              ),
                            for (final event in app.workspace.records(
                              'strategy_events',
                            ))
                              ListTile(
                                leading: const Icon(Icons.bolt_outlined),
                                title: Text(event.title),
                                subtitle: Text(
                                  '${event.text('type')} · ${dateField(event.at('occurred_at'))}\n${event.text('impact')}',
                                ),
                                trailing: Text(
                                  '${app.workspace.records('event_assumptions').where((link) => link.ref('event_id') == event.id).length} assumptions',
                                ),
                                onTap: () => editStrategyRecord(
                                  context,
                                  app,
                                  'strategy_events',
                                  record: event,
                                ),
                              ),
                          ],
                        ),
                      ),
                    for (final r
                        in app.workspace
                            .records('period_reviews')
                            .where((r) => r.text('type') == type))
                      ListTile(
                        title: Text(r.title),
                        subtitle: Text(
                          '${r.text('period_start')} – ${r.text('period_end')}\n${r.text('summary')}\n'
                          '${list(r, 'wins_json').isEmpty ? '' : 'Wins: ${list(r, 'wins_json').join(' · ')}\n'}'
                          '${list(r, 'problems_json').isEmpty ? '' : 'Problems: ${list(r, 'problems_json').join(' · ')}\n'}'
                          'Evidence: ${r.text('evidence_context')}\nNext: ${r.text('next_action')}',
                        ),
                        isThreeLine: true,
                        onTap: () => editStrategyRecord(
                          context,
                          app,
                          'period_reviews',
                          record: r,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
