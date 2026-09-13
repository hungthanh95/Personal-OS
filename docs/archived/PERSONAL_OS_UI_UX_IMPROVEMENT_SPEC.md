# Personal OS — UI/UX Redesign Specification

**Version:** 2.0  
**Status:** Design target for implementation agents  
**Primary goal:** Redesign the current Personal OS UI around a clear desktop dashboard, simplified workflows, and progressive disclosure while preserving the existing domain model and functionality.

---

# 1. Visual North Star

Use the supplied dashboard mockup as the visual and interaction reference.

The target feeling is:

- modern Windows/Web desktop app,
- calm and premium,
- light surfaces with subtle depth,
- clear hierarchy,
- strong dashboard summary,
- visually motivating without childish gamification,
- focused on progress, trajectory, and next actions,
- minimal exposure of internal system complexity.

The app must feel like a **personal mission-control system**, not a CRUD/admin tool.

---

# 2. UX Principles

## 2.1 Dashboard first

The default launch screen is **Dashboard**, not Today.

Dashboard answers:

1. What is my current mission?
2. Am I on track?
3. What are my biggest gaps?
4. What should I do today?
5. What are my current priorities?
6. What progress/wins did I create recently?

Today remains the execution screen.

---

## 2.2 One primary action per screen

Examples:

```text
Dashboard → Continue / Plan next
Today     → Start session
Mission   → Plan biggest gap
Projects  → Continue project
Knowledge → Search / Import
Review    → Start review
```

Avoid multiple same-level actions.

---

## 2.3 Progressive disclosure

Default screen:

```text
Summary
```

Then:

```text
Details
```

Then:

```text
Advanced
```

Do not expose advanced strategy entities, embeddings, audits, diagnostics, or internal recommendation mechanics in the primary UI.

---

## 2.4 Preserve functionality, reduce visibility

Do not delete current capabilities unless broken.

Instead classify UI into:

### Tier 1 — Always visible

```text
Dashboard
Mission
Projects
Strategy
Knowledge
Review
Settings
```

### Tier 2 — Contextual

```text
Career workspace
Income Lab
Trajectory
Assumptions
Strategy history
Ownership / Capital
```

### Tier 3 — Advanced

```text
Embeddings
Retrieval diagnostics
Context-sharing audit
Technical telemetry
Recommendation internals
Database path
```

---

# 3. Navigation

Recommended sidebar:

```text
Dashboard
Missions
Projects
Strategy
Knowledge
Review
Settings
```

Optional:

```text
Inbox
```

Do not show low-level modules in navigation.

Dashboard must be selected after launch.

---

# 4. Dashboard — Main Design Target

## 4.1 Layout

Desktop layout:

```text
┌─────────────────────────────────────────────────────────────────────┐
│ Top bar: Logo | Search | Notifications | User                     │
├──────────────┬───────────────────────────────────────┬──────────────┤
│ Sidebar      │ Main dashboard                       │ Right rail   │
│              │                                      │              │
│ Dashboard    │ Active Mission hero                  │ Today        │
│ Missions     │                                      │              │
│ Projects     │ Engine summary cards                 │ Priorities   │
│ Strategy     │                                      │              │
│ Knowledge    │ Skill Readiness | Weekly Progress    │ Recent Wins  │
│ Review       │                                      │              │
│ Settings     │                                      │              │
└──────────────┴───────────────────────────────────────┴──────────────┘
```

---

## 4.2 Active Mission Hero

The hero is the strongest element on Dashboard.

Content:

```text
ACTIVE MISSION

Job Switch 2027
Higher-paying C++ / Linux / Automotive role

58% progress

Status:
On track

Optional:
target window
short motivation line
```

Required:

- mission title,
- mission subtitle,
- progress,
- status,
- open mission action.

Avoid:

- edit controls,
- raw IDs,
- strategy internals,
- multiple action buttons.

A soft visual/banner image may be used, but it must remain subtle and not reduce readability.

---

## 4.3 Engine Summary

Show three compact cards:

```text
Career Engine
Ownership Engine
Capital Engine
```

Each card contains only:

