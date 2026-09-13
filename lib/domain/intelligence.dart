import 'career.dart';
import 'insights.dart';
import 'knowledge.dart';
import 'models.dart';

class IntelligenceContextBoundary {
  final String mode;
  final bool sendsDataOffDevice;
  final List<String> includedData;
  final String explanation;

  const IntelligenceContextBoundary({
    required this.mode,
    required this.sendsDataOffDevice,
    required this.includedData,
    required this.explanation,
  });
}

class StructuredRecommendation {
  final String type;
  final String title;
  final String reason;
  final String factBasis;
  final String inference;
  final String expectedBenefit;
  final String risk;
  final int confidence;
  final String suggestedAction;
  final List<String> evidenceIds;
  final String? targetType;
  final String? targetId;

  const StructuredRecommendation({
    required this.type,
    required this.title,
    required this.reason,
    required this.factBasis,
    required this.inference,
    required this.expectedBenefit,
    required this.risk,
    required this.confidence,
    required this.suggestedAction,
    this.evidenceIds = const [],
    this.targetType,
    this.targetId,
  });
}

class AdaptiveReviewDraft {
  final String type;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String summary;
  final List<String> wins;
  final List<String> problems;
  final List<String> evidenceIds;
  final List<String> changedAssumptionIds;
  final List<String> carryForward;
  final List<String> nextPriorities;
  final List<StructuredRecommendation> recommendations;

  const AdaptiveReviewDraft({
    required this.type,
    required this.periodStart,
    required this.periodEnd,
    required this.summary,
    required this.wins,
    required this.problems,
    required this.evidenceIds,
    required this.changedAssumptionIds,
    required this.carryForward,
    required this.nextPriorities,
    required this.recommendations,
  });
}

abstract interface class IntelligenceProvider {
  String get name;
  IntelligenceContextBoundary contextBoundary(Workspace workspace);
  KnowledgeMetadataSuggestion analyzeKnowledge(
    String text,
    Workspace workspace,
  );
  List<PrioritySuggestion> recommendNextWeek(
    Workspace workspace,
    String missionId,
  );
  AdaptiveReviewDraft buildReview(
    Workspace workspace, {
    required String type,
    required DateTime periodStart,
    required DateTime periodEnd,
  });
  List<double> embed(String text, {int dimensions = 96});
}

class LocalIntelligenceProvider implements IntelligenceProvider {
  const LocalIntelligenceProvider();

  @override
  String get name => 'Local explainable rules';

  @override
  IntelligenceContextBoundary contextBoundary(
    Workspace workspace,
  ) => const IntelligenceContextBoundary(
    mode: 'Local-only',
    sendsDataOffDevice: false,
    includedData: [
      'workspace records already stored in the local SQLite database',
    ],
    explanation:
        'Rules and embeddings run inside the app process. No document, salary, career or strategy data is sent to a service.',
  );

  @override
  KnowledgeMetadataSuggestion analyzeKnowledge(
    String text,
    Workspace workspace,
  ) => suggestKnowledgeMetadata(text, workspace);

  @override
  List<PrioritySuggestion> recommendNextWeek(
    Workspace workspace,
    String missionId,
  ) => nextWeekPrioritySuggestions(workspace, missionId);

