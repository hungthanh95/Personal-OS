import 'dart:math';

typedef DataRowMap = Map<String, Object?>;
String newId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${List.generate(12, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
DateTime? date(Object? value) =>
    value == null ? null : DateTime.fromMillisecondsSinceEpoch(value as int);

abstract class Entity {
  final DataRowMap data;
  Entity(DataRowMap data) : data = Map.unmodifiable(data);
  String get id => text('id');
  String get title => text('title');
  String text(String key) => data[key] as String? ?? '';
  String? ref(String key) => data[key] as String?;
  int number(String key, [int fallback = 0]) => data[key] as int? ?? fallback;
  DateTime? at(String key) => date(data[key]);
  DateTime get createdAt => at('created_at') ?? DateTime(2000);
  DataRowMap patch(DataRowMap changes) => {...data, ...changes};
}

class LifeArea extends Entity {
  LifeArea(super.data);
  int get color => number('color', 0xff54816d);
}

enum GoalStatus { active, paused, completed, abandoned }

class Goal extends Entity {
  Goal(super.data);
  String? get areaId => ref('life_area_id');
  int get priority => number('priority', 2);
  GoalStatus get status => GoalStatus.values.byName(text('status'));
}

enum ProjectStatus { active, paused, completed, archived }

class Project extends Entity {
  Project(super.data);
  String? get goalId => ref('goal_id');
  String? get outcomeId => ref('outcome_id');
  String? get initiativeId => ref('initiative_id');
  int get priority => number('priority', 2);
  ProjectStatus get status => ProjectStatus.values.byName(text('status'));
  String get nextAction => text('next_action');
}

class Milestone extends Entity {
  Milestone(super.data);
  String get projectId => text('project_id');
  bool get completed => at('completed_at') != null;
}

enum SessionStatus {
  planned('PLANNED', 'Planned'),
  active('ACTIVE', 'Active'),
  done('DONE', 'Done'),
  inProgress('IN_PROGRESS', 'In progress'),
  blocked('BLOCKED', 'Blocked'),
  skipped('SKIPPED', 'Skipped'),
  cancelled('CANCELLED', 'Cancelled');

  final String value, label;
  const SessionStatus(this.value, this.label);
  bool get terminal => this == done || this == skipped || this == cancelled;
  bool canTransitionTo(SessionStatus next) =>
      !terminal && next != this && next != planned;
}

class Session extends Entity {
  Session(super.data);
  String? get projectId => ref('project_id');
  String? get goalId => ref('goal_id');
  String? get taskId => ref('task_id');
  int get priority => number('priority', 2);
  SessionStatus get status => number('blocked') == 1
      ? SessionStatus.blocked
      : SessionStatus.values.firstWhere((s) => s.value == text('status'));
  String get blockedReason => text('blocked_reason');
  DateTime get plannedStart => at('planned_start')!;
  int get plannedMinutes => number('planned_minutes', 60);
  int get actualSeconds => number('actual_seconds');
  DateTime? get segmentStart => at('segment_start');
  bool get attended =>
      at('actual_start') != null && status != SessionStatus.cancelled;
  int elapsedSeconds(DateTime now) =>
      actualSeconds +
      (segmentStart == null
          ? 0
          : max(0, now.difference(segmentStart!).inSeconds));
}

class WorkTask extends Entity {
  WorkTask(super.data);
  bool get done => text('status') == 'Done' || number('done') == 1;
}

class Output extends Entity {
  Output(super.data);
  String? get projectId => ref('project_id');
  String? get sessionId => ref('session_id');
}

class KnowledgeItem extends Entity {
  KnowledgeItem(super.data);
  String? get projectId => ref('project_id');
  String? get goalId => ref('goal_id');
}

class KnowledgeSearchHit {
  final KnowledgeItem item;
  final String snippet;
  final double rank;
  final String relationship;
  final String? sectionTitle;
  final int? startOffset;

  const KnowledgeSearchHit({
    required this.item,
    required this.snippet,
    required this.rank,
    this.relationship = 'Full-text match',
    this.sectionTitle,
    this.startOffset,
  });
}

class InboxItem extends Entity {
  InboxItem(super.data);
  bool get processed => at('processed_at') != null;
}

class WeeklyReview extends Entity {
  WeeklyReview(super.data);
}

class FocusInterval extends Entity {
  FocusInterval(super.data);
  String get sessionId => text('session_id');
  DateTime get start => at('start_at')!;
  DateTime get end => at('end_at')!;
  int get seconds => number('seconds');
}

class StrategyRecord extends Entity {
  StrategyRecord(super.data);
}

class ReadinessDimension {
  final String name;
  final double weight;
  final int score;
  final int? previousScore;
  final StrategyRecord? evidence;

  const ReadinessDimension({
    required this.name,
    required this.weight,
    required this.score,
    required this.previousScore,
    required this.evidence,
  });

  int? get assessmentDelta =>
      previousScore == null ? null : score - previousScore!;
  double get contribution => score * weight;
}

class ProductUsageSummary {
  final int activeDays;
  final int plannedSessions;
  final int completedSessions;
  final int reviews;
  final int evidenceCount;
  final int searches;
  final double? retrievalSuccess;
  final double? averageSearchMs;
  final int decidedRecommendations;
  final int acceptedRecommendations;

  const ProductUsageSummary({
    required this.activeDays,
    required this.plannedSessions,
    required this.completedSessions,
    required this.reviews,
    required this.evidenceCount,
    required this.searches,
    required this.retrievalSuccess,
    required this.averageSearchMs,
    required this.decidedRecommendations,
    required this.acceptedRecommendations,
  });

  double? get completionRate =>
      plannedSessions == 0 ? null : completedSessions / plannedSessions;
  double? get recommendationAcceptance => decidedRecommendations == 0
      ? null
      : acceptedRecommendations / decidedRecommendations;
}

class Workspace {
  final Map<String, List<StrategyRecord>> strategyData;
  final List<LifeArea> areas;
  final List<Goal> goals;
  final List<Project> projects;
  final List<Milestone> milestones;
  final List<Session> sessions;
  final List<WorkTask> tasks;
  final List<Output> outputs;
  final List<KnowledgeItem> knowledge;
  final List<InboxItem> inbox;
  final List<WeeklyReview> reviews;
  final List<FocusInterval> intervals;
  final Map<String, String> settings;
  const Workspace({
    this.strategyData = const {},
    this.areas = const [],
    this.goals = const [],
    this.projects = const [],
    this.milestones = const [],
    this.sessions = const [],
    this.tasks = const [],
    this.outputs = const [],
    this.knowledge = const [],
    this.inbox = const [],
    this.reviews = const [],
    this.intervals = const [],
    this.settings = const {},
  });
  Project? project(String? id) => projects.where((x) => x.id == id).firstOrNull;
  Goal? goal(String? id) => goals.where((x) => x.id == id).firstOrNull;
  Goal? sessionGoal(Session s) {
    final linkedProject = project(s.projectId);
    final direct = goal(linkedProject?.goalId ?? s.goalId);
    if (direct != null) return direct;
    final initiative = record('initiatives', linkedProject?.initiativeId);
    final outcome = record(
      'outcomes',
      linkedProject?.outcomeId ?? initiative?.ref('outcome_id'),
    );
    final mission = record(
      'missions',
      outcome?.ref('mission_id') ?? initiative?.ref('mission_id'),
    );
    return goal(mission?.ref('goal_id'));
  }

  double? progress(Iterable<Milestone> items) => items.isEmpty
      ? null
      : items.where((m) => m.completed).length / items.length;
  double? projectProgress(String id) =>
      progress(milestones.where((m) => m.projectId == id));
  double? goalProgress(String id) =>
      progress(milestones.where((m) => project(m.projectId)?.goalId == id));
  List<Session> today(DateTime now) {
    final start = DateTime(now.year, now.month, now.day),
        end = DateTime(now.year, now.month, now.day + 1);
    final result = sessions
        .where(
          (s) =>
              s.status != SessionStatus.cancelled &&
              (s.status == SessionStatus.active ||
                  (!s.plannedStart.isBefore(start) &&
                      s.plannedStart.isBefore(end)) ||
                  (!s.status.terminal && s.plannedStart.isBefore(start))),
        )
        .toList();
    result.sort((a, b) {
      var c = a.plannedStart.compareTo(b.plannedStart);
      if (c == 0) c = a.priority.compareTo(b.priority);
      if (c == 0) {
        c = (sessionGoal(a)?.priority ?? 2).compareTo(
          sessionGoal(b)?.priority ?? 2,
        );
      }
      return c == 0 ? a.id.compareTo(b.id) : c;
    });
    return result;
  }

  List<StrategyRecord> records(String table) => strategyData[table] ?? const [];
  StrategyRecord? record(String table, String? id) =>
      records(table).where((r) => r.id == id).firstOrNull;
  StrategyRecord? get activeMission {
    final missions =
        records('missions').where((r) => r.text('status') == 'Active').toList()
          ..sort(
            (a, b) => a.number('priority').compareTo(b.number('priority')),
          );
    return missions.firstOrNull;
  }

  Map<String, double> get configuredReadinessWeights {
    final configured = records('readiness_weights');
    if (configured.isEmpty) return readinessWeights;
    final weights = <String, double>{
      for (final record in configured)
        record.text('dimension'): (record.data['weight'] as num).toDouble(),
    };
    final total = weights.values.fold(0.0, (sum, value) => sum + value);
    return total <= 0
        ? readinessWeights
        : weights.map((key, value) => MapEntry(key, value / total));
  }

  List<ReadinessDimension> readinessBreakdown(String skillId) =>
      configuredReadinessWeights.entries.map((dimension) {
        final entries =
            records('evidence')
                .where(
                  (record) =>
                      record.ref('skill_id') == skillId &&
                      record.text('dimension') == dimension.key &&
                      record.number('verified') == 1,
                )
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return ReadinessDimension(
          name: dimension.key,
          weight: dimension.value,
          score: entries.firstOrNull?.number('score') ?? 0,
          previousScore: entries.length > 1 ? entries[1].number('score') : null,
          evidence: entries.firstOrNull,
        );
      }).toList();

  double readinessAt(String skillId, DateTime cutoff) =>
      configuredReadinessWeights.entries.fold(0.0, (total, dimension) {
        final entries =
            records('evidence')
                .where(
                  (record) =>
                      record.ref('skill_id') == skillId &&
                      record.text('dimension') == dimension.key &&
                      record.number('verified') == 1 &&
                      !record.createdAt.isAfter(cutoff),
                )
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return total +
            (entries.firstOrNull?.number('score') ?? 0) * dimension.value;
      });

  double readiness(String skillId) => readinessBreakdown(
    skillId,
  ).fold(0.0, (total, dimension) => total + dimension.contribution);

  ProductUsageSummary usageSummary(DateTime now) {
    final start = now.subtract(const Duration(days: 30));
    final periodSessions = sessions
        .where(
          (session) =>
              !session.plannedStart.isBefore(start) &&
              !session.plannedStart.isAfter(now) &&
              session.status != SessionStatus.cancelled,
        )
        .toList();
    final activeDays = periodSessions
        .where((session) => session.attended)
        .map(
          (session) =>
              '${session.plannedStart.year}-${session.plannedStart.month}-${session.plannedStart.day}',
        )
        .toSet()
        .length;
    final periodEvidence = records('evidence')
        .where(
          (record) =>
              !record.createdAt.isBefore(start) &&
              !record.createdAt.isAfter(now),
        )
        .length;
    final searches = records('knowledge_search_events')
        .where(
          (record) =>
              record.at('searched_at') != null &&
              !record.at('searched_at')!.isBefore(start) &&
              !record.at('searched_at')!.isAfter(now),
        )
        .toList();
    final decisions = records('recommendation_decisions')
        .where(
          (record) =>
              !record.createdAt.isBefore(start) &&
              !record.createdAt.isAfter(now),
        )
        .toList();
    final averageSearchMs = searches.isEmpty
        ? null
        : searches.fold<double>(
                0,
                (sum, record) => sum + record.number('duration_ms'),
              ) /
              searches.length;
    return ProductUsageSummary(
      activeDays: activeDays,
      plannedSessions: periodSessions.length,
      completedSessions: periodSessions
          .where((session) => session.status == SessionStatus.done)
          .length,
      reviews: reviews
          .where(
            (review) =>
                review.at('updated_at') != null &&
                !review.at('updated_at')!.isBefore(start) &&
                !review.at('updated_at')!.isAfter(now),
          )
          .length,
      evidenceCount: periodEvidence,
      searches: searches.length,
      retrievalSuccess: searches.isEmpty
          ? null
          : searches
                    .where((record) => record.number('result_count') > 0)
                    .length /
                searches.length,
      averageSearchMs: averageSearchMs,
      decidedRecommendations: decisions.length,
      acceptedRecommendations: decisions
          .where((record) => record.text('decision') == 'Accepted')
          .length,
    );
  }

  double missionProgress(String id) {
    final items = records('outcomes').where((r) => r.ref('mission_id') == id);
    if (items.isEmpty) return 0;
    final weight = items.fold(0, (sum, r) => sum + r.number('weight', 1));
    return items.fold(
          0.0,
          (sum, r) =>
              sum +
              (r.number('current_value') / r.number('target', 1)).clamp(0, 1) *
                  r.number('weight', 1),
        ) /
        weight;
  }

  String whyPath(Session session) {
    final g = sessionGoal(session);
    final linkedProject = project(session.projectId);
    final initiative = record('initiatives', linkedProject?.initiativeId);
    final outcome = record(
      'outcomes',
      linkedProject?.outcomeId ?? initiative?.ref('outcome_id'),
    );
    final m =
        record(
          'missions',
          outcome?.ref('mission_id') ?? initiative?.ref('mission_id'),
        ) ??
        records(
          'missions',
        ).where((r) => g != null && r.ref('goal_id') == g.id).firstOrNull;
    final s = record('strategies', m?.ref('strategy_id'));
    final v = record('visions', s?.ref('vision_id'));
    return [
      session.title,
      linkedProject?.title,
      initiative?.title,
      outcome?.title,
      if (outcome == null) g?.title,
      m?.title,
      s?.title,
      v?.title,
    ].whereType<String>().join(' → ');
  }
}

const readinessWeights = <String, double>{
  'Knowledge': .15,
  'Implementation': .20,
  'Debugging': .20,
  'Application': .20,
  'Interview': .15,
  'Production': .10,
};
