import 'dart:math';

import '../domain/insights.dart';
import '../domain/models.dart';

bool projectSupportsMission(
  Workspace workspace,
  Project project,
  StrategyRecord mission,
) {
  if (project.goalId != null && project.goalId == mission.ref('goal_id')) {
    return true;
  }
  final outcome = workspace.record('outcomes', project.outcomeId);
  if (outcome?.ref('mission_id') == mission.id) return true;
  final initiative = workspace.record('initiatives', project.initiativeId);
  return initiative?.ref('mission_id') == mission.id ||
      workspace
              .record('outcomes', initiative?.ref('outcome_id'))
              ?.ref('mission_id') ==
          mission.id;
}

bool sessionSupportsMission(
  Workspace workspace,
  Session session,
  StrategyRecord mission,
) {
  final project = workspace.project(session.projectId);
  return (project != null &&
          projectSupportsMission(workspace, project, mission)) ||
      (session.goalId != null && session.goalId == mission.ref('goal_id'));
}

class MissionWeeklySummary {
  final int planned;
  final int completed;
  final int focusedSeconds;
  final int outputCount;
  final int applicationCount;
  final int interviewCount;

  const MissionWeeklySummary({
    required this.planned,
    required this.completed,
    required this.focusedSeconds,
    required this.outputCount,
    required this.applicationCount,
    required this.interviewCount,
  });

  double? get completion => planned == 0 ? null : completed / planned;

  factory MissionWeeklySummary.calculate(
    Workspace workspace,
    StrategyRecord mission,
    DateTime day,
  ) {
    final start = weekStart(day);
    final end = weekEnd(start);
    final sessions = workspace.sessions
        .where(
          (session) =>
              session.status != SessionStatus.cancelled &&
              within(session.plannedStart, start, end) &&
              sessionSupportsMission(workspace, session, mission),
        )
        .toList();
    final sessionIds = sessions.map((session) => session.id).toSet();
    final missionProjectIds = workspace.projects
        .where((project) => projectSupportsMission(workspace, project, mission))
        .map((project) => project.id)
        .toSet();
    final outputIds = workspace.outputs
        .where(
          (output) =>
              within(output.createdAt, start, end) &&
              (sessionIds.contains(output.sessionId) ||
                  missionProjectIds.contains(output.projectId)),
        )
        .map((output) => output.id)
        .toSet();
    var focusedSeconds = 0;
    for (final interval in workspace.intervals.where(
      (interval) => sessionIds.contains(interval.sessionId),
    )) {
      final total = interval.end.difference(interval.start).inSeconds;
      final overlap =
          max(
            0,
            min(
                  interval.end.millisecondsSinceEpoch,
                  end.millisecondsSinceEpoch,
                ) -
                max(
                  interval.start.millisecondsSinceEpoch,
                  start.millisecondsSinceEpoch,
                ),
          ) ~/
          1000;
      focusedSeconds += total == interval.seconds && total > 0
          ? overlap
          : (within(interval.end, start, end) ? interval.seconds : 0);
    }
    final jobIds = workspace
        .records('jobs')
        .where((job) => job.ref('mission_id') == mission.id)
        .map((job) => job.id)
        .toSet();
    final applications = workspace
        .records('applications')
        .where(
          (application) =>
              jobIds.contains(application.ref('job_id')) &&
              within(application.createdAt, start, end),
        )
        .toList();
    final applicationIds = applications.map((item) => item.id).toSet();
    final interviews = workspace
        .records('interviews')
        .where(
          (interview) =>
              applicationIds.contains(interview.ref('application_id')) &&
              within(interview.createdAt, start, end),
        )
        .length;
    return MissionWeeklySummary(
      planned: sessions.length,
      completed: sessions
          .where((session) => session.status == SessionStatus.done)
          .length,
      focusedSeconds: focusedSeconds,
      outputCount: outputIds.length,
      applicationCount: applications.length,
      interviewCount: interviews,
    );
  }
}

class MissionCareerPipeline {
  final int jobs;
  final int applications;
  final int interviews;
  final int offers;

  const MissionCareerPipeline({
    required this.jobs,
    required this.applications,
    required this.interviews,
    required this.offers,
  });

