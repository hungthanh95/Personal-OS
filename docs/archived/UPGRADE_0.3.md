# Personal OS 0.3.0 — Weekly execution and feedback loops

Source implementation against `PERSONAL_OS_PRODUCT_SPEC.md`, 2026-09-12. This checkpoint has not yet replaced the packaged 0.2.0 Windows release.

## Added in this source checkpoint

- Schema v3 adds jobs, detected requirements, applications, interviews, interview questions, learning priorities and Income Lab experiments. Existing v1/v2 databases migrate in place.
- Career workspace accepts up to 50 pasted job descriptions per import, prevents duplicate mission/JD pairs, matches against skills already defined on the mission and compares observed demand with verified readiness. Recommendations show their evidence and confidence.
- Application and interview records form a visible pipeline. A Fail or Partial question can be converted once into a sourced learning priority; the converted question is then immutable.
- Income Lab enforces a concrete next action for every experiment unless the user explicitly marks it Killed. The dashboard shows active, promising and killed counts.
- Strategy approvals now maintain sequential version numbers and previous-version links. The Strategy screen compares changed snapshot fields between versions.
- Schema v4 adds project types, Knowledge summaries, session templates and recurring schedules. Recurrence generation is idempotent, keeps 21 days available automatically and supports a manual 12-week horizon.
- Projects can link directly to a mission outcome. The session Why Path uses that link to show session → project → outcome → mission → strategy → vision, with legacy Goal linkage as a fallback.
- TXT, Markdown, DOCX and text-based PDF import. A deterministic local helper proposes a short summary, tags and matching skill/project/mission links in the editable form before anything is saved.
- Settings can restore an exported SQLite backup. Restore validates and migrates a staged copy, saves the active database as a timestamped safety snapshot, and only then swaps databases.
- Global search includes titled strategy, career and experiment records and opens them in an appropriate context instead of treating every result as Knowledge.

## Human-control rules

- Job matching, summaries, tags, links and next-week priorities are local rule-based suggestions. Users review or explicitly add them; they do not rewrite strategy or validate evidence.
- Strategy records change only through an accepted proposal. Stored versions remain immutable.
- Verified readiness still requires a user-confirmed assessment linked to an output.
- Recurrence edits rebuild future PLANNED occurrences only. Completed session history remains intact.

## Current limits

- PDF support targets PDFs with extractable text in ordinary PDF text operators. Scans and documents with unsupported custom font mappings need OCR or conversion to TXT/DOCX.
- JD parsing is local phrase matching against mission skills. It does not crawl URLs, infer years of experience or contact external market services.
- There is no LLM provider, embeddings, semantic retrieval, cloud sync, account, financial connection or automatic market monitoring.
- Period reviews use user-entered evidence context. Trend ingestion and automated assumption review remain future work.
- The strategy view shows the causal hierarchy and version comparison but does not yet provide a zoomable canvas or separate Horizon/Initiative entities.
- The 0.3.0 Windows binary has not been built in the current sandbox. Use `flutter run -d windows` from source until a verified package is produced.

## Verification completed here

- All changed Dart files were formatted.
- Targeted static analysis passed for domain, controller and Flutter screens that resolve without the restricted external Pub cache.
- SQLite migrations v1 through v4 executed in memory: 31 tables, Knowledge summary and project type columns present, and duplicate recurring occurrences rejected.
- Repository/widget tests were expanded for JD aggregation, interview conversion, strategy version sequencing, experiment constraints, PDF extraction, metadata suggestions and recurring generation. The complete Flutter suite still needs a rerun when the Flutter SDK lockfile and Pub cache are writable.
