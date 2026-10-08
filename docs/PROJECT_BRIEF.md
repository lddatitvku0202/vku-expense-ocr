# PROJECT BRIEF — Mini-Project 3: OCR Expense Tracker & Receipt Parser (Flutter & Dart)

> **Gửi Claude Code:** Đây là bản giao việc đầy đủ. Hãy đọc HẾT file này trước khi làm bất cứ điều gì, sau đó thực hiện dự án từ A đến Z theo đúng thứ tự Phase bên dưới. Làm liên tục qua các phase, chỉ dừng lại hỏi tôi khi gặp **BLOCKER** (định nghĩa ở mục 2). Giải thích, nhật ký và tài liệu viết bằng **tiếng Việt**; code, tên biến, comment trong code và commit message viết bằng **tiếng Anh**.

---

## 0. Bối cảnh

- Môn học: **Cross-Platform Mobile App Development** — Khoa Khoa học Máy tính, VKU (Trường ĐH CNTT & Truyền thông Việt – Hàn). Giảng viên: TS. Nguyễn Thanh Tuấn.
- Kiến thức nền: slide **Week 7** (Flutter & Dart Part 1: Fundamentals & Widget Tree) và **Week 8** (Flutter Part 2: State Management, Routing & Platform Channels).
- Tôi là sinh viên, mục tiêu của tôi là **hiểu được quá trình làm**. Vì vậy mỗi phase bạn phải ghi nhật ký học tập (mục 6.3) để tôi đọc lại.
- Thư mục đang mở trong VS Code chính là thư mục gốc của dự án. Tôi sẽ tự tạo repo GitHub và push. **Bạn chỉ commit cục bộ, KHÔNG tạo remote, KHÔNG push.**

---

## 1. Nhiệm vụ đầu tiên: tạo `CLAUDE.md`

Trước khi viết code, tạo file `CLAUDE.md` ở thư mục gốc. Nội dung gồm:

1. **Quy tắc làm việc**: chép nguyên văn mục 2 và mục 6 của brief này.
2. **Đặc tả yêu cầu (FROZEN)**: chép nguyên văn mục 3 (toàn bộ FR, NFR, rubric, deliverables). Đặt tiêu đề `## Requirements (FROZEN — không được sửa)`.
3. **Bản đồ kiến thức slide → code**: chép mục 4.
4. **Các lỗi đã biết trong slide cần sửa**: chép mục 5.
5. **Kế hoạch Phase**: chép mục 7 kèm checklist `[ ]` cho từng đầu việc.
6. **Progress Log**: bảng theo dõi trạng thái từng phase (Phase | Trạng thái | Commit cuối | Kết quả test | Ghi chú). Cập nhật sau mỗi phase.
7. **Decisions Log**: các quyết định kỹ thuật kèm lý do (ví dụ: chọn sqflite thay vì isar).
8. **Blockers / Deviations**: nơi ghi các vấn đề cần tôi quyết định.

Đồng thời lưu bản gốc của brief này vào `docs/PROJECT_BRIEF.md` (nếu nó đang nằm ở thư mục gốc thì `git mv` vào `docs/`).

**Khôi phục phiên làm việc:** nếu phiên bị gián đoạn hoặc context bị nén, việc đầu tiên là đọc `CLAUDE.md` (mục Progress Log) và `git log --oneline`, rồi tiếp tục từ đầu việc chưa xong. Không làm lại từ đầu.

---

## 2. QUY TẮC BẤT DI BẤT DỊCH (Integrity Rules)

### 2.1. Không được sửa yêu cầu để né lỗi
- Mục `Requirements (FROZEN)` trong `CLAUDE.md` **không bao giờ được chỉnh sửa**, kể cả khi gặp lỗi.
- **Cấm hạ cấp tính năng** để "cho chạy được". Ví dụ những việc bị cấm:
  - Bỏ camera live (gói `camera`) và chỉ dùng `image_picker`.
  - Dùng `fl_chart`, `syncfusion_flutter_charts` hay bất kỳ thư viện chart nào thay cho `CustomPainter`.
  - Thay ML Kit on-device bằng API OCR trên cloud.
  - Mock hoặc hard-code kết quả OCR/parse trong **code production**.
  - Bỏ màn hình Review, bỏ animation, bỏ dark mode, bỏ lưu ảnh hóa đơn.
  - Thay Riverpod 2 bằng `setState` toàn cục.
  - Bỏ bớt danh mục hoặc thêm danh mục ngoài 5 danh mục quy định.
- Nếu một yêu cầu **thật sự không thể** thực hiện trong môi trường hiện tại: dừng lại, ghi vào mục `Blockers / Deviations` (mô tả lỗi, những gì đã thử, các phương án, đề xuất), rồi **hỏi tôi**. Chỉ làm theo phương án khác khi tôi đã đồng ý.

### 2.2. Không gian lận test
- Không xóa test, không `skip:` test, không nới lỏng assertion, không sửa dữ liệu kỳ vọng chỉ để test pass.
- Không viết code đặc biệt nhận diện dữ liệu test (special-casing).
- Không dùng `// ignore:` hay `// ignore_for_file:` để tắt cảnh báo của `flutter analyze`. Ngoại lệ duy nhất là lỗi do code sinh tự động, và phải ghi lý do vào Decisions Log.
- Khi test fail: sửa **code** cho đúng. Chỉ sửa test khi chính test sai so với requirement, và phải giải thích trong commit message.

### 2.3. BLOCKER là gì (chỉ những trường hợp này mới được dừng lại hỏi)
- Thiếu công cụ hoặc môi trường: chưa cài Flutter, Android SDK, chưa chấp nhận license, thiếu `keytool`, Flutter không phải bản 3.x.
- Một requirement mâu thuẫn hoặc không khả thi (theo mục 2.1).
- Cần thông tin chỉ tôi có (ví dụ tên hiển thị của tôi trong README hoặc báo cáo).

