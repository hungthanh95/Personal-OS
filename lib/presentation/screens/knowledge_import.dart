import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../application/app_controller.dart';
import '../../infrastructure/document_parser.dart';
import 'record_editor.dart';

Future<void> importKnowledge(BuildContext context, AppController app) async {
  try {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'Documents',
          extensions: ['txt', 'md', 'markdown', 'pdf', 'doc', 'docx'],
        ),
      ],
    );
    if (file == null) return;
    final parsed = await DocumentParser().inspect(file.path);
    final text = parsed.text;
    final managedSource = await app.repository.preserveKnowledgeSource(
      file.path,
      parsed.checksum,
    );
    if (!context.mounted) return;
    final suggestions = app.intelligenceProvider.analyzeKnowledge(
      text,
      app.workspace,
    );
    final existing = app.workspace.knowledge
        .where(
          (item) =>
              item.text('source_checksum') == parsed.checksum ||
              item.text('source_uri') == file.path,
        )
        .firstOrNull;
    await editRecord(
      context,
      app,
      'knowledge',
      entity: existing,
      initial: {
        'title': existing?.title ?? p.basenameWithoutExtension(file.path),
        'content': text,
        'summary': existing?.text('summary').isNotEmpty == true
            ? existing!.text('summary')
            : suggestions.summary,
        'tags': existing?.text('tags').isNotEmpty == true
            ? existing!.text('tags')
            : suggestions.tags.join(', '),
        'project_id': existing?.ref('project_id') ?? suggestions.projectId,
        'skill_id': existing?.ref('skill_id') ?? suggestions.skillId,
        'mission_id': existing?.ref('mission_id') ?? suggestions.missionId,
        'source_uri': file.path,
        'source_filename': parsed.filename,
        'source_checksum': parsed.checksum,
        'source_size': parsed.size,
        'source_modified_at': parsed.modifiedAt.millisecondsSinceEpoch,
        'imported_at': DateTime.now().millisecondsSinceEpoch,
        'source_mime': parsed.mimeType,
        'managed_source_path': managedSource,
      },
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed; existing notes are unchanged. $e'),
        ),
      );
    }
  }
}
