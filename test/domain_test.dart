import 'package:flutter_test/flutter_test.dart' hide within;
import 'package:personal_os/domain/models.dart';
import 'package:personal_os/domain/insights.dart';

void main() {
  final now = DateTime(2026, 9, 11, 12);
  final stamp = now.millisecondsSinceEpoch;
  Goal goal(String id, {int days = 40, String status = 'active'}) => Goal({
    'id': id,
    'title': id,
    'life_area_id': 'career',
    'status': status,
    'created_at': now.subtract(Duration(days: days)).millisecondsSinceEpoch,
  });
  Project project(String id, {String status = 'active'}) => Project({
    'id': id,
    'title': id,
    'goal_id': 'g',
    'status': status,
    'created_at': now.subtract(const Duration(days: 35)).millisecondsSinceEpoch,
  });
  Session session(
    String id, {
    String status = 'DONE',
    int days = 1,
    String? projectId = 'p',
  }) => Session({
    'id': id,
    'title': id,
    'project_id': projectId,
    'status': status,
    'planned_start': now.subtract(Duration(days: days)).millisecondsSinceEpoch,
    'actual_start': now.subtract(Duration(days: days)).millisecondsSinceEpoch,
    'actual_end': now.subtract(Duration(days: days)).millisecondsSinceEpoch,
    'created_at': stamp,
    'planned_minutes': 60,
  });

  test(
    'Session transition matrix protects terminal states and repeated transitions',
    () {
      for (final source in SessionStatus.values) {
        expect(source.canTransitionTo(source), isFalse);
        expect(source.canTransitionTo(SessionStatus.planned), isFalse);
        if (source.terminal) {
          for (final destination in SessionStatus.values) {
            expect(source.canTransitionTo(destination), isFalse);
          }
        }
      }
      expect(
        SessionStatus.planned.canTransitionTo(SessionStatus.active),
        isTrue,
      );
      expect(
        SessionStatus.active.canTransitionTo(SessionStatus.inProgress),
        isTrue,
      );
      expect(
        SessionStatus.inProgress.canTransitionTo(SessionStatus.active),
        isTrue,
      );
      expect(
        SessionStatus.active.canTransitionTo(SessionStatus.blocked),
        isTrue,
      );
      expect(
        SessionStatus.blocked.canTransitionTo(SessionStatus.active),
        isTrue,
      );
      expect(SessionStatus.active.canTransitionTo(SessionStatus.done), isTrue);
    },
  );
  test('Weeks start Monday and use half-open boundaries', () {
    expect(weekStart(now), DateTime(2026, 9, 7));
    expect(weekStart(DateTime(2026, 9, 13, 23, 59)), DateTime(2026, 9, 7));
    expect(
      within(DateTime(2026, 9, 14), weekStart(now), weekEnd(weekStart(now))),
      isFalse,
    );
  });
  test(
    'Weekly metrics use planned sessions and ignore legacy timer intervals',
    () {
      final sunday = DateTime(2026, 9, 6, 23, 30),
          monday = DateTime(2026, 9, 7, 0, 30);
      final w = Workspace(
        goals: [goal('g')],
        projects: [project('p')],
        sessions: [
          session('s'),
          session('cancel', status: 'CANCELLED'),
        ],
        intervals: [
          FocusInterval({
            'id': 'i',
            'session_id': 's',
            'start_at': sunday.millisecondsSinceEpoch,
            'end_at': monday.millisecondsSinceEpoch,
            'seconds': 3600,
          }),
        ],
        outputs: [
          Output({'id': 'o', 'project_id': 'p', 'created_at': stamp}),
        ],
      );
      final result = WeeklyMetrics.calculate(w, now);
      expect(result.planned, 1);
      expect(result.completed, 1);
      expect(result.scheduledMinutes, 60);
      expect(result.pending, 0);
      expect(result.outputCount, 1);
      expect(result.goalIds, {'g'});
      expect(WeeklyMetrics.calculate(w, sunday).scheduledMinutes, 0);
    },
  );
  test('Legacy timer intervals do not create scheduled-work progress', () {
    final end = DateTime(2026, 9, 7);
    final w = Workspace(
      intervals: [
        FocusInterval({
          'id': 'i',
          'session_id': 's',
          'start_at': end.millisecondsSinceEpoch,
          'end_at': end.millisecondsSinceEpoch,
          'seconds': 900,
        }),
      ],
    );
    expect(WeeklyMetrics.calculate(w, end).scheduledMinutes, 0);
    expect(WeeklyMetrics.calculate(w, end).completion, isNull);
  });
  test('Activity score has documented weights and is bounded', () {
    final area = LifeArea({'id': 'career'});
    final w = Workspace(
      areas: [area],
      goals: [goal('g')],
      projects: [project('p')],
      sessions: [session('s')],
      milestones: [
        Milestone({'id': 'm', 'project_id': 'p', 'completed_at': stamp}),
      ],
    );
    expect(activityScore(w, area, now), 25);
    expect(activityScore(Workspace(goals: [goal('g')]), area, now), 0);
    final busy = Workspace(
      goals: List.generate(10, (i) => goal('g$i')),
      projects: [
        Project({'id': 'p', 'goal_id': 'g0'}),
      ],
      sessions: List.generate(100, (i) => session('$i')),
      milestones: List.generate(
        30,
        (i) =>
            Milestone({'id': '$i', 'project_id': 'p', 'completed_at': stamp}),
      ),
    );
    expect(activityScore(busy, area, now), 100);
  });
  test('Inactivity checks thresholds, status and real output evidence', () {
    final w = Workspace(
      goals: [
        goal('g'),
        goal('new', days: 3),
        goal('paused', status: 'paused'),
      ],
      projects: [
        project('p'),
        project('paused', status: 'paused'),
      ],
    );
    expect(inactiveProjects(w, now).map((p) => p.id), ['p']);
    expect(inactiveGoals(w, now).map((g) => g.id), ['g']);
    final attended = Workspace(
      goals: w.goals,
      projects: w.projects,
      outputs: [
        Output({'id': 'o', 'project_id': 'p', 'created_at': stamp}),
      ],
    );
    expect(inactiveProjects(attended, now), isEmpty);
    expect(inactiveGoals(attended, now), isEmpty);
  });
  test(
    'Insight rules identify activity without output and missing milestones',
    () {
      final w = Workspace(
        goals: [goal('g')],
        projects: [project('p')],
        sessions: [session('1'), session('2'), session('3')],
      );
      final messages = RuleBasedInsightProvider().generate(w, now);
      expect(messages.any((i) => i.id == 'no-output-p'), isTrue);
      expect(messages.any((i) => i.id == 'milestone-p'), isTrue);
      expect(messages.any((i) => i.id == 'completion'), isTrue);
      final withOutput = Workspace(
        goals: w.goals,
        projects: w.projects,
        sessions: w.sessions,
        outputs: [
          Output({'id': 'o', 'project_id': 'p', 'created_at': stamp}),
        ],
      );
      expect(
        RuleBasedInsightProvider()
            .generate(withOutput, now)
            .any((i) => i.id == 'no-output-p'),
        isFalse,
      );
    },
  );
  test('Progress uses milestones, with null for unmeasured projects', () {
    final w = Workspace(
      projects: [project('p')],
      milestones: [
        Milestone({'id': '1', 'project_id': 'p', 'completed_at': stamp}),
        Milestone({'id': '2', 'project_id': 'p'}),
      ],
    );
    expect(w.projectProgress('p'), .5);
    expect(w.goalProgress('g'), .5);
    expect(w.projectProgress('none'), isNull);
  });
  test('A confirmed session does not change task execution or readiness', () {
    final w = Workspace(
      projects: [project('p')],
      sessions: [session('confirmed')],
      tasks: [
        WorkTask({
          'id': 'task',
          'project_id': 'p',
          'title': 'Implement example',
          'status': 'Planned',
          'done': 0,
          'created_at': stamp,
        }),
      ],
    );
    expect(w.projectExecutionProgress('p'), 0);
    expect(w.readiness('skill'), 0);
  });
  test(
    'Today includes overdue and active sessions without changing schedule order',
    () {
      final w = Workspace(
        sessions: [
          session('tomorrow', status: 'PLANNED', days: -1),
          session('today', status: 'PLANNED', days: 0),
          session('overdue', status: 'IN_PROGRESS', days: 1),
          session('done-old', days: 2),
          session('active-old', status: 'ACTIVE', days: 3),
        ],
      );
      expect(w.today(now).map((s) => s.id), ['active-old', 'overdue', 'today']);
    },
  );
}
