You are a senior product engineer, UX architect, and Flutter developer.

I want you to design and implement a local-first application called **Personal OS**.

The application is not another generic todo app, habit tracker, or note-taking app.

Its purpose is to act as a **personal operating system for knowledge workers and engineers**, helping the user connect:

**Life Area → Goal → Project → Experiment → Task/Session → Output → Knowledge**

The most important principle is:

> The application should not only track what the user plans to do. It should track why they are doing it, what result was produced, and whether the activity is helping achieve a meaningful goal.

Do not overbuild the first version.

Build the application around the workflow described below.

---

# 1. Product Vision

Personal OS should answer these questions at any time:

1. What should I focus on today?
2. Why is this task important?
3. Which goal/project does it contribute to?
4. What did I actually produce from my work?
5. Am I spending time on the right things?
6. Which projects am I neglecting?
7. What should I do next?
8. What did I learn?
9. How did this week compare to last week?

The product should feel like a personal **Mission Control / Chief of Staff**, not a task manager.

---

# 2. Target User

Initial target user:

* software engineer
* embedded engineer
* knowledge worker
* technical team lead
* solo builder
* freelancer
* someone learning multiple skills
* someone working on multiple long-term personal goals

Typical life areas:

* Career
* Income
* Learning
* Personal Projects
* Family
* Health
* Finance

---

# 3. Product Philosophy

Follow these principles strictly.

## 3.1 Output > Activity

Do not reward the user merely for checking tasks as done.

Every meaningful session should ideally produce:

* Actual Output
* Learning
* Decision
* Next Action

Example:

Bad:

"Study C++ — Done"

Better:

"Study C++ smart pointers"

Actual Output:

* implemented `unique_ptr` example
* created notes comparing ownership models

Learning:

* understand ownership semantics

Next Action:

* implement `shared_ptr` comparison

---

## 3.2 Goals must connect to execution

Every task/session can optionally link to:

Goal → Project → Session

Example:

Increase engineering income
→ Career Upgrade
→ Modern C++ Learning Path
→ Smart Pointer Session

---

## 3.3 Focus instead of information overload

The UI must be calm.

Do not create dashboards filled with unnecessary charts.

The user should quickly understand:

* what matters now
* current progress
* next action

---

## 3.4 Local-first

Version 1 should work completely offline.

Use local storage.

Do not require:

* cloud account
* login
* server backend
* subscription
* collaboration

Architect the code so cloud sync could be added later.

---

# 4. Technology

Use:

* Flutter
* Dart
* Desktop-first UI
* Windows and macOS support
* SQLite for local database

Recommended packages can be chosen by you, but minimize dependencies.

Use a clean architecture.

Suggested layers:

presentation
domain
application
infrastructure
database

State management can use Riverpod or another simple modern Flutter solution.

Choose one and document the reason.

---

# 5. Navigation

Main navigation should contain:

* Today
* Goals
* Projects
* Knowledge
* Review
* Inbox

At the bottom or top of the navigation include:

* Search
* Settings

Do not add more primary navigation items unless strictly necessary.

---

# 6. Screen 1 — Today

This is the most important screen in the product.

It should feel like a personal command center.

Layout:

Left:
Navigation

Center:
Today's focus

Right:
Life status / weekly overview

Bottom or contextual section:
AI Navigator / Personal Insight

Example structure:

PERSONAL OS

Good evening, [User]

Today's Focus

1. Technical Learning
   21:00–22:00
   Not Started

2. English Session
   22:25–23:25
   Not Started

3. Income Lab
   23:30–00:00
   Not Started

For each session show:

* title
* associated project
* associated goal
* planned time
* duration
* status
* priority

Actions:

* Start Session
* Mark Done
* Mark In Progress
* Skip
* Reschedule

Do not overload this screen.

---

# 7. Session Execution Screen

When the user starts a session, show a focused execution view.

Example:

Modern C++ — Smart Pointer

WHY

Improve C++ capability for future embedded/Linux roles.

INPUT

* Article about `std::unique_ptr`
* Example source code
* previous notes

TODAY'S TARGET

Understand ownership and implement one working example.

START SESSION

Optionally show:

* timer
* elapsed time

