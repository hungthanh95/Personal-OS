# Data model — schema v13

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
| System | `inbox`, `weekly_reviews`, `settings`, `context_sharing_audit` |

## Core invariants

- Session states: Planned, Active, In Progress, Blocked, Done, Skipped and Cancelled. `Blocked` is represented by an indexed flag over the compatible `IN_PROGRESS` storage state and requires a blocker/next action. Done/Skipped/Cancelled are terminal. Only one Active row exists.
- Focus duration is accumulated from intervals. Manual correction replaces intervals with a point-attributed total. Cancelled sessions are excluded from the completion denominator.
- Task states include Backlog, Planned, InProgress, Blocked, Done and Cancelled with schedule, estimate, actual and priority fields.
- Readiness uses only the latest verified Evidence for each of six dimensions. Configured weights must be nonnegative and total 1.0. Evidence history remains append-only.
- Outcome progress is weighted and capped at its target. Time spent alone never changes readiness or Outcome progress.
- Recommendation decisions and strategy versions are immutable audit records. Applying an accepted recommendation is separate from accepting it.
- Recurring occurrences are unique by schedule/date; future Planned occurrences can be rebuilt without touching completed history.
- Document imports deduplicate by source path/checksum. Managed source deletion is allowed only inside the app-owned source directory.
- A failed or partial interview question can be converted once to a sourced learning priority. Experiments require Next Action unless Killed.

## Migrations

v1 created execution; v2 strategy/evidence; v3 career/experiments; v4 recurrence/project types; v5 full causal graph and structured recommendations; v6 source-aware Knowledge/FTS/concepts; v7 embeddings; v8 planning propagation/events; v9 Ownership/Capital; v10 richer JD extraction; v11 global recommendation audit; v12 retrieval/product telemetry and context audit; v13 Blocked sessions. Automated coverage upgrades every historical version 1–12 to v13 while preserving a sentinel setting.
