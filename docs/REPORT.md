# MINI-PROJECT SHORT TECHNICAL REPORT

**Course:** Cross-Platform Mobile App Development (VKU)
**Mini-Project Title:** Mini-Project 3 — VKU Expense OCR (quản lý chi tiêu bằng OCR on-device)
**Team / Student Name:** Lê Duy Đạt (cá nhân)
**Submission Date:** [DD/MM/YYYY — điền ngày nộp]

---

## 1. GENERAL INFORMATION & DELIVERABLE LINKS
* **Team Members:**
  1. Lê Duy Đạt — Student ID: 23IT048 — Class: 23SE1 — Role: Sinh viên thực hiện duy nhất (thiết kế, lập trình, kiểm thử, tài liệu) — Contribution: 100%
* **🔗 Live Demo URL (APK):** https://github.com/lddatitvku0202/vku-expense-ocr/releases/download/v1.0.0/app-release.apk
* **📦 Release page:** https://github.com/lddatitvku0202/vku-expense-ocr/releases/tag/v1.0.0
* **💻 GitHub Repository:** https://github.com/lddatitvku0202/vku-expense-ocr *(dự kiến, repo chưa được tạo/đẩy lên)*
* **🎥 Video Demo (Optional):** [CHƯA CÓ — điền link video 2–3 phút]

---

## 2. FEATURE IMPLEMENTATION CHECKLIST
Chú thích: ✅ hoàn thành, có test tự động trên máy tính · 🟨 code và test máy tính xong, **chưa xác minh trên điện thoại thật**. *Cột cuối nói rõ phần nào đã/chưa kiểm chứng ngoài máy tính* (emulator = AVD Android 13, 2 GB RAM, webcam làm camera sau).

| # | Required Feature | Status | Implementation Details & Acceptance Level |
|:---:|---|:---:|---|
| 1 | **FR-1** Camera live, flash, chạm lấy nét, khung căn chỉnh, cắt theo khung + `image_cropper`, thư viện, quyền camera | 🟨 | Có đủ 7 mục, quy đổi khung → ảnh thật có 1.200 tổ hợp test. Emulator: preview webcam, mở `image_cropper`, chọn ảnh thư viện chạy được. **Chưa thử:** flash thật, lấy nét, độ khớp vùng cắt, từ chối/cấp lại quyền. |
| 2 | **FR-2** ML Kit Latin on-device, adapter `OcrLine`, ghép hàng + khử nghiêng, đo thời gian, `close()` | ✅ | Chạy trên emulator (bản debug và bản release đã ký). Thời gian OCR 5 s (trung vị, debug) – 11–12 s (release, emulator 2 GB RAM): **không đại diện cho điện thoại**. |
| 3 | **FR-3** `ReceiptParser`: tổng tiền, ngày, tên cửa hàng, danh mục (Dart 3 pattern matching), độ tin cậy từng trường, bảng regex | ✅ | 31/31 hóa đơn **tổng hợp** đúng mọi trường. Trên **22 hóa đơn thật**: xem mục 4 (tên cửa hàng là điểm yếu). |
| 4 | **FR-4** Màn Review: form + validator, ngày, danh mục, dấu cảnh báo (icon + chữ), văn bản OCR gốc, ô số tiền tự định dạng, 3 chế độ | ✅ | Widget test đủ các ca. Emulator (release): thêm thủ công và lưu từ OCR chạy được. |
| 5 | **FR-5** `sqflite`, repository, lưu ảnh + thumbnail (isolate), xóa + Undo | ✅ | DB test bằng `sqflite_common_ffi`; SQLite thật chạy trên emulator. `integration_test/storage_test.dart` **chưa chạy** trên thiết bị. |
| 6 | **FR-6** Donut + cột tuần bằng `CustomPainter` (không thư viện chart), animation, chạm, `shouldRepaint`, trạng thái rỗng | ✅ | Hình học tách thành hàm thuần (phủ 100%). Donut hiển thị đúng dữ liệu trên emulator. **Chưa đo** độ mượt animation trên máy thật. |
| 7 | **FR-7** `go_router` + `StatefulShellRoute`, 3 tab, `/expense/:id`, Lịch sử `ListView.builder` + `Dismissible` | ✅ | Test điều hướng và Lịch sử; 3 tab chạy trên emulator. |
| 8 | **FR-8** Material 3, sáng/tối/hệ thống (lưu lại), responsive, loading/rỗng/lỗi | ✅ | 5 màn × 4 kích thước × chữ 1,5×: 0 overflow; độ tương phản đạt WCAG. **Chưa nhìn bằng mắt** nền tối trên máy thật. |
| 9 | **NFR-1** Hoàn toàn offline | ✅ | APK **không khai báo `INTERNET`** (bằng chứng ở mục 4). Chưa thử chế độ máy bay trên máy thật. |
| 10 | **NFR-2/3** Hiệu năng, `dispose`, vòng đời | ✅ | Đã rà soát (regex biên dịch một lần; mọi controller/timer/camera được giải phóng). |
| 11 | **NFR-6** APK release đã ký | 🟨 | Ký bằng keystore riêng, `apksigner verify` khớp, 89,3 MiB, cài và chạy trên emulator. **Chưa chạy trên điện thoại thật.** |