Với các lỗi biên dịch, lỗi phụ thuộc hay lỗi test thông thường: **tự điều tra và sửa**, không dừng lại hỏi.

### 2.4. Bảo mật và Git
- Không bao giờ commit: keystore (`*.jks`, `*.keystore`), `android/key.properties`, file `.env`, thư mục `build/`, file APK/AAB, `.dart_tool/`.
- Không tạo remote, không push, không force-push, không rewrite lịch sử (`rebase -i`, `commit --amend` trên commit đã merge).

---

## 3. ĐẶC TẢ YÊU CẦU (FROZEN)

### 3.1. Mục tiêu học tập
- Xây dựng ứng dụng quản lý tài chính cá nhân bằng Flutter, có AI chạy trên thiết bị (on-device).
- Tích hợp **Google ML Kit Text Recognition** để đọc hóa đơn offline.
- Xây dựng **bộ phân tích heuristic bằng regex** để trích xuất tổng tiền, tên cửa hàng và ngày giao dịch.
- Vẽ biểu đồ tròn/donut và biểu đồ cột **có tương tác và animation** bằng `CustomPainter`.

### 3.2. Kịch bản bài toán
Sinh viên VKU và thủ quỹ câu lạc bộ thường xuyên cầm hóa đơn giấy từ siêu thị, quán ăn. Việc gõ tay số tiền vào bảng tính rất mất công và dễ sai. Ứng dụng cho phép chụp hóa đơn, tự nhận dạng và tách dữ liệu, cho người dùng kiểm tra lại, lưu cục bộ và trực quan hóa chi tiêu.

### 3.3. Công nghệ bắt buộc
- Flutter **3.x**, Dart **3** (dùng null safety, records, patterns, switch expressions).
- `google_mlkit_text_recognition` (on-device, offline, không tốn phí cloud).
- CSDL cục bộ: `sqflite` (đề cho phép `sqflite` hoặc `isar`; dự án chọn **`sqflite`** vì slide và rubric dùng gói này).
- State management: **Riverpod 2** (`flutter_riverpod` phiên bản major **2.x**, vì rubric ghi "Riverpod 2").
- Routing: `go_router`.
- Định dạng số và ngày: `intl`.
- Biểu đồ: **chỉ dùng `CustomPainter`**, không dùng thư viện chart bên thứ ba.

### 3.4. Yêu cầu chức năng (Functional Requirements)

**FR-1. Chụp ảnh & cắt ảnh (Camera Capture & Image Cropping)**
- FR-1.1: Màn hình camera hiển thị **viewfinder trực tiếp** (gói `camera`, `CameraPreview`).
- FR-1.2: Nút **bật/tắt flash** (ít nhất 2 trạng thái off/torch hoặc off/auto/always), có icon phản ánh trạng thái hiện tại.
- FR-1.3: **Chạm để lấy nét**: chạm vào preview thì gọi `setFocusPoint` / `setExposurePoint`, hiển thị vòng chỉ báo lấy nét tại điểm chạm.
- FR-1.4: **Khung căn chỉnh (framing crop overlay)**: lớp phủ tối mờ có khung chữ nhật tỷ lệ hóa đơn ở giữa, vẽ bằng `Stack`/`CustomPainter`.
- FR-1.5: Sau khi chụp, ảnh được **cắt theo vùng khung căn chỉnh** (quy đổi tọa độ khung trên preview sang tọa độ ảnh thật). Người dùng có thể **điều chỉnh vùng cắt thủ công** (ví dụ `image_cropper`).
- FR-1.6: Có lựa chọn **chọn ảnh từ thư viện** (`image_picker`) như một đường vào bổ sung. Đây **không** phải là thay thế cho FR-1.1.
- FR-1.7: Xử lý quyền camera: nếu bị từ chối thì hiển thị thông báo rõ ràng và cách mở cài đặt; không được crash.

**FR-2. Nhận dạng chữ on-device**
- FR-2.1: Dùng `TextRecognizer(script: TextRecognitionScript.latin)` xử lý ảnh đã cắt, hoàn toàn offline.
- FR-2.2: Tầng adapter chuyển `RecognizedText` của ML Kit thành model nội bộ (`OcrLine` gồm `text` và `Rect boundingBox`) để phần parser **không phụ thuộc ML Kit** và test được bằng unit test.
- FR-2.3: **Ghép dòng theo hàng (row grouping)**: các `TextLine` có khoảng Y chồng lấp (theo ngưỡng tỷ lệ chiều cao) được ghép thành một hàng logic, sắp xếp từ trái sang phải. Mục đích: ghép nhãn "Tổng tiền" ở cột trái với số tiền ở cột phải.
- FR-2.4: Đo thời gian xử lý OCR bằng `Stopwatch`, hiển thị ở màn Review (dạng thông tin phụ) và ghi log. Con số này dùng cho báo cáo (không được bịa số liệu).
- FR-2.5: Đóng `TextRecognizer` đúng lúc (`close()`), không rò rỉ tài nguyên.

**FR-3. Bộ phân tích heuristic regex (`ReceiptParser`)**
- FR-3.1: **Chuẩn hóa văn bản**: hàm bỏ dấu tiếng Việt (bao gồm `đ/Đ → d/D`), chuyển chữ thường, gộp khoảng trắng. Dùng bản đã chuẩn hóa để so khớp từ khóa, nhưng giữ bản gốc để hiển thị.
- FR-3.2: **Tổng tiền**: nhận được các định dạng `150.000`, `150,000`, `150000`, `150.000đ`, `150.000 đ`, `150,000 VND`, `150.000 VNĐ`, `1.250.000`. Từ khóa ưu tiên (sau khi bỏ dấu) gồm ít nhất: `tong thanh toan`, `thanh toan`, `tong cong`, `tong tien`, `total`, `amount due`, `can thanh toan`, `khach phai tra`. Quy tắc:
  - Ưu tiên từ khóa "thanh toán cuối cùng" hơn "tổng tiền hàng" khi hóa đơn có cả hai (vì có giảm giá/VAT).
  - Nếu có nhiều ứng viên, ưu tiên hàng nằm thấp hơn trên hóa đơn.
  - Loại trừ số điện thoại, mã số thuế (MST), số hóa đơn, mã vạch, giờ (`hh:mm`), số lượng × đơn giá trên cùng một dòng nếu nhận diện được.
  - **Fallback**: không tìm thấy từ khóa thì lấy số tiền hợp lệ lớn nhất (sau khi loại trừ), đánh dấu độ tin cậy thấp.
  - Kết quả là `int` (đồng VND), không dùng `double`.
