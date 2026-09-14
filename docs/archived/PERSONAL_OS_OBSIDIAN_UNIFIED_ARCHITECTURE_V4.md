# Personal OS + Obsidian — Unified Architecture & Implementation Specification

**Version:** 4.1  
**Status:** Architecture baseline + implementation specification  
**Purpose:** Define the final boundary between Obsidian and Personal OS, and provide agents with one complete implementation reference.

---

# 1. Product Definition

The system consists of two clearly separated layers:

```text
Obsidian
= user-owned data + knowledge layer

Personal OS
= strategy + planning + execution + review + derived intelligence layer
```

The core principle is:

> **The user owns the Markdown. Personal OS owns the workflow and derived views.**

## 1.1 V4.1 scheduled-work model

Personal OS plans a learning/work session but does not measure attendance or elapsed time. `planned_minutes` describes the calendar allocation only. There is no Start/Pause/Resume/Stop workflow.

Each scheduled occurrence has one stable-ID Markdown note. After its planned end, Personal OS confirms completion only when the note has both `status: done` and a concrete, resolvable Output.

The app reconciles on startup/resume, at a scheduled end, every five minutes while results remain pending, and on explicit request. If the app was closed, the next startup performs the missed check. No background service or filesystem watcher is required.

Late output remains pending rather than becoming an automatic failure. Streaks are calculated per recurring schedule from confirmed occurrences; unscheduled days do not break a streak.

Personal OS must not become a second proprietary information store that competes with Obsidian.

---

# 2. Responsibilities

## 2.1 Obsidian

Obsidian is the primary place for durable information and knowledge.

It stores:

```text
Knowledge notes
Strategy
Strategy versions
Assumptions
Missions
Projects
Tasks
Skills
Evidence
Career records
Applications
Interviews
Reviews
Experiments
```

All durable business data should be represented as:

```text
Markdown + YAML frontmatter
```

Obsidian provides:

```text
editing
notes
backlinks
portable files
human browsing
manual organization
```

---

## 2.2 Personal OS

Personal OS is the operating layer on top of the Markdown workspace.

It provides:

```text
Dashboard
Goals / Missions / Targets
Planning
Task / Project status management
Progress calculation
Skill Readiness
Evidence tracking
Career pipeline
Reviews
Strategy versioning workflow
Knowledge search/retrieval
Markdown Preview
Markmap visualization
```

Personal OS may create/update Markdown through forms, but must preserve the underlying files as the canonical data.

---

# 3. High-Level Architecture

```text
┌───────────────────────────────────────────────┐
│                 OBSIDIAN VAULT                │
│                                               │
│ Markdown + YAML                               │
│                                               │
│ Strategy / Mission / Project / Task           │
│ Skill / Evidence / Career / Review            │
│ Knowledge Notes                               │
└──────────────────────┬────────────────────────┘
                       │
                       │ App startup scan
                       ▼
┌───────────────────────────────────────────────┐
│           MARKDOWN WORKSPACE LAYER            │
│                                               │
│ WorkspaceManager                              │
│ MarkdownEntityParser                          │
│ MarkdownEntityStore                           │
│ SchemaValidator                               │
│ StartupWorkspaceLoader                        │
└──────────────────────┬────────────────────────┘
                       │
                       ▼
┌───────────────────────────────────────────────┐
│              SQLITE PROJECTION                │
│                                               │
│ Entity index                                  │
│ Relationships                                 │
│ FTS5                                          │
│ Parsed sections                               │
│ Derived metrics/cache                         │
│ Runtime/session state                         │
│ UI preferences                                │
└──────────────────────┬────────────────────────┘
                       │
                       ▼
┌───────────────────────────────────────────────┐
│                PERSONAL OS                    │
│                                               │
│ Dashboard                                     │
│ Mission / Projects / Tasks                    │
│ Career                                        │
│ Reviews                                       │
│ Search / Retrieval                            │
│ Preview / Markmap                             │
└───────────────────────────────────────────────┘
```

---

# 4. Canonical Data Ownership

## Markdown owns

