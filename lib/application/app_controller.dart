import 'package:flutter/foundation.dart';
import '../domain/models.dart';
import '../domain/repository.dart';
import '../domain/insights.dart';
import '../domain/intelligence.dart';

class AppController extends ChangeNotifier {
  final WorkspaceRepository repository;
  final InsightProvider insightProvider;
  final IntelligenceProvider intelligenceProvider;
  Workspace workspace = const Workspace();
  bool loading = true;
  String? error;
  AppController(
    this.repository, {
    InsightProvider? insightProvider,
    IntelligenceProvider? intelligenceProvider,
  }) : insightProvider = insightProvider ?? RuleBasedInsightProvider(),
       intelligenceProvider =
           intelligenceProvider ?? const LocalIntelligenceProvider();
  Future<void> refresh() async {
    try {
      workspace = await repository.load();
      error = null;
    } catch (e) {
      error = 'Could not load local data: $e';
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> save(String table, DataRowMap row) async {
    await repository.save(table, row);
    await refresh();
  }

  Future<void> start(Session s) async {
    await repository.startSession(s.id, DateTime.now());
    await refresh();
  }

  Future<void> review(
    Session s,
    SessionStatus status, {
    String output = '',
    String learning = '',
    String nextAction = '',
    String link = '',
    int? seconds,
  }) async {
    await repository.reviewSession(
      s.id,
      status,
      DateTime.now(),
      output: output,
      learning: learning,
      nextAction: nextAction,
      link: link,
      correctedSeconds: seconds,
    );
    await refresh();
  }

  Future<void> reschedule(Session s, DateTime start, int minutes) async {
    await repository.reschedule(s.id, start, minutes);
    await refresh();
  }

  Future<void> triage(String id, String table, DataRowMap row) async {
    await repository.triage(id, table, row);
    await refresh();
  }

  Future<void> clearDemo() async {
    await repository.clearDemo();
    await refresh();
  }

  Future<void> deleteDataCategory(String category) async {
    await repository.deleteDataCategory(category);
    await refresh();
  }

  Future<int> importJobDescriptions(String missionId, String text) async {
    final count = await repository.importJobDescriptions(missionId, text);
    await refresh();
    return count;
  }

  Future<void> convertInterviewQuestionToPriority(String questionId) async {
    await repository.convertInterviewQuestionToPriority(questionId);
    await refresh();
  }

  Future<int> generateRecurringSessions(DateTime through) async {
    final count = await repository.generateRecurringSessions(through);
    await refresh();
    return count;
  }

  List<Insight> get insights =>
      insightProvider.generate(workspace, DateTime.now());
  List<Entity> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    const searchableStrategyTables = [
      'visions',
      'strategies',
      'missions',
      'skills',
      'assumptions',
      'strategy_proposals',
      'jobs',
      'interview_questions',
      'learning_priorities',
      'experiments',
      'period_reviews',
    ];
    return <Entity>[
          ...workspace.goals,
          ...workspace.projects,
          ...workspace.sessions,
          ...workspace.outputs,
          ...workspace.knowledge,
          for (final table in searchableStrategyTables)
            ...workspace.records(table),
        ]
        .where(
          (e) => e.data.values.whereType<String>().any(
            (v) => v.toLowerCase().contains(q),
          ),
        )
        .take(80)
        .toList();
  }

  Future<List<KnowledgeSearchHit>> searchKnowledge(String query) =>
      repository.searchKnowledge(
        query,
        semanticVector: intelligenceProvider.embed(query),
      );

  IntelligenceContextBoundary get intelligenceContext =>
      intelligenceProvider.contextBoundary(workspace);

  Future<void> updateReadinessWeights(Map<String, double> weights) async {
    await repository.updateReadinessWeights(weights);
    await refresh();
  }

  Future<String> createWeeklyPlanPreview(String missionId) async {
    final suggestions = intelligenceProvider.recommendNextWeek(
      workspace,
      missionId,
    );
    final id = await repository.createWeeklyPlanPreview(missionId, suggestions);
    await refresh();
    return id;
  }

  Future<String> generateAdaptiveReview({
    required String type,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final draft = intelligenceProvider.buildReview(
      workspace,
      type: type,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
    final id = await repository.saveAdaptiveReview(draft);
    await refresh();
    return id;
  }

  Future<void> decidePlanningChangeSet(
    String id, {
    required bool approve,
  }) async {
    await repository.decidePlanningChangeSet(id, approve: approve);
    await refresh();
  }

  Future<int> applyPlanningChangeSet(String id) async {
    final count = await repository.applyPlanningChangeSet(id);
    await refresh();
    return count;
  }
}