- FR-3.3: **Ngày**: nhận `DD/MM/YYYY`, `DD-MM-YYYY`, `DD.MM.YYYY`, `DD/MM/YY`, có hoặc không có giờ kèm theo. Validate ngày tồn tại thật (loại `45/13/2026`). Năm 2 chữ số quy về 20YY. Không tìm thấy thì để null (người dùng chọn ở Review, mặc định gợi ý ngày hôm nay).
- FR-3.4: **Tên cửa hàng**: tìm trong khoảng 5 hàng đầu; bỏ các hàng chứa từ khóa địa chỉ, điện thoại, MST, website, hotline (`dia chi`, `d/c`, `dc:`, `dt`, `tel`, `hotline`, `mst`, `www`, `http`, `hoa don`...) và hàng có tỷ lệ chữ số cao; chọn hàng có nhiều chữ cái nhất trong số còn lại. Nếu không đủ tin cậy thì để null.
- FR-3.5: **Gợi ý danh mục** theo từ khóa trong tên cửa hàng hoặc nội dung, dùng `switch` pattern matching của Dart 3. Đúng **5 danh mục**: `Food`, `Study`, `Travel`, `Gear`, `Entertainment`. Không đoán được thì trả về null (người dùng **bắt buộc** chọn ở Review).
- FR-3.6: Kết quả trả về là `ParsedReceipt` gồm `merchant`, `total`, `date`, `suggestedCategory`, `rawText`, và **độ tin cậy cho từng trường** (`high`/`low`/`missing`).
- FR-3.7: Tài liệu `docs/REGEX_TABLE.md` liệt kê mọi pattern: mục đích, regex, ví dụ khớp, ví dụ không khớp, giới hạn đã biết. (Dùng cho báo cáo.)

**FR-4. Màn hình Review & Verification (bắt buộc)**
- FR-4.1: Hiển thị ảnh hóa đơn đã cắt (có thể phóng to bằng `InteractiveViewer`).
- FR-4.2: `Form` + `GlobalKey<FormState>` + `TextFormField` cho tên cửa hàng và số tiền; chọn ngày bằng `showDatePicker`; chọn danh mục (bắt buộc, 5 lựa chọn).
- FR-4.3: Validator: tên cửa hàng không rỗng; số tiền là số nguyên dương sau khi bỏ dấu phân cách; ngày không nằm ở tương lai; danh mục phải được chọn.
- FR-4.4: Trường có độ tin cậy `low` hoặc `missing` được **đánh dấu trực quan** (màu viền hoặc icon cảnh báo kèm chú thích).
- FR-4.5: Có phần mở rộng **"Xem văn bản OCR gốc"** (raw text) và thời gian OCR.
- FR-4.6: Ô số tiền tự định dạng phân cách hàng nghìn kiểu Việt Nam khi nhập.
- FR-4.7: Quản lý focus (`FocusNode`, chuyển trường bằng nút Next trên bàn phím); `dispose()` toàn bộ controller và focus node.
- FR-4.8: Lưu thành công thì hiện `SnackBar` và quay về màn trước; hủy thì hỏi xác nhận nếu đã sửa.
- FR-4.9: Màn này cũng dùng để **thêm thủ công** (không có ảnh, các trường rỗng) và để **sửa** một giao dịch đã lưu.

**FR-5. CSDL cục bộ & vòng đời giao dịch**
- FR-5.1: `sqflite`, bảng `expenses` gồm: `id INTEGER PK AUTOINCREMENT`, `merchant TEXT NOT NULL`, `amount INTEGER NOT NULL`, `date INTEGER NOT NULL` (epoch ms), `category TEXT NOT NULL`, `image_path TEXT`, `thumb_path TEXT`, `raw_text TEXT`, `created_at INTEGER NOT NULL`, `updated_at INTEGER NOT NULL`. Có quản lý `version` / `onUpgrade`.
- FR-5.2: CRUD đầy đủ qua lớp `ExpenseRepository` (interface + triển khai sqflite).
- FR-5.3: **Lưu ảnh hóa đơn**: copy ảnh đã cắt vào thư mục ứng dụng (`path_provider` → `getApplicationDocumentsDirectory()/receipts/`), tạo **thumbnail** (ví dụ chiều rộng 256px, JPEG) trong isolate nền (`Isolate.run`/`compute`). DB chỉ lưu đường dẫn.
- FR-5.4: Xóa giao dịch thì xóa luôn file ảnh và thumbnail; có **Undo** qua SnackBar.
- FR-5.5: Phân loại theo 5 danh mục (enum `ExpenseCategory` có tên hiển thị tiếng Việt, icon, màu).