```text
Name
Short purpose
Current status / progress
Small progress bar
```

Example:

```text
Career Engine
Skills → Opportunities
68%
```

Do not show detailed Ownership/Capital records here.

---

## 4.4 Skill Readiness

Use a clean chart or compact bars.

Recommended initial categories:

```text
Modern C++
Linux/System
Interview
English
Job Pipeline
```

Purpose:

> Show capability gaps immediately.

Do not show all skills.

Show only the 4–6 skills most relevant to the active mission.

Include:

```text
View details →
```

---

## 4.5 Weekly Progress

Display only mission-relevant execution metrics.

Example:

```text
Technical     65%
English       40%
Applications  35%
Income Lab    20%
```

Alternative metrics:

```text
5 / 7 sessions
6h 30m focused
3 outputs
2 applications
```

Avoid dense analytics.

---

## 4.6 Right Rail — Today

Compact timeline:

```text
TODAY

21:00 Technical
CodeCrafters / C++ practice

22:25 English
Listening & speaking

23:30 Career & Income Sprint
Job search / applications / Income Lab
```

Clicking an item opens the session detail or Today screen.

Dashboard must not become a replacement for Today.

---

## 4.7 Right Rail — Top Priorities

Maximum 3–4 items.

Example:

```text
1. CodeCrafters
2. Linux IPC & sockets
3. Review job descriptions
4. Update CV & LinkedIn
```

Priority source must be deterministic where possible:

```text
mission relevance
+
skill gap
+
deadline
+
explicit user priority
```

Avoid AI dependency.

---

## 4.8 Right Rail — Recent Wins

Show evidence-based wins.

Example:

```text
✓ Passed CodeCrafters stage 14
✓ 2 job applications sent
✓ Improved Linux IPC knowledge
```

Only real outputs/evidence count.

Do not use XP, levels, badges, or fake motivational metrics.

---

# 5. Dashboard Data Rules

Dashboard values must be explainable and deterministic.

## Mission Progress

Use existing outcome/mission progress logic.

## Skill Readiness

Use verified evidence only.

## Top Priority

Suggested score:

```text
Priority Score =
Mission Relevance
× Gap Size
× Urgency
```

Optional career weighting:

```text
× Market Demand
```

## Recent Wins

Newest verified evidence linked to active mission.

## Weekly Progress

Use:

```text
completed / planned sessions
focused time
outputs/evidence created
applications/interviews
```

---

# 6. Today Screen

Purpose:

> Execute today's work quickly.

## 6.1 Layout

```text
TODAY

PRIMARY FOCUS
────────────────────────

21:00–22:00
Modern C++ — Smart Pointers

Why
Modern C++
→ Interview Readiness
→ Job Switch

Target
Complete one practical exercise.

[Start session]


LATER TODAY
────────────────────────

22:25 English
23:30 Career & Income Sprint


THIS WEEK
────────────────────────

5 / 7 sessions
6h 30m focused
3 evidence items
```

---

## 6.2 Rules

- One session visually dominant.
- Secondary sessions use compact rows.
- `Plan session` is secondary.
- `Recurring plan` moves to overflow / secondary menu.
- Remove large non-actionable “insight” cards from the main flow.

---

# 7. Session Workflow

## Before session

Show:

```text
Title
Time
Why
Input
Target
Related Knowledge
```

Primary:

```text
Start
```

Secondary:

```text
Reschedule
Skip
More
```

---

## During session

Show:

```text
Timer
Target
Input
Quick note
Pause
Finish
```

No unrelated controls.

---

## Finish session

Compact form:

```text
What did you produce?
[ multiline ]

What did you learn?
[ optional ]

Next action
[ optional ]

Evidence
[ Add ]

[Save & finish]
```

Target:

- start work within 2 clicks,
- finish and record result within 60 seconds.

---

# 8. Mission Screen

Mission is the detailed progress screen.

Example:

