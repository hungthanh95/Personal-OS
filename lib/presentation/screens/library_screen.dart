import 'knowledge_import.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../application/app_controller.dart';
import '../../domain/models.dart';
import '../widgets/common.dart';
import 'record_editor.dart';
import 'session_screen.dart';

class LibraryScreen extends StatelessWidget {
  final AppController app;
  const LibraryScreen(this.app, {super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 28, 28, 0),
          child: PageHeading(
            'Knowledge & outputs',
            'Distill what you learned. Keep evidence of what you made.',
          ),
        ),
        const TabBar(
          tabs: [
            Tab(text: 'Knowledge'),
            Tab(text: 'Output Library'),
            Tab(text: 'Concept graph'),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              _list(context, true),
              _list(context, false),
              _concepts(context),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _list(BuildContext context, bool knowledge) {
    final records = <Entity>[
      if (knowledge) ...app.workspace.knowledge else ...app.workspace.outputs,
    ];
    final table = knowledge ? 'knowledge' : 'outputs';
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        if (knowledge)
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => KnowledgeSearchDialog(app),
                ),
                icon: const Icon(Icons.manage_search_outlined),
                label: const Text('Search with context'),
              ),
              OutlinedButton.icon(
                onPressed: () => importKnowledge(context, app),
                icon: const Icon(Icons.file_open_outlined),
                label: const Text('Import document'),
              ),
            ],
          ),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => editRecord(context, app, table),
            icon: const Icon(Icons.add),
            label: Text(knowledge ? 'Create note' : 'Record output'),
          ),
        ),
        const SizedBox(height: 20),
        if (records.isEmpty)
          EmptyState(
            knowledge ? 'Something worth remembering' : 'Evidence of progress',
            knowledge
                ? 'Capture a distilled learning, decision or useful reference.'
                : 'Record what your work actually produced.',
            knowledge ? 'Create note' : 'Record output',
            () => editRecord(context, app, table),
          ),
        ...records.map((r) => EvidenceTile(app, r)),
      ],
    );
  }

  Widget _concepts(BuildContext context) {
    final workspace = app.workspace;
    final concepts = workspace.records('concepts').toList()
      ..sort((a, b) => a.title.compareTo(b.title));
    final duplicateGroups = duplicateKnowledgeGroups(workspace.knowledge);
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        Section(
          'Suggested duplicate review',
          child: duplicateGroups.isEmpty
              ? const Panel(
                  child: Text(
                    'No exact source-checksum or normalized-title duplicates detected.',
                  ),
                )
              : Panel(
                  child: Column(
                    children: [
                      for (final group in duplicateGroups)
                        ListTile(
                          leading: const Icon(Icons.content_copy_outlined),
                          title: Text(
                            group.map((item) => item.title).join(' · '),
                          ),
                          subtitle: const Text(
                            'Review these local records before keeping or merging them.',
                          ),
                        ),
                    ],
                  ),
                ),
        ),
        Section(
          'Concepts and freshness',
          child: concepts.isEmpty
              ? const Panel(
                  child: Text(
                    'Add comma-separated tags to Knowledge items to build the concept graph.',
                  ),
                )
              : Column(
                  children: [
                    for (final concept in concepts)
                      Card(
                        child: ExpansionTile(
                          title: Text(concept.title),
                          subtitle: Text(
                            'Freshness window ${concept.number('freshness_days', 180)} days',
                          ),
                          children: [
                            for (final item in workspace.knowledge.where(
                              (item) => workspace
                                  .records('knowledge_concepts')
                                  .any(
                                    (link) =>
                                        link.ref('concept_id') == concept.id &&
                                        link.ref('knowledge_id') == item.id,
                                  ),
                            ))
                              ListTile(
                                title: Text(item.title),
                                subtitle: Text(
                                  knowledgeFreshness(workspace, item),
                                ),
                                onTap: () => openEvidence(context, app, item),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class KnowledgeAdvancedScreen extends StatelessWidget {
  final AppController app;
  const KnowledgeAdvancedScreen(this.app, {super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Advanced knowledge'),
        bottom: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(text: 'Concept Graph'),
            Tab(text: 'Semantic Search'),
            Tab(text: 'Duplicates'),
            Tab(text: 'Freshness'),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          _conceptGraph(context),
          _semanticSearch(context),
          _duplicates(context),
          _freshness(context),
        ],
      ),
    ),
  );

  Widget _conceptGraph(BuildContext context) {
    final concepts = app.workspace.records('concepts').toList()
      ..sort((a, b) => a.title.compareTo(b.title));
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const PageHeading(
          'Concept Graph',
          'Browse the concepts connecting your local knowledge.',
        ),
        if (concepts.isEmpty)
          const Panel(
            child: Text(
              'No concepts yet. Add tags to knowledge items to build local concept relationships.',
            ),
          )
        else
          Panel(
            child: Column(
              children: [
                for (final concept in concepts)
                  ExpansionTile(
                    leading: const Icon(Icons.hub_outlined),
                    title: Text(concept.title),
                    subtitle: Text(
                      '${app.workspace.records('knowledge_concepts').where((link) => link.ref('concept_id') == concept.id).length} linked items',
                    ),
                    children: [
                      for (final item in app.workspace.knowledge.where(
                        (item) => app.workspace
                            .records('knowledge_concepts')
                            .any(
                              (link) =>
                                  link.ref('concept_id') == concept.id &&
                                  link.ref('knowledge_id') == item.id,
                            ),
                      ))
                        ListTile(
                          title: Text(item.title),
                          onTap: () => openEvidence(context, app, item),
                        ),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _semanticSearch(BuildContext context) => ListView(
    padding: const EdgeInsets.all(28),
    children: [
      const PageHeading(
        'Semantic Search',
        'Retrieve local notes by meaning and relationship, not only title.',
      ),
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Search results include a relevance explanation, source section and local retrieval latency.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => KnowledgeSearchDialog(app),
              ),
              icon: const Icon(Icons.manage_search_outlined),
              label: const Text('Start semantic search'),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _duplicates(BuildContext context) {
    final groups = duplicateKnowledgeGroups(app.workspace.knowledge);
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const PageHeading(
          'Duplicates',
          'Review matching checksums and normalized titles before merging.',
        ),
        if (groups.isEmpty)
          const Panel(child: Text('No duplicate groups detected.'))
        else
          Panel(
            child: Column(
              children: [
                for (final group in groups)
                  ExpansionTile(
                    leading: const Icon(Icons.content_copy_outlined),
                    title: Text('${group.length} possible duplicates'),
                    children: [
                      for (final item in group)
                        ListTile(
                          title: Text(item.title),
                          subtitle: Text(dayLabel(item.createdAt)),
                          onTap: () => openEvidence(context, app, item),
                        ),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _freshness(BuildContext context) {
    final items = app.workspace.knowledge.toList()
      ..sort((a, b) {
        final aNeedsReview = knowledgeFreshness(
          app.workspace,
          a,
        ).startsWith('Review');
        final bNeedsReview = knowledgeFreshness(
          app.workspace,
          b,
        ).startsWith('Review');
        if (aNeedsReview != bNeedsReview) return aNeedsReview ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const PageHeading(
          'Freshness',
          'See which references need review based on their concept windows.',
        ),
        if (items.isEmpty)
          const Panel(child: Text('No knowledge items to assess yet.'))
        else
          Panel(
            child: Column(
              children: [
                for (final item in items)
                  ListTile(
                    leading: Icon(
                      knowledgeFreshness(
                            app.workspace,
                            item,
                          ).startsWith('Review')
                          ? Icons.warning_amber_outlined
                          : Icons.check_circle_outline,
                    ),
                    title: Text(item.title),
                    subtitle: Text(knowledgeFreshness(app.workspace, item)),
                    onTap: () => openEvidence(context, app, item),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

List<List<KnowledgeItem>> duplicateKnowledgeGroups(List<KnowledgeItem> items) {
  final groups = <String, List<KnowledgeItem>>{};
  for (final item in items) {
    final checksum = item.text('source_checksum');
    final normalizedTitle = item.title.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '',
    );
    final key = checksum.isNotEmpty
        ? 'checksum:$checksum'
        : 'title:$normalizedTitle';
    if (normalizedTitle.isEmpty && checksum.isEmpty) continue;
    groups.putIfAbsent(key, () => []).add(item);
  }
  return groups.values.where((group) => group.length > 1).toList();
}

String knowledgeFreshness(Workspace workspace, KnowledgeItem item) {
  final conceptIds = workspace
      .records('knowledge_concepts')
      .where((link) => link.ref('knowledge_id') == item.id)
      .map((link) => link.ref('concept_id'))
      .toSet();
  final windows = workspace
      .records('concepts')
      .where((concept) => conceptIds.contains(concept.id))
      .map((concept) => concept.number('freshness_days', 180))
      .toList();
  final freshnessDays = windows.isEmpty
      ? 180
      : windows.reduce((a, b) => a < b ? a : b);
  final updated = item.at('updated_at') ?? item.createdAt;
  final age = DateTime.now().difference(updated).inDays;
  if (age <= freshnessDays) return 'Fresh · updated $age days ago';
  return 'Review recommended · $age days old (window $freshnessDays days)';
}

class EvidenceTile extends StatelessWidget {
  final AppController app;
  final Entity record;
  const EvidenceTile(this.app, this.record, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: Icon(
          record is Output
              ? Icons.inventory_2_outlined
              : Icons.menu_book_outlined,
        ),
        title: Text(record.title),
        subtitle: Text(
          '${record.text('type')} · ${app.workspace.project(record.ref('project_id'))?.title ?? 'Independent'} · ${dayLabel(record.createdAt)}${record is KnowledgeItem ? '\n${knowledgeFreshness(app.workspace, record as KnowledgeItem)}' : ''}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => openEvidence(context, app, record),
      ),
    ),
  );
}

void openEvidence(BuildContext context, AppController app, Entity record) =>
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => EvidenceDetail(app, record)),
    );

class EvidenceDetail extends StatelessWidget {
  final AppController app;
  final Entity original;
  final KnowledgeSearchHit? match;
  const EvidenceDetail(this.app, this.original, {this.match, super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: app,
    builder: (context, _) {
      final isOutput = original is Output;
      final Entity r = isOutput
          ? app.workspace.outputs
                    .where((o) => o.id == original.id)
                    .firstOrNull ??
                original
          : app.workspace.knowledge
                    .where((k) => k.id == original.id)
                    .firstOrNull ??
                original;
      final session = app.workspace.sessions
          .where((s) => s.id == r.ref('session_id'))
          .firstOrNull;
      final knowledgeLinks = isOutput
          ? const <StrategyRecord>[]
          : app.workspace
                .records('knowledge_links')
                .where(
                  (link) =>
                      link.ref('knowledge_id') == r.id &&
                      link.text('entity_type') == 'Knowledge',
                )
                .toList();
      return Scaffold(
        appBar: AppBar(
          title: Text(isOutput ? 'Output' : 'Knowledge'),
          actions: [
            TextButton.icon(
              onPressed: () => editRecord(
                context,
                app,
                isOutput ? 'outputs' : 'knowledge',
                entity: r,
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(32),
              children: [
                PageHeading(
                  r.title,
                  '${r.text('type')} · ${dayLabel(r.createdAt)}',
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    if (r.ref('project_id') != null)
                      Tag(
                        app.workspace.project(r.ref('project_id'))?.title ?? '',
                      ),
                    ...r
                        .text('tags')
                        .split(',')
                        .where((t) => t.trim().isNotEmpty)
                        .map((t) => Tag(t.trim())),
                  ],
                ),
                const SizedBox(height: 24),
                if (match != null)
                  Section(
                    'Matching source context',
                    child: Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${match!.sectionTitle ?? 'Document'} · offset ${match!.startOffset ?? 0}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          SelectableText(match!.snippet),
                          const SizedBox(height: 8),
                          Text('Why matched: ${match!.relationship}'),
                        ],
                      ),
                    ),
                  ),
                Panel(
                  child: MarkdownBody(
                    data: r.text(isOutput ? 'description' : 'content'),
                    selectable: true,
                  ),
                ),
                if (!isOutput && r.text('summary').isNotEmpty)
                  Section(
                    'Summary',
                    child: Panel(child: SelectableText(r.text('summary'))),
                  ),
                if (knowledgeLinks.isNotEmpty)
                  Section(
                    'Related Knowledge',
                    child: Panel(
                      child: Column(
                        children: [
                          for (final link in knowledgeLinks)
                            if (app.workspace.knowledge
                                    .where(
                                      (item) =>
                                          item.id == link.ref('entity_id'),
                                    )
                                    .firstOrNull
                                case final related?)
                              ListTile(
                                leading: const Icon(Icons.hub_outlined),
                                title: Text(related.title),
                                subtitle: Text(
                                  '${link.text('relationship')} · ${link.number('confidence')}% confidence${link.number('suggested') == 1 ? ' · Suggested from shared concepts' : ''}',
                                ),
                                trailing: link.number('suggested') == 1
                                    ? TextButton(
                                        onPressed: () => attempt(
                                          context,
                                          () => app.save('knowledge_links', {
                                            'id': link.id,
                                            'suggested': 0,
                                            'confidence': 100,
                                          }),
                                        ),
                                        child: const Text('Accept link'),
                                      )
                                    : null,
                                onTap: () =>
                                    openEvidence(context, app, related),
                              ),
                        ],
                      ),
                    ),
                  ),
                if (r.text('source_uri').isNotEmpty)
                  Section(
                    'Original source',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(r.text('source_uri')),
                        if (r.text('source_checksum').isNotEmpty)
                          Text(
                            '${r.text('source_filename')} · ${r.number('source_size')} bytes · checksum ${r.text('source_checksum')}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => _openSource(context, r),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open preserved source'),
                        ),
                      ],
                    ),
                  ),
                if (r.ref('skill_id') != null)
                  Text(
                    'Skill: ${app.workspace.record('skills', r.ref('skill_id'))?.title ?? ''}',
                  ),
                if (r.ref('mission_id') != null)
                  Text(
                    'Mission: ${app.workspace.record('missions', r.ref('mission_id'))?.title ?? ''}',
                  ),
                if (r.text('link').isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Section(
                    'Link / file path',
                    child: SelectableText(r.text('link')),
                  ),
                ],
                if (r.text('notes').isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Section('Notes', child: SelectableText(r.text('notes'))),
                ],
                if (session != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: OutlinedButton.icon(
                      onPressed: () => openSession(context, app, session),
                      icon: const Icon(Icons.arrow_back),
                      label: Text('Source session: ${session.title}'),
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

Future<void> _openSource(BuildContext context, Entity item) async {
  try {
    var source = item.text('managed_source_path');
    if (source.isEmpty || !await File(source).exists()) {
      source = item.text('source_uri');
    }
    if (source.isEmpty) throw StateError('No source path is available.');
    if (Platform.isWindows) {
      await Process.start('explorer.exe', [
        source,
      ], mode: ProcessStartMode.detached);
    } else if (Platform.isMacOS) {
      await Process.start('open', [source], mode: ProcessStartMode.detached);
    } else {
      await Process.start('xdg-open', [
        source,
      ], mode: ProcessStartMode.detached);
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open source: $error')));
    }
  }
}

class KnowledgeSearchDialog extends StatefulWidget {
  final AppController app;

  const KnowledgeSearchDialog(this.app, {super.key});

  @override
  State<KnowledgeSearchDialog> createState() => _KnowledgeSearchDialogState();
}

class _KnowledgeSearchDialogState extends State<KnowledgeSearchDialog> {
  final query = TextEditingController();
  List<KnowledgeSearchHit> results = const [];
  bool searching = false;
  String? message;

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  Future<void> search() async {
    if (query.text.trim().isEmpty) return;
    setState(() {
      searching = true;
      message = null;
    });
    try {
      final matches = await widget.app.searchKnowledge(query.text);
      if (mounted) {
        setState(() {
          results = matches;
          message = matches.isEmpty ? 'No full-text matches.' : null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => message = 'Search failed: $error');
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: SizedBox(
      width: 720,
      height: 560,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: query,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Search Knowledge',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Search',
                  onPressed: searching ? null : search,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
              onSubmitted: (_) => search(),
            ),
            const SizedBox(height: 16),
            if (searching) const LinearProgressIndicator(),
            if (message != null)
              Padding(padding: const EdgeInsets.all(12), child: Text(message!)),
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final hit = results[index];
                  return ListTile(
                    title: Text(hit.item.title),
                    subtitle: Text(
                      '${hit.snippet}\nWhy matched: ${hit.relationship}${hit.sectionTitle == null ? '' : '\nSection: ${hit.sectionTitle} · offset ${hit.startOffset ?? 0}'}${hit.item.text('source_filename').isEmpty ? '' : '\nSource: ${hit.item.text('source_filename')}'}',
                    ),
                    isThreeLine: true,
                    onTap: () {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      navigator.push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              EvidenceDetail(widget.app, hit.item, match: hit),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
