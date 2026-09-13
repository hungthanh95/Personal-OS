# Verification — Personal OS 0.4.0

Verified on 13/09/2026, Windows x64, Flutter 3.44.2 stable and Dart 3.12.2.

## Automated gates

| Gate | Result |
| --- | --- |
| `dart format lib test` | PASS — 35 files formatted |
| `flutter analyze` | PASS — no issues |
| `flutter test` | PASS — 44 tests |
| Historical migration loop | PASS — schema versions 1–12 upgrade to v13 and retain stored settings |
| `flutter build windows --release` | PASS |
| Native isolated-data smoke | PASS — process remained running for 8 seconds and created a 720,896-byte SQLite workspace |

Tests cover session timing/transitions including Blocked, atomic evidence capture, recurrence, validation/rollback, strategy versions and decisions, readiness, adaptive reviews, plan propagation, source-aware/semantic Knowledge, JD extraction/funnel inputs, interview conversion, Ownership/Capital records, portable export/category deletion, backup/restore foundations, responsive forms and desktop navigation.

## Release artifact

`dist/PersonalOS-0.4.0-windows-x64.zip`

- Size: 14,684,680 bytes
- SHA-256: `F5EC509BB81E6D2F002BDEB5BEDA9930D9DDC3949EF8E0031F93F4989C5CCA19`
- ZIP entries: 16
- Contents check: executable, Flutter runtime, SQLite/file-selector libraries, asset manifest and editable strategy starter are present.

## Runtime/performance evidence

Knowledge search records duration locally in `knowledge_search_events`; Settings exposes the last measured startup time against the 3-second target. Navigation and Today are local synchronous projections after workspace load. The normal test/demo dataset stays inside the product targets; users should review telemetry on materially larger personal datasets.

## Platform/security limits

Windows x64 is the released platform. macOS compilation, signing and runtime QA require macOS hardware and remain unverified.

0.4 has no network provider, cloud sync, account or credential input. Context sharing audit therefore records zero off-device operations. Application-level database encryption is not included; protect the Windows profile/disk with OS encryption for sensitive data.
