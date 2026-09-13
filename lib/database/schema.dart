import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const schemaVersion = 13;
Future<void> migrate(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 1) {
    for (final sql in _v1) {
      await db.execute(sql);
    }
  }
  if (oldVersion < 2 && newVersion >= 2) {
    for (final sql in _v2) {
      await db.execute(sql);
    }
  }
  if (oldVersion < 3 && newVersion >= 3) {
    for (final sql in _v3) {
      await db.execute(sql);
    }
  }
  if (oldVersion < 4 && newVersion >= 4) {
    for (final sql in _v4) {
      await db.execute(sql);
    }
  }
  if (oldVersion < 5 && newVersion >= 5) {
    for (final sql in _v5) {
      await db.execute(sql);
    }
  }
  if (oldVersion < 6 && newVersion >= 6) {
    for (final sql in _v6) {
      await db.execute(sql);
    }
  }
  if (oldVersion < 7 && newVersion >= 7) {
    for (final sql in _v7) {
      await db.execute(sql);
    }
  }
  if (oldVersion < 8 && newVersion >= 8) {
    for (final sql in _v8) {
      await db.execute(sql);
    }
  }
  if (oldVersion < 9 && newVersion >= 9) {
    for (final sql in _v9) {
      await db.execute(sql);
    }
  }
  if (oldVersion < 10 && newVersion >= 10) {
    for (final sql in _v10) {
      await db.execute(sql);
    }
  }
  if (oldVersion < 11 && newVersion >= 11) {
    for (final sql in _v11) {
      await db.execute(sql);
    }
  }
  if (oldVersion < 12 && newVersion >= 12) {
    for (final sql in _v12) {
      await db.execute(sql);
    }
  }
  if (oldVersion < 13 && newVersion >= 13) {
    for (final sql in _v13) {
      await db.execute(sql);
    }
  }
}

const _v1 = [
  'CREATE TABLE life_areas (id TEXT PRIMARY KEY, title TEXT NOT NULL, color INTEGER NOT NULL)',
  "CREATE TABLE goals (id TEXT PRIMARY KEY, title TEXT NOT NULL CHECK(length(trim(title))>0), description TEXT NOT NULL DEFAULT '', why TEXT NOT NULL DEFAULT '', life_area_id TEXT REFERENCES life_areas(id), priority INTEGER NOT NULL DEFAULT 2 CHECK(priority BETWEEN 1 AND 3), target_at INTEGER, status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active','paused','completed','abandoned')), created_at INTEGER NOT NULL)",
  "CREATE TABLE projects (id TEXT PRIMARY KEY, title TEXT NOT NULL CHECK(length(trim(title))>0), description TEXT NOT NULL DEFAULT '', goal_id TEXT REFERENCES goals(id), priority INTEGER NOT NULL DEFAULT 2 CHECK(priority BETWEEN 1 AND 3), status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active','paused','completed','archived')), start_at INTEGER, target_at INTEGER, next_action TEXT NOT NULL DEFAULT '', created_at INTEGER NOT NULL)",
  "CREATE TABLE milestones (id TEXT PRIMARY KEY, project_id TEXT NOT NULL REFERENCES projects(id), title TEXT NOT NULL CHECK(length(trim(title))>0), description TEXT NOT NULL DEFAULT '', kind TEXT NOT NULL DEFAULT 'milestone' CHECK(kind IN ('milestone','experiment')), completed_at INTEGER, created_at INTEGER NOT NULL)",
  "CREATE TABLE sessions (id TEXT PRIMARY KEY, title TEXT NOT NULL CHECK(length(trim(title))>0), project_id TEXT REFERENCES projects(id), goal_id TEXT REFERENCES goals(id), milestone_id TEXT REFERENCES milestones(id), why TEXT NOT NULL DEFAULT '', input TEXT NOT NULL DEFAULT '', target TEXT NOT NULL DEFAULT '', priority INTEGER NOT NULL DEFAULT 2 CHECK(priority BETWEEN 1 AND 3), status TEXT NOT NULL DEFAULT 'PLANNED' CHECK(status IN ('PLANNED','ACTIVE','DONE','IN_PROGRESS','SKIPPED','CANCELLED')), planned_start INTEGER NOT NULL, planned_minutes INTEGER NOT NULL CHECK(planned_minutes>0), actual_start INTEGER, actual_end INTEGER, actual_seconds INTEGER NOT NULL DEFAULT 0 CHECK(actual_seconds>=0), segment_start INTEGER, next_action TEXT NOT NULL DEFAULT '', created_at INTEGER NOT NULL, CHECK(project_id IS NULL OR goal_id IS NULL))",
  "CREATE UNIQUE INDEX one_active_session ON sessions(status) WHERE status='ACTIVE'",
  'CREATE INDEX sessions_date ON sessions(planned_start)',
  'CREATE INDEX sessions_project ON sessions(project_id)',
  "CREATE TABLE tasks (id TEXT PRIMARY KEY, project_id TEXT REFERENCES projects(id), title TEXT NOT NULL CHECK(length(trim(title))>0), done INTEGER NOT NULL DEFAULT 0 CHECK(done IN (0,1)), created_at INTEGER NOT NULL)",
  "CREATE TABLE outputs (id TEXT PRIMARY KEY, title TEXT NOT NULL CHECK(length(trim(title))>0), type TEXT NOT NULL DEFAULT 'Artifact', description TEXT NOT NULL DEFAULT '', project_id TEXT REFERENCES projects(id), session_id TEXT REFERENCES sessions(id), link TEXT NOT NULL DEFAULT '', notes TEXT NOT NULL DEFAULT '', created_at INTEGER NOT NULL)",
  'CREATE INDEX outputs_project ON outputs(project_id, created_at)',
  "CREATE TABLE knowledge (id TEXT PRIMARY KEY, title TEXT NOT NULL CHECK(length(trim(title))>0), type TEXT NOT NULL DEFAULT 'Note', content TEXT NOT NULL DEFAULT '', tags TEXT NOT NULL DEFAULT '', project_id TEXT REFERENCES projects(id), goal_id TEXT REFERENCES goals(id), session_id TEXT REFERENCES sessions(id), created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, CHECK(project_id IS NULL OR goal_id IS NULL))",
  "CREATE TABLE inbox (id TEXT PRIMARY KEY, title TEXT NOT NULL CHECK(length(trim(title))>0), kind TEXT NOT NULL DEFAULT 'Idea', processed_at INTEGER, created_at INTEGER NOT NULL)",
  "CREATE TABLE weekly_reviews (id TEXT PRIMARY KEY, reflection TEXT NOT NULL DEFAULT '', next_action TEXT NOT NULL DEFAULT '', updated_at INTEGER NOT NULL)",
  'CREATE TABLE focus_intervals (id TEXT PRIMARY KEY, session_id TEXT NOT NULL REFERENCES sessions(id), start_at INTEGER NOT NULL, end_at INTEGER NOT NULL CHECK(end_at>=start_at), seconds INTEGER NOT NULL CHECK(seconds>=0))',
  'CREATE INDEX intervals_dates ON focus_intervals(start_at,end_at)',
  'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
];

