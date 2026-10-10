# CLAUDE.md — VKU Expense OCR (Mini-Project 3)

> File điều phối cho Claude Code. Nguồn gốc: `docs/PROJECT_BRIEF.md`.
> Các mục đánh dấu *chép nguyên văn* được sinh tự động từ brief, không chỉnh sửa nội dung.

## Khôi phục phiên làm việc

Nếu phiên bị gián đoạn hoặc context bị nén: đọc mục **Progress Log** bên dưới và chạy
`git log --oneline --graph --all`, rồi tiếp tục từ đầu việc `[ ]` đầu tiên chưa xong
của phase đang dở. Không làm lại từ đầu.

Môi trường máy hiện tại (cập nhật ở Phase 0):

- Thư mục dự án: `D:\Start Github\Projects\vku-ocr-expense` (repo git riêng, nhánh chính `main`).
- Flutter SDK: `D:\flutter` (stable **3.47.6**, Dart **3.13.5**). Đã thêm `D:\flutter\bin` vào PATH của User,
  nhưng các tiến trình mở **trước** khi cài vẫn chưa thấy → gọi bằng đường dẫn đầy đủ `D:\flutter\bin\flutter`.
- **Bắt buộc** trước mọi lệnh pub/build (đã đặt ở cấp User; trong phiên cũ phải tự export):
  `GRADLE_USER_HOME=D:\dev-cache\gradle`, `PUB_CACHE=D:\dev-cache\pub` (ổ C: gần đầy).
- Android SDK: `D:\Android\SDK` (NDK 28.2.13676358 đã cài tay). JDK cho Gradle: Temurin 21
  (`flutter config --jdk-dir`). Không đổi `java` 1.8 trên PATH hệ thống.
- Không đụng tới repo git ở gốc `D:\`.
- Chi tiết cài đặt: `docs/SETUP_ENV.md`.

---

## Quy tắc làm việc (chép nguyên văn mục 2 và mục 6 của brief)

### 2. QUY TẮC BẤT DI BẤT DỊCH (Integrity Rules)

#### 2.1. Không được sửa yêu cầu để né lỗi
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

#### 2.2. Không gian lận test
- Không xóa test, không `skip:` test, không nới lỏng assertion, không sửa dữ liệu kỳ vọng chỉ để test pass.
- Không viết code đặc biệt nhận diện dữ liệu test (special-casing).
- Không dùng `// ignore:` hay `// ignore_for_file:` để tắt cảnh báo của `flutter analyze`. Ngoại lệ duy nhất là lỗi do code sinh tự động, và phải ghi lý do vào Decisions Log.
- Khi test fail: sửa **code** cho đúng. Chỉ sửa test khi chính test sai so với requirement, và phải giải thích trong commit message.

#### 2.3. BLOCKER là gì (chỉ những trường hợp này mới được dừng lại hỏi)
- Thiếu công cụ hoặc môi trường: chưa cài Flutter, Android SDK, chưa chấp nhận license, thiếu `keytool`, Flutter không phải bản 3.x.
- Một requirement mâu thuẫn hoặc không khả thi (theo mục 2.1).
- Cần thông tin chỉ tôi có (ví dụ tên hiển thị của tôi trong README hoặc báo cáo).

Với các lỗi biên dịch, lỗi phụ thuộc hay lỗi test thông thường: **tự điều tra và sửa**, không dừng lại hỏi.

#### 2.4. Bảo mật và Git
- Không bao giờ commit: keystore (`*.jks`, `*.keystore`), `android/key.properties`, file `.env`, thư mục `build/`, file APK/AAB, `.dart_tool/`.
- Không tạo remote, không push, không force-push, không rewrite lịch sử (`rebase -i`, `commit --amend` trên commit đã merge).

### 6. Quy trình làm việc bắt buộc

#### 6.1. Git workflow (để GitHub "đẹp")
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

#### 6.2. Quality Gate (tự kiểm thử sau MỖI phase, bắt buộc pass mới được merge)
Chạy theo thứ tự và ghi kết quả:
1. `dart format --output=none --set-exit-if-changed lib test`
2. `flutter analyze` → **0 issues**
3. `flutter test` → **100% pass** (kể cả test cũ, để đảm bảo không regression)
4. Từ Phase 1 trở đi: `flutter build apk --debug` → thành công
5. Nếu `flutter devices` thấy thiết bị hoặc emulator Android: chạy `flutter test integration_test` (từ Phase 8), hoặc ít nhất `flutter run` để kiểm tra khởi động không lỗi. Nếu **không có thiết bị**: ghi rõ "chưa test trên thiết bị" và viết **checklist test thủ công** cho phase đó trong `docs/TEST_REPORT.md` để tôi tự kiểm tra. Đây không được coi là pass phần test trên thiết bị.
6. Rà soát lại các FR thuộc phase: đánh `[x]` trong `CLAUDE.md` **chỉ khi** có test hoặc bằng chứng chứng minh.

Nếu bất kỳ bước nào fail: sửa code và chạy lại toàn bộ gate. Không merge khi gate chưa xanh.

#### 6.3. Tài liệu sau mỗi phase
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

## Requirements (FROZEN — không được sửa)

> Chép nguyên văn mục 3 của brief. KHÔNG BAO GIỜ chỉnh sửa mục này.

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

## Bản đồ kiến thức slide → code (chép mục 4)

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

## Các lỗi đã biết trong slide cần sửa (chép mục 5)

1. **W8 s42 – regex từ khóa không dấu** (`tong tien|thanh toan`) không khớp với chữ có dấu từ OCR → bắt buộc chuẩn hóa bỏ dấu (FR-3.1).
2. **W8 s42 – split theo `\n`**: ML Kit thường tách nhãn và số tiền thành các block khác nhau → bắt buộc ghép hàng theo bounding box (FR-2.3).
3. **W8 s33 – `shouldRepaint` chỉ so sánh `progress`** → biểu đồ không vẽ lại khi dữ liệu đổi (FR-6.4).
4. **W8 s28 – `UniqueKey().toString()` làm ID** → dùng `INTEGER PRIMARY KEY AUTOINCREMENT`.
5. **W7 s42 / W7 s43 – chỉ có `image_picker`** → không đáp ứng viewfinder live, flash, focus → thêm gói `camera` (FR-1).
6. **W7 s43 – `pubspec.yaml` thiếu `path_provider`** (cần cho lưu ảnh) và có thể thiếu `camera`, `image`, `image_cropper`.
7. **Số tiền là `double`** trong slide → VND không có phần lẻ, lưu `int` để tránh lỗi làm tròn.
8. **Phiên bản gói trong slide có thể đã cũ**: dùng `flutter pub add` để lấy bản mới tương thích, **trừ `flutter_riverpod` phải giữ major 2.x**. Ghi phiên bản thực tế vào Decisions Log. Đọc README của từng gói (đặc biệt là `minSdkVersion` cho ML Kit/camera, cấu hình Android cho `image_cropper`) rồi cấu hình đúng.

---

## Kế hoạch Phase (chép mục 7, kèm checklist)

### Phase 0 — Khởi tạo & môi trường
- [x] Kiểm tra: `flutter --version` (phải là 3.x, Dart 3), `dart --version`, `flutter doctor -v`, `git --version`, `java -version`/`keytool`. Thiếu thì ghi BLOCKER kèm lệnh khắc phục cụ thể.
- [x] Nếu thư mục chưa có `pubspec.yaml`: `flutter create --org vn.edu.vku --project-name vku_expense_ocr --platforms android,ios .` (giữ nguyên file brief). Nếu đã có project thì kiểm tra lại cấu hình.
- [x] `git init -b main`; `.gitignore` chuẩn Flutter, bổ sung `*.jks`, `*.keystore`, `android/key.properties`, `*.apk`, `*.aab`, `.env`, `coverage/`.
- [x] Tạo `CLAUDE.md` (mục 1), `docs/PROJECT_BRIEF.md`, `docs/PHASE_LOG.md`, `docs/TEST_REPORT.md`, `README.md` khung.
- [x] Bật lint chặt hơn trong `analysis_options.yaml` (ví dụ `prefer_const_constructors`, `prefer_final_locals`, `always_declare_return_types`, `avoid_print`, `use_build_context_synchronously`).
- [x] Commit gợi ý: `chore: scaffold flutter project`, `docs: add CLAUDE.md with frozen requirements and phase plan`, `chore(lint): enable stricter analysis options`.
- [x] Gate: analyze + test mặc định + build debug.

