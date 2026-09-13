import 'dart:convert';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import '../database/schema.dart';
import '../domain/career.dart';
import '../domain/intelligence.dart';
import '../domain/models.dart';
import '../domain/repository.dart';
import 'seed.dart';

class SqliteWorkspaceRepository implements WorkspaceRepository {
  final Database db;
  SqliteWorkspaceRepository._(this.db);
  static Future<SqliteWorkspaceRepository> open(
    String path, {
    bool demo = true,
  }) async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await migrate(db, 0, version);
          if (demo) await seedDemo(db, DateTime.now());
        },
        onUpgrade: migrate,
      ),
    );
    return SqliteWorkspaceRepository._(db);
  }

  static const tables = [
    ...strategyTables,
    'life_areas',
    'goals',
    'projects',
    'milestones',
    'sessions',
    'tasks',
    'outputs',
    'knowledge',
    'inbox',
    'weekly_reviews',
    'settings',
  ];
  static const strategyTables = [
    'visions',
    'horizons',
    'strategies',
    'missions',
    'outcomes',
    'initiatives',
    'skills',
    'evidence',
    'evidence_links',
    'assumptions',
    'strategy_versions',
    'strategy_proposals',
    'recommendations',
    'recommendation_evidence',
    'recommendation_targets',
    'review_decisions',
    'recommendation_decisions',
    'review_evidence',
    'period_reviews',
    'metrics',
    'metric_snapshots',
    'readiness_weights',
    'knowledge_sections',
    'knowledge_links',
    'concepts',
    'knowledge_concepts',
    'knowledge_embeddings',
    'knowledge_search_events',
    'context_sharing_audit',
    'planning_change_sets',
    'planning_changes',
    'strategy_events',
    'event_assumptions',
    'engine_allocations',
    'customer_discoveries',
    'revenue_entries',
    'distribution_events',
    'capital_contributions',
    'net_worth_snapshots',
    'jobs',
    'job_requirements',
    'applications',
    'interviews',
    'interview_questions',
    'learning_priorities',
    'experiments',
    'session_templates',
    'recurring_schedules',
  ];
  @override
  Future<Workspace> load() async {
    final now = DateTime.now();
    await db.transaction((tx) async {
      await _materializeRecurringSessions(
        tx,
        now,
        now.add(const Duration(days: 21)),
      );
      final missingKnowledgeIndexes = await tx.rawQuery('''
        SELECT knowledge.id
        FROM knowledge
        LEFT JOIN knowledge_embeddings
          ON knowledge_embeddings.knowledge_id = knowledge.id
        WHERE knowledge_embeddings.knowledge_id IS NULL
           OR NOT EXISTS (
             SELECT 1 FROM knowledge_sections
             WHERE knowledge_sections.knowledge_id = knowledge.id
           )
      ''');
      for (final row in missingKnowledgeIndexes) {
        await _rebuildKnowledgeStructure(tx, row['id'] as String);
      }
    });
    return db.transaction(
      (tx) async => Workspace(
        strategyData: {
          for (final table in strategyTables)
            table: (await tx.query(table)).map(StrategyRecord.new).toList(),
        },
        areas: (await tx.query('life_areas')).map(LifeArea.new).toList(),
        goals: (await tx.query('goals')).map(Goal.new).toList(),
        projects: (await tx.query('projects')).map(Project.new).toList(),
        milestones: (await tx.query('milestones')).map(Milestone.new).toList(),
        sessions: (await tx.query(
          'sessions',
          orderBy: 'planned_start',
        )).map(Session.new).toList(),
        tasks: (await tx.query('tasks')).map(WorkTask.new).toList(),
        outputs: (await tx.query(
          'outputs',
          orderBy: 'created_at DESC',
        )).map(Output.new).toList(),
        knowledge: (await tx.query(
          'knowledge',
          orderBy: 'updated_at DESC',
        )).map(KnowledgeItem.new).toList(),
        inbox: (await tx.query(
          'inbox',
          orderBy: 'created_at DESC',
        )).map(InboxItem.new).toList(),
        reviews: (await tx.query(
          'weekly_reviews',
        )).map(WeeklyReview.new).toList(),
        intervals: (await tx.query(
          'focus_intervals',
        )).map(FocusInterval.new).toList(),
        settings: {
          for (final r in await tx.query('settings'))
            r['key'] as String: r['value'] as String,
        },
      ),
    );
  }

  Future<void> _validateLinks(
    DatabaseExecutor tx,
    String table,
    DataRowMap row,
  ) async {
    if (table == 'recurring_schedules') {
      final weekdays = (row['weekdays'] as String? ?? '')
          .split(',')
          .map((value) => int.tryParse(value.trim()))
          .toList();
      if (weekdays.isEmpty ||
          weekdays.any((value) => value == null || value < 1 || value > 7)) {
        throw ArgumentError('Weekdays must be comma-separated values 1–7.');
      }
      if (!RegExp(
        r'^(?:[01]\d|2[0-3]):[0-5]\d$',
      ).hasMatch(row['local_time'] as String? ?? '')) {
        throw ArgumentError('Local time must use HH:mm in 24-hour time.');
      }
      final start = row['start_date'] as String? ?? '';
      final end = row['end_date'] as String? ?? '';
      if ((start.isNotEmpty && DateTime.tryParse(start) == null) ||
          (end.isNotEmpty && DateTime.tryParse(end) == null) ||
          (start.isNotEmpty && end.isNotEmpty && start.compareTo(end) > 0)) {
        throw ArgumentError('Choose a valid recurrence date range.');
      }
    }
    if (table == 'projects' && row['outcome_id'] != null) {
      final outcomes = await tx.query(
        'outcomes',
        where: 'id = ?',
        whereArgs: [row['outcome_id']],
      );
      if (outcomes.isEmpty) throw StateError('Mission outcome not found.');
      if (row['goal_id'] != null) {
        final missions = await tx.query(
          'missions',
          where: 'id = ?',
          whereArgs: [outcomes.single['mission_id']],
        );
        if (missions.isEmpty || missions.single['goal_id'] != row['goal_id']) {
          throw StateError(
            'Project goal and outcome must belong to the same mission path.',
          );
        }
      }
    }
    if (table == 'projects' && row['initiative_id'] != null) {
      final initiatives = await tx.query(
        'initiatives',
        where: 'id = ?',
        whereArgs: [row['initiative_id']],
      );
      if (initiatives.isEmpty) throw StateError('Initiative not found.');
      final initiative = initiatives.single;
      if (row['outcome_id'] != null &&
          initiative['outcome_id'] != null &&
          row['outcome_id'] != initiative['outcome_id']) {
        throw StateError('Project outcome must match its initiative outcome.');
      }
      if (row['goal_id'] != null) {
        final missions = await tx.query(
          'missions',
          where: 'id = ?',
          whereArgs: [initiative['mission_id']],
        );
        if (missions.isEmpty || missions.single['goal_id'] != row['goal_id']) {
          throw StateError(
            'Project goal and initiative must belong to the same mission path.',
          );
        }
      }
    }
    if (table == 'initiatives' && row['outcome_id'] != null) {
      final outcomes = await tx.query(
        'outcomes',
        where: 'id = ?',
        whereArgs: [row['outcome_id']],
      );
      if (outcomes.isEmpty ||
          outcomes.single['mission_id'] != row['mission_id']) {
        throw StateError('Initiative outcome must belong to its mission.');
      }
    }
    if (['sessions', 'session_templates'].contains(table) &&
        row['milestone_id'] != null) {
      final milestones = await tx.query(
        'milestones',
        where: 'id = ?',
        whereArgs: [row['milestone_id']],
      );
      if (milestones.isEmpty ||
          milestones.single['project_id'] != row['project_id']) {
        throw StateError(
          'Choose a milestone belonging to this session’s project.',
        );
      }
    }
    if (table == 'sessions' && row['task_id'] != null) {
      final tasks = await tx.query(
        'tasks',
        where: 'id = ?',
        whereArgs: [row['task_id']],
      );
      if (tasks.isEmpty || tasks.single['project_id'] != row['project_id']) {
        throw StateError('Choose a task belonging to this session’s project.');
      }
    }
    if (table == 'milestones') {
      final linked = await tx.query(
        'sessions',
        where: 'milestone_id = ?',
        whereArgs: [row['id']],
      );
      if (linked.any((s) => s['project_id'] != row['project_id'])) {
        throw StateError(
          'This milestone is linked to sessions. Keep it in its original project.',
        );
      }
    }
    if (['outputs', 'knowledge'].contains(table) && row['session_id'] != null) {
      final source = await _session(tx, row['session_id'] as String);
      if (source.projectId != row['project_id'] ||
          (table == 'knowledge' && source.goalId != row['goal_id'])) {
        throw StateError(
          'Evidence keeps the project and goal of its source session.',
        );
      }
    }
  }

  Future<void> _save(DatabaseExecutor tx, String table, DataRowMap row) async {
    if (!tables.contains(table)) throw ArgumentError('Unknown record type');
    final key = table == 'settings' ? 'key' : 'id';
    final existing = await tx.query(
      table,

      where: '$key = ?',
      whereArgs: [row[key]],
    );
    await _validateLinks(tx, table, {...?existing.firstOrNull, ...row});
    if (existing.isEmpty) {
      await tx.insert(table, row);
    } else {
      await tx.update(table, row, where: '$key = ?', whereArgs: [row[key]]);
    }
  }

  @override
  Future<void> save(String table, DataRowMap row) => db.transaction((tx) async {
    if (table == 'tasks') {
      final existing = await tx.query(
        table,
        where: 'id = ?',
        whereArgs: [row['id']],
      );
      final merged = {...?existing.firstOrNull, ...row};
      row = {...row, 'done': merged['status'] == 'Done' ? 1 : 0};
    }
    if (table == 'sessions') {
      final existing = await tx.query(
        table,
        where: 'id = ?',
        whereArgs: [row['id']],
      );
      if (existing.isNotEmpty &&
          row['status'] != null &&
          row['status'] != existing.first['status']) {
        throw StateError('Use session commands to change status.');
      }
      if (existing.isEmpty &&
          row['status'] != null &&
          row['status'] != 'PLANNED') {
        throw StateError('New sessions must be planned.');
      }
    }
    if (table == 'evidence' &&
        (await tx.query(
          table,
          where: 'id = ?',
          whereArgs: [row['id']],
        )).isNotEmpty) {
      throw StateError('Create a new assessment to preserve evidence history.');
    }
    if (table == 'interview_questions') {
      final existing = await tx.query(
        table,
        where: 'id = ?',
        whereArgs: [row['id']],
      );
      if (existing.isNotEmpty && existing.single['converted_at'] != null) {
        throw StateError(
          'A question already converted to a priority is immutable.',
        );
      }
    }
    if (table == 'strategy_versions') {
      throw StateError('Strategy history is immutable.');
    }
    if (table == 'recommendations') {
      final existing = await tx.query(
        table,
        where: 'id = ?',
        whereArgs: [row['id']],
      );
      if (existing.isEmpty &&
          row['status'] != null &&
          row['status'] != 'Proposed') {
        throw StateError('New recommendations must be proposed first.');
      }
      if (existing.isNotEmpty) {
        final before = existing.single;
        final oldStatus = before['status'] as String;
        final nextStatus = row['status'] as String? ?? oldStatus;
        final allowed = oldStatus == 'Proposed'
            ? {'Proposed', 'Accepted', 'Modified', 'Rejected', 'Expired'}
            : oldStatus == 'Accepted'
            ? {'Accepted', 'Applied'}
            : {oldStatus};
        if (!allowed.contains(nextStatus)) {
          throw StateError('This recommendation decision is immutable.');
        }
        if (oldStatus != 'Proposed') {
          final changedContent = row.entries.any(
            (entry) =>
                !{'id', 'status', 'decided_at'}.contains(entry.key) &&
                before[entry.key] != entry.value,
          );
          if (changedContent) {
            throw StateError('Decided recommendation content is immutable.');
          }
        }
        if (nextStatus != oldStatus && nextStatus != 'Proposed') {
          final decidedAt = DateTime.now().millisecondsSinceEpoch;
          row = {...row, 'decided_at': decidedAt};
          await _recordRecommendationDecision(
            tx,
            before,
            nextStatus,
            decidedAt,
          );
        }
      }
    }
    if (table == 'recurring_schedules' || table == 'session_templates') {
      final occurrenceDate = _isoDate(DateTime.now());
      if (table == 'recurring_schedules') {
        await tx.delete(
          'sessions',
          where:
              "recurring_schedule_id = ? AND occurrence_date >= ? AND status = 'PLANNED'",
          whereArgs: [row['id'], occurrenceDate],
        );
      } else {
        final schedules = await tx.query(
          'recurring_schedules',
          columns: ['id'],
          where: 'template_id = ?',
          whereArgs: [row['id']],
        );
        for (final schedule in schedules) {
          await tx.delete(
            'sessions',
            where:
                "recurring_schedule_id = ? AND occurrence_date >= ? AND status = 'PLANNED'",
            whereArgs: [schedule['id'], occurrenceDate],
          );
        }
      }
    }
    if (table == 'strategies') {
      final old = await tx.query(
        table,
        where: 'id = ?',
        whereArgs: [row['id']],
      );
      if (old.isNotEmpty) {
        throw StateError('Propose and approve a strategy change.');
      }
    }
    if (table == 'strategy_proposals') {
      final old = await tx.query(
        table,
        where: 'id = ?',
        whereArgs: [row['id']],
      );
      if (old.isEmpty && row['status'] != null && row['status'] != 'Pending') {
        throw StateError('New proposals must be pending.');
      }
      if (old.isNotEmpty) {
        if (old.single['status'] != 'Pending') {
          throw StateError('This proposal was already decided.');
        }
        if (row['status'] == 'Accepted') {
          final proposal = {...old.single, ...row};
          final strategy = (await tx.query(
            'strategies',
            where: 'id = ?',
            whereArgs: [proposal['strategy_id']],
          )).single;
          final updated = {
            ...strategy,
            'title': proposal['title'],
            'description': proposal['description'],
            if (proposal['engine'] != 'Unchanged') 'engine': proposal['engine'],
            if (proposal['allocation'] != 'Unchanged')
              'allocation': proposal['allocation'],
          };
          final versions = await tx.query(
            'strategy_versions',
            where: 'strategy_id = ?',
            whereArgs: [strategy['id']],
            orderBy: 'version_number DESC',
          );
          String? previousVersionId;
          var nextVersion = 1;
          if (versions.isEmpty) {
            previousVersionId = newId();
            await tx.insert('strategy_versions', {
              'id': previousVersionId,
              'strategy_id': strategy['id'],
              'title': strategy['title'],
              'snapshot_json': jsonEncode(strategy),
              'change_reason': 'Initial recorded strategy',
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'version_number': nextVersion,
            });
            nextVersion++;
          } else {
            previousVersionId = versions.first['id'] as String;
            nextVersion = (versions.first['version_number'] as int) + 1;
          }
          await tx.insert('strategy_versions', {
            'id': newId(),
            'strategy_id': strategy['id'],
            'title': updated['title'],
            'snapshot_json': jsonEncode(updated),
            'change_reason': proposal['reason'],
            'created_at': DateTime.now().millisecondsSinceEpoch,
            'version_number': nextVersion,
            'previous_version_id': previousVersionId,
          });
          await tx.update(
            'strategies',
            updated,
            where: 'id = ?',
            whereArgs: [strategy['id']],
          );
        }
      }
    }
    await _save(tx, table, row);
    if (table == 'knowledge') {
      await _rebuildKnowledgeStructure(tx, row['id'] as String);
    }
    if (table == 'strategy_events') {
      await _linkEventAssumptions(tx, row['id'] as String);
    }
  });

  Future<void> _linkEventAssumptions(
    DatabaseExecutor tx,
    String eventId,
  ) async {
    final events = await tx.query(
      'strategy_events',
      where: 'id = ?',
      whereArgs: [eventId],
    );
    if (events.isEmpty) return;
    final event = events.single;
    final eventTerms = _meaningfulTerms(
      '${event['title']} ${event['description']} ${event['impact']}',
    );
    await tx.delete(
      'event_assumptions',
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
    for (final assumption in await tx.query('assumptions')) {
      final assumptionTerms = _meaningfulTerms(
        '${assumption['title']} ${assumption['evidence_context']}',
      );
      final overlap = eventTerms.intersection(assumptionTerms).length;
      final strategicallyWeak = [
        'Weakening',
        'Invalidated',
      ].contains(assumption['status']);
      if (overlap == 0 && !strategicallyWeak) continue;
      await tx.insert('event_assumptions', {
        'event_id': eventId,
        'assumption_id': assumption['id'],
        'relationship': strategicallyWeak ? 'ReinforcesConcern' : 'MayAffect',
        'confidence': strategicallyWeak
            ? 80
            : (45 + overlap * 15).clamp(45, 90),
      });
    }
  }

  Set<String> _meaningfulTerms(String text) => text
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9+#]+'))
      .where((term) => term.length >= 4)
      .where(
        (term) =>
            !{'this', 'that', 'with', 'from', 'have', 'will'}.contains(term),
      )
      .toSet();

  Future<void> _recordRecommendationDecision(
    DatabaseExecutor tx,
    DataRowMap recommendation,
    String status,
    int decidedAt,
  ) async {
    final recommendationId = recommendation['id'] as String;
    final decision = switch (status) {
      'Accepted' => 'Accepted',
      'Modified' => 'Modified',
      'Rejected' || 'Expired' => 'Rejected',
      _ => null,
    };
    if (decision != null) {
      await tx.insert('recommendation_decisions', {
        'id': newId(),
        'recommendation_id': recommendationId,
        'decision': decision,
        'rationale': recommendation['reason'] ?? '',
        'created_at': decidedAt,
      });
      final reviews = await tx.query('period_reviews');
      for (final review in reviews) {
        List<String> ids;
        try {
          ids = (jsonDecode(review['recommendations_json'] as String) as List)
              .map((value) => value.toString())
              .toList();
        } catch (_) {
          continue;
        }
        if (!ids.contains(recommendationId)) continue;
        await tx.insert('review_decisions', {
          'id': newId(),
          'review_id': review['id'],
          'review_type': review['type'],
          'recommendation_id': recommendationId,
          'decision': decision,
          'rationale': recommendation['reason'] ?? '',
          'created_at': decidedAt,
        });
        final recorded = <Object?>[
          ...((jsonDecode(review['user_decisions_json'] as String) as List)),
          {
            'recommendation_id': recommendationId,
            'decision': decision,
            'decided_at': decidedAt,
          },
        ];
        await tx.update(
          'period_reviews',
          {'user_decisions_json': jsonEncode(recorded)},
          where: 'id = ?',
          whereArgs: [review['id']],
        );
      }
    }
    if (status != 'Accepted' || recommendation['type'] != 'Planning') return;
    final existing = await tx.query(
      'planning_change_sets',
      where: 'recommendation_id = ?',
      whereArgs: [recommendationId],
    );
    if (existing.isNotEmpty) return;
    final targets = await tx.query(
      'recommendation_targets',
      where: 'recommendation_id = ?',
      whereArgs: [recommendationId],
    );
    String? projectId;
    String? goalId;
    String? missionId;
    final target = targets.firstOrNull;
    if (target?['entity_type'] == 'Mission') {
      missionId = target!['entity_id'] as String;
    } else if (target?['entity_type'] == 'Skill') {
      final skills = await tx.query(
        'skills',
        where: 'id = ?',
        whereArgs: [target!['entity_id']],
      );
      missionId = skills.firstOrNull?['mission_id'] as String?;
    }
    if (missionId != null) {
      final missions = await tx.query(
        'missions',
        where: 'id = ?',
        whereArgs: [missionId],
      );
      goalId = missions.firstOrNull?['goal_id'] as String?;
      final projects = await tx.rawQuery(
        '''
        SELECT projects.id
        FROM projects
        LEFT JOIN initiatives ON initiatives.id = projects.initiative_id
        LEFT JOIN outcomes ON outcomes.id = projects.outcome_id
        WHERE projects.status = 'active'
          AND (initiatives.mission_id = ? OR outcomes.mission_id = ? OR projects.goal_id = ?)
        ORDER BY projects.priority, projects.created_at
        LIMIT 1
        ''',
        [missionId, missionId, goalId],
      );
      projectId = projects.firstOrNull?['id'] as String?;
      if (projectId != null) goalId = null;
    }
    final now = DateTime.fromMillisecondsSinceEpoch(decidedAt);
    final daysUntilMonday = 8 - now.weekday;
    final nextMonday = DateTime(
      now.year,
      now.month,
      now.day + daysUntilMonday,
      21,
    );
    final setId = newId();
    await tx.insert('planning_change_sets', {
      'id': setId,
      'recommendation_id': recommendationId,
      'title': recommendation['title'],
      'status': 'Draft',
      'created_at': decidedAt,
    });
    await tx.insert('planning_changes', {
      'id': newId(),
      'change_set_id': setId,
      'action': 'CreateSession',
      'payload_json': jsonEncode({
        'id': newId(),
        'title': recommendation['title'],
        'project_id': projectId,
        'goal_id': goalId,
        'why': recommendation['reason'],
        'target': recommendation['suggested_action'],
        'priority': 2,
        'planned_start': nextMonday.millisecondsSinceEpoch,
        'planned_minutes': 60,
        'created_at': decidedAt,
      }),
      'status': 'Proposed',
      'created_at': decidedAt,
    });
  }

  Future<void> _rebuildKnowledgeStructure(
    DatabaseExecutor tx,
    String knowledgeId,
  ) async {
    final rows = await tx.query(
      'knowledge',
      where: 'id = ?',
      whereArgs: [knowledgeId],
    );
    if (rows.isEmpty) return;
    final item = rows.single;
    final content = item['content'] as String? ?? '';
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final embeddingSource = [
      item['title'],
      item['summary'],
      content,
      item['tags'],
    ].whereType<String>().join('\n');
    final embedding = const LocalIntelligenceProvider().embed(embeddingSource);
    await tx.insert('knowledge_embeddings', {
      'knowledge_id': knowledgeId,
      'model': 'local-hash-v1',
      'dimensions': embedding.length,
      'vector_json': jsonEncode(embedding),
      'content_checksum': jobDescriptionFingerprint(embeddingSource),
      'updated_at': stamp,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await tx.delete(
      'knowledge_sections',
      where: 'knowledge_id = ?',
      whereArgs: [knowledgeId],
    );
    for (final section in _sections(content, item['title'] as String? ?? '')) {
      await tx.insert('knowledge_sections', {
        'id': newId(),
        'knowledge_id': knowledgeId,
        'ordinal': section.ordinal,
        'title': section.title,
        'content': section.content,
        'start_offset': section.start,
        'end_offset': section.end,
        'created_at': stamp,
      });
    }

    for (final relation in [
      ('Skill', item['skill_id']),
      ('Project', item['project_id']),
      ('Mission', item['mission_id']),
      ('Session', item['session_id']),
    ]) {
      if (relation.$2 == null) continue;
      await tx.insert('knowledge_links', {
        'id': newId(),
        'knowledge_id': knowledgeId,
        'entity_type': relation.$1,
        'entity_id': relation.$2,
        'relationship': 'Related',
        'confidence': 100,
        'suggested': 0,
        'created_at': stamp,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    await tx.delete(
      'knowledge_links',
      where: 'knowledge_id = ? AND suggested = 1',
      whereArgs: [knowledgeId],
    );
    await tx.delete(
      'knowledge_links',
      where: "entity_type = 'Knowledge' AND entity_id = ? AND suggested = 1",
      whereArgs: [knowledgeId],
    );

    await tx.delete(
      'knowledge_concepts',
      where: 'knowledge_id = ?',
      whereArgs: [knowledgeId],
    );
    final tags = (item['tags'] as String? ?? '')
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet();
    for (final tag in tags) {
      final existing = await tx.query(
        'concepts',
        where: 'title = ? COLLATE NOCASE',
        whereArgs: [tag],
      );
      final conceptId = existing.isEmpty ? newId() : existing.single['id'];
      if (existing.isEmpty) {
        await tx.insert('concepts', {
          'id': conceptId,
          'title': tag,
          'created_at': stamp,
        });
      }
      final related = await tx.query(
        'knowledge_concepts',
        columns: ['knowledge_id'],
        where: 'concept_id = ? AND knowledge_id != ?',
        whereArgs: [conceptId, knowledgeId],
      );
      await tx.insert('knowledge_concepts', {
        'knowledge_id': knowledgeId,
        'concept_id': conceptId,
        'relationship': 'Tagged',
        'confidence': 100,
        'created_at': stamp,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      for (final other in related) {
        final otherId = other['knowledge_id'] as String;
        for (final link in [(knowledgeId, otherId), (otherId, knowledgeId)]) {
          await tx.insert('knowledge_links', {
            'id': newId(),
            'knowledge_id': link.$1,
            'entity_type': 'Knowledge',
            'entity_id': link.$2,
            'relationship': 'SharedConcept:$tag',
            'confidence': 65,
            'suggested': 1,
            'created_at': stamp,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
    }
  }

  List<({int ordinal, String title, String content, int start, int end})>
  _sections(String content, String fallbackTitle) {
    if (content.trim().isEmpty) return const [];
    final headings = RegExp(
      r'^#{1,6}\s+(.+)$',
      multiLine: true,
    ).allMatches(content).toList();
    if (headings.isEmpty) {
      return [
        (
          ordinal: 0,
          title: fallbackTitle,
          content: content,
          start: 0,
          end: content.length,
        ),
      ];
    }
    final sections =
        <({int ordinal, String title, String content, int start, int end})>[];
    if (headings.first.start > 0 &&
        content.substring(0, headings.first.start).trim().isNotEmpty) {
      sections.add((
        ordinal: sections.length,
        title: fallbackTitle,
        content: content.substring(0, headings.first.start).trim(),
        start: 0,
        end: headings.first.start,
      ));
    }
    for (var index = 0; index < headings.length; index++) {
      final match = headings[index];
      final start = match.start;
      final end = index + 1 < headings.length
          ? headings[index + 1].start
          : content.length;
      sections.add((
        ordinal: sections.length,
        title: match.group(1)!.trim(),
        content: content.substring(match.end, end).trim(),
        start: start,
        end: end,
      ));
    }
    return sections;
  }

  Future<Session> _session(DatabaseExecutor tx, String id) async {
    final rows = await tx.query('sessions', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) throw StateError('Session no longer exists.');
    return Session(rows.single);
  }

  @override
  Future<void> startSession(String id, DateTime now) => db.transaction((
    tx,
  ) async {
    final s = await _session(tx, id);
    if (!s.status.canTransitionTo(SessionStatus.active)) {
      throw StateError('This session cannot be started.');
    }
    if ((await tx.query('sessions', where: "status = 'ACTIVE'")).isNotEmpty) {
      throw StateError('Finish or pause the active session first.');
    }
    await tx.update(
      'sessions',
      {
        'status': 'ACTIVE',
        'blocked': 0,
        'blocked_reason': '',
        'actual_start': s.data['actual_start'] ?? now.millisecondsSinceEpoch,
        'segment_start': now.millisecondsSinceEpoch,
        'actual_end': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  });
  @override
  Future<void> reviewSession(
    String id,
    SessionStatus status,
    DateTime now, {
    String output = '',
    String learning = '',
    String nextAction = '',
    String link = '',
    int? correctedSeconds,
  }) => db.transaction((tx) async {
    final s = await _session(tx, id);
    if (!s.status.canTransitionTo(status) || status == SessionStatus.active) {
      throw StateError(
        'This review has already been saved or the transition is invalid.',
      );
    }
    if (correctedSeconds != null && correctedSeconds < 0) {
      throw ArgumentError('Duration cannot be negative.');
    }
    if (status == SessionStatus.blocked && nextAction.trim().isEmpty) {
      throw ArgumentError('Describe the blocker or next action.');
    }
    final stamp = now.millisecondsSinceEpoch;
    var total = s.elapsedSeconds(now);
    if (s.segmentStart != null && now.isBefore(s.segmentStart!)) {
      throw StateError(
        'System clock moved backwards. Correct the clock before saving.',
      );
    }
    if (correctedSeconds != null) {
      total = correctedSeconds;
      await tx.delete(
        'focus_intervals',
        where: 'session_id = ?',
        whereArgs: [id],
      );
      await tx.insert('focus_intervals', {
        'id': newId(),
        'session_id': id,
        'start_at': stamp,
        'end_at': stamp,
        'seconds': total,
      });
    } else if (s.segmentStart != null) {
      await tx.insert('focus_intervals', {
        'id': newId(),
        'session_id': id,
        'start_at': s.segmentStart!.millisecondsSinceEpoch,
        'end_at': stamp,
        'seconds': now.difference(s.segmentStart!).inSeconds,
      });
    }
    await tx.update(
      'sessions',
      {
        'status': status == SessionStatus.blocked
            ? SessionStatus.inProgress.value
            : status.value,
        'blocked': status == SessionStatus.blocked ? 1 : 0,
        'blocked_reason': status == SessionStatus.blocked
            ? nextAction.trim()
            : '',
        'actual_start':
            s.data['actual_start'] ??
            ((status == SessionStatus.done ||
                    status == SessionStatus.inProgress ||
                    status == SessionStatus.blocked)
                ? stamp
                : null),
        'actual_end': stamp,
        'actual_seconds': total,
        'segment_start': null,
        'next_action': nextAction.trim(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    if (output.trim().isNotEmpty) {
      await tx.insert('outputs', {
        'id': newId(),
        'title': '${s.title} — output',
        'type': 'Artifact',
        'description': output.trim(),
        'project_id': s.projectId,
        'session_id': id,
        'link': link.trim(),
        'created_at': stamp,
      });
    }
    if (learning.trim().isNotEmpty) {
      await tx.insert('knowledge', {
        'id': newId(),
        'title': '${s.title} — learning',
        'type': 'Learning',
        'content': learning.trim(),
        'project_id': s.projectId,
        'goal_id': s.goalId,
        'session_id': id,
        'created_at': stamp,
        'updated_at': stamp,
      });
    }
    if (s.projectId != null && nextAction.trim().isNotEmpty) {
      await tx.update(
        'projects',
        {'next_action': nextAction.trim()},
        where: 'id = ?',
        whereArgs: [s.projectId],
      );
    }
  });
  @override
  Future<void> reschedule(
    String id,
    DateTime start,
    int minutes,
  ) => db.transaction((tx) async {
    final s = await _session(tx, id);
    if (s.status != SessionStatus.planned &&
        s.status != SessionStatus.inProgress &&
        s.status != SessionStatus.blocked) {
      throw StateError(
        'Only planned, in-progress, or blocked sessions can be rescheduled.',
      );
    }
    if (minutes <= 0) throw ArgumentError('Choose a positive duration.');
    await tx.update(
      'sessions',
      {
        'planned_start': start.millisecondsSinceEpoch,
        'planned_minutes': minutes,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  });
  @override
  Future<void> triage(String inboxId, String destination, DataRowMap row) =>
      db.transaction((tx) async {
        if (![
          'goals',
          'projects',
          'sessions',
          'knowledge',
        ].contains(destination)) {
          throw ArgumentError('Unsupported destination.');
        }
        final items = await tx.query(
          'inbox',
          where: 'id = ? AND processed_at IS NULL',
          whereArgs: [inboxId],
        );
        if (items.isEmpty) {
          throw StateError('This capture has already been processed.');
        }
        await _validateLinks(tx, destination, row);
        await tx.insert(destination, row);
        await tx.update(
          'inbox',
          {'processed_at': DateTime.now().millisecondsSinceEpoch},
          where: 'id = ?',
          whereArgs: [inboxId],
        );
      });
  @override
  Future<void> clearDemo() => db.transaction((tx) async {
    if ((await tx.query(
      'settings',
      where: "key = 'demo' AND value = 'true'",
    )).isEmpty) {
      throw StateError('This workspace is no longer a demo.');
    }
    for (final table in [
      'review_evidence',
      'review_decisions',
      'recommendation_decisions',
      'event_assumptions',
      'net_worth_snapshots',
      'capital_contributions',
      'distribution_events',
      'revenue_entries',
      'customer_discoveries',
      'engine_allocations',
      'planning_changes',
      'planning_change_sets',
      'recommendation_evidence',
      'recommendation_targets',
      'metric_snapshots',
      'evidence_links',
      'knowledge_concepts',
      'knowledge_embeddings',
      'knowledge_search_events',
      'context_sharing_audit',
      'knowledge_links',
      'knowledge_sections',
      'learning_priorities',
      'interview_questions',
      'interviews',
      'applications',
      'job_requirements',
      'jobs',
      'experiments',
      'knowledge',
      'concepts',
      'evidence',
      'recommendations',
      'strategy_events',
      'metrics',
      'skills',
      'assumptions',
      'strategy_versions',
      'strategy_proposals',
      'period_reviews',
      'focus_intervals',
      'outputs',
      'sessions',
      'recurring_schedules',
      'session_templates',
      'tasks',
      'milestones',
      'projects',
      'initiatives',
      'outcomes',
      'missions',
      'strategies',
      'horizons',
      'visions',
      'goals',
      'life_areas',
      'inbox',
      'weekly_reviews',
    ]) {
      await tx.delete(table);
    }
    await tx.delete('readiness_weights');
    final stamp = DateTime.now().millisecondsSinceEpoch;
    for (final entry in readinessWeights.entries) {
      await tx.insert('readiness_weights', {
        'id': entry.key,
        'dimension': entry.key,
        'weight': entry.value,
        'updated_at': stamp,
      });
    }
    await _save(tx, 'settings', {'key': 'demo', 'value': 'false'});
    await seedAreas(tx);
  });
  @override
  Future<void> close() => db.close();

  @override
  Future<void> exportPortableJson(String path) async {
    final export = await db.transaction(
      (tx) async => <String, Object?>{
        'format': 'personal-os-portable-export',
        'schema_version': schemaVersion,
        'exported_at': DateTime.now().toUtc().toIso8601String(),
        'tables': {
          for (final table in {...tables, 'focus_intervals'})
            table: await tx.query(table),
        },
      },
    );
    await File(path).writeAsString(
      const JsonEncoder.withIndent('  ').convert(export),
      flush: true,
    );
  }

  @override
  Future<void> deleteDataCategory(String category) async {
    if (!{'Career', 'Knowledge', 'OwnershipCapital'}.contains(category)) {
      throw ArgumentError('Unknown data category.');
    }
    final managedFiles = category == 'Knowledge'
        ? (await db.query('knowledge', columns: ['managed_source_path']))
              .map((row) => row['managed_source_path'] as String? ?? '')
              .where((path) => path.isNotEmpty)
              .toList()
        : const <String>[];
    await db.transaction((tx) async {
      final categoryTables = switch (category) {
        'Career' => [
          'learning_priorities',
          'interview_questions',
          'interviews',
          'applications',
          'job_requirements',
          'jobs',
        ],
        'Knowledge' => [
          'knowledge_concepts',
          'knowledge_embeddings',
          'knowledge_links',
          'knowledge_sections',
          'knowledge',
          'concepts',
          'knowledge_search_events',
        ],
        _ => [
          'net_worth_snapshots',
          'capital_contributions',
          'distribution_events',
          'revenue_entries',
          'customer_discoveries',
          'engine_allocations',
          'experiments',
        ],
      };
      for (final table in categoryTables) {
        await tx.delete(table);
      }
    });
    if (category == 'Knowledge') {
      final managedRoot = p.normalize(
        p.join(p.dirname(db.path), 'personal_os_files'),
      );
      for (final path in managedFiles) {
        final normalized = p.normalize(path);
        if (!p.isWithin(managedRoot, normalized)) continue;
        final file = File(normalized);
        if (await file.exists()) await file.delete();
      }
    }
  }

  @override
  Future<void> backup(String path) async {
    await db.execute('VACUUM INTO ?', [path]);
  }

  @override
  Future<void> installStrategyTemplate(Map<String, List<DataRowMap>> records) =>
      db.transaction((tx) async {
        if ((await tx.query('visions')).isNotEmpty) {
          throw StateError(
            'Starter setup is available only before you create a vision.',
          );
        }
        for (final table in [
          'visions',
          'strategies',
          'goals',
          'missions',
          'skills',
        ]) {
          for (final row in records[table] ?? <DataRowMap>[]) {
            await tx.insert(table, row);
          }
        }
      });

  @override
  Future<int> importJobDescriptions(String missionId, String text) =>
      db.transaction((tx) async {
        final mission = await tx.query(
          'missions',
          where: 'id = ?',
          whereArgs: [missionId],
        );
        if (mission.isEmpty) throw StateError('Choose an existing mission.');
        final skills = (await tx.query(
          'skills',
          where: 'mission_id = ?',
          whereArgs: [missionId],
        )).map(StrategyRecord.new).toList();
        if (skills.isEmpty) {
          throw StateError(
            'Add mission skills before importing job descriptions.',
          );
        }
        final parsed = const JobDescriptionParser().parse(text, skills);
        final stamp = DateTime.now().millisecondsSinceEpoch;
        var inserted = 0;
        for (final job in parsed) {
          final jobId = newId();
          final rowId = await tx.insert('jobs', {
            'id': jobId,
            'mission_id': missionId,
            'title': job.title,
            'company': job.company,
            'location': job.location,
            'domain': job.domain,
            'seniority': job.seniority,
            'employment_type': job.employmentType,
            'source_url': job.sourceUrl,
            'salary_min': job.salaryMin,
            'salary_max': job.salaryMax,
            'currency': job.currency,
            'description': job.description,
            'fingerprint': jobDescriptionFingerprint(job.description),
            'imported_at': stamp,
            'created_at': stamp,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
          if (rowId == 0) continue;
          inserted++;
          for (final requirement in job.requirements) {
            await tx.insert('job_requirements', {
              'id': newId(),
              'job_id': jobId,
              'skill_id': requirement.skill.id,
              'skill_name': requirement.skill.title,
              'requirement_type': requirement.type,
              'years_required': requirement.yearsRequired,
              'source_excerpt': requirement.sourceExcerpt,
              'confidence': requirement.confidence,
              'created_at': stamp,
            });
          }
        }
        return inserted;
      });

  @override
  Future<void> convertInterviewQuestionToPriority(
    String questionId,
  ) => db.transaction((tx) async {
    final questions = await tx.query(
      'interview_questions',
      where: 'id = ?',
      whereArgs: [questionId],
    );
    if (questions.isEmpty) throw StateError('Interview question not found.');
    final question = questions.single;
    if (!['Fail', 'Partial'].contains(question['result'])) {
      throw StateError('Only failed or partial answers become priorities.');
    }
    if (question['converted_at'] != null) {
      throw StateError('This question is already a learning priority.');
    }
    final interview = (await tx.query(
      'interviews',
      where: 'id = ?',
      whereArgs: [question['interview_id']],
    )).single;
    final application = (await tx.query(
      'applications',
      where: 'id = ?',
      whereArgs: [interview['application_id']],
    )).single;
    final job = (await tx.query(
      'jobs',
      where: 'id = ?',
      whereArgs: [application['job_id']],
    )).single;
    final stamp = DateTime.now().millisecondsSinceEpoch;
    await tx.insert('learning_priorities', {
      'id': newId(),
      'mission_id': job['mission_id'],
      'skill_id': question['skill_id'],
      'source_question_id': questionId,
      'title': question['title'],
      'reason':
          'Interview answer was ${question['result']} for ${job['company']} ${job['title']}'
              .trim(),
      'created_at': stamp,
    });
    await tx.update(
      'interview_questions',
      {'converted_at': stamp},
      where: 'id = ?',
      whereArgs: [questionId],
    );
  });

  @override
  Future<int> generateRecurringSessions(DateTime through) => db.transaction(
    (tx) => _materializeRecurringSessions(tx, DateTime.now(), through),
  );

  @override
  Future<String> preserveKnowledgeSource(
    String sourcePath,
    String checksum,
  ) async {
    if (!RegExp(r'^[0-9a-f]{16}$').hasMatch(checksum)) {
      throw ArgumentError('Invalid document checksum.');
    }
    final source = File(sourcePath);
    if (!await source.exists()) throw ArgumentError('Source file not found.');
    final directory = Directory(
      p.join(p.dirname(db.path), 'personal_os_files'),
    );
    await directory.create(recursive: true);
    final extension = p.extension(sourcePath).toLowerCase();
    final destination = File(p.join(directory.path, '$checksum$extension'));
    if (!await destination.exists()) {
      await source.copy(destination.path);
    }
    return destination.path;
  }

  @override
  Future<List<KnowledgeSearchHit>> searchKnowledge(
    String query, {
    int limit = 40,
    List<double>? semanticVector,
  }) async {
    final stopwatch = Stopwatch()..start();
    final terms = query
        .trim()
        .split(RegExp(r'\s+'))
        .map((term) => term.replaceAll(RegExp(r'["*():^]'), ''))
        .where((term) => term.isNotEmpty)
        .take(12)
        .toList();
    if (terms.isEmpty) return const [];
    final expression = terms
        .map((term) => '"${term.replaceAll('"', '""')}"*')
        .join(' AND ');
    final rows = await db.rawQuery(
      '''
      SELECT knowledge.*,
             snippet(knowledge_fts, 2, '‹', '›', ' … ', 18) AS search_snippet,
             bm25(knowledge_fts, 5.0, 2.0, 1.0, 1.5) AS search_rank
      FROM knowledge_fts
      JOIN knowledge ON knowledge.rowid = knowledge_fts.rowid
      WHERE knowledge_fts MATCH ?
      ORDER BY search_rank
      LIMIT ?
      ''',
      [expression, limit.clamp(1, 100)],
    );
    final hits = <String, KnowledgeSearchHit>{};
    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      final data = Map<String, Object?>.from(row)
        ..remove('search_snippet')
        ..remove('search_rank');
      final item = KnowledgeItem(data);
      final section = await _bestKnowledgeSection(item.id, terms);
      hits[item.id] = KnowledgeSearchHit(
        item: KnowledgeItem(data),
        snippet: row['search_snippet'] as String? ?? '',
        rank: 2 - index / 1000,
        sectionTitle: section?['title'] as String?,
        startOffset: section?['start_offset'] as int?,
      );
    }
    if (semanticVector != null && semanticVector.isNotEmpty) {
      final embedded = await db.rawQuery(
        '''
        SELECT knowledge.*, knowledge_embeddings.vector_json
        FROM knowledge_embeddings
        JOIN knowledge ON knowledge.id = knowledge_embeddings.knowledge_id
        WHERE knowledge_embeddings.dimensions = ?
      ''',
        [semanticVector.length],
      );
      for (final row in embedded) {
        try {
          final vector = (jsonDecode(row['vector_json'] as String) as List)
              .map((value) => (value as num).toDouble())
              .toList();
          var similarity = 0.0;
          for (var index = 0; index < vector.length; index++) {
            similarity += vector[index] * semanticVector[index];
          }
          if (similarity < .12 && !hits.containsKey(row['id'])) continue;
          final data = Map<String, Object?>.from(row)..remove('vector_json');
          final item = KnowledgeItem(data);
          final section = await _bestKnowledgeSection(item.id, terms);
          final existing = hits[item.id];
          final preview = item.text('summary').isNotEmpty
              ? item.text('summary')
              : item.text('content');
          hits[item.id] = KnowledgeSearchHit(
            item: item,
            snippet:
                existing?.snippet ??
                (preview.length <= 180
                    ? preview
                    : '${preview.substring(0, 177)}…'),
            rank: (existing?.rank ?? 0) + similarity,
            relationship: existing == null
                ? 'Semantic similarity ${(similarity * 100).round()}% using local embedding'
                : 'Full-text match + semantic similarity ${(similarity * 100).round()}%',
            sectionTitle:
                existing?.sectionTitle ?? section?['title'] as String?,
            startOffset:
                existing?.startOffset ?? section?['start_offset'] as int?,
          );
        } catch (_) {
          continue;
        }
      }
    }
    final sorted = hits.values.toList()
      ..sort((first, second) => second.rank.compareTo(first.rank));
    final result = sorted.take(limit.clamp(1, 100)).toList();
    stopwatch.stop();
    await db.insert('knowledge_search_events', {
      'id': newId(),
      'query': query.trim(),
      'result_count': result.length,
      'top_score': result.firstOrNull?.rank,
      'duration_ms': stopwatch.elapsedMilliseconds,
      'searched_at': DateTime.now().millisecondsSinceEpoch,
    });
    return result;
  }

  Future<DataRowMap?> _bestKnowledgeSection(
    String knowledgeId,
    List<String> terms,
  ) async {
    final sections = await db.query(
      'knowledge_sections',
      where: 'knowledge_id = ?',
      whereArgs: [knowledgeId],
      orderBy: 'ordinal',
    );
    if (sections.isEmpty) return null;
    for (final section in sections) {
      final text = '${section['title']} ${section['content']}'.toLowerCase();
      if (terms.any((term) => text.contains(term.toLowerCase()))) {
        return Map<String, Object?>.from(section);
      }
    }
    return Map<String, Object?>.from(sections.first);
  }

  @override
  Future<void> updateReadinessWeights(Map<String, double> weights) async {
    final expected = readinessWeights.keys.toSet();
    if (weights.keys.toSet().difference(expected).isNotEmpty ||
        expected.difference(weights.keys.toSet()).isNotEmpty) {
      throw ArgumentError('Provide all six readiness dimensions.');
    }
    if (weights.values.any((weight) => !weight.isFinite || weight < 0)) {
      throw ArgumentError('Readiness weights must be zero or greater.');
    }
    final total = weights.values.fold(0.0, (sum, weight) => sum + weight);
    if (total <= 0) {
      throw ArgumentError(
        'At least one readiness weight must be greater than zero.',
      );
    }
    final stamp = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((tx) async {
      for (final entry in weights.entries) {
        await tx.insert('readiness_weights', {
          'id': entry.key,
          'dimension': entry.key,
          'weight': entry.value / total,
          'updated_at': stamp,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  @override
  Future<String> saveAdaptiveReview(AdaptiveReviewDraft draft) =>
      db.transaction((tx) async {
        final stamp = DateTime.now().millisecondsSinceEpoch;
        final reviewId = newId();
        final recommendationIds = <String>[];
        for (final recommendation in draft.recommendations) {
          final recommendationId = newId();
          recommendationIds.add(recommendationId);
          await tx.insert('recommendations', {
            'id': recommendationId,
            'type': recommendation.type,
            'title': recommendation.title,
            'reason': recommendation.reason,
            'fact_basis': recommendation.factBasis,
            'inference': recommendation.inference,
            'expected_benefit': recommendation.expectedBenefit,
            'risk': recommendation.risk,
            'confidence': recommendation.confidence,
            'suggested_action': recommendation.suggestedAction,
            'status': 'Proposed',
            'requires_user_approval': 1,
            'created_at': stamp,
          });
          for (final evidenceId in recommendation.evidenceIds.toSet()) {
            final exists = await tx.query(
              'evidence',
              columns: ['id'],
              where: 'id = ?',
              whereArgs: [evidenceId],
            );
            if (exists.isNotEmpty) {
              await tx.insert(
                'recommendation_evidence',
                {
                  'recommendation_id': recommendationId,
                  'evidence_id': evidenceId,
                },
                conflictAlgorithm: ConflictAlgorithm.ignore,
              );
            }
          }
          if (recommendation.targetType != null &&
              recommendation.targetId != null) {
            await tx.insert('recommendation_targets', {
              'id': newId(),
              'recommendation_id': recommendationId,
              'entity_type': recommendation.targetType,
              'entity_id': recommendation.targetId,
              'relationship': 'Affected',
              'created_at': stamp,
            });
          }
        }
        await tx.insert('period_reviews', {
          'id': reviewId,
          'title': '${draft.type} review — ${_isoDate(draft.periodStart)}',
          'type': draft.type,
          'period_start': _isoDate(draft.periodStart),
          'period_end': _isoDate(draft.periodEnd),
          'summary': draft.summary,
          'evidence_context': draft.evidenceIds.isEmpty
              ? 'No verified assessment evidence in this period.'
              : 'Verified evidence: ${draft.evidenceIds.join(', ')}',
          'next_action': draft.nextPriorities.firstOrNull ?? '',
          'wins_json': jsonEncode(draft.wins),
          'problems_json': jsonEncode(draft.problems),
          'changed_assumptions_json': jsonEncode(draft.changedAssumptionIds),
          'recommendations_json': jsonEncode(recommendationIds),
          'user_decisions_json': '[]',
          'carry_forward_json': jsonEncode(draft.carryForward),
          'next_priorities_json': jsonEncode(draft.nextPriorities),
          'created_at': stamp,
        });
        for (final evidenceId in draft.evidenceIds.toSet()) {
          final exists = await tx.query(
            'evidence',
            columns: ['id'],
            where: 'id = ?',
            whereArgs: [evidenceId],
          );
          if (exists.isNotEmpty) {
            await tx.insert('review_evidence', {
              'id': newId(),
              'review_id': reviewId,
              'review_type': draft.type,
              'evidence_id': evidenceId,
              'relationship': 'Considered',
              'created_at': stamp,
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }
        if (draft.type == 'EventDriven') {
          await tx.update(
            'strategy_events',
            {'reviewed_at': stamp},
            where: 'review_recommended = 1 AND reviewed_at IS NULL',
          );
        }
        return reviewId;
      });

  @override
  Future<String> createWeeklyPlanPreview(
    String missionId,
    List<PrioritySuggestion> suggestions,
  ) => db.transaction((tx) async {
    if (suggestions.isEmpty) {
      throw StateError(
        'Add verified evidence, job demand or interview priorities first.',
      );
    }
    final missions = await tx.query(
      'missions',
      where: 'id = ?',
      whereArgs: [missionId],
    );
    if (missions.isEmpty) throw StateError('Mission not found.');
    final mission = missions.single;
    final title = 'Next-week plan · ${mission['title']}';
    final pending = await tx.query(
      'planning_change_sets',
      where: "title = ? AND status IN ('Draft','Approved')",
      whereArgs: [title],
    );
    if (pending.isNotEmpty) {
      throw StateError('Review the existing next-week preview first.');
    }
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final recommendationId = newId();
    final confidence =
        (suggestions.fold<double>(0, (sum, item) => sum + item.confidence) /
                suggestions.length *
                100)
            .round();
    await tx.insert('recommendations', {
      'id': recommendationId,
      'type': 'Planning',
      'title': title,
      'reason':
          'Priority ranking combines verified readiness, saved job demand and active interview learning priorities.',
      'fact_basis': suggestions.map((item) => item.reason).join('\n'),
      'inference':
          'Focused sessions on the highest observed gaps are likely to improve mission readiness.',
      'expected_benefit':
          'A reviewable week with concrete evidence-producing objectives.',
      'risk':
          'Local records may be incomplete; inspect timing and scope before applying.',
      'confidence': confidence,
      'suggested_action': suggestions.map((item) => item.title).join(' · '),
      'status': 'Proposed',
      'requires_user_approval': 1,
      'created_at': stamp,
    });
    await tx.insert('recommendation_targets', {
      'id': newId(),
      'recommendation_id': recommendationId,
      'entity_type': 'Mission',
      'entity_id': missionId,
      'relationship': 'Affected',
      'created_at': stamp,
    });
    for (final suggestion in suggestions) {
      if (suggestion.skillId == null) continue;
      await tx.insert('recommendation_targets', {
        'id': newId(),
        'recommendation_id': recommendationId,
        'entity_type': 'Skill',
        'entity_id': suggestion.skillId,
        'relationship': 'Affected',
        'created_at': stamp,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      final evidence = await tx.query(
        'evidence',
        columns: ['id'],
        where: 'skill_id = ? AND verified = 1',
        whereArgs: [suggestion.skillId],
        orderBy: 'created_at DESC',
        limit: 1,
      );
      if (evidence.isNotEmpty) {
        await tx.insert('recommendation_evidence', {
          'recommendation_id': recommendationId,
          'evidence_id': evidence.single['id'],
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
    final setId = newId();
    await tx.insert('planning_change_sets', {
      'id': setId,
      'recommendation_id': recommendationId,
      'title': title,
      'status': 'Draft',
      'created_at': stamp,
    });
    final now = DateTime.now();
    final nextMonday = DateTime(
      now.year,
      now.month,
      now.day + (8 - now.weekday),
      21,
    );
    final goalId = mission['goal_id'] as String?;
    final projects = await tx.rawQuery(
      '''
      SELECT projects.id
      FROM projects
      LEFT JOIN initiatives ON initiatives.id = projects.initiative_id
      LEFT JOIN outcomes ON outcomes.id = projects.outcome_id
      WHERE projects.status = 'active'
        AND (initiatives.mission_id = ? OR outcomes.mission_id = ? OR projects.goal_id = ?)
      ORDER BY projects.priority, projects.created_at
      ''',
      [missionId, missionId, goalId],
    );
    final projectId = projects.firstOrNull?['id'] as String?;
    for (var index = 0; index < suggestions.length; index++) {
      final suggestion = suggestions[index];
      final start = nextMonday.add(Duration(days: index));
      await tx.insert('planning_changes', {
        'id': newId(),
        'change_set_id': setId,
        'action': 'CreateSession',
        'payload_json': jsonEncode({
          'id': newId(),
          'title': suggestion.title,
          'project_id': projectId,
          'goal_id': projectId == null ? goalId : null,
          'why': suggestion.reason,
          'target': 'Produce one reviewable output for ${suggestion.title}.',
          'priority': index == 0 ? 1 : 2,
          'planned_start': start.millisecondsSinceEpoch,
          'planned_minutes': 60,
          'created_at': stamp,
        }),
        'status': 'Proposed',
        'created_at': stamp,
      });
    }
    return setId;
  });

  @override
  Future<void> decidePlanningChangeSet(String id, {required bool approve}) =>
      db.transaction((tx) async {
        final rows = await tx.query(
          'planning_change_sets',
          where: 'id = ?',
          whereArgs: [id],
        );
        if (rows.isEmpty) throw StateError('Planning preview not found.');
        if (rows.single['status'] != 'Draft') {
          throw StateError('This planning preview was already decided.');
        }
        final recommendationId = rows.single['recommendation_id'] as String;
        final recommendations = await tx.query(
          'recommendations',
          where: 'id = ?',
          whereArgs: [recommendationId],
        );
        final stamp = DateTime.now().millisecondsSinceEpoch;
        if (recommendations.isNotEmpty &&
            recommendations.single['status'] == 'Proposed') {
          final status = approve ? 'Accepted' : 'Rejected';
          await _recordRecommendationDecision(
            tx,
            recommendations.single,
            status,
            stamp,
          );
          await tx.update(
            'recommendations',
            {'status': status, 'decided_at': stamp},
            where: 'id = ?',
            whereArgs: [recommendationId],
          );
        }
        await tx.update(
          'planning_change_sets',
          {'status': approve ? 'Approved' : 'Rejected', 'decided_at': stamp},
          where: 'id = ?',
          whereArgs: [id],
        );
      });

  @override
  Future<int> applyPlanningChangeSet(String id) => db.transaction((tx) async {
    final sets = await tx.query(
      'planning_change_sets',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (sets.isEmpty) throw StateError('Planning preview not found.');
    final set = sets.single;
    if (set['status'] != 'Approved') {
      throw StateError('Approve this planning preview before applying it.');
    }
    final changes = await tx.query(
      'planning_changes',
      where: "change_set_id = ? AND status = 'Proposed'",
      whereArgs: [id],
    );
    var applied = 0;
    for (final change in changes) {
      final payload = Map<String, Object?>.from(
        jsonDecode(change['payload_json'] as String) as Map,
      );
      if (change['action'] == 'CreateSession') {
        await _validateLinks(tx, 'sessions', payload);
        await tx.insert('sessions', payload);
      } else if (change['action'] == 'UpdateSession') {
        final sessionId = change['target_id'] as String?;
        if (sessionId == null) throw StateError('Session target is missing.');
        final session = await _session(tx, sessionId);
        if (session.status != SessionStatus.planned &&
            session.status != SessionStatus.inProgress) {
          throw StateError('Only future or paused sessions can be updated.');
        }
        await _validateLinks(tx, 'sessions', {...session.data, ...payload});
        await tx.update(
          'sessions',
          payload,
          where: 'id = ?',
          whereArgs: [sessionId],
        );
      } else if (change['action'] == 'CancelSession') {
        final sessionId = change['target_id'] as String?;
        if (sessionId == null) throw StateError('Session target is missing.');
        final session = await _session(tx, sessionId);
        if (session.status.terminal) {
          throw StateError('Completed session history cannot be cancelled.');
        }
        await tx.update(
          'sessions',
          {'status': 'CANCELLED'},
          where: 'id = ?',
          whereArgs: [sessionId],
        );
      }
      await tx.update(
        'planning_changes',
        {'status': 'Applied'},
        where: 'id = ?',
        whereArgs: [change['id']],
      );
      applied++;
    }
    final stamp = DateTime.now().millisecondsSinceEpoch;
    await tx.update(
      'planning_change_sets',
      {'status': 'Applied', 'applied_at': stamp},
      where: 'id = ?',
      whereArgs: [id],
    );
    await tx.update(
      'recommendations',
      {'status': 'Applied'},
      where: 'id = ?',
      whereArgs: [set['recommendation_id']],
    );
    return applied;
  });

  Future<int> _materializeRecurringSessions(
    DatabaseExecutor tx,
    DateTime from,
    DateTime through,
  ) async {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(through.year, through.month, through.day);
    if (end.isBefore(start)) {
      throw ArgumentError('Recurring schedule horizon cannot be in the past.');
    }
    if (end.difference(start).inDays > 92) {
      throw ArgumentError('Generate at most 93 days at a time.');
    }
    final schedules = await tx.query(
      'recurring_schedules',
      where: 'enabled = 1',
    );
    var inserted = 0;
    for (final schedule in schedules) {
      final templateRows = await tx.query(
        'session_templates',
        where: 'id = ?',
        whereArgs: [schedule['template_id']],
      );
      if (templateRows.isEmpty) continue;
      final template = templateRows.single;
      final weekdays = (schedule['weekdays'] as String)
          .split(',')
          .map((value) => int.tryParse(value.trim()))
          .whereType<int>()
          .where((value) => value >= 1 && value <= 7)
          .toSet();
      if (weekdays.isEmpty) continue;
      final time = RegExp(
        r'^(\d{2}):(\d{2})$',
      ).firstMatch(schedule['local_time'] as String);
      if (time == null) continue;
      final hour = int.parse(time.group(1)!);
      final minute = int.parse(time.group(2)!);
      if (hour > 23 || minute > 59) continue;
      final scheduleStart = schedule['start_date'] as String;
      final scheduleEnd = schedule['end_date'] as String;
      for (
        var day = start;
        !day.isAfter(end);
        day = day.add(const Duration(days: 1))
      ) {
        final occurrence = _isoDate(day);
        if (!weekdays.contains(day.weekday) ||
            (scheduleStart.isNotEmpty &&
                occurrence.compareTo(scheduleStart) < 0) ||
            (scheduleEnd.isNotEmpty && occurrence.compareTo(scheduleEnd) > 0)) {
          continue;
        }
        final rowId = await tx.insert('sessions', {
          'id': newId(),
          'title': template['title'],
          'project_id': template['project_id'],
          'goal_id': template['goal_id'],
          'milestone_id': template['milestone_id'],
          'why': template['why'],
          'input': template['input'],
          'target': template['target'],
          'priority': template['priority'],
          'planned_start': DateTime(
            day.year,
            day.month,
            day.day,
            hour,
            minute,
          ).millisecondsSinceEpoch,
          'planned_minutes': template['planned_minutes'],
          'recurring_schedule_id': schedule['id'],
          'occurrence_date': occurrence,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        if (rowId != 0) inserted++;
      }
    }
    return inserted;
  }

  String _isoDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
