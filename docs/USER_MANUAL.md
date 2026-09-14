# Personal OS 0.4 — Hướng dẫn sử dụng

Cập nhật: 14/09/2026 cho Architecture V4.1. Tên nút được giữ bằng tiếng Anh để khớp giao diện.

## 1. Cài đặt và dữ liệu

Giải nén `dist/PersonalOS-0.4.0-v4.1-windows-x64.zip` vào một thư mục, giữ nguyên executable, DLL và thư mục `data`, rồi mở `personal_os.exe`. Ứng dụng chạy offline và lưu SQLite trong Application Support của tài khoản Windows. Đường dẫn chính xác hiển thị ở **Settings → Local database**.

Lần mở đầu có Quick start và dữ liệu mẫu mang nhãn **DEMO WORKSPACE · LOCAL**. Bạn có thể thử các luồng trước khi vào **Settings → Start an empty workspace**. Thao tác này xóa cả dữ liệu bạn đã thêm vào workspace demo, vì vậy hãy export trước nếu cần giữ.

## 2. Bản đồ màn hình

| Màn hình | Mục đích |
| --- | --- |
| Today | Xem lịch, mở note Obsidian, kiểm tra kết quả, Why Path và tuần hiện tại |
| Mission | Outcome, skill readiness, blocker, trajectory và Career workspace |
| Strategy | Vision đến Initiative, assumptions/events, recommendation và version history |
| Projects | Project, task, milestone, output, Income/Ownership/Capital |
| Knowledge | Ghi chú, tài liệu, output, search và concept graph |
| Review | Weekly/Monthly/Quarterly/Annual/Event-Driven review và kế hoạch tuần tới |
| Inbox | Ghi nhanh rồi phân loại |
| Settings | Theme, readiness weights, privacy, backup/restore/export/delete |

Phím tắt: `Ctrl+K` mở tìm kiếm toàn app, `Ctrl+N` mở quick capture, `Esc` đóng dialog. Sidebar có nhãn semantics và hỗ trợ keyboard focus.

## 3. Thiết lập hướng đi

1. Vào **Strategy** và tạo **Vision**.
2. Thêm **Horizon**, sau đó **Strategy** thuộc Vision/Horizon.
3. Thêm **Mission**, **Outcome** đo được và **Initiative**.
4. Vào **Projects**, tạo Project thuộc Initiative hoặc Outcome.
5. Thêm Task hoặc Session vào Project.

Sau khi chọn vault, app tạo source note riêng cho Mission, Project và Task. Dùng **Open note** tại màn hình tương ứng để sửa nội dung trong Obsidian. Lần scan tiếp theo cập nhật projection; đổi tên hoặc di chuyển note vẫn giữ liên kết bằng ID. Nếu trùng ID, YAML lỗi hoặc tham chiếu không tồn tại, app không nhận nhầm note và giữ projection hợp lệ gần nhất. Lỗi của Session hiện trên trang chi tiết; lỗi source của Mission/Project/Task hiện được lưu trong source mapping và có trong portable JSON để chẩn đoán.

Khi sửa trong app, writer chỉ patch frontmatter và các section mà app quản lý; section hoặc YAML tùy chỉnh của người dùng được giữ lại. Task chỉ thành Done khi note Task có trạng thái Done; một Session hoàn thành không tự đánh dấu Task Done.

Mở **Strategy map** để lọc theo Horizon và đi từ Strategy → Mission → Outcome → Initiative → Project → Task/Session/Output. Chọn node để xem chi tiết. Why Path của session giải thích đường nối về mission và vision.

## 4. Làm việc với Session

1. Vào **Today → Plan session**, chọn Project hoặc Goal, giờ, thời lượng, priority, WHY, INPUT và target.
2. Vào **Settings → Obsidian workspace**, chọn vault. App tạo một note cho mỗi session mà không ghi đè note có sẵn.
3. Mở session rồi chọn **Open note**. Làm việc và ghi Output/Learning/Next Action trong Obsidian.
4. Sau giờ kết thúc, đặt `status: done` và ghi Output cụ thể. App tự kiểm tra khi đang mở, khi quay lại app/máy thức dậy hoặc khi bạn chọn **Check result**.

