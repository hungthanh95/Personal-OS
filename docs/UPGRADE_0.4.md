# Personal OS 0.4.0

0.4 expands the app from an execution tracker into the full local strategy/evidence loop described by the archived 1.0 specification.

## Added

- Horizon/Initiative/Task-linked causal hierarchy and interactive Strategy map.
- Structured Evidence, configurable readiness weights, assessment deltas and trajectory charts.
- Structured adaptive reviews, events/assumptions, recommendation audit, weekly plan preview and explicit propagation.
- Managed Knowledge sources, section context, FTS5, local semantic embeddings, concepts, duplicates, freshness and session recommendations.
- Richer JD extraction, market/career funnel, salary samples, clusters and interview weakness priorities.
- Ownership Engine, customer discovery, revenue/distribution, Capital contributions and net-worth snapshots.
- Local usage/search telemetry, Quick start, semantics, portable JSON export and category deletion.
- Session `Blocked` state with required blocker and resume/reschedule flow.

## Data migration

Opening an older workspace upgrades it incrementally to schema v13. Existing session rows receive `blocked = 0`; all previous content and settings remain. Restore continues to validate/migrate a staged copy and create a safety snapshot before replacing the active database.

## Compatibility

Windows x64 is supported. The release is portable and unsigned. Keep every ZIP item together. macOS remains source-only and unverified.

## Privacy

Intelligence is local-only; no document, salary, application, goal or review data leaves the device. No provider credentials are accepted or stored.
