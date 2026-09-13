import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import '../../application/app_controller.dart';
import '../../domain/models.dart';
import '../widgets/common.dart';
import 'career_income_screens.dart';
import 'direction_screens.dart';
import 'session_screen.dart';
import 'library_screen.dart';

Future<void> showSearchPalette(BuildContext context, AppController app) =>
    showDialog<void>(context: context, builder: (_) => SearchPalette(app));

Future<void> showOnboarding(
  BuildContext context,
  AppController app, {
  bool firstRun = false,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: !firstRun,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Welcome to Personal OS'),
      content: const SizedBox(
        width: 620,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A local workspace for connecting direction, focused work and evidence.',
            ),
            SizedBox(height: 18),
            ListTile(
              leading: CircleAvatar(child: Text('1')),
              title: Text('Set direction'),
              subtitle: Text(
                'Create a Vision and Strategy, or load the editable starter from Strategy.',
              ),
            ),
            ListTile(
              leading: CircleAvatar(child: Text('2')),
              title: Text('Connect work'),
              subtitle: Text(
                'Create a Mission, Outcome, Initiative and Project, then plan a Session.',
              ),
            ),
            ListTile(
              leading: CircleAvatar(child: Text('3')),
              title: Text('Produce evidence'),
              subtitle: Text(
                'Finish the Session, record an Output and add a verified skill assessment.',
              ),
            ),
            ListTile(
              leading: CircleAvatar(child: Text('4')),
              title: Text('Review before change'),
              subtitle: Text(
                'Generate a review or weekly plan, inspect its evidence, then approve and apply it.',
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Your SQLite database, preserved documents, rules and embeddings stay on this device.',
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () async {
            await app.save('settings', {
              'key': 'onboarding_complete',
              'value': 'true',
            });
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
          child: const Text('Start exploring'),
        ),
      ],
    ),
  );
}

class SearchPalette extends StatefulWidget {
  final AppController app;
  const SearchPalette(this.app, {super.key});
  @override
  State<SearchPalette> createState() => _SearchPaletteState();
}