| Trạng thái | Cách dùng |
| --- | --- |
| Planned | Đã lên lịch hoặc đang chờ kết quả |
| Done | Được xác nhận sau giờ kết thúc từ `status: done` + Output trong Obsidian |
| Skipped | Chủ động bỏ qua |
| Cancelled | Hủy; không tính vào mẫu số completion |

`planned_minutes` chỉ là thời lượng dành trên lịch, không phải thời gian đã học. App không có Start/Pause/Resume/Stop và không đo elapsed time. Nếu thiếu Done hoặc Output, session tiếp tục ở trạng thái chờ; output bổ sung muộn sẽ được tính lại vào đúng occurrence ban đầu.

Output hợp lệ phải có nội dung thực trong `## Output` hoặc liên kết tới một kết quả tồn tại trong vault. Heading rỗng, placeholder và wikilink không tìm thấy đích chưa đủ điều kiện. “Đang trong khung lịch”, “Awaiting result” và “Missing output” là trạng thái hiển thị suy ra; chúng không khẳng định người dùng đang học.

## 5. Lịch lặp và kế hoạch tuần

Trong **Today → Recurring plan**, tạo Session template rồi Recurring schedule. Weekday dùng ISO `1..7` tương ứng thứ Hai đến Chủ nhật. App tự materialize 21 ngày; **Generate 12 weeks** mở rộng đến 93 ngày và không tạo trùng occurrence. Streak được tính theo các occurrence Done liên tiếp của từng lịch; ngày không có lịch không làm đứt streak, Skipped làm đứt và Cancelled bị loại. Một occurrence đang chờ kết quả làm phần tiếp theo của streak chưa thể xác định; output bổ sung muộn được tính tại occurrence gốc.

Trong **Review**, chọn Mission rồi **Create plan preview**. Hệ thống local đề xuất ưu tiên dựa trên gap/evidence, tạo draft các session thứ Hai–thứ Sáu. Kiểm tra lý do, evidence, risk và confidence; chọn Accept/Reject, sau đó approve và apply change set. Không có thay đổi lịch âm thầm.

## 6. Mission, Outcome và readiness

1. Tạo Outcome với target/current value/unit/weight.
2. Tạo các Skill cần cho Mission.
3. Sau khi có Output, mở Skill và **Link output & assess dimension**.
4. Chọn một trong sáu chiều: Knowledge, Implementation, Debugging, Application, Interview, Production; nhập score/confidence và xác nhận evidence.

Readiness chỉ dùng assessment **verified** mới nhất của mỗi chiều. Thời gian học không tự tăng điểm. Vào **Settings → Readiness model** để chỉnh sáu trọng số; tổng phải bằng 100%. Mission hiển thị score × weight, evidence mới nhất và delta so với assessment xác nhận trước.

Mở **Trajectory** để xem outcome progress, readiness delta 30/90 ngày, metric snapshots và product-use metrics. Mỗi custom metric có direction, target, nguồn và confidence.

## 7. Strategy, assumptions và review thích ứng

Mỗi recommendation có recommendation, reason, fact basis, inference, expected benefit, risk, confidence, evidence IDs và affected targets. Người dùng quyết định **Accept / Modify / Reject**. Mọi quyết định được lưu vào audit history.

Thay đổi Strategy tạo snapshot trước/sau với version number và previous-version link. Recommendation được chấp nhận chỉ tác động kế hoạch qua planning change-set có preview, approve và apply riêng.

Review hỗ trợ:

- Weekly: execution, output, evidence và next-week priorities.
- Monthly: xu hướng thực hiện và gap.
- Quarterly: mission/readiness, career funnel, discoveries/revenue, capacity và assumptions.
- Annual: thesis, assumptions, kết quả, lựa chọn roadmap 1 năm/3 năm.
- Event-Driven: JobOffer, JobLoss, SalaryChange, FirstCustomer, RevenueThreshold, AI capability shift, market contraction hoặc sự kiện nhập tay.