### Phase 1 — Nền tảng: models, theme, router, cấu trúc thư mục
- [x] Thêm dependencies: `flutter_riverpod` (^2.x), `go_router`, `intl`, `sqflite`, `path`, `path_provider`, `google_mlkit_text_recognition`, `camera`, `image_picker`, `image_cropper`, `image`; dev: `sqflite_common_ffi`, `mocktail`, `integration_test` (sdk). Cấu hình Android: `minSdkVersion`, quyền camera, activity của `image_cropper` theo README từng gói; iOS: `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`.
- [x] Tạo cấu trúc `lib/core|models|services|state|widgets|screens`.
- [x] `models/`: `ExpenseCategory` (enum 5 giá trị + label tiếng Việt + icon + màu, dùng switch expression), `Expense` (immutable, `const` constructor, `copyWith`, `toMap/fromMap`, `amount` là `int`), `OcrLine`, `ParsedReceipt`, `FieldConfidence`.
- [x] `core/`: `app_theme.dart` (M3 light/dark từ seed VKU Navy), `formatters.dart` (VND, ngày), `router.dart` (GoRouter + ShellRoute 3 tab, các màn hình placeholder), `text_normalizer.dart` (bỏ dấu tiếng Việt).
- [x] `main.dart`: `ProviderScope` + `MaterialApp.router`; `initializeDateFormatting('vi_VN')`.
- [x] Test: `toMap/fromMap` round-trip, formatter VND (`150000 → "150.000 đ"`), bỏ dấu (`"Tổng Tiền Thanh Toán" → "tong tien thanh toan"`, `"Đ" → "d"`), switch danh mục đủ 5 nhánh, router khởi động không lỗi (widget test).

### Phase 2 — ReceiptParser (TDD, phần quan trọng nhất)
- [x] Viết test **trước**, sau đó mới viết code.
- [x] Tạo **≥ 15 fixture** văn bản hóa đơn tổng hợp mô phỏng hóa đơn thật ở Việt Nam, đặt tại `test/fixtures/receipts/*.txt` hoặc dưới dạng danh sách `OcrLine` kèm bounding box: Co.op Mart, WinMart, Bách Hóa Xanh, Highlands Coffee, Phúc Long, The Coffee House, Circle K, GS25, Lotte Mart, nhà sách Fahasa, Grab/Be (Travel), rạp CGV (Entertainment), cửa hàng điện tử (Gear), quán cơm nhỏ, hóa đơn tiếng Anh. Fixture phải gồm các ca khó: có cả "Tổng tiền hàng" và "Tổng thanh toán" sau giảm giá, nhãn và số tiền nằm ở 2 block khác nhau, số điện thoại hoặc MST gần số tiền, ngày có giờ, năm 2 chữ số, chữ OCR mất dấu hoặc sai ký tự nhẹ (`TONG TIEN`, `Tong tlen`), số tiền dạng `150,000`, `150.000đ`, `1.250.000 VNĐ`.
- [x] Mỗi fixture có kết quả kỳ vọng (merchant, total, date, category) viết **trước khi** chạy parser. Không chỉnh kỳ vọng để khớp với output.
- [x] Triển khai `lib/services/receipt_parser.dart`: các hàm nhỏ thuần Dart (`extractTotal`, `extractDate`, `extractMerchant`, `suggestCategory`, `parse`), không phụ thuộc Flutter UI hay ML Kit.
- [x] Triển khai `lib/services/row_grouper.dart` (FR-2.3) cùng test với bounding box giả.
- [x] Viết `docs/REGEX_TABLE.md`.
- [x] Báo cáo **độ chính xác trên bộ fixture** cho từng trường (ví dụ total 14/15) trong PHASE_LOG và TEST_REPORT. Fixture nào fail thì phải được ghi rõ là "known limitation" kèm lý do. Chỉ được phép làm vậy sau khi đã thực sự cố gắng sửa, và không được xóa fixture đó.

