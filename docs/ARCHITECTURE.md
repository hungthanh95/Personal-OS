# Architecture — Personal OS 0.4

## Runtime shape

Personal OS is a single-user Flutter desktop app with an offline-first SQLite database. The production Windows build contains no account, network provider or cloud synchronization path.

| Layer | Responsibility |
| --- | --- |
| `lib/domain` | Immutable entities, status transitions, metrics, readiness, career/knowledge rules and intelligence contracts |
| `lib/application` | `AppController` commands and UI refresh orchestration |
| `lib/infrastructure` | SQLite repository, transactions, parsing, retrieval, backup/restore and local telemetry |
| `lib/database` | Ordered schema migrations v1–v13 |
| `lib/presentation` | Material desktop shell, six primary destinations, details, dialogs and charts |
| `test` | Domain, repository, migration, forms and widget coverage |

`ChangeNotifier` and `ListenableBuilder` keep state explicit and small. `WorkspaceRepository` is the write/persistence boundary. `IntelligenceProvider` is the structured intelligence boundary; `LocalIntelligenceProvider` implements summaries, embeddings, weekly priorities and adaptive review without network access.

## Data flow and control

The causal path is Vision → Horizon → Strategy → Mission → Outcome → Initiative → Project → Task/Session → Output/Evidence. A completed session can atomically record duration, Output, Knowledge and Next Action. Verified Evidence feeds readiness. Reviews create structured recommendations and decision audit records. Strategy changes require user action and planning changes require a separate preview/approve/apply flow.

Repository transactions enforce single active session, terminal-state protection, immutable decision history, source-link consistency, idempotent recurrence/import and restore staging. Foreign keys are enabled for every connection.

## Retrieval

Knowledge import preserves a managed local source and metadata. SQLite FTS5 supplies exact retrieval; a deterministic local embedding provider supplies semantic similarity; concepts and Knowledge links supply graph relevance. Results merge these scores and expose source, section, offset, snippet and relationship. Search events record local result count and duration for QA.

## Privacy boundary

Only Local-only mode is enabled. The provider boundary reports included categories and whether data leaves the device. `context_sharing_audit` exists for future provider integrations; 0.4 performs no off-device calls and accepts no credentials. Portable JSON export and category deletion sit behind explicit user actions.

## Platform

Windows x64 is the supported 0.4 release target. The macOS runner remains in source as a porting base; it is not a verified release target until built, signed and tested on macOS.