Assumption Weakening/Invalidated, confidence thấp và event chưa review được đưa vào phân tích; hệ thống chỉ đề xuất, không tự viết lại strategy.

## 8. Knowledge

Chọn **Knowledge → Import document** để nhập TXT, Markdown, text-based PDF hoặc DOCX. File DOC cũ được chọn để app hiển thị hướng dẫn chuyển sang DOCX/TXT. PDF scan/custom font cần OCR hoặc chuyển đổi bên ngoài.

Khi import, app:

- giới hạn 20 MB và giữ thao tác lỗi an toàn;
- sao chép nguồn vào vùng managed local files;
- lưu filename, checksum, size, modified/import time, MIME và section offsets;
- ngăn trùng theo path/checksum;
- gợi ý summary, tags, concepts và links cục bộ để bạn sửa trước khi lưu.

**Search with context** kết hợp SQLite FTS5, local semantic vector và concept relationships. Kết quả hiển thị snippet, source, section/offset và lý do khớp. Khi mở, phần **Matching source context** giữ đúng đoạn khớp; **Open preserved source** mở bản nguồn. Session cũng hiển thị tối đa năm Knowledge item liên quan.

Tab **Concept graph** cho biết freshness window, nhóm nghi trùng và các suggested links. Suggested relation vẫn editable; **Accept link** mới xác nhận quan hệ.

## 9. Career workspace

Mở một Mission rồi vào **Career workspace**. Có thể paste tối đa 50 JD, ngăn cách bằng dòng `---`. Các nhãn hỗ trợ gồm `Title:`, `Company:`, `Location:`, `Domain:`, `Seniority:`, `Employment:`, `URL:` và `Salary:`.

Parser cục bộ ghi required/preferred/mentioned, years required, source excerpt và confidence cho skill đã có trong Mission. Dashboard hiển thị demand/readiness gap, role/domain/company clusters, salary sample và funnel Job → Application → Interview → Offer với tử số, mẫu số và cảnh báo mẫu nhỏ.

Ghi interview result, strengths, weaknesses và questions. Câu hỏi Partial/Fail có thể **Make priority** một lần để tạo learning priority có nguồn; sau đó dùng biểu tượng plan để tạo session.

App không crawl web. Source URL do bạn nhập được lưu làm provenance; dữ liệu thị trường không tự cập nhật và không được trình bày như chắc chắn.

## 10. Projects, Ownership và Capital

Project hỗ trợ Learning, Product, Career, IncomeExperiment, Content và Personal; có task schedule/estimate/priority/status, milestones, sessions, outputs, Knowledge và Next Action.

Trong **Income Lab**, lưu hypothesis, market, time budget, experiment, result, signal và next action. Signal gồm Unknown/Negative/Weak/Promising/Strong/Revenue. Mọi experiment chưa Killed phải có next action.

Mở **Ownership & Capital** để:

- đặt Career/Ownership/Capital engine mode, weekly budget range và objective;
- ghi customer discovery/problem evidence/signal;
- ghi revenue và distribution reach/leads;
- ghi capital contribution/withdrawal/return;
- lưu net-worth snapshots có date/source/notes.

Các số này do người dùng nhập. Ứng dụng không kết nối ngân hàng, broker hoặc biến thành công cụ giao dịch.

## 11. Inbox và tìm kiếm chung

Quick capture chỉ cần title/kind. Trong Inbox, chuyển item chưa xử lý thành Goal, Project, Session hoặc Knowledge. Việc chuyển đổi là transaction: nếu link không hợp lệ, item vẫn chưa processed.

`Ctrl+K` tìm tiêu đề/nội dung trong execution, strategy và career records. Tìm kiếm sâu trong tài liệu dùng **Knowledge → Search with context**.

