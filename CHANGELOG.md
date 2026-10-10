# Changelog

Thay đổi theo phase. Mỗi phase là một nhánh `phase/<số>-<tên>` được merge vào `main` bằng `--no-ff` và gắn tag `phase-<số>`. Chi tiết (đã làm gì, vì sao, kết quả kiểm thử) nằm trong [docs/PHASE_LOG.md](docs/PHASE_LOG.md); số liệu kiểm thử trong [docs/TEST_REPORT.md](docs/TEST_REPORT.md).

## [1.0.0] — Phase 11B: Báo cáo và hoàn tất (2026-10-10)

### Thêm
- `docs/REPORT.md`: bản nguồn báo cáo kỹ thuật ngắn theo template của khoa (trạng thái FR/NFR trung thực, độ chính xác OCR lần đầu và sau sửa, bảng "cố ý làm hỏng → test đỏ", các lỗi thật test đã bắt, bằng chứng không có quyền mạng, hạn chế). Xuất ra 3 trang, chữ 10pt.
- `tool/report/md_to_pdf.py`: xuất Markdown thành PDF bằng Microsoft Edge (máy không có pandoc), in số trang và cảnh báo nếu ngoài 2–4 trang.
- `docs/DEMO_SCRIPT.md`: kịch bản video 2–3 phút theo cảnh, hai phương án quay (điện thoại thật / emulator + webcam), dữ liệu mẫu, lưu ý quyền riêng tư.
- `docs/HANDOVER.md`: danh sách việc tác giả tự làm theo thứ tự ưu tiên (sao lưu keystore, kiểm tra trên điện thoại thật, đo OCR, ảnh, video, PDF, GitHub, Release, nộp bài).

### Rà soát cuối
- Quét toàn bộ lịch sử git (111 commit): không có keystore, `.apk`, ảnh hóa đơn, `ground_truth.csv`, mật khẩu hay khóa riêng.
- Đối chiếu README, REPORT, CLAUDE.md, TEST_REPORT: số liệu và trạng thái xác minh thống nhất.

## Phase 11A — Release (2026-10-10, nhánh `phase/11a-release`)

### Thêm
- Ký APK release bằng keystore riêng nằm ngoài repo, cấu hình đọc từ `android/key.properties` (đã `.gitignore`); `docs/SIGNING.md`.
- `README.md` hoàn chỉnh (tác giả, checklist FR/NFR trung thực, sơ đồ Mermaid, công nghệ, lệnh build, hạn chế), `docs/screenshots/` kèm hướng dẫn, `CHANGELOG.md`.
- Test cấu hình release (`test/core/release_config_test.dart`).

### Sửa
- R8 làm hỏng build release: thêm `-dontwarn` cho các script ML Kit không đóng gói (Trung/Nhật/Hàn/Devanagari).
- R8 làm OCR **thất bại ở bản release** (constructor của các `ComponentRegistrar` của ML Kit bị loại): thêm keep rule. Phát hiện khi chạy thử APK release trên emulator.

### Sửa (tiếp)
- **NFR-1:** gỡ quyền `INTERNET` và `ACCESS_NETWORK_STATE` khỏi bản release bằng `tools:node="remove"` (hai quyền do thư viện telemetry của ML Kit và media3 thêm vào). APK không còn khai báo quyền mạng; OCR vẫn đọc đúng trên emulator (B-002 đã đóng).
- Thêm 4 test cấu hình: manifest gỡ hai quyền, vẫn giữ `CAMERA`, gỡ `RECORD_AUDIO`, mã nguồn không mở kết nối mạng.

## Phase 10 — UI/UX polish, bản rút gọn (2026-10-10)
- Menu giao diện Sáng / Tối / Theo hệ thống ở Dashboard; bảng màu danh mục cho nền tối, độ tương phản đạt WCAG (4,5:1 chữ, 3:1 đồ họa).
- Test overflow 5 màn × 4 kích thước × chữ 1,5×; sửa card Lịch sử bị tràn khi số tiền lớn.
- Loading / rỗng / lỗi có "Thử lại" ở các màn; nhãn app "VKU Expense OCR"; rà soát NFR-2/NFR-3 (regex biên dịch một lần).

## Phase 9 — Biểu đồ CustomPainter (2026-10-10)
- Donut theo danh mục và cột theo tuần vẽ hoàn toàn bằng `CustomPainter` (animation, chạm lát/cột bằng `atan2`, legend, trạng thái rỗng, Semantics); hình học tách thành hàm thuần; `shouldRepaint` so sánh dữ liệu, màu, progress, phần tử chọn.
- Test kiến trúc chặn mọi thư viện chart.

## Phase 8 — Lịch sử và Dashboard (2026-10-10)
- `ExpenseSummaryCard` (bài lab Week 7) có thumbnail; Lịch sử với `Dismissible`, lọc danh mục, hai trạng thái rỗng; SnackBar Undo dùng chung cửa sổ Undo 5 giây; Dashboard có tổng tháng và chuyển tháng.
- `integration_test/app_flow_test.dart` (viết, chưa chạy).

## Phase 7 — Màn Review và Verification (2026-10-10)
- Form kiểm tra lại với validator tiếng Việt, ô số tiền tự định dạng, dấu độ tin cậy bằng icon + chú thích (tên cửa hàng nổi bật nhất), lưu an toàn (xóa ảnh nếu ghi DB lỗi), ba chế độ, hủy có xác nhận. Gỡ màn debug OCR.

## Phase 6 — Camera (2026-10-10)
- Màn camera: preview trực tiếp, flash, chạm lấy nét, khung căn chỉnh, quy đổi khung → vùng cắt, cắt trong isolate, `image_cropper`, quyền camera, vòng đời; camera sau interface để test được.

## Phase 5 — State management Riverpod 2 (2026-10-10)
- `expenseListProvider` (thêm / sửa / xóa / Undo), tổng tháng / danh mục / tuần, `themeModeProvider` lưu bằng `shared_preferences`, trạng thái quét; dọn ảnh mồ côi khi khởi động.

## Phase 4 — CSDL và lưu ảnh (2026-10-09)
- `sqflite` (bảng `expenses`, migration giữ dữ liệu), `ExpenseRepository`, lưu ảnh + thumbnail trong isolate.

## Phase 3 — Dịch vụ OCR (2026-10-09)
- ML Kit on-device, pipeline ảnh → OCR → ghép hàng → parse, khử nghiêng, công cụ đánh giá trên hóa đơn thật (đáp án khóa bằng SHA-256); sửa lỗi tổng quát từ lần đo đầu (tổng tiền 10/19 → 16/19 trên tập chính).

## Phase 2 — ReceiptParser (2026-10-08)
- Bộ phân tích regex viết theo TDD với 23 hóa đơn tổng hợp, `RowGrouper`, bảng regex `docs/REGEX_TABLE.md`.

## Phase 1 — Nền tảng (2026-10-08)
- Models, theme Material 3, `go_router` với `StatefulShellRoute`, cấu trúc thư mục, định dạng VND/ngày, bỏ dấu tiếng Việt.

## Phase 0 — Khởi tạo và môi trường (2026-10-08)
- Cài Flutter, Android SDK, JDK 21; khởi tạo repo, lint chặt, `CLAUDE.md` và tài liệu.
