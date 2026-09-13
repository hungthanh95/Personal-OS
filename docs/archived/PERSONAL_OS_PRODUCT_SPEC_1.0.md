# Personal OS — Product & Engineering Specification

**Version:** 1.0  
**Status:** Development-ready blueprint  
**Primary goal:** Build a personal strategy and execution system that connects long-term direction to quarterly strategy, weekly planning, daily execution, measurable evidence, and adaptive reviews.

---

## 1. Product Vision

Personal OS is **not** primarily a todo app, calendar, habit tracker, note app, or chatbot.

It is a **personal strategy and execution system** that continuously answers:

1. Where am I trying to go?
2. What matters most right now?
3. What should I do today?
4. Why does this task matter?
5. Am I actually improving?
6. Is my roadmap still valid?
7. What should change when the market, AI capability, technology, or my situation changes?

Core loop:

```text
Vision
  ↓
Long-Term Strategy
  ↓
Annual Roadmap
  ↓
Quarterly Strategy
  ↓
90-Day Mission
  ↓
Weekly Plan
  ↓
Daily Execution
  ↓
Evidence
  ↓
Review
  ↓
Strategy Update
  └──────────────→ back into roadmap
```

Product philosophy:

> Plan → Execute → Observe Reality → Adapt.

---

## 2. Core Principles

### 2.1 Outcome-first

Do not reward activity alone.

Bad:

```text
Studied C++ for 5 hours.
Progress +10%.
```

Good:

```text
Modern C++ / Ownership

Knowledge          ✓
Coding             ✓
Interview answer   ✓
Project usage      ○
Real interview     ○

Readiness: 70%
```

Progress should be driven by **evidence**, not only time spent.

### 2.2 Strategy before tasks

Every meaningful task/session should be traceable upward:

```text
Task
  ↓ why?
Project
  ↓ why?
Outcome
  ↓ why?
Mission
  ↓ why?
Strategy
  ↓ why?
Vision
```

Example:

```text
CodeCrafters TCP challenge
        ↓
Systems Programming
        ↓
C++ / Linux Readiness
        ↓
Job Switch Mission
        ↓
Higher Income
        ↓
Career Engine
        ↓
Financial Independence
```

### 2.3 Adaptive roadmap

The app must support:

- Quarterly Strategy Review.
- Annual Roadmap Review.
- Event-Driven Review.
- Strategy version history.
- Assumption tracking.
- Evidence-based reprioritization.

The app must ask:

> Is this still worth doing?

not only:

> Did you complete it?

### 2.4 Evidence over gamification

Motivation should come mainly from visible trajectory, capability growth, artifacts, market feedback, and completed outcomes.

Streaks are optional. XP/levels must never become the primary progress model.

### 2.5 Human in control

AI may summarize, detect gaps, recommend reprioritization, connect knowledge, propose roadmap changes, analyze job-market evidence, and generate weekly plans.

AI must not silently:

- rewrite strategy,
- change priorities,
- archive missions,
- mark unsupported evidence as valid,
- change long-term financial assumptions.

Strategic changes require explicit user approval.

---

## 3. Long-Term Strategy Model

Default engine model:

```text
2043 VISION
Financial Independence
        │
        ├── Career Engine
        ├── Ownership Engine
        └── Capital Engine
```

### Career Engine

Purpose:

- increase market value,
- increase salary,
- maintain employability,
- build scarce technical capability,
- create professional optionality.

### Ownership Engine

Purpose:

- build products/IP,
- create recurring revenue,
- build distribution,
- accumulate equity/ownership,
- create assets not directly tied to hours worked.

### Capital Engine

Purpose:

- save,
- invest,
- compound capital,
- improve financial resilience.

MVP only needs high-level contribution and net-worth snapshots. Personal OS is not a brokerage app.

---

## 4. Seed Strategy for Current User

This is sample seed data and must **not** be hard-coded.

```text
VISION
Financial Independence by 2043

CURRENT LIFE PHASE
Career Engine       PRIMARY
Ownership Engine    MAINTENANCE
Capital Engine      CONTINUOUS
```

Reason:

> Primary 6–12 month objective is to switch to a significantly higher-paying role.

### Primary Mission

```text
Mission: Job Switch — Higher Salary
Horizon: 6–12 months
Priority: P0
Status: Active
```

Target capability areas:

- Modern C++.
- Linux / OS / Networking.
- Systems Programming.
- CodeCrafters.
- Embedded/System Design.
- Automotive Architecture.
- AUTOSAR Adaptive / QNX.
- Debugging.
- English communication.
- Interview readiness.
- Job pipeline execution.

Maintenance initiatives:

- Trace Inspector.
- DiagRCA.
- AI × Automotive experiments.
- Income Lab.
- Distribution.

---

## 5. Seed Weekly Schedule

### Technical Core — 21:00–22:00

```text
Monday      Modern C++
Tuesday     Linux / OS / Networking
Wednesday   CodeCrafters Systems Programming
Thursday    AUTOSAR Adaptive / QNX / Automotive Architecture
Friday      Embedded System Design + Debugging + Interview
Saturday    Deep Applied Technical; prefer CodeCrafters/C++/Linux
Sunday      Weekly Technical Review + Mock Interview
```

### English — 22:25–23:25

Daily 60-minute session.

Suggested structure:

```text
10 min Listening
10 min Grammar or vocabulary
20 min Speaking / role-play
10 min Correction + re-speaking
 6 min Shadowing
 4 min Recall
```

### Career / Income Sprint — 23:30–00:00

```text
Monday      C++ Interview / Coding
Tuesday     Income Lab
Wednesday   LeetCode / Interview
Thursday    AI × Automotive Product
Friday      Job Pipeline
```

Weekend:

```text
Saturday morning   Income Lab Build Day
Sunday morning     Income Lab Market Day
```

---

## 6. Core Domain Model

Primary hierarchy:

```text
Vision
  ↓
Horizon
  ↓
Strategy
  ↓
Mission
  ↓
Outcome
  ↓
Initiative
  ↓
Project
  ↓
Task / Session
  ↓
Evidence
```

Cross-linked entities:

```text
Skill
Knowledge Item
Metric
Habit
Experiment
Job
Application
Interview
Artifact
Assumption
Review
Strategy Version
```

---

## 7. Entity Definitions

### Vision

```text
id
title
description
target_date
status
created_at
updated_at
```

### Strategy

```text
id
vision_id
title
description
priority
status
effective_from
effective_to
strategy_version_id
```

### Mission

```text
id
strategy_id
title
description
priority
status
start_date
target_date
confidence
progress
success_criteria
```

### Outcome

```text
id
mission_id
title
target
current_value
unit
weight
status
```

### Initiative

Examples:

```text
Modern C++ Preparation
Systems Programming
English
Job Pipeline
Trace Inspector
Income Lab
```

### Project

```text
id
initiative_id
title
purpose
status
progress
start_date
target_date
linked_skill_ids[]
linked_goal_ids[]
```

### Task

```text
id
project_id
title
description
status
scheduled_at
estimated_minutes
actual_minutes
priority
why_path
```

### Session

```text
id
task_id
started_at
ended_at
planned_minutes
actual_minutes
status
input
actual_output
next_action
notes
```

Statuses:

```text
Planned
InProgress
Done
Skipped
Blocked
```

### Evidence

Types:

```text
Code
TestPass
GitCommit
Artifact
InterviewAnswer
InterviewResult
Benchmark
Diagram
Note
ExternalFeedback
JobMarketSignal
RevenueSignal
PublishedContent
ManualVerification
```

Fields:

```text
id
type
title
description
source
source_uri
created_at
verified
confidence
linked_skill_ids[]
linked_project_ids[]
linked_outcome_ids[]
```

### Skill

```text
id
name
category
target_level
estimated_readiness
confidence
last_evaluated_at
```

Recommended readiness dimensions:

```text
Knowledge
Implementation
Debugging
Application
Interview
Production
```

### Knowledge Item

Supported input:

- text,
- Markdown,
- PDF,
- DOC/DOCX.

Fields:

```text
id
title
source_type
source_uri
raw_text
summary
tags[]
linked_skill_ids[]
linked_project_ids[]
linked_mission_ids[]
created_at
updated_at
```

Optional derived data:

```text
chunks[]
embeddings[]
entities[]
concept_links[]
```

### Job

```text
id
company
title
location
salary_min
salary_max
currency
source_url
status
fit_score
created_at
```

### Application

Statuses:

```text
Saved
Applied
Screening
Interview
Offer
Rejected
Withdrawn
```

### Interview

```text
id
application_id
date
round
result
questions[]
strengths[]
weaknesses[]
new_learning_priorities[]
```

### Experiment

Used by Income Lab and product validation.