const _v2 = [
  "CREATE TABLE visions (id TEXT PRIMARY KEY, title TEXT NOT NULL CHECK(length(trim(title))>0), description TEXT NOT NULL DEFAULT '', target_date TEXT NOT NULL DEFAULT '', created_at INTEGER NOT NULL)",
  "CREATE TABLE strategies (id TEXT PRIMARY KEY, vision_id TEXT NOT NULL REFERENCES visions(id), title TEXT NOT NULL CHECK(length(trim(title))>0), description TEXT NOT NULL DEFAULT '', engine TEXT NOT NULL DEFAULT 'Career', allocation TEXT NOT NULL DEFAULT 'Primary', created_at INTEGER NOT NULL)",
  "CREATE TABLE missions (id TEXT PRIMARY KEY, strategy_id TEXT NOT NULL REFERENCES strategies(id), goal_id TEXT REFERENCES goals(id), title TEXT NOT NULL CHECK(length(trim(title))>0), success_criteria TEXT NOT NULL DEFAULT '', status TEXT NOT NULL DEFAULT 'Active', priority INTEGER NOT NULL DEFAULT 0 CHECK(priority BETWEEN 0 AND 3), confidence INTEGER NOT NULL DEFAULT 0 CHECK(confidence BETWEEN 0 AND 100), target_date TEXT NOT NULL DEFAULT '', created_at INTEGER NOT NULL)",
  "CREATE TABLE outcomes (id TEXT PRIMARY KEY, mission_id TEXT NOT NULL REFERENCES missions(id), title TEXT NOT NULL CHECK(length(trim(title))>0), target INTEGER NOT NULL CHECK(target>0), current_value INTEGER NOT NULL DEFAULT 0 CHECK(current_value>=0), weight INTEGER NOT NULL DEFAULT 1 CHECK(weight>0), unit TEXT NOT NULL DEFAULT '', created_at INTEGER NOT NULL)",
  "CREATE TABLE skills (id TEXT PRIMARY KEY, mission_id TEXT NOT NULL REFERENCES missions(id), title TEXT NOT NULL CHECK(length(trim(title))>0), created_at INTEGER NOT NULL)",
  "CREATE TABLE evidence (id TEXT PRIMARY KEY, skill_id TEXT NOT NULL REFERENCES skills(id), output_id TEXT NOT NULL REFERENCES outputs(id), dimension TEXT NOT NULL CHECK(dimension IN ('Knowledge','Implementation','Debugging','Application','Interview','Production')), score INTEGER NOT NULL CHECK(score BETWEEN 0 AND 100), verified INTEGER NOT NULL DEFAULT 0 CHECK(verified IN (0,1)), created_at INTEGER NOT NULL)",
  "CREATE TABLE assumptions (id TEXT PRIMARY KEY, strategy_id TEXT NOT NULL REFERENCES strategies(id), title TEXT NOT NULL CHECK(length(trim(title))>0), status TEXT NOT NULL DEFAULT 'Unverified', confidence INTEGER NOT NULL DEFAULT 0 CHECK(confidence BETWEEN 0 AND 100), evidence_context TEXT NOT NULL DEFAULT '', created_at INTEGER NOT NULL)",
  "CREATE TABLE strategy_versions (id TEXT PRIMARY KEY, strategy_id TEXT NOT NULL REFERENCES strategies(id), title TEXT NOT NULL, snapshot_json TEXT NOT NULL, change_reason TEXT NOT NULL, created_at INTEGER NOT NULL)",
  "CREATE TABLE strategy_proposals (id TEXT PRIMARY KEY, strategy_id TEXT NOT NULL REFERENCES strategies(id), title TEXT NOT NULL CHECK(length(trim(title))>0), description TEXT NOT NULL DEFAULT '', reason TEXT NOT NULL CHECK(length(trim(reason))>0), engine TEXT NOT NULL DEFAULT 'Unchanged', allocation TEXT NOT NULL DEFAULT 'Unchanged', evidence_context TEXT NOT NULL DEFAULT '', confidence INTEGER NOT NULL DEFAULT 0 CHECK(confidence BETWEEN 0 AND 100), status TEXT NOT NULL DEFAULT 'Pending' CHECK(status IN ('Pending','Accepted','Rejected')), created_at INTEGER NOT NULL)",
  "CREATE TABLE period_reviews (id TEXT PRIMARY KEY, title TEXT NOT NULL, type TEXT NOT NULL, period_start TEXT NOT NULL, period_end TEXT NOT NULL, summary TEXT NOT NULL, evidence_context TEXT NOT NULL DEFAULT '', next_action TEXT NOT NULL DEFAULT '', created_at INTEGER NOT NULL)",
  "ALTER TABLE knowledge ADD COLUMN source_uri TEXT NOT NULL DEFAULT ''",
  "ALTER TABLE knowledge ADD COLUMN skill_id TEXT REFERENCES skills(id)",
  "ALTER TABLE knowledge ADD COLUMN mission_id TEXT REFERENCES missions(id)",
  "CREATE INDEX evidence_skill ON evidence(skill_id, created_at)",
];