**FR-6. Biểu đồ Custom Canvas**
- FR-6.1: **Donut chart phân bổ theo danh mục** (`DonutChartPainter extends CustomPainter`): mỗi lát là `drawArc` dạng stroke; có animation quét từ 0 đến 1 bằng `AnimationController` + `AnimatedBuilder`; tổng tiền vẽ ở giữa bằng `TextPainter`; có chú thích (legend) gồm màu, tên danh mục, số tiền và %.
- FR-6.2: **Tương tác donut**: chạm vào một lát thì lát đó nổi bật (dày hơn hoặc lệch ra) và hiển thị chi tiết. Tính lát được chạm bằng `atan2` và khoảng cách đến tâm (hit-test vòng khuyên).
- FR-6.3: **Biểu đồ cột chi tiêu theo tuần** (`WeeklyBarPainter`): 7 cột T2 → CN của tuần đang chọn, chiều cao tỷ lệ với ngày cao nhất, cột bo góc (`drawRRect`), nhãn ngày và giá trị vẽ bằng `TextPainter`, có animation cột mọc lên; có nút chuyển tuần trước/sau; chạm vào cột thì hiện số tiền của ngày đó.
- FR-6.4: `shouldRepaint` phải so sánh **cả dữ liệu, màu, progress và lát/cột đang chọn** (không chỉ progress như slide).
- FR-6.5: Biểu đồ tự cập nhật khi thêm, sửa hoặc xóa giao dịch (thông qua Riverpod), animation chạy lại khi dữ liệu đổi.
- FR-6.6: Trạng thái rỗng (chưa có dữ liệu) hiển thị thông điệp thay vì biểu đồ trống.

**FR-7. Điều hướng & màn hình**
- FR-7.1: `GoRouter` + `ShellRoute` (hoặc `StatefulShellRoute`) với `NavigationBar` M3 gồm 3 tab: **Tổng quan** (Dashboard: tổng tháng, donut, cột tuần), **Quét** (Camera), **Lịch sử** (danh sách).
- FR-7.2: Route chi tiết hoặc sửa có path parameter: `/expense/:id`, `/review` (truyền dữ liệu parse qua `extra` hoặc provider).
- FR-7.3: Lịch sử dùng `ListView.builder`, item là `ExpenseSummaryCard` (bài lab Week 7: icon danh mục trong vòng tròn, tên + ngày xếp dọc `CrossAxisAlignment.start`, số tiền định dạng `###.### đ`, bọc trong `Card` + `InkWell`), có thumbnail; `Dismissible` + `ValueKey(id)` để xóa; lọc theo danh mục.

**FR-8. UI/UX**
- FR-8.1: Material 3, `ColorScheme.fromSeed(seedColor: Color(0xFF2C4570))` (VKU Navy) cho cả `theme` và `darkTheme`, `themeMode` theo hệ thống và có nút chuyển thủ công (sáng/tối/hệ thống) được lưu lại.
- FR-8.2: Responsive: dùng `LayoutBuilder`/`MediaQuery`; màn hình ngang hoặc rộng (≥ 600dp) thì Dashboard hiển thị donut và cột cạnh nhau. Không có lỗi `RenderFlex overflowed` ở cả dọc lẫn ngang.
- FR-8.3: `SafeArea`; định dạng tiền `NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0)`; ngày `dd/MM/yyyy`.
- FR-8.4: Trạng thái loading, rỗng và lỗi rõ ràng cho mọi màn hình dùng dữ liệu bất đồng bộ (`AsyncValue.when`).

### 3.5. Yêu cầu phi chức năng (NFR)
- NFR-1: Hoạt động **hoàn toàn offline**; không gọi mạng.
- NFR-2: Hiệu năng theo slide: dùng `const` tối đa; không tính toán nặng trong `build()` (parse và tạo thumbnail chạy ngoài UI thread); `ListView.builder` cho danh sách; `Consumer`/`select` để giới hạn phạm vi rebuild.
- NFR-3: Quản lý vòng đời: `dispose()` cho `CameraController`, `AnimationController`, `TextEditingController`, `FocusNode`; `close()` cho `TextRecognizer`; xử lý `AppLifecycleState` cho camera (tạm dừng/khởi tạo lại).
- NFR-4: Kiến trúc thư mục bắt buộc: `lib/core/`, `lib/models/`, `lib/services/`, `lib/state/`, `lib/widgets/`, `lib/screens/`.
- NFR-5: `flutter analyze` 0 issue; code được `dart format`.
- NFR-6: Chạy trên **thiết bị Android thật**; build **APK release đã ký**.

### 3.6. Rubric (10 điểm)
| Thành phần | Yêu cầu | Điểm |
|---|---|---|
| On-Device OCR & Heuristics | Chụp ảnh, ML Kit, regex trích Tổng tiền, Ngày, Tên cửa hàng | 3.5 |
| Custom Canvas Visualization | Donut/Pie animated + biểu đồ cột tuần bằng `CustomPainter` | 2.5 |
| State Management & DB | Provider/Riverpod 2, CRUD `sqflite`, lưu ảnh hóa đơn | 2.0 |
| UI/UX Polish | Material 3, dark mode, responsive, dialog review & sửa thủ công | 1.0 |
| Deliverables & Report | APK release đã ký, video demo, GitHub sạch, báo cáo PDF 2–4 trang | 1.0 |

### 3.7. Bộ hồ sơ nộp (3 deliverables)
1. **Live Demo / Release APK**: link tải `app-release.apk` (GitHub Releases hoặc Drive), đã test trên máy Android thật, kèm **video demo 2–3 phút**: quét trực tiếp một hóa đơn thật → parse → xác nhận ở màn Review → donut chart cập nhật có animation.
2. **GitHub Repository** public: lịch sử commit sạch, kiến trúc module, `README.md` có hướng dẫn cài đặt và lệnh build.
3. **Báo cáo kỹ thuật PDF 2–4 trang** theo template: checklist tính năng, sơ đồ kiến trúc, bảng regex OCR, ảnh chụp chế độ sáng/tối, các hạn chế.
- **Hạn nộp**: cuối Tuần 8 (Chủ nhật, 23:59). Trễ bị trừ 1 điểm/ngày.

---

## 4. Bản đồ kiến thức slide → nơi áp dụng trong code

