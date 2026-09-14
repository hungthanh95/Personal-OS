import 'models.dart';
import 'intelligence.dart';
import 'career.dart';

class SessionReconciliationSummary {
  final int scanned;
  final int completed;
  final int pending;
  final int errors;

  const SessionReconciliationSummary({
    this.scanned = 0,
    this.completed = 0,
    this.pending = 0,
    this.errors = 0,
  });
}

abstract interface class WorkspaceRepository {
  Future<Workspace> load();
  Future<void> save(String table, DataRowMap row);
  Future<void> reschedule(String id, DateTime start, int minutes);
  Future<void> triage(String inboxId, String destination, DataRowMap row);
  Future<void> clearDemo();
  Future<void> backup(String path);
  Future<void> backupWorkspace(String path);
  Future<void> exportPortableJson(String path);
  Future<void> deleteDataCategory(String category);
  Future<void> installStrategyTemplate(Map<String, List<DataRowMap>> records);
  Future<int> importJobDescriptions(String missionId, String text);
  Future<void> convertInterviewQuestionToPriority(String questionId);
  Future<int> generateRecurringSessions(DateTime through);
  Future<void> configureMarkdownWorkspace(String path);
  Future<String> markdownRecordPath(String table, String id);
  Future<String> sessionNotePath(String sessionId);
  Future<SessionReconciliationSummary> reconcileSessions({DateTime? now});
  Future<void> setSessionDisposition(String sessionId, String status);
  Future<void> syncMarkdownRecord(String table, String id);
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