const _v3 = [
  "CREATE TABLE jobs (id TEXT PRIMARY KEY, mission_id TEXT NOT NULL REFERENCES missions(id), title TEXT NOT NULL CHECK(length(trim(title))>0), company TEXT NOT NULL DEFAULT '', location TEXT NOT NULL DEFAULT '', salary_min INTEGER, salary_max INTEGER, currency TEXT NOT NULL DEFAULT '', source_url TEXT NOT NULL DEFAULT '', status TEXT NOT NULL DEFAULT 'Saved' CHECK(status IN ('Saved','Applied','Closed')), fit_score INTEGER CHECK(fit_score BETWEEN 0 AND 100), description TEXT NOT NULL DEFAULT '', fingerprint TEXT, created_at INTEGER NOT NULL, CHECK(salary_min IS NULL OR salary_min >= 0), CHECK(salary_max IS NULL OR salary_max >= salary_min), UNIQUE(mission_id, fingerprint))",
  "CREATE TABLE job_requirements (id TEXT PRIMARY KEY, job_id TEXT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE, skill_id TEXT REFERENCES skills(id), skill_name TEXT NOT NULL CHECK(length(trim(skill_name))>0), created_at INTEGER NOT NULL, UNIQUE(job_id, skill_name))",
  "CREATE TABLE applications (id TEXT PRIMARY KEY, job_id TEXT NOT NULL REFERENCES jobs(id), status TEXT NOT NULL DEFAULT 'Saved' CHECK(status IN ('Saved','Applied','Screening','Interview','Offer','Rejected','Withdrawn')), applied_at TEXT NOT NULL DEFAULT '', notes TEXT NOT NULL DEFAULT '', created_at INTEGER NOT NULL)",
  "CREATE TABLE interviews (id TEXT PRIMARY KEY, application_id TEXT NOT NULL REFERENCES applications(id), date TEXT NOT NULL DEFAULT '', round TEXT NOT NULL DEFAULT '', result TEXT NOT NULL DEFAULT 'Pending' CHECK(result IN ('Pending','Pass','Partial','Fail')), strengths TEXT NOT NULL DEFAULT '', weaknesses TEXT NOT NULL DEFAULT '', new_learning_priorities TEXT NOT NULL DEFAULT '', created_at INTEGER NOT NULL)",
  "CREATE TABLE interview_questions (id TEXT PRIMARY KEY, interview_id TEXT NOT NULL REFERENCES interviews(id) ON DELETE CASCADE, skill_id TEXT REFERENCES skills(id), title TEXT NOT NULL CHECK(length(trim(title))>0), result TEXT NOT NULL DEFAULT 'Pending' CHECK(result IN ('Pending','Pass','Partial','Fail')), notes TEXT NOT NULL DEFAULT '', converted_at INTEGER, created_at INTEGER NOT NULL)",
  "CREATE TABLE learning_priorities (id TEXT PRIMARY KEY, mission_id TEXT NOT NULL REFERENCES missions(id), skill_id TEXT REFERENCES skills(id), source_question_id TEXT UNIQUE REFERENCES interview_questions(id), title TEXT NOT NULL CHECK(length(trim(title))>0), reason TEXT NOT NULL DEFAULT '', status TEXT NOT NULL DEFAULT 'Active' CHECK(status IN ('Active','Planned','Done','Dismissed')), created_at INTEGER NOT NULL)",
  "CREATE TABLE experiments (id TEXT PRIMARY KEY, project_id TEXT REFERENCES projects(id), title TEXT NOT NULL CHECK(length(trim(title))>0), hypothesis TEXT NOT NULL CHECK(length(trim(hypothesis))>0), market TEXT NOT NULL DEFAULT '', time_budget INTEGER NOT NULL DEFAULT 60 CHECK(time_budget>0), status TEXT NOT NULL DEFAULT 'Idea' CHECK(status IN ('Idea','Research','Running','Complete','Killed')), input TEXT NOT NULL DEFAULT '', experiment TEXT NOT NULL CHECK(length(trim(experiment))>0), result TEXT NOT NULL DEFAULT '', signal TEXT NOT NULL DEFAULT 'Unknown' CHECK(signal IN ('Unknown','Negative','Weak','Promising','Strong','Revenue')), next_action TEXT NOT NULL DEFAULT '', created_at INTEGER NOT NULL, CHECK(status='Killed' OR length(trim(next_action))>0))",
  "CREATE INDEX job_requirements_skill ON job_requirements(skill_id, skill_name)",
  "CREATE INDEX applications_job ON applications(job_id, created_at)",
  "CREATE INDEX interviews_application ON interviews(application_id, created_at)",
  "CREATE INDEX interview_questions_interview ON interview_questions(interview_id, created_at)",
  "CREATE INDEX learning_priorities_mission ON learning_priorities(mission_id, status)",
  "CREATE INDEX experiments_project ON experiments(project_id, created_at)",
  "ALTER TABLE strategy_versions ADD COLUMN version_number INTEGER NOT NULL DEFAULT 0",
  "ALTER TABLE strategy_versions ADD COLUMN previous_version_id TEXT REFERENCES strategy_versions(id)",
  "UPDATE strategy_versions SET version_number = (SELECT COUNT(*) FROM strategy_versions AS earlier WHERE earlier.strategy_id = strategy_versions.strategy_id AND (earlier.created_at < strategy_versions.created_at OR (earlier.created_at = strategy_versions.created_at AND earlier.rowid <= strategy_versions.rowid)))",
  "UPDATE strategy_versions SET previous_version_id = (SELECT previous.id FROM strategy_versions AS previous WHERE previous.strategy_id = strategy_versions.strategy_id AND previous.version_number = strategy_versions.version_number - 1)",
];