| Slide | Kiến thức | Áp dụng ở |
|---|---|---|
| W7 s5 | Declarative UI = f(state) | Toàn bộ UI dựng từ state Riverpod |
| W7 s12 | Null safety `?`, `??`, `??=`, `?.`, `!` | `ParsedReceipt` (các trường nullable), hạn chế dùng `!` |
| W7 s13 | Records | Kết quả trung gian của parser, ví dụ `(int amount, Confidence c)` |
| W7 s14 | Pattern matching, switch expression | Gợi ý danh mục, màu/icon theo `ExpenseCategory` |
| W7 s15 | Constructor `const`, named, initializer list | Models, widgets |
| W7 s16 | `const` widget | Mọi widget tĩnh |
| W7 s17 | Future, Stream, async | OCR, DB, lưu file |
| W7 s19–24 | 3 cây, `canUpdate`, Key | `ValueKey(expense.id)` trong danh sách và `Dismissible` |
| W7 s26–29 | Stateless/Stateful, lifecycle, `dispose()` | Camera, form, animation controllers |
| W7 s30 | Antipattern: tính toán nặng trong `build()` | Parse và thumbnail ngoài `build`, dùng isolate |
| W7 s32–39 | M3, Scaffold, Row/Column, Expanded, Stack/Positioned, ListView.builder, SafeArea/MediaQuery | Toàn bộ layout; overlay camera dùng Stack |
| W7 s45 | Lab `ExpenseSummaryCard` | Item danh sách Lịch sử |
| W8 s4–6 | Ephemeral vs App state, InheritedWidget | Flash/focus là ephemeral (`setState`); danh sách chi tiêu là app state (Riverpod) |
| W8 s14–18 | Riverpod 2: `Notifier`, `ConsumerWidget`, `ref.watch/read`, `FutureProvider`, `AsyncValue` | Thư mục `lib/state/` |
| W8 s20–24 | GoRouter, path/query params, ShellRoute | `lib/core/router.dart` |
| W8 s26–28 | Form, `GlobalKey<FormState>`, validator, FocusNode | Màn Review |
| W8 s30–34 | CustomPainter, hệ tọa độ, `drawArc`, `AnimatedBuilder` | `lib/widgets/charts/` |
| W8 s36–39 | Platform Channels | **Không bắt buộc** theo rubric; chỉ làm nếu mọi phase đã xong (Phase 12, tùy chọn) |
| W8 s41–42 | Pipeline, regex | `lib/services/` |
| W8 s43 | Deliverables, cấu trúc thư mục | Phase 11 |

---

## 5. Các lỗi đã biết trong slide (phải làm đúng hơn slide, không chép nguyên)

1. **W8 s42 – regex từ khóa không dấu** (`tong tien|thanh toan`) không khớp với chữ có dấu từ OCR → bắt buộc chuẩn hóa bỏ dấu (FR-3.1).
2. **W8 s42 – split theo `\n`**: ML Kit thường tách nhãn và số tiền thành các block khác nhau → bắt buộc ghép hàng theo bounding box (FR-2.3).
3. **W8 s33 – `shouldRepaint` chỉ so sánh `progress`** → biểu đồ không vẽ lại khi dữ liệu đổi (FR-6.4).
4. **W8 s28 – `UniqueKey().toString()` làm ID** → dùng `INTEGER PRIMARY KEY AUTOINCREMENT`.
5. **W7 s42 / W7 s43 – chỉ có `image_picker`** → không đáp ứng viewfinder live, flash, focus → thêm gói `camera` (FR-1).
6. **W7 s43 – `pubspec.yaml` thiếu `path_provider`** (cần cho lưu ảnh) và có thể thiếu `camera`, `image`, `image_cropper`.
7. **Số tiền là `double`** trong slide → VND không có phần lẻ, lưu `int` để tránh lỗi làm tròn.
8. **Phiên bản gói trong slide có thể đã cũ**: dùng `flutter pub add` để lấy bản mới tương thích, **trừ `flutter_riverpod` phải giữ major 2.x**. Ghi phiên bản thực tế vào Decisions Log. Đọc README của từng gói (đặc biệt là `minSdkVersion` cho ML Kit/camera, cấu hình Android cho `image_cropper`) rồi cấu hình đúng.

---

## 6. Quy trình làm việc bắt buộc

### 6.1. Git workflow (để GitHub "đẹp")
- Nhánh chính: `main`. Cấu hình `git config user.name`/`user.email` **chỉ khi** chưa có; nếu chưa có thì hỏi tôi (BLOCKER loại "thông tin chỉ tôi có").
- Mỗi phase làm trên một nhánh riêng: `phase/<số>-<tên-ngắn>` (ví dụ `phase/2-receipt-parser`).
- Commit nhỏ, mỗi commit là một đơn vị logic hoàn chỉnh, build được. Thường 2–6 commit mỗi phase.
- Commit message theo **Conventional Commits** bằng tiếng Anh:
  - `type(scope): subject` (subject ≤ 72 ký tự, thể mệnh lệnh, không dấu chấm cuối).
  - type thuộc: `feat`, `fix`, `test`, `refactor`, `docs`, `chore`, `build`, `style`, `perf`.
  - Có body giải thích **why** khi thay đổi không hiển nhiên.
  - Ví dụ: `feat(parser): extract totals using diacritic-insensitive keywords`.
- Kết thúc phase (sau khi Quality Gate pass): `git checkout main && git merge --no-ff phase/... -m "merge: phase N - <tên>"`, sau đó tạo tag nhẹ `phase-N`.
- Kết thúc dự án: tag `v1.0.0`.
- Không commit file sinh ra khi build. Kiểm tra `git status` sạch sau mỗi phase.