### Phase 3 — Dịch vụ OCR (ML Kit)
- [x] `lib/services/ocr_service.dart`: interface `OcrService` + `MlKitOcrService` (InputImage từ file, recognizer latin, chuyển sang `List<OcrLine>`, đo `Stopwatch`, `close()`).
- [x] Pipeline `ReceiptScanService`: ảnh → OCR → group rows → parse → `ParsedReceipt` + thời gian xử lý.
- [x] Test: `ReceiptScanService` với `FakeOcrService` (fake chỉ nằm trong `test/`), kiểm tra pipeline và xử lý lỗi (ảnh hỏng, text rỗng → trả về ParsedReceipt với các trường `missing`, không crash).
- [x] Đánh giá trên hóa đơn thật `D:\receipts-test\`: **trước khi chấm** phải kiểm tra SHA-256 của `ground_truth.csv` bằng `0ec9054112e46ecebf22f87b5d12dec588c9aea5c52eacad37f2ae134d03ecc0`; không khớp thì **dừng lại báo bạn**. Chấm theo mục "Quy tắc gán nhãn & chấm điểm hóa đơn thật" trong `docs/TEST_REPORT.md`, báo riêng set=main / set=edge. Không sửa `ground_truth.csv`. *(Yêu cầu bổ sung của bạn, không thuộc brief gốc.)* → đã chạy trên **emulator** (lần đầu + sau sửa, `docs/TEST_REPORT.md`); trên điện thoại thật còn nợ.
- [x] Thêm màn hình debug tạm (chọn ảnh từ thư viện → hiển thị raw text + kết quả parse) để kiểm tra trên máy thật. Màn này sau đó trở thành phần "Xem văn bản OCR gốc" của Review, không để lại code chết.

### Phase 4 — CSDL & lưu ảnh
- [x] `lib/services/database_service.dart` (mở DB, schema version 1, `onCreate`, `onUpgrade`), `ExpenseRepository` + `SqfliteExpenseRepository` (insert, getAll sắp xếp theo ngày giảm dần, getById, update, delete, query theo khoảng ngày, tổng theo danh mục).
- [x] `lib/services/image_storage_service.dart`: lưu ảnh vào `receipts/`, tạo thumbnail bằng gói `image` trong `Isolate.run`, xóa file.
- [x] Test: repository với `sqflite_common_ffi` (DB in-memory), đủ CRUD và truy vấn theo khoảng ngày; image storage với thư mục tạm (ghi, tạo thumbnail đúng kích thước, xóa).

### Phase 5 — State management (Riverpod 2)
- [x] Providers: `expenseRepositoryProvider`, `imageStorageProvider`, `ocrServiceProvider`, `expenseListProvider` (`AsyncNotifier<List<Expense>>` với `add/update/remove/restore`), `categoryTotalsProvider` (dẫn xuất), `selectedWeekProvider`, `weeklyTotalsProvider` (7 phần tử T2 → CN), `monthTotalProvider`, `themeModeProvider`, `scanControllerProvider` (trạng thái quét: idle/processing/result/error).
- [x] Test với `ProviderContainer` + override bằng repository giả: thêm → danh sách và tổng cập nhật; xóa → giảm; restore (undo); tính tuần đúng biên (Chủ nhật, đổi tháng/năm); tổng theo danh mục đúng.

### Phase 6 — Camera capture
- [x] `screens/scan/camera_screen.dart`: khởi tạo camera sau (back), `CameraPreview`, nút flash, chạm lấy nét có vòng chỉ báo, overlay khung (`CustomPainter` vẽ lớp tối có lỗ hình chữ nhật), nút chụp, nút chọn từ thư viện; xử lý `AppLifecycleState`; xử lý khi không có camera hoặc bị từ chối quyền.
- [x] `services/image_crop_service.dart`: quy đổi khung overlay sang tọa độ ảnh (tính đến tỷ lệ preview, `BoxFit` và hướng xoay), cắt bằng gói `image` trong isolate, sau đó mở `image_cropper` để chỉnh tay.
- [x] Chụp hoặc chọn ảnh xong → chạy `ReceiptScanService` (hiện loading) → điều hướng sang Review.
- [x] `CameraController(..., enableAudio: false)` — quyền micro `RECORD_AUDIO` đã bị gỡ khỏi manifest ở Phase 1 (D-014); để `enableAudio` mặc định (`true`) sẽ khiến camera lỗi hoặc xin quyền thừa. *(Ghi chú bổ sung theo yêu cầu của bạn ở Phase 2, không thuộc brief gốc.)*
- [x] Test: unit test hàm quy đổi tọa độ khung → vùng cắt (nhiều tỷ lệ màn hình/ảnh); unit test cắt ảnh trả về đúng kích thước; widget test overlay painter (`shouldRepaint`). Camera thật thì đưa vào checklist test thủ công.

### Phase 7 — Màn Review & Verification
- [x] Triển khai đủ FR-4 (form, validator, date picker, chọn danh mục, đánh dấu độ tin cậy thấp, raw text, thời gian OCR, input formatter VND, focus, xác nhận khi hủy, chế độ thêm thủ công và chế độ sửa).
- [x] Lưu: lưu ảnh và thumbnail → insert DB qua notifier → SnackBar → quay về.
- [x] Từ kết quả đánh giá Phase 3, tên cửa hàng là trường yếu nhất (7/19): FR-4.4 phải đánh dấu thật rõ khi merchant có độ tin cậy low/missing để người dùng kiểm tra lại. *(Yêu cầu bổ sung của bạn ở Phase 4, không thuộc brief gốc.)*
- [x] Widget test: hiển thị dữ liệu parse sẵn; trường `missing` được đánh dấu; validator chặn số tiền ≤ 0, tên rỗng, ngày tương lai, chưa chọn danh mục; submit hợp lệ gọi `add` (repository giả); chế độ sửa gọi `update`.

### Phase 8 — Lịch sử & Dashboard (khung)
- [x] `widgets/expense_summary_card.dart` (bài lab Week 7, có thumbnail), `screens/history/` (ListView.builder, lọc danh mục, Dismissible + Undo, chạm để sửa `/expense/:id`), Dashboard hiển thị tổng tháng và các vị trí dành cho biểu đồ.
- [x] FAB hoặc nút "Thêm thủ công".
- [x] Widget test: danh sách hiển thị đúng thứ tự; vuốt xóa → biến mất → Undo → quay lại; lọc danh mục; trạng thái rỗng.
- [ ] `integration_test/app_flow_test.dart`: luồng thêm thủ công → xuất hiện trong lịch sử → tổng trên dashboard đổi (chạy khi có thiết bị). → **đã viết, CHƯA chạy** (chưa có thiết bị; không bật emulator ở Phase 8), xem Việc còn nợ.

### Phase 9 — Biểu đồ CustomPainter
- [x] `widgets/charts/donut_chart_painter.dart` + `donut_chart.dart` (StatefulWidget, `SingleTickerProviderStateMixin`, `AnimationController` + `CurvedAnimation`, chạy lại khi dữ liệu đổi trong `didUpdateWidget`, hit-test chạm, legend).
- [x] `widgets/charts/weekly_bar_painter.dart` + `weekly_bar_chart.dart` (animation, chạm cột, chuyển tuần).
- [x] Tách phần hình học thành hàm thuần để test: `angleToSliceIndex`, `isPointInRing`, `barRects(values, size)`, `percentages(totals)`.
- [x] Test: unit test hình học (góc tại 12h/3h/6h/9h với `startAngle = -π/2`, điểm ngoài vòng khuyên, tổng % = 1, tất cả giá trị = 0); `shouldRepaint` đúng khi dữ liệu/progress/selection đổi; widget test chạm vào lát → hiện chi tiết; animation hoàn tất sau `pumpAndSettle`.
- [x] Gắn vào Dashboard; xác nhận biểu đồ tự cập nhật khi thêm giao dịch (widget test với provider override).

### Phase 10 — UI/UX polish
- [ ] Chuyển theme (sáng/tối/hệ thống); layout responsive ≥ 600dp; kiểm tra không overflow ở cả dọc và ngang bằng widget test với nhiều kích thước (`tester.view.physicalSize`); `Semantics` cho các nút icon; empty/loading/error states thống nhất; icon app và tên hiển thị "VKU Expense OCR".
- [ ] Rà soát `const`, `dispose`, và tính toán trong `build()` theo NFR-2/NFR-3; ghi kết quả rà soát vào PHASE_LOG.

### Phase 11 — Release & Deliverables
- [ ] **Ký APK**: cấu hình `android/app/build.gradle(.kts)` đọc `key.properties`. Nếu có `keytool`: tạo keystore tại `~/vku-keys/upload-keystore.jks` (ngoài repo) với mật khẩu ngẫu nhiên mạnh, ghi vào `android/key.properties` (đã gitignore). Thông báo rõ cho tôi đường dẫn file và yêu cầu **sao lưu**. Viết `docs/SIGNING.md` hướng dẫn tự tạo lại keystore.
- [ ] `flutter build apk --release` → xác minh chữ ký (`apksigner verify --print-certs` hoặc `keytool -printcert -jarfile`), ghi kích thước APK và đường dẫn output.
- [ ] `README.md` hoàn chỉnh: giới thiệu, tính năng (checklist FR), ảnh chụp (`docs/screenshots/`, để placeholder và hướng dẫn tôi chụp nếu không chụp được), kiến trúc (sơ đồ Mermaid pipeline + cấu trúc thư mục), công nghệ và phiên bản, yêu cầu môi trường, lệnh `flutter pub get` / `flutter run` / `flutter test` / `flutter build apk --release`, link tải APK (placeholder), hạn chế, tác giả (placeholder).
- [ ] `docs/REPORT.md`: bản nguồn của báo cáo PDF 2–4 trang theo đúng cấu trúc yêu cầu: (1) checklist tính năng, (2) sơ đồ kiến trúc, (3) bảng regex OCR, (4) ảnh sáng/tối, (5) kết quả đo OCR và độ chính xác parser, (6) hạn chế và hướng phát triển. Nếu có `pandoc` thì xuất thử `docs/REPORT.pdf`; nếu không thì hướng dẫn tôi cách xuất.
- [ ] `docs/DEMO_SCRIPT.md`: kịch bản quay video 2–3 phút theo từng cảnh, có mốc thời gian.
- [ ] `CHANGELOG.md` tổng hợp theo phase.
- [ ] Gate cuối: toàn bộ test pass, analyze 0, build release thành công. Merge, tag `v1.0.0`.

### Phase 12 — (Tùy chọn, chỉ khi Phase 0–11 đã hoàn tất) Platform Channel
- [ ] `MethodChannel('vn.edu.vku/device_info')` theo W8 s37–38: ví dụ rung haptic khi lưu thành công, hoặc đọc mức pin hiển thị cảnh báo trước khi quét. Có test bằng `TestDefaultBinaryMessengerBinding` mock handler. Ghi rõ đây là phần mở rộng.

---

## Checklist FR / NFR (đánh `[x]` chỉ khi có test hoặc bằng chứng)

> Danh sách mã lấy từ mục Requirements. Nội dung chi tiết xem ở mục FROZEN phía trên.

- [ ] FR-1.1 — code + test máy tính xong, CHƯA xác minh trên điện thoại thật: `CameraScreen` + `PluginReceiptCamera` (`CameraPreview`, `BoxFit.cover`); widget test với camera giả; smoke test emulator + webcam: preview chạy
- [ ] FR-1.2 — code + test máy tính xong, CHƯA xác minh trên điện thoại thật: vòng flash tắt/tự động/luôn bật/đèn pin, icon theo trạng thái, máy không có flash → vô hiệu nút (`camera_screen_test.dart`)
- [ ] FR-1.3 — code + test máy tính xong, CHƯA xác minh trên điện thoại thật: `FrameGeometry.viewportToNormalized` + `setFocusPoint`/`setExposurePoint` chỉ khi được hỗ trợ, vòng chỉ báo (`frame_geometry_test.dart`, `camera_screen_test.dart`)
- [ ] FR-1.4 — code + test máy tính xong, CHƯA xác minh trên điện thoại thật: `ReceiptFramePainter` (lớp tối có lỗ hình hóa đơn), `shouldRepaint` (`receipt_frame_overlay_test.dart`)
- [ ] FR-1.5 — code + test máy tính xong, CHƯA xác minh trên điện thoại thật: `FrameGeometry.frameToImageCrop` (1.200 tổ hợp trong ảnh) + `ImageCropService.cropToFrame` (EXIF 1/6/3/8) + `image_cropper`; smoke test emulator: cắt 418×672. `image_cropper` chưa được thử trên máy
- [ ] FR-1.6 — code + test máy tính xong, CHƯA xác minh trên điện thoại thật: nút thư viện ở màn camera và ở các màn lỗi → ảnh xoay đứng → chỉnh tay → OCR → Review (`camera_screen_test.dart`)
- [ ] FR-1.7 — code + test máy tính xong, CHƯA xác minh trên điện thoại thật: `CameraAccessDenied` → hướng dẫn + "Mở Cài đặt" (`permission_handler`) + thư viện, thử lại khi quay về app (`camera_service_test.dart`, `camera_screen_test.dart`)
- [x] FR-2.1 — bằng chứng: `MlKitOcrService` (`lib/services/ocr_service.dart`), `test/services/ocr_service_test.dart` (gửi script Latin + đường dẫn ảnh qua channel), chạy ML Kit bundled trên emulator với 22 ảnh (`docs/TEST_REPORT.md`); ảnh đã cắt sẽ có từ Phase 6
- [x] FR-2.2 — bằng chứng: `ocrLinesFrom` (`lib/services/ocr_service.dart`) chuyển `RecognizedText` → `OcrLine` (text, `Rect`, cornerPoints), `test/services/ocr_service_test.dart`; parser không import ML Kit (`test/services/parser_purity_test.dart`)
- [x] FR-2.3 — bằng chứng: `lib/services/row_grouper.dart`, `test/services/row_grouper_test.dart` (11 test: 2 block trái/phải, lệch dọc, bậc thang, ngưỡng cấu hình) + benchmark 23 fixture
- [x] FR-2.4 — bằng chứng: `Stopwatch` quanh `processImage` + log (`ocr_service_test.dart`); hiển thị ở màn Review trong "Xem văn bản OCR gốc" (`test/screens/review_screen_test.dart`); số đo emulator ở `docs/TEST_REPORT.md`. Chưa thử trên máy thật
- [x] FR-2.5 — bằng chứng: `MlKitOcrService.close()` đóng đúng recognizer (`ocr_service_test.dart`), `ocrServiceProvider` gọi `close()` khi dispose (`lib/state/ocr_providers.dart`)
- [x] FR-3.1 — bằng chứng: `TextNormalizer.normalize/ocrKey` dùng để so khớp, giá trị trả về giữ nguyên bản gốc (`test/core/text_normalizer_test.dart`, `text_normalizer_ocr_test.dart`, merchant test "keeps the original spelling")
- [x] FR-3.2 — bằng chứng: `ReceiptParser.extractTotal`, `test/services/receipt_parser_total_test.dart` (34 test: 9 định dạng, 8 từ khóa, ưu tiên, hàng thấp hơn, loại trừ, fallback, kết quả `int`); fixture total 23/23
- [x] FR-3.3 — bằng chứng: `ReceiptParser.extractDate`, `test/services/receipt_parser_date_test.dart` (20 test: 4 định dạng, có giờ, 45/13/2026, 31/04, 29/02, 20YY, null); fixture date 23/23
- [x] FR-3.4 — bằng chứng: `ReceiptParser.extractMerchant`, `test/services/receipt_parser_merchant_test.dart` (23 test: đủ từ khóa FR, 5 hàng đầu, tỷ lệ chữ số, null); fixture merchant 23/23
- [x] FR-3.5 — bằng chứng: `ReceiptParser.suggestCategory` (switch trên record, list pattern + `when`, switch exhaustive), `test/services/receipt_parser_category_test.dart` (28 test); fixture category 23/23
- [x] FR-3.6 — bằng chứng: `ReceiptParser.parse` → `ParsedReceipt` đủ trường + độ tin cậy từng trường (`test/services/receipt_parser_parse_test.dart`)
- [x] FR-3.7 — bằng chứng: `docs/REGEX_TABLE.md` (29 pattern, sinh từ mã nguồn bằng `tool/regex_table/`, ví dụ đã chạy thử)
- [x] FR-4.1 — bằng chứng: `ReceiptImageView` (ảnh đã cắt, chạm → `InteractiveViewer` toàn màn) (`test/screens/review_screen_test.dart`). Chưa thử trên máy thật
- [x] FR-4.2 — bằng chứng: `Form` + `GlobalKey<FormState>`, `TextFormField` tên/số tiền, `showDatePicker` (không quá hôm nay), 5 `ChoiceChip` danh mục (`test/screens/review_screen_test.dart`). Chưa thử trên máy thật
- [x] FR-4.3 — bằng chứng: `ExpenseValidators` (tên rỗng, số tiền ≤ 0 kể cả hóa đơn 0 đ, ngày tương lai, chưa chọn danh mục), thông báo tiếng Việt (`test/core/expense_validators_test.dart`, `test/screens/review_screen_test.dart`). Chưa thử trên máy thật
- [x] FR-4.4 — bằng chứng: icon + dòng chú thích cho từng trường low/missing (không chỉ màu); tên cửa hàng là banner nổi bật nhất ở đầu form + viền màu (`test/screens/review_screen_test.dart`). Chưa thử trên máy thật
- [x] FR-4.5 — bằng chứng: `OcrTextPanel` trong màn Review: văn bản OCR gốc + thời gian OCR (`test/screens/review_screen_test.dart`, `test/widgets/ocr_text_panel_test.dart`). Chưa thử trên máy thật
- [x] FR-4.6 — bằng chứng: `VndAmountInputFormatter`: chấm phân cách khi gõ, con trỏ đúng khi sửa giữa chuỗi, dán "150,000"/"150.000đ" → 150000 (`test/core/amount_input_test.dart`, `test/screens/review_screen_test.dart`). Chưa thử trên máy thật
- [x] FR-4.7 — bằng chứng: `FocusNode` + `TextInputAction.next` tên → số tiền; mọi controller/focus node được `dispose()`; cuộn được khi bàn phím mở ở màn nhỏ và màn ngang (`test/screens/review_screen_test.dart`). Chưa thử trên máy thật
- [x] FR-4.8 — bằng chứng: lưu → SnackBar → quay về; `PopScope` hỏi "Bỏ thay đổi?" khi đã sửa, cả nút back AppBar lẫn back Android (`test/screens/review_screen_test.dart`). Chưa thử trên máy thật
- [x] FR-4.9 — bằng chứng: ba chế độ: từ kết quả quét, thêm thủ công không ảnh, sửa `/expense/:id` gọi `edit` (`test/screens/review_screen_test.dart`). Chưa thử trên máy thật
- [x] FR-5.1 — bằng chứng: `DatabaseService` (`lib/services/database_service.dart`), `test/services/database_service_test.dart` (kiểu cột, NOT NULL, AUTOINCREMENT, version 1, `onUpgrade` từ v1 giữ nguyên dữ liệu, thiếu bước migration thì rollback)
- [x] FR-5.2 — bằng chứng: `ExpenseRepository` + `SqfliteExpenseRepository` (`lib/services/expense_repository.dart`), `test/services/sqflite_expense_repository_test.dart` (22 test: CRUD, thứ tự, biên đầu/cuối ngày, tổng theo danh mục)
- [x] FR-5.3 — bằng chứng: `ImageStorageService.save` copy vào `<documents>/receipts/`, thumbnail JPEG 256px trong `Isolate.run` (`test/services/image_storage_service_test.dart`); trên Android thật: `integration_test/storage_test.dart` (chưa chạy, xem Việc còn nợ)
- [ ] FR-5.4 — một phần (logic xong): `ExpenseListNotifier.remove/restore/commitDeletion` giữ ảnh trong `undoWindow` 5 s rồi mới xóa, restore giữ nguyên id (`test/state/expense_list_notifier_test.dart`, `fakeAsync`); dọn ảnh mồ côi khi khởi động (`app_startup_test.dart`); xóa file đã mất không crash (Phase 4). Còn SnackBar Undo → Phase 8
- [x] FR-5.5 — bằng chứng: `lib/models/expense_category.dart` (switch expression), `test/models/expense_category_test.dart` (đủ 5 nhánh label/icon/màu, round-trip DB)
- [x] FR-6.1 — bằng chứng: `DonutChartPainter` (`drawArc` stroke, quét 0 → 1, tổng ở giữa bằng `TextPainter`, rút gọn khi dài), `DonutChart` (`AnimationController` + `CurvedAnimation`, legend màu/tên/số tiền/%) (`test/widgets/charts/chart_widgets_test.dart`, `chart_painters_test.dart`). Chưa thử trên máy thật (độ mượt animation, độ chính xác khi chạm)
- [x] FR-6.2 — bằng chứng: chạm lát → dày hơn + chi tiết, chạm lại/lỗ giữa/ngoài → bỏ chọn; hit-test `atan2` + vòng khuyên (`chart_geometry_test.dart`, `test/widgets/charts/chart_widgets_test.dart`). Chưa thử trên máy thật (độ mượt animation, độ chính xác khi chạm)
- [x] FR-6.3 — bằng chứng: `WeeklyBarPainter` (7 cột `drawRRect`, nhãn ngày + giá trị bằng `TextPainter`, cột mọc lên), `WeeklyBarChart` (tuần trước/sau, khoảng ngày, chạm cột → số tiền, hôm nay nổi bật) (`test/widgets/charts/chart_widgets_test.dart`, `chart_painters_test.dart`). Chưa thử trên máy thật (độ mượt animation, độ chính xác khi chạm)
- [x] FR-6.4 — bằng chứng: `shouldRepaint` của cả hai painter so sánh dữ liệu, màu, progress, phần tử đang chọn (và hôm nay); mỗi tiêu chí một test (`test/widgets/charts/chart_painters_test.dart`). Chưa thử trên máy thật (độ mượt animation, độ chính xác khi chạm)
- [x] FR-6.5 — bằng chứng: thêm/sửa/xóa giao dịch → donut và cột tuần cập nhật, animation chạy lại (`test/screens/dashboard_screen_test.dart`, `test/widgets/charts/chart_widgets_test.dart`). Chưa thử trên máy thật (độ mượt animation, độ chính xác khi chạm)
- [x] FR-6.6 — bằng chứng: tháng không có chi tiêu → thông điệp thay cho donut; tuần không có chi tiêu → thông điệp, vẫn chuyển tuần được (`test/widgets/charts/chart_widgets_test.dart`). Chưa thử trên máy thật (độ mượt animation, độ chính xác khi chạm)
- [x] FR-7.1 — bằng chứng: `StatefulShellRoute.indexedStack` + `NavigationBar` M3 3 tab (`test/app_router_test.dart`); Tổng quan có tổng tháng, donut, cột tuần (`test/screens/dashboard_screen_test.dart`); Quét = camera (Phase 6); Lịch sử = danh sách (Phase 8). Chưa thử trên máy thật
- [x] FR-7.2 — bằng chứng: `lib/core/router.dart` (`/expense/:id`, `/review` + `extra`), `test/app_router_test.dart` (path param, extra, id sai → trang lỗi)
- [x] FR-7.3 — bằng chứng: `HistoryScreen` (`ListView.builder`, `ExpenseSummaryCard` theo lab Week 7 có thumbnail, `Dismissible` + `ValueKey(id)`, lọc theo danh mục) (`test/screens/history_screen_test.dart`, `test/widgets/expense_summary_card_test.dart`). Chưa thử trên máy thật
- [ ] FR-8.1 — một phần: `AppTheme` M3 light/dark từ seed `0xFF2C4570` (`test/core/app_theme_test.dart`); `themeModeProvider` lưu/đọc lại qua `shared_preferences`, `MaterialApp.themeMode` theo nó (`test/state/theme_mode_provider_test.dart`, `test/app_theme_mode_test.dart`); nút chuyển → Phase 10
- [ ] FR-8.2 — một phần: Dashboard đặt donut và cột tuần cạnh nhau khi ≥ 600 dp, không overflow ở 320 dp và màn ngang với chữ 1,5× (`dashboard_screen_test.dart`); Review, camera, Lịch sử có test màn nhỏ/ngang ở Phase 6–8. Rà soát toàn app → Phase 10
- [ ] FR-8.3 — một phần: `Formatters.vnd` / `Formatters.date` (`test/core/formatters_test.dart`), `SafeArea` ở các màn hiện có; áp dụng toàn app → Phase 7–10
- [ ] FR-8.4 — một phần: provider dẫn xuất trả `AsyncValue` (loading/error lan từ danh sách, có test); hiển thị bằng `AsyncValue.when` ở các màn → Phase 7–10
- [ ] NFR-1 — bằng chứng: _chưa có_
- [ ] NFR-2 — bằng chứng: _chưa có_
- [ ] NFR-3 — bằng chứng: _chưa có_
- [x] NFR-4 — bằng chứng: `lib/core`, `lib/models`, `lib/services`, `lib/state`, `lib/widgets`, `lib/screens` (Phase 1)
- [ ] NFR-5 — bằng chứng: _chưa có_
- [ ] NFR-6 — bằng chứng: _chưa có_

---

## Progress Log

| Phase | Trạng thái | Commit cuối | Kết quả test | Ghi chú |
|---|---|---|---|---|
| 0 — Khởi tạo & môi trường | ✅ Xong | tag `phase-0` | format ✔ · analyze 0 issue · test 1/1 · build debug ✔ | B-001 đã giải quyết (cài Flutter 3.47.6). Chưa test trên thiết bị (chưa cắm máy) |
| 1 — Nền tảng | ✅ Xong | tag `phase-1` | format ✔ · analyze 0 · test 48/48 · coverage 85.3% · build debug ✔ | Chưa test trên thiết bị (chưa cắm máy) |
| 2 — ReceiptParser | ✅ Xong | tag `phase-2` | format ✔ · analyze 0 · test 201/201 · coverage 94.9% · build debug ✔ · fixture 23/23 mọi trường | Chưa test trên thiết bị; fixture là dữ liệu tổng hợp (xem PHASE_LOG) |
| 3 — Dịch vụ OCR | ✅ Xong | tag `phase-3` | format ✔ · analyze 0 · test 272/272 · coverage 95.6% · build debug ✔ · fixture 31/31 · hóa đơn thật (emulator, main 19): merchant 7→7 · total 10→16 · date 14→15 · category đúng 10→11 | Đánh giá trên emulator `vku_test_api33`; **chưa đánh giá trên điện thoại thật (NFR-6 còn nợ)**. Màn debug tạm xóa ở Phase 7 |
| 4 — CSDL & lưu ảnh | ✅ Xong | tag `phase-4` | format ✔ · analyze 0 · test 321/321 · coverage 95.5% · build debug ✔ | Test DB bằng `sqflite_common_ffi`, ảnh bằng thư mục tạm; **chưa chạy trên thiết bị** (không bật emulator theo yêu cầu, `integration_test/storage_test.dart` chờ máy) |
| 5 — State management | ✅ Xong | tag `phase-5` | format ✔ · analyze 0 · test 383/383 · coverage 95.0% · build debug ✔ | Test bằng `ProviderContainer` + repository/storage giả, `fakeAsync` cho Undo; **chưa chạy trên thiết bị** (không bật emulator theo yêu cầu) |
| 6 — Camera capture | ✅ Xong (FR-1: code + test máy tính xong, CHƯA xác minh trên điện thoại thật) | tag `phase-6` | format ✔ · analyze 0 · test 438/438 · coverage 91.5% · build debug ✔ · smoke test **emulator + webcam** 1 lần pass (preview → chụp → cắt → OCR → /review) | `image_cropper`, flash, lấy nét, quyền, vòng đời chưa thử trên máy thật; xem checklist trong Việc còn nợ |
| 7 — Review & Verification | ✅ Xong | tag `phase-7` | format ✔ · analyze 0 · test 489/489 · coverage 92.8% · build debug ✔ | Widget test trên máy tính; **chưa thử trên thiết bị** (không bật emulator theo yêu cầu). Màn debug OCR Phase 3 đã gỡ |
| 8 — Lịch sử & Dashboard | ✅ Xong | tag `phase-8` | format ✔ · analyze 0 · test 514/514 · coverage 93.1% · build debug ✔ | Widget test trên máy tính; `integration_test/app_flow_test.dart` đã viết, **chưa chạy** (chưa có thiết bị). Chưa thử trên máy thật |
| 9 — Biểu đồ CustomPainter | ✅ Xong | tag `phase-9` | format ✔ · analyze 0 · test 582/582 · coverage 94.2% · build debug ✔ | Không dùng thư viện chart (có test kiến trúc). Chưa thử trên máy thật |
| 10 — UI/UX polish | ⬜ Chưa bắt đầu | — | — | |
| 11 — Release & Deliverables | ⬜ Chưa bắt đầu | — | — | |
| 12 — Platform Channel (tùy chọn) | ⬜ Chưa bắt đầu | — | — | |

Chú thích: ⬜ chưa bắt đầu · 🟨 đang làm · 🟥 bị chặn · ✅ xong (gate xanh, đã merge, đã tag).

---

## Việc còn nợ

> Những việc đã biết nhưng chưa làm được trong môi trường hiện tại. Gạch khi xong.

- [ ] **NFR-6 / Phase 3:** chạy `tool/ocr_eval/run_ocr_eval.ps1 -DeviceId <serial>` trên **điện thoại Android thật** (mới có số đo emulator), ghi thời gian OCR thật vào `docs/TEST_REPORT.md`.
- [ ] Khi có điện thoại thật, đánh giá thêm một bộ hóa đơn MỚI (holdout), gán nhãn và khóa hash trước, chạy đúng một lần, không sửa parser trước lần chạy đó. *(Yêu cầu của bạn ở Phase 4.)*
- [ ] **Phase 4:** chạy `flutter test integration_test/storage_test.dart -d <máy>` (sqflite thật + `path_provider` trên Android).
- [ ] **Phase 5:** `flutter run` trên Android để xác nhận `main()` mở DB + `shared_preferences` và dọn ảnh mồ côi khi khởi động không lỗi (mới kiểm chứng bằng `sqflite_common_ffi` trên Windows).
- [ ] **Phase 6 — camera trên điện thoại thật** (FR-1 chưa được đánh `[x]` cho tới khi xong mục này):
  - [ ] Preview đúng tỷ lệ (vật tròn không méo), lấp đầy vùng xem.
  - [ ] Flash: icon đổi tắt → tự động → luôn bật → đèn pin, đèn sáng/nháy thật.
  - [ ] Chạm lấy nét: vòng chỉ báo đúng chỗ chạm, ảnh nét lại.
  - [ ] Ảnh sau khi cắt không bị xoay (cầm máy dọc và ngang).
  - [ ] Vùng cắt khớp với khung căn chỉnh đã thấy, không mất chữ ở mép.
  - [ ] `image_cropper` mở được, "Hủy" quay về camera, xác nhận thì sang Review.
  - [ ] Từ chối quyền → hướng dẫn + "Mở Cài đặt" → cấp lại quyền → quay về, camera tự chạy.
  - [ ] Chuyển app rồi quay lại (và đổi tab rồi quay lại): camera vẫn chạy, không màn đen, không crash.
  - [ ] Chạy `flutter test integration_test/camera_smoke_test.dart -d <máy>` với một hóa đơn thật trước camera.
- [ ] **Phase 7 — màn Review trên điện thoại thật:** bàn phím số cho ô số tiền và nút Next chuyển ô; form cuộn được khi bàn phím mở; bộ chọn ngày hiện tiếng Việt và không cho chọn ngày tương lai; phóng to ảnh hóa đơn; lưu thật (ảnh + thumbnail vào `receipts/`, DB); nút back Android hỏi trước khi bỏ thay đổi.
- [ ] **Phase 8:** chạy `flutter test integration_test/app_flow_test.dart -d <máy>` (thêm thủ công → Lịch sử → tổng Dashboard → vuốt xóa → Undo) khi có thiết bị.
- [ ] **Phase 9 — biểu đồ trên điện thoại thật:** animation donut và cột mượt (không giật khi mở tab, khi thêm/xóa giao dịch); chạm đúng lát/cột trên màn thật (cả lát nhỏ, gần ranh giới); chữ ở lỗ giữa không tràn với số tiền lớn và chữ hệ thống phóng to; TalkBack đọc mô tả biểu đồ.
- [ ] Checklist test thủ công trên thiết bị của Phase 0–9 trong `docs/TEST_REPORT.md`.

---

## Decisions Log

| # | Quyết định | Lý do |
|---|---|---|
| D-001 | CSDL cục bộ dùng `sqflite` (không dùng `isar`) | Brief mục 3.3 chốt `sqflite` vì slide và rubric dùng gói này; test được bằng `sqflite_common_ffi` trên máy dev. |
| D-002 | `flutter_riverpod` giữ major **2.x** (không lên 3.x) | Rubric ghi "Riverpod 2" (brief mục 3.3 và mục 5.8). |
| D-003 | Repo git riêng tại thư mục dự án (`git init -b main`) | Ổ `D:\` có sẵn một repo git ở gốc (thuộc Administrators, bị git báo *dubious ownership*). Repo lồng bên trong giúp lịch sử dự án độc lập, không dính repo ở `D:\`. |
| D-004 | Thêm `.gitattributes` (`* text=auto eol=lf`, `*.bat`/`*.cmd` giữ CRLF) | Git for Windows đang bật `core.autocrlf=true` ở cấp hệ thống. Ép LF giúp `dart format --set-exit-if-changed` ổn định và diff trên GitHub sạch. |
| D-005 | Tạo project với `--platforms android,ios` (không có thư mục windows/linux/macos) | Brief mục 7 Phase 0. Phụ: Flutter chỉ cần symlink (Developer Mode của Windows) khi project có nền tảng desktop; máy này **chưa bật Developer Mode** nên không thêm nền tảng desktop. |
| D-006 | Gradle dùng JDK **Temurin 21** (`flutter config --jdk-dir`) | `java` trên PATH là 1.8 (quá cũ cho AGP 9); JBR của Android Studio là Java 25. Template Flutter 3.47 dùng AGP 9.1 + Gradle 9.3.1; JDK 21 (LTS) là lựa chọn ổn định. Không đổi `java` 1.8 trên PATH hệ thống. |
| D-007 | Flutter **3.47.6** stable (Dart **3.13.5**), clone đầy đủ (không `--depth`) vào `D:\flutter` | Đúng major 3.x theo brief nên giữ nhánh `stable`, không checkout tag khác. Clone đầy đủ để `flutter upgrade`/checkout tag hoạt động. |
| D-008 | `GRADLE_USER_HOME=D:\dev-cache\gradle`, `PUB_CACHE=D:\dev-cache\pub` (biến cấp User) | Ổ C: chỉ còn ~9.5 GB; cache Gradle/pub có thể lên nhiều GB. Đặt trước lần chạy `flutter` đầu tiên. |
| D-009 | Cài NDK 28.2.13676358 thủ công bằng `android.exe ... sdk install ndk/28.2.13676358` | AGP tự cài NDK thất bại vì `sdkmanager.bat` (shim của Android CLI 2026) để `cmd` tách tên gói tại dấu `;`. Gọi trực tiếp Android CLI với tên gói dạng `/`. Chi tiết: `docs/SETUP_ENV.md` mục 8.1. |
| D-010 | `org.gradle.jvmargs=-Xmx3G ...`, `kotlin.daemon.jvmargs=-Xmx1G` | Template mặc định `-Xmx8G` = toàn bộ RAM máy (8 GB) → Windows phình `pagefile.sys` trên ổ C:. Build vẫn thành công với 3 GB. |
| D-011 | Lint: bật `strict-casts`, `strict-inference`, `strict-raw-types` + rule bổ sung; **bỏ** `unnecessary_await_in_return` | Rule này đã bị deprecate trong Dart 3.13 (`flutter analyze` báo `deprecated_lint`). Không dùng `// ignore`. |
| D-012 | Phiên bản gói thực tế (Phase 1, `flutter pub add`): flutter_riverpod **2.6.1**, go_router 18.0.2, intl 0.20.3, sqflite 2.4.4+1, path 1.9.1, path_provider 2.1.6, google_mlkit_text_recognition 0.17.1 (commons 0.13.0), camera 0.12.1 (camera_android_camerax 0.7.5+1), image_picker 1.2.4, image_cropper 12.2.1, image 4.10.1; dev: sqflite_common_ffi 2.4.3, mocktail 1.0.5, integration_test (sdk) | Brief mục 5.8. `flutter_riverpod` có bản 3.4.3 nhưng giữ 2.x (D-002). Lưu ý: `^` bị `cmd` nuốt khi gọi `flutter pub add` từ Git Bash nên ràng buộc riverpod được sửa tay thành `^2.6.1`. |
| D-013 | ML Kit dùng model **bundled** (`com.google.mlkit:text-recognition:16.0.1`), chỉ script Latin | Đã kiểm tra `android/build.gradle` của plugin: model đóng gói trong APK, không tải qua Google Play Services → chạy offline ngay lần đầu (NFR-1). Không thêm gói Chinese/Japanese/Korean/Devanagari để APK nhỏ. |
| D-014 | `minSdk = 24` cố định; gỡ quyền `RECORD_AUDIO` bằng `tools:node="remove"`; khai báo `UCropActivity` | camera_android_camerax cần 23, ML Kit cần 21, Flutter 3.47 mặc định 24. App chỉ chụp ảnh tĩnh (`enableAudio: false`) nên không xin quyền micro. `UCropActivity` theo README image_cropper 12.2.1. |
| D-015 | Thêm `flutter_localizations`, `locale: vi_VN` | `showDatePicker` (FR-4.2) và chuỗi Material (OK/Hủy…) hiển thị tiếng Việt; `initializeDateFormatting('vi_VN')` trước `runApp`. |
| D-016 | Router: `StatefulShellRoute.indexedStack` tạo trong `routerProvider` (Riverpod) | Mỗi tab giữ stack riêng; router không bị tạo lại trong `build()` (W7 s30); test override được router. |
| D-017 | `ExpenseCategory` lưu DB bằng `name` (`food`, `study`…); giá trị lạ → `FormatException` | Ổn định khi đổi nhãn tiếng Việt; dữ liệu hỏng không bị gán nhầm danh mục. |
| D-018 | `Formatters.vnd` giữ khoảng trắng **không ngắt** (U+00A0) giữa số và `đ` | Là dữ liệu chuẩn của locale vi_VN; tránh xuống dòng tách `đ`. Test so sánh chính xác `'150.000\u00A0đ'`. |
| D-019 | `copyWith` dùng `ValueGetter<String?>?` cho trường nullable | Phân biệt "không đổi" (bỏ qua tham số) với "xóa về null" (`() => null`), cần khi xóa ảnh hóa đơn. |
| D-020 | Parser + row grouper là **Dart thuần**: `ExpenseCategory` bỏ icon/màu (chuyển sang extension `ExpenseCategoryStyle` ở `lib/core/category_style.dart`), `@immutable` lấy từ gói `meta` thay cho `flutter/foundation` | Yêu cầu Phase 2 của bạn (không import Flutter UI/ML Kit). `test/services/parser_purity_test.dart` dò toàn bộ chuỗi import để giữ ràng buộc này. `dart:ui` chỉ được phép trong row grouper vì FR-2.2 bắt buộc `Rect`. |
| D-021 | `ReceiptParser` nhận `List<String>` (mỗi phần tử là một hàng đã ghép), không nhận `OcrLine` | Tách hình học (RowGrouper) khỏi xử lý chữ; test parser viết bằng chuỗi thuần, dễ đọc. |
| D-022 | Fixture dạng `.txt` + ` \| ` phân cách block; bounding box **tổng hợp** do `test/support/receipt_fixture.dart` sinh (trả theo cột như ML Kit, jitter ±4 px, `# skew:`) | Viết tay 23 hóa đơn × ~15 dòng tọa độ là không khả thi; cách này vẫn buộc dữ liệu đi qua row grouper. Hạn chế: hình học đều đặn hơn ảnh thật. |
| D-023 | Kỳ vọng tên cửa hàng là **danh sách các dòng cùng nêu tên cửa hàng** (ví dụ "HIGHLANDS COFFEE" hoặc "Highlands Coffee Vincom Huế"), so sánh sau khi bỏ dấu/chữ hoa | Quyết định trước khi chạy parser: cả dòng thương hiệu lẫn dòng chi nhánh đều là câu trả lời đúng với người dùng; slogan, địa chỉ, pháp nhân thì không. |
| D-024 | Sổ `known_limitations.dart` + benchmark so khớp **chính xác** tập trường sai với sổ | Cho phép ghi nhận hạn chế mà không `skip` test hay nới assertion: sửa được thì test báo phải gỡ khỏi sổ, sai thêm thì test fail. Hiện sổ rỗng. |
| D-025 | Phân loại hàng theo **từ khóa xuất hiện sớm nhất**, cùng vị trí thì từ khóa dài hơn thắng | "Tổng chiết khấu", "Tổng đài", "Tổng số lượng" bắt đầu bằng "tổng" nhưng không phải tổng tiền; "Tổng tiền (gồm VAT)" vẫn là tổng. |
| D-026 | `ocrKey` gộp ký tự OCR (0→o, 1/l/\|→i) và `repairDigits` sửa O/l trong số | Chịu được "Tong tlen", "T0NG", "139.5OO", "2O26" mà không cần so khớp mờ (edit distance). |
| D-027 | Loại slogan năm thành lập ("since", "est.", "thành lập", "từ năm") khỏi ứng viên tên cửa hàng | Sửa lỗi benchmark phát hiện ở `bookworm_english.txt` mà không đổi tiêu chí "nhiều chữ cái nhất" của FR-3.4 (chỉ thêm loại trừ). |
| D-028 | Từ điển danh mục tránh từ trùng nghĩa khi bỏ dấu (trả/trà, sửa/sữa, kèm/kem, lầu/lẩu, phố/phở, sạch/sách) | Bỏ dấu làm nhiều từ khác nghĩa trùng nhau; dùng cụm cụ thể ("trà sữa", "sữa tươi") thay cho từ đơn. |
| D-029 | `docs/REGEX_TABLE.md` sinh bằng script Python `tool/regex_table/` | Regex trích nguyên văn từ code và ví dụ được chạy thử, nên bảng trong báo cáo luôn khớp với code. Python có sẵn trên máy; không ảnh hưởng app. |
| D-030 | Schema = version 1 cố định + `schemaMigrations` (mỗi version một danh sách SQL); cài mới chạy v1 rồi mọi bước, nâng cấp chỉ chạy bước còn thiếu; thiếu bước thì `StateError` | Hai đường (cài mới / nâng cấp) luôn ra cùng schema; không bao giờ `DROP TABLE` khi nâng cấp. sqflite chạy `onCreate`/`onUpgrade` trong transaction nên lỗi giữa chừng được rollback (có test). |
| D-031 | `getBetween`/`totalsByCategory` dùng khoảng nửa mở `[0h ngày đầu, 0h ngày sau ngày cuối)` | Bao trọn 23:59:59.999 mà không phải chọn "mili giây cuối"; `DateTime(y, m, d + 1)` tự xử lý cuối tháng/năm. |
| D-032 | `ExpenseRepository.delete` chỉ xóa dòng và trả về bản ghi; file ảnh xóa riêng bằng `ImageStorageService.deleteFilesOf` | Undo (FR-5.4) cần ảnh còn nguyên trong lúc SnackBar hiển thị; Phase 5 xóa file khi việc xóa đã chắc chắn (hết thời gian Undo). |
| D-033 | `ImageStorageService.delete` bỏ qua `null`, file đã mất, và **từ chối** đường dẫn nằm ngoài `receipts/` | Xóa giao dịch không bao giờ crash vì ảnh mất; một đường dẫn lạc (ví dụ ảnh gốc trong thư viện) không thể bị xóa nhầm. |
| D-034 | Thumbnail: `bakeOrientation` → `copyResize(width: 256, Interpolation.average)` → JPEG quality 85, không phóng to ảnh nhỏ; bắt mọi lỗi giải mã (`on Object`) thành `ImageStorageException` | Ảnh điện thoại thường xoay bằng EXIF; bộ giải mã của gói `image` ném `RangeError` (là `Error`) với ảnh hỏng, có test cho trường hợp này. |
| D-035 | DB lưu **đường dẫn tuyệt đối** của ảnh | Đúng FR-5.3 ("DB chỉ lưu đường dẫn"); ổn định trên Android. Hạn chế đã biết: trên iOS thư mục container có thể đổi sau khi cập nhật app (dự án chỉ nộp APK Android). |
| D-036 | Lưu chế độ giao diện bằng `shared_preferences` 2.5.6 (qua interface `SettingsStore`), **không** thêm bảng `settings` bằng migration version 2 | Đây là một cặp khóa–giá trị, đúng mục đích của `shared_preferences`; giữ schema DB đúng FR-5.1 và không phải nâng version chỉ vì một cài đặt. Đọc một lần trong `main()` (có cache), nên khung hình đầu đã đúng sáng/tối, không bị nháy. Interface cho phép test bằng kho trong bộ nhớ. |
| D-037 | `restore` chèn lại **đúng bản ghi cũ, giữ nguyên id**; không có nhánh dự phòng đổi id | `AUTOINCREMENT` không bao giờ cấp lại id của dòng đã xóa (có test ở Phase 4), nên chèn lại id cũ luôn được. Giữ id giúp `ValueKey(id)` ở danh sách ổn định khi Undo. |
| D-038 | DB và `SharedPreferences` mở trong `main()` (`createStartupOverrides`) rồi đưa vào `ProviderScope` bằng override; dọn ảnh mồ côi chạy **trước** `runApp` | Mọi provider phía sau là đồng bộ (không phải `FutureProvider` lồng nhau). Dọn rác trước `runApp` thì không thể xóa nhầm ảnh đang lưu dở (chưa có thao tác nào của người dùng). |
| D-039 | `remove` cập nhật state **đồng bộ** trước khi gọi DB; DB lỗi thì tải lại danh sách và ném lại lỗi | `Dismissible` (Phase 8) yêu cầu item rời cây ngay khung hình sau khi vuốt, nếu không Flutter báo lỗi "dismissed Dismissible widget is still part of the tree". |
| D-040 | Phương thức sửa tên là `edit`, không phải `update` | `AsyncNotifier` đã có `update(...)` với chữ ký khác; đặt trùng là lỗi biên dịch. |
| D-041 | Thêm `selectedMonthProvider`; `categoryTotalsProvider` và `monthTotalProvider` tính theo tháng đang chọn | Dashboard (FR-7.1) hiển thị "tổng tháng" và donut; cần một khoảng thời gian rõ ràng cho donut. Mặc định là tháng hiện tại, có `previous/next` để sau này xem tháng trước. |
| D-042 | `undoWindow` = 5 s; Undo thất bại (DB lỗi) thì đặt lại hẹn giờ đủ 5 s | SnackBar ở Phase 8 dùng cùng hằng số. Đặt lại đủ 5 s chỉ làm file tồn tại lâu hơn một chút, không bao giờ xóa sớm. |
| D-043 | Tổng theo danh mục / tuần / tháng tính bằng Dart từ `expenseListProvider`, không gọi `totalsByCategory` của SQL | Một nguồn dữ liệu duy nhất nên biểu đồ tự cập nhật sau mọi thao tác (FR-6.5); dữ liệu cá nhân nhỏ (vài trăm dòng) nên tính trong Dart rất nhanh. `totalsByCategory` của repository vẫn giữ và có test. |
| D-044 | `permission_handler` ghim **12.0.3** (không dùng 13.x), chỉ dùng `openAppSettings()` | 13.0.2 kéo theo `permission_handler_android` 14.1.0 đòi compileSdk 37; app biên dịch với 36 (platform cao nhất đã cài, cũng là mức AGP 9.1 khuyến nghị). Quyền camera vẫn do plugin `camera` tự xin. |
| D-045 | Máy không có flash được phát hiện ở **lần đổi flash đầu tiên bị từ chối** → vô hiệu nút + thông báo | Plugin `camera` 0.12 không có API cho biết máy có đèn flash hay không. |
| D-046 | Quy đổi khung → ảnh: viewport → preview (`cover`) → ảnh (`cover`), padding 3% mỗi phía, kẹp trong ảnh, làm tròn ra ngoài | Giả định ảnh chụp và preview là hai vùng cắt giữa của cùng khung nhìn (CameraX dùng một resolution preset cho cả hai). Padding bù sai lệch nhỏ, vì `image_cropper` chỉ cho thu nhỏ vùng cắt, không mở rộng lại được. Cần kiểm chứng trên điện thoại. |
| D-047 | Bộ giải mã JPEG của gói `image` 4.10.1 **tự xoay theo EXIF** khi giải mã (`_jpeg_quantize_io.dart`); vẫn gọi `bakeOrientation` sau đó | Ảnh luôn đứng trước khi cắt (4 test EXIF thật). `bakeOrientation` là lớp an toàn cho định dạng khác. Test thuần ban đầu kỳ vọng sai hành vi thư viện nên được sửa; ca PNG bỏ vì bộ mã hóa PNG không ghi EXIF. |
| D-048 | Camera chỉ được giữ khi đang hiển thị: trả khi app `inactive/paused/hidden` (trừ lúc đang khởi tạo, vì hộp thoại xin quyền cũng làm app `inactive`), khi tab bị ẩn (`TickerMode` do `StatefulShellRoute` tắt), và trong lúc cắt/OCR/Review | Tiết kiệm pin và RAM (OCR cần bộ nhớ); `IndexedStack` giữ tab Quét sống nên nếu không thì camera chạy cả khi đang ở tab khác. Không trả camera khi đang khởi tạo để tránh vòng lặp xin quyền. |
| D-049 | Luồng chụp: tự cắt theo khung → `image_cropper` để chỉnh tay → OCR → Review. "Hủy" ở màn chỉnh = hủy quét. Ảnh thư viện: xoay đứng → chỉnh tay. OCR thất bại → hộp thoại "Nhập tay" mở Review kèm ảnh. `ResolutionPreset.veryHigh` | `image_cropper` không nhận vùng cắt khởi tạo, nên tự cắt trước rồi cho chỉnh. Ảnh thư viện không chụp qua khung nên không tự cắt. Độ phân giải cao giúp đọc chữ nhỏ. |
| D-050 | Smoke test camera: AVD `hw.camera.back=webcam0`; trong `integration_test/camera_smoke_test.dart`, bước `image_cropper` được thay bằng bước cho ảnh đi thẳng qua (chỉ trong test) | Activity native của uCrop không bấm được từ Flutter test. Việc `image_cropper` mở được nằm trong checklist điện thoại, không được coi là đã test. |
| D-051 | Form Review dùng `SingleChildScrollView` + `Column`, không dùng `ListView` | `ListView` dựng trường theo kiểu lười: trường chưa cuộn tới chưa được dựng, và `Form.validate()` bỏ qua nó. Test phát hiện điều này (nút Lưu và ô danh mục không tồn tại khi chưa cuộn). |
| D-052 | Dấu độ tin cậy = icon + chú thích (+ màu); tên cửa hàng dùng banner ở đầu form; dấu của một trường **mất đi khi người dùng sửa trường đó** | Không dựa vào màu (người mù màu, màn hình tối). Tên cửa hàng là trường yếu nhất ở Phase 3 (7/19). Người dùng đã sửa nghĩa là đã kiểm tra. |
| D-053 | Ô số tiền: chỉ giữ chữ số, tối đa 12 chữ số; con trỏ đặt sau cùng số chữ số như trước khi định dạng; xóa ngay sau dấu chấm thì xóa chữ số đứng trước; văn bản dán được đọc bằng `AmountInput.parse` (bỏ phần thập phân kiểu "150.000,00") | Đáp ứng FR-4.6 mà không để con trỏ nhảy. Hóa đơn 0 đ vẫn bị chặn ("số tiền > 0"), thông báo giải thích trường hợp giảm giá toàn bộ. |
| D-054 | Giao dịch mới lưu ngày đã chọn lúc 00:00; khi sửa mà **không đổi ngày** thì giữ nguyên giờ cũ | Biểu đồ và tổng chỉ cần ngày. Giữ giờ khi sửa để thứ tự trong Lịch sử không bị xáo trộn. |
| D-055 | Gỡ màn debug OCR (Phase 3) và route `/debug/ocr`; `OcrTextPanel` dùng lại trong Review, thời gian OCR có thể null | Brief yêu cầu không để code chết. Chế độ sửa không có thời gian OCR (DB không lưu), chỉ hiện số dòng. Test của màn debug bị xóa cùng màn; nội dung tương đương được test ở màn Review và màn camera. |
| D-056 | Hủy: `PopScope(canPop: !_dirty)` + hộp thoại "Bỏ thay đổi?"; chưa sửa gì thì quay về ngay | Giữ cử chỉ back dự đoán của Android khi form chưa sửa. FR-4.8 chỉ yêu cầu hỏi khi đã sửa. |
| D-057 | SnackBar Undo dùng `duration: ExpenseListNotifier.undoWindow` (một hằng số duy nhất) và gọi `holdForUndo(id)`; SnackBar đóng mà không bấm Undo → `commitDeletion` | Hẹn giờ của notifier bắt đầu lúc xóa, còn SnackBar chỉ bắt đầu đếm sau khi trượt vào (~250 ms). Nếu không giữ, ảnh có thể bị xóa trong khi nút "Hoàn tác" vẫn hiện. Hẹn giờ 5 s của notifier vẫn là lưới an toàn khi không có giao diện giữ. |
| D-058 | `SnackBar(persist: false)` | Trong Flutter 3.47, SnackBar có nút hành động mặc định `persist = true` (không tự đóng); khi đó lần xóa không bao giờ được chốt. Test "hết thời gian thì xóa hẳn" phát hiện điều này. |
| D-059 | Xóa liên tiếp: SnackBar mới thay SnackBar cũ, lần xóa trước được chốt ngay (kể cả ảnh); Undo chỉ áp dụng cho lần xóa mới nhất | Chỉ một SnackBar hiện được một lúc; giữ lần xóa cũ khi không còn nút Undo cho nó sẽ để lại ảnh không ai dọn. |
| D-060 | Chip lọc Lịch sử dùng `Wrap`, không cuộn ngang | Sáu chip trên màn 360 dp: cuộn ngang sẽ giấu các chip cuối (test chạm hụt cũng vì vậy). |
| D-061 | Dashboard không cho chuyển sang tháng tương lai; `integration_test/app_flow_test.dart` dùng file DB và thư mục ảnh riêng | Tháng tương lai không thể có chi tiêu. Test luồng chạy trên máy thật không được đụng dữ liệu của người dùng. |
| D-062 | Cột có giá trị 0 vẫn vẽ một "chân" cao 3 px trên đường đáy (`BarLayout.minHeight`); giá trị rất nhỏ cũng không thấp hơn mức đó; chạm theo cả chiều cao cột (`barIndexAt`) | Người dùng thấy đủ 7 ngày, ngày nào chưa chi; vẫn chạm được ngày 0 đ để xem "0 đ". |
| D-063 | Tỷ lệ cột theo **giá trị lớn nhất** của tuần (`barScaleMax`), không làm tròn lên số "đẹp" | FR-6.3: "chiều cao tỷ lệ với ngày cao nhất" (cột cao nhất chạm đỉnh). Tất cả 0 → thang 1, không chia cho 0. |
| D-064 | Hit-test donut dùng độ dày của lát **đang chọn** (×1,35) làm vùng chạm; ranh giới thuộc về lát bắt đầu tại đó; chạm lần nữa / lỗ giữa / ngoài → bỏ chọn | Chạm bằng ngón tay dễ hụt vòng mỏng; quy tắc ranh giới rõ ràng để test được. |
| D-065 | Animation: donut 900 ms, cột 700 ms, `Curves.easeOutCubic`; chỉ chạy lại khi dữ liệu **khác về giá trị** (`CategoryTotals`/`WeeklyTotals` so sánh bằng giá trị) | Không replay vô ích khi provider phát lại cùng số liệu; dữ liệu đổi giữa chừng thì chạy lại từ 0 (có test). |
| D-066 | Tổng ở lỗ giữa: dùng `Formatters.vnd`, quá 80% đường kính lỗ thì đổi sang `compactVnd` ("1,25tr đ"), vẫn quá thì thu nhỏ cỡ chữ | Số tiền lớn hoặc chữ hệ thống phóng to không được tràn ra khỏi lỗ. |
| D-067 | Legend: tên danh mục co lại có "…", cụm "số tiền + %" nằm trong `FittedBox(scaleDown)`; nhãn trong biểu đồ cột giới hạn hệ số chữ ở 1,3× | Test 320 dp với chữ 1,5× và số tiền 123 tỷ phát hiện legend tràn (RenderFlex overflow) ở bản đầu. |

