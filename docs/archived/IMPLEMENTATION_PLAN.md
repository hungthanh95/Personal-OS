# Implementation plan

The original six phases below describe the 0.1 execution baseline. The 0.2 strategy foundation and 0.3 weekly/career expansion are documented in `UPGRADE_0.2.md` and `UPGRADE_0.3.md`.

1. Foundation: scaffold Windows/macOS Flutter, typed entities/repository, SQLite schema, demo seed, theme, six-destination shell.
2. Execution: today schedule, session planning/start/reschedule/skip, timer, transactional review with output and learning.
3. Direction: goal/project CRUD, milestones/experiments, derived progress and linked detail views.
4. Evidence: outputs, Markdown knowledge, inbox quick capture and transactional conversion.
5. Reflection: weekly comparison, saved reflections, deterministic insight provider, activity score, Life Map.
6. Polish/verify: global search, shortcuts, settings/empty states, domain/repository/widget tests, Windows build and visual checks.

## Verification gates
`dart format`, `flutter analyze`, `flutter test`, `flutter build windows`. Test transitions including double review and active uniqueness; week boundaries/cross-midnight/ignored goals; score bounds and milestone-based progress; insight thresholds; persistence, rollback, seed idempotence and reopen. Record actual outcomes and host-specific limitations in docs/VERIFICATION.md.

## Completion tracking
- [x] Original brief archived and pre-implementation design documents written.
- [x] Phase 1
- [x] Phase 2
- [x] Phase 3
- [x] Phase 4
- [x] Phase 5
- [x] Phase 6

The baseline was completed on 2026-09-11 with 24 passing tests and a verified Windows package. The current 0.3 source has 37 test cases; its full Flutter test/build gate remains pending because the current sandbox cannot write the Flutter SDK lockfile or read the external Pub cache. See `VERIFICATION.md`.