class _SearchPaletteState extends State<SearchPalette> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final results = widget.app.search(query);
    return Dialog(
      child: SizedBox(
        width: 660,
        height: 500,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                autofocus: true,
                onChanged: (v) => setState(() => query = v),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText:
                      'Search goals, work, knowledge, career and strategy',
                ),
                onSubmitted: (_) {
                  if (results.isNotEmpty) open(results.first);
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: results.isEmpty
                    ? Center(
                        child: Text(
                          query.trim().isEmpty
                              ? 'Search by title, content or tag.'
                              : 'No matches. Try a different word.',
                        ),
                      )
                    : ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final e = results[index];
                          return ListTile(
                            title: Text(e.title),
                            subtitle: Text(_kind(e)),
                            onTap: () => open(e),
                          );
                        },
                      ),
              ),
              const Text(
                'Enter opens first result · Esc closes',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void open(Entity e) {
    final navigator = Navigator.of(context);
    final app = widget.app;
    final strategyTable = _strategyTable(e);
    navigator.pop();
    final Widget screen = switch (e) {
      Goal() => DirectionDetail(app: app, id: e.id, isGoal: true),
      Project() => DirectionDetail(app: app, id: e.id, isGoal: false),
      Session() => SessionScreen(app: app, id: e.id),
      Output() || KnowledgeItem() => EvidenceDetail(app, e),
      StrategyRecord() when strategyTable == 'missions' =>
        CareerWorkspaceScreen(app, e.id),
      StrategyRecord() when strategyTable == 'jobs' => CareerWorkspaceScreen(
        app,
        e.text('mission_id'),
      ),
      StrategyRecord() when strategyTable == 'experiments' => IncomeLabScreen(
        app,
      ),
      _ => _StrategyRecordDetail(e, strategyTable ?? 'strategy record'),
    };
    navigator.push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  String? _strategyTable(Entity entity) {
    if (entity is! StrategyRecord) return null;
    for (final entry in widget.app.workspace.strategyData.entries) {
      if (entry.value.any((record) => identical(record, entity))) {
        return entry.key;
      }
    }
    return null;
  }

  String _kind(Entity entity) {
    if (entity is Goal) return 'Goal';
    if (entity is Project) return 'Project';
    if (entity is Session) return 'Session';
    if (entity is Output) return 'Output';
    if (entity is KnowledgeItem) return 'Knowledge';
    return (_strategyTable(entity) ?? 'Strategy record').replaceAll('_', ' ');
  }
}

class _StrategyRecordDetail extends StatelessWidget {
  final Entity record;
  final String kind;

  const _StrategyRecordDetail(this.record, this.kind);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(kind.replaceAll('_', ' '))),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: [
            PageHeading(record.title, 'Search result context'),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in record.data.entries)
                    if (!['id', 'title', 'created_at'].contains(entry.key) &&
                        entry.value != null &&
                        entry.value.toString().trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SelectableText(
                          '${entry.key.replaceAll('_', ' ')}: ${entry.value}',
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class SettingsScreen extends StatefulWidget {
  final AppController app;
  final String databasePath;
  final Future<void> Function(String path)? onRestore;
  const SettingsScreen(
    this.app,
    this.databasePath, {
    this.onRestore,
    super.key,
  });
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController name;
  late final Map<String, TextEditingController> readiness;
  @override
  void initState() {
    super.initState();
    name = TextEditingController(
      text: widget.app.workspace.settings['name'] ?? '',
    );
    readiness = {
      for (final entry
          in widget.app.workspace.configuredReadinessWeights.entries)
        entry.key: TextEditingController(
          text: (entry.value * 100).toStringAsFixed(0),
        ),
    };
  }

  @override
  void dispose() {
    name.dispose();
    for (final controller in readiness.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.app,
    builder: (context, _) => ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const PageHeading('Settings', 'Your workspace. Stored on this device.'),
        Section(
          'Appearance',
          child: Panel(
            child: DropdownButtonFormField<String>(
              initialValue: widget.app.workspace.settings['theme'] ?? 'system',
              decoration: const InputDecoration(labelText: 'Theme'),
              items: [
                'system',
                'light',
                'dark',
              ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => attempt(
                context,
                () =>
                    widget.app.save('settings', {'key': 'theme', 'value': v!}),
              ),
            ),
          ),
        ),
        Section(
          'Personalize',
          child: Panel(
            child: Column(
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Your name'),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => attempt(context, () async {
                      await widget.app.save('settings', {
                        'key': 'name',
                        'value': name.text.trim(),
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Name saved.')),
                        );
                      }
                    }),
                    child: const Text('Save name'),
                  ),
                ),
              ],
            ),
          ),
        ),
        Section(
          'Readiness model',
          child: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Set the relative importance of each evidence dimension. Values are percentages and must total 100%. Existing evidence is preserved; only the calculated readiness changes.',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final entry in readiness.entries)
                      SizedBox(
                        width: 190,
                        child: TextField(
                          controller: entry.value,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: entry.key,
                            suffixText: '%',
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: saveReadinessWeights,
                    child: const Text('Save readiness weights'),
                  ),
                ),
              ],
            ),
          ),
        ),
        Section(
          'Intelligence and privacy',
          child: Panel(
            child: Builder(
              builder: (context) {
                final boundary = widget.app.intelligenceContext;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          boundary.sendsDataOffDevice
                              ? Icons.cloud_outlined
                              : Icons.computer_outlined,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          boundary.mode,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(boundary.explanation),
                    const SizedBox(height: 8),
                    Text(
                      'Context available: ${boundary.includedData.join(', ')}.',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Persistent context-sharing audit: ${widget.app.workspace.records('context_sharing_audit').isEmpty ? 'no off-device operations recorded' : '${widget.app.workspace.records('context_sharing_audit').length} reviewed operations'}.',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Latest measured startup: ${widget.app.workspace.settings['last_startup_ms'] ?? 'not measured'} ms (target < 3000 ms). Knowledge search latency is recorded locally for retrieval QA.',
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        Section(
          'Local database',
          child: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personal OS works offline. There is no account or remote sync.',
                ),
                const SizedBox(height: 12),
                SelectableText(widget.databasePath),
                OutlinedButton.icon(
                  onPressed: () => attempt(context, () async {
                    final location = await getSaveLocation(
                      suggestedName:
                          'personal-os-${DateTime.now().millisecondsSinceEpoch}.sqlite',
                    );
                    if (location == null) return;
                    await widget.app.repository.backup(location.path);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Consistent SQLite backup saved.'),
                        ),
                      );
                    }
                  }),
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Export database backup'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: exportJson,
                  icon: const Icon(Icons.data_object_outlined),
                  label: const Text('Export portable JSON'),
                ),
                if (widget.onRestore != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: restore,
                    icon: const Icon(Icons.settings_backup_restore),
                    label: const Text('Restore from backup'),
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'For a manual backup, close the application and copy the SQLite file to a safe location.',
                ),
              ],
            ),
          ),
        ),
        Section(
          'Personal data controls',
          child: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delete one local data category without clearing the rest of your workspace. Export a backup first if you may need it later.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in [
                      'Career',
                      'Knowledge',
                      'OwnershipCapital',
                    ])
                      OutlinedButton(
                        onPressed: () => deleteCategory(category),
                        child: Text(
                          'Delete ${category == 'OwnershipCapital' ? 'Ownership & Capital' : category} data',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Section(
          'Keyboard',
          child: const Panel(
            child: Text(
              'Ctrl / Cmd + K   Search\nCtrl / Cmd + N   Quick capture\nSpace   Activate a focused session button\nEsc   Close a dialog',
            ),
          ),
        ),
        Section(
          'Help',
          child: Panel(
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => showOnboarding(context, widget.app),
                icon: const Icon(Icons.help_outline),
                label: const Text('Open quick start'),
              ),
            ),
          ),
        ),
        Section(
          'Activity Score',
          child: const Panel(
            child: Text(
              'An approximate signal of attention, not well-being.\nActive goals: up to 20 points.\nSessions attended in 7 days: up to 50 points.\nMilestones completed in 7 days: up to 30 points.\nNo recent sessions with active goals: subtract 20.\nAlways clamped to 0–100.',
            ),
          ),
        ),
        if (widget.app.workspace.settings['demo'] == 'true')
          Section(
            'Demo workspace',
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You are exploring sample data. Starting fresh clears ALL records in this demo workspace, including anything you added.',
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: clear,
                    child: const Text('Start an empty workspace'),
                  ),
                ],
              ),
            ),
          ),
        const Text('Personal OS · v0.4.0 source preview · Local-first'),
      ],
    ),
  );

  Future<void> saveReadinessWeights() async {
    final parsed = <String, double>{};
    for (final entry in readiness.entries) {
      final value = double.tryParse(entry.value.text.trim());
      if (value == null || value < 0 || value > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${entry.key} must be between 0 and 100.')),
        );
        return;
      }
      parsed[entry.key] = value;
    }
    final total = parsed.values.fold(0.0, (sum, value) => sum + value);
    if ((total - 100).abs() > .01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Weights currently total ${total.toStringAsFixed(1)}%. Set them to 100%.',
          ),
        ),
      );
      return;
    }
    await attempt(context, () async {
      await widget.app.updateReadinessWeights(parsed);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Readiness weights saved.')),
        );
      }
    });
  }

  Future<void> exportJson() async {
    final location = await getSaveLocation(
      suggestedName:
          'personal-os-export-${DateTime.now().millisecondsSinceEpoch}.json',
    );
    if (location == null || !mounted) return;
    await attempt(context, () async {
      await widget.app.repository.exportPortableJson(location.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Portable JSON export saved.')),
        );
      }
    });
  }

  Future<void> deleteCategory(String category) async {
    final label = category == 'OwnershipCapital'
        ? 'Ownership & Capital'
        : category;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete all $label data?'),
        content: Text(
          'This permanently removes the local $label records. Knowledge deletion also removes preserved source copies managed by Personal OS.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete category'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await attempt(context, () => widget.app.deleteDataCategory(category));
    }
  }

  Future<void> clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear this demo workspace?'),
        content: const Text(
          'This removes goals, projects, sessions, outputs, knowledge, inbox and reviews, including your additions. This cannot be undone. Back up the database first if needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep data'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear and start fresh'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await attempt(context, widget.app.clearDemo);
    }
  }

  Future<void> restore() async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'Personal OS SQLite backup',
          extensions: ['sqlite', 'db'],
        ),
      ],
    );
    if (file == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore this backup?'),
        content: const Text(
          'The active workspace will be replaced. A safety snapshot of the current database will be saved beside it first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore backup'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await attempt(context, () => widget.onRestore!(file.path));
    }
  }
}
