import 'package:flutter_test/flutter_test.dart';
import 'package:personal_os/domain/models.dart';
import 'package:personal_os/presentation/dashboard_data.dart';

void main() {
  final now = DateTime(2026, 9, 13, 10);
  final mission = StrategyRecord({
    'id': 'mission-active',
    'title': 'Active mission',
    'goal_id': 'goal-active',
    'status': 'Active',
    'created_at': 1,
  });
  final otherMission = StrategyRecord({
    'id': 'mission-other',
    'title': 'Other mission',
    'goal_id': 'goal-other',
    'status': 'Paused',
    'created_at': 1,
  });
  final missionProject = Project({
    'id': 'project-mission',
    'title': 'Mission project',
    'goal_id': 'goal-active',
    'status': 'active',
    'priority': 2,
    'next_action': 'Ship mission work',
    'target_at': now.add(const Duration(days: 5)).millisecondsSinceEpoch,
    'project_type': 'Career',
    'created_at': 1,
  });
  final unrelatedProject = Project({
    'id': 'project-unrelated',
    'title': 'Unrelated project',
    'goal_id': 'goal-other',
    'status': 'active',
    'priority': 1,
    'next_action': 'Do unrelated work',
    'target_at': now.add(const Duration(days: 5)).millisecondsSinceEpoch,
    'project_type': 'Personal',
    'created_at': 1,
  });
  final missionOutput = Output({
    'id': 'output-mission',
    'title': 'Verified mission artifact',
    'project_id': 'project-mission',
    'session_id': 'session-mission',
    'created_at': now.millisecondsSinceEpoch,
  });
  final unrelatedOutput = Output({
    'id': 'output-other',
    'title': 'Unrelated artifact',
    'project_id': 'project-unrelated',
    'created_at': now.millisecondsSinceEpoch,
  });
  final workspace = Workspace(
    strategyData: {
      'missions': [mission, otherMission],
      'skills': [
        StrategyRecord({
          'id': 'skill-active',
          'title': 'Mission skill',
          'mission_id': 'mission-active',
          'created_at': 1,
        }),
        StrategyRecord({
          'id': 'skill-other',
          'title': 'Other skill',
          'mission_id': 'mission-other',
          'created_at': 1,
        }),
      ],
      'evidence': [
        StrategyRecord({
          'id': 'evidence-active',
          'title': 'Verified',
          'skill_id': 'skill-active',
          'output_id': 'output-mission',
          'verified': 1,
          'score': 80,
          'dimension': 'Implementation',
          'created_at': now.millisecondsSinceEpoch,
        }),
        StrategyRecord({
          'id': 'evidence-unverified',
          'title': 'Unverified',
          'skill_id': 'skill-active',
          'output_id': 'output-mission',
          'verified': 0,
          'score': 100,
          'dimension': 'Knowledge',
          'created_at': now.millisecondsSinceEpoch,
        }),
        StrategyRecord({
          'id': 'evidence-other',
          'title': 'Other mission evidence',
          'skill_id': 'skill-other',
          'output_id': 'output-other',
          'verified': 1,
          'score': 100,
          'dimension': 'Knowledge',
          'created_at': now.millisecondsSinceEpoch,
        }),
      ],
      'outcomes': [
        StrategyRecord({
          'id': 'outcome-active',
          'title': 'Outcome',
          'mission_id': 'mission-active',
          'target': 10,
          'current_value': 5,
          'weight': 1,
          'created_at': 1,
        }),
      ],
      'jobs': [
        StrategyRecord({
          'id': 'job-active',
          'title': 'Mission role',
          'mission_id': 'mission-active',
          'created_at': now.millisecondsSinceEpoch,
        }),
        StrategyRecord({
          'id': 'job-other',
          'title': 'Other role',
          'mission_id': 'mission-other',
          'created_at': now.millisecondsSinceEpoch,
        }),
      ],
      'applications': [
        StrategyRecord({
          'id': 'application-active',
          'title': 'Mission application',
          'job_id': 'job-active',
          'status': 'Offer',
          'created_at': now.millisecondsSinceEpoch,
        }),
        StrategyRecord({
          'id': 'application-other',
          'title': 'Other application',
          'job_id': 'job-other',
          'created_at': now.millisecondsSinceEpoch,
        }),
      ],
      'interviews': [
        StrategyRecord({
          'id': 'interview-active',
          'title': 'Mission interview',
          'application_id': 'application-active',
          'created_at': now.millisecondsSinceEpoch,
        }),
      ],
    },
    projects: [missionProject, unrelatedProject],
    sessions: [
      Session({
        'id': 'session-mission',
        'title': 'Mission session',
        'project_id': 'project-mission',
        'status': 'DONE',
        'planned_start': now.millisecondsSinceEpoch,
        'planned_minutes': 60,
        'actual_seconds': 1800,
        'blocked': 0,
        'created_at': 1,
      }),
      Session({
        'id': 'session-other',
        'title': 'Other session',
        'project_id': 'project-unrelated',
        'status': 'DONE',
        'planned_start': now.millisecondsSinceEpoch,
        'planned_minutes': 60,
        'actual_seconds': 1800,
        'blocked': 0,
        'created_at': 1,
      }),
    ],
    outputs: [missionOutput, unrelatedOutput],
  );

  test(
    'dashboard priority scoring favors mission relevance and explains rank',
    () {
      final priorities = dashboardPriorities(workspace, mission, now);
      expect(priorities.first.project.id, 'project-mission');
      expect(priorities.first.explanation, contains('Mission-linked'));
      expect(priorities.first.explanation, contains('gap'));
      expect(priorities.first.explanation, contains('due in'));
    },
  );

  test('recent wins require verified evidence for the active mission', () {
    final wins = dashboardWins(workspace, mission);
    expect(wins, hasLength(1));
    expect(wins.single.output.id, 'output-mission');
    expect(wins.single.skill, 'Mission skill');
  });

  test('weekly summary excludes work belonging to other missions', () {
    final summary = MissionWeeklySummary.calculate(workspace, mission, now);
    expect(summary.planned, 1);
    expect(summary.completed, 1);
    expect(summary.outputCount, 1);
    expect(summary.applicationCount, 1);
    expect(summary.interviewCount, 1);
  });

  test('career pipeline is scoped to the selected mission', () {
    final pipeline = MissionCareerPipeline.calculate(workspace, mission.id);
    expect(pipeline.jobs, 1);
    expect(pipeline.applications, 1);
    expect(pipeline.interviews, 1);
    expect(pipeline.offers, 1);
  });

  test('engine summary never invents capital progress', () {
    final summaries = engineSummaries(workspace, mission);
    expect(
      summaries.singleWhere((item) => item.engine == 'Career').progress,
      .5,
    );
    expect(
      summaries.singleWhere((item) => item.engine == 'Capital').progress,
      isNull,
    );
  });
}
