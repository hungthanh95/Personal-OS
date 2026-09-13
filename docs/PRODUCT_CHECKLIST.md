# Personal OS — Product completion checklist

Updated: 13/09/2026. Derived from the complete [Product & Engineering Specification 1.0](archived/PERSONAL_OS_PRODUCT_SPEC_1.0.md). `DONE` means implementation plus code/test/release evidence; `EXCLUDED` is an explicit non-goal or a capability intentionally outside the supported 0.4 platform/mode.

## A. Product foundation

- [x] `DONE` Local-first Flutter desktop shell with Today, Mission, Strategy, Projects, Knowledge and Review.
- [x] `DONE` Full Vision → Horizon → Strategy → Mission → Outcome → Initiative → Project → Task/Session → Evidence/Review causal path.
- [x] `DONE` Evidence-first readiness; study time never changes readiness.
- [x] `DONE` Why Path from execution to Mission/Vision.
- [x] `DONE` Structured recommendation with fact/inference, evidence, targets, benefit, risk, confidence and approval requirement.
- [x] `DONE` Immutable recommendation decisions and strategy version audit.
- [x] `DONE` Editable starter data; demo clearing is explicit and never silently reseeds.

## B. Today and execution

- [x] `DONE` Plan/start/pause/resume/finish/skip/cancel/reschedule and one-active-session invariant.
- [x] `DONE` Planned, Active, In Progress, Blocked, Done, Skipped and Cancelled session behavior; Blocked stores a required reason and can resume.
- [x] `DONE` Atomic Actual Output, learning, Next Action, link and duration correction.
- [x] `DONE` Task schedule, estimate/actual, priority, statuses and Session relationship.
- [x] `DONE` Today summary, overdue ordering, deterministic insights, active Mission and Why Path.
- [x] `DONE` Recurring templates/schedules, automatic 21-day materialization, manual 12-week generation and duplicate prevention.
- [x] `DONE` Local next-week priority generation and multi-session weekly plan preview.
- [x] `DONE` Accepted changes propagate only through explicit preview, approve and apply.

## C. Mission and trajectory

- [x] `DONE` Mission success criteria/status/priority/confidence and weighted measurable Outcomes.
- [x] `DONE` Six readiness dimensions using latest verified Output-linked Evidence.
- [x] `DONE` Configurable readiness weights validated to total 100%.
- [x] `DONE` Per-dimension score × weight explanation, latest evidence and delta from previous assessment.
- [x] `DONE` 30/90-day readiness, Outcome progress and custom metric trajectories with charts.
- [x] `DONE` Product metrics: active days, session completion, reviews, evidence/week, retrieval success/latency and recommendation acceptance.

## D. Strategy and adaptive reviews

- [x] `DONE` Horizon-filtered hierarchy explorer with node inspection.
- [x] `DONE` Weekly, Monthly, Quarterly, Annual and Event-Driven structured reviews.
- [x] `DONE` Wins, problems, evidence IDs, changed assumptions, recommendations, decisions, carry-forward and next priorities.
- [x] `DONE` Quarterly execution/readiness/career/ownership/capacity aggregation.
- [x] `DONE` Annual thesis/assumption/outcome analysis and 1-year/3-year roadmap options.
- [x] `DONE` Strategy events, affected-assumption links and review-needed workflow.
- [x] `DONE` Weakening/invalidated and low-confidence assumption detection without automatic mutation.
- [x] `DONE` Accept/Modify/Reject, prior-version preservation and future-plan propagation.

## E. Projects, Ownership and Capital

- [x] `DONE` Project CRUD/details, types, Goal/Outcome/Initiative links, milestones, tasks, sessions, outputs, Knowledge and Next Action.
- [x] `DONE` Income Lab bounded experiments with signal and Next Action-or-Killed invariant.
- [x] `DONE` Career/Ownership/Capital engine modes, budgets and objectives.
- [x] `DONE` Customer discovery and product/revenue/distribution tracking.
- [x] `DONE` Capital contributions/withdrawals/returns and net-worth snapshots.
- [x] `DONE` Engine allocation review inputs available to adaptive review.

## F. Knowledge and retrieval