```text
Strategy content
Mission state
Project state
Task state
Skill definitions
Evidence
Career records
Application status
Interview notes
Review records
Experiment records
Knowledge notes
```

Examples of canonical fields:

```yaml
status: done
status: active
status: interview
priority: P1
mission: mission-job-switch
project: project-codecrafters
```

---

## SQLite owns

```text
FTS index
parsed heading sections
entity lookup
relationship projection
computed progress
readiness cache
runtime timer state
temporary UI state
settings
search cache
last indexed checksum
```

SQLite must not become a competing owner of durable business status.

## 4.1 Migration ownership matrix

| Data | Canonical after migration | Transition rule |
| --- | --- | --- |
| Knowledge, Task, Project, Mission | Markdown | Move one entity type at a time; SQLite becomes projection only after its gate passes. |
| Session occurrence, template and recurring schedule | Markdown | Included before Task migration because schedule completion and streak depend on them. |
| Session Output/Learning/Next Action | Session note or linked Markdown | SQLite rows are projections and use stable source identity to avoid duplicates. |
| Historical timer/interval rows | Legacy SQLite backup | Preserve for compatibility; do not write or use them for new progress. |
| Evidence assessments and decisions | Markdown after their later migration | Preserve full timestamp, identity and immutable history. |
| FTS, parsed sections, relationships and progress/streak | SQLite projection | Rebuildable from the migrated Markdown set. |
| UI settings and unfinished operation journal | SQLite runtime state | Back up with the vault during the transition. |

The Rebuild Projection command may delete only data proven rebuildable for the completed migration phases. It must not delete the whole transition database while any durable domain still has SQLite ownership.

---

# 5. Important Recovery Rule

The SQLite projection must be rebuildable from the Markdown workspace.

Critical verification:

```text
Delete disposable SQLite projection/cache
→ reopen app
→ scan Markdown
→ rebuild structured state
```

After rebuild, Personal OS must recover:

```text
Knowledge
Tasks
Projects
Missions
Skills / Evidence
Strategy / Versions
Career
Reviews
Experiments
```

except for intentionally runtime-only state.

---

# 6. Workspace Initialization

Add a primary action:

```text
Create Personal OS Workspace
```

For an existing Obsidian vault:

```text
Initialize Personal OS in this Vault
```

Flow:

```text
Choose folder / vault
        ↓
Preview generated structure
        ↓
Create folders
        ↓
Generate templates
        ↓
Optional starter data
        ↓
Index Markdown
        ↓
Open Dashboard
```

---

# 7. Recommended Vault Structure

```text
Personal OS/
├── 00 Dashboard/
│   └── README.md
├── 01 Strategy/
│   ├── vision.md
│   ├── current-strategy.md
│   ├── versions/
│   └── assumptions/
├── 02 Missions/
├── 03 Projects/
├── 04 Tasks/
├── 05 Skills/
├── 06 Evidence/
├── 07 Career/
│   ├── jobs/
│   ├── applications/
│   └── interviews/
├── 08 Reviews/
│   ├── weekly/
│   ├── monthly/
│   ├── quarterly/
│   ├── annual/
│   └── event-driven/
├── 09 Experiments/
├── 10 Knowledge/
├── 11 Sessions/
├── _templates/
│   ├── strategy.md
│   ├── strategy-version.md
│   ├── assumption.md
│   ├── mission.md
│   ├── project.md
│   ├── task.md
│   ├── skill.md
│   ├── evidence.md
│   ├── job.md
│   ├── application.md
│   ├── interview.md
│   ├── review.md
│   ├── experiment.md
│   ├── knowledge.md
│   ├── session.md
│   └── recurring-schedule.md
└── .personal-os/
    └── workspace.yaml
```

Initialization must never silently overwrite existing user notes.

---

# 8. Canonical File Format

Use:

> **Markdown + YAML frontmatter**

Example:

```markdown
---
id: task-01JXYZ
type: task
title: Implement HTTP parser
status: in_progress
project: project-codecrafters
priority: P1
due: 2026-09-20
created: 2026-09-13
updated: 2026-09-13
---

# Implement HTTP parser

## Goal

Complete request-line and header parsing.

## Work

- [x] Parse request line
- [ ] Parse headers

## Output

## Next Action
```