```text
JOB SWITCH 2027

Status        On Track
Progress      58%
Confidence    72%
Target        6–12 months


CURRENT → TARGET
────────────────────────

Modern C++     62 → 80
Linux          55 → 80
Interview      42 → 75
English        70 → 80


TOP GAPS
────────────────────────

1. Linux IPC
2. C++ Concurrency
3. Interview Reasoning


RECENT EVIDENCE
────────────────────────

✓ CodeCrafters stage passed
✓ shared_ptr exercise
✓ SOME/IP mock interview


CAREER PIPELINE
────────────────────────

Jobs reviewed      18
Applied             4
Interviews          2
Offers              0
```

Advanced mission metadata goes behind:

```text
Details
Edit
Strategy context
```

---

# 9. Strategy Screen

Current Strategy UI must be simplified heavily.

Default view must be visual and read-first.

Example:

```text
Financial Independence 2043
          │
 ┌────────┼─────────┐
 Career  Ownership  Capital
   │
Job Switch 2027
   │
 ├─ C++
 ├─ Linux
 ├─ Automotive
 └─ English
```

Selected node panel:

```text
Job Switch 2027

Purpose
Increase salary and technical market value.

Status
Active

Evidence
12 items

Assumptions
3

[Open mission]
[Edit]
```

Creation actions collapse into:

```text
+ Add
```

Menu:

```text
Vision
Strategy
Mission
Assumption
```

Do not show all of these simultaneously:

```text
New visions
New horizons
New strategies
New assumptions
New proposals
New recommendations
```

---

# 10. Projects Screen

Default to active work.

Example:

```text
ACTIVE PROJECTS

CodeCrafters
74%
Next: concurrency stage
Linked mission: Job Switch

Trace Inspector
Maintenance
Next: investigation experiment

Income Lab
Experiment
Next: improve Excel demo
```

Each project card shows:

```text
Title
Type
Status
Progress
Next Action
Linked Mission
```

Detail screen may show:

```text
Milestones
Tasks
Sessions
Outputs
Evidence
Knowledge
Skills
```

---

# 11. Knowledge Screen

Default behavior must be search-first.

Example:

```text
Search your knowledge...
[ Import ]

Recent
- Linux IPC
- Effective Modern C++
- SOME/IP debugging

Relevant to current mission
- Smart pointers
- Linux sockets
- Interview questions
```

Advanced tabs:

```text
Concept Graph
Semantic Search
Duplicates
Freshness
```

Do not lead with embeddings or AI terminology.

---

# 12. Review Screen

Review should behave like a guided workflow.

## Weekly

```text
WEEKLY REVIEW

Planned        7
Completed      5
Evidence       3
Blocked        1

What went well?
[ ]

What slipped?
[ ]

Biggest learning?
[ ]

Carry forward
[ ]

Next-week focus
[ ]

[Complete review]
```

Target completion time:

```text
≤10 minutes
```

---

## Quarterly

Focus only on strategic questions:

```text
Is the current mission still correct?
Which assumptions changed?
What changed in the market?
Which skill deserves more/less attention?
Should resource allocation change?
```

Do not expose internal recommendation mechanics unless expanded.

---

# 13. Settings Redesign

Use sections:

```text
Appearance
Data
Privacy
Readiness
Advanced
```

Advanced contains:

```text
Database path
Startup latency
Search latency
Context-sharing audit
Technical diagnostics
```

The default Settings screen should not resemble a debug console.

---

# 14. Visual Style

Use the supplied mockup as reference.

## General

- very light neutral background,
- white cards,
- soft blue/green/purple accents,
- subtle shadow,
- rounded corners,
- generous but controlled spacing,
- modern desktop proportions.

## Layout

```text
Sidebar             210–230 px
Top bar             64–72 px
Main content        flexible
Right rail          300–340 px
Content gap         16–20 px
Page padding        20–28 px
Card radius         14–18 px
```

## Typography

```text
Hero title          30–36
Page title          28–32
Section heading     18–20
Card title          16–18
Body                14–16
Metadata            12–13
```

---

# 15. Color Usage

Avoid a monochrome “all green” UI.

Use:

```text
Blue    → Career / primary progress
Green   → on-track / completion
Purple  → Ownership / secondary engine
Gold    → capital / wins / attention
Red     → blocked / risk
Neutral → secondary UI
```

