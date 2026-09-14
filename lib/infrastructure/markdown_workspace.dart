import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../domain/repository.dart';

class SessionReconciliationService {
  final MarkdownWorkspaceManager workspace;

  const SessionReconciliationService(this.workspace);

  Future<SessionReconciliationSummary> reconcile({DateTime? now}) =>
      workspace._reconcileSessions(now: now);
}

class MarkdownWorkspaceManager {
  final Database db;
  MarkdownWorkspaceManager(this.db);

  Future<String?> get configuredRoot async {
    final rows = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['obsidian_vault_path'],
    );
    final value = rows.firstOrNull?['value'] as String? ?? '';
    return value.trim().isEmpty ? null : p.normalize(value);
  }

  Future<void> initialize(String rootPath) async {
    final root = Directory(p.normalize(p.absolute(rootPath)));
    if (!await root.exists()) {
      throw ArgumentError('The selected Obsidian vault does not exist.');
    }
    for (final relative in [
      '00 Dashboard',
      '01 Strategy',
      '02 Missions',
      '03 Projects',
      '04 Tasks',
      '05 Skills',
      '06 Evidence',
      '07 Career',
      '08 Reviews',
      '09 Experiments',
      '10 Knowledge',
      '11 Sessions',
      '_templates',
      '.personal-os',
    ]) {
      await Directory(p.join(root.path, relative)).create(recursive: true);
    }
    await _writeIfMissing(
      File(p.join(root.path, '.personal-os', 'workspace.yaml')),
      'workspace_id: personal-os-main\nschema_version: 4.1\ncreated: ${_isoDate(DateTime.now())}\n',
    );
    await _writeIfMissing(
      File(p.join(root.path, '_templates', 'session.md')),
      _sessionTemplate,
    );
    await _writeIfMissing(
      File(p.join(root.path, '_templates', 'mission.md')),
      _missionTemplate,
    );
    await _writeIfMissing(
      File(p.join(root.path, '_templates', 'project.md')),
      _projectTemplate,
    );
    await _writeIfMissing(
      File(p.join(root.path, '_templates', 'task.md')),
      _taskTemplate,
    );
    await db.insert('settings', {
      'key': 'obsidian_vault_path',
      'value': root.path,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await ensureDomainNotes();
    await ensurePlanningNotes();
    await ensureSessionNotes();
  }

  Future<int> ensureDomainNotes() async {
    final rootPath = await configuredRoot;
    if (rootPath == null) return 0;
    final root = Directory(rootPath);
    if (!await root.exists()) {
      throw FileSystemException('Obsidian vault is unavailable', rootPath);
    }
    final sourceRows = await db.query('workspace_entity_sources');
    final sources = {
      for (final row in sourceRows)
        '${row['entity_type']}:${row['entity_id']}': row,
    };
    Map<String, List<File>>? existingDocuments;
    var created = 0;
    for (final table in ['missions', 'projects', 'tasks']) {
      final type = _domainType(table);
      for (final row in await db.query(table)) {
        final key = '$type:${row['id']}';
        final existingPath = sources[key]?['path'] as String? ?? '';
        if (existingPath.isNotEmpty) continue;
        existingDocuments ??= await _existingDocuments(root);
        final matches = existingDocuments[key] ?? const <File>[];
        if (matches.length > 1) {
          await db.insert(
            'workspace_entity_sources',
            {
              'entity_type': type,
              'entity_id': row['id'],
              'path': p.relative(matches.first.path, from: root.path),
              'checksum': '',
              'error': 'Duplicate ID in Obsidian vault.',
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          continue;
        }
        final file =
            matches.firstOrNull ??
            await _claimableFile(
              _domainPath(root.path, table, row),
              root.path,
              row['id'] as String,
            );
        if (!await file.exists()) {
          await _atomicWrite(file, _renderDomainDocument(table, row));
          created++;
        }
        await db.insert('workspace_entity_sources', {
          'entity_type': type,
          'entity_id': row['id'],
          'path': p.relative(file.path, from: root.path),
          'checksum': await _fileChecksum(file),
          'error': '',
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    return created;
  }

  Future<int> ensurePlanningNotes() async {
    final rootPath = await configuredRoot;
    if (rootPath == null) return 0;
    final root = Directory(rootPath);
    if (!await root.exists()) {
      throw FileSystemException('Obsidian vault is unavailable', rootPath);
    }
    var created = 0;
    for (final table in ['session_templates', 'recurring_schedules']) {
      for (final row in await db.query(table)) {
        final file = File(_planningPath(root.path, table, row));
        if (await file.exists()) continue;
        await _atomicWrite(file, _renderPlanningDocument(table, row));
        created++;
      }
    }
    return created;
  }

  Future<void> syncRecord(String table, String id) async {
    final rootPath = await configuredRoot;
    if (rootPath == null) return;
    if ({'missions', 'projects', 'tasks'}.contains(table)) {
      await ensureDomainNotes();
      final rows = await db.query(table, where: 'id = ?', whereArgs: [id]);
      if (rows.isEmpty) return;
      final row = rows.single;
      final type = _domainType(table);
      final sourceRows = await db.query(
        'workspace_entity_sources',
        where: 'entity_type = ? AND entity_id = ?',
        whereArgs: [type, id],
      );
      if (sourceRows.isEmpty) {
        throw StateError('The Markdown source mapping could not be created.');
      }
      final file = File(p.join(rootPath, sourceRows.single['path'] as String));
      if (!await file.exists()) {
        throw StateError('The $type note is missing from the vault.');
      }
      final source = await file.readAsString();
      final expected = _checksum(utf8.encode(source));
      var updated = _patchFrontmatter(
        source,
        _domainFrontmatterChanges(table, row),
      );
      for (final section in _domainSections(table, row).entries) {
        updated = _patchSection(updated, section.key, section.value);
      }
      await _writeWithRevision(file, updated, expected);
      await db.update(
        'workspace_entity_sources',
        {
          'checksum': await _fileChecksum(file),
          'error': '',
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'entity_type = ? AND entity_id = ?',
        whereArgs: [type, id],
      );
      return;
    }
    if (table == 'sessions') {
      await ensureSessionNotes();
      final rows = await db.query(table, where: 'id = ?', whereArgs: [id]);
      if (rows.isEmpty) return;
      final row = rows.single;
      final path = await sessionNotePath(id);
      final file = File(path);
      final source = await file.readAsString();
      final expected = _checksum(utf8.encode(source));
      var updated = _patchFrontmatter(source, {
        'title': row['title'] as String,
        'project': row['project_id'] as String? ?? '',
        'task': row['task_id'] as String? ?? '',
        'planned_start': _date(row['planned_start']).toIso8601String(),
        'planned_minutes': '${row['planned_minutes']}',
        'status': switch (row['status']) {
          'DONE' => 'done',
          'SKIPPED' => 'skipped',
          'CANCELLED' => 'cancelled',
          _ => 'planned',
        },
        'updated': DateTime.now().toIso8601String(),
      });
      updated = _patchSection(updated, 'Goal', row['target'] as String? ?? '');
      updated = _patchSection(updated, 'Input', row['input'] as String? ?? '');
      await _writeWithRevision(file, updated, expected);
      await db.update(
        'sessions',
        {'note_checksum': await _fileChecksum(file)},
        where: 'id = ?',
        whereArgs: [id],
      );
      return;
    }
    if (!{'session_templates', 'recurring_schedules'}.contains(table)) {
      return;
    }
    final rows = await db.query(table, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return;
    final row = rows.single;
    final file = File(_planningPath(rootPath, table, row));
    if (!await file.exists()) {
      await _atomicWrite(file, _renderPlanningDocument(table, row));
      return;
    }
    final source = await file.readAsString();
    final expected = _checksum(utf8.encode(source));
    final changes = table == 'session_templates'
        ? {
            'title': row['title'] as String,
            'project': row['project_id'] as String? ?? '',
            'planned_minutes': '${row['planned_minutes']}',
            'priority': '${row['priority']}',
            'updated': DateTime.now().toIso8601String(),
          }
        : {
            'title': row['title'] as String,
            'template': row['template_id'] as String,
            'weekdays': row['weekdays'] as String,
            'local_time': row['local_time'] as String,
            'enabled': (row['enabled'] as int? ?? 1) == 1 ? 'true' : 'false',
            'start_date': row['start_date'] as String? ?? '',
            'end_date': row['end_date'] as String? ?? '',
            'updated': DateTime.now().toIso8601String(),
          };
    var updated = _patchFrontmatter(source, changes);
    if (table == 'session_templates') {
      updated = _patchSection(updated, 'Goal', row['target'] as String? ?? '');
      updated = _patchSection(updated, 'Input', row['input'] as String? ?? '');
    }
    await _writeWithRevision(file, updated, expected);
  }

  Future<int> ensureSessionNotes() async {
    final rootPath = await configuredRoot;
    if (rootPath == null) return 0;
    final root = Directory(rootPath);
    if (!await root.exists()) {
      throw FileSystemException('Obsidian vault is unavailable', rootPath);
    }
    await ensurePlanningNotes();
    final rows = await db.query('sessions', orderBy: 'planned_start');
    Map<String, List<File>>? existingDocuments;
    var created = 0;
    for (final row in rows) {
      final currentPath = row['note_path'] as String? ?? '';
      if (currentPath.isNotEmpty) continue;
      existingDocuments ??= await _existingDocuments(root);
      final matches =
          existingDocuments['session:${row['id']}'] ?? const <File>[];
      if (matches.length > 1) {
        await db.update(
          'sessions',
          {'reconciliation_error': 'Duplicate session ID in Obsidian vault.'},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
        continue;
      }
      final sessionPath = p.join(
        root.path,
        '11 Sessions',
        '${_isoDate(_date(row['planned_start']))}-${_slug(row['title'] as String)}-${_shortId(row['id'] as String)}.md',
      );
      var file = matches.firstOrNull ?? File(sessionPath);
      if (await file.exists()) {
        final claimedId = _documentId(file, root.path);
        if (claimedId != row['id']) {
          final suffix = _checksum(
            utf8.encode(row['id'] as String),
          ).substring(0, 8);
          file = File(
            p.join(
              p.dirname(sessionPath),
              '${p.basenameWithoutExtension(sessionPath)}-$suffix.md',
            ),
          );
          if (await file.exists() &&
              _documentId(file, root.path) != row['id']) {
            throw StateError(
              'Cannot create a session note without overwriting an existing file.',
            );
          }
        }
      }
      if (!await file.exists()) {
        final outputs = await db.query(
          'outputs',
          where: 'session_id = ?',
          whereArgs: [row['id']],
        );
        final knowledge = await db.query(
          'knowledge',
          where: 'session_id = ?',
          whereArgs: [row['id']],
        );
        final output = outputs
            .map((item) {
              final description = item['description'] as String? ?? '';
              final link = item['link'] as String? ?? '';
              return [
                description,
                if (link.isNotEmpty) '[Artifact]($link)',
              ].where((value) => value.isNotEmpty).join('\n\n');
            })
            .where((value) => value.isNotEmpty)
            .join('\n\n');
        final learning = knowledge
            .map((item) => item['content'] as String? ?? '')
            .where((value) => value.isNotEmpty)
            .join('\n\n');
        await _atomicWrite(file, _renderSession(row, output, learning));
        created++;
      }
      await db.update(
        'sessions',
        {
          'note_path': p.relative(file.path, from: root.path),
          'note_checksum': await _fileChecksum(file),
          'reconciliation_error': '',
        },
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
    return created;
  }

  String? _documentId(File file, String rootPath) {
    try {
      return _parseDocument(file, rootPath).metadata['id']?.trim();
    } on FormatException {
      return null;
    }
  }

  Future<Map<String, List<File>>> _existingDocuments(Directory root) async {
    final result = <String, List<File>>{};
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File || p.extension(entity.path).toLowerCase() != '.md') {
        continue;
      }
      final relative = p.relative(entity.path, from: root.path);
      if (p
          .split(relative)
          .any(
            (part) =>
                part == '.obsidian' ||
                part == '.personal-os' ||
                part == '_templates',
          )) {
        continue;
      }
      try {
        final document = _parseDocument(entity, root.path);
        final type = document.metadata['type']?.trim().toLowerCase() ?? '';
        final id = document.metadata['id']?.trim() ?? '';
        if (type.isNotEmpty && id.isNotEmpty) {
          result.putIfAbsent('$type:$id', () => []).add(entity);
        }
      } on FormatException {
        // Reconciliation reports malformed sources without overwriting them.
      }
    }
    return result;
  }

  Future<String> sessionNotePath(String sessionId) async {
    await ensureSessionNotes();
    final rootPath = await configuredRoot;
    if (rootPath == null) {
      throw StateError('Choose an Obsidian vault in Settings first.');
    }
    final rows = await db.query(
      'sessions',
      columns: ['note_path'],
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    if (rows.isEmpty || (rows.single['note_path'] as String).isEmpty) {
      throw StateError('Session note could not be created.');
    }
    return p.join(rootPath, rows.single['note_path'] as String);
  }

  Future<String> recordNotePath(String table, String id) async {
    if (table == 'sessions') return sessionNotePath(id);
    if (!{'missions', 'projects', 'tasks'}.contains(table)) {
      throw ArgumentError('This record type has no migrated Markdown source.');
    }
    await ensureDomainNotes();
    final rootPath = await configuredRoot;
    if (rootPath == null) {
      throw StateError('Choose an Obsidian vault in Settings first.');
    }
    final rows = await db.query(
      'workspace_entity_sources',
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: [_domainType(table), id],
    );
    if (rows.isEmpty || (rows.single['path'] as String).isEmpty) {
      throw StateError('The Markdown source could not be created.');
    }
    final file = File(p.join(rootPath, rows.single['path'] as String));
    if (!await file.exists()) {
      throw StateError('The Markdown source is missing from the vault.');
    }
    return file.path;
  }

  Future<void> updateSessionPlan(
    String sessionId,
    DateTime plannedStart,
    int plannedMinutes,
  ) async {
    final operationId = 'workspace-${DateTime.now().microsecondsSinceEpoch}';
    await db.insert('workspace_operations', {
      'id': operationId,
      'kind': 'RescheduleSession',
      'status': 'Started',
      'payload_json': jsonEncode({
        'session_id': sessionId,
        'planned_start': plannedStart.toIso8601String(),
        'planned_minutes': plannedMinutes,
      }),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    try {
      final path = await sessionNotePath(sessionId);
      final file = File(path);
      final before = await file.readAsString();
      final checksum = _checksum(utf8.encode(before));
      final updated = _patchFrontmatter(before, {
        'planned_start': plannedStart.toIso8601String(),
        'planned_minutes': '$plannedMinutes',
        'updated': DateTime.now().toIso8601String(),
      });
      await _writeWithRevision(file, updated, checksum);
      final rootPath = (await configuredRoot)!;
      await db.update(
        'sessions',
        {
          'planned_start': plannedStart.millisecondsSinceEpoch,
          'planned_minutes': plannedMinutes,
          'note_path': p.relative(path, from: rootPath),
          'note_checksum': await _fileChecksum(file),
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );
      await db.update(
        'workspace_operations',
        {
          'status': 'Completed',
          'completed_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [operationId],
      );
    } catch (error) {
      await db.update(
        'workspace_operations',
        {'status': 'Failed', 'error': '$error'},
        where: 'id = ?',
        whereArgs: [operationId],
      );
      rethrow;
    }
  }

  Future<void> setSessionDisposition(String sessionId, String status) async {
    if (!{'skipped', 'cancelled'}.contains(status)) {
      throw ArgumentError('Only skipped or cancelled can be set in the app.');
    }
    final operationId = 'workspace-${DateTime.now().microsecondsSinceEpoch}';
    await db.insert('workspace_operations', {
      'id': operationId,
      'kind': 'SetSessionDisposition',
      'status': 'Started',
      'payload_json': jsonEncode({'session_id': sessionId, 'status': status}),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    try {
      final path = await sessionNotePath(sessionId);
      final file = File(path);
      final before = await file.readAsString();
      final expected = _checksum(utf8.encode(before));
      await _writeWithRevision(
        file,
        _patchFrontmatter(before, {
          'status': status,
          'updated': DateTime.now().toIso8601String(),
        }),
        expected,
      );
      await db.transaction((tx) async {
        await tx.update(
          'sessions',
          {
            'status': status == 'skipped' ? 'SKIPPED' : 'CANCELLED',
            'note_checksum': await _fileChecksum(file),
            'reconciliation_error': '',
            'reconciled_at': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [sessionId],
        );
        await tx.update(
          'workspace_operations',
          {
            'status': 'Completed',
            'completed_at': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [operationId],
        );
      });
    } catch (error) {
      await db.update(
        'workspace_operations',
        {'status': 'Failed', 'error': '$error'},
        where: 'id = ?',
        whereArgs: [operationId],
      );
      rethrow;
    }
  }

  Future<bool> recoverPlanningChangeSet(String changeSetId) async {
    final sets = await db.query(
      'planning_change_sets',
      columns: ['status'],
      where: 'id = ?',
      whereArgs: [changeSetId],
    );
    if (sets.isEmpty || sets.single['status'] != 'Applied') return false;
    final changes = await db.query(
      'planning_changes',
      where: "change_set_id = ? AND status = 'Applied'",
      whereArgs: [changeSetId],
    );
    for (final change in changes) {
      final targetId = change['action'] == 'CreateSession'
          ? (jsonDecode(change['payload_json'] as String) as Map)['id']
                as String?
          : change['target_id'] as String?;
      if (targetId != null) await syncRecord('sessions', targetId);
    }
    return true;
  }

  Future<void> _recoverStartedPlanningOperations() async {
    final operations = await db.query(
      'workspace_operations',
      where: "kind = 'ApplyPlanningChangeSet' AND status = 'Started'",
    );
    for (final operation in operations) {
      try {
        final payload = jsonDecode(operation['payload_json'] as String) as Map;
        final changeSetId = payload['change_set_id'] as String?;
        if (changeSetId == null) {
          throw const FormatException('Missing planning change set ID.');
        }
        if (!await recoverPlanningChangeSet(changeSetId)) {
          throw StateError('The planning change set was not applied.');
        }
        await db.update(
          'workspace_operations',
          {
            'status': 'Completed',
            'completed_at': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [operation['id']],
        );
      } catch (error) {
        await db.update(
          'workspace_operations',
          {'status': 'Failed', 'error': '$error'},
          where: 'id = ?',
          whereArgs: [operation['id']],
        );
      }
    }
  }

  Future<SessionReconciliationSummary> _reconcileSessions({
    DateTime? now,
  }) async {
    final rootPath = await configuredRoot;
    if (rootPath == null) return const SessionReconciliationSummary();
    final root = Directory(rootPath);
    if (!await root.exists()) {
      throw FileSystemException('Obsidian vault is unavailable', rootPath);
    }
    await ensureDomainNotes();
    await ensureSessionNotes();
    await _recoverStartedPlanningOperations();
    final scannedFiles = <_ScannedFile>[];
    try {
      await for (final entity in root.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File ||
            p.extension(entity.path).toLowerCase() != '.md') {
          continue;
        }
        final relative = p.relative(entity.path, from: root.path);
        final parts = p.split(relative);
        if (parts.any(
          (part) =>
              part == '.obsidian' ||
              part == '.personal-os' ||
              part == '_templates',
        )) {
          continue;
        }
        final stat = await entity.stat();
        scannedFiles.add(
          _ScannedFile(
            path: p.normalize(entity.path),
            size: stat.size,
            modifiedAt: stat.modified.millisecondsSinceEpoch,
          ),
        );
      }
    } on FileSystemException {
      rethrow; // An incomplete scan must never be interpreted as deletion.
    }

    final documents = <_MarkdownDocument>[];
    final invalidPaths = <String>{};
    final indexedRows = await db.query('workspace_file_index');
    final indexed = {for (final row in indexedRows) row['path'] as String: row};
    var errors = 0;
    for (final scanned in scannedFiles) {
      try {
        final cached = indexed[scanned.path];
        if (cached != null &&
            cached['size'] == scanned.size &&
            cached['modified_at'] == scanned.modifiedAt) {
          final metadata =
              (jsonDecode(cached['metadata_json'] as String) as Map).map(
                (key, value) => MapEntry('$key', '$value'),
              );
          documents.add(
            _MarkdownDocument(
              path: scanned.path,
              relativePath: p.relative(scanned.path, from: root.path),
              body: cached['body'] as String,
              metadata: metadata,
              checksum: cached['checksum'] as String,
              sourceSize: scanned.size,
              modifiedAt: scanned.modifiedAt,
              changed: false,
            ),
          );
        } else {
          documents.add(_parseDocument(File(scanned.path), root.path));
        }
      } on FormatException {
        invalidPaths.add(scanned.path);
        errors++;
      }
    }
    final allIds = <String, List<_MarkdownDocument>>{};
    for (final document in documents) {
      final id = document.metadata['id']?.trim() ?? '';
      if (id.isNotEmpty) allIds.putIfAbsent(id, () => []).add(document);
    }
    final duplicateIds = allIds.entries
        .where((entry) => entry.value.length > 1)
        .map((entry) => entry.key)
        .toSet();
    errors += duplicateIds.length;
    final sessionDocuments = documents
        .where(
          (document) => document.metadata['type']?.toLowerCase() == 'session',
        )
        .toList();
    final byId = <String, List<_MarkdownDocument>>{};
    for (final document in sessionDocuments) {
      final id = document.metadata['id']?.trim() ?? '';
      if (id.isEmpty) {
        errors++;
        continue;
      }
      byId.putIfAbsent(id, () => []).add(document);
    }
    final currentRows = await db.query('sessions');
    final current = {for (final row in currentRows) row['id'] as String: row};
    var completed = 0;
    var pending = 0;
    final clock = now ?? DateTime.now();

    await db.transaction((tx) async {
      errors += await _syncDomainProjection(
        tx,
        documents,
        duplicateIds,
        invalidPaths,
        root.path,
        clock,
      );
      await _syncPlanningProjection(tx, documents, duplicateIds);
      for (final entry in byId.entries) {
        if (entry.value.length > 1 || duplicateIds.contains(entry.key)) {
          if (current.containsKey(entry.key)) {
            await tx.update(
              'sessions',
              {
                'status': 'PLANNED',
                'output_markdown': '',
                'learning_markdown': '',
                'reconciliation_error':
                    'Duplicate session ID in Obsidian vault.',
                'reconciled_at': clock.millisecondsSinceEpoch,
                'confirmed_at': null,
              },
              where: 'id = ?',
              whereArgs: [entry.key],
            );
            await tx.delete(
              'outputs',
              where: 'session_id = ? AND notes = ?',
              whereArgs: [entry.key, _projectionMarker],
            );
          }
          continue;
        }
        final document = entry.value.single;
        var row = current[entry.key];
        final start = DateTime.tryParse(
          document.metadata['planned_start'] ?? '',
        );
        final minutes = int.tryParse(
          document.metadata['planned_minutes'] ?? '',
        );
        if (start == null || minutes == null || minutes <= 0) {
          errors++;
          if (row != null) {
            await tx.update(
              'sessions',
              {
                'status': 'PLANNED',
                'output_markdown': '',
                'learning_markdown': '',
                'reconciliation_error':
                    'Session note has an invalid planned_start or planned_minutes.',
                'reconciled_at': clock.millisecondsSinceEpoch,
                'confirmed_at': null,
              },
              where: 'id = ?',
              whereArgs: [entry.key],
            );
            await tx.delete(
              'outputs',
              where: 'session_id = ? AND notes = ?',
              whereArgs: [entry.key, _projectionMarker],
            );
          }
          continue;
        }
        final projectValue = document.metadata['project']?.trim() ?? '';
        final taskValue = document.metadata['task']?.trim() ?? '';
        final scheduleValue = document.metadata['schedule']?.trim() ?? '';
        final project = await _existingReference(tx, 'projects', projectValue);
        final task = await _existingReference(tx, 'tasks', taskValue);
        final schedule = await _existingReference(
          tx,
          'recurring_schedules',
          scheduleValue,
        );
        final missingReferences = <String>[
          if (projectValue.isNotEmpty && project == null)
            'project $projectValue',
          if (taskValue.isNotEmpty && task == null) 'task $taskValue',
          if (scheduleValue.isNotEmpty && schedule == null)
            'schedule $scheduleValue',
        ];
        final title = document.metadata['title']?.trim().isNotEmpty == true
            ? document.metadata['title']!.trim()
            : p.basenameWithoutExtension(document.path);
        if (row == null) {
          final inserted = <String, Object?>{
            'id': entry.key,
            'title': title,
            'project_id': project,
            'task_id': task,
            'planned_start': start.millisecondsSinceEpoch,
            'planned_minutes': minutes,
            'recurring_schedule_id': schedule,
            'status': 'PLANNED',
            'created_at': _dateFromMetadata(
              document.metadata['created'],
            ).millisecondsSinceEpoch,
          };
          await tx.insert('sessions', inserted);
          row = {...inserted, 'note_path': '', 'note_checksum': ''};
          current[entry.key] = row;
        }
        row = {
          ...row,
          'title': title,
          'project_id': project,
          'task_id': task,
          'recurring_schedule_id': schedule,
          'planned_start': start.millisecondsSinceEpoch,
          'planned_minutes': minutes,
        };
        final plannedStart = start;
        final plannedMinutes = minutes;
        final due = !clock.isBefore(
          plannedStart.add(Duration(minutes: plannedMinutes)),
        );
        final requestedStatus = (document.metadata['status'] ?? 'planned')
            .trim()
            .toLowerCase();
        final output = document.section('Output').trim();
        final learning = document.section('Learning').trim();
        final nextAction = document.section('Next Action').trim();
        final validOutput = _hasValidOutput(document, output, documents);
        final projectionStatus = requestedStatus == 'cancelled'
            ? 'CANCELLED'
            : requestedStatus == 'skipped'
            ? 'SKIPPED'
            : requestedStatus == 'done' &&
                  due &&
                  validOutput &&
                  missingReferences.isEmpty
            ? 'DONE'
            : 'PLANNED';
        final error = missingReferences.isNotEmpty
            ? 'Missing reference: ${missingReferences.join(', ')}.'
            : !{
                'planned',
                'done',
                'skipped',
                'cancelled',
              }.contains(requestedStatus)
            ? 'Invalid session status: $requestedStatus.'
            : requestedStatus == 'done' && due && !validOutput
            ? 'Status is done but Output is missing or unresolved.'
            : '';
        if (error.isNotEmpty) errors++;
        if (projectionStatus == 'DONE') {
          completed++;
          await _upsertOutput(tx, row, document, output, clock);
        } else {
          if (due && projectionStatus == 'PLANNED') pending++;
          await tx.delete(
            'outputs',
            where: 'session_id = ? AND notes = ?',
            whereArgs: [entry.key, _projectionMarker],
          );
        }
        await tx.update(
          'sessions',
          {
            'title': title,
            'project_id': project,
            'task_id': task,
            'recurring_schedule_id': schedule,
            'planned_start': plannedStart.millisecondsSinceEpoch,
            'planned_minutes': plannedMinutes,
            'status': projectionStatus,
            'note_path': document.relativePath,
            'note_checksum': document.checksum,
            'output_markdown': projectionStatus == 'DONE' ? output : '',
            'learning_markdown': projectionStatus == 'DONE' ? learning : '',
            'next_action': nextAction,
            'reconciliation_error': error,
            'reconciled_at': clock.millisecondsSinceEpoch,
            'confirmed_at': projectionStatus == 'DONE'
                ? plannedStart
                      .add(Duration(minutes: plannedMinutes))
                      .millisecondsSinceEpoch
                : null,
          },
          where: 'id = ?',
          whereArgs: [entry.key],
        );
      }

      final seenIds = byId.keys.toSet();
      for (final row in currentRows) {
        final notePath = row['note_path'] as String? ?? '';
        if (notePath.isEmpty || seenIds.contains(row['id'])) continue;
        await tx.update(
          'sessions',
          {
            'status': 'PLANNED',
            'output_markdown': '',
            'learning_markdown': '',
            'reconciliation_error':
                invalidPaths.contains(p.normalize(p.join(root.path, notePath)))
                ? 'Session note has invalid YAML/frontmatter.'
                : 'Session note is missing from the vault.',
            'reconciled_at': clock.millisecondsSinceEpoch,
            'confirmed_at': null,
          },
          where: 'id = ?',
          whereArgs: [row['id']],
        );
        await tx.delete(
          'outputs',
          where: 'session_id = ? AND notes = ?',
          whereArgs: [row['id'], _projectionMarker],
        );
        errors++;
      }
      await _syncKnowledge(tx, root.path, documents, duplicateIds, clock);
      await _updateFileIndex(
        tx,
        documents,
        scannedFiles.map((file) => file.path).toSet(),
        invalidPaths,
        clock,
      );
      await tx.update(
        'workspace_operations',
        {'status': 'Completed', 'completed_at': clock.millisecondsSinceEpoch},
        where:
            "status = 'Started' AND kind IN ('RescheduleSession','SetSessionDisposition')",
      );
      await tx.insert('settings', {
        'key': 'last_workspace_scan',
        'value': clock.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
    return SessionReconciliationSummary(
      scanned: sessionDocuments.length,
      completed: completed,
      pending: pending,
      errors: errors,
    );
  }

  Future<int> _syncDomainProjection(
    DatabaseExecutor tx,
    List<_MarkdownDocument> documents,
    Set<String> duplicateIds,
    Set<String> invalidPaths,
    String rootPath,
    DateTime now,
  ) async {
    var errors = 0;
    final active = <String>{};
    final knownSources = {
      for (final row in await tx.query('workspace_entity_sources'))
        '${row['entity_type']}:${row['entity_id']}': row,
    };
    for (final type in ['mission', 'project', 'task']) {
      final table = '${type}s';
      final typed = documents.where(
        (document) => document.metadata['type']?.toLowerCase() == type,
      );
      for (final document in typed) {
        final id = document.metadata['id']?.trim() ?? '';
        if (id.isEmpty) {
          errors++;
          continue;
        }
        final key = '$type:$id';
        active.add(key);
        if (duplicateIds.contains(id)) {
          await _storeEntitySource(
            tx,
            type,
            id,
            document,
            'Duplicate ID in Obsidian vault.',
            now,
          );
          continue;
        }
        final known = knownSources[key];
        if (!document.changed &&
            known?['path'] == document.relativePath &&
            (known?['error'] as String? ?? '').isEmpty) {
          continue;
        }
        final title = document.metadata['title']?.trim() ?? '';
        if (title.isEmpty) {
          errors++;
          await _storeEntitySource(
            tx,
            type,
            id,
            document,
            'Missing required title.',
            now,
          );
          continue;
        }
        final result = await _domainRow(tx, table, document, now);
        if (result.error.isNotEmpty) {
          errors++;
          await _storeEntitySource(tx, type, id, document, result.error, now);
          continue;
        }
        await _upsertRow(tx, table, {'id': id, 'title': title, ...result.row});
        await _storeEntitySource(tx, type, id, document, '', now);
      }
    }
    final existing = await tx.query('workspace_entity_sources');
    final documentPaths = documents.map((document) => document.path).toSet();
    for (final source in existing) {
      final key = '${source['entity_type']}:${source['entity_id']}';
      if (active.contains(key)) continue;
      final absolute = p.normalize(p.join(rootPath, source['path'] as String));
      final error = invalidPaths.contains(absolute)
          ? 'Markdown source has invalid YAML/frontmatter.'
          : documentPaths.contains(absolute)
          ? 'Markdown source no longer declares the expected type and ID.'
          : !File(absolute).existsSync()
          ? 'Markdown source is missing from the vault.'
          : '';
      if (error.isNotEmpty) {
        await tx.update(
          'workspace_entity_sources',
          {'error': error, 'updated_at': now.millisecondsSinceEpoch},
          where: 'entity_type = ? AND entity_id = ?',
          whereArgs: [source['entity_type'], source['entity_id']],
        );
        if (!invalidPaths.contains(absolute)) errors++;
      }
    }
    return errors;
  }

  Future<({Map<String, Object?> row, String error})> _domainRow(
    DatabaseExecutor tx,
    String table,
    _MarkdownDocument document,
    DateTime now,
  ) async {
    final metadata = document.metadata;
    final created = _dateFromMetadata(
      metadata['created'],
      fallback: now,
    ).millisecondsSinceEpoch;
    if (table == 'missions') {
      const statuses = {'Active', 'Paused', 'Completed', 'Archived'};
      final status = _canonicalValue(metadata['status'], statuses, 'Active');
      final priority = int.tryParse(metadata['priority'] ?? '') ?? 0;
      final confidence = int.tryParse(metadata['confidence'] ?? '') ?? 0;
      final strategyValue = metadata['strategy']?.trim() ?? '';
      final goalValue = metadata['goal']?.trim() ?? '';
      final strategy = await _existingReference(
        tx,
        'strategies',
        strategyValue,
      );
      final goal = await _existingReference(tx, 'goals', goalValue);
      final invalidDate =
          !_validOptionalDate(metadata['start_date']) ||
          !_validOptionalDate(metadata['target_date']);
      final missing = <String>[
        if (strategy == null)
          'strategy ${strategyValue.isEmpty ? '(empty)' : strategyValue}',
        if (goalValue.isNotEmpty && goal == null) 'goal $goalValue',
      ];
      if (status == null ||
          priority < 0 ||
          priority > 3 ||
          confidence < 0 ||
          confidence > 100 ||
          invalidDate ||
          missing.isNotEmpty) {
        return (
          row: const <String, Object?>{},
          error: missing.isNotEmpty
              ? 'Missing reference: ${missing.join(', ')}.'
              : 'Mission frontmatter contains an invalid status, number, or date.',
        );
      }
      return (
        row: {
          'strategy_id': strategy,
          'goal_id': goal,
          'description': document.section('Description'),
          'success_criteria': document.section('Success Criteria'),
          'status': status,
          'priority': priority,
          'confidence': confidence,
          'start_date': metadata['start_date']?.trim() ?? '',
          'target_date': metadata['target_date']?.trim() ?? '',
          'created_at': created,
        },
        error: '',
      );
    }
    if (table == 'projects') {
      const statuses = {'active', 'paused', 'completed', 'archived'};
      const types = {
        'Learning',
        'Product',
        'Career',
        'IncomeExperiment',
        'Content',
        'Personal',
      };
      final status = _canonicalValue(metadata['status'], statuses, 'active');
      final projectType = _canonicalValue(
        metadata['project_type'],
        types,
        'Personal',
      );
      final priority = int.tryParse(metadata['priority'] ?? '') ?? 2;
      final goalValue = metadata['goal']?.trim() ?? '';
      final outcomeValue = metadata['outcome']?.trim() ?? '';
      final initiativeValue = metadata['initiative']?.trim() ?? '';
      final goal = await _existingReference(tx, 'goals', goalValue);
      final outcome = await _existingReference(tx, 'outcomes', outcomeValue);
      final initiative = await _existingReference(
        tx,
        'initiatives',
        initiativeValue,
      );
      final start = _optionalDateMillis(metadata['start_at']);
      final target = _optionalDateMillis(metadata['target_at']);
      final missing = <String>[
        if (goalValue.isNotEmpty && goal == null) 'goal $goalValue',
        if (outcomeValue.isNotEmpty && outcome == null) 'outcome $outcomeValue',
        if (initiativeValue.isNotEmpty && initiative == null)
          'initiative $initiativeValue',
      ];
      final relationshipError = missing.isEmpty
          ? await _projectRelationshipError(
              tx,
              goal: goal,
              outcome: outcome,
              initiative: initiative,
            )
          : '';
      if (status == null ||
          projectType == null ||
          priority < 1 ||
          priority > 3 ||
          start.invalid ||
          target.invalid ||
          missing.isNotEmpty ||
          relationshipError.isNotEmpty) {
        return (
          row: const <String, Object?>{},
          error: missing.isNotEmpty
              ? 'Missing reference: ${missing.join(', ')}.'
              : relationshipError.isNotEmpty
              ? relationshipError
              : 'Project frontmatter contains an invalid status, type, number, or date.',
        );
      }
      return (
        row: {
          'description': document.section('Description'),
          'goal_id': goal,
          'outcome_id': outcome,
          'initiative_id': initiative,
          'project_type': projectType,
          'priority': priority,
          'status': status,
          'start_at': start.value,
          'target_at': target.value,
          'next_action': document.section('Next Action'),
          'created_at': created,
        },
        error: '',
      );
    }
    const statuses = {
      'Backlog',
      'Planned',
      'InProgress',
      'Blocked',
      'Done',
      'Cancelled',
    };
    final status = _canonicalValue(metadata['status'], statuses, 'Backlog');
    final priority = int.tryParse(metadata['priority'] ?? '') ?? 2;
    final projectValue = metadata['project']?.trim() ?? '';
    final project = await _existingReference(tx, 'projects', projectValue);
    final scheduled = _optionalDateMillis(metadata['scheduled_at']);
    final estimated = _optionalInt(metadata['estimated_minutes']);
    final actual = _optionalInt(metadata['actual_minutes']);
    if (status == null ||
        priority < 1 ||
        priority > 3 ||
        scheduled.invalid ||
        estimated.invalid ||
        actual.invalid ||
        (estimated.value != null && estimated.value! <= 0) ||
        (actual.value != null && actual.value! < 0) ||
        (projectValue.isNotEmpty && project == null)) {
      return (
        row: const <String, Object?>{},
        error: projectValue.isNotEmpty && project == null
            ? 'Missing reference: project $projectValue.'
            : 'Task frontmatter contains an invalid status, number, or date.',
      );
    }
    return (
      row: {
        'project_id': project,
        'description': document.section('Description'),
        'status': status,
        'done': status == 'Done' ? 1 : 0,
        'scheduled_at': scheduled.value,
        'estimated_minutes': estimated.value,
        'actual_minutes': actual.value,
        'priority': priority,
        'created_at': created,
      },
      error: '',
    );
  }

  Future<String> _projectRelationshipError(
    DatabaseExecutor tx, {
    required String? goal,
    required String? outcome,
    required String? initiative,
  }) async {
    if (outcome != null && goal != null) {
      final outcomes = await tx.query(
        'outcomes',
        where: 'id = ?',
        whereArgs: [outcome],
      );
      final missions = outcomes.isEmpty
          ? const <Map<String, Object?>>[]
          : await tx.query(
              'missions',
              where: 'id = ?',
              whereArgs: [outcomes.single['mission_id']],
            );
      if (missions.isEmpty || missions.single['goal_id'] != goal) {
        return 'Project goal and outcome do not belong to the same mission path.';
      }
    }
    if (initiative != null) {
      final rows = await tx.query(
        'initiatives',
        where: 'id = ?',
        whereArgs: [initiative],
      );
      if (rows.isEmpty) return 'Project initiative is missing.';
      final row = rows.single;
      if (outcome != null &&
          row['outcome_id'] != null &&
          row['outcome_id'] != outcome) {
        return 'Project outcome does not match its initiative outcome.';
      }
      if (goal != null) {
        final missions = await tx.query(
          'missions',
          where: 'id = ?',
          whereArgs: [row['mission_id']],
        );
        if (missions.isEmpty || missions.single['goal_id'] != goal) {
          return 'Project goal and initiative do not share a mission path.';
        }
      }
    }
    return '';
  }

  Future<void> _storeEntitySource(
    DatabaseExecutor tx,
    String type,
    String id,
    _MarkdownDocument document,
    String error,
    DateTime now,
  ) => tx.insert('workspace_entity_sources', {
    'entity_type': type,
    'entity_id': id,
    'path': document.relativePath,
    'checksum': document.checksum,
    'error': error,
    'updated_at': now.millisecondsSinceEpoch,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  String? _canonicalValue(String? value, Set<String> allowed, String fallback) {
    final input = value?.trim().isNotEmpty == true ? value!.trim() : fallback;
    return allowed
        .where((item) => item.toLowerCase() == input.toLowerCase())
        .firstOrNull;
  }

  bool _validOptionalDate(String? value) =>
      value == null ||
      value.trim().isEmpty ||
      DateTime.tryParse(value.trim()) != null;

  ({int? value, bool invalid}) _optionalDateMillis(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return (value: null, invalid: false);
    final parsed = DateTime.tryParse(input);
    return parsed == null
        ? (value: null, invalid: true)
        : (value: parsed.millisecondsSinceEpoch, invalid: false);
  }

  ({int? value, bool invalid}) _optionalInt(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return (value: null, invalid: false);
    final parsed = int.tryParse(input);
    return (value: parsed, invalid: parsed == null);
  }

  Future<void> _updateFileIndex(
    DatabaseExecutor tx,
    List<_MarkdownDocument> documents,
    Set<String> scannedPaths,
    Set<String> invalidPaths,
    DateTime now,
  ) async {
    for (final document in documents) {
      if (!document.changed) continue;
      await tx.insert('workspace_file_index', {
        'path': document.path,
        'size': document.sourceSize,
        'modified_at': document.modifiedAt,
        'checksum': document.checksum,
        'metadata_json': jsonEncode(document.metadata),
        'body': document.body,
        'updated_at': now.millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    final indexed = await tx.query('workspace_file_index', columns: ['path']);
    for (final row in indexed) {
      final path = row['path'] as String;
      if (!scannedPaths.contains(path) || invalidPaths.contains(path)) {
        await tx.delete(
          'workspace_file_index',
          where: 'path = ?',
          whereArgs: [path],
        );
      }
    }
  }

  Future<void> _syncKnowledge(
    DatabaseExecutor tx,
    String rootPath,
    List<_MarkdownDocument> documents,
    Set<String> duplicateIds,
    DateTime now,
  ) async {
    final notes = documents
        .where(
          (document) => !_structuredDocumentTypes.contains(
            document.metadata['type']?.toLowerCase(),
          ),
        )
        .toList();
    final activePaths = notes.map((document) => document.path).toSet();
    final existing = await tx.query(
      'knowledge',
      columns: ['id', 'managed_source_path'],
      where: "managed_source_path <> ''",
    );
    for (final duplicateId in duplicateIds) {
      await tx.delete(
        'knowledge',
        where: "id = ? AND managed_source_path <> ''",
        whereArgs: [duplicateId],
      );
    }
    for (final document in notes) {
      if (!document.changed) continue;
      final explicitId = document.metadata['id']?.trim() ?? '';
      if (explicitId.isNotEmpty && duplicateIds.contains(explicitId)) continue;
      final id = explicitId.isNotEmpty
          ? explicitId
          : 'vault-note-${_checksum(utf8.encode(document.relativePath.toLowerCase()))}';
      final title = document.metadata['title']?.trim().isNotEmpty == true
          ? document.metadata['title']!.trim()
          : p.basenameWithoutExtension(document.path);
      final row = {
        'id': id,
        'title': title,
        'type': document.metadata['type'] ?? 'Note',
        'content': document.body,
        'tags': document.metadata['tags'] ?? '',
        'source_filename': p.basename(document.path),
        'source_checksum': document.checksum,
        'source_size': document.sourceSize,
        'source_modified_at': document.modifiedAt,
        'imported_at': now.millisecondsSinceEpoch,
        'source_mime': 'text/markdown',
        'managed_source_path': document.path,
        'created_at': _dateFromMetadata(
          document.metadata['created'],
        ).millisecondsSinceEpoch,
        'updated_at': _dateFromMetadata(
          document.metadata['updated'],
          fallback: now,
        ).millisecondsSinceEpoch,
      };
      await tx.insert(
        'knowledge',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    for (final row in existing) {
      final path = p.normalize(row['managed_source_path'] as String);
      if (p.isWithin(rootPath, path) && !activePaths.contains(path)) {
        await tx.delete(
          'knowledge',
          where: 'id = ? AND managed_source_path = ?',
          whereArgs: [row['id'], row['managed_source_path']],
        );
      }
    }
  }

  Future<void> _syncPlanningProjection(
    DatabaseExecutor tx,
    List<_MarkdownDocument> documents,
    Set<String> duplicateIds,
  ) async {
    for (final duplicateId in duplicateIds) {
      await tx.update(
        'recurring_schedules',
        {'enabled': 0},
        where: 'id = ? OR template_id = ?',
        whereArgs: [duplicateId, duplicateId],
      );
    }
    final templates = documents.where(
      (document) =>
          document.changed &&
          document.metadata['type']?.toLowerCase() == 'session_template',
    );
    for (final document in templates) {
      final id = document.metadata['id']?.trim() ?? '';
      final title = document.metadata['title']?.trim() ?? '';
      final minutes = int.tryParse(document.metadata['planned_minutes'] ?? '');
      if (id.isEmpty ||
          title.isEmpty ||
          minutes == null ||
          minutes <= 0 ||
          duplicateIds.contains(id)) {
        continue;
      }
      final row = <String, Object?>{
        'id': id,
        'title': title,
        'project_id': await _existingReference(
          tx,
          'projects',
          document.metadata['project'],
        ),
        'why': document.section('Why'),
        'input': document.section('Input'),
        'target': document.section('Goal'),
        'priority': int.tryParse(document.metadata['priority'] ?? '') ?? 2,
        'planned_minutes': minutes,
        'created_at': _dateFromMetadata(
          document.metadata['created'],
        ).millisecondsSinceEpoch,
      };
      await _upsertRow(tx, 'session_templates', row);
    }
    final schedules = documents.where(
      (document) =>
          document.changed &&
          document.metadata['type']?.toLowerCase() == 'recurring_schedule',
    );
    for (final document in schedules) {
      final id = document.metadata['id']?.trim() ?? '';
      final title = document.metadata['title']?.trim() ?? '';
      final template = document.metadata['template']?.trim() ?? '';
      final weekdays = document.metadata['weekdays']?.trim() ?? '';
      final localTime = document.metadata['local_time']?.trim() ?? '';
      final validTemplate = await _existingReference(
        tx,
        'session_templates',
        template,
      );
      if (id.isEmpty ||
          title.isEmpty ||
          validTemplate == null ||
          !RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(localTime) ||
          !_validWeekdays(weekdays) ||
          duplicateIds.contains(id)) {
        continue;
      }
      final row = <String, Object?>{
        'id': id,
        'template_id': validTemplate,
        'title': title,
        'weekdays': weekdays,
        'local_time': localTime,
        'enabled':
            (document.metadata['enabled'] ?? 'true').toLowerCase() == 'false'
            ? 0
            : 1,
        'start_date': document.metadata['start_date'] ?? '',
        'end_date': document.metadata['end_date'] ?? '',
        'created_at': _dateFromMetadata(
          document.metadata['created'],
        ).millisecondsSinceEpoch,
      };
      await _upsertRow(tx, 'recurring_schedules', row);
    }
  }

  Future<void> _upsertRow(
    DatabaseExecutor tx,
    String table,
    Map<String, Object?> row,
  ) async {
    final existing = await tx.query(
      table,
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [row['id']],
    );
    if (existing.isEmpty) {
      await tx.insert(table, row);
    } else {
      final changes = {...row}..remove('id');
      await tx.update(table, changes, where: 'id = ?', whereArgs: [row['id']]);
    }
  }

  bool _validWeekdays(String value) {
    final days = value
        .split(',')
        .map((part) => int.tryParse(part.trim()))
        .toList();
    return days.isNotEmpty &&
        days.every((day) => day != null && day >= 1 && day <= 7);
  }

  Future<void> _upsertOutput(
    DatabaseExecutor tx,
    Map<String, Object?> session,
    _MarkdownDocument document,
    String output,
    DateTime now,
  ) async {
    final existing = await tx.query(
      'outputs',
      columns: ['id'],
      where: 'session_id = ? AND notes = ?',
      whereArgs: [session['id'], _projectionMarker],
      limit: 1,
    );
    final id =
        existing.firstOrNull?['id'] as String? ??
        _outputId(session['id'] as String);
    final row = {
      'id': id,
      'title': '${session['title']} — output',
      'type': 'Artifact',
      'description': output,
      'project_id': session['project_id'],
      'session_id': session['id'],
      'link': document.path,
      'notes': _projectionMarker,
      'created_at': _date(session['planned_start']).millisecondsSinceEpoch,
    };
    await tx.insert(
      'outputs',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> _existingReference(
    DatabaseExecutor tx,
    String table,
    String? value,
  ) async {
    final id = value?.trim() ?? '';
    if (id.isEmpty) return null;
    final rows = await tx.query(
      table,
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : id;
  }

  _MarkdownDocument _parseDocument(File file, String rootPath) {
    final source = file.readAsStringSync();
    final lines = source.replaceAll('\r\n', '\n').split('\n');
    final metadata = <String, String>{};
    var bodyStart = 0;
    if (lines.firstOrNull?.trim() == '---') {
      final end = lines.indexWhere((line) => line.trim() == '---', 1);
      if (end < 0) throw const FormatException('Unclosed YAML frontmatter.');
      for (var index = 1; index < end; index++) {
        final line = lines[index];
        if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
        final separator = line.indexOf(':');
        if (line.startsWith(' ') || line.startsWith('\t')) {
          continue;
        }
        if (separator <= 0) {
          throw FormatException(
            'Invalid YAML/frontmatter at line ${index + 1}.',
          );
        }
        final key = line.substring(0, separator).trim();
        if (metadata.containsKey(key)) {
          throw FormatException('Duplicate YAML key "$key".');
        }
        var value = line.substring(separator + 1).trim();
        if (value.length >= 2 &&
            ((value.startsWith('"') && value.endsWith('"')) ||
                (value.startsWith("'") && value.endsWith("'")))) {
          value = value.substring(1, value.length - 1);
        }
        metadata[key] = value;
      }
      bodyStart = end + 1;
    }
    final body = lines.skip(bodyStart).join('\n');
    return _MarkdownDocument(
      path: p.normalize(file.path),
      relativePath: p.relative(file.path, from: rootPath),
      body: body,
      metadata: metadata,
      checksum: _checksum(utf8.encode(source)),
      sourceSize: utf8.encode(source).length,
      modifiedAt: file.lastModifiedSync().millisecondsSinceEpoch,
      changed: true,
    );
  }

  bool _hasValidOutput(
    _MarkdownDocument document,
    String value,
    List<_MarkdownDocument> allDocuments,
  ) {
    final cleaned = value
        .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '')
        .replaceAll(RegExp(r'^\s*[-*]\s*\[\s\]\s*$', multiLine: true), '')
        .trim();
    if (cleaned.isEmpty ||
        {
          'todo',
          'tbd',
          'n/a',
          'none',
          'placeholder',
        }.contains(cleaned.toLowerCase())) {
      return false;
    }
    final wikiLinks = RegExp(
      r'!??\[\[([^\]|#]+)(?:#[^\]|]+)?(?:\|[^\]]+)?\]\]',
    ).allMatches(cleaned).map((match) => match.group(1)!.trim()).toList();
    final markdownLinks = RegExp(r'\[[^\]]+\]\(([^)]+)\)')
        .allMatches(cleaned)
        .map((match) => match.group(1)!.trim())
        .where(
          (target) =>
              !target.startsWith('http://') && !target.startsWith('https://'),
        )
        .toList();
    final textOnly = cleaned
        .replaceAll(RegExp(r'!??\[\[[^\]]+\]\]'), '')
        .replaceAll(RegExp(r'\[[^\]]+\]\([^)]+\)'), '')
        .replaceAll(RegExp(r'[-*_#>`\s]'), '');
    if (textOnly.isNotEmpty) return true;
    for (final target in wikiLinks) {
      if (allDocuments.any(
        (candidate) =>
            p.basenameWithoutExtension(candidate.path).toLowerCase() ==
            p.basenameWithoutExtension(target).toLowerCase(),
      )) {
        return true;
      }
    }
    for (final target in markdownLinks) {
      final normalized = p.normalize(p.join(p.dirname(document.path), target));
      if (File(normalized).existsSync()) return true;
    }
    return cleaned.contains(RegExp(r'https?://'));
  }

  String _renderSession(
    Map<String, Object?> row,
    String output,
    String learning,
  ) {
    final start = _date(row['planned_start']);
    final status = switch (row['status']) {
      'DONE' => 'done',
      'SKIPPED' => 'skipped',
      'CANCELLED' => 'cancelled',
      _ => 'planned',
    };
    return '''---
id: ${row['id']}
type: session
title: ${_yamlScalar(row['title'] as String)}
schedule: ${row['recurring_schedule_id'] ?? ''}
project: ${row['project_id'] ?? ''}
task: ${row['task_id'] ?? ''}
planned_start: ${start.toIso8601String()}
planned_minutes: ${row['planned_minutes']}
status: $status
created: ${_date(row['created_at']).toIso8601String()}
updated: ${DateTime.now().toIso8601String()}
---

# ${row['title']}

## Goal

${row['target'] ?? ''}

## Input

${row['input'] ?? ''}

## Output

$output

## Learning

$learning

## Next Action

${row['next_action'] ?? ''}
''';
  }

  String _domainType(String table) => switch (table) {
    'missions' => 'mission',
    'projects' => 'project',
    'tasks' => 'task',
    _ => throw ArgumentError('Unsupported Markdown domain table: $table'),
  };

  String _domainFolder(String table) => switch (table) {
    'missions' => '02 Missions',
    'projects' => '03 Projects',
    'tasks' => '04 Tasks',
    _ => throw ArgumentError('Unsupported Markdown domain table: $table'),
  };

  String _domainPath(
    String rootPath,
    String table,
    Map<String, Object?> row,
  ) => p.join(
    rootPath,
    _domainFolder(table),
    '${_domainType(table)}-${_slug(row['title'] as String)}-${_shortId(row['id'] as String)}.md',
  );

  Future<File> _claimableFile(
    String preferredPath,
    String rootPath,
    String id,
  ) async {
    var file = File(preferredPath);
    if (!await file.exists() || _documentId(file, rootPath) == id) return file;
    final suffix = _checksum(utf8.encode(id)).substring(0, 8);
    file = File(
      p.join(
        p.dirname(preferredPath),
        '${p.basenameWithoutExtension(preferredPath)}-$suffix.md',
      ),
    );
    if (await file.exists() && _documentId(file, rootPath) != id) {
      throw StateError(
        'Cannot create a Markdown record without overwriting an existing file.',
      );
    }
    return file;
  }

  String _renderDomainDocument(String table, Map<String, Object?> row) {
    final frontmatter = _domainFrontmatterChanges(table, row);
    final fields = <String, String>{
      'id': row['id'] as String,
      'type': _domainType(table),
      ...frontmatter,
      'created': _date(row['created_at']).toIso8601String(),
    };
    final yaml = fields.entries
        .map((entry) => '${entry.key}: ${_yamlScalar(entry.value)}')
        .join('\n');
    final sections = _domainSections(table, row).entries
        .map((entry) => '## ${entry.key}\n\n${entry.value.trim()}')
        .join('\n\n');
    return '''---
$yaml
---

# ${row['title']}

$sections
''';
  }

  Map<String, String> _domainFrontmatterChanges(
    String table,
    Map<String, Object?> row,
  ) {
    final updated = DateTime.now().toIso8601String();
    return switch (table) {
      'missions' => {
        'title': row['title'] as String,
        'strategy': row['strategy_id'] as String? ?? '',
        'goal': row['goal_id'] as String? ?? '',
        'status': row['status'] as String? ?? 'Active',
        'priority': '${row['priority'] ?? 0}',
        'confidence': '${row['confidence'] ?? 0}',
        'start_date': row['start_date'] as String? ?? '',
        'target_date': row['target_date'] as String? ?? '',
        'updated': updated,
      },
      'projects' => {
        'title': row['title'] as String,
        'goal': row['goal_id'] as String? ?? '',
        'outcome': row['outcome_id'] as String? ?? '',
        'initiative': row['initiative_id'] as String? ?? '',
        'project_type': row['project_type'] as String? ?? 'Personal',
        'status': row['status'] as String? ?? 'active',
        'priority': '${row['priority'] ?? 2}',
        'start_at': _optionalIso(row['start_at']),
        'target_at': _optionalIso(row['target_at']),
        'updated': updated,
      },
      'tasks' => {
        'title': row['title'] as String,
        'project': row['project_id'] as String? ?? '',
        'status': row['status'] as String? ?? 'Backlog',
        'priority': '${row['priority'] ?? 2}',
        'scheduled_at': _optionalIso(row['scheduled_at']),
        'estimated_minutes': '${row['estimated_minutes'] ?? ''}',
        'actual_minutes': '${row['actual_minutes'] ?? ''}',
        'updated': updated,
      },
      _ => throw ArgumentError('Unsupported Markdown domain table: $table'),
    };
  }

  Map<String, String> _domainSections(String table, Map<String, Object?> row) =>
      switch (table) {
        'missions' => {
          'Description': row['description'] as String? ?? '',
          'Success Criteria': row['success_criteria'] as String? ?? '',
        },
        'projects' => {
          'Description': row['description'] as String? ?? '',
          'Next Action': row['next_action'] as String? ?? '',
        },
        'tasks' => {'Description': row['description'] as String? ?? ''},
        _ => throw ArgumentError('Unsupported Markdown domain table: $table'),
      };

  String _optionalIso(Object? value) => value is int
      ? DateTime.fromMillisecondsSinceEpoch(value).toIso8601String()
      : '';

  String _planningPath(
    String rootPath,
    String table,
    Map<String, Object?> row,
  ) {
    final directory = table == 'session_templates' ? 'Templates' : 'Schedules';
    return p.join(
      rootPath,
      '11 Sessions',
      directory,
      '${table == 'session_templates' ? 'template' : 'schedule'}-${_slug(row['id'] as String)}.md',
    );
  }

  String _renderPlanningDocument(String table, Map<String, Object?> row) {
    final created = _date(row['created_at']).toIso8601String();
    if (table == 'session_templates') {
      return '''---
id: ${row['id']}
type: session_template
title: ${_yamlScalar(row['title'] as String)}
project: ${row['project_id'] ?? ''}
planned_minutes: ${row['planned_minutes']}
priority: ${row['priority']}
created: $created
updated: ${DateTime.now().toIso8601String()}
---

# ${row['title']}

## Why

${row['why'] ?? ''}

## Goal

${row['target'] ?? ''}

## Input

${row['input'] ?? ''}
''';
    }
    return '''---
id: ${row['id']}
type: recurring_schedule
title: ${_yamlScalar(row['title'] as String)}
template: ${row['template_id']}
weekdays: ${_yamlScalar(row['weekdays'] as String)}
local_time: ${_yamlScalar(row['local_time'] as String)}
enabled: ${(row['enabled'] as int? ?? 1) == 1}
start_date: ${row['start_date'] ?? ''}
end_date: ${row['end_date'] ?? ''}
created: $created
updated: ${DateTime.now().toIso8601String()}
---

# ${row['title']}
''';
  }

  String _patchFrontmatter(String source, Map<String, String> changes) {
    final newline = source.contains('\r\n') ? '\r\n' : '\n';
    final normalized = source.replaceAll('\r\n', '\n');
    final lines = normalized.split('\n');
    if (lines.firstOrNull?.trim() != '---') {
      throw const FormatException('Session note has no YAML frontmatter.');
    }
    final end = lines.indexWhere((line) => line.trim() == '---', 1);
    if (end < 0) throw const FormatException('Unclosed YAML frontmatter.');
    final remaining = {...changes};
    for (var index = 1; index < end; index++) {
      final separator = lines[index].indexOf(':');
      if (separator <= 0) continue;
      final key = lines[index].substring(0, separator).trim();
      if (remaining.containsKey(key)) {
        lines[index] = '$key: ${_yamlScalar(remaining.remove(key)!)}';
      }
    }
    lines.insertAll(
      end,
      remaining.entries.map(
        (entry) => '${entry.key}: ${_yamlScalar(entry.value)}',
      ),
    );
    return lines.join(newline);
  }

  String _patchSection(String source, String title, String content) {
    final newline = source.contains('\r\n') ? '\r\n' : '\n';
    final normalized = source.replaceAll('\r\n', '\n');
    final heading = RegExp(
      '^##[ \\t]+${RegExp.escape(title)}[ \\t]*\$',
      caseSensitive: false,
      multiLine: true,
    ).firstMatch(normalized);
    final replacement = '## $title\n\n${content.trim()}\n\n';
    late final String updated;
    if (heading == null) {
      updated = '${normalized.trimRight()}\n\n$replacement';
    } else {
      final remainder = normalized.substring(heading.end);
      final nextHeading = RegExp(
        r'^##[ \t]+',
        multiLine: true,
      ).firstMatch(remainder);
      final end = nextHeading == null
          ? normalized.length
          : heading.end + nextHeading.start;
      updated = normalized.replaceRange(heading.start, end, replacement);
    }
    return updated.replaceAll('\n', newline);
  }

  Future<void> _writeWithRevision(
    File file,
    String content,
    String expectedChecksum,
  ) async {
    final current = await _fileChecksum(file);
    if (current != expectedChecksum) {
      throw StateError(
        'External change detected. Reload the session note and try again.',
      );
    }
    await _atomicWrite(file, content);
  }

  Future<void> _writeIfMissing(File file, String content) async {
    if (!await file.exists()) await _atomicWrite(file, content);
  }

  Future<void> _atomicWrite(File target, String content) async {
    await target.parent.create(recursive: true);
    final temporary = File(
      '${target.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    await temporary.writeAsString(content, flush: true);
    await temporary.rename(target.path);
  }

  Future<String> _fileChecksum(File file) async =>
      _checksum(await file.readAsBytes());

  static String _checksum(List<int> bytes) {
    var first = 0x811c9dc5;
    var second = 0x9e3779b9;
    for (final byte in bytes) {
      first = ((first ^ byte) * 0x01000193) & 0xffffffff;
      second = ((second ^ (byte + 31)) * 0x01000193) & 0xffffffff;
    }
    return '${first.toRadixString(16).padLeft(8, '0')}${second.toRadixString(16).padLeft(8, '0')}';
  }

  static DateTime _date(Object? value) => switch (value) {
    int milliseconds => DateTime.fromMillisecondsSinceEpoch(milliseconds),
    String text => DateTime.tryParse(text) ?? DateTime(2000),
    _ => DateTime(2000),
  };

  static DateTime _dateFromMetadata(String? value, {DateTime? fallback}) =>
      DateTime.tryParse(value ?? '') ?? fallback ?? DateTime.now();

  static String _isoDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  static String _slug(String value) {
    final slug = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty
        ? 'session'
        : slug.substring(0, slug.length.clamp(0, 48));
  }

  static String _shortId(String value) =>
      value.length <= 8 ? value : value.substring(value.length - 8);

  static String _outputId(String sessionId) => 'session-output-$sessionId';

  static const _projectionMarker = 'Projected from Obsidian session note.';

  static const _structuredDocumentTypes = {
    'session',
    'session_template',
    'recurring_schedule',
    'vision',
    'strategy',
    'mission',
    'outcome',
    'initiative',
    'goal',
    'project',
    'task',
    'skill',
    'evidence',
    'review',
    'experiment',
  };

  static String _yamlScalar(String value) {
    if (value.isEmpty) return '';
    if (RegExp(r'''[:#\[\]{},&*!|>@`"'\n\r]''').hasMatch(value) ||
        value.trim() != value) {
      return jsonEncode(value);
    }
    return value;
  }
}

class _MarkdownDocument {
  final String path;
  final String relativePath;
  final String body;
  final Map<String, String> metadata;
  final String checksum;
  final int sourceSize;
  final int modifiedAt;
  final bool changed;

  const _MarkdownDocument({
    required this.path,
    required this.relativePath,
    required this.body,
    required this.metadata,
    required this.checksum,
    required this.sourceSize,
    required this.modifiedAt,
    required this.changed,
  });

  String section(String title) {
    final heading = RegExp(
      '^##[ \\t]+${RegExp.escape(title)}[ \\t]*\$',
      caseSensitive: false,
      multiLine: true,
    ).firstMatch(body);
    if (heading == null) return '';
    final remainder = body.substring(heading.end);
    final nextHeading = RegExp(
      r'^##[ \t]+',
      multiLine: true,
    ).firstMatch(remainder);
    final end = nextHeading == null
        ? body.length
        : heading.end + nextHeading.start;
    return body.substring(heading.end, end).trim();
  }
}

class _ScannedFile {
  final String path;
  final int size;
  final int modifiedAt;

  const _ScannedFile({
    required this.path,
    required this.size,
    required this.modifiedAt,
  });
}

const _sessionTemplate = '''---
id:
type: session
title:
schedule:
project:
task:
planned_start:
planned_minutes: 60
status: planned
created:
updated:
---

# {{title}}

## Goal

## Input

## Output

## Learning

## Next Action
''';

const _missionTemplate = '''---
id:
type: mission
title:
strategy:
goal:
status: Active
priority: 0
confidence: 0
start_date:
target_date:
created:
updated:
---

# {{title}}

## Description

## Success Criteria
''';

const _projectTemplate = '''---
id:
type: project
title:
goal:
outcome:
initiative:
project_type: Personal
status: active
priority: 2
start_at:
target_at:
created:
updated:
---

# {{title}}

## Description

## Next Action
''';

const _taskTemplate = '''---
id:
type: task
title:
project:
status: Backlog
priority: 2
scheduled_at:
estimated_minutes:
actual_minutes:
created:
updated:
---

# {{title}}

## Description
''';