---

# 9. Global Metadata Contract

Structured entities should contain:

```yaml
id:
type:
title:
created:
updated:
```

Rules:

- `id` is stable and never derived from filename.
- Rename/move does not change identity.
- `type` selects schema/parser.
- Unknown YAML keys must be preserved.
- Unknown Markdown content must be preserved.
- App writes must patch minimally.

---

# 10. Templates

## 10.1 Task

```markdown
---
id:
type: task
title:
status: planned
project:
priority: P2
due:
skills: []
created:
updated:
---

# {{title}}

## Goal

What does Done mean?

## Work

- [ ] Optional sub-step

## Output

## Next Action
```

Canonical completion:

```yaml
status: done
```

Body checkboxes are not canonical Task status.

Supported states:

```text
backlog
planned
in_progress
blocked
done
cancelled
```

---

## 10.2 Project

```markdown
---
id:
type: project
title:
status: active
mission:
skills: []
start:
target:
created:
updated:
---

# {{title}}

## Purpose

## Success

## Next Action

## Notes
```

Project execution progress:

```text
Done Tasks / Non-Cancelled Tasks
```

Do not store a fake/manual progress percentage if it can be calculated.

---

## 10.3 Mission

```markdown
---
id:
type: mission
title:
status: active
strategy:
priority: P1
start:
target:
success_criteria: []
skills: []
created:
updated:
---

# {{title}}

## Why

## Success Criteria

## Current Focus

## Notes
```

Mission UI must keep separate:

```text
Execution Progress
Outcome Progress
Skill Readiness
```

---

## 10.4 Strategy

```markdown
---
id:
type: strategy
title:
status: active
vision:
current_version:
created:
updated:
---

# {{title}}

## Thesis

## Current Priorities

1.
2.
3.

## Why This Strategy

## Risks

## Assumptions
```

---

## 10.5 Strategy Version

```markdown
---
id:
type: strategy_version
strategy:
version:
previous_version:
effective_date:
change_reason:
created:
---

# Strategy Version {{version}}

## Thesis

## What Changed

## Why

## Evidence

## Assumptions
```

Accepted historical versions are immutable from the normal app workflow.

---

## 10.6 Assumption

```markdown
---
id:
type: assumption
title:
strategy:
status: unverified
importance: medium
confidence: 0.5
last_validated:
created:
updated:
---

# {{title}}

## Supporting Evidence

## Contradicting Evidence

## Notes
```

Statuses:

```text
unverified
supported
validated
weakening
invalidated
```

---

## 10.7 Skill

```markdown
---
id:
type: skill
title:
category:
target_level:
created:
updated:
---

# {{title}}

## Target

## Notes
```

Skill Readiness is derived from verified Evidence.

Dimensions:

```text
Knowledge
Implementation
Debugging
Application
Interview
Production
```

---

## 10.8 Evidence

```markdown
---
id:
type: evidence
title:
evidence_type:
skill:
dimension:
score:
verified: false
confidence:
output:
project:
mission:
source:
created:
updated:
---

# {{title}}

## What This Proves

## Result

## Source / Artifact

## Notes
```

Each Evidence document is one assessment for one Skill and one of `knowledge`, `implementation`, `debugging`, `application`, `interview`, or `production`. `score` and `confidence` use 0–100 and have different meanings. Readiness uses the latest verified assessment for each Skill × Dimension while preserving history and full timestamps.

---

## 10.9 Job

```markdown
---
id:
type: job
title:
company:
location:
status: saved
source_url:
salary_min:
salary_max:
currency:
required_skills: []
preferred_skills: []
created:
updated:
---

# {{title}} — {{company}}

## Job Description

## Notes
```

---

## 10.10 Application

```markdown
---
id:
type: application
title:
job:
status: saved
applied_date:
created:
updated:
---

# {{title}}

## Notes

## Next Action
```

Statuses:

```text
saved
applied
screening
interview
offer
rejected
withdrawn
```

---

## 10.11 Interview