  factory MissionCareerPipeline.calculate(
    Workspace workspace,
    String missionId,
  ) {
    final jobs = workspace
        .records('jobs')
        .where((item) => item.ref('mission_id') == missionId)
        .toList();
    final jobIds = jobs.map((item) => item.id).toSet();
    final applications = workspace
        .records('applications')
        .where((item) => jobIds.contains(item.ref('job_id')))
        .toList();
    final applicationIds = applications.map((item) => item.id).toSet();
    final interviews = workspace
        .records('interviews')
        .where((item) => applicationIds.contains(item.ref('application_id')))
        .length;
    return MissionCareerPipeline(
      jobs: jobs.length,
      applications: applications.length,
      interviews: interviews,
      offers: applications
          .where((item) => item.text('status').toLowerCase().contains('offer'))
          .length,
    );
  }
}

class DashboardPriority {
  final Project project;
  final double score;
  final String explanation;

  const DashboardPriority(this.project, this.score, this.explanation);
}

List<DashboardPriority> dashboardPriorities(
  Workspace workspace,
  StrategyRecord? mission,
  DateTime now,
) {
  final missionSkills = mission == null
      ? const <StrategyRecord>[]
      : workspace
            .records('skills')
            .where((skill) => skill.ref('mission_id') == mission.id)
            .toList();
  final largestSkillGap = missionSkills.isEmpty
      ? .5
      : missionSkills
            .map((skill) => 1 - workspace.readiness(skill.id) / 100)
            .reduce(max)
            .clamp(.05, 1.0);
  final priorities = <DashboardPriority>[];
  for (final project in workspace.projects.where(
    (project) => project.status == ProjectStatus.active,
  )) {
    final relevant =
        mission != null && projectSupportsMission(workspace, project, mission);
    final outcome = workspace.record(
      'outcomes',
      project.outcomeId ??
          workspace
              .record('initiatives', project.initiativeId)
              ?.ref('outcome_id'),
    );
    final outcomeGap = outcome == null || outcome.number('target') <= 0
        ? null
        : (1 - outcome.number('current_value') / outcome.number('target'))
              .clamp(.05, 1.0);
    final gap = outcomeGap ?? largestSkillGap;
    final target = project.at('target_at');
    final days = target?.difference(now).inDays;
    final urgency = days == null
        ? .5
        : days <= 7
        ? 1.0
        : days <= 30
        ? .8
        : days <= 90
        ? .6
        : .4;
    final explicitPriority = switch (project.priority) {
      1 => 1.0,
      2 => .75,
      _ => .5,
    };
    final relevance = relevant ? 1.0 : .25;
    final score = relevance * gap * urgency * explicitPriority;
    final gapLabel = '${(gap * 100).round()}% gap';
    final urgencyLabel = days == null
        ? 'no deadline'
        : days < 0
        ? '${-days}d overdue'
        : 'due in ${max(0, days)}d';
    priorities.add(
      DashboardPriority(
        project,
        score,
        '${relevant ? 'Mission-linked' : 'Supporting'} · $gapLabel · $urgencyLabel · P${project.priority}',
      ),
    );
  }
  priorities.sort((a, b) {
    final score = b.score.compareTo(a.score);
    if (score != 0) return score;
    final priority = a.project.priority.compareTo(b.project.priority);
    return priority == 0
        ? a.project.title.compareTo(b.project.title)
        : priority;
  });
  return priorities;
}

class DashboardWin {
  final StrategyRecord evidence;
  final Output output;
  final String skill;

  const DashboardWin({
    required this.evidence,
    required this.output,
    required this.skill,
  });
}

List<DashboardWin> dashboardWins(Workspace workspace, StrategyRecord? mission) {
  if (mission == null) return const [];
  final skills = <String, StrategyRecord>{
    for (final skill in workspace.records('skills'))
      if (skill.ref('mission_id') == mission.id) skill.id: skill,
  };
  final outputs = {for (final output in workspace.outputs) output.id: output};
  final wins =
      workspace
          .records('evidence')
          .where(
            (evidence) =>
                evidence.number('verified') == 1 &&
                skills.containsKey(evidence.ref('skill_id')) &&
                outputs.containsKey(evidence.ref('output_id')),
          )
          .map(
            (evidence) => DashboardWin(
              evidence: evidence,
              output: outputs[evidence.ref('output_id')]!,
              skill: skills[evidence.ref('skill_id')]!.title,
            ),
          )
          .toList()
        ..sort((a, b) => b.evidence.createdAt.compareTo(a.evidence.createdAt));
  return wins;
}

