import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:personal_os/database/schema.dart';
import 'package:personal_os/domain/career.dart';
import 'package:personal_os/domain/knowledge.dart';
import 'package:personal_os/domain/intelligence.dart';
import 'package:personal_os/domain/models.dart';
import 'package:personal_os/infrastructure/sqlite_repository.dart';
import 'package:personal_os/infrastructure/document_parser.dart';

void main() {
  late Directory temp;
  late SqliteWorkspaceRepository repo;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('strategy_test_');
    repo = await SqliteWorkspaceRepository.open(
      '${temp.path}/db.sqlite',
      demo: false,
    );
  });
  tearDown(() async {
    await repo.close();
    await temp.delete(recursive: true);
  });
  Future<void> setupStrategy() async {
    await repo.save('visions', {
      'id': 'v',
      'title': 'My vision',
      'created_at': 1,
    });
    await repo.save('strategies', {
      'id': 's',
      'title': 'Original strategy',
      'vision_id': 'v',
      'created_at': 1,
    });
    await repo.save('missions', {
      'id': 'm',
      'title': 'Mission',
      'strategy_id': 's',
      'created_at': 1,
    });
  }

  test(
    'approval is atomic, proposals do not mutate strategy, history is immutable',
    () async {
      await setupStrategy();
      await repo.save('strategy_proposals', {
        'id': 'p',
        'strategy_id': 's',
        'title': 'New strategy',
        'reason': 'Observed evidence',
        'created_at': 2,
      });
      expect(
        (await repo.load()).record('strategies', 's')!.title,
        'Original strategy',
      );
      await expectLater(
        repo.save('strategies', {'id': 's', 'title': 'Silent rewrite'}),
        throwsStateError,
      );
      await repo.save('strategy_proposals', {'id': 'p', 'status': 'Accepted'});
      var w = await repo.load();
      expect(w.record('strategies', 's')!.title, 'New strategy');
      expect(w.records('strategy_versions').length, 2);
      expect(
        w.records('strategy_versions').map((v) => v.number('version_number')),
        containsAll([1, 2]),
      );
      expect(
        w.records('strategy_versions').first.text('snapshot_json'),
        contains('Original strategy'),
      );
      await expectLater(
        repo.save('strategy_proposals', {'id': 'p', 'status': 'Accepted'}),
        throwsStateError,
      );
      await expectLater(
        repo.save('strategy_versions', {
          'id': w.records('strategy_versions').first.id,
          'title': 'overwrite',
        }),
        throwsStateError,
      );
      await repo.close();
      repo = await SqliteWorkspaceRepository.open(
        '${temp.path}/db.sqlite',
        demo: false,
      );
      w = await repo.load();
      expect(w.records('strategy_versions').length, 2);
      await repo.save('strategy_proposals', {
        'id': 'p2',
        'strategy_id': 's',
        'title': 'Third strategy',
        'reason': 'More evidence',
        'created_at': 3,
      });
      await repo.save('strategy_proposals', {'id': 'p2', 'status': 'Accepted'});
      w = await repo.load();
      expect(w.records('strategy_versions').length, 3);
      expect(
        w.records('strategy_versions').map((v) => v.number('version_number')),
        containsAll([1, 2, 3]),
      );
    },
  );
  test(
    'weighted readiness requires verified linked evidence; latest assessment wins',
    () async {
      await setupStrategy();
      await repo.save('skills', {
        'id': 'skill',
        'mission_id': 'm',
        'title': 'Linux',
        'created_at': 1,
      });
      await repo.save('outputs', {
        'id': 'o',
        'title': 'Passing tests',
        'created_at': 1,
      });
      await repo.save('evidence', {
        'id': 'e1',
        'skill_id': 'skill',
        'output_id': 'o',
        'dimension': 'Implementation',
        'score': 100,
        'verified': 0,
        'created_at': 1,
      });
      expect((await repo.load()).readiness('skill'), 0);
      await repo.save('evidence', {
        'id': 'e2',
        'skill_id': 'skill',
        'output_id': 'o',
        'dimension': 'Implementation',
        'score': 100,
        'verified': 1,
        'created_at': 2,
      });
      expect((await repo.load()).readiness('skill'), 20);
      await repo.save('evidence', {
        'id': 'e3',
        'skill_id': 'skill',
        'output_id': 'o',
        'dimension': 'Implementation',
        'score': 50,
        'verified': 1,
        'created_at': 3,
      });
      var workspace = await repo.load();
      expect(workspace.readiness('skill'), 10);
      final implementation = workspace
          .readinessBreakdown('skill')
          .singleWhere((item) => item.name == 'Implementation');
      expect(implementation.assessmentDelta, -50);
      await repo.updateReadinessWeights({
        for (final dimension in readinessWeights.keys)
          dimension: dimension == 'Implementation' ? 100 : 0,
      });
      workspace = await repo.load();
      expect(workspace.readiness('skill'), 50);
      expect(workspace.configuredReadinessWeights['Implementation'], 1);
      await expectLater(
        repo.updateReadinessWeights({'Implementation': 100}),
        throwsArgumentError,
      );
      await expectLater(
        repo.save('evidence', {'id': 'e3', 'score': 100}),
        throwsStateError,
      );
      await expectLater(
        repo.save('evidence', {
          'id': 'bad',
          'skill_id': 'missing',
          'output_id': 'o',
          'dimension': 'Implementation',
          'score': 100,
          'created_at': 4,
        }),
        throwsA(isA<DatabaseException>()),
      );
    },
  );
  test('outcomes use weights, cap attainment and reject zero target', () async {
    await setupStrategy();
    await repo.save('outcomes', {
      'id': 'a',
      'mission_id': 'm',
      'title': 'A',
      'target': 10,
      'current_value': 20,
      'weight': 3,
      'created_at': 1,
    });
    await repo.save('outcomes', {
      'id': 'b',
      'mission_id': 'm',
      'title': 'B',
      'target': 10,
      'current_value': 0,
      'weight': 1,
      'created_at': 1,
    });
    expect((await repo.load()).missionProgress('m'), .75);
    await expectLater(
      repo.save('outcomes', {'id': 'a', 'target': 0}),
      throwsA(isA<DatabaseException>()),
    );
  });
  test('project outcome completes the session-to-vision why path', () async {
    await setupStrategy();
    await repo.save('outcomes', {
      'id': 'outcome',
      'mission_id': 'm',
      'title': 'Interview readiness',
      'target': 5,
      'created_at': 1,
    });
    await repo.save('projects', {
      'id': 'project',
      'title': 'CodeCrafters',
      'outcome_id': 'outcome',
      'created_at': 1,
    });
    await repo.save('sessions', {
      'id': 'session',
      'title': 'HTTP server',
      'project_id': 'project',
      'planned_start': 1,
      'planned_minutes': 60,
      'created_at': 1,
    });
    expect(
      (await repo.load()).whyPath((await repo.load()).sessions.single),
      'HTTP server → CodeCrafters → Interview readiness → Mission → Original strategy → My vision',
    );
  });
  test('v5 hierarchy links horizon to initiative, task and session', () async {
    await repo.save('visions', {
      'id': 'v5-vision',
      'title': 'Long-term direction',
      'created_at': 1,
    });
    await repo.save('horizons', {
      'id': 'horizon',
      'vision_id': 'v5-vision',
      'title': '2027 horizon',
      'created_at': 1,
    });
    await repo.save('strategies', {
      'id': 'v5-strategy',
      'vision_id': 'v5-vision',
      'horizon_id': 'horizon',
      'title': 'Career strategy',
      'created_at': 1,
    });
    await repo.save('missions', {
      'id': 'v5-mission',
      'strategy_id': 'v5-strategy',
      'title': 'Job switch',
      'created_at': 1,
    });
    await repo.save('outcomes', {
      'id': 'v5-outcome',
      'mission_id': 'v5-mission',
      'title': 'Interview ready',
      'target': 1,
      'created_at': 1,
    });
    await repo.save('initiatives', {
      'id': 'initiative',
      'mission_id': 'v5-mission',
      'outcome_id': 'v5-outcome',
      'title': 'Systems programming',
      'weekly_budget_minutes': 120,
      'created_at': 1,
    });
    await repo.save('projects', {
      'id': 'v5-project',
      'initiative_id': 'initiative',
      'title': 'CodeCrafters',
      'created_at': 1,
    });
    await repo.save('tasks', {
      'id': 'task',
      'project_id': 'v5-project',
      'title': 'Implement parser',
      'description': 'Complete one observable stage',
      'status': 'Blocked',
      'estimated_minutes': 60,
      'priority': 1,
      'created_at': 1,
    });
    await repo.save('sessions', {
      'id': 'v5-session',
      'project_id': 'v5-project',
      'task_id': 'task',
      'title': 'Parser session',
      'planned_start': 1,
      'planned_minutes': 60,
      'created_at': 1,
    });
    final workspace = await repo.load();
    expect(workspace.tasks.single.text('status'), 'Blocked');
    expect(workspace.sessions.single.taskId, 'task');
    expect(
      workspace.whyPath(workspace.sessions.single),
      'Parser session → CodeCrafters → Systems programming → Interview ready → Job switch → Career strategy → Long-term direction',
    );
  });

  test(
    'structured recommendation decisions preserve their audit record',
    () async {
      await repo.save('recommendations', {
        'id': 'recommendation',
        'type': 'Strategy',
        'title': 'Increase Linux priority',
        'reason': 'Demand exceeds readiness',
        'fact_basis': 'Linux appears in 8 of 10 jobs',
        'inference': 'More practice should reduce the gap',
        'expected_benefit': 'Higher interview readiness',
        'risk': 'Less time for another skill',
        'confidence': 80,
        'suggested_action': 'Add two Linux sessions',
        'created_at': 1,
      });
      await repo.save('recommendations', {
        'id': 'recommendation',
        'status': 'Accepted',
      });
      final accepted = (await repo.load()).record(
        'recommendations',
        'recommendation',
      )!;
      expect(accepted.text('status'), 'Accepted');
      expect(accepted.at('decided_at'), isNotNull);
      expect(
        (await repo.load())
            .records('recommendation_decisions')
            .single
            .text('decision'),
        'Accepted',
      );
      await expectLater(
        repo.save('recommendations', {
          'id': 'recommendation',
          'reason': 'Rewrite history',
        }),
        throwsStateError,
      );
      await repo.save('recommendations', {
        'id': 'recommendation',
        'status': 'Applied',
      });
      expect(
        (await repo.load())
            .record('recommendations', 'recommendation')!
            .text('status'),
        'Applied',
      );
    },
  );
  test(
    'adaptive review persists evidence and recommendation targets',
    () async {
      await setupStrategy();
      final start = DateTime(2026, 9, 1);
      final end = DateTime(2026, 10, 1);
      final stamp = DateTime(2026, 9, 10).millisecondsSinceEpoch;
      await repo.save('skills', {
        'id': 'review-skill',
        'mission_id': 'm',
        'title': 'Linux IPC',
        'created_at': stamp,
      });
      await repo.save('outputs', {
        'id': 'review-output',
        'title': 'IPC benchmark',
        'created_at': stamp,
      });
      await repo.save('evidence', {
        'id': 'review-evidence',
        'skill_id': 'review-skill',
        'output_id': 'review-output',
        'dimension': 'Implementation',
        'score': 40,
        'verified': 1,
        'created_at': stamp,
      });
      await repo.save('learning_priorities', {
        'id': 'priority',
        'mission_id': 'm',
        'skill_id': 'review-skill',
        'title': 'Practice shared memory',
        'reason': 'Failed interview question',
        'created_at': stamp,
      });
      await repo.save('assumptions', {
        'id': 'weak-assumption',
        'strategy_id': 's',
        'title': 'Hiring demand remains stable',
        'status': 'Weakening',
        'confidence': 30,
        'evidence_context': 'Fewer matching roles this month',
        'created_at': stamp,
      });
      await repo.save('strategy_events', {
        'id': 'market-event',
        'type': 'MarketContraction',
        'title': 'Hiring demand contracted',
        'description': 'Target-role hiring demand is less stable.',
        'impact': 'Recheck the active career strategy.',
        'occurred_at': stamp,
        'created_at': stamp,
      });
      final workspace = await repo.load();
      expect(workspace.records('event_assumptions'), hasLength(1));
      const provider = LocalIntelligenceProvider();
      expect(provider.contextBoundary(workspace).sendsDataOffDevice, isFalse);
      final draft = provider.buildReview(
        workspace,
        type: 'Quarterly',
        periodStart: start,
        periodEnd: end,
      );
      expect(
        draft.recommendations.map((recommendation) => recommendation.type),
        containsAll(['Planning', 'Assumption']),
      );
      expect(draft.evidenceIds, contains('review-evidence'));
      await repo.saveAdaptiveReview(draft);
      final saved = await repo.load();
      expect(saved.records('period_reviews'), hasLength(1));
      expect(saved.records('recommendations'), hasLength(2));
      expect(saved.records('recommendation_targets'), hasLength(2));
      expect(saved.records('recommendation_evidence'), isNotEmpty);
      expect(saved.records('review_evidence'), hasLength(1));
      final planningRecommendation = saved
          .records('recommendations')
          .firstWhere((record) => record.text('type') == 'Planning');
      await repo.save('recommendations', {
        'id': planningRecommendation.id,
        'status': 'Accepted',
      });
      var planned = await repo.load();
      expect(planned.records('review_decisions'), hasLength(1));
      expect(planned.records('planning_change_sets'), hasLength(1));
      expect(planned.sessions, isEmpty);
      final changeSet = planned.records('planning_change_sets').single;
      await repo.decidePlanningChangeSet(changeSet.id, approve: true);
      expect(await repo.applyPlanningChangeSet(changeSet.id), 1);
      planned = await repo.load();
      expect(planned.sessions, hasLength(1));
      expect(planned.sessions.single.title, planningRecommendation.title);
      expect(
        planned.record('planning_change_sets', changeSet.id)!.text('status'),
        'Applied',
      );
      expect(
        planned
            .record('recommendations', planningRecommendation.id)!
            .text('status'),
        'Applied',
      );
      final annual = provider.buildReview(
        planned,
        type: 'Annual',
        periodStart: start,
        periodEnd: end,
      );
      expect(
        annual.recommendations.map((recommendation) => recommendation.type),
        contains('Strategy'),
      );
      expect(annual.nextPriorities.join(' '), contains('3-year'));
      final eventReview = provider.buildReview(
        planned,
        type: 'EventDriven',
        periodStart: start,
        periodEnd: end,
      );
      expect(eventReview.summary, contains('unreviewed material events'));
      await repo.saveAdaptiveReview(eventReview);
      expect(
        (await repo.load())
            .record('strategy_events', 'market-event')!
            .data['reviewed_at'],
        isNotNull,
      );
    },
  );
  test(
    'v1 migration retains old user records and does not seed strategy',
    () async {
      await repo.close();
      final legacy = await databaseFactoryFfi.openDatabase(
        '${temp.path}/legacy.sqlite',
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, v) => migrate(db, 0, 1),
        ),
      );
      await legacy.insert('goals', {
        'id': 'old',
        'title': 'User goal',
        'created_at': 1,
      });
      await legacy.close();
      repo = await SqliteWorkspaceRepository.open('${temp.path}/legacy.sqlite');
      final w = await repo.load();
      expect(w.goals.single.title, 'User goal');
      expect(w.records('visions'), isEmpty);
      expect(await repo.db.getVersion(), schemaVersion);
      final tables = await repo.db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final names = tables.map((row) => row['name']).toSet();
      expect(
        names,
        containsAll([
          'horizons',
          'initiatives',
          'recommendations',
          'evidence_links',
          'review_decisions',
          'recommendation_decisions',
          'knowledge_search_events',
          'context_sharing_audit',
          'metrics',
          'metric_snapshots',
          'readiness_weights',
          'knowledge_sections',
          'knowledge_links',
          'concepts',
          'knowledge_concepts',
          'knowledge_embeddings',
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
        ]),
      );
    },
  );
  test(
    'every historical schema upgrades without losing stored settings',
    () async {
      for (var version = 1; version < schemaVersion; version++) {
        final path = '${temp.path}/historical-$version.sqlite';
        final historical = await databaseFactoryFfi.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: version,
            onCreate: (db, target) => migrate(db, 0, target),
          ),
        );
        await historical.insert('settings', {
          'key': 'migration-sentinel',
          'value': 'schema-$version',
        });
        await historical.close();
        final upgraded = await SqliteWorkspaceRepository.open(
          path,
          demo: false,
        );
        expect(await upgraded.db.getVersion(), schemaVersion);
        expect(
          (await upgraded.load()).settings['migration-sentinel'],
          'schema-$version',
        );
        await upgraded.close();
      }
    },
  );
  test(
    'ownership and capital records preserve reviewable local signals',
    () async {
      await repo.save('projects', {
        'id': 'product',
        'title': 'Trace Inspector',
        'project_type': 'Product',
        'created_at': 1,
      });
      await repo.save('engine_allocations', {
        'id': 'ownership',
        'engine': 'Ownership',
        'mode': 'Maintenance',
        'weekly_budget_min': 30,
        'weekly_budget_max': 60,
        'current_objective': 'One customer signal each week',
        'created_at': 1,
      });
      await repo.save('customer_discoveries', {
        'id': 'discovery',
        'project_id': 'product',
        'problem': 'Root cause analysis takes too long',
        'evidence': 'Engineer described a two-hour manual trace',
        'signal': 'Strong',
        'next_action': 'Prototype the trace summary',
        'happened_at': 2,
        'created_at': 2,
      });
      await repo.save('revenue_entries', {
        'id': 'revenue',
        'project_id': 'product',
        'amount': 100.5,
        'occurred_at': 3,
        'created_at': 3,
      });
      await repo.save('distribution_events', {
        'id': 'distribution',
        'project_id': 'product',
        'channel': 'Technical blog',
        'reach': 80,
        'leads': 3,
        'occurred_at': 4,
        'created_at': 4,
      });
      await repo.save('capital_contributions', {
        'id': 'capital',
        'account': 'Long-term portfolio',
        'amount': 250.0,
        'occurred_at': 5,
        'created_at': 5,
      });
      await repo.save('net_worth_snapshots', {
        'id': 'net-worth',
        'value': 1000.0,
        'observed_at': 6,
        'created_at': 6,
      });
      final workspace = await repo.load();
      expect(workspace.records('engine_allocations'), hasLength(1));
      expect(
        workspace.records('customer_discoveries').single.text('signal'),
        'Strong',
      );
      expect(workspace.records('revenue_entries').single.data['amount'], 100.5);
      expect(workspace.records('net_worth_snapshots'), hasLength(1));
      await expectLater(
        repo.save('capital_contributions', {
          'id': 'invalid',
          'account': 'Portfolio',
          'amount': -1,
          'occurred_at': 7,
          'created_at': 7,
        }),
        throwsA(isA<DatabaseException>()),
      );
      final exportPath = '${temp.path}/portable.json';
      await repo.exportPortableJson(exportPath);
      final exported = jsonDecode(await File(exportPath).readAsString()) as Map;
      expect(exported['schema_version'], schemaVersion);
      expect((exported['tables'] as Map)['engine_allocations'], hasLength(1));
      await repo.deleteDataCategory('OwnershipCapital');
      final retained = await repo.load();
      expect(retained.records('engine_allocations'), isEmpty);
      expect(retained.projects.single.id, 'product');
    },
  );
  test(
    'online backup reopens independently and duplicate starter is rejected',
    () async {
      await setupStrategy();
      await repo.backup('${temp.path}/backup.sqlite');
      await repo.exportPortableJson('${temp.path}/portable.json');
      final portable =
          jsonDecode(await File('${temp.path}/portable.json').readAsString())
              as Map<String, dynamic>;
      expect(portable['schema_version'], schemaVersion);
      expect(
        (portable['tables'] as Map<String, dynamic>)['visions'],
        isNotEmpty,
      );
      final copy = await SqliteWorkspaceRepository.open(
        '${temp.path}/backup.sqlite',
        demo: false,
      );
      expect((await copy.load()).record('visions', 'v')!.title, 'My vision');
      await copy.close();
      await expectLater(repo.installStrategyTemplate({}), throwsStateError);
    },
  );
  test(
    'document parser preserves Unicode and rejects unsupported / empty input',
    () async {
      final file = File('${temp.path}/note.md');
      await file.writeAsString('# Kiến thức\nLinux IPC');
      expect(await DocumentParser().extract(file.path), contains('Kiến thức'));
      await file.writeAsString('');
      await expectLater(
        DocumentParser().extract(file.path),
        throwsFormatException,
      );
      final pdf = File('${temp.path}/scan.pdf');
      await pdf.writeAsString('fake');
      await expectLater(
        DocumentParser().extract(pdf.path),
        throwsFormatException,
      );
      await pdf.writeAsString(
        '%PDF-1.4\n1 0 obj\n<< /Length 48 >>\nstream\n'
        'BT /F1 12 Tf (Linux networking) Tj ET\n'
        'endstream\nendobj\n%%EOF',
      );
      expect(await DocumentParser().extract(pdf.path), 'Linux networking');
    },
  );

  test(
    'knowledge import metadata, sections, concepts and FTS stay inspectable',
    () async {
      final file = File('${temp.path}/linux.md');
      await file.writeAsString(
        '# Linux IPC\nShared memory moves bytes.\n\n# Sockets\nSockets cross hosts.',
      );
      final parsed = await DocumentParser().inspect(file.path);
      final managed = await repo.preserveKnowledgeSource(
        file.path,
        parsed.checksum,
      );
      expect(await File(managed).readAsString(), contains('Shared memory'));
      await repo.save('knowledge', {
        'id': 'knowledge-fts',
        'title': 'Linux communication',
        'content': parsed.text,
        'summary': 'IPC and sockets',
        'tags': 'Linux, Networking',
        'source_uri': file.path,
        'source_filename': parsed.filename,
        'source_checksum': parsed.checksum,
        'source_size': parsed.size,
        'source_modified_at': parsed.modifiedAt.millisecondsSinceEpoch,
        'imported_at': 1,
        'source_mime': parsed.mimeType,
        'managed_source_path': managed,
        'created_at': 1,
        'updated_at': 1,
      });
      final workspace = await repo.load();
      expect(workspace.records('knowledge_sections'), hasLength(2));
      expect(
        workspace.records('concepts').map((record) => record.title),
        containsAll(['Linux', 'Networking']),
      );
      final hits = await repo.searchKnowledge('shared memory');
      expect(hits, hasLength(1));
      expect(hits.single.item.id, 'knowledge-fts');
      expect(hits.single.snippet, contains('‹Shared›'));
      expect(hits.single.sectionTitle, 'Linux IPC');
      expect(hits.single.startOffset, 0);
      await repo.save('knowledge', {
        'id': 'related-item',
        'title': 'Linux process notes',
        'content': 'Processes can exchange data through pipes.',
        'tags': 'Linux',
        'created_at': 2,
        'updated_at': 2,
      });
      expect(
        (await repo.load())
            .records('knowledge_links')
            .where(
              (link) =>
                  link.ref('knowledge_id') == 'related-item' &&
                  link.ref('entity_id') == 'knowledge-fts' &&
                  link.number('suggested') == 1,
            ),
        hasLength(1),
      );
      await repo.save('knowledge', {
        'id': 'semantic-item',
        'title': 'Concurrency primitive',
        'content': 'A mutex protects shared state between threads.',
        'tags': 'C++',
        'created_at': 2,
        'updated_at': 2,
      });
      final semanticHits = await repo.searchKnowledge(
        'synchronization',
        semanticVector: const LocalIntelligenceProvider().embed(
          'synchronization',
        ),
      );
      expect(semanticHits.map((hit) => hit.item.id), contains('semantic-item'));
      expect(
        semanticHits
            .firstWhere((hit) => hit.item.id == 'semantic-item')
            .relationship,
        contains('Semantic similarity'),
      );
      expect(await repo.searchKnowledge('definitely-absent-term'), isEmpty);
      final measured = (await repo.load()).usageSummary(DateTime.now());
      expect(measured.searches, 3);
      expect(measured.retrievalSuccess, closeTo(2 / 3, .001));
      expect(measured.averageSearchMs, isNotNull);
      await repo.deleteDataCategory('Knowledge');
      expect((await repo.load()).knowledge, isEmpty);
      expect(await File(managed).exists(), isFalse);
    },
  );

  test('knowledge import suggestions remain reviewable and source-based', () {
    final workspace = Workspace(
      projects: [
        Project({'id': 'p', 'title': 'CodeCrafters'}),
      ],
      strategyData: {
        'skills': [
          StrategyRecord({
            'id': 'skill',
            'mission_id': 'mission',
            'title': 'Linux networking',
          }),
        ],
      },
    );
    final suggestion = suggestKnowledgeMetadata(
      'Linux networking explains sockets. Apply it in CodeCrafters. '
      'Linux networking improves debugging.',
      workspace,
    );
    expect(suggestion.summary, contains('sockets'));
    expect(suggestion.tags, contains('Linux networking'));
    expect(suggestion.skillId, 'skill');
    expect(suggestion.projectId, 'p');
    expect(suggestion.missionId, 'mission');
  });

  test(
    'job descriptions aggregate mission demand and remain local records',
    () async {
      await setupStrategy();
      await repo.save('skills', {
        'id': 'cpp',
        'mission_id': 'm',
        'title': 'Modern C++',
        'created_at': 1,
      });
      await repo.save('skills', {
        'id': 'linux',
        'mission_id': 'm',
        'title': 'Linux / OS / Networking',
        'created_at': 1,
      });
      final count = await repo.importJobDescriptions(
        'm',
        'Title: Senior Embedded Engineer\nCompany: A\nDomain: Automotive\nSalary: 100000-140000 USD\nMinimum 3+ years C++ required\nLinux preferred\n---\n'
            'Title: Platform Engineer\nCompany: B\nLinux networking',
      );
      expect(count, 2);
      final w = await repo.load();
      final demand = skillDemandForMission(w, 'm');
      expect(w.records('jobs').length, 2);
      expect(demand.first.skill.id, 'linux');
      expect(demand.first.jobCount, 2);
      expect(demand.where((d) => d.skill.id == 'cpp').single.jobCount, 1);
      final automotive = w
          .records('jobs')
          .singleWhere((job) => job.text('company') == 'A');
      expect(automotive.text('domain'), 'Automotive');
      expect(automotive.text('seniority'), 'Senior');
      expect(automotive.data['salary_min'], 100000);
      final cppRequirement = w
          .records('job_requirements')
          .singleWhere((record) => record.ref('skill_id') == 'cpp');
      expect(cppRequirement.text('requirement_type'), 'Required');
      expect(cppRequirement.data['years_required'], 3.0);
      expect(cppRequirement.text('source_excerpt'), contains('3+ years'));
      final duplicateCount = await repo.importJobDescriptions(
        'm',
        'Title: Senior Embedded Engineer\nCompany: A\nDomain: Automotive\nSalary: 100000-140000 USD\nMinimum 3+ years C++ required\nLinux preferred',
      );
      expect(duplicateCount, 0);
      expect((await repo.load()).records('jobs').length, 2);
      final suggestions = nextWeekPrioritySuggestions(await repo.load(), 'm');
      expect(suggestions.first.title, contains('Linux'));
      expect(suggestions.first.reason, contains('2/2'));
      final previewId = await repo.createWeeklyPlanPreview('m', suggestions);
      var planned = await repo.load();
      expect(
        planned.records('planning_changes'),
        hasLength(suggestions.length),
      );
      expect(
        planned.record('planning_change_sets', previewId)!.text('status'),
        'Draft',
      );
      await expectLater(
        repo.createWeeklyPlanPreview('m', suggestions),
        throwsStateError,
      );
      await repo.decidePlanningChangeSet(previewId, approve: true);
      expect(await repo.applyPlanningChangeSet(previewId), suggestions.length);
      planned = await repo.load();
      expect(planned.sessions, hasLength(suggestions.length));
      expect(
        planned.records('recommendation_decisions').single.text('decision'),
        'Accepted',
      );
    },
  );

  test(
    'failed interview question converts once into a sourced priority',
    () async {
      await setupStrategy();
      await repo.save('jobs', {
        'id': 'job',
        'mission_id': 'm',
        'title': 'Systems Engineer',
        'company': 'Example',
        'created_at': 1,
      });
      await repo.save('applications', {
        'id': 'application',
        'job_id': 'job',
        'status': 'Interview',
        'created_at': 1,
      });
      await repo.save('interviews', {
        'id': 'interview',
        'application_id': 'application',
        'result': 'Partial',
        'created_at': 1,
      });
      await repo.save('interview_questions', {
        'id': 'question',
        'interview_id': 'interview',
        'title': 'Explain shared_ptr internals',
        'result': 'Fail',
        'created_at': 1,
      });
      await repo.convertInterviewQuestionToPriority('question');
      final w = await repo.load();
      expect(
        w.records('learning_priorities').single.title,
        contains('shared_ptr'),
      );
      expect(
        w.records('learning_priorities').single.ref('source_question_id'),
        'question',
      );
      expect(
        w.record('interview_questions', 'question')!.data['converted_at'],
        isNotNull,
      );
      await expectLater(
        repo.convertInterviewQuestionToPriority('question'),
        throwsStateError,
      );
      await expectLater(
        repo.save('interview_questions', {'id': 'question', 'result': 'Pass'}),
        throwsStateError,
      );
    },
  );

  test('income experiments require a next action or explicit kill', () async {
    await expectLater(
      repo.save('experiments', {
        'id': 'invalid',
        'title': 'Excel automation',
        'hypothesis': 'SMEs will pay',
        'experiment': 'Send ten proposals',
        'created_at': 1,
      }),
      throwsA(isA<DatabaseException>()),
    );
    await repo.save('experiments', {
      'id': 'valid',
      'title': 'Excel automation',
      'hypothesis': 'SMEs will pay',
      'experiment': 'Send ten proposals',
      'next_action': 'Build portfolio demo',
      'created_at': 1,
    });
    expect(
      (await repo.load()).records('experiments').single.title,
      contains('Excel'),
    );
  });

  test('recurring schedules generate idempotent planned sessions', () async {
    final today = DateTime.now();
    final dateText =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    await repo.save('session_templates', {
      'id': 'template',
      'title': 'English practice',
      'priority': 1,
      'planned_minutes': 60,
      'created_at': 1,
    });
    await repo.save('recurring_schedules', {
      'id': 'schedule',
      'template_id': 'template',
      'title': 'Daily English',
      'weekdays': '${today.weekday}',
      'local_time': '22:25',
      'start_date': dateText,
      'end_date': dateText,
      'created_at': 1,
    });
    expect(await repo.generateRecurringSessions(today), 1);
    expect(await repo.generateRecurringSessions(today), 0);
    var workspace = await repo.load();
    final generated = workspace.sessions.single;
    expect(generated.title, 'English practice');
    expect(generated.plannedMinutes, 60);
    expect(generated.data['occurrence_date'], dateText);
    await repo.save('recurring_schedules', {'id': 'schedule', 'enabled': 0});
    workspace = await repo.load();
    expect(workspace.sessions, hasLength(1));
    expect(
      workspace.records('recurring_schedules').single.number('enabled'),
      0,
    );
  });
}
