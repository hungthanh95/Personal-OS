# Personal OS 0.2.0 — Strategy foundation

Implementation against `PERSONAL_OS_PRODUCT_SPEC.md`, 2026-09-12.

## Available in this release

- Six primary destinations: Today, Mission, Strategy, Projects, Knowledge, Review. Inbox and Settings remain utilities. Legacy Goals/Life Map remain available within Mission.
- SQLite schema v2 adds visions, strategies, missions, outcomes, skills, evidence assessments, assumptions, proposals, strategy versions and period reviews. Migration preserves existing records and does not reinterpret old goals as missions automatically.
- Strategy offers an optional JSON-backed starter example. Loading it is explicit, transactional and allowed only before a vision exists. All starter entities are normal editable data; strategy edits go through proposals. No synthetic readiness or completed outcomes are seeded.
- Missions link to a legacy goal, connecting its projects and sessions to strategy and vision. Today shows the highest-priority active mission. Session WHY includes the full available relationship path.
- Outcome progress uses weighted attainment, capped at 100% per outcome. This is manually entered outcome attainment, not automatically inferred from evidence.
- Skill readiness uses latest verified manual assessments per dimension: Knowledge 15%, Implementation 20%, Debugging 20%, Application 20%, Interview 15%, Production 10%. Every assessment requires an existing output. Missing dimensions contribute zero. Assessments are append-only through the repository. A replacement assessment preserves prior history. Study hours do not change readiness.
- Assumption tracking with confidence and supporting/contradicting evidence context entered by the user.
- Strategy proposals support Accept, Modify, Reject. Acceptance atomically stores before/after snapshots, applies title, description and optional engine/allocation changes, and records the decision. Decided proposals and stored snapshots cannot be edited through the repository. Existing future sessions remain explicit user plans; they are not rescheduled by strategy acceptance.
- Weekly review retained; Monthly, Quarterly, Annual and Event-Driven review journals added. Reviews do not silently modify strategy.
- TXT/Markdown/DOCX import, UTF-8 extraction, source path preservation, editable skill/mission/project links and keyword search via Ctrl/Cmd+K. Reimporting an identical source path opens the existing item for review before saving. Failed extraction does not save a note. Original source path is selectable; source files are not bundled into the database.
- Settings can export a consistent live SQLite snapshot using VACUUM INTO. Existing destination files are not overwritten. To restore, close the app, preserve the current database, and copy the backup to the database path shown in Settings.

## Getting started with existing data

1. Open Strategy. Create your vision and strategy, or choose **Load editable starter strategy**.
2. Open Mission and edit a mission to link an existing goal. Its projects and sessions then acquire a strategy/vision WHY path.
3. Add measurable outcomes and skills.
4. Finish sessions and capture outputs. Expand a skill in Mission, choose **Link output & assess dimension**, and explicitly verify the assessment when appropriate.
5. Import and link reference documents in Knowledge. Search across content with Ctrl/Cmd+K.
6. Record reviews. Propose and explicitly accept strategic changes in Strategy.
7. Export a database backup in Settings.

## Remaining specification work

This is a strategy foundation release, not completion of the full MVP–V5 roadmap.

- PDF and legacy DOC parsing, OCR, direct source opening and managed source-file storage are not implemented. Convert to TXT or DOCX before import.
- No LLM provider, document summarization, generated review, AI priority planning or semantic retrieval. Existing insights are labeled rule-based. Strategy proposals in this release are user-authored.
- No editable recurring weekly schedule template, separate horizons/initiatives, interactive zoom graph, configurable readiness weights, structured many-to-many evidence relationships or automatic strategy-to-planning propagation.
- No job/JD aggregation, application/interview pipeline, Income Lab experiments, market connectors, capital snapshots or V3–V5 intelligence modules.
- Period review evidence and assumption evidence are text context, not validated evidence ID relations. Quarterly/annual/event review forms do not automatically detect market changes.
- UI labels remain English, matching the existing application.
- Windows release is validated here. macOS needs its own native build and runtime validation.

## Design constraints

Keep actual performance claims separate from unmeasured targets. No launch/search performance benchmarks have been collected. No real user database was opened or reset during development. Repository tests use isolated temporary SQLite files.