```text
id
title
hypothesis
market
time_budget
status
input
experiment
result
signal
next_action
```

Signal:

```text
Unknown
Negative
Weak
Promising
Strong
Revenue
```

### Assumption

```text
id
strategy_id
statement
importance
confidence
last_validated_at
status
supporting_evidence_ids[]
contradicting_evidence_ids[]
```

Statuses:

```text
Unverified
Supported
Validated
Weakening
Invalidated
```

### Review

Types:

```text
Daily
Weekly
Monthly
Quarterly
Annual
EventDriven
```

Fields:

```text
id
type
period_start
period_end
summary
wins[]
problems[]
evidence_ids[]
changed_assumptions[]
recommendations[]
user_decisions[]
created_at
```

### Strategy Version

```text
id
version_number
effective_date
title
snapshot_json
change_reason
previous_version_id
```

Never overwrite strategic history.

---

## 8. Evidence-Based Readiness

Do not derive readiness from study hours alone.

Recommended configurable formula:

```text
Skill Readiness =
  Knowledge      * 0.15
+ Implementation * 0.20
+ Debugging      * 0.20
+ Application    * 0.20
+ Interview      * 0.15
+ Production     * 0.10
```

Examples:

```text
CodeCrafters test pass
→ Implementation evidence

Correct answer in real interview
→ Interview evidence

Used concept in real project
→ Application + Production evidence

Solved debugging scenario
→ Debugging evidence
```

MVP may start with manual dimension scores plus evidence counts.

Production should use explainable scoring and expose why a readiness number changed.

---

## 9. Primary Screen Architecture

MVP should have only six top-level screens:

```text
01 Today
02 Mission
03 Strategy
04 Projects
05 Knowledge
06 Review
```

Specialized modules come later.

---

## 10. Screen 01 — Today

Purpose:

> What should I do today, and why does it matter?

Example:

```text
CURRENT MISSION
🚀 Job Switch — Higher Salary
Current phase: Interview Preparation
Status: On Track

THIS WEEK
Technical       8 / 10 h
English         5 / 7
Interview       3 / 5
Applications    2 / 5

TONIGHT
21:00  Modern C++             [Start]
22:25  English                [Start]
23:30  C++ Interview          [Start]

WHY THIS MATTERS
Modern C++
→ Interview Readiness
→ Job Switch
→ Higher Income
→ Career Engine
→ Financial Independence

TRAJECTORY
Career       ↑
Ownership    →
Capital      ↑
```

MVP behavior:

- show active mission,
- show today's sessions,
- start/finish/skip session,
- capture Actual Output,
- capture Next Action,
- show Why Path,
- show weekly summary.

---

## 11. Screen 02 — Mission

Purpose: Track the active short-term mission.

Example:

```text
JOB SWITCH — HIGHER SALARY

Status       On Track
Priority     P0
Confidence   72%
Progress     58%

READINESS
Modern C++       72%
Linux/System     61%
CodeCrafters     74%
Automotive       80%
System Design    65%
English          70%
Interview        53%
Job Pipeline     35%
```

Sections:

1. Mission summary.
2. Success criteria.
3. Outcomes.
4. Skill readiness.
5. Current blockers.
6. Recent evidence.
7. Job pipeline.
8. Recommended priorities.

---

## 12. Screen 03 — Strategy

Purpose: Show the causal chain from long-term vision to current action.

```text
                     2043 VISION
               Financial Independence
                         │
        ┌────────────────┼───────────────┐
        │                │               │
      CAREER          OWNERSHIP        CAPITAL
        │                │
        │                └── Trace Inspector
        │
     JOB SWITCH
        │
 ┌──────┼──────────┬───────────┐
C++   Linux     Automotive   English
```

Required behavior:

- zoom by horizon,
- select node,
- inspect linked evidence,
- inspect assumptions,
- see strategy version history,
- propose strategy change,
- require explicit approval.

---

## 13. Screen 04 — Projects

Example:

```text
CodeCrafters — Systems Programming

Purpose
Improve C++ + Linux capability for Job Switch.

Linked skills
C++
Networking
Linux
Systems Programming
Debugging

Latest milestone
HTTP server — request parsing

Evidence
12 tests passed
3 concepts mastered

Next
Concurrency / connection handling
```

Project types:

```text
Learning
Product
Career
IncomeExperiment
Content
Personal
```

---

## 14. Screen 05 — Knowledge

Purpose: Build a knowledge base that both user and AI can retrieve.

MVP requirements:

- import TXT,
- import Markdown,
- import PDF,
- import DOC/DOCX,
- preserve source metadata,
- extract text,
- keyword search,
- link to skills/projects/missions,
- show original source context.

Important:

The KB must **not** become a hidden AI-only vector store.

User must be able to:

- browse,
- search,
- open source,
- inspect relationships,
- edit metadata,
- understand why AI retrieved an item.

Example:

```text
Knowledge Item: std::move
Source: Effective Modern C++
Linked Skill: Modern C++
Applied In: CodeCrafters HTTP Server
Evidence: commit #ab213
Supports: Job Switch Mission
```

---

## 15. Screen 06 — Review

Tabs:

```text
Weekly
Monthly
Quarterly
Annual
Event-Driven
```

### Weekly Review

Questions:

```text
What did I plan?
What did I complete?
What evidence did I create?
What was blocked?
What skill improved?
What slipped?
What should change next week?
```

Output:

- weekly summary,
- key evidence,
- skill movement,
- missed sessions,
- carry-forward items,
- next-week priorities.

---

## 16. Quarterly Strategy Review

This is a core feature.

Purpose:

> Determine whether the current 90-day plan still makes sense.

Inputs:

- mission progress,
- skill readiness,
- job-market evidence,
- interview outcomes,
- salary data,
- AI capability changes,
- technology trends,
- product progress,
- personal capacity,
- changed assumptions.

Example:

```text
Q4 STRATEGY REVIEW

CURRENT MISSION
Job Switch — Higher Salary

STATUS
On Track

MARKET CHANGES
↑ C++ / Linux
→ Automotive
↑ AI-assisted engineering
↓ Generic coding work

PERSONAL PROGRESS
C++          72%
Linux        61%
Interview    53%
Applications 35%

ASSUMPTION CHANGE
AI coding capability improving faster than expected.

RECOMMENDED ALLOCATION

Before
C++              30
Linux            25
AUTOSAR          20
AI               10

Next Quarter
C++              25
Linux            25
System Design    20
AI Engineering   20
AUTOSAR          10
```

Actions:

```text
Accept
Modify
Reject
```

AI must show reasons, evidence, and confidence.

---

## 17. Annual Review

Purpose:

> Determine whether the user is still climbing the right mountain.

Questions:

1. What was the strategic thesis?
2. Which assumptions were correct?
3. Which assumptions failed?
4. What changed externally?
5. What changed personally?
6. Should engine allocation change?
7. What should the next 1-year and 3-year roadmap be?

Example:

```text
2027 REVIEW

2026 STRATEGY
Higher-paying technical role.

RESULTS
✓ Job switch completed
✓ Salary increased
✓ C++/Linux improved
△ Ownership engine weak

EXTERNAL CHANGES
AI coding much stronger.
Robotics investment accelerated.
Automotive hiring changed.

2028 OPTIONS
A Career acceleration
B AI × Automotive product
C Robotics / Edge AI
D Consulting / Freelance

RECOMMENDED
B + C

ENGINE ALLOCATION
Career       Maintenance
Ownership    Primary
Capital      Continuous
```

---

## 18. Event-Driven Review

Possible triggers:

- major job offer,
- Job Switch mission completed,
- job loss,
- major salary change,
- first paying customer,
- product reaches revenue threshold,
- major AI capability shift,
- target market contracts sharply,
- user manually requests reconsideration.

Behavior:

1. Record event.
2. Show affected assumptions.
3. Recommend whether a strategic review is needed.
4. Never modify strategy automatically.

---

## 19. Strategy Versioning

Every accepted strategic change creates a new version.

```text
v1 — Sep 2026   Career Primary
v2 — Jan 2027   Career + AI Hedge
v3 — Jan 2028   Ownership Primary
v4 — Jan 2030   Product Scale
```

UI supports:

- compare versions,
- inspect changed assumptions,
- inspect reasons,
- inspect historical context.

---

## 20. Job Market Intelligence

Not required for MVP; important for V1.

Input:

- pasted job descriptions,
- job URLs later,
- interview feedback,
- salary ranges.

AI extraction:

```text
Role
Company
Salary
Required Skills
Preferred Skills
Years of Experience
Domain
Location
```

Aggregate example:

```text
MARKET SKILL DEMAND
C++             92%
Linux           81%
Networking      66%
AUTOSAR         61%
Python          43%
Yocto           39%
QNX             27%
```

Compare with user readiness:

```text
YOUR GAP
Linux IPC        HIGH
Modern C++       MEDIUM
Networking       MEDIUM
Yocto            HIGH
```

Suggested priority formula:

```text
Priority =
Market Demand
× Role Importance
× User Gap
× Mission Relevance
```

All recommendations must be explainable.

---

## 21. Interview Feedback Loop

```text
Job Market
   ↓
Apply
   ↓
Interview
   ↓
Questions / Feedback
   ↓
Gap Analysis
   ↓
Learning Priorities
   ↓
Practice
   ↓
Re-apply
```

Example:

```text
Company X

shared_ptr internals       FAIL
virtual destructor         PASS
process vs thread          PARTIAL
SOME/IP                    PASS
race-condition debugging   FAIL

Detected weakness
C++ ownership
Concurrency debugging

Recommended next learning
shared_ptr internals
race conditions
mutex / condition_variable
```

---

## 22. Income Lab

Purpose: Run small market experiments instead of accumulating ideas.

Pipeline:

```text
Idea
  ↓
Research
  ↓
Hypothesis
  ↓
Experiment
  ↓
Market Signal
  ↓
Kill / Iterate / Scale
```

Experiment example:

```text
Excel Automation

Hypothesis
SMEs will pay for recurring Excel automation.

Experiment
10 targeted proposals.

Result
3 viewed
1 reply
0 paid

Signal
Weak Positive

Next
Improve portfolio demo.
```

Every experiment must have a concrete `Next Action` or explicit `Kill` decision.

---

## 23. Ownership Engine

Initial projects:

```text
Trace Inspector
DiagRCA
AI × Automotive experiments
Technical distribution
```

Mode:

```text
Primary
Maintenance
Paused
Archived
```

Current seed:

```text
Ownership Engine
Mode: Maintenance
Weekly budget: 30–60 min
Current objective: one meaningful AI × Automotive experiment per week.
```

After successful job switch, the app may propose:

```text
Career      Primary → Maintenance
Ownership   Maintenance → Primary
```

User must approve.

---

## 24. Motivation & Trajectory

Prefer objective trajectory.

Example:

```text
LAST 30 DAYS
31 learning sessions
24.5 focused hours
47 code commits
13 interview questions
8 jobs analyzed
4 applications
2 interviews
```

And:

```text
90-DAY SKILL CHANGE
Modern C++    +34
Linux         +19
Interview     +33
```

Optional:

- streak,
- consistency score,
- momentum indicator.

---

## 25. Why Path

Every session can show a causal chain.

```text
Tonight:
CodeCrafters TCP concurrency

Why?

CodeCrafters
→ Systems Programming
→ C++ / Linux Readiness
→ Job Switch
→ Higher Salary
→ Career Engine
→ Financial Independence
```

This is a core motivational feature.

---

## 26. AI Responsibilities

### Planning

- convert mission into weekly plan,
- recommend priority,
- create session objectives,
- propose next actions.

### Review

- summarize evidence,
- detect stagnation,
- identify repeated blockers,
- compare expected vs actual trajectory.

### Knowledge

- summarize documents,
- extract concepts,
- suggest links,
- retrieve relevant knowledge.

### Career

- parse JDs,
- aggregate demand,
- compare market demand to readiness,
- analyze interview weaknesses.

### Strategy

- inspect assumptions,
- detect possible invalidation,
- recommend quarterly/annual adjustments.

---

## 27. AI Guardrails

AI must:

- cite supporting evidence inside the app,
- distinguish fact from inference,
- show uncertainty,
- allow correction,
- preserve strategy history,
- never silently change priorities.

Good recommendation format:

```text
Recommendation
Increase Linux IPC priority.

Why
- Appears in 12/20 target jobs.
- Current readiness estimated at 42%.
- Asked in 2 recent interviews.

Confidence
High
```

---

## 28. Knowledge Architecture

Logical pipeline:

```text
Input File
  ↓
Parser
  ↓
Normalized Document
  ↓
Text Sections
  ↓
Metadata
  ↓
Full-Text Index
  ↓
Semantic Index
  ↓
Concept Links
  ↓
User-visible Knowledge Item
```

MVP inputs:

```text
.txt
.md
.pdf
.docx
```

Preserve:

- original filename,
- original file,
- extracted text,
- section boundaries,
- page/offset if possible,
- checksum,
- import timestamp.

---

## 29. Retrieval Requirements

Long-term retrieval:

```text
Full-text search
+
Semantic retrieval
+
Graph relationships
```

Retrieval result should include:

```text
title
source
section
snippet
page/offset if available
relationship to current task
```

The user must be able to open source context.

---

## 30. Suggested Technical Architecture

Recommended default, not a hard requirement.

### Client

```text
Flutter
```

Rationale:

- desktop-first friendly,
- mobile later,
- good dashboard UI,
- single UI codebase.

### Local Data

```text
SQLite
```

Suggested Flutter persistence layer:

```text
Drift
```

Use:

- relational tables,
- FTS5 for text search,
- JSON only where useful,
- explicit migrations.

### AI Layer

Use provider abstraction.

```text
AIProvider
  summarize()
  extractStructured()
  generate()
  embed()
```

Do not let UI call vendor SDKs directly.

### Document Layer

```text
DocumentParser
  TextParser
  MarkdownParser
  PdfParser
  DocxParser
```

### Embeddings

Not required for earliest MVP.

Later introduce:

```text
EmbeddingProvider
VectorStore
```

---

## 31. Local-First Requirement

Preferred defaults:

- personal graph stored locally,
- tasks/sessions local,
- documents local,
- AI calls receive only required context,
- user can inspect what context is sent,
- cloud sync optional later.

Production modes may include:

```text
Local-only
Cloud sync
Hybrid
```

---

## 32. Privacy

Potentially sensitive data:

- salary,
- financial notes,
- job applications,
- private documents,
- interview notes,
- personal goals.

Production requirements:

- secure credential storage,
- encryption at rest where practical,
- explicit AI context boundaries,
- clear local/cloud indicators,
- export/delete support,
- no silent data upload.

---

## 33. MVP Scope

Goal:

> Make the system useful every day for strategy-linked learning and execution.

### MVP Core Data

- Vision.
- Mission.
- Project.
- Task.
- Session.
- Skill.
- Evidence.
- Weekly Review.
- Knowledge Item.

### MVP Screens

```text
Today
Mission
Strategy
Projects
Knowledge
Review
```

### MVP AI

- summarize imported document,
- propose tags,
- suggest skill/project links,
- generate weekly review summary,
- generate next-week priority suggestions.

### MVP Exclusions

Do not build yet:

- automatic web market crawling,
- financial account integration,
- autonomous roadmap rewriting,
- mobile sync,
- social publishing,
- complex multi-agent architecture,
- advanced gamification,
- collaboration.

---

## 34. MVP Acceptance Criteria

MVP is complete when a user can:

1. Create a long-term vision.
2. Create an active mission.
3. Link mission to skills.
4. Create project `CodeCrafters`.
5. Schedule a technical session.
6. Start and complete the session.
7. Record Actual Output.
8. Attach evidence.
9. See skill readiness change.
10. View Why Path from session to vision.
11. Import PDF or Markdown.
12. Link knowledge to skill/project.
13. Search knowledge.
14. Complete Weekly Review.
15. Generate next-week priorities.
16. Preserve all data after restart.

---

## 35. V1 — Personal Execution System

Goal:

> Turn MVP into a dependable weekly operating system.

Add:

- recurring schedules,
- session templates,
- monthly review,
- readiness dimensions,
- better evidence scoring,
- strategy versioning,
- assumption model,
- experiment model,
- Income Lab dashboard,
- job records,
- application pipeline,
- interview records,
- basic charts,
- export/import.

AI additions:

- interview gap extraction,
- JD parsing,
- evidence-based skill suggestions,
- assumption-review suggestions.

### V1 Acceptance Criteria

User can:

- paste 20 JDs,
- see aggregated skill demand,
- compare demand to readiness,
- add interview questions,
- convert failed questions into learning priorities,
- run an Income Lab experiment,
- perform monthly review,
- compare strategy versions.

---

## 36. V2 — Adaptive Strategy Engine

Goal:

> Help decide what deserves attention next.

Add:

- Quarterly Strategy Review,
- Annual Review,
- Event-Driven Review,
- assumption validation,
- strategy comparison,
- trend evidence,
- priority rebalancing.

Every strategy recommendation must include:

```text
Recommendation
Evidence
Affected assumptions
Expected benefit
Risk
Confidence
```

User approval is required.

### V2 Acceptance Criteria

System can:

1. Detect a weakening assumption.
2. Show evidence.
3. Recommend adjustment.
4. Offer Accept / Modify / Reject.
5. Create new Strategy Version.
6. Preserve previous version.
7. Propagate accepted changes into future planning.