const _v4 = [
  "ALTER TABLE projects ADD COLUMN project_type TEXT NOT NULL DEFAULT 'Personal' CHECK(project_type IN ('Learning','Product','Career','IncomeExperiment','Content','Personal'))",
  "ALTER TABLE projects ADD COLUMN outcome_id TEXT REFERENCES outcomes(id)",
  "ALTER TABLE knowledge ADD COLUMN summary TEXT NOT NULL DEFAULT ''",
  "CREATE TABLE session_templates (id TEXT PRIMARY KEY, title TEXT NOT NULL CHECK(length(trim(title))>0), project_id TEXT REFERENCES projects(id), goal_id TEXT REFERENCES goals(id), milestone_id TEXT REFERENCES milestones(id), why TEXT NOT NULL DEFAULT '', input TEXT NOT NULL DEFAULT '', target TEXT NOT NULL DEFAULT '', priority INTEGER NOT NULL DEFAULT 2 CHECK(priority BETWEEN 1 AND 3), planned_minutes INTEGER NOT NULL DEFAULT 60 CHECK(planned_minutes>0), created_at INTEGER NOT NULL, CHECK(project_id IS NULL OR goal_id IS NULL))",
  "CREATE TABLE recurring_schedules (id TEXT PRIMARY KEY, template_id TEXT NOT NULL REFERENCES session_templates(id), title TEXT NOT NULL CHECK(length(trim(title))>0), weekdays TEXT NOT NULL CHECK(length(trim(weekdays))>0), local_time TEXT NOT NULL CHECK(length(local_time)=5), enabled INTEGER NOT NULL DEFAULT 1 CHECK(enabled IN (0,1)), start_date TEXT NOT NULL DEFAULT '', end_date TEXT NOT NULL DEFAULT '', created_at INTEGER NOT NULL)",
  "ALTER TABLE sessions ADD COLUMN recurring_schedule_id TEXT REFERENCES recurring_schedules(id)",
  "ALTER TABLE sessions ADD COLUMN occurrence_date TEXT",
  "CREATE UNIQUE INDEX recurring_session_occurrence ON sessions(recurring_schedule_id, occurrence_date) WHERE recurring_schedule_id IS NOT NULL",
  "CREATE INDEX recurring_schedules_template ON recurring_schedules(template_id, enabled)",
];

