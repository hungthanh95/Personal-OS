# Personal OS — Product v0.1

## Intent
A calm, offline mission control connecting Life Area → Goal → Project → Milestone / Experiment → Session → Output → Knowledge. Useful work is evidenced by outputs, learning, decisions and next actions, not checkboxes.

## Scope and decisions
- Desktop Flutter for Windows and macOS; SQLite; no accounts, backend or AI API.
- Six destinations: Today, Goals, Projects, Knowledge, Review, Inbox. Search and Settings are utilities.
- Output Library is a tab within Knowledge. Life Map is a tab within Goals. Execution is a focused route.
- Experiment is a milestone kind (hypothesis in description), not a separate experiment management system.
- A Task is a lightweight project next action; Sessions schedule execution. Linking is optional; project-linked records derive their goal to prevent contradictory links.
- Session review creates separate Output and Learning records atomically. Empty output is allowed: activity without output must remain visible, never fabricate evidence.
- Milestone completion drives progress; no milestones means “Not measured”, never a fictional percentage.
- Activity Score is an explicitly approximate 0–100 heuristic, not well-being measurement.
- Insights are deterministic, explainable and never reorder schedules.
- Demo data is labeled and can be replaced by an empty workspace through Settings. Seed only on database creation.

## Core acceptance journey
Open Today → inspect why/project/goal → start session → review status, output, learning, next action → see linked evidence in project and goal → capture and triage inbox → inspect week comparison and insights → browse Life Map/search → restart without data loss.

## Constraints resolved
“AI Navigator” is named Personal Insight for clarity; provider interface preserves future integration. Timers measure recorded active intervals, including app suspension until the user ends a session; manual duration correction is offered at review. Weeks start Monday in local time; event timestamps stored as epoch milliseconds. Cancelled sessions do not enter completion denominator. Planned count follows planned date; focused time follows actual recorded intervals, outputs their creation dates. Session ordering: scheduled instant, session priority, goal priority, overdue tie-break; user schedule always wins.

See ORIGINAL_REQUIREMENTS.md for the unmodified specification.
