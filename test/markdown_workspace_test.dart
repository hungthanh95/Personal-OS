import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:personal_os/domain/models.dart';
import 'package:personal_os/infrastructure/sqlite_repository.dart';

void main() {
  late Directory temp;
  late Directory vault;
  late SqliteWorkspaceRepository repository;
  final now = DateTime(2026, 9, 14, 22, 5);

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('personal_os_markdown_');
    vault = await Directory('${temp.path}/vault').create();
    repository = await SqliteWorkspaceRepository.open(
      '${temp.path}/projection.sqlite',
      demo: false,
    );
    await repository.save('sessions', {
      'id': 'session-1',
      'title': 'Modern C++ Smart Pointers',
      'planned_start': DateTime(2026, 9, 14, 21).millisecondsSinceEpoch,
      'planned_minutes': 60,
      'created_at': DateTime(2026, 9, 13).millisecondsSinceEpoch,
    });
    await repository.configureMarkdownWorkspace(vault.path);
  });

  tearDown(() async {
    await repository.close();
    await temp.delete(recursive: true);
  });

  Future<File> sessionNote() async =>
      File(await repository.sessionNotePath('session-1'));

  test(
    'workspace initialization creates folders, metadata and session note',
    () async {
      expect(await Directory('${vault.path}/11 Sessions').exists(), isTrue);
      expect(
        await File('${vault.path}/_templates/session.md').exists(),
        isTrue,
      );
      expect(
        await File('${vault.path}/.personal-os/workspace.yaml').exists(),
        isTrue,
      );
      final note = await sessionNote();
      expect(await note.exists(), isTrue);
      final text = await note.readAsString();
      expect(text, contains('id: session-1'));
      expect(text, contains('status: planned'));
      expect(text, contains('## Output'));
    },
  );

  test('session note creation preserves a colliding user file', () async {
    await repository.save('sessions', {
      'id': 'session-2',
      'title': 'Collision Session',
      'planned_start': DateTime(2026, 9, 14, 18).millisecondsSinceEpoch,
      'planned_minutes': 30,
      'created_at': DateTime(2026, 9, 13).millisecondsSinceEpoch,
    });
    final collision = File(
      '${vault.path}/11 Sessions/2026-09-14-collision-session-session-2.md',
    );
    await collision.writeAsString('# Existing user note');

    await repository.syncMarkdownRecord('sessions', 'session-2');
    expect(await collision.readAsString(), '# Existing user note');
    final generated = File(await repository.sessionNotePath('session-2'));
    expect(p.equals(generated.path, collision.path), isFalse);
    expect(await generated.readAsString(), contains('id: session-2'));
  });

  test(
    'unchanged Markdown is reused from the incremental file index',
    () async {
      await repository.reconcileSessions(now: now);
      final first = await repository.db.query(
        'workspace_file_index',
        orderBy: 'path',
      );
      await repository.reconcileSessions(
        now: now.add(const Duration(hours: 1)),
      );
      final second = await repository.db.query(
        'workspace_file_index',
        orderBy: 'path',
      );
      expect(first, isNotEmpty);
      expect(
        second.map((row) => row['updated_at']),
        first.map((row) => row['updated_at']),
      );
    },
  );

  test(
    'an interrupted planning batch repairs its session note before scan',
    () async {
      final changedStart = DateTime(2026, 9, 15, 20);
      final stamp = DateTime.now().millisecondsSinceEpoch;
      await repository.db.insert('recommendations', {
        'id': 'recommendation-recovery',
        'type': 'Planning',
        'title': 'Move the session',
        'reason': 'Test recovery',
        'confidence': 80,
        'created_at': stamp,
      });
      await repository.db.insert('planning_change_sets', {
        'id': 'change-set-recovery',
        'recommendation_id': 'recommendation-recovery',
        'title': 'Recovered plan',
        'status': 'Applied',
        'created_at': stamp,
        'applied_at': stamp,
      });
      await repository.db.insert('planning_changes', {
        'id': 'change-recovery',
        'change_set_id': 'change-set-recovery',
        'action': 'UpdateSession',
        'target_id': 'session-1',
        'payload_json': '{}',
        'status': 'Applied',
        'created_at': stamp,
      });
      await repository.db.update(
        'sessions',
        {'planned_start': changedStart.millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: ['session-1'],
      );
      await repository.db.insert('workspace_operations', {
        'id': 'operation-recovery',
        'kind': 'ApplyPlanningChangeSet',
        'status': 'Started',
        'payload_json': '{"change_set_id":"change-set-recovery"}',
        'created_at': stamp,
      });

      await repository.reconcileSessions(now: changedStart);

    expect(
      await sessionNote().then((file) => file.readAsString()),
      contains(changedStart.toIso8601String()),
    );
      final operations = await repository.db.query(
        'workspace_operations',
        where: 'id = ?',
        whereArgs: ['operation-recovery'],
      );
      expect(operations.single['status'], 'Completed');
    },
  );

  test(
    'workspace backup contains both the vault and SQLite projection',
    () async {
      await File(
        '${vault.path}/10 Knowledge/backup-note.md',
      ).writeAsString('# Backup me');
      final backup = File('${temp.path}/workspace.zip');
      await repository.backupWorkspace(backup.path);

      final archive = ZipDecoder().decodeBytes(await backup.readAsBytes());
      final names = archive.files.map((file) => file.name).toSet();
      expect(names, contains('personal-os/database.sqlite'));
      expect(names, contains('personal-os/vault/10 Knowledge/backup-note.md'));
      expect(
        names.any((name) => name.endsWith('.personal-os/workspace.yaml')),
        isTrue,
      );
    },
  );

  test(
    'local projection still loads while the configured vault is offline',
    () async {
      final disconnected = Directory('${temp.path}/vault-offline');
      await vault.rename(disconnected.path);

      final workspace = await repository.load();
      expect(workspace.sessions.single.id, 'session-1');
      await expectLater(
        repository.reconcileSessions(now: now),
        throwsA(isA<FileSystemException>()),
      );
    },
  );

  test('done plus output after planned end confirms once', () async {
    final note = await sessionNote();
    var text = await note.readAsString();
    text = text.replaceFirst('status: planned', 'status: done');
    text = text.replaceFirst(
      '## Output\n\n',
      '## Output\n\nImplemented unique_ptr ownership example.\n\n',
    );
    await note.writeAsString(text);

    final first = await repository.reconcileSessions(now: now);
    final second = await repository.reconcileSessions(now: now);
    final workspace = await repository.load();
    expect(first.completed, 1);
    expect(second.completed, 1);
    expect(workspace.sessions.single.status, SessionStatus.done);
    expect(workspace.sessions.single.actualSeconds, 0);
    expect(workspace.sessions.single.outputMarkdown, contains('unique_ptr'));
    expect(
      workspace.outputs.where((item) => item.sessionId == 'session-1'),
      hasLength(1),
    );
  });

  test(
    'done without output remains pending and removing output recalculates',
    () async {
      final note = await sessionNote();
      var text = (await note.readAsString()).replaceFirst(
        'status: planned',
        'status: done',
      );
      await note.writeAsString(text);
      var result = await repository.reconcileSessions(now: now);
      var workspace = await repository.load();
      expect(result.pending, 1);
      expect(workspace.sessions.single.status, SessionStatus.planned);
      expect(workspace.sessions.single.reconciliationError, contains('Output'));

      text = text.replaceFirst('## Output\n\n', '## Output\n\nA result\n\n');
      await note.writeAsString(text);
      await repository.reconcileSessions(now: now);
      expect(
        (await repository.load()).sessions.single.status,
        SessionStatus.done,
      );

      text = text.replaceFirst('## Output\n\nA result\n\n', '## Output\n\n');
      await note.writeAsString(text);
      result = await repository.reconcileSessions(now: now);
      workspace = await repository.load();
      expect(result.pending, 1);
      expect(workspace.sessions.single.status, SessionStatus.planned);
      expect(workspace.outputs, isEmpty);
    },
  );

  test('link-only output must resolve inside the vault', () async {
    final note = await sessionNote();
    var text = await note.readAsString();
    text = text.replaceFirst('status: planned', 'status: done');
    text = text.replaceFirst(
      '## Output\n\n',
      '## Output\n\n[[Smart Pointer Result]]\n\n',
    );
    await note.writeAsString(text);

    await repository.reconcileSessions(now: now);
    var session = (await repository.load()).sessions.single;
    expect(session.status, SessionStatus.planned);
    expect(session.reconciliationError, contains('unresolved'));

    await File(
      '${vault.path}/10 Knowledge/Smart Pointer Result.md',
    ).writeAsString('# Concrete result');
    await repository.reconcileSessions(now: now);
    session = (await repository.load()).sessions.single;
    expect(session.status, SessionStatus.done);
  });

  test('completion before planned end is not confirmed', () async {
    final note = await sessionNote();
    var text = await note.readAsString();
    text = text.replaceFirst('status: planned', 'status: done');
    text = text.replaceFirst('## Output\n\n', '## Output\n\nResult\n\n');
    await note.writeAsString(text);
    await repository.reconcileSessions(now: DateTime(2026, 9, 14, 21, 30));
    expect(
      (await repository.load()).sessions.single.status,
      SessionStatus.planned,
    );
  });

  test('reschedule and skip patch the note and projection together', () async {
    final moved = DateTime(2026, 9, 15, 20);
    await repository.reschedule('session-1', moved, 45);
    var text = await (await sessionNote()).readAsString();
    expect(text, contains('planned_start: "${moved.toIso8601String()}"'));
    expect(text, contains('planned_minutes: 45'));
    var session = (await repository.load()).sessions.single;
    expect(session.plannedStart, moved);
    expect(session.plannedMinutes, 45);

    await repository.setSessionDisposition('session-1', 'skipped');
    text = await (await sessionNote()).readAsString();
    expect(text, contains('status: skipped'));
    session = (await repository.load()).sessions.single;
    expect(session.status, SessionStatus.skipped);
  });

  test('renaming a note keeps the stable session ID association', () async {
    final original = await sessionNote();
    final renamed = File('${vault.path}/11 Sessions/renamed-session.md');
    await original.rename(renamed.path);

    await repository.reconcileSessions(now: now);
    final session = (await repository.load()).sessions.single;
    expect(session.notePath, contains('renamed-session.md'));
    expect(
      p.normalize(await repository.sessionNotePath('session-1')),
      p.normalize(renamed.path),
    );
  });

  test('duplicate IDs are quarantined and cannot keep a completion', () async {
    final note = await sessionNote();
    var text = await note.readAsString();
    text = text.replaceFirst('status: planned', 'status: done');
    text = text.replaceFirst('## Output\n\n', '## Output\n\nResult\n\n');
    await note.writeAsString(text);
    await repository.reconcileSessions(now: now);
    expect(
      (await repository.load()).sessions.single.status,
      SessionStatus.done,
    );

    await File('${vault.path}/11 Sessions/duplicate.md').writeAsString(text);
    final result = await repository.reconcileSessions(now: now);
    final workspace = await repository.load();
    expect(result.errors, greaterThan(0));
    expect(workspace.sessions.single.status, SessionStatus.planned);
    expect(
      workspace.sessions.single.reconciliationError,
      contains('Duplicate'),
    );
    expect(workspace.outputs, isEmpty);
  });

  test(
    'malformed YAML is reported without treating the note as deleted',
    () async {
      final note = await sessionNote();
      final text = (await note.readAsString()).replaceFirst(
        'planned_minutes: 60',
        'planned_minutes 60',
      );
      await note.writeAsString(text);

      final result = await repository.reconcileSessions(now: now);
      final session = (await repository.load()).sessions.single;
      expect(result.errors, greaterThan(0));
      expect(session.status, SessionStatus.planned);
      expect(session.reconciliationError, contains('invalid YAML'));
    },
  );

  test(
    'template and recurring schedule can be rebuilt from Markdown',
    () async {
      await repository.save('session_templates', {
        'id': 'template-cpp',
        'title': 'C++ practice',
        'planned_minutes': 60,
        'priority': 1,
        'created_at': now.millisecondsSinceEpoch,
      });
      await repository.syncMarkdownRecord('session_templates', 'template-cpp');
      await repository.save('recurring_schedules', {
        'id': 'schedule-cpp',
        'template_id': 'template-cpp',
        'title': 'Monday C++',
        'weekdays': '1',
        'local_time': '21:00',
        'created_at': now.millisecondsSinceEpoch,
      });
      await repository.syncMarkdownRecord(
        'recurring_schedules',
        'schedule-cpp',
      );

      final rebuilt = await SqliteWorkspaceRepository.open(
        '${temp.path}/rebuilt.sqlite',
        demo: false,
      );
      try {
        await rebuilt.configureMarkdownWorkspace(vault.path);
        await rebuilt.reconcileSessions(now: now);
        final workspace = await rebuilt.load();
        expect(
          workspace.records('session_templates').map((item) => item.id),
          contains('template-cpp'),
        );
        expect(
          workspace.records('recurring_schedules').map((item) => item.id),
          contains('schedule-cpp'),
        );
        expect(
          workspace.sessions.map((item) => item.id),
          contains('session-1'),
        );
        expect(
          workspace.knowledge
              .map((item) => item.text('type').toLowerCase())
              .where((type) => type.contains('session')),
          isEmpty,
        );
      } finally {
        await rebuilt.close();
      }
    },
  );

  test(
    'streak excludes cancelled, breaks on skipped, and pauses at pending',
    () {
      Session session(String id, String status, int day) => Session({
        'id': id,
        'title': id,
        'status': status,
        'recurring_schedule_id': 'schedule',
        'planned_start': DateTime(2026, 9, day, 21).millisecondsSinceEpoch,
        'planned_minutes': 60,
        'created_at': 0,
      });
      final workspace = Workspace(
        sessions: [
          session('done-1', 'DONE', 7),
          session('cancelled', 'CANCELLED', 8),
          session('done-2', 'DONE', 9),
          session('skipped', 'SKIPPED', 10),
          session('done-3', 'DONE', 11),
          session('pending', 'PLANNED', 12),
          session('later-done', 'DONE', 13),
        ],
      );
      final streak = workspace.sessionStreak('schedule', now);
      expect(streak.confirmed, 1);
      expect(streak.pending, 1);
    },
  );
}