```markdown
---
id:
type: interview
title:
application:
date:
round:
result:
created:
updated:
---

# {{title}}

## Questions

### Question

Result: pass / partial / fail

## Strengths

## Weaknesses

## Next Learning
```

---

## 10.12 Review

```markdown
---
id:
type: review
review_type: weekly
period_start:
period_end:
status: draft
created:
updated:
---

# Weekly Review

## Wins

## Misses

## Evidence Created

## What Improved

## Blockers

## Carry Forward

## Next Priorities
```

Types:

```text
weekly
monthly
quarterly
annual
event_driven
```

---

## 10.13 Experiment

```markdown
---
id:
type: experiment
title:
status: active
signal: unknown
project:
created:
updated:
---

# {{title}}

## Hypothesis

## Market

## Experiment

## Result

## Signal

## Next Action
```

---

## 10.14 Knowledge

Knowledge can be either structured Personal OS Markdown or normal Obsidian Markdown.

Example:

```markdown
---
id:
type: knowledge
title: Linux IPC
tags:
  - linux
  - ipc
skills:
  - skill-linux
projects:
  - project-codecrafters
---

# Linux IPC

## Shared Memory

...

## Sockets

...
```

Ordinary notes without Personal OS frontmatter must still be indexable/searchable.

---

## 10.15 Scheduled Session

```markdown
---
id:
type: session
title:
schedule:
project:
task:
planned_start:
planned_minutes: 60
status: planned
created:
updated:
---

# {{title}}

## Goal

## Input

## Output

## Learning

## Next Action
```

Canonical states are `planned`, `done`, `skipped`, and `cancelled`. “Scheduled now”, “Awaiting result”, “Missing output”, and validation errors are derived display states. A completed Session does not automatically complete a Task or create verified Evidence.

An Output is valid when it contains concrete content, an external URL, or a local Markdown/wikilink whose target resolves. Empty headings, placeholders, unchecked tasks, and unresolved link-only content are not completion evidence.

---

# 11. Synchronization Model

Realtime filesystem synchronization is deliberately postponed. V4.1 adds scheduled reconciliation without introducing a watcher.

## Obsidian → Personal OS

Primary mechanism:

```text
Open app
→ scan workspace
→ detect new/changed/deleted files
→ parse YAML + Markdown
→ validate
→ update SQLite projection
→ recalculate derived state
→ show Dashboard
```

Detection uses:

```text
stable id
path
modified time
checksum
```

No filesystem watcher is required.

While the app is open, a five-minute reconciliation check is allowed for Sessions whose planned end has passed. Scans are incremental and overlapping requests are coalesced.

---

## Personal OS → Markdown

When the user edits from the app:

```text
Edit form
→ Save
→ patch YAML / supported section
→ atomic file write
→ update SQLite projection
→ refresh UI
```

Example:

```text
Task → Done
```

writes:

```yaml
status: done
```

---

# 12. External Changes While App Is Open

Required V4.1 behavior:

```text
Edit in Obsidian
→ planned end / app resume / five-minute check / manual check
→ new data is loaded
```

Required convenience action:

```text
Reload Workspace
```

is available for explicit reconciliation.

Do not implement a live filesystem watcher yet.

---

# 13. Safe Markdown Writer

Required abstraction:

```dart
abstract class MarkdownEntityStore {
  Future<EntityDocument> read(String id);

  Future<void> create(
    EntityDocument document,
  );

  Future<void> updateFrontmatter(
    String id,
    Map<String, dynamic> changes,
  );

  Future<void> renameOrMove(
    String id,
    String newPath,
  );
}
```

Write rules:

- parse the current file first,
- patch supported fields only,
- preserve unknown YAML keys,
- preserve Markdown body,
- preserve user-created sections,
- write temporary file,
- atomically replace target,
- update checksum/projection.

---

# 14. Conflict Handling

Before any app write:

```text
current disk checksum
vs
checksum captured at app load/index
```

If unchanged:

```text
save
```

If changed externally:

```text
External change detected.

[Reload file]
[Cancel]
[Overwrite]
```

Default:

```text
Reload file
```

Never silently overwrite external changes.

---

# 15. Stable ID / Rename / Move

Identity is based on:

```yaml
id:
```