## 12. Backup, restore, export và xóa

- **Export workspace backup** tạo ZIP gồm toàn bộ Obsidian vault và SQLite snapshot nhất quán; cần cấu hình vault trước và đây là bản sao lưu đầy đủ trong giai đoạn chuyển tiếp.
- **Export database backup** chỉ tạo SQLite snapshot để dùng với luồng restore hiện tại.
- **Restore from backup** hiện chỉ nhận file SQLite từ **Export database backup**; nó kiểm tra header, migrate bản staging, tạo safety snapshot rồi mới thay database đang đóng. Workspace ZIP là gói lưu trữ đầy đủ nhưng chưa có nút restore trực tiếp.
- **Export portable JSON** xuất toàn bộ bảng cùng schema version/time để kiểm tra hoặc di chuyển dữ liệu.
- **Personal data controls** xóa riêng Career, Knowledge hoặc Ownership/Capital sau xác nhận. Xóa Knowledge cũng dọn bản managed source nếu đường dẫn nằm đúng vùng app quản lý.

Không sửa file SQLite khi app đang mở. Khi copy thủ công, đóng app trước.

## 13. Privacy và giới hạn

0.4.0 chỉ có **Local-only intelligence**. Không có connector, cloud sync, external LLM hay nơi nhập credential; vì vậy không có credential nào được lưu và context-sharing audit phải ghi nhận không có off-device calls. Nếu một provider mạng được bổ sung sau này, secure credential storage và consent/audit trước khi gửi context là yêu cầu bắt buộc.

Database chưa dùng application-level encryption. Hãy bảo vệ tài khoản Windows/ổ đĩa bằng BitLocker hoặc cơ chế mã hóa hệ điều hành nếu lưu salary, interview notes hay tài liệu riêng tư.

0.4.0 được build/test trên Windows x64. macOS runner có trong source nhưng chưa được build, ký hoặc runtime-test; macOS chưa phải platform phát hành.

## 14. Checklist kiểm tra UI thủ công

- [ ] Chạy Quick start, đổi theme/name/readiness weights và khởi động lại.
- [ ] Tạo hierarchy từ Vision đến Session; kiểm tra Strategy map và Why Path.
- [ ] Tạo session 21:00–22:00; sau 22:00 ghi `status: done` và Output trong Obsidian rồi kiểm tra completion/streak mà không Start session.
- [ ] Thử thiếu Output, bổ sung Output muộn, đổi tên note, trùng ID và YAML lỗi.
- [ ] Mở/sửa note Mission, Project, Task; kiểm tra projection và section tùy ý vẫn được giữ.
- [ ] Ghi output/learning/evidence; kiểm tra Task progress và readiness không tăng chỉ vì session hoàn thành.
- [ ] Tạo assumption/event/review/recommendation; thử Accept, Modify, Reject và plan propagation.
- [ ] Import Markdown/PDF/DOCX; thử DOC cũ, file scan, import trùng, search context và open source.
- [ ] Nhập JD, application, interview/question; kiểm tra clusters, funnel và priority conversion.
- [ ] Ghi customer discovery/revenue/distribution/capital/net worth.
- [ ] Export workspace ZIP, SQLite và JSON; thử restore SQLite và xóa từng category trên dữ liệu thử.
- [ ] Kiểm tra keyboard-only, light/dark, text scale, cửa sổ hẹp và thông báo lỗi.

Mẫu ghi lỗi:

```text
Phiên bản/cách chạy:
Màn hình, theme, kích thước/text scale:
Các bước:
Kết quả mong đợi:
Kết quả thực tế:
Ảnh hoặc mô tả:
Mức ảnh hưởng:
```

## 15. Tài liệu liên quan

- [Product checklist](PRODUCT_CHECKLIST.md)
- [Verification](VERIFICATION.md)
- [Data model](DATA_MODEL.md)
- [Architecture](ARCHITECTURE.md)
- [Release 0.4](UPGRADE_0.4.md)
- [Archived documents](archived/README.md)