---

## 37. V3 — Knowledge & Intelligence Layer

Goal:

> Deeply connect knowledge with execution.

Add:

- embeddings,
- semantic search,
- concept graph,
- automatic relation suggestions,
- source-aware retrieval,
- task-to-knowledge recommendations,
- duplicate concept detection,
- knowledge freshness.

Example:

```text
Current task:
Linux IPC interview preparation

Relevant knowledge:
- POSIX shared memory note
- CodeCrafters process exercise
- interview question from Company X
- Linux manual excerpt
```

---

## 38. V4 — Market & Career Intelligence

Goal:

> Connect external market reality to personal roadmap.

Capabilities may include:

- job-source connectors,
- salary tracking,
- role clustering,
- skill-demand trends,
- company tracking,
- interview analytics.

Output example:

```text
Target Role Health
Demand
Salary
Skill Gap
Application Conversion
Interview Conversion
Offer Conversion
```

Never claim certainty.

---

## 39. V5 — Ownership & Wealth OS

Goal:

> Expand beyond career after the short-term career mission is stabilized.

Add:

- product portfolio,
- product experiments,
- customer discovery,
- revenue metrics,
- distribution metrics,
- capital contribution tracking,
- net-worth snapshots,
- engine-allocation review.

Do not turn the product into a brokerage application.

---

## 40. Final Production Vision

The mature system covers:

```text
Strategy
Career
Learning
Knowledge
Projects
Products
Income Experiments
Reviews
Capital
```

The user should be able to ask:

```text
What matters most this quarter?
Why?

Am I still on track for my active mission?

What changed in the market?

Which assumption is weakening?

Which skill has the highest expected return?

What did I actually produce in the last 90 days?

Should I continue learning this topic?

What should I stop doing?

What is my next best action tonight?
```

The app should answer from the user's own evidence and current strategy.

---

## 41. Production Quality Requirements

### Reliability

- no silent data loss,
- migrations tested,
- import idempotent where practical,
- parser failures safe and recoverable.

### Performance Targets

```text
App launch               < 3 s
Today local render       < 1 s
Keyword search           < 500 ms for normal local KB
Navigation               perceived instant
```

### Explainability

Any AI recommendation affecting strategy must expose:

```text
Why
Evidence
Confidence
Affected goals
```

### Auditability

Keep history for:

- strategy changes,
- review decisions,
- skill readiness changes,
- AI recommendations.

---

## 42. Suggested Repository Structure

```text
personal_os/
├── app/
│   ├── screens/
│   │   ├── today/
│   │   ├── mission/
│   │   ├── strategy/
│   │   ├── projects/
│   │   ├── knowledge/
│   │   └── review/
│   ├── components/
│   ├── navigation/
│   └── theme/
│
├── domain/
│   ├── vision/
│   ├── strategy/
│   ├── mission/
│   ├── skills/
│   ├── evidence/
│   ├── projects/
│   ├── sessions/
│   ├── knowledge/
│   ├── review/
│   ├── jobs/
│   ├── interviews/
│   └── experiments/
│
├── data/
│   ├── db/
│   ├── repositories/
│   ├── migrations/
│   └── seed/
│
├── ai/
│   ├── providers/
│   ├── prompts/
│   ├── retrieval/
│   ├── review/
│   └── recommendations/
│
├── document/
│   ├── parsers/
│   ├── indexing/
│   └── models/
│
├── tests/
│   ├── unit/
│   ├── integration/
│   ├── golden/
│   └── e2e/
│
└── docs/
```

---

## 43. Initial Database Tables

MVP:

```text
visions
missions
projects
tasks
sessions
skills
evidence
knowledge_items
knowledge_links
reviews
```

Later:

```text
strategies
strategy_versions
assumptions
outcomes
initiatives
skill_evidence
jobs
job_requirements
applications
interviews
interview_questions
experiments
metrics
```

---

## 44. Core Relationships

```text
Vision       1 ─── N Mission
Mission      N ─── N Skill
Mission      1 ─── N Project
Project      1 ─── N Task
Task         1 ─── N Session
Session      1 ─── N Evidence
Skill        N ─── N Evidence
Knowledge    N ─── N Skill
Knowledge    N ─── N Project
Review       N ─── N Evidence
```

Later:

```text
Strategy     1 ─── N Assumption
Job          1 ─── N JobRequirement
Application  1 ─── N Interview
Interview    1 ─── N InterviewQuestion
```