const _v5 = [
  "CREATE TABLE horizons (id TEXT PRIMARY KEY, vision_id TEXT NOT NULL REFERENCES visions(id), title TEXT NOT NULL CHECK(length(trim(title))>0), description TEXT NOT NULL DEFAULT '', start_date TEXT NOT NULL DEFAULT '', end_date TEXT NOT NULL DEFAULT '', status TEXT NOT NULL DEFAULT 'Active' CHECK(status IN ('Planned','Active','Completed','Archived')), sort_order INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL)",
  "ALTER TABLE strategies ADD COLUMN horizon_id TEXT REFERENCES horizons(id)",
  "ALTER TABLE strategies ADD COLUMN priority INTEGER NOT NULL DEFAULT 1 CHECK(priority BETWEEN 0 AND 3)",
  "ALTER TABLE strategies ADD COLUMN status TEXT NOT NULL DEFAULT 'Active' CHECK(status IN ('Planned','Active','Paused','Completed','Archived'))",
  "ALTER TABLE strategies ADD COLUMN effective_from TEXT NOT NULL DEFAULT ''",
  "ALTER TABLE strategies ADD COLUMN effective_to TEXT NOT NULL DEFAULT ''",
  "ALTER TABLE missions ADD COLUMN description TEXT NOT NULL DEFAULT ''",
  "ALTER TABLE missions ADD COLUMN start_date TEXT NOT NULL DEFAULT ''",
  "ALTER TABLE outcomes ADD COLUMN status TEXT NOT NULL DEFAULT 'Active' CHECK(status IN ('Planned','Active','Achieved','Missed','Archived'))",
  "CREATE TABLE initiatives (id TEXT PRIMARY KEY, mission_id TEXT NOT NULL REFERENCES missions(id), outcome_id TEXT REFERENCES outcomes(id), title TEXT NOT NULL CHECK(length(trim(title))>0), description TEXT NOT NULL DEFAULT '', status TEXT NOT NULL DEFAULT 'Active' CHECK(status IN ('Planned','Active','Paused','Completed','Archived')), priority INTEGER NOT NULL DEFAULT 1 CHECK(priority BETWEEN 0 AND 3), weekly_budget_minutes INTEGER NOT NULL DEFAULT 0 CHECK(weekly_budget_minutes>=0), created_at INTEGER NOT NULL)",
  "ALTER TABLE projects ADD COLUMN initiative_id TEXT REFERENCES initiatives(id)",
  "ALTER TABLE tasks ADD COLUMN description TEXT NOT NULL DEFAULT ''",
  "ALTER TABLE tasks ADD COLUMN status TEXT NOT NULL DEFAULT 'Backlog' CHECK(status IN ('Backlog','Planned','InProgress','Blocked','Done','Cancelled'))",
  "ALTER TABLE tasks ADD COLUMN scheduled_at INTEGER",
  "ALTER TABLE tasks ADD COLUMN estimated_minutes INTEGER CHECK(estimated_minutes IS NULL OR estimated_minutes>0)",
  "ALTER TABLE tasks ADD COLUMN actual_minutes INTEGER CHECK(actual_minutes IS NULL OR actual_minutes>=0)",
  "ALTER TABLE tasks ADD COLUMN priority INTEGER NOT NULL DEFAULT 2 CHECK(priority BETWEEN 1 AND 3)",
  "UPDATE tasks SET status = CASE WHEN done = 1 THEN 'Done' ELSE 'Backlog' END",
  "ALTER TABLE sessions ADD COLUMN task_id TEXT REFERENCES tasks(id)",
  "ALTER TABLE evidence ADD COLUMN type TEXT NOT NULL DEFAULT 'ManualVerification'",
  "ALTER TABLE evidence ADD COLUMN title TEXT NOT NULL DEFAULT ''",
  "ALTER TABLE evidence ADD COLUMN description TEXT NOT NULL DEFAULT ''",
  "ALTER TABLE evidence ADD COLUMN source TEXT NOT NULL DEFAULT 'User'",
  "ALTER TABLE evidence ADD COLUMN source_uri TEXT NOT NULL DEFAULT ''",
  "ALTER TABLE evidence ADD COLUMN confidence INTEGER NOT NULL DEFAULT 100 CHECK(confidence BETWEEN 0 AND 100)",
  "CREATE TABLE evidence_links (id TEXT PRIMARY KEY, evidence_id TEXT NOT NULL REFERENCES evidence(id) ON DELETE CASCADE, entity_type TEXT NOT NULL CHECK(entity_type IN ('Skill','Project','Outcome','Mission','Task','Session','Knowledge','Assumption','Review')), entity_id TEXT NOT NULL, relationship TEXT NOT NULL DEFAULT 'Supports', created_at INTEGER NOT NULL, UNIQUE(evidence_id, entity_type, entity_id, relationship))",
  "CREATE INDEX evidence_links_entity ON evidence_links(entity_type, entity_id)",
  "CREATE TABLE recommendations (id TEXT PRIMARY KEY, type TEXT NOT NULL CHECK(type IN ('Planning','Review','Knowledge','Career','Strategy','Assumption')), title TEXT NOT NULL CHECK(length(trim(title))>0), reason TEXT NOT NULL CHECK(length(trim(reason))>0), fact_basis TEXT NOT NULL DEFAULT '', inference TEXT NOT NULL DEFAULT '', expected_benefit TEXT NOT NULL DEFAULT '', risk TEXT NOT NULL DEFAULT '', confidence INTEGER NOT NULL CHECK(confidence BETWEEN 0 AND 100), suggested_action TEXT NOT NULL DEFAULT '', status TEXT NOT NULL DEFAULT 'Proposed' CHECK(status IN ('Proposed','Accepted','Modified','Rejected','Applied','Expired')), requires_user_approval INTEGER NOT NULL DEFAULT 1 CHECK(requires_user_approval IN (0,1)), created_at INTEGER NOT NULL, decided_at INTEGER)",
  "CREATE TABLE recommendation_evidence (recommendation_id TEXT NOT NULL REFERENCES recommendations(id) ON DELETE CASCADE, evidence_id TEXT NOT NULL REFERENCES evidence(id), PRIMARY KEY(recommendation_id, evidence_id))",
  "CREATE TABLE recommendation_targets (id TEXT PRIMARY KEY, recommendation_id TEXT NOT NULL REFERENCES recommendations(id) ON DELETE CASCADE, entity_type TEXT NOT NULL CHECK(entity_type IN ('Vision','Horizon','Strategy','Mission','Outcome','Initiative','Project','Task','Session','Skill','Assumption')), entity_id TEXT NOT NULL, relationship TEXT NOT NULL DEFAULT 'Affected', created_at INTEGER NOT NULL, UNIQUE(recommendation_id, entity_type, entity_id, relationship))",
  "CREATE INDEX recommendation_targets_entity ON recommendation_targets(entity_type, entity_id)",
  "CREATE TABLE review_decisions (id TEXT PRIMARY KEY, review_id TEXT NOT NULL, review_type TEXT NOT NULL CHECK(review_type IN ('Weekly','Monthly','Quarterly','Annual','EventDriven')), recommendation_id TEXT REFERENCES recommendations(id), decision TEXT NOT NULL CHECK(decision IN ('Accepted','Modified','Rejected','Deferred')), rationale TEXT NOT NULL DEFAULT '', created_at INTEGER NOT NULL)",
  "CREATE TABLE review_evidence (id TEXT PRIMARY KEY, review_id TEXT NOT NULL, review_type TEXT NOT NULL CHECK(review_type IN ('Weekly','Monthly','Quarterly','Annual','EventDriven')), evidence_id TEXT NOT NULL REFERENCES evidence(id), relationship TEXT NOT NULL DEFAULT 'Considered', created_at INTEGER NOT NULL, UNIQUE(review_id, review_type, evidence_id, relationship))",
  "ALTER TABLE period_reviews ADD COLUMN wins_json TEXT NOT NULL DEFAULT '[]'",
  "ALTER TABLE period_reviews ADD COLUMN problems_json TEXT NOT NULL DEFAULT '[]'",
  "ALTER TABLE period_reviews ADD COLUMN changed_assumptions_json TEXT NOT NULL DEFAULT '[]'",
  "ALTER TABLE period_reviews ADD COLUMN recommendations_json TEXT NOT NULL DEFAULT '[]'",
  "ALTER TABLE period_reviews ADD COLUMN user_decisions_json TEXT NOT NULL DEFAULT '[]'",
  "ALTER TABLE period_reviews ADD COLUMN carry_forward_json TEXT NOT NULL DEFAULT '[]'",
  "ALTER TABLE period_reviews ADD COLUMN next_priorities_json TEXT NOT NULL DEFAULT '[]'",
  "CREATE TABLE metrics (id TEXT PRIMARY KEY, title TEXT NOT NULL CHECK(length(trim(title))>0), category TEXT NOT NULL CHECK(category IN ('Mission','Skill','Career','Ownership','Capital','Product','Usage')), unit TEXT NOT NULL DEFAULT '', direction TEXT NOT NULL DEFAULT 'HigherIsBetter' CHECK(direction IN ('HigherIsBetter','LowerIsBetter','Neutral')), target_value REAL, created_at INTEGER NOT NULL)",
  "CREATE TABLE metric_snapshots (id TEXT PRIMARY KEY, metric_id TEXT NOT NULL REFERENCES metrics(id) ON DELETE CASCADE, value REAL NOT NULL, source TEXT NOT NULL DEFAULT 'Manual', source_uri TEXT NOT NULL DEFAULT '', confidence INTEGER NOT NULL DEFAULT 100 CHECK(confidence BETWEEN 0 AND 100), observed_at INTEGER NOT NULL, notes TEXT NOT NULL DEFAULT '', created_at INTEGER NOT NULL)",
  "CREATE INDEX metric_snapshots_metric_time ON metric_snapshots(metric_id, observed_at)",
  "CREATE TABLE readiness_weights (id TEXT PRIMARY KEY, dimension TEXT NOT NULL UNIQUE CHECK(dimension IN ('Knowledge','Implementation','Debugging','Application','Interview','Production')), weight REAL NOT NULL CHECK(weight>=0 AND weight<=1), updated_at INTEGER NOT NULL)",
  "INSERT INTO readiness_weights(id,dimension,weight,updated_at) VALUES ('Knowledge','Knowledge',0.15,0),('Implementation','Implementation',0.20,0),('Debugging','Debugging',0.20,0),('Application','Application',0.20,0),('Interview','Interview',0.15,0),('Production','Production',0.10,0)",
];