class EngineSummaryData {
  final String engine;
  final String purpose;
  final String status;
  final String detail;
  final double? progress;

  const EngineSummaryData({
    required this.engine,
    required this.purpose,
    required this.status,
    required this.detail,
    required this.progress,
  });
}

double? _metricProgress(Workspace workspace, String category) {
  final progresses = <double>[];
  for (final metric
      in workspace
          .records('metrics')
          .where((metric) => metric.text('category') == category)) {
    final target = (metric.data['target_value'] as num?)?.toDouble();
    if (target == null || target <= 0) continue;
    final snapshots =
        workspace
            .records('metric_snapshots')
            .where((snapshot) => snapshot.ref('metric_id') == metric.id)
            .toList()
          ..sort(
            (a, b) => (b.at('observed_at') ?? b.createdAt).compareTo(
              a.at('observed_at') ?? a.createdAt,
            ),
          );
    final latest = snapshots.firstOrNull;
    if (latest == null) continue;
    final value = (latest.data['value'] as num).toDouble();
    final progress = metric.text('direction') == 'LowerIsBetter'
        ? (value <= 0 ? 1.0 : target / value)
        : value / target;
    progresses.add(progress.clamp(0.0, 1.0));
  }
  if (progresses.isEmpty) return null;
  return progresses.reduce((a, b) => a + b) / progresses.length;
}

List<EngineSummaryData> engineSummaries(
  Workspace workspace,
  StrategyRecord? mission,
) {
  final allocations = <String, StrategyRecord>{
    for (final allocation in workspace.records('engine_allocations'))
      allocation.text('engine'): allocation,
  };
  final strategies = <String, StrategyRecord>{
    for (final strategy in workspace.records('strategies'))
      strategy.text('engine'): strategy,
  };
  String status(String engine) =>
      allocations[engine]?.text('mode') ??
      strategies[engine]?.text('allocation') ??
      'Not configured';
  String detail(String engine, String fallback) =>
      allocations[engine]?.text('current_objective').isNotEmpty == true
      ? allocations[engine]!.text('current_objective')
      : fallback;

  final careerMetric = _metricProgress(workspace, 'Career');
  final careerProgress =
      careerMetric ??
      (mission == null ? null : workspace.missionProgress(mission.id));

  final ownershipMetric = _metricProgress(workspace, 'Ownership');
  final ownershipProjects = workspace.projects.where((project) {
    if ([
      'Product',
      'IncomeExperiment',
    ].contains(project.text('project_type'))) {
      return true;
    }
    final linkedMission = workspace
        .records('missions')
        .where(
          (candidate) => projectSupportsMission(workspace, project, candidate),
        )
        .firstOrNull;
    return workspace
            .record('strategies', linkedMission?.ref('strategy_id'))
            ?.text('engine') ==
        'Ownership';
  }).toList();
  final ownershipIds = ownershipProjects.map((project) => project.id).toSet();
  final ownershipProgress =
      ownershipMetric ??
      workspace.progress(
        workspace.milestones.where(
          (milestone) => ownershipIds.contains(milestone.projectId),
        ),
      );

  final capitalProgress = _metricProgress(workspace, 'Capital');
  final hasNetWorth = workspace.records('net_worth_snapshots').isNotEmpty;
  return [
    EngineSummaryData(
      engine: 'Career',
      purpose: 'Skills → opportunities',
      status: status('Career'),
      detail: detail(
        'Career',
        careerMetric == null
            ? 'Active mission progress'
            : 'Tracked career metrics',
      ),
      progress: careerProgress,
    ),
    EngineSummaryData(
      engine: 'Ownership',
      purpose: 'Projects → durable assets',
      status: status('Ownership'),
      detail: detail(
        'Ownership',
        ownershipProgress == null
            ? 'No measurable milestones'
            : 'Product milestone progress',
      ),
      progress: ownershipProgress,
    ),
    EngineSummaryData(
      engine: 'Capital',
      purpose: 'Savings → compounding',
      status: status('Capital'),
      detail: detail(
        'Capital',
        capitalProgress != null
            ? 'Tracked capital metrics'
            : hasNetWorth
            ? 'Net worth recorded · set a target metric'
            : 'No target metric yet',
      ),
      progress: capitalProgress,
    ),
  ];
}
