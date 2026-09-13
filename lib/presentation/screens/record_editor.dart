import 'package:flutter/material.dart';
import '../../application/app_controller.dart';
import '../../domain/models.dart';
import '../widgets/common.dart';

Future<void> editRecord(
  BuildContext context,
  AppController app,
  String table, {
  Entity? entity,
  DataRowMap initial = const {},
  String? inboxId,
}) => showDialog<void>(
  context: context,
  builder: (_) => RecordEditor(
    app: app,
    table: table,
    entity: entity,
    initial: initial,
    inboxId: inboxId,
  ),
);

class RecordEditor extends StatefulWidget {
  final AppController app;
  final String table;
  final Entity? entity;
  final DataRowMap initial;
  final String? inboxId;
  const RecordEditor({
    required this.app,
    required this.table,
    this.entity,
    this.initial = const {},
    this.inboxId,
    super.key,
  });
  @override
  State<RecordEditor> createState() => _RecordEditorState();
}

class _RecordEditorState extends State<RecordEditor> {
  final form = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  late DataRowMap values;
  bool saving = false;
  String? error;
  String get table => widget.table;
  @override
  void initState() {
    super.initState();
    values = {...?widget.entity?.data, ...widget.initial};
    final now = DateTime.now();
    values.putIfAbsent(
      'planned_start',
      () => DateTime(
        now.year,
        now.month,
        now.day,
        now.hour + 1,
      ).millisecondsSinceEpoch,
    );
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController controller(String key, [String? fallback]) =>
      fields.putIfAbsent(
        key,
        () => TextEditingController(
          text: values[key]?.toString() ?? fallback ?? '',
        ),
      );
  Widget input(
    String key,
    String label, {
    int lines = 1,
    bool required = false,
    String? fallback,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller(key, fallback),
      minLines: lines,
      maxLines: lines == 1 ? 1 : lines + 3,
      decoration: InputDecoration(labelText: label),
      validator: (v) =>
          required && (v == null || v.trim().isEmpty) ? 'Enter $label' : null,
    ),
  );
  Widget select(
    String key,
    String label,
    Map<String, String> options, {
    String? fallback,
    bool nullable = false,
  }) {
    final current =
        values[key]?.toString() ??
        (nullable ? '' : fallback ?? options.keys.firstOrNull ?? '');
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        key: ValueKey('$key-$current-${options.keys.join(',')}'),
        initialValue: options.containsKey(current) || current == ''
            ? current
            : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        validator: (v) => !nullable && (v == null || v.isEmpty)
            ? 'Choose $label first'
            : null,
        items: [
          if (nullable)
            const DropdownMenuItem(value: '', child: Text('Unlinked')),
          ...options.entries.map(
            (e) => DropdownMenuItem(
              value: e.key,
              child: Text(e.value, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: (v) => setState(() {
          values[key] = v == '' ? null : v;
          if (key == 'project_id') {
            values['goal_id'] = null;
            values['milestone_id'] = null;
          }
        }),
        onSaved: (v) => values[key] = v == '' ? null : v,
      ),
    );
  }

  Widget dateInput(String key, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller('${key}_field', dateField(date(values[key]))),
      decoration: InputDecoration(labelText: '$label (YYYY-MM-DD, optional)'),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        final parsed = DateTime.tryParse(v);
        return parsed == null || dateField(parsed) != v
            ? 'Use a valid YYYY-MM-DD date'
            : null;
      },
    ),
  );
  @override
  Widget build(BuildContext context) {
    final w = widget.app.workspace;
    final linked = values['project_id'] != null;
    final name =
        {
          'goals': 'goal',
          'projects': 'project',
          'sessions': 'session',
          'milestones': 'milestone',
          'outputs': 'output',
          'knowledge': 'knowledge',
          'inbox': 'capture',
          'tasks': 'task',
        }[table] ??
        table;
    return AlertDialog(
      title: Text(
        '${widget.inboxId != null
            ? 'Convert to'
            : widget.entity == null
            ? 'Create'
            : 'Edit'} $name',
      ),
      content: SizedBox(
        width: 570,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                input('title', 'Title', required: true),
                if (table == 'goals') ...[
                  select('life_area_id', 'Life area', {
                    for (final a in w.areas) a.id: a.title,
                  }, nullable: true),
                  input('description', 'Description', lines: 2),
                  input('why', 'Why this matters', lines: 2),
                  select('status', 'Status', {
                    for (final s in GoalStatus.values) s.name: s.name,
                  }, fallback: 'active'),
                  dateInput('target_at', 'Target date'),
                ],
                if (table == 'projects') ...[
                  select('goal_id', 'Goal', {
                    for (final g in w.goals) g.id: g.title,
                  }, nullable: true),
                  select('outcome_id', 'Mission outcome', {
                    for (final outcome in w.records('outcomes'))
                      outcome.id: outcome.title,
                  }, nullable: true),
                  select('initiative_id', 'Initiative', {
                    for (final initiative in w.records('initiatives'))
                      initiative.id: initiative.title,
                  }, nullable: true),
                  input('description', 'Description', lines: 2),
                  select('project_type', 'Project type', {
                    for (final type in [
                      'Learning',
                      'Product',
                      'Career',
                      'IncomeExperiment',
                      'Content',
                      'Personal',
                    ])
                      type: type,
                  }, fallback: 'Personal'),
                  input('next_action', 'Next action', lines: 2),
                  select('status', 'Status', {
                    for (final s in ProjectStatus.values) s.name: s.name,
                  }, fallback: 'active'),
                  dateInput('start_at', 'Start date'),
                  dateInput('target_at', 'Target date'),
                ],
                if ([
                  'sessions',
                  'outputs',
                  'knowledge',
                  'tasks',
                  'milestones',
                ].contains(table))
                  select('project_id', 'Project', {
                    for (final p in w.projects) p.id: p.title,
                  }, nullable: table != 'milestones'),
                if (['sessions', 'knowledge'].contains(table) && !linked)
                  select('goal_id', 'Goal (optional)', {
                    for (final g in w.goals) g.id: g.title,
                  }, nullable: true),
                if (table == 'sessions') ...[
                  if (linked)
                    select('task_id', 'Task', {
                      for (final task in w.tasks.where(
                        (task) =>
                            task.ref('project_id') == values['project_id'],
                      ))
                        task.id: task.title,
                    }, nullable: true),
                  if (linked)
                    select('milestone_id', 'Milestone / experiment', {
                      for (final m in w.milestones.where(
                        (m) => m.projectId == values['project_id'],
                      ))
                        m.id: m.title,
                    }, nullable: true),
                  _scheduleFields(),
                  input('why', 'Why this session matters', lines: 2),
                  input('input', 'Inputs / references', lines: 2),
                  input('target', "Today's target", lines: 2),
                ],
                if (['goals', 'projects', 'sessions'].contains(table))
                  select('priority', 'Priority', {
                    '1': 'P1 · High',
                    '2': 'P2 · Normal',
                    '3': 'P3 · Low',
                  }, fallback: '2'),
                if (table == 'milestones') ...[
                  select('kind', 'Kind', {
                    'milestone': 'Milestone',
                    'experiment': 'Experiment',
                  }, fallback: 'milestone'),
                  input('description', 'Description / hypothesis', lines: 3),
                ],
                if (table == 'tasks') ...[
                  input('description', 'Description', lines: 3),
                  select('status', 'Status', {
                    for (final status in [
                      'Backlog',
                      'Planned',
                      'InProgress',
                      'Blocked',
                      'Done',
                      'Cancelled',
                    ])
                      status: status,
                  }, fallback: 'Backlog'),
                  input('scheduled_at', 'Scheduled at (YYYY-MM-DD HH:mm)'),
                  input('estimated_minutes', 'Estimated minutes'),
                  input('actual_minutes', 'Actual minutes'),
                  select('priority', 'Priority', {
                    '1': 'P1 · High',
                    '2': 'P2 · Normal',
                    '3': 'P3 · Low',
                  }, fallback: '2'),
                ],
                if (table == 'outputs') ...[
                  select('type', 'Output type', {
                    for (final t in [
                      'Artifact',
                      'TestPass',
                      'GitCommit',
                      'InterviewAnswer',
                      'InterviewResult',
                      'ExternalFeedback',
                      'JobMarketSignal',
                      'RevenueSignal',
                      'ManualVerification',
                      'Code sample',
                      'Prototype',
                      'Document',
                      'Research',
                      'Decision',
                      'Test report',
                      'Recording',
                    ])
                      t: t,
                  }, fallback: 'Artifact'),
                  input('description', 'Actual output', lines: 4),
                  input('link', 'Link or local file path'),
                  input('notes', 'Notes', lines: 2),
                ],
                if (table == 'knowledge') ...[
                  select('type', 'Knowledge type', {
                    for (final t in [
                      'Note',
                      'Learning',
                      'Decision',
                      'Lesson Learned',
                      'Reference',
                      'Idea',
                    ])
                      t: t,
                  }, fallback: 'Note'),
                  input('content', 'Distilled knowledge (Markdown)', lines: 6),
                  input(
                    'summary',
                    'Suggested summary (review before saving)',
                    lines: 3,
                  ),
                  input('tags', 'Tags (comma separated)'),
                  input('source_uri', 'Original source path / URI'),
                  select('skill_id', 'Linked skill', {
                    for (final s in w.records('skills')) s.id: s.title,
                  }, nullable: true),
                  select('mission_id', 'Linked mission', {
                    for (final m in w.records('missions')) m.id: m.title,
                  }, nullable: true),
                ],
                if (table == 'inbox')
                  select('kind', 'Capture type', {
                    for (final t in [
                      'Task',
                      'Idea',
                      'Project idea',
                      'Learning topic',
                      'Note',
                    ])
                      t: t,
                  }, fallback: 'Idea'),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
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
          child: Text(
            saving
                ? 'Saving…'
                : widget.inboxId != null
                ? 'Convert'
                : 'Save',
          ),
        ),
      ],
    );
  }

  Widget _scheduleFields() => Column(
    children: [
      TextFormField(
        controller: controller(
          'schedule',
          '${dateField(date(values['planned_start']))} ${timeLabel(date(values['planned_start'])!)}',
        ),
        decoration: const InputDecoration(
          labelText: 'Planned start (YYYY-MM-DD HH:mm)',
        ),
        validator: (v) {
          final d = DateTime.tryParse(v ?? '');
          return d == null || '${dateField(d)} ${timeLabel(d)}' != v
              ? 'Enter a valid date and time'
              : null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: controller('planned_minutes', '60'),
        decoration: const InputDecoration(
          labelText: 'Planned duration (minutes)',
        ),
        keyboardType: TextInputType.number,
        validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
            ? 'Enter a positive duration'
            : null,
      ),
      const SizedBox(height: 16),
    ],
  );
  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    form.currentState!.save();
    setState(() {
      saving = true;
      error = null;
    });
    final now = DateTime.now().millisecondsSinceEpoch;
    final row = <String, Object?>{
      'id': widget.entity?.id ?? newId(),
      'title': fields['title']!.text.trim(),
      'created_at': widget.entity?.data['created_at'] ?? now,
    };
    const allowed = {
      'goals': [
        'description',
        'why',
        'life_area_id',
        'priority',
        'target_at',
        'status',
      ],
      'projects': [
        'description',
        'project_type',
        'goal_id',
        'outcome_id',
        'initiative_id',
        'priority',
        'status',
        'start_at',
        'target_at',
        'next_action',
      ],
      'sessions': [
        'project_id',
        'goal_id',
        'task_id',
        'milestone_id',
        'why',
        'input',
        'target',
        'priority',
        'planned_start',
        'planned_minutes',
      ],
      'milestones': ['project_id', 'description', 'kind'],
      'tasks': [
        'project_id',
        'description',
        'status',
        'scheduled_at',
        'estimated_minutes',
        'actual_minutes',
        'priority',
      ],
      'outputs': ['type', 'description', 'project_id', 'link', 'notes'],
      'knowledge': [
        'type',
        'content',
        'summary',
        'tags',
        'project_id',
        'goal_id',
        'source_uri',
        'source_filename',
        'source_checksum',
        'source_size',
        'source_modified_at',
        'imported_at',
        'source_mime',
        'managed_source_path',
        'skill_id',
        'mission_id',
      ],
      'inbox': ['kind'],
    };
    for (final key in allowed[table]!) {
      if (key == 'priority') {
        row[key] = int.parse(values[key]?.toString() ?? '2');
      } else if (['estimated_minutes', 'actual_minutes'].contains(key)) {
        final value = fields[key]?.text.trim() ?? '';
        final parsed = value.isEmpty ? null : int.tryParse(value);
        if (value.isNotEmpty && (parsed == null || parsed < 0)) {
          throw FormatException('$key must be a non-negative integer');
        }
        if (key == 'estimated_minutes' && parsed == 0) {
          throw const FormatException('estimated_minutes must be positive');
        }
        row[key] = parsed;
      } else if (key == 'scheduled_at') {
        final value = fields[key]?.text.trim() ?? '';
        final parsed = value.isEmpty ? null : DateTime.tryParse(value);
        if (value.isNotEmpty && parsed == null) {
          throw const FormatException('Scheduled at must use YYYY-MM-DD HH:mm');
        }
        row[key] = parsed?.millisecondsSinceEpoch;
      } else if (['target_at', 'start_at'].contains(key)) {
        row[key] = DateTime.tryParse(
          fields['${key}_field']?.text ?? '',
        )?.millisecondsSinceEpoch;
      } else if (key == 'planned_start') {
        row[key] = DateTime.parse(
          fields['schedule']!.text,
        ).millisecondsSinceEpoch;
      } else if (key == 'planned_minutes') {
        row[key] = int.parse(fields[key]!.text);
      } else {
        row[key] = fields[key]?.text.trim() ?? values[key];
      }
    }
    if (table == 'tasks') {
      row['done'] = row['status'] == 'Done' ? 1 : 0;
    }
    if (table == 'knowledge') {
      row['updated_at'] = now;
      for (final key in [
        'source_filename',
        'source_checksum',
        'source_mime',
        'managed_source_path',
      ]) {
        row[key] ??= '';
      }
    }
    try {
      if (widget.inboxId != null) {
        await widget.app.triage(widget.inboxId!, table, row);
      } else {
        await widget.app.save(table, row);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Could not save: $e';
          saving = false;
        });
      }
    }
  }
}