When session finishes, open Session Review.

Fields:

Status:

* Done
* In Progress
* Skip

Actual Output:

multi-line text

What Did I Learn?

multi-line text

Next Action:

multi-line text

Optional:

* links
* files
* notes

If status = In Progress:

Next Action should be strongly encouraged.

---

# 8. Goals

Goal examples:

* Increase engineering income
* Become strong in modern C++
* Build second income stream
* Improve English communication
* Build a commercial software product

Goal detail page should contain:

Goal title

Description

Why this matters

Target date

Status:

* Active
* Paused
* Completed
* Abandoned

Progress

Related Projects

Recent Outputs

Recent Sessions

Next Milestone

Do not use fake progress.

Progress should derive from project milestones where possible.

---

# 9. Projects

Projects should represent meaningful initiatives.

Examples:

Career Upgrade

Trace Inspector

Income Lab

English Improvement

Personal OS

Project fields:

* title
* description
* linked goal
* status
* priority
* start date
* target date
* progress
* current milestone
* next action

Statuses:

* Active
* Paused
* Completed
* Archived

Project page layout:

PROJECT NAME

Goal

Current milestone

Progress

NEXT ACTION

Active Tasks / Sessions

Recent Outputs

Knowledge

Timeline / Activity

AI Insight

---

# 10. Outputs

Outputs are a core concept.

An Output is evidence that useful work happened.

Examples:

* GitHub repository
* working prototype
* Excel automation demo
* article
* document
* mindmap
* code sample
* experiment result
* job market research
* learning notes
* decision
* test report

Fields:

* title
* type
* description
* project
* source session
* created date
* link/path
* notes

Provide a simple Output Library.

Do not turn it into a full file manager.

---

# 11. Knowledge

Knowledge should store distilled learning, not random notes.

Possible types:

* Note
* Learning
* Decision
* Lesson Learned
* Reference
* Idea

Fields:

* title
* content
* tags
* related goal
* related project
* source session
* created date
* updated date

Allow basic Markdown.

Keep this feature simple in MVP.

Do not attempt to build a Notion clone.

---

# 12. Inbox

Inbox is a quick capture system.

The user should be able to rapidly capture:

* Task
* Idea
* Project idea
* Learning topic
* Note

Captured items are initially unclassified.

Example:

"Research freelance Excel automation"

Then later the user can convert it to:

Goal:
Second Income

Project:
Income Lab

Session:
Research Excel Automation

Implement a simple triage workflow.

---

# 13. Review

Implement Weekly Review.

Weekly Review should answer:

* How many sessions were planned?
* How many were completed?
* How much time was spent?
* Which goals received attention?
* Which goals were ignored?
* Which projects produced outputs?
* Which projects had activity but no output?
* Which projects have been inactive?

Show:

Weekly Completion

Focused Time

Outputs Produced

Goals Worked On

Projects Neglected

Important Lessons

Recommended Next Actions

Use simple visualizations only when useful.

---

# 14. AI Navigator

Design the application so AI can later be connected.

For MVP, AI can operate through a deterministic rules-based Insight Engine.

Do not require an LLM API.

The Insight Engine should generate useful observations such as:

"You spent four sessions researching side hustles but produced no experiment."

"You have nine active projects. Four have not received any activity for 21 days."

"Career received 65% of your focused time this week."

"Income Lab has received three research sessions but no output."

"You completed 80% of planned sessions."

"Project X has been active for 30 days without a milestone being completed."

"Your goal 'Improve C++' has received no activity for two weeks."

Create the architecture so an LLM provider can replace or supplement the rule engine later.

Create an interface such as:

InsightProvider

with implementations:

RuleBasedInsightProvider

Future:

OpenAIInsightProvider

Do not implement OpenAI integration yet.

---

# 15. Life Status

Today screen should contain a small Life Status area.

Example:

Career     72
Income     41
Learning   83
Health     58

Do NOT pretend these values are scientifically accurate.

For MVP, calculate a simple Activity Score based on:

* active goals
* recent sessions
* completed milestones
* inactivity

Clearly name it:

Activity Score

rather than Life Score.

---

# 16. Life Map

Create a Life Map screen or component.

It should visualize:

Life Area
→ Goal
→ Project
→ Experiment / Milestone

Example:

Career
├── Increase Engineering Income
│   ├── Modern C++ Path
│   ├── Linux Path
│   └── Job Market Research
│
Income
├── Build Second Income
│   ├── Freelance
│   ├── Product
│   └── Content

Do not build an overly complex graph editor.

Version 1 can use a clean hierarchical visualization.

This can become a signature feature of Personal OS.

---

# 17. Data Model

Design the database approximately around these entities:

LifeArea

Goal

Project

Milestone

Session

Task

Output

KnowledgeItem

InboxItem

WeeklyReview

Insight

Recommended relations:

LifeArea
1 → many Goals

Goal
1 → many Projects

Project
1 → many Milestones

Project
1 → many Sessions

Session
1 → many Outputs

Session
1 → many KnowledgeItems

Project
1 → many Outputs

Project
1 → many KnowledgeItems

Avoid excessive normalization if it hurts simplicity.

Create proper repository abstractions.

---

# 18. Session Status

Use:

PLANNED

ACTIVE

DONE

IN_PROGRESS

SKIPPED

CANCELLED

Store:

planned start

planned duration

actual start

actual end

actual duration

---

# 19. Dashboard Logic

Today's screen should prioritize sessions based on:

1. scheduled time
2. user priority
3. associated goal priority
4. overdue status

Do not allow AI to arbitrarily reorder the user's schedule.

AI can recommend changes but user remains in control.

---

# 20. Search

Global search should search across:

* Goals
* Projects
* Sessions
* Outputs
* Knowledge

Keyboard shortcut:

Ctrl/Cmd + K

---

# 21. Keyboard UX

Desktop UX should support keyboard use.

Recommended shortcuts:

Ctrl/Cmd + K
Search

Ctrl/Cmd + N
Quick Capture

Space
Start selected session where appropriate

Esc
Close dialog

Do not over-engineer shortcuts.

---

# 22. Visual Design

Style:

* modern
* calm
* minimal
* professional
* slightly futuristic
* productivity / command center feel

Avoid:

* excessive gradients
* neon cyberpunk
* giant cards everywhere
* excessive shadows
* childish gamification
* cluttered dashboards

Preferred structure:

Left sidebar:
220–240px

Main content:
fluid

Right contextual panel:
260–320px when necessary

Use:

* rounded cards
* subtle borders
* generous spacing
* clean typography

Support:

* Light Mode
* Dark Mode

Recommended visual inspiration:

Linear
Raycast
Arc
Things
Notion Calendar
modern developer tools

Do not directly copy any product.

---

# 23. Home UI Concept

Use this layout as inspiration:

+-------------------------------------------------------------+
| PERSONAL OS                           Fri, Sep 11             |
+-------------+---------------------------+-------------------+
|             |                           |                   |
| TODAY       | GOOD EVENING              | ACTIVITY STATUS   |
|             |                           |                   |
| Goals       | Today's Focus             | Career       72   |
| Projects    |                           | Income       41   |
| Knowledge   | [Technical Learning]      | Learning     83   |
| Review      | 21:00 - 22:00             |                   |
| Inbox       |                           | THIS WEEK         |
|             | [English Session]         |                   |
|             | 22:25 - 23:25             | 8 / 10 sessions  |
|             |                           | 3 outputs         |
|             | [Income Lab]              |                   |
|             | 23:30 - 00:00             |                   |
|             |                           |                   |
+-------------+---------------------------+-------------------+
| AI NAVIGATOR                                                |
|                                                             |
| You researched side hustles four times but shipped no       |
| experiment. Consider building one small prototype tonight.  |
|                                                             |
| [Start Focus] [Change Plan] [View Insight]                  |
+-------------------------------------------------------------+

---

# 24. Empty States

Every screen needs good empty states.

Examples:

No Projects

"Projects turn goals into concrete initiatives."

[Create First Project]

No Outputs

"Outputs are evidence of progress."

[Record Output]

No Knowledge

"Capture something worth remembering."

[Create Note]

Avoid generic:

"No data found."

---

# 25. Seed Data

Create realistic demo data so the application feels complete on first run.

Example Life Areas:

Career

Income