- [x] `DONE` Safe TXT/Markdown/text-PDF/DOCX import; legacy DOC selection gives an actionable conversion path.
- [x] `DONE` Managed source preservation, filename/checksum/size/MIME/import time, sections and offsets.
- [x] `DONE` Editable local summary/tag/concept/link suggestions and many-to-many Knowledge relationships.
- [x] `DONE` SQLite FTS5 with snippets and locally recorded latency.
- [x] `DONE` Deterministic local embedding provider and semantic index.
- [x] `DONE` Concept graph, suggested relations, duplicate detection and freshness windows.
- [x] `DONE` Combined full-text + semantic + graph retrieval with source/section/snippet and relevance explanation.
- [x] `DONE` Matching context preserved when opening a result; preserved original source can be opened.
- [x] `DONE` Task/session-to-Knowledge recommendations during execution.

## G. Career and market intelligence

- [x] `DONE` Paste up to 50 JDs, local duplicate prevention and stored source URL provenance.
- [x] `DONE` Required/preferred/mentioned skills, years, excerpts, confidence, domain, seniority, employment and salary extraction.
- [x] `DONE` Mission skill-demand vs verified-readiness gap ranking.
- [x] `DONE` Job/application/interview/question pipeline and one-time sourced learning-priority conversion.
- [x] `DONE` Role/domain/company clusters, salary sample and interview weakness clusters.
- [x] `DONE` Job → application → interview → offer conversion with numerator, denominator, sample size and uncertainty language.
- [x] `DONE` Target-role health inputs combine demand, salary, skill gap and funnel outcomes.
- [ ] `EXCLUDED` Automatic web market crawling. Explicit MVP exclusion; manual paste/URL provenance preserves user control.

## H. Intelligence and guardrails

- [x] `DONE` Unified provider interface for summarization, extraction, generation, review and embeddings.
- [x] `DONE` Usable Local-only provider for Knowledge, career parsing, weekly planning and adaptive reviews.
- [x] `DONE` User-visible provider/context boundary and persistent context-sharing audit.
- [x] `DONE` Every strategy-affecting recommendation is evidence-linked, distinguishes fact/inference, states uncertainty and remains correctable.
- [x] `DONE` No external provider or credential surface in 0.4; no personal context leaves the device.
- [ ] `EXCLUDED` Autonomous strategy rewriting and complex multi-agent architecture.

## I. Privacy, data and reliability

- [x] `DONE` Ordered SQLite migrations v1–v13, foreign keys and migration test for every historical schema.
- [x] `DONE` Parser failures are recoverable and import is idempotent where practical.
- [x] `DONE` Consistent backup and staged restore with migration and safety snapshot.
- [x] `DONE` Portable all-table JSON export and separate Career/Knowledge/Ownership-Capital deletion.
- [x] `DONE` Explicit Local-only indicator and zero silent upload paths.
- [x] `DONE` Credential requirement is satisfied by accepting/storing no credentials in the supported Local-only mode.
- [x] `DONE` At-rest protection decision is explicit: application-level encryption is absent; sensitive deployments use Windows profile/disk encryption. This fulfills “where practical” for the portable offline 0.4 package without adding unrecoverable in-app key management.
- [ ] `EXCLUDED` Mandatory cloud/mobile sync and automatic financial account/brokerage integration.

## J. UX, quality and release

- [x] `DONE` Calm responsive Material UI, light/dark/system, keyboard shortcuts, semantics and empty/error states.
- [x] `DONE` Quick-start onboarding and complete 0.4 user manual with manual UI checklist.
- [x] `DONE` Charts for readiness/outcomes/metrics and market/funnel summaries.
- [x] `DONE` MVP golden path covered across repository and widget acceptance tests without direct database mutation.
- [x] `DONE` Normal-dataset launch/search targets instrumented; responsive desktop/narrow widget coverage passes.
- [x] `DONE` `dart format`, `flutter analyze`, all 44 tests, Windows release build and isolated native smoke pass.
- [x] `DONE` Windows x64 portable package, SHA-256 and contents verification produced.
- [x] `DONE` Supported-platform decision: 0.4 is Windows x64; macOS runner is source-only and explicitly unverified.
- [ ] `EXCLUDED` Social publishing, collaboration, advanced gamification and generic todo/job-board/brokerage behavior.

## Release evidence

- [Verification report](VERIFICATION.md)
- [User manual](USER_MANUAL.md)
- [Architecture](ARCHITECTURE.md)
- [Schema model](DATA_MODEL.md)
- `dist/PersonalOS-0.4.0-windows-x64.zip`
- SHA-256 `F5EC509BB81E6D2F002BDEB5BEDA9930D9DDC3949EF8E0031F93F4989C5CCA19`