### 6.2. Quality Gate (tự kiểm thử sau MỖI phase, bắt buộc pass mới được merge)
Chạy theo thứ tự và ghi kết quả:
1. `dart format --output=none --set-exit-if-changed lib test`
2. `flutter analyze` → **0 issues**
3. `flutter test` → **100% pass** (kể cả test cũ, để đảm bảo không regression)
4. Từ Phase 1 trở đi: `flutter build apk --debug` → thành công
5. Nếu `flutter devices` thấy thiết bị hoặc emulator Android: chạy `flutter test integration_test` (từ Phase 8), hoặc ít nhất `flutter run` để kiểm tra khởi động không lỗi. Nếu **không có thiết bị**: ghi rõ "chưa test trên thiết bị" và viết **checklist test thủ công** cho phase đó trong `docs/TEST_REPORT.md` để tôi tự kiểm tra. Đây không được coi là pass phần test trên thiết bị.
6. Rà soát lại các FR thuộc phase: đánh `[x]` trong `CLAUDE.md` **chỉ khi** có test hoặc bằng chứng chứng minh.

Nếu bất kỳ bước nào fail: sửa code và chạy lại toàn bộ gate. Không merge khi gate chưa xanh.

### 6.3. Tài liệu sau mỗi phase
- Cập nhật **Progress Log** trong `CLAUDE.md`.
- Thêm một mục vào `docs/PHASE_LOG.md` (tiếng Việt, viết cho sinh viên đọc hiểu):
  - **Mục tiêu phase** và các FR liên quan.
  - **Đã làm gì**: file nào, class nào, vai trò của từng phần.
  - **Vì sao làm vậy**: liên hệ với slide nào (W7/W8 số slide), các lựa chọn thay thế đã cân nhắc.
  - **Khái niệm cần hiểu**: giải thích ngắn các khái niệm mới (ví dụ: row grouping theo bounding box, AsyncNotifier, hit-test bằng atan2).
  - **Kết quả kiểm thử**: số test, lệnh đã chạy, kết quả.
  - **Cách tự kiểm tra bằng tay** trên máy.
  - **Danh sách commit** của phase (`git log --oneline main..phase/...` trước khi merge).
- Cập nhật `docs/TEST_REPORT.md` (bảng: phase, số test, pass/fail, coverage nếu có, kết quả test thủ công).

---

## 7. KẾ HOẠCH PHASE (thực hiện tuần tự)

### Phase 0 — Khởi tạo & môi trường
- Kiểm tra: `flutter --version` (phải là 3.x, Dart 3), `dart --version`, `flutter doctor -v`, `git --version`, `java -version`/`keytool`. Thiếu thì ghi BLOCKER kèm lệnh khắc phục cụ thể.
- Nếu thư mục chưa có `pubspec.yaml`: `flutter create --org vn.edu.vku --project-name vku_expense_ocr --platforms android,ios .` (giữ nguyên file brief). Nếu đã có project thì kiểm tra lại cấu hình.
- `git init -b main`; `.gitignore` chuẩn Flutter, bổ sung `*.jks`, `*.keystore`, `android/key.properties`, `*.apk`, `*.aab`, `.env`, `coverage/`.
- Tạo `CLAUDE.md` (mục 1), `docs/PROJECT_BRIEF.md`, `docs/PHASE_LOG.md`, `docs/TEST_REPORT.md`, `README.md` khung.
- Bật lint chặt hơn trong `analysis_options.yaml` (ví dụ `prefer_const_constructors`, `prefer_final_locals`, `always_declare_return_types`, `avoid_print`, `use_build_context_synchronously`).
- Commit gợi ý: `chore: scaffold flutter project`, `docs: add CLAUDE.md with frozen requirements and phase plan`, `chore(lint): enable stricter analysis options`.
- Gate: analyze + test mặc định + build debug.

### Phase 1 — Nền tảng: models, theme, router, cấu trúc thư mục
- Thêm dependencies: `flutter_riverpod` (^2.x), `go_router`, `intl`, `sqflite`, `path`, `path_provider`, `google_mlkit_text_recognition`, `camera`, `image_picker`, `image_cropper`, `image`; dev: `sqflite_common_ffi`, `mocktail`, `integration_test` (sdk). Cấu hình Android: `minSdkVersion`, quyền camera, activity của `image_cropper` theo README từng gói; iOS: `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`.
- Tạo cấu trúc `lib/core|models|services|state|widgets|screens`.
- `models/`: `ExpenseCategory` (enum 5 giá trị + label tiếng Việt + icon + màu, dùng switch expression), `Expense` (immutable, `const` constructor, `copyWith`, `toMap/fromMap`, `amount` là `int`), `OcrLine`, `ParsedReceipt`, `FieldConfidence`.
- `core/`: `app_theme.dart` (M3 light/dark từ seed VKU Navy), `formatters.dart` (VND, ngày), `router.dart` (GoRouter + ShellRoute 3 tab, các màn hình placeholder), `text_normalizer.dart` (bỏ dấu tiếng Việt).
- `main.dart`: `ProviderScope` + `MaterialApp.router`; `initializeDateFormatting('vi_VN')`.
- Test: `toMap/fromMap` round-trip, formatter VND (`150000 → "150.000 đ"`), bỏ dấu (`"Tổng Tiền Thanh Toán" → "tong tien thanh toan"`, `"Đ" → "d"`), switch danh mục đủ 5 nhánh, router khởi động không lỗi (widget test).