const _v6 = [
  "ALTER TABLE knowledge ADD COLUMN source_filename TEXT NOT NULL DEFAULT ''",
  "ALTER TABLE knowledge ADD COLUMN source_checksum TEXT NOT NULL DEFAULT ''",
  "ALTER TABLE knowledge ADD COLUMN source_size INTEGER",
  "ALTER TABLE knowledge ADD COLUMN source_modified_at INTEGER",
  "ALTER TABLE knowledge ADD COLUMN imported_at INTEGER",
  "ALTER TABLE knowledge ADD COLUMN source_mime TEXT NOT NULL DEFAULT ''",
  "ALTER TABLE knowledge ADD COLUMN managed_source_path TEXT NOT NULL DEFAULT ''",
  "CREATE TABLE knowledge_sections (id TEXT PRIMARY KEY, knowledge_id TEXT NOT NULL REFERENCES knowledge(id) ON DELETE CASCADE, ordinal INTEGER NOT NULL CHECK(ordinal>=0), title TEXT NOT NULL DEFAULT '', content TEXT NOT NULL, page_number INTEGER, start_offset INTEGER NOT NULL CHECK(start_offset>=0), end_offset INTEGER NOT NULL CHECK(end_offset>=start_offset), created_at INTEGER NOT NULL, UNIQUE(knowledge_id, ordinal))",
  "CREATE INDEX knowledge_sections_item ON knowledge_sections(knowledge_id, ordinal)",
  "INSERT INTO knowledge_sections(id,knowledge_id,ordinal,title,content,start_offset,end_offset,created_at) SELECT 'section-' || id,id,0,title,content,0,length(content),created_at FROM knowledge WHERE length(trim(content))>0",
  "CREATE TABLE knowledge_links (id TEXT PRIMARY KEY, knowledge_id TEXT NOT NULL REFERENCES knowledge(id) ON DELETE CASCADE, entity_type TEXT NOT NULL CHECK(entity_type IN ('Skill','Project','Mission','Outcome','Initiative','Task','Session','Evidence','Knowledge')), entity_id TEXT NOT NULL, relationship TEXT NOT NULL DEFAULT 'Related', confidence INTEGER NOT NULL DEFAULT 100 CHECK(confidence BETWEEN 0 AND 100), suggested INTEGER NOT NULL DEFAULT 0 CHECK(suggested IN (0,1)), created_at INTEGER NOT NULL, UNIQUE(knowledge_id, entity_type, entity_id, relationship))",
  "CREATE INDEX knowledge_links_entity ON knowledge_links(entity_type, entity_id)",
  "CREATE TABLE concepts (id TEXT PRIMARY KEY, title TEXT NOT NULL COLLATE NOCASE UNIQUE CHECK(length(trim(title))>0), description TEXT NOT NULL DEFAULT '', freshness_days INTEGER NOT NULL DEFAULT 180 CHECK(freshness_days>0), created_at INTEGER NOT NULL)",
  "CREATE TABLE knowledge_concepts (knowledge_id TEXT NOT NULL REFERENCES knowledge(id) ON DELETE CASCADE, concept_id TEXT NOT NULL REFERENCES concepts(id) ON DELETE CASCADE, relationship TEXT NOT NULL DEFAULT 'Mentions', confidence INTEGER NOT NULL DEFAULT 100 CHECK(confidence BETWEEN 0 AND 100), created_at INTEGER NOT NULL, PRIMARY KEY(knowledge_id, concept_id, relationship))",
  "CREATE VIRTUAL TABLE knowledge_fts USING fts5(title, summary, content, tags, content='knowledge', content_rowid='rowid')",
  "CREATE TRIGGER knowledge_fts_insert AFTER INSERT ON knowledge BEGIN INSERT INTO knowledge_fts(rowid,title,summary,content,tags) VALUES (new.rowid,new.title,new.summary,new.content,new.tags); END",
  "CREATE TRIGGER knowledge_fts_delete AFTER DELETE ON knowledge BEGIN INSERT INTO knowledge_fts(knowledge_fts,rowid,title,summary,content,tags) VALUES ('delete',old.rowid,old.title,old.summary,old.content,old.tags); END",
  "CREATE TRIGGER knowledge_fts_update AFTER UPDATE ON knowledge BEGIN INSERT INTO knowledge_fts(knowledge_fts,rowid,title,summary,content,tags) VALUES ('delete',old.rowid,old.title,old.summary,old.content,old.tags); INSERT INTO knowledge_fts(rowid,title,summary,content,tags) VALUES (new.rowid,new.title,new.summary,new.content,new.tags); END",
  "INSERT INTO knowledge_fts(rowid,title,summary,content,tags) SELECT rowid,title,summary,content,tags FROM knowledge",
];