not path.

Therefore:

```text
same id + new path
```

means:

```text
rename/move
```

not:

```text
new entity
```

---

# 16. Progress Semantics

This is critical.

## Task

Canonical state:

```yaml
status:
```

---

## Project Execution Progress

```text
Done Tasks / Non-Cancelled Tasks
```

---

## Mission Execution Progress

Derived from linked Projects/Outcomes according to current domain rules.

---

## Outcome Progress

Uses measurable result/outcome values where defined.

---

## Skill Readiness

Uses verified Evidence only.

Critical rule:

> Task Done can increase execution progress.  
> Task Done does not automatically increase Skill Readiness.

This preserves the original evidence-first design.

## Scheduled-work completion

```text
Confirmed due Sessions / Due non-cancelled Sessions
```

Pending Sessions are shown separately. Planned duration is never reported as focused or actual time. Project Milestone progress remains separate from Project Execution progress.

## Recurring-schedule streak

- Count consecutive confirmed `done` occurrences for one recurring schedule.
- `skipped` breaks the streak; `cancelled` is excluded.
- Days without an occurrence have no effect.
- A pending occurrence makes the subsequent streak unresolved until it is completed or explicitly skipped/cancelled.
- Late output recalculates the streak at the original occurrence position.

---

# 17. Dashboard Role

Dashboard answers:

```text
What is my current mission?
Am I on track?
What should I do today?
What is my biggest gap?
What progress/wins did I create recently?
```

Dashboard reads from the SQLite projection and derived metrics, not by reparsing Markdown on every render.

Recommended regions:

```text
Active Mission
Career / Ownership / Capital
Skill Readiness
Weekly Progress
Today
Top Priorities
Recent Wins
```

No fake progress percentages.

---

# 18. Goal / Plan / Target Workflow

Personal OS is the primary place for:

```text
define Mission
set Target
create Project
create Task
plan work
change status
review execution
inspect progress
```

When the user edits these through Personal OS forms, the underlying Markdown is updated.

Obsidian remains fully compatible with direct manual editing.

---

# 19. Knowledge Architecture

Obsidian is the Knowledge Base.

Personal OS should:

```text
load Markdown
index Markdown
search Markdown
display Markdown
retrieve Markdown
visualize Markdown
```

Personal OS should not recreate a separate proprietary KB.

---

# 20. Knowledge Index

Use SQLite FTS5.

Index:

```text
title
body
heading
tags
path
entity type
```

Prefer heading-based sections rather than arbitrary token chunks.

Example section:

```text
File:
Linux/ipc.md

Heading:
POSIX Shared Memory

Content:
...
```

---

# 21. Knowledge Retrieval Service

Both the user and future AI must use the same retrieval layer.

```dart
abstract class KnowledgeRetrievalService {
  Future<List<KnowledgeSearchResult>> search(
    String query, {
    int limit = 10,
  });

  Future<KnowledgeDocument?> getDocument(String id);

  Future<List<KnowledgeSection>> getRelevantSections(
    String query, {
    int limit = 5,
  });
}
```

No separate hidden AI knowledge database.

---

# 22. Markdown Preview

Personal OS must support rendered Markdown:

```text
headings
paragraphs
lists
tables
code blocks
blockquotes
links
task lists
```

Preview is read-oriented.

Editing can remain form-based or be done directly in Obsidian.

---

# 23. Markmap

Knowledge notes support:

```text
Preview | Markmap
```

Markmap is generated from Markdown structure.

Requirements:

```text
zoom
pan
expand/collapse
fit-to-screen
```

Do not persist another graph representation solely for Markmap.

---

# 24. Obsidian Link Support

Parse:

```markdown
[[RAII]]
[[Linux IPC|IPC]]
```

and normal Markdown links.

Resolved wikilinks should open the target note inside Personal OS when possible.

Unresolved links remain visible.

---

# 25. Knowledge Scope Reduction

Current active Knowledge scope:

```text
Markdown
Obsidian vault/folder
FTS5
browse
Preview
Markmap
entity links
shared RetrievalService
```

Out of current scope:

```text
PDF import
DOC/DOCX import
OCR
embeddings
semantic search
AI concept graph
automatic summaries
duplicate concept intelligence
AI-generated links
```

Existing code may remain temporarily hidden if destructive removal is risky.

---

# 26. Template Generator UX

First-run:

```text
Create Personal OS Workspace
```

Settings:

```text
Settings
→ Workspace
→ Initialize / Repair Templates
```

Options:

```text
Workspace location
[Choose folder]

[x] Generate default folder structure
[x] Generate templates
[ ] Generate example starter data
```

After generation:

```text
Workspace ready

Created:
12 folders
14 templates

Indexed:
X Markdown files

[Open Dashboard]
[Open folder]
```

---

# 27. Simple Forms, Not YAML Editors

Normal users should not need to manually edit YAML.

Example Task form:

```text
Title
Status
Project
Priority
Due
Skills

Goal
Next Action

[Save]
```

Personal OS maps the form to Markdown/YAML.

Advanced users may edit the same file in Obsidian.

---

# 28. Template Visibility

Generate all templates, but do not expose all domain concepts at once.

Primary concepts:

```text
Mission
Project
Task
Knowledge
Evidence
```

Contextual/advanced:

```text
Strategy Version
Assumption
Review
Career entities
Experiment
```

This avoids overwhelming normal daily use.

---

# 29. Workspace Metadata

`.personal-os/workspace.yaml`:

```yaml
workspace_id: personal-os-main
schema_version: 4.1
created: 2026-09-13
```

This file contains compatibility metadata only.

Do not store personal strategy content here.

---

# 30. Validation

Each known entity type has a minimal schema.

Example Task:

```text
id
type=task
title
status
```

Invalid files must not crash startup.

Example error:

```text
Invalid Task

File:
04 Tasks/http-parser.md

Invalid status:
complete

Expected:
backlog
planned
in_progress
blocked
done
cancelled
```

Continue loading other valid files.

---

# 31. Migration Strategy

Do **not** perform a big-bang rewrite.

## Phase M1 — Workspace Infrastructure

Add:

```text
WorkspaceManager
MarkdownEntityParser
MarkdownEntityStore
StartupWorkspaceLoader
SchemaValidator
```

Add template generation.

Add revision-aware atomic writes, duplicate-ID and partial-scan protection, and a recoverable operation journal for multi-file commands. A filesystem transaction is not claimed; interrupted operations must be safely retryable.

---

## Phase M2 — Knowledge

Implement/validate:

```text
load Obsidian Markdown
browse
FTS search
Markdown Preview
Markmap
```

---

## Phase M3 — Task

Before Task migration, migrate Session templates, recurring schedules, occurrence notes, reconciliation, and schedule streaks. Retain historical timer columns/rows for migration compatibility, but stop writing or using them in product behavior.

Move Task canonical ownership to Markdown.

Verify:

```text
Create in app → Markdown created
Edit in app → Markdown updated
Edit in Obsidian → restart → app updated
status: done → restart → Task Done
rename/move → same ID
conflict → warning
```

---

## Phase M4 — Project

Move Project canonical ownership.

Verify:

```text
Task Done
→ Project Execution Progress changes
```

---

## Phase M5 — Mission

Move Mission canonical ownership.

Verify:

```text
Project execution
→ Mission execution summary
```

---

# 32. Mandatory Stop-and-Verify Gate

After:

```text
Knowledge
Task
Project
Mission
```

are migrated:

> **STOP. Do not automatically migrate everything else.**

Verify actual daily use.

Required:

```text
1. Edit in Obsidian → restart app → correct.
2. Edit in app → Markdown correct.
3. Restart app → correct.
4. Rename/move file → entity preserved.
5. External change before app save → no silent data loss.
6. Delete/rebuild projection → core state recovered.
7. Dashboard values remain correct.
```

Only continue if this gate passes.

---

# 33. Later Migration

After the gate:

```text
M6 → Skill + Evidence
M7 → Strategy + Versions + Assumptions + Reviews
M8 → Jobs + Applications + Interviews + Experiments
M9 → SQLite cleanup
```

---

# 34. Existing Data Migration