### Phase 2 — ReceiptParser (TDD, phần quan trọng nhất)
- Viết test **trước**, sau đó mới viết code.
- Tạo **≥ 15 fixture** văn bản hóa đơn tổng hợp mô phỏng hóa đơn thật ở Việt Nam, đặt tại `test/fixtures/receipts/*.txt` hoặc dưới dạng danh sách `OcrLine` kèm bounding box: Co.op Mart, WinMart, Bách Hóa Xanh, Highlands Coffee, Phúc Long, The Coffee House, Circle K, GS25, Lotte Mart, nhà sách Fahasa, Grab/Be (Travel), rạp CGV (Entertainment), cửa hàng điện tử (Gear), quán cơm nhỏ, hóa đơn tiếng Anh. Fixture phải gồm các ca khó: có cả "Tổng tiền hàng" và "Tổng thanh toán" sau giảm giá, nhãn và số tiền nằm ở 2 block khác nhau, số điện thoại hoặc MST gần số tiền, ngày có giờ, năm 2 chữ số, chữ OCR mất dấu hoặc sai ký tự nhẹ (`TONG TIEN`, `Tong tlen`), số tiền dạng `150,000`, `150.000đ`, `1.250.000 VNĐ`.
- Mỗi fixture có kết quả kỳ vọng (merchant, total, date, category) viết **trước khi** chạy parser. Không chỉnh kỳ vọng để khớp với output.
- Triển khai `lib/services/receipt_parser.dart`: các hàm nhỏ thuần Dart (`extractTotal`, `extractDate`, `extractMerchant`, `suggestCategory`, `parse`), không phụ thuộc Flutter UI hay ML Kit.
- Triển khai `lib/services/row_grouper.dart` (FR-2.3) cùng test với bounding box giả.
- Viết `docs/REGEX_TABLE.md`.
- Báo cáo **độ chính xác trên bộ fixture** cho từng trường (ví dụ total 14/15) trong PHASE_LOG và TEST_REPORT. Fixture nào fail thì phải được ghi rõ là "known limitation" kèm lý do. Chỉ được phép làm vậy sau khi đã thực sự cố gắng sửa, và không được xóa fixture đó.

### Phase 3 — Dịch vụ OCR (ML Kit)
- `lib/services/ocr_service.dart`: interface `OcrService` + `MlKitOcrService` (InputImage từ file, recognizer latin, chuyển sang `List<OcrLine>`, đo `Stopwatch`, `close()`).
- Pipeline `ReceiptScanService`: ảnh → OCR → group rows → parse → `ParsedReceipt` + thời gian xử lý.
- Test: `ReceiptScanService` với `FakeOcrService` (fake chỉ nằm trong `test/`), kiểm tra pipeline và xử lý lỗi (ảnh hỏng, text rỗng → trả về ParsedReceipt với các trường `missing`, không crash).
- Thêm màn hình debug tạm (chọn ảnh từ thư viện → hiển thị raw text + kết quả parse) để kiểm tra trên máy thật. Màn này sau đó trở thành phần "Xem văn bản OCR gốc" của Review, không để lại code chết.

### Phase 4 — CSDL & lưu ảnh
- `lib/services/database_service.dart` (mở DB, schema version 1, `onCreate`, `onUpgrade`), `ExpenseRepository` + `SqfliteExpenseRepository` (insert, getAll sắp xếp theo ngày giảm dần, getById, update, delete, query theo khoảng ngày, tổng theo danh mục).
- `lib/services/image_storage_service.dart`: lưu ảnh vào `receipts/`, tạo thumbnail bằng gói `image` trong `Isolate.run`, xóa file.
- Test: repository với `sqflite_common_ffi` (DB in-memory), đủ CRUD và truy vấn theo khoảng ngày; image storage với thư mục tạm (ghi, tạo thumbnail đúng kích thước, xóa).

### Phase 5 — State management (Riverpod 2)
- Providers: `expenseRepositoryProvider`, `imageStorageProvider`, `ocrServiceProvider`, `expenseListProvider` (`AsyncNotifier<List<Expense>>` với `add/update/remove/restore`), `categoryTotalsProvider` (dẫn xuất), `selectedWeekProvider`, `weeklyTotalsProvider` (7 phần tử T2 → CN), `monthTotalProvider`, `themeModeProvider`, `scanControllerProvider` (trạng thái quét: idle/processing/result/error).
- Test với `ProviderContainer` + override bằng repository giả: thêm → danh sách và tổng cập nhật; xóa → giảm; restore (undo); tính tuần đúng biên (Chủ nhật, đổi tháng/năm); tổng theo danh mục đúng.

### Phase 6 — Camera capture
- `screens/scan/camera_screen.dart`: khởi tạo camera sau (back), `CameraPreview`, nút flash, chạm lấy nét có vòng chỉ báo, overlay khung (`CustomPainter` vẽ lớp tối có lỗ hình chữ nhật), nút chụp, nút chọn từ thư viện; xử lý `AppLifecycleState`; xử lý khi không có camera hoặc bị từ chối quyền.
- `services/image_crop_service.dart`: quy đổi khung overlay sang tọa độ ảnh (tính đến tỷ lệ preview, `BoxFit` và hướng xoay), cắt bằng gói `image` trong isolate, sau đó mở `image_cropper` để chỉnh tay.
- Chụp hoặc chọn ảnh xong → chạy `ReceiptScanService` (hiện loading) → điều hướng sang Review.
- Test: unit test hàm quy đổi tọa độ khung → vùng cắt (nhiều tỷ lệ màn hình/ảnh); unit test cắt ảnh trả về đúng kích thước; widget test overlay painter (`shouldRepaint`). Camera thật thì đưa vào checklist test thủ công.

### Phase 7 — Màn Review & Verification
- Triển khai đủ FR-4 (form, validator, date picker, chọn danh mục, đánh dấu độ tin cậy thấp, raw text, thời gian OCR, input formatter VND, focus, xác nhận khi hủy, chế độ thêm thủ công và chế độ sửa).
- Lưu: lưu ảnh và thumbnail → insert DB qua notifier → SnackBar → quay về.
- Widget test: hiển thị dữ liệu parse sẵn; trường `missing` được đánh dấu; validator chặn số tiền ≤ 0, tên rỗng, ngày tương lai, chưa chọn danh mục; submit hợp lệ gọi `add` (repository giả); chế độ sửa gọi `update`.

