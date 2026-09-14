# Personal OS

Personal OS 0.4.0 là ứng dụng Flutter desktop local-first để nối chiến lược dài hạn với công việc hằng ngày và bằng chứng thực tế:

```text
Vision → Horizon → Strategy → Mission → Outcome → Initiative
→ Project → Task/Session → Output/Evidence → Review → approved change
```

Ứng dụng chạy offline, không cần tài khoản, API key hoặc mạng. Không có dữ liệu nào được gửi ra ngoài thiết bị.

## Chạy bản Windows

- Portable V4.1 release: `dist/PersonalOS-0.4.0-v4.1-windows-x64.zip`
- Executable sau khi build: `build/windows/x64/runner/Release/personal_os.exe`

Giải nén toàn bộ ZIP rồi giữ executable, DLL và thư mục `data` cùng nhau.

## Chạy từ mã nguồn

Yêu cầu Flutter 3.44.2 / Dart 3.12.2 hoặc bản tương thích và Windows desktop toolchain.

```sh
flutter pub get
flutter run -d windows
```

Database phát triển riêng:

```sh
flutter run -d windows --dart-define=PERSONAL_OS_DB=D:/temp/personal-os-dev.sqlite
```

## Chức năng hiện tại

- Today: lập lịch và recurring plan; mỗi buổi có một note Obsidian. Sau giờ kết thúc, app xác nhận `status: done` + Output, cập nhật completion/streak và không đo thời gian thực tế.
- Markdown workspace: Mission, Project, Task và Session có source note riêng; app patch các field do hệ thống quản lý, giữ nguyên section người dùng thêm và dùng SQLite làm projection có thể rebuild.
- Mission: outcomes có trọng số, sáu chiều readiness dựa trên evidence, trọng số tùy chỉnh, trajectory 30/90 ngày và usage metrics.
- Strategy: hierarchy explorer, assumptions/events, review thích ứng, recommendation có evidence/risk/confidence, Accept/Modify/Reject, version history và plan propagation preview.
- Projects: milestone/task/session/output/Knowledge, Income Lab, Ownership Engine, customer discovery, revenue/distribution, capital contribution và net-worth snapshots.
- Knowledge: import TXT/Markdown/PDF/DOCX, hướng dẫn chuyển DOC cũ, bảo tồn nguồn/checksum/section, FTS5 + semantic local + concept graph, duplicate/freshness và gợi ý theo session.
- Career: nhập tối đa 50 JD, phân tích required/preferred/years/domain/salary, demand/readiness, application/interview funnel, weakness clusters và learning priorities.
- Privacy/data: workspace ZIP gồm vault + SQLite, database restore có safety snapshot, portable JSON export, xóa từng nhóm dữ liệu, migration v1–v15 và local context-sharing audit.

## Kiểm tra

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build windows --release
```

## Tài liệu

- [User manual](docs/USER_MANUAL.md)
- [Product checklist](docs/PRODUCT_CHECKLIST.md)
- [Completed specification (archived)](docs/archived/PERSONAL_OS_PRODUCT_SPEC.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Data model](docs/DATA_MODEL.md)
- [Verification](docs/VERIFICATION.md)
- [Release 0.4](docs/UPGRADE_0.4.md)
- [Archived documents](docs/archived/README.md)

macOS runner được giữ trong source để có thể port sau này, nhưng 0.4.0 chỉ phát hành và xác minh trên Windows x64.