const _v7 = [
  "CREATE TABLE knowledge_embeddings (knowledge_id TEXT PRIMARY KEY REFERENCES knowledge(id) ON DELETE CASCADE, model TEXT NOT NULL, dimensions INTEGER NOT NULL CHECK(dimensions>=8), vector_json TEXT NOT NULL, content_checksum TEXT NOT NULL, updated_at INTEGER NOT NULL)",
  "CREATE INDEX knowledge_embeddings_checksum ON knowledge_embeddings(content_checksum)",
];

const _v8 = [
  "CREATE TABLE planning_change_sets (id TEXT PRIMARY KEY, recommendation_id TEXT NOT NULL UNIQUE REFERENCES recommendations(id), title TEXT NOT NULL CHECK(length(trim(title))>0), status TEXT NOT NULL DEFAULT 'Draft' CHECK(status IN ('Draft','Approved','Applied','Rejected')), created_at INTEGER NOT NULL, decided_at INTEGER, applied_at INTEGER)",
  "CREATE TABLE planning_changes (id TEXT PRIMARY KEY, change_set_id TEXT NOT NULL REFERENCES planning_change_sets(id) ON DELETE CASCADE, action TEXT NOT NULL CHECK(action IN ('CreateSession','UpdateSession','CancelSession')), target_id TEXT, payload_json TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'Proposed' CHECK(status IN ('Proposed','Applied','Skipped')), created_at INTEGER NOT NULL)",
  "CREATE INDEX planning_changes_set ON planning_changes(change_set_id, status)",
  "CREATE TABLE strategy_events (id TEXT PRIMARY KEY, type TEXT NOT NULL CHECK(type IN ('JobOffer','MissionCompleted','JobLoss','SalaryChange','FirstCustomer','RevenueThreshold','AICapabilityShift','MarketContraction','Manual')), title TEXT NOT NULL CHECK(length(trim(title))>0), description TEXT NOT NULL DEFAULT '', impact TEXT NOT NULL DEFAULT '', occurred_at INTEGER NOT NULL, review_recommended INTEGER NOT NULL DEFAULT 1 CHECK(review_recommended IN (0,1)), reviewed_at INTEGER, created_at INTEGER NOT NULL)",
  "CREATE TABLE event_assumptions (event_id TEXT NOT NULL REFERENCES strategy_events(id) ON DELETE CASCADE, assumption_id TEXT NOT NULL REFERENCES assumptions(id), relationship TEXT NOT NULL DEFAULT 'MayAffect', confidence INTEGER NOT NULL DEFAULT 50 CHECK(confidence BETWEEN 0 AND 100), PRIMARY KEY(event_id, assumption_id))",
];