---

## Blockers / Deviations

### B-001 — Chưa cài Flutter SDK (✅ đã giải quyết 2026-10-08)

- **Quyết định của bạn:** phương án 1, Claude Code tự cài với các điều kiện: clone đầy đủ, cache ra ổ D:, PATH User, JDK 21, không đụng repo `D:\`, ghi lại vào `docs/SETUP_ENV.md`.
- **Kết quả:** Flutter 3.47.6 / Dart 3.13.5 tại `D:\flutter`; `flutter doctor -v` → Android toolchain ✔ (SDK 36, JDK 21, all licenses accepted). Visual Studio thiếu → bỏ qua (chỉ build Android). Phát sinh thêm: NDK phải cài tay (D-009), giảm heap Gradle (D-010).
- **Lịch sử:** phần dưới giữ nguyên mô tả lúc mở blocker.

- **Mô tả:** `flutter` và `dart` không có trong PATH. Đã tìm `flutter.bat`/`dart.exe` trên ổ `C:` và `D:` (độ sâu 5–6 thư mục, gồm `C:\flutter`, `C:\src\flutter`, `D:\flutter`, `D:\src\flutter`, `~\flutter`, `~\development\flutter`): **không có**. Đây là BLOCKER loại "thiếu công cụ" (mục 2.3).
- **Đã kiểm tra được (2026-10-08):**
  - `git` 2.43.0 ✔ — `user.name`/`user.email` đã cấu hình global ✔
  - Android SDK `D:\Android\SDK` ✔ (platforms 24/33/34/35/36, build-tools 30.0.3 → 37.0.0, cmdline-tools `latest`, platform-tools). Thư mục `licenses/` mới có `android-sdk-license` → cần chạy `flutter doctor --android-licenses` sau khi cài Flutter.
  - JDK: `java` trên PATH = 1.8.0_202; `JAVA_HOME` = Temurin 21.0.6 ✔; JBR Android Studio = 25.0.3. `keytool` có sẵn (JDK 8 và 21) ✔
  - `adb devices`: **chưa có thiết bị** Android nào kết nối.
  - Dung lượng trống: `C:` 9.5 GB (ít), `D:` 48 GB → nên cài Flutter vào `D:`.
  - Windows Developer Mode: **tắt** (xem D-005, không chặn nếu chỉ build Android/iOS).
  - `pandoc`: chưa có (chỉ cần ở Phase 11 để xuất PDF, không chặn).
- **Phương án:**
  1. **(Đề xuất)** Cài Flutter stable bằng git vào `D:\flutter` (đường dẫn không có dấu cách), rồi thêm `D:\flutter\bin` vào PATH của user. Lệnh PowerShell:
     ```powershell
     git clone https://github.com/flutter/flutter.git -b stable D:\flutter
     [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", "User") + ";D:\flutter\bin", "User")
     # Mở terminal / VS Code mới để nhận PATH, sau đó:
     flutter config --android-sdk "D:\Android\SDK"
     flutter config --jdk-dir "C:\Program Files\Eclipse Adoptium\jdk-21.0.6.7-hotspot"
     flutter doctor --android-licenses   # gõ y để chấp nhận
     flutter doctor -v
     ```
  2. Tải file zip stable từ https://docs.flutter.dev/get-started/install/windows/mobile, giải nén vào `D:\flutter`, rồi làm tiếp như phương án 1 từ dòng `SetEnvironmentVariable`.
  3. Claude Code tự chạy phương án 1 (tải khoảng 1–2 GB vào `D:\flutter`, sửa biến PATH của user) nếu bạn đồng ý.
- **Trạng thái:** đã làm xong phần không cần Flutter của Phase 0 (git, `CLAUDE.md`, `docs/`, `.gitignore`, `.gitattributes`, README khung). Phần `flutter create`, lint và Quality Gate chờ B-001.