---

## 45. Core Service Interfaces

```text
StrategyService
MissionService
PlanningService
SessionService
EvidenceService
SkillReadinessService
KnowledgeService
ReviewService
AIService
DocumentParser
SearchService
```

Later:

```text
JobMarketService
InterviewAnalysisService
ExperimentService
StrategyReviewService
```

---

## 46. Structured Recommendation Object

Example:

```json
{
  "title": "Increase Linux IPC priority",
  "reason": "Appears frequently in target jobs and current readiness is low.",
  "confidence": 0.86,
  "supportingEvidenceIds": ["ev_1", "ev_2", "ev_3"],
  "affectedMissionIds": ["mission_job_switch"],
  "suggestedAction": "Allocate two sessions next week to Linux IPC.",
  "requiresUserApproval": true
}
```

---

## 47. Review Output Schema

```json
{
  "summary": "",
  "wins": [],
  "misses": [],
  "evidenceCreated": [],
  "skillChanges": [],
  "assumptionsChanged": [],
  "recommendations": [],
  "carryForward": [],
  "nextPeriodPriorities": []
}
```

---

## 48. Development Order

### Milestone 1 — Skeleton

- app setup,
- navigation,
- local DB,
- base entities.

### Milestone 2 — Today

- schedule display,
- session lifecycle,
- Actual Output / Next Action.

### Milestone 3 — Strategy + Mission

- vision,
- mission,
- basic strategy graph,
- Why Path.

### Milestone 4 — Projects + Evidence

- project tracking,
- evidence capture,
- skill linkage.

### Milestone 5 — Knowledge

- import TXT/MD/PDF/DOCX,
- extraction,
- search,
- links.

### Milestone 6 — Review

- weekly review,
- trajectory summary,
- next-week priorities.

### Milestone 7 — AI

- document summary,
- review summary,
- link suggestions,
- priority recommendations.

### Milestone 8 — Hardening

- migration tests,
- backup/export,
- E2E tests,
- error handling.

This completes MVP.

---

## 49. MVP Golden E2E Scenario

Setup:

```text
Vision:
Financial Independence 2043

Mission:
Job Switch — Higher Salary

Skills:
Modern C++
Linux
Systems Programming
Automotive
English
Interview

Project:
CodeCrafters — Systems Programming
```

Flow:

1. Schedule Wednesday 21:00 CodeCrafters.
2. Open Today.
3. Confirm Why Path.
4. Start session.
5. Complete one stage.
6. Record Actual Output.
7. Record Next Action.
8. Add TestPass evidence.
9. Observe skill readiness update.
10. Import a Linux networking PDF.
11. Link it to Linux + CodeCrafters.
12. Search the knowledge base.
13. Complete Weekly Review.
14. AI proposes next-week priority.
15. User Accepts or Modifies.

Expected result:

> The user can see a direct relationship between work performed today and the active mission.

---

## 50. Non-Goals

Personal OS should not become:

- another generic todo app,
- a Notion clone,
- a note dump,
- an AI chatbot with no structured state,
- a brokerage/trading tool,
- a job board,
- a social network,
- an autonomous life coach.

Core differentiation:

> Structured personal strategy + execution + evidence + adaptation.

---

## 51. UX Principles

- **Calm:** avoid dashboard overload.
- **Explainable:** always show why a metric/recommendation exists.
- **Progressive disclosure:** Home stays simple; details live deeper.
- **User ownership:** AI-generated relations are editable.
- **Low friction:** session start/finish requires very few actions.
- **Trajectory-first:** show improvement over time.

---

## 52. Product Success Metrics

MVP:

```text
Weekly active use
Session completion rate
Review completion rate
Evidence captured/week
Knowledge retrieval success
```

Later:

```text
Mission completion rate
Percentage of tasks linked to mission
Strategy recommendation acceptance rate
Skill-readiness calibration vs interviews
Time-to-decision during review
```

Do not optimize only for time-in-app.

A good Personal OS may reduce the time required to manage one's life system.

---

## 53. Final Product Definition

Personal OS succeeds when the user can open it and immediately understand:

```text
Where am I going?
What is my current mission?
What should I do today?
Why does it matter?
What evidence shows I am improving?
What changed in reality?
Does my roadmap still make sense?
What should I change next?
```

The final system should behave like a:

> **Personal Strategy Engine + Execution System + Evidence-Based Memory.**
