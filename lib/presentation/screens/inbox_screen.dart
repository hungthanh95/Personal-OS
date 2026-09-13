import 'package:flutter/material.dart';
import '../../application/app_controller.dart';
import '../widgets/common.dart';
import 'record_editor.dart';

class InboxScreen extends StatelessWidget {
  final AppController app;
  const InboxScreen(this.app, {super.key});
  @override
  Widget build(BuildContext context) {
    final items = app.workspace.inbox.where((i) => !i.processed).toList();
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        PageHeading(
          'Inbox',
          'Capture now. Give it a direction when you are ready.',
          action: FilledButton.icon(
            onPressed: () => editRecord(context, app, 'inbox'),
            icon: const Icon(Icons.add),
            label: const Text('Quick capture'),
          ),
        ),
        if (items.isEmpty)
          EmptyState(
            'A clear inbox',
            'Capture a task, an idea or something you want to explore.',
            'Capture an idea',
            () => editRecord(context, app, 'inbox'),
          ),
        ...items.map(
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(i.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    '${i.text('kind')} · ${dayLabel(i.createdAt)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final destination in {
                        'goals': 'Goal',
                        'projects': 'Project',
                        'sessions': 'Session',
                        'knowledge': 'Knowledge',
                      }.entries)
                        OutlinedButton(
                          onPressed: () => editRecord(
                            context,
                            app,
                            destination.key,
                            initial: {'title': i.title},
                            inboxId: i.id,
                          ),
                          child: Text('→ ${destination.value}'),
                        ),
                      TextButton(
                        onPressed: () => attempt(
                          context,
                          () => app.save(
                            'inbox',
                            i.patch({
                              'processed_at':
                                  DateTime.now().millisecondsSinceEpoch,
                            }),
                          ),
                        ),
                        child: const Text('Archive'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (app.workspace.inbox.any((i) => i.processed))
          ExpansionTile(
            title: Text(
              'Processed (${app.workspace.inbox.where((i) => i.processed).length})',
            ),
            children: app.workspace.inbox
                .where((i) => i.processed)
                .map(
                  (i) => ListTile(
                    title: Text(i.title),
                    subtitle: const Text('Converted or archived'),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