---

## 3. TECHNICAL ARCHITECTURE & PROJECT STRUCTURE
**Pipeline:** Camera / Thư viện ảnh → cắt theo khung (xoay EXIF, `Isolate.run`) → `image_cropper` → ML Kit `TextRecognizer` (Latin, offline) → `OcrLine` (text + bounding box) → `RowGrouper` (khử nghiêng, ghép hàng) → `ReceiptParser` → `ParsedReceipt` (kèm độ tin cậy từng trường) → màn Review → `sqflite` + `receipts/` (thumbnail) → Riverpod → Dashboard (donut, cột) / Lịch sử.

**Cấu trúc:** `lib/core` (theme, router, định dạng, hình học khung, validators) · `lib/models` · `lib/services` (parser, row grouper, OCR, DB, repository, lưu ảnh, camera sau interface) · `lib/state` (Riverpod 2.6.1) · `lib/widgets` (+ `charts/`) · `lib/screens`. Parser và hình học biểu đồ là **Dart thuần** (có test kiểm tra không import Flutter/ML Kit).

**State (Riverpod 2):** `expenseListProvider` (`AsyncNotifier`: thêm/sửa/xóa/Undo) là nguồn dữ liệu duy nhất; tổng tháng, tổng theo danh mục, tổng theo tuần là provider dẫn xuất nên biểu đồ tự cập nhật. Trạng thái tạm (flash, vòng lấy nét, ô nhập) dùng `setState`.

**Xử lý lỗi:** ảnh hỏng/OCR lỗi không ném ra UI mà thành `ScanFailed` (người dùng nhập tay); lưu = ảnh trước, DB sau, **DB lỗi thì xóa ảnh vừa lưu** (không rác mồ côi); xóa giữ ảnh trong cửa sổ Undo 5 s (một hằng số dùng chung với SnackBar), dọn ảnh mồ côi khi khởi động; lỗi camera là `sealed class` (thiếu quyền / không có camera / lỗi khác), luôn còn đường chọn ảnh thư viện; mọi màn có loading/rỗng/lỗi + "Thử lại".

---

## 4. EMPIRICAL EVIDENCE & SCREENSHOTS
| Tổng quan (sáng) | Tổng quan (tối) | Chỉnh vùng cắt sau khi quét | Review: cảnh báo (tối) |
|---|---|---|---|
| ![Tổng quan sáng](screenshots/dashboard_light.png) | ![Tổng quan tối](screenshots/dashboard_dark.png) | ![Chỉnh vùng cắt](screenshots/scan.png) | ![Review](screenshots/review.png) |

