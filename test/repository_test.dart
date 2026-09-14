import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_os/infrastructure/sqlite_repository.dart';
import 'package:personal_os/domain/models.dart';
import 'package:personal_os/domain/insights.dart';

void main() {
  late SqliteWorkspaceRepository repo;
  late Directory temp;
  final now = DateTime(2026, 9, 11, 12);
  Future<void> addSession(String id) => repo.save('sessions', {
    'id': id,
    'title': 'Work $id',
    'project_id': 'p',
    'planned_start': now.millisecondsSinceEpoch,
    'planned_minutes': 60,
    'created_at': now.millisecondsSinceEpoch,
  });
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('personal_os_test_');
    repo = await SqliteWorkspaceRepository.open(
      '${temp.path}/test.sqlite',
      demo: false,
    );
    await repo.save('goals', {
      'id': 'g',
      'title': 'Meaningful goal',
      'created_at': now.millisecondsSinceEpoch,
    });
    await repo.save('projects', {
      'id': 'p',
      'title': 'Project',
      'goal_id': 'g',
      'created_at': now.millisecondsSinceEpoch,
    });
  });
  tearDown(() async {
    await repo.close();
    await temp.delete(recursive: true);
  });
  test(
    'Create, update, close and reopen preserve links and settings',
    () async {
      await repo.save('projects', {'id': 'p', 'title': 'Updated project'});
      await repo.save('settings', {'key': 'theme', 'value': 'dark'});
      await repo.close();
      repo = await SqliteWorkspaceRepository.open('${temp.path}/test.sqlite');
      final w = await repo.load();
      expect(w.projects.single.title, 'Updated project');
      expect(w.projects.single.goalId, 'g');
      expect(w.settings['theme'], 'dark');
      expect(w.sessions, isEmpty);
    },
  );
  test(
    'Session review writes evidence and learning once, atomically',
    () async {
      await addSession('s');
      await repo.startSession('s', now);
      await repo.reviewSession(
        's',
        SessionStatus.done,
        now.add(const Duration(minutes: 25)),
        output: 'Working prototype',
        learning: 'Ownership matters',
        nextAction: 'Test edge cases',
      );
      final w = await repo.load();
      expect(w.sessions.single.status, SessionStatus.done);
      expect(w.sessions.single.actualSeconds, 1500);
      expect(w.outputs.single.sessionId, 's');
      expect(w.knowledge.single.ref('session_id'), 's');
      expect(w.projects.single.nextAction, 'Test edge cases');
      expect(WeeklyMetrics.calculate(w, now).scheduledMinutes, 60);
      await expectLater(
        repo.reviewSession('s', SessionStatus.done, now, output: 'Duplicate'),
        throwsStateError,
      );
      expect((await repo.load()).outputs.length, 1);
    },
  );
  test(
    'Pause and resume accumulate only active intervals and enforce one active',
    () async {
      await addSession('a');
      await addSession('b');
      await repo.startSession('a', now);
      await expectLater(repo.startSession('b', now), throwsStateError);
      await repo.reviewSession(
        'a',
        SessionStatus.inProgress,
        now.add(const Duration(minutes: 10)),
        nextAction: 'Continue',
      );
      await repo.startSession('a', now.add(const Duration(minutes: 30)));
      await repo.reviewSession(
        'a',
        SessionStatus.done,
        now.add(const Duration(minutes: 35)),
      );
      final w = await repo.load();
      expect(w.sessions.firstWhere((s) => s.id == 'a').actualSeconds, 900);
      expect(w.intervals.length, 2);
    },
  );
  test('Blocked sessions retain a reason and can resume', () async {
    await addSession('blocked');
    await repo.startSession('blocked', now);
    await repo.reviewSession(
      'blocked',
      SessionStatus.blocked,
      now.add(const Duration(minutes: 5)),
      nextAction: 'Waiting for a customer sample',
    );
    var session = (await repo.load()).sessions.single;
    expect(session.status, SessionStatus.blocked);
    expect(session.blockedReason, 'Waiting for a customer sample');
    await repo.reschedule('blocked', now.add(const Duration(days: 1)), 30);
    await repo.startSession('blocked', now.add(const Duration(days: 1)));
    session = (await repo.load()).sessions.single;
    expect(session.status, SessionStatus.active);
    expect(session.blockedReason, isEmpty);
  });
  test('Invalid review rolls back status and evidence', () async {
    await addSession('s');
    await repo.startSession('s', now);
    await expectLater(
      repo.reviewSession(
        's',
        SessionStatus.done,
        now,
        output: 'Should not persist',
        correctedSeconds: -1,
      ),
      throwsArgumentError,
    );
    final w = await repo.load();
    expect(w.sessions.single.status, SessionStatus.active);
    expect(w.outputs, isEmpty);
  });
  test('Triage is atomic and double conversion is rejected', () async {
    await repo.save('inbox', {
      'id': 'i',
      'title': 'A captured idea',
      'created_at': now.millisecondsSinceEpoch,
    });
    await expectLater(
      repo.triage('i', 'projects', {
        'id': 'bad',
        'title': 'Bad',
        'goal_id': 'missing',
        'created_at': 0,
      }),
      throwsA(anything),
    );
    expect((await repo.load()).inbox.single.processed, isFalse);
    await repo.triage('i', 'projects', {
      'id': 'new',
      'title': 'New project',
      'goal_id': 'g',
      'created_at': 0,
    });
    expect((await repo.load()).inbox.single.processed, isTrue);
    await expectLater(
      repo.triage('i', 'projects', {
        'id': 'again',
        'title': 'Duplicate',
        'created_at': 0,
      }),
      throwsStateError,
    );
  });
  test(
    'Rescheduling updates planned allocation and rejects terminal rows',
    () async {
      await addSession('s');
      await repo.reschedule('s', now.add(const Duration(days: 1)), 30);
      expect((await repo.load()).sessions.single.plannedMinutes, 30);
      await repo.db.update(
        'sessions',
        {'status': 'DONE'},
        where: 'id = ?',
        whereArgs: ['s'],
      );
      await expectLater(repo.reschedule('s', now, 60), throwsStateError);
    },
  );
  test(
    'Seed is only created once; clear demo never reseeds on reopen',
    () async {
      await repo.close();
      repo = await SqliteWorkspaceRepository.open('${temp.path}/demo.sqlite');
      final w = await repo.load();
      expect(w.goals.length, 4);
      expect(w.sessions.length, 12);
      await repo.close();
      repo = await SqliteWorkspaceRepository.open('${temp.path}/demo.sqlite');
      expect((await repo.load()).sessions.length, 12);
      await repo.clearDemo();
      await repo.close();
      repo = await SqliteWorkspaceRepository.open('${temp.path}/demo.sqlite');
      expect((await repo.load()).sessions, isEmpty);
      expect((await repo.load()).settings['demo'], 'false');
      expect((await repo.load()).areas.length, 4);
      await expectLater(repo.clearDemo(), throwsStateError);
    },
  );
  test(
    'Evidence cannot be moved away from its source session project',
    () async {
      await addSession('s');
      await repo.reviewSession(
        's',
        SessionStatus.done,
        now,
        output: 'Verified result',
      );
      final output = (await repo.load()).outputs.single;
      await expectLater(
        repo.save('outputs', {'id': output.id, 'project_id': null}),
        throwsStateError,
      );
      expect((await repo.load()).outputs.single.projectId, 'p');
    },
  );
  test(
    'A late transaction error rolls back session state and output together',
    () async {
      await addSession('s');
      await repo.startSession('s', now);
      await repo.db.execute(
        "CREATE TRIGGER fail_learning BEFORE INSERT ON knowledge BEGIN SELECT RAISE(ABORT, 'simulated storage error'); END",
      );
      await expectLater(
        repo.reviewSession(
          's',
          SessionStatus.done,
          now.add(const Duration(minutes: 5)),
          output: 'Do not partially persist',
          learning: 'Fails after output insert',
        ),
        throwsA(anything),
      );
      final w = await repo.load();
      expect(w.sessions.single.status, SessionStatus.active);
      expect(w.outputs, isEmpty);
      expect(w.intervals, isEmpty);
    },
  );
}
