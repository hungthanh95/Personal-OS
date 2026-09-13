import 'models.dart';
import 'intelligence.dart';
import 'career.dart';

abstract interface class WorkspaceRepository {
  Future<Workspace> load();
  Future<void> save(String table, DataRowMap row);
  Future<void> startSession(String id, DateTime now);
  Future<void> reviewSession(
    String id,
    SessionStatus status,
    DateTime now, {
    String output = '',
    String learning = '',
    String nextAction = '',
    String link = '',
    int? correctedSeconds,
  });
  Future<void> reschedule(String id, DateTime start, int minutes);
  Future<void> triage(String inboxId, String destination, DataRowMap row);
  Future<void> clearDemo();
  Future<void> backup(String path);
  Future<void> exportPortableJson(String path);
  Future<void> deleteDataCategory(String category);
  Future<void> installStrategyTemplate(Map<String, List<DataRowMap>> records);
  Future<int> importJobDescriptions(String missionId, String text);
  Future<void> convertInterviewQuestionToPriority(String questionId);
  Future<int> generateRecurringSessions(DateTime through);
  Future<String> preserveKnowledgeSource(String sourcePath, String checksum);
  Future<List<KnowledgeSearchHit>> searchKnowledge(
    String query, {
    int limit = 40,
    List<double>? semanticVector,
  });
  Future<void> updateReadinessWeights(Map<String, double> weights);
  Future<String> createWeeklyPlanPreview(
    String missionId,
    List<PrioritySuggestion> suggestions,
  );
  Future<String> saveAdaptiveReview(AdaptiveReviewDraft draft);
  Future<void> decidePlanningChangeSet(String id, {required bool approve});
  Future<int> applyPlanningChangeSet(String id);
  Future<void> close();
}