### Phase 8 — Lịch sử & Dashboard (khung)
- `widgets/expense_summary_card.dart` (bài lab Week 7, có thumbnail), `screens/history/` (ListView.builder, lọc danh mục, Dismissible + Undo, chạm để sửa `/expense/:id`), Dashboard hiển thị tổng tháng và các vị trí dành cho biểu đồ.
- FAB hoặc nút "Thêm thủ công".
- Widget test: danh sách hiển thị đúng thứ tự; vuốt xóa → biến mất → Undo → quay lại; lọc danh mục; trạng thái rỗng.
- `integration_test/app_flow_test.dart`: luồng thêm thủ công → xuất hiện trong lịch sử → tổng trên dashboard đổi (chạy khi có thiết bị).

### Phase 9 — Biểu đồ CustomPainter
- `widgets/charts/donut_chart_painter.dart` + `donut_chart.dart` (StatefulWidget, `SingleTickerProviderStateMixin`, `AnimationController` + `CurvedAnimation`, chạy lại khi dữ liệu đổi trong `didUpdateWidget`, hit-test chạm, legend).
- `widgets/charts/weekly_bar_painter.dart` + `weekly_bar_chart.dart` (animation, chạm cột, chuyển tuần).
- Tách phần hình học thành hàm thuần để test: `angleToSliceIndex`, `isPointInRing`, `barRects(values, size)`, `percentages(totals)`.
- Test: unit test hình học (góc tại 12h/3h/6h/9h với `startAngle = -π/2`, điểm ngoài vòng khuyên, tổng % = 1, tất cả giá trị = 0); `shouldRepaint` đúng khi dữ liệu/progress/selection đổi; widget test chạm vào lát → hiện chi tiết; animation hoàn tất sau `pumpAndSettle`.
- Gắn vào Dashboard; xác nhận biểu đồ tự cập nhật khi thêm giao dịch (widget test với provider override).

### Phase 10 — UI/UX polish
- Chuyển theme (sáng/tối/hệ thống); layout responsive ≥ 600dp; kiểm tra không overflow ở cả dọc và ngang bằng widget test với nhiều kích thước (`tester.view.physicalSize`); `Semantics` cho các nút icon; empty/loading/error states thống nhất; icon app và tên hiển thị "VKU Expense OCR".
- Rà soát `const`, `dispose`, và tính toán trong `build()` theo NFR-2/NFR-3; ghi kết quả rà soát vào PHASE_LOG.

### Phase 11 — Release & Deliverables
- **Ký APK**: cấu hình `android/app/build.gradle(.kts)` đọc `key.properties`. Nếu có `keytool`: tạo keystore tại `~/vku-keys/upload-keystore.jks` (ngoài repo) với mật khẩu ngẫu nhiên mạnh, ghi vào `android/key.properties` (đã gitignore). Thông báo rõ cho tôi đường dẫn file và yêu cầu **sao lưu**. Viết `docs/SIGNING.md` hướng dẫn tự tạo lại keystore.
- `flutter build apk --release` → xác minh chữ ký (`apksigner verify --print-certs` hoặc `keytool -printcert -jarfile`), ghi kích thước APK và đường dẫn output.
- `README.md` hoàn chỉnh: giới thiệu, tính năng (checklist FR), ảnh chụp (`docs/screenshots/`, để placeholder và hướng dẫn tôi chụp nếu không chụp được), kiến trúc (sơ đồ Mermaid pipeline + cấu trúc thư mục), công nghệ và phiên bản, yêu cầu môi trường, lệnh `flutter pub get` / `flutter run` / `flutter test` / `flutter build apk --release`, link tải APK (placeholder), hạn chế, tác giả (placeholder).
- `docs/REPORT.md`: bản nguồn của báo cáo PDF 2–4 trang theo đúng cấu trúc yêu cầu: (1) checklist tính năng, (2) sơ đồ kiến trúc, (3) bảng regex OCR, (4) ảnh sáng/tối, (5) kết quả đo OCR và độ chính xác parser, (6) hạn chế và hướng phát triển. Nếu có `pandoc` thì xuất thử `docs/REPORT.pdf`; nếu không thì hướng dẫn tôi cách xuất.
- `docs/DEMO_SCRIPT.md`: kịch bản quay video 2–3 phút theo từng cảnh, có mốc thời gian.
- `CHANGELOG.md` tổng hợp theo phase.
- Gate cuối: toàn bộ test pass, analyze 0, build release thành công. Merge, tag `v1.0.0`.

### Phase 12 — (Tùy chọn, chỉ khi Phase 0–11 đã hoàn tất) Platform Channel
- `MethodChannel('vn.edu.vku/device_info')` theo W8 s37–38: ví dụ rung haptic khi lưu thành công, hoặc đọc mức pin hiển thị cảnh báo trước khi quét. Có test bằng `TestDefaultBinaryMessengerBinding` mock handler. Ghi rõ đây là phần mở rộng.

---

## 8. Báo cáo cuối cùng gửi tôi (sau Phase 11)

Khi hoàn tất, in ra trong chat:
1. Bảng tổng kết: từng FR → trạng thái (Done / Partial / Blocked) → bằng chứng (file test hoặc mô tả).
2. Kết quả Quality Gate cuối và độ chính xác parser trên fixture.
3. `git log --oneline --graph --decorate` (rút gọn).
4. Những việc **tôi** cần tự làm: test trên máy thật bằng hóa đơn thật theo checklist trong `docs/TEST_REPORT.md`, chụp màn hình, quay video theo `docs/DEMO_SCRIPT.md`, sao lưu keystore, xuất PDF.
5. Hướng dẫn push lên GitHub:
   ```bash
   git remote add origin https://github.com/<username>/vku-expense-ocr.git
   git push -u origin main
   git push origin --tags
   ```
   Sau đó tạo GitHub Release từ tag `v1.0.0` và đính kèm `build/app/outputs/flutter-apk/app-release.apk`.

---

**Bắt đầu ngay với Phase 0.** Nhắc lại: không sửa requirement để né lỗi, không gian lận test, không push, commit theo phase, tự chạy Quality Gate sau mỗi phase và ghi nhật ký cho tôi hiểu.
