# Data model — schema v15

All persisted entities use text primary keys. Timestamps are epoch milliseconds; local dates are interpreted at the UI boundary. Optional relationships remain nullable so users can capture incomplete work and classify it later.

## Main graph

| Area | Tables |
| --- | --- |
| Direction | `visions`, `horizons`, `strategies`, `missions`, `outcomes`, `initiatives` |
| Execution | `life_areas`, `goals`, `projects`, `milestones`, `tasks`, `sessions`, `focus_intervals`, `session_templates`, `recurring_schedules` |
| Evidence | `outputs`, `skills`, `evidence`, `evidence_links`, `readiness_weights`, `metrics`, `metric_snapshots` |
| Adaptation | `assumptions`, `strategy_events`, `event_assumptions`, `period_reviews`, `recommendations`, `recommendation_evidence`, `recommendation_targets`, `recommendation_decisions`, `review_evidence`, `review_decisions`, `strategy_versions`, `strategy_proposals`, `planning_change_sets`, `planning_changes` |
| Knowledge | `knowledge`, `knowledge_sections`, `knowledge_fts`, `knowledge_embeddings`, `knowledge_links`, `concepts`, `knowledge_concepts`, `knowledge_search_events` |
| Career | `jobs`, `job_requirements`, `applications`, `interviews`, `interview_questions`, `learning_priorities` |
| Ownership | `experiments`, `engine_allocations`, `customer_discoveries`, `revenue_entries`, `distribution_events`, `capital_contributions`, `net_worth_snapshots` |
| System | `inbox`, `weekly_reviews`, `settings`, `context_sharing_audit`, `workspace_entity_sources`, `workspace_file_index`, `workspace_operations` |

## Core invariants

- New Session behavior uses Planned, Done, Skipped and Cancelled. Completion is projected from a stable-ID Obsidian occurrence note only after its planned end and requires `status: done` plus a concrete Output. Legacy Active/In Progress/Blocked and focus-interval fields remain readable for migration compatibility but are no longer written or used by product metrics.
- `planned_minutes` is calendar allocation only. Cancelled sessions are excluded from the completion denominator; overdue Planned sessions are reported separately as awaiting a result.
- Task states include Backlog, Planned, InProgress, Blocked, Done and Cancelled with schedule, estimate, actual and priority fields.
- Readiness uses only the latest verified Evidence for each of six dimensions. Configured weights must be nonnegative and total 1.0. Evidence history remains append-only.
- Outcome progress is weighted and capped at its target. Time spent alone never changes readiness or Outcome progress.
- Recommendation decisions and strategy versions are immutable audit records. Applying an accepted recommendation is separate from accepting it.
- Recurring occurrences are unique by schedule/date; future Planned occurrences can be rebuilt without touching completed history.
- Mission, Project and Task have one stable-ID Markdown source each. `workspace_entity_sources` maps identity to the current path and records source errors; a successful scan updates the SQLite projection and follows renames. Source deletion is inferred only after a successful vault scan, and transition-mode rows are retained with an actionable error.
- Markdown writers patch owned frontmatter and known sections with an expected revision. User-defined sections remain intact. Planning batches and session disposition changes use `workspace_operations` so an interrupted write can be detected and repaired.
- Document imports deduplicate by source path/checksum. Managed source deletion is allowed only inside the app-owned source directory.
- A failed or partial interview question can be converted once to a sourced learning priority. Experiments require Next Action unless Killed.

## Migrations

v1 created execution; v2 strategy/evidence; v3 career/experiments; v4 recurrence/project types; v5 full causal graph and structured recommendations; v6 source-aware Knowledge/FTS/concepts; v7 embeddings; v8 planning propagation/events; v9 Ownership/Capital; v10 richer JD extraction; v11 global recommendation audit; v12 retrieval/product telemetry and context audit; v13 Blocked sessions; v14 adds Obsidian session-note projection, incremental file index, reconciliation state and recoverable workspace-operation records; v15 adds stable source mapping for Mission, Project and Task Markdown migration.
