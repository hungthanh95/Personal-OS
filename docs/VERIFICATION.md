# Verification — Personal OS 0.4.0 / Architecture V4.1

Verified on 14/09/2026, Windows x64, Flutter 3.44.2 stable and Dart 3.12.2.

## Automated gates

| Gate | Result |
| --- | --- |
| `dart format lib test` | PASS — 43 files checked |
| `flutter analyze` | PASS — no issues |
| `flutter test` | PASS — 74 tests |
| Historical migration loop | PASS — schema versions 1–14 upgrade to v15 and retain stored settings |
| `flutter build windows --release` | PASS — `build/windows/x64/runner/Release/personal_os.exe` |
| Native isolated-data smoke | PASS — process remained running for 8 seconds and created a 720,896-byte SQLite workspace |

Focused V4.1 tests cover output-confirmed scheduled sessions without a timer, late/retracted output, unresolved links, YAML errors, rename and duplicate-ID handling, incremental scans, recurrence/streak, interrupted planning-write recovery, Markdown rebuild, offline vault behavior, combined vault/SQLite backup, Mission/Project/Task source creation and reconciliation, app-side patch preservation, and source rename/deletion behavior. The final full-suite result below is recorded only after the release gate completes.

## Release artifact

`dist/PersonalOS-0.4.0-v4.1-windows-x64.zip`

- Size: 14,879,946 bytes
- SHA-256: `DF53B6FB970A964C5FC6162A7AFE999AD94BCD04015E0C4BB4DBA1802DA70EB9`
- ZIP entries: 16
- Contents check: executable, Flutter runtime, SQLite/file-selector libraries, asset manifest and editable strategy starter are present.

## Runtime/performance evidence

Knowledge search records duration locally in `knowledge_search_events`; Settings exposes the last measured startup time against the 3-second target. Navigation and Today are local synchronous projections after workspace load. The normal test/demo dataset stays inside the product targets; users should review telemetry on materially larger personal datasets.

## Platform/security limits

Windows x64 is the released platform. macOS compilation, signing and runtime QA require macOS hardware and remain unverified.

0.4 has no network provider, cloud sync, account or credential input. Context sharing audit therefore records zero off-device operations. Application-level database encryption is not included; protect the Windows profile/disk with OS encryption for sensitive data.