Color never replaces labels.

---

# 16. Button Hierarchy

## Primary

Filled color.

Examples:

```text
Start session
Plan gap
Complete review
```

## Secondary

Outline / neutral.

Examples:

```text
Plan session
Open mission
Import
```

## Tertiary

Text/icon only.

Examples:

```text
View details
Edit
More
```

Avoid multiple filled buttons on one screen.

---

# 17. Empty States

Current empty screens feel unfinished.

Every empty state must show:

```text
What this area is for
Why it matters
One primary next action
Optional example
```

Example Mission empty state:

```text
No active mission yet.

A mission connects daily work to a measurable outcome.

[Create mission]

Example:
Job Switch 2027
```

---

# 18. Workflow Optimization

## Daily

```text
Dashboard
→ Today
→ Start session
→ Finish
→ Record output/evidence
```

## Weekly

```text
Review
→ Planned vs actual
→ Evidence
→ Biggest gap
→ Next-week focus
→ Adjust sessions
```

## Quarterly

```text
Mission trajectory
→ Market / career evidence
→ Assumptions
→ Current vs Target
→ Continue / Adjust / Stop
```

---

# 19. AI Policy

Current redesign phase is **deterministic-first**.

Do not add:

- chat assistant,
- LLM sidebar,
- external AI providers,
- autonomous planning,
- automatic strategy rewriting,
- multi-agent orchestration.

Existing local deterministic logic may remain.

The UI must work fully without AI.

---

# 20. Implementation Order

## UX-1 — Dashboard

Implement first:

- dashboard route,
- default launch screen,
- mission hero,
- engine cards,
- skill readiness,
- weekly progress,
- Today rail,
- priority list,
- recent wins.

## UX-2 — Today

- primary focus card,
- compact later sessions,
- simplified start/finish flow.

## UX-3 — Mission + Strategy

- mission progress view,
- Current → Target,
- top gaps,
- evidence,
- visual strategy map,
- collapse creation controls.

## UX-4 — Projects + Knowledge + Review

- active-first projects,
- search-first knowledge,
- guided review.

## UX-5 — Settings + Polish

- move diagnostics to Advanced,
- responsive layout,
- keyboard flow,
- empty states,
- dark mode,
- copy cleanup.

---

# 21. Acceptance Criteria

## Dashboard

- [ ] Default screen after launch.
- [ ] Active mission immediately visible.
- [ ] Mission progress visible.
- [ ] Career / Ownership / Capital summary visible.
- [ ] 4–6 active skill readiness items visible.
- [ ] Weekly progress visible.
- [ ] Today timeline visible.
- [ ] Top priorities visible.
- [ ] Recent evidence/wins visible.
- [ ] No more than 8 dashboard regions/cards.
- [ ] No advanced technical/internal information.

## Daily workflow

- [ ] Start primary session in ≤2 clicks.
- [ ] Finish session and record output in ≤60 seconds.
- [ ] Why Path is easy to access.
- [ ] Secondary actions do not compete visually.

## Mission

- [ ] Current → Target visible.
- [ ] Biggest gaps ranked.
- [ ] Evidence visible.
- [ ] Career funnel summarized.

## Strategy

- [ ] Visual hierarchy is default.
- [ ] One `+ Add` action replaces button wall.
- [ ] Selected node has contextual details.

## Review

- [ ] Weekly review achievable in ≤10 minutes.
- [ ] Quarterly review surfaces only meaningful strategy decisions.

---

# 22. Explicit Non-Goals

During this redesign, do NOT:

- add new product modules,
- add new entities,
- add more charts,
- add more top-level navigation,
- rewrite persistence,
- redesign the domain model,
- add cloud sync,
- add social features,
- expand AI.

The current problem is **presentation and workflow**, not missing features.

---

# 23. Final Design Standard

The target experience is:

```text
I open the app.
I immediately know my mission.
I can see if I am progressing.
I know my biggest gap.
I know what I should do today.
I can start work quickly.
I can review progress without getting lost.
```

The final product should feel like:

> **A calm, modern personal mission-control dashboard.**