Before moving any entity type:

```text
1. Backup current SQLite DB.
2. Export records.
3. Generate Markdown equivalents.
4. Validate record count.
5. Validate stable IDs.
6. Validate relationships.
7. Switch read path.
8. Keep rollback capability.
```

Never immediately delete the old SQLite data.

---

# 35. Acceptance — Workspace

- [ ] Empty folder can become a Personal OS workspace.
- [ ] Existing Obsidian vault can be initialized.
- [ ] Folder structure is generated.
- [ ] Templates are generated.
- [ ] Existing notes are preserved.
- [ ] Workspace loads after restart.
- [ ] Markdown is indexed on startup.

---

# 36. Acceptance — Obsidian → App

- [ ] New Markdown appears after app restart.
- [ ] Changed YAML appears after app restart.
- [ ] Deleted files disappear from projection.
- [ ] Renamed/moved files retain the same entity.
- [ ] One invalid file does not prevent the workspace from loading.
- [ ] No filesystem watcher is required.

---

# 37. Acceptance — App → Obsidian

- [ ] Create Task in app → `.md` created.
- [ ] Edit Task in app → YAML updated.
- [ ] Mark Task Done → `status: done`.
- [ ] Existing Markdown body survives.
- [ ] Unknown YAML survives.
- [ ] Conflict is detected before overwrite.

---

# 38. Acceptance — Progress

- [ ] Task Done changes Project execution progress.
- [ ] Cancelled Task is excluded.
- [ ] Project execution feeds Mission execution summary.
- [ ] Task completion does not automatically increase Skill Readiness.
- [ ] Verified Evidence changes Readiness.

---

# 39. Acceptance — Knowledge

- [ ] Obsidian Markdown is indexed.
- [ ] Folder browsing works.
- [ ] Keyword search works.
- [ ] Heading search works.
- [ ] Tag search works.
- [ ] Markdown Preview works.
- [ ] Markmap works.
- [ ] Resolved wikilinks work where practical.
- [ ] User and future AI share the same retrieval interface.

---

# 40. Acceptance — Recovery

Run:

```text
1. Backup workspace.
2. Stop Personal OS.
3. Delete disposable SQLite projection/cache.
4. Reopen app.
5. Rebuild from Markdown.
```

Expected:

- [ ] Knowledge recovered.
- [ ] Tasks recovered.
- [ ] Projects recovered.
- [ ] Missions recovered.

Later, after migration:

- [ ] Skills/Evidence recovered.
- [ ] Strategy/versioning recovered.
- [ ] Career pipeline recovered.
- [ ] Reviews recovered.
- [ ] Experiments recovered.

---

# 41. Golden End-to-End Scenario

1. Initialize an Obsidian vault.
2. Templates are generated.
3. Create `CodeCrafters` Project in Personal OS.
4. Project Markdown appears.
5. Create `HTTP Parser` Task in Obsidian.
6. Restart Personal OS.
7. Task appears under CodeCrafters.
8. Mark Task Done in Personal OS.
9. Markdown becomes:

```yaml
status: done
```

10. Project execution progress increases.
11. Edit Task Goal in Obsidian.
12. Restart app.
13. Updated Goal appears.
14. Rename Task file.
15. Restart app.
16. Same Task remains.
17. Modify the same file externally while app holds an older checksum.
18. Attempt to save in app.
19. App detects conflict.
20. Open a Knowledge note.
21. Verify Markdown Preview.
22. Verify Markmap.
23. Delete SQLite projection/cache.
24. Restart.
25. Verify Knowledge/Task/Project/Mission state rebuilds.

**PASS when:**

> The user can keep all durable data in Obsidian Markdown while Personal OS reliably manages goals, plans, status, progress, review, and knowledge retrieval on top of it.

---

# 42. Final Architecture Statement

The final system is:

```text
Obsidian
= Data + Knowledge

Personal OS
= Strategy + Planning + Execution + Review + Retrieval
```

Or more precisely:

> **Obsidian is the user-owned persistence and knowledge layer. Personal OS is the structured strategy/execution engine and interface over that layer.**

This architecture should remain the reference boundary for future development.