Learning

Personal

Example Goals:

Increase Engineering Income

Build Second Income

Improve English Communication

Become Strong in Modern C++

Example Projects:

Career Upgrade

Modern C++ Path

Income Lab

English Improvement

Personal OS

Example Today sessions:

21:00–22:00
Modern C++ — Smart Pointers

22:25–23:25
English Speaking Session

23:30–00:00
Income Lab — Research Excel Automation

---

# 26. MVP Scope

Version 0.1 MUST include:

Today

Goals

Projects

Sessions

Session Review

Outputs

Knowledge

Inbox

Weekly Review

Rule-based Insights

SQLite persistence

Dark / Light mode

Demo seed data

Search

Basic settings

Life Map

Do NOT implement:

Cloud sync

User account

Multi-user

Mobile app

Notifications

Calendar synchronization

Google Calendar

Notion integration

OpenAI integration

Payment

Subscription

Team collaboration

Full file storage

Habit tracking

Finance management

Health tracking

Complex graph editing

Plugins

Marketplace

Gamification

Do not add features outside this MVP unless they are necessary for application infrastructure.

---

# 27. Code Quality

Use production-quality structure.

Requirements:

* understandable folder structure
* typed domain models
* repository abstractions
* clear error handling
* database migrations
* reusable widgets
* theme system
* no giant widgets
* avoid files with thousands of lines
* avoid business logic inside UI widgets

Add comments only where useful.

Avoid excessive abstraction.

---

# 28. Testing

Add tests for important domain logic.

At minimum test:

Session status transition

Weekly metrics calculation

Activity Score

Project inactivity detection

Goal inactivity detection

Insight rules

Database repository basic operations

---

# 29. Development Strategy

Do not try to implement the entire app in one huge step.

Work incrementally.

Phase 1:

Project architecture

Database

Theme

Navigation shell

Seed data

Phase 2:

Today screen

Sessions

Session execution

Session review

Phase 3:

Goals

Projects

Milestones

Phase 4:

Outputs

Knowledge

Inbox

Phase 5:

Weekly Review

Rule-based Insights

Life Map

Phase 6:

Polish

Search

Keyboard shortcuts

Empty states

Testing

---

# 30. First Task

Before writing implementation code:

1. Analyze the product requirements.
2. Identify any inconsistencies.
3. Propose the final architecture.
4. Define the folder structure.
5. Define the database schema.
6. Define domain models.
7. Define navigation.
8. Define the design system.
9. Define implementation phases.
10. Create a concise implementation plan.

Save these documents under:

docs/

Create:

docs/PRODUCT.md

docs/ARCHITECTURE.md

docs/DATA_MODEL.md

docs/DESIGN_SYSTEM.md

docs/IMPLEMENTATION_PLAN.md

After those documents are complete, begin implementing Phase 1.

Do not ask for confirmation between every phase.

Make reasonable engineering decisions and continue.

If a requirement is ambiguous, prefer:

simplicity

> maintainability
> local-first
> clear UX
> extensibility

Do not expand the scope.

---

# 31. Definition of Done for MVP

The MVP is complete when a user can:

1. Open Personal OS.

2. See today's sessions.

3. Understand which Goal and Project each session contributes to.

4. Start a session.

5. Finish a session.

6. Record:

   * status
   * actual output
   * learning
   * next action

7. Navigate to a Project.

8. See its:

   * progress
   * sessions
   * outputs
   * knowledge
   * next action

9. Navigate to a Goal.

10. See connected Projects.

11. Quickly capture an idea in Inbox.

12. Convert the Inbox item into a Goal, Project, Session, or Knowledge item.

13. View outputs created from previous sessions.

14. Run a Weekly Review.

15. Receive meaningful rule-based Insights.

16. View Life Map.

17. Search information globally.

18. Close and reopen the application without losing data.

The product should already feel useful without any AI API.

The core value must come from its information architecture and workflow, not from an LLM.

---

# 32. Final Product Principle

Whenever deciding whether to add a feature, ask:

> Does this help the user decide what matters, execute it, capture the result, or learn from it?

If the answer is no, do not add it.

Build Personal OS as a calm personal Mission Control for turning goals into concrete outputs.