const _v9 = [
  "CREATE TABLE engine_allocations (id TEXT PRIMARY KEY, engine TEXT NOT NULL UNIQUE CHECK(engine IN ('Career','Ownership','Capital')), mode TEXT NOT NULL DEFAULT 'Maintenance' CHECK(mode IN ('Primary','Maintenance','Continuous','Paused','Archived')), weekly_budget_min INTEGER NOT NULL DEFAULT 0 CHECK(weekly_budget_min>=0), weekly_budget_max INTEGER NOT NULL DEFAULT 0 CHECK(weekly_budget_max>=weekly_budget_min), current_objective TEXT NOT NULL DEFAULT '', effective_from TEXT NOT NULL DEFAULT '', created_at INTEGER NOT NULL)",
  "CREATE TABLE customer_discoveries (id TEXT PRIMARY KEY, project_id TEXT REFERENCES projects(id), contact TEXT NOT NULL DEFAULT '', segment TEXT NOT NULL DEFAULT '', problem TEXT NOT NULL CHECK(length(trim(problem))>0), evidence TEXT NOT NULL DEFAULT '', signal TEXT NOT NULL DEFAULT 'Unknown' CHECK(signal IN ('Unknown','Negative','Weak','Promising','Strong')), next_action TEXT NOT NULL DEFAULT '', happened_at INTEGER NOT NULL, created_at INTEGER NOT NULL)",
  "CREATE INDEX customer_discoveries_project_time ON customer_discoveries(project_id, happened_at)",
  "CREATE TABLE revenue_entries (id TEXT PRIMARY KEY, project_id TEXT REFERENCES projects(id), amount REAL NOT NULL CHECK(amount>=0), currency TEXT NOT NULL DEFAULT 'USD', source TEXT NOT NULL DEFAULT '', occurred_at INTEGER NOT NULL, notes TEXT NOT NULL DEFAULT '', created_at INTEGER NOT NULL)",
  "CREATE INDEX revenue_entries_project_time ON revenue_entries(project_id, occurred_at)",
  "CREATE TABLE distribution_events (id TEXT PRIMARY KEY, project_id TEXT REFERENCES projects(id), channel TEXT NOT NULL CHECK(length(trim(channel))>0), kind TEXT NOT NULL DEFAULT 'Published', reach INTEGER NOT NULL DEFAULT 0 CHECK(reach>=0), leads INTEGER NOT NULL DEFAULT 0 CHECK(leads>=0), occurred_at INTEGER NOT NULL, notes TEXT NOT NULL DEFAULT '', created_at INTEGER NOT NULL)",
  "CREATE INDEX distribution_events_project_time ON distribution_events(project_id, occurred_at)",
  "CREATE TABLE capital_contributions (id TEXT PRIMARY KEY, account TEXT NOT NULL CHECK(length(trim(account))>0), amount REAL NOT NULL CHECK(amount>=0), currency TEXT NOT NULL DEFAULT 'USD', type TEXT NOT NULL DEFAULT 'Contribution' CHECK(type IN ('Contribution','Withdrawal','Return')), occurred_at INTEGER NOT NULL, notes TEXT NOT NULL DEFAULT '', created_at INTEGER NOT NULL)",
  "CREATE INDEX capital_contributions_time ON capital_contributions(occurred_at)",
  "CREATE TABLE net_worth_snapshots (id TEXT PRIMARY KEY, value REAL NOT NULL, currency TEXT NOT NULL DEFAULT 'USD', observed_at INTEGER NOT NULL, source TEXT NOT NULL DEFAULT 'Manual', notes TEXT NOT NULL DEFAULT '', created_at INTEGER NOT NULL)",
  "CREATE INDEX net_worth_snapshots_time ON net_worth_snapshots(observed_at)",
];

const _v10 = [
  "ALTER TABLE jobs ADD COLUMN seniority TEXT NOT NULL DEFAULT ''",
  "ALTER TABLE jobs ADD COLUMN domain TEXT NOT NULL DEFAULT ''",
  "ALTER TABLE jobs ADD COLUMN employment_type TEXT NOT NULL DEFAULT ''",
  "ALTER TABLE jobs ADD COLUMN imported_at INTEGER",
  "UPDATE jobs SET imported_at = created_at WHERE imported_at IS NULL",
  "ALTER TABLE job_requirements ADD COLUMN requirement_type TEXT NOT NULL DEFAULT 'Mentioned' CHECK(requirement_type IN ('Required','Preferred','Mentioned'))",
  "ALTER TABLE job_requirements ADD COLUMN years_required REAL",
  "ALTER TABLE job_requirements ADD COLUMN source_excerpt TEXT NOT NULL DEFAULT ''",
  "ALTER TABLE job_requirements ADD COLUMN confidence INTEGER NOT NULL DEFAULT 60 CHECK(confidence BETWEEN 0 AND 100)",
];

const _v11 = [
  "CREATE TABLE recommendation_decisions (id TEXT PRIMARY KEY, recommendation_id TEXT NOT NULL REFERENCES recommendations(id) ON DELETE CASCADE, decision TEXT NOT NULL CHECK(decision IN ('Accepted','Modified','Rejected','Deferred')), rationale TEXT NOT NULL DEFAULT '', created_at INTEGER NOT NULL)",
  "CREATE INDEX recommendation_decisions_recommendation ON recommendation_decisions(recommendation_id, created_at)",
  "INSERT INTO recommendation_decisions(id,recommendation_id,decision,rationale,created_at) SELECT 'migrated-' || id,id,CASE WHEN status='Expired' THEN 'Rejected' ELSE status END,'Migrated decision history',decided_at FROM recommendations WHERE decided_at IS NOT NULL AND status IN ('Accepted','Modified','Rejected','Expired')",
];

const _v12 = [
  "CREATE TABLE knowledge_search_events (id TEXT PRIMARY KEY, query TEXT NOT NULL, result_count INTEGER NOT NULL CHECK(result_count>=0), top_score REAL, duration_ms INTEGER NOT NULL CHECK(duration_ms>=0), searched_at INTEGER NOT NULL)",
  "CREATE INDEX knowledge_search_events_time ON knowledge_search_events(searched_at)",
  "CREATE TABLE context_sharing_audit (id TEXT PRIMARY KEY, provider_name TEXT NOT NULL, operation TEXT NOT NULL, categories_json TEXT NOT NULL DEFAULT '[]', record_count INTEGER NOT NULL DEFAULT 0 CHECK(record_count>=0), purpose TEXT NOT NULL DEFAULT '', user_approved INTEGER NOT NULL DEFAULT 0 CHECK(user_approved IN (0,1)), created_at INTEGER NOT NULL)",
];

const _v13 = [
  "ALTER TABLE sessions ADD COLUMN blocked INTEGER NOT NULL DEFAULT 0 CHECK(blocked IN (0,1))",
  "ALTER TABLE sessions ADD COLUMN blocked_reason TEXT NOT NULL DEFAULT ''",
  "CREATE INDEX sessions_blocked ON sessions(blocked, planned_start)",
];