  @override
  AdaptiveReviewDraft buildReview(
    Workspace workspace, {
    required String type,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    if (!periodStart.isBefore(periodEnd)) {
      throw ArgumentError('Review period end must be after its start.');
    }
    final mission = workspace.activeMission;
    final sessions = workspace.sessions
        .where(
          (session) =>
              !session.plannedStart.isBefore(periodStart) &&
              session.plannedStart.isBefore(periodEnd) &&
              session.status != SessionStatus.cancelled,
        )
        .toList();
    final outputs = workspace.outputs
        .where(
          (output) =>
              !output.createdAt.isBefore(periodStart) &&
              output.createdAt.isBefore(periodEnd),
        )
        .toList();
    final completed = sessions
        .where((session) => session.status == SessionStatus.done)
        .length;
    final missed = sessions
        .where(
          (session) =>
              session.status == SessionStatus.skipped ||
              (!session.status.terminal &&
                  session.plannedStart.isBefore(periodEnd)),
        )
        .toList();
    final openEventIds = workspace
        .records('strategy_events')
        .where(
          (event) =>
              event.number('review_recommended') == 1 &&
              event.data['reviewed_at'] == null,
        )
        .map((event) => event.id)
        .toSet();
    final eventAffectedAssumptions = workspace
        .records('event_assumptions')
        .where((link) => openEventIds.contains(link.ref('event_id')))
        .map((link) => link.ref('assumption_id'))
        .whereType<String>()
        .toSet();
    final changedAssumptions = workspace
        .records('assumptions')
        .where(
          (assumption) =>
              assumption.text('status') == 'Weakening' ||
              assumption.text('status') == 'Invalidated' ||
              (assumption.text('status') == 'Unverified' &&
                  assumption.number('confidence') <= 40) ||
              eventAffectedAssumptions.contains(assumption.id),
        )
        .toList();
    final verifiedEvidence = workspace
        .records('evidence')
        .where(
          (evidence) =>
              evidence.number('verified') == 1 &&
              !evidence.createdAt.isBefore(periodStart) &&
              evidence.createdAt.isBefore(periodEnd),
        )
        .toList();
    final jobs = workspace
        .records('jobs')
        .where(
          (job) =>
              !job.createdAt.isBefore(periodStart) &&
              job.createdAt.isBefore(periodEnd),
        )
        .toList();
    final applications = workspace
        .records('applications')
        .where(
          (application) =>
              !application.createdAt.isBefore(periodStart) &&
              application.createdAt.isBefore(periodEnd),
        )
        .toList();
    final interviews = workspace
        .records('interviews')
        .where(
          (interview) =>
              !interview.createdAt.isBefore(periodStart) &&
              interview.createdAt.isBefore(periodEnd),
        )
        .toList();
    final revenue = workspace
        .records('revenue_entries')
        .where(
          (entry) =>
              !entry.createdAt.isBefore(periodStart) &&
              entry.createdAt.isBefore(periodEnd),
        )
        .fold<double>(
          0,
          (sum, entry) => sum + (entry.data['amount'] as num).toDouble(),
        );
    final discoveries = workspace
        .records('customer_discoveries')
        .where(
          (entry) =>
              !entry.createdAt.isBefore(periodStart) &&
              entry.createdAt.isBefore(periodEnd),
        )
        .toList();
    final focusedSeconds = sessions.fold<int>(
      0,
      (sum, session) => sum + session.actualSeconds,
    );
    final wins = <String>[
      if (completed > 0) '$completed sessions completed',
      if (outputs.isNotEmpty) '${outputs.length} concrete outputs recorded',
      if (verifiedEvidence.isNotEmpty)
        '${verifiedEvidence.length} verified skill assessments added',
      if (workspace
          .records('applications')
          .any((application) => application.text('status') == 'Offer'))
        'At least one job application reached Offer',
      if (workspace
          .records('experiments')
          .any((experiment) => experiment.text('signal') == 'Revenue'))
        'An Income Lab experiment recorded a revenue signal',
      if (jobs.isNotEmpty) '${jobs.length} target jobs analyzed',
      if (applications.isNotEmpty)
        '${applications.length} applications entered the pipeline',
      if (interviews.isNotEmpty)
        '${interviews.length} interviews supplied market feedback',
      if (discoveries.isNotEmpty)
        '${discoveries.length} customer discovery signals recorded',
      if (revenue > 0) '${revenue.toStringAsFixed(2)} revenue recorded',
    ];
    final problems = <String>[
      if (missed.isNotEmpty)
        '${missed.length} planned sessions slipped or were skipped',
      if (outputs.isEmpty && sessions.isNotEmpty)
        'No concrete output was recorded for this period',
      for (final assumption in changedAssumptions)
        'Assumption ${assumption.title} is ${assumption.text('status')}',
      for (final project in inactiveProjects(workspace, periodEnd))
        'Project ${project.title} has no recent activity',
      if (type == 'Quarterly' &&
          sessions.isNotEmpty &&
          completed * 2 < sessions.length)
        'Quarterly session completion was below 50%',
    ];
    final priorities = mission == null
        ? const <PrioritySuggestion>[]
        : recommendNextWeek(workspace, mission.id);
    final recommendations = <StructuredRecommendation>[
      for (final priority in priorities)
        StructuredRecommendation(
          type: 'Planning',
          title: priority.title,
          reason: priority.reason,
          factBasis: priority.reason,
          inference:
              'Giving this gap focused time next period is likely to improve mission readiness.',
          expectedBenefit: 'Improve progress on ${mission!.title}',
          risk: 'May reduce time available for other active priorities.',
          confidence: (priority.confidence * 100).round(),
          suggestedAction: 'Plan one focused session for ${priority.title}.',
          targetType: priority.skillId == null ? 'Mission' : 'Skill',
          targetId: priority.skillId ?? mission.id,
          evidenceIds: verifiedEvidence
              .map((evidence) => evidence.id)
              .take(5)
              .toList(),
        ),
      for (final assumption in changedAssumptions)
        StructuredRecommendation(
          type: 'Assumption',
          title: 'Review ${assumption.title}',
          reason:
              'The assumption is marked ${assumption.text('status')} at ${assumption.number('confidence')}% confidence.',
          factBasis: assumption.text('evidence_context'),
          inference: 'The current strategy may depend on a weakening premise.',
          expectedBenefit:
              'Avoid allocating future work using an outdated premise.',
          risk:
              'Changing direction from limited evidence may create unnecessary churn.',
          confidence: (100 - assumption.number('confidence')).clamp(35, 90),
          suggestedAction:
              'Inspect the evidence and decide whether strategy should change.',
          targetType: 'Assumption',
          targetId: assumption.id,
          evidenceIds: verifiedEvidence
              .map((evidence) => evidence.id)
              .take(5)
              .toList(),
        ),
    ];
    if (type == 'Annual' && mission != null) {
      final allocations = workspace
          .records('engine_allocations')
          .map(
            (allocation) =>
                '${allocation.text('engine')}=${allocation.text('mode')}',
          )
          .join(', ');
      recommendations.add(
        StructuredRecommendation(
          type: 'Strategy',
          title: 'Review the 1-year and 3-year engine roadmap',
          reason:
              'Annual review is the explicit point for testing the current thesis and engine allocation.',
          factBasis:
              '${mission.title} outcome attainment is ${(workspace.missionProgress(mission.id) * 100).round()}%. Engine allocation: ${allocations.isEmpty ? 'not recorded' : allocations}.',
          inference:
              'The next roadmap should preserve the strongest evidence while naming conditions for a future engine shift.',
          expectedBenefit:
              'A clear 1-year operating focus and a conditional 3-year direction.',
          risk:
              'Long-range options have high uncertainty and should not rewrite active strategy automatically.',
          confidence: 55,
          suggestedAction:
              'Write one 1-year committed roadmap and two 3-year options with evidence thresholds.',
          targetType: 'Mission',
          targetId: mission.id,
          evidenceIds: verifiedEvidence.map((evidence) => evidence.id).toList(),
        ),
      );
    }
    final progress = mission == null
        ? null
        : (workspace.missionProgress(mission.id) * 100).round();
    final periodDetail = type == 'Quarterly'
        ? 'Quarterly aggregate: ${(focusedSeconds / 3600).toStringAsFixed(1)} focused hours; ${jobs.length} jobs, ${applications.length} applications and ${interviews.length} interviews; ${discoveries.length} customer discoveries and ${revenue.toStringAsFixed(2)} revenue.'
        : type == 'Annual'
        ? 'Annual thesis review: ${changedAssumptions.length} assumptions require attention; ${workspace.records('engine_allocations').length} engine allocations are recorded.'
        : type == 'EventDriven'
        ? 'Event review: ${openEventIds.length} unreviewed material events affect ${eventAffectedAssumptions.length} linked assumptions.'
        : '';
    final roadmapPriorities = type == 'Annual' && mission != null
        ? [
            '1-year roadmap: concentrate evidence-producing work on ${mission.title}.',
            '3-year options: define conditions for Career, Ownership and Capital allocation changes.',
          ]
        : const <String>[];
    return AdaptiveReviewDraft(
      type: type,
      periodStart: periodStart,
      periodEnd: periodEnd,
      summary:
          '${mission == null ? 'No active mission' : '${mission.title} is at $progress% weighted outcome attainment'}. '
          '$completed of ${sessions.length} planned sessions completed; ${outputs.length} outputs and ${verifiedEvidence.length} verified assessments recorded. $periodDetail',
      wins: wins,
      problems: problems,
      evidenceIds: verifiedEvidence.map((evidence) => evidence.id).toList(),
      changedAssumptionIds: changedAssumptions
          .map((assumption) => assumption.id)
          .toList(),
      carryForward: missed.map((session) => session.title).toList(),
      nextPriorities: [
        ...priorities.map((priority) => priority.title),
        ...roadmapPriorities,
      ],
      recommendations: recommendations,
    );
  }

  @override
  List<double> embed(String text, {int dimensions = 96}) {
    if (dimensions < 8) throw ArgumentError('Use at least 8 dimensions.');
    final vector = List<double>.filled(dimensions, 0);
    final words = text
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map((word) => word.replaceAll(RegExp(r'[,;:!?()\[\]{}"“”]'), ''))
        .where((word) => word.length > 1);
    for (final word in words) {
      for (final term in {word, _canonical(word)}) {
        var hash = 0x811c9dc5;
        for (final unit in term.codeUnits) {
          hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
        }
        vector[hash % dimensions] += hash.isEven ? 1 : -1;
      }
    }
    final magnitude = vector.fold(0.0, (sum, value) => sum + value * value);
    if (magnitude == 0) return vector;
    final scale = 1 / _sqrt(magnitude);
    return vector.map((value) => value * scale).toList(growable: false);
  }

  String _canonical(String word) => switch (word) {
    'mutex' ||
    'lock' ||
    'locking' ||
    'synchronization' ||
    'race-condition' ||
    'race' => 'concurrency',
    'ipc' || 'shared-memory' || 'pipe' || 'socket' => 'interprocess',
    'ownership' || 'shared_ptr' || 'unique_ptr' => 'memory-management',
    'debug' || 'debugging' || 'diagnosis' || 'rca' => 'troubleshooting',
    'interview' || 'screening' || 'hiring' => 'career-assessment',
    'revenue' || 'customer' || 'sales' || 'paid' => 'market-validation',
    _ => word,
  };

  double _sqrt(double value) {
    var estimate = value > 1 ? value : 1.0;
    for (var index = 0; index < 16; index++) {
      estimate = (estimate + value / estimate) / 2;
    }
    return estimate;
  }
}
