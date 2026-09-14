import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:personal_os/infrastructure/sqlite_repository.dart';

void main() {
  late Directory temp;
  late Directory vault;
  late SqliteWorkspaceRepository repository;
  final stamp = DateTime(2026, 9, 14, 9).millisecondsSinceEpoch;

  Future<void> seedUpstream(SqliteWorkspaceRepository repo) async {
    await repo.save('visions', {
      'id': 'vision',
      'title': 'Vision',
      'created_at': stamp,
    });
    await repo.save('strategies', {
      'id': 'strategy',
      'vision_id': 'vision',
      'title': 'Strategy',
      'created_at': stamp,
    });
    await repo.save('goals', {
      'id': 'goal',
      'title': 'Goal',
      'status': 'active',
      'created_at': stamp,
    });
  }

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('personal_os_domain_');
    vault = await Directory('${temp.path}/vault').create();
    repository = await SqliteWorkspaceRepository.open(
      '${temp.path}/projection.sqlite',
      demo: false,
    );
    await seedUpstream(repository);
    await repository.save('missions', {
      'id': 'mission',
      'strategy_id': 'strategy',
      'goal_id': 'goal',
      'title': 'Modern C++ Mission',
      'description': 'Build strong systems skills.',
      'success_criteria': 'Ship a reliable project.',
      'status': 'Active',
      'priority': 1,
      'confidence': 50,
      'created_at': stamp,
    });
    await repository.save('projects', {
      'id': 'project',
      'title': 'Smart Pointer Project',
      'description': 'Practice ownership.',
      'goal_id': 'goal',
      'project_type': 'Learning',
      'priority': 1,
      'status': 'active',
      'next_action': 'Ship first slice.',
      'created_at': stamp,
    });
    await repository.save('tasks', {
      'id': 'task',
      'project_id': 'project',
      'title': 'Implement unique_ptr example',
      'description': 'Write and explain the example.',
      'status': 'Backlog',
      'priority': 1,
      'done': 0,
      'created_at': stamp,
    });
    await repository.configureMarkdownWorkspace(vault.path);
  });

  tearDown(() async {
    await repository.close();
    await temp.delete(recursive: true);
  });

  Future<File> source(String type, String id) async {
    final rows = await repository.db.query(
      'workspace_entity_sources',
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: [type, id],
    );
    return File(p.join(vault.path, rows.single['path'] as String));
  }

  test(
    'initialization creates templates and one source note per domain',
    () async {
      for (final type in ['mission', 'project', 'task']) {
        expect(
          await File('${vault.path}/_templates/$type.md').exists(),
          isTrue,
        );
        expect(await (await source(type, type)).exists(), isTrue);
      }
      expect(
        await repository.db.query('workspace_entity_sources'),
        hasLength(3),
      );
    },
  );

  test('Obsidian edits update Mission, Project and Task projections', () async {
    final mission = await source('mission', 'mission');
    await mission.writeAsString(
      (await mission.readAsString()).replaceFirst(
        'confidence: 50',
        'confidence: 75',
      ),
    );
    final project = await source('project', 'project');
    await project.writeAsString(
      (await project.readAsString()).replaceFirst(
        '## Next Action\n\nShip first slice.',
        '## Next Action\n\nPublish the ownership demo.',
      ),
    );
    final task = await source('task', 'task');
    await task.writeAsString(
      (await task.readAsString()).replaceFirst(
        'status: Backlog',
        'status: Done',
      ),
    );

    final result = await repository.reconcileSessions(
      now: DateTime(2026, 9, 14, 22),
    );
    final workspace = await repository.load();
    expect(result.errors, 0);
    expect(workspace.record('missions', 'mission')!.number('confidence'), 75);
    expect(workspace.projects.single.nextAction, 'Publish the ownership demo.');
    expect(workspace.tasks.single.done, isTrue);
  });

  test(
    'app writes patch existing Markdown without replacing user sections',
    () async {
      final task = await source('task', 'task');
      await task.writeAsString(
        '${await task.readAsString()}\n## User Notes\n\nKeep this.\n',
      );
      await repository.save('tasks', {
        'id': 'task',
        'status': 'Planned',
        'priority': 2,
      });
      await repository.syncMarkdownRecord('tasks', 'task');

      final text = await task.readAsString();
      expect(text, contains('status: Planned'));
      expect(text, contains('priority: 2'));
      expect(text, contains('## User Notes\n\nKeep this.'));
    },
  );

  test(
    'a new task written in Obsidian is imported with its relationship',
    () async {
      await File('${vault.path}/04 Tasks/new-task.md').writeAsString('''---
id: task-new
type: task
title: Review ownership notes
project: project
status: Done
priority: 2
scheduled_at: 2026-09-15T20:00:00
estimated_minutes: 30
actual_minutes:
created: 2026-09-14T10:00:00
updated: 2026-09-14T10:00:00
---

# Review ownership notes

## Description

Summarize the tradeoffs.
''');

      await repository.reconcileSessions(now: DateTime(2026, 9, 15, 21));
      final task = (await repository.load()).tasks.firstWhere(
        (item) => item.id == 'task-new',
      );
      expect(task.ref('project_id'), 'project');
      expect(task.done, isTrue);
      expect(task.number('estimated_minutes'), 30);
    },
  );

  test(
    'renames update source identity and deletion retains data with an error',
    () async {
      final task = await source('task', 'task');
      final renamed = File('${vault.path}/04 Tasks/renamed-task.md');
      await task.rename(renamed.path);
      await repository.reconcileSessions();
      var sourceRow = (await repository.db.query(
        'workspace_entity_sources',
        where: "entity_type = 'task' AND entity_id = 'task'",
      )).single;
      expect(sourceRow['path'], contains('renamed-task.md'));

      await renamed.delete();
      await repository.reconcileSessions();
      sourceRow = (await repository.db.query(
        'workspace_entity_sources',
        where: "entity_type = 'task' AND entity_id = 'task'",
      )).single;
      expect(sourceRow['error'], contains('missing'));
      expect((await repository.load()).tasks.single.id, 'task');
    },
  );

  test(
    'Mission, Project and Task rebuild from Markdown with upstream IDs',
    () async {
      final rebuilt = await SqliteWorkspaceRepository.open(
        '${temp.path}/rebuilt.sqlite',
        demo: false,
      );
      try {
        await seedUpstream(rebuilt);
        await rebuilt.configureMarkdownWorkspace(vault.path);
        await rebuilt.reconcileSessions();
        final workspace = await rebuilt.load();
        expect(
          workspace.records('missions').map((item) => item.id),
          contains('mission'),
        );
        expect(workspace.projects.map((item) => item.id), contains('project'));
        expect(workspace.tasks.map((item) => item.id), contains('task'));
      } finally {
        await rebuilt.close();
      }
    },
  );
}