*Ảnh chụp trên **emulator** Android 13 (camera là webcam laptop), **không phải điện thoại thật**. Tổng quan: tổng tháng, donut theo danh mục (6 giao dịch mẫu); giao diện sáng và tối. Review: ô số tiền và ngày có icon + chú thích "Không chắc chắn — hãy kiểm tra lại", "Không đọc được ngày — đã điền tạm hôm nay". Thêm ảnh biểu đồ cột tuần, Lịch sử, văn bản OCR gốc: `docs/screenshots/`.*

**Độ chính xác trên hóa đơn thật.** Bộ **22 ảnh hóa đơn sưu tầm** (19 `main` + 3 `edge`), nằm ngoài repo; đáp án khóa bằng SHA-256 trước khi chấm; chạy ML Kit thật trên **emulator** (không phải điện thoại).

| Tập | Tên cửa hàng | Tổng tiền | Ngày | Danh mục đúng / không đoán / sai |
|---|:---:|:---:|:---:|:---:|
| main (19) — lần đầu | 7 | 10 | 14 | 10 / 5 / 4 |
| main (19) — **sau sửa** | **7** | **16** | **15** | **11 / 4 / 4** |
| edge (3) — lần đầu → sau sửa | 1 → 1 | 2 → 2 | 2 → 2 | 1/1/1 → 2/1/0 |

⚠ **Số sau sửa là lạc quan:** các bản sửa tổng quát được thiết kế **sau khi xem lỗi của chính bộ 22 ảnh này**, nên đây không còn là dữ liệu chưa thấy. Không trường nào tụt giữa hai lần. 31 hóa đơn **tổng hợp** (do chính người viết parser soạn) đạt 31/31, cũng là con số lạc quan. Cần một bộ ảnh mới (holdout) chạy một lần để đo khách quan.

**Kiểm thử:** **717 test** (parser, DB, state, camera, Review, biểu đồ, layout, độ tương phản, cấu hình release), tất cả pass; **độ phủ 94,5%** dòng (2391/2531); `flutter analyze` 0 issue; viết test trước (TDD) từ Phase 2 trở đi.

**Cố ý làm hỏng code để thử test** (9 lần, đều bị bắt):

| Phase | Làm hỏng | Test đỏ |
|:---:|---|:---:|
| 5 | Hẹn giờ xóa ảnh của Undo = 0 s · sai biên cuối tuần | 3 · 4 |
| 6 | Bỏ kiểm tra `focusPointSupported` · không trả camera khi app inactive | 1 · 1 |
| 7 | Bỏ xóa ảnh khi ghi DB lỗi · `PopScope.canPop: true` | 2 · 2 |
| 8 | Bỏ `holdForUndo` (ảnh bị xóa khi nút "Hoàn tác" còn hiện) | 1 |
| 9 | `angleToSliceIndex` bỏ góc bắt đầu · `barRects` bỏ chiều cao tối thiểu · cột treo từ trên | 7 · 3 · 2 |

*(Một đột biến "tương đương" ở Phase 9 không làm test đỏ vì cho đúng cùng giá trị; đã nhận ra và làm lại.)*

**Không có quyền mạng (NFR-1).** Manifest bản release ban đầu có `INTERNET` và `ACCESS_NETWORK_STATE` do thư viện telemetry của ML Kit thêm vào (mã của app không gọi mạng). Đã gỡ bằng `tools:node="remove"`. `aapt dump permissions` và `apkanalyzer manifest permissions` trên `app-release.apk` chỉ còn `CAMERA`, `READ/WRITE_EXTERNAL_STORAGE` (≤ API 28) và quyền nội bộ; báo cáo gộp manifest ghi hai quyền `REJECTED`; trên emulator tiến trình app **không thuộc nhóm `inet`** và OCR vẫn đọc đúng.

---

