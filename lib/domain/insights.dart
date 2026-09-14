import 'dart:math';
import 'models.dart';

DateTime weekStart(DateTime now) =>
    DateTime(now.year, now.month, now.day - now.weekday + 1);
DateTime weekEnd(DateTime start) =>
    DateTime(start.year, start.month, start.day + 7);
bool within(DateTime time, DateTime start, DateTime end) =>
    !time.isBefore(start) && time.isBefore(end);

class WeeklyMetrics {
  final DateTime start;
  final int planned, completed, pending, scheduledMinutes, outputCount;
  final Set<String> goalIds, outputProjectIds, activityProjectIds;
  const WeeklyMetrics(
    this.start,
    this.planned,
    this.completed,
    this.pending,
    this.scheduledMinutes,
    this.outputCount,
    this.goalIds,
    this.outputProjectIds,
    this.activityProjectIds,
  );
  double? get completion => planned == 0 ? null : completed / planned;
  factory WeeklyMetrics.calculate(Workspace w, DateTime day) {
    final start = weekStart(day), end = weekEnd(weekStart(day));
    final planned = w.sessions.where(
      (s) =>
          s.status != SessionStatus.cancelled &&
          within(s.plannedStart, start, end),
    );
    final output = w.outputs.where((o) => within(o.createdAt, start, end));
    final completed = planned
        .where((session) => session.status == SessionStatus.done)
        .toList();
    return WeeklyMetrics(
      start,
      planned.length,
      completed.length,
      planned.where((session) => session.isAwaitingResult(day)).length,
      planned.fold(0, (total, session) => total + session.plannedMinutes),
      output.length,
      completed.map((s) => w.sessionGoal(s)?.id).whereType<String>().toSet(),
      output.map((o) => o.projectId).whereType<String>().toSet(),
      completed.map((s) => s.projectId).whereType<String>().toSet(),
    );
  }
}

DateTime lastProjectActivity(Workspace w, Project p) {
  final dates = <DateTime>[
    p.createdAt,
    ...w.sessions
        .where((s) => s.projectId == p.id && s.status == SessionStatus.done)
        .map((s) => s.plannedEnd),
    ...w.outputs.where((o) => o.projectId == p.id).map((o) => o.createdAt),
    ...w.milestones
        .where((m) => m.projectId == p.id && m.completed)
        .map((m) => m.at('completed_at')!),
  ];
  dates.sort();
  return dates.last;
}

List<Project> inactiveProjects(Workspace w, DateTime now, {int days = 21}) => w
    .projects
    .where(
      (p) =>
          p.status == ProjectStatus.active &&
          now.difference(lastProjectActivity(w, p)).inDays >= days,
    )
    .toList();
List<Goal> inactiveGoals(Workspace w, DateTime now, {int days = 14}) =>
    w.goals.where((g) {
      if (g.status != GoalStatus.active) return false;
      final dates = [
        g.createdAt,
        ...w.projects
            .where((p) => p.goalId == g.id)
            .map((p) => lastProjectActivity(w, p)),
        ...w.sessions
            .where(
              (s) =>
                  w.sessionGoal(s)?.id == g.id &&
                  s.status == SessionStatus.done,
            )
            .map((s) => s.plannedEnd),
      ];
      dates.sort();
      return now.difference(dates.last).inDays >= days;
    }).toList();
int activityScore(Workspace w, LifeArea area, DateTime now) {
  final since = now.subtract(const Duration(days: 7));
  final goals = w.goals
      .where((g) => g.areaId == area.id && g.status == GoalStatus.active)
      .map((g) => g.id)
      .toSet();
  final sessions = w.sessions
      .where(
        (s) =>
            goals.contains(w.sessionGoal(s)?.id) &&
            s.status == SessionStatus.done &&
            within(
              s.plannedEnd,
              since,
              now.add(const Duration(milliseconds: 1)),
            ),
      )
      .length;
  final milestones = w.milestones
      .where(
        (m) =>
            goals.contains(w.project(m.projectId)?.goalId) &&
            m.completed &&
            within(
              m.at('completed_at')!,
              since,
              now.add(const Duration(milliseconds: 1)),
            ),
      )
      .length;
  return (min(20, goals.length * 5) +
          min(50, sessions * 10) +
          min(30, milestones * 10) -
          (goals.isNotEmpty && sessions == 0 ? 20 : 0))
      .clamp(0, 100)
      .toInt();
}

class Insight {
  final String id, message;
  final String? projectId, goalId;
  const Insight(this.id, this.message, {this.projectId, this.goalId});
}

abstract interface class InsightProvider {
  List<Insight> generate(Workspace workspace, DateTime now);
}

class RuleBasedInsightProvider implements InsightProvider {
  @override
  List<Insight> generate(Workspace w, DateTime now) {
    final result = <Insight>[];
    final m = WeeklyMetrics.calculate(w, now);
    for (final p in w.projects.where((p) => p.status == ProjectStatus.active)) {
      final sessions = w.sessions.where(
        (s) =>
            s.projectId == p.id &&
            s.status == SessionStatus.done &&
            s.plannedEnd.isAfter(now.subtract(const Duration(days: 14))),
      );
      final outputs = w.outputs.where(
        (o) =>
            o.projectId == p.id &&
            o.createdAt.isAfter(now.subtract(const Duration(days: 14))),
      );
      if (sessions.length >= 3 && outputs.isEmpty) {
        result.add(
          Insight(
            'no-output-${p.id}',
            '${p.title} received ${sessions.length} sessions in 14 days but produced no recorded output. Define one small deliverable.',
            projectId: p.id,
          ),
        );
      }
      if (now.difference(p.createdAt).inDays >= 30 &&
          !w.milestones.any((x) => x.projectId == p.id && x.completed)) {
        result.add(
          Insight(
            'milestone-${p.id}',
            '${p.title} has been open for 30+ days without a completed milestone. Make the next milestone smaller.',
            projectId: p.id,
          ),
        );
      }
    }
    for (final p in inactiveProjects(w, now)) {
      result.add(
        Insight(
          'inactive-${p.id}',
          '${p.title} has no activity for ${now.difference(lastProjectActivity(w, p)).inDays} days. Schedule a session or pause it.',
          projectId: p.id,
        ),
      );
    }
    for (final g in inactiveGoals(w, now)) {
      result.add(
        Insight(
          'goal-${g.id}',
          '${g.title} has received no activity for at least 14 days. Revisit its priority.',
          goalId: g.id,
        ),
      );
    }
    if (m.planned > 0) {
      result.add(
        Insight(
          'completion',
          '${m.completed} of ${m.planned} planned sessions completed this week (${(m.completion! * 100).round()}%). Outputs recorded: ${m.outputCount}.',
        ),
      );
    }
    if (result.isEmpty) {
      result.add(
        const Insight(
          'begin',
          'Start with one meaningful session. Define the output you want before you begin.',
        ),
      );
    }
    return result;
  }
}