## 5. TECHNICAL CHALLENGES & RESOLUTIONS
**(1) OCR hỏng chỉ ở bản release.** Bản release (ký, R8 bật) cài và chạy được nhưng báo "Không đọc được hóa đơn" ở ảnh mà bản debug đọc đúng; 713 test lúc đó đều xanh. Logcat: `ComponentDiscovery: Could not instantiate …CommonComponentRegistrar` (`NoSuchMethodException: <init>`), rồi `NullPointerException` ở `InputImage.fromFilePath`. Giải mã stack bằng `retrace` + `mapping.txt`: ML Kit nạp các registrar bằng reflection từ tên trong manifest, R8 không thấy ai gọi nên loại constructor. **Sửa:** một keep rule cho constructor của `ComponentRegistrar` (không tắt R8, không đổi tính năng); cùng ảnh sau đó đọc đúng WinMart, 73.300, 14/04/2025. Bài học: "build được" ≠ "chạy đúng"; phải chạy APK release.

**(2) Hoàn tác (Undo) không được xóa ảnh quá sớm.** SnackBar bắt đầu đếm sau khi trượt vào, hẹn giờ xóa của notifier bắt đầu lúc vuốt, nên ảnh có thể bị xóa khi nút "Hoàn tác" vẫn hiện. **Sửa:** `holdForUndo` giữ lần xóa cho tới khi SnackBar quyết định; dùng **một** hằng số `undoWindow`; xóa liên tiếp thì lần xóa trước được chốt ngay.

**Các lỗi thật mà test đã bắt** (đều sửa code, không sửa test để né):

| Lỗi | Phát hiện bởi | Sửa |
|---|---|---|
| Form dùng `ListView`: trường chưa cuộn tới chưa được dựng nên `Form.validate()` bỏ qua (danh mục chưa chọn vẫn lưu được) | widget test Review | `SingleChildScrollView` + `Column` |
| SnackBar có nút hành động **không tự đóng** (Flutter 3.47) nên lần xóa không bao giờ được chốt | test "hết thời gian thì xóa hẳn" | `persist: false` |
| Legend donut tràn ở 320 dp, chữ 1,5×, số tiền lớn | test overflow | `FittedBox` cho cụm số tiền + % |
| Card Lịch sử tràn 9,8 px ở 320–411 dp khi số tiền 123.456.789 đ | test overflow 5 màn × 4 kích thước | số tiền co lại, tên lấy phần còn lại |
| Màu danh mục thiếu tương phản (nền tối: "Thiết bị" 2,64:1 và 1,74:1 trên nền donut; nền sáng: "Ăn uống" 2,94:1; yêu cầu 3:1) | test WCAG | bảng màu cho nền tối, làm đậm màu nền sáng |
| Build release dừng vì R8 báo thiếu lớp của các script ML Kit không đóng gói | `flutter build apk --release` | `-dontwarn` cho 4 gói (không bật thêm model) |

---

## 6. LIMITATIONS (HẠN CHẾ — TRUNG THỰC)
* **Chưa kiểm tra trên điện thoại Android thật** (lưu ý cho toàn bộ báo cáo): flash, chạm lấy nét, độ khớp vùng cắt với khung, độ mượt animation, độ chính xác chạm, nền tối bằng mắt, chế độ máy bay, thời gian OCR thật, thumbnail ở Lịch sử trên bản release.
* **Tên cửa hàng là trường yếu nhất (7/19):** logo kiểu chữ đặc biệt bị OCR đọc sai ("HIGHANDS CUFFE"), ảnh không có tên cửa hàng; vì vậy màn Review cảnh báo nổi bật khi trường này kém tin cậy. Ngày có thể mất dấu `/`; vài ảnh mờ OCR sai số nặng (tổng tiền sai 3/19 ảnh chính).
* Hóa đơn tổng 0 đ (giảm giá toàn bộ) không lưu được vì đề yêu cầu số tiền dương; chỉ nhận dạng chữ Latin; chỉ nhắm Android; APK 89,3 MiB (model ML Kit + nhiều kiến trúc CPU).
