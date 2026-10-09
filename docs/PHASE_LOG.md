# Nhật ký học tập theo Phase

> Viết cho sinh viên đọc lại để hiểu **đã làm gì, vì sao, và tự kiểm tra thế nào**.
> Mỗi phase một mục. Thuật ngữ kỹ thuật giữ tiếng Anh khi cần, kèm giải thích.

---

## Phase 0 — Khởi tạo & môi trường

**Trạng thái:** ✅ hoàn tất (merge vào `main`, tag `phase-0`).

### Mục tiêu phase

- Kiểm tra và cài công cụ: Flutter 3.x / Dart 3, Android SDK, JDK + `keytool`, git.
- Dựng khung project Flutter (`flutter create`), repo git, `.gitignore` an toàn (không lộ keystore, APK…).
- Tạo `CLAUDE.md`, "bộ não" của dự án: quy tắc, yêu cầu đóng băng (FROZEN), kế hoạch phase, nhật ký tiến độ, quyết định kỹ thuật, blocker.
- Bật lint chặt hơn để code sạch ngay từ đầu.
- FR liên quan: chưa có FR chức năng. Phase này đặt nền cho **NFR-5** (`flutter analyze` 0 issue, `dart format`) và **NFR-6** (build được APK Android).

### Đã làm gì

| File | Vai trò |
|---|---|
| `CLAUDE.md` | Quy tắc làm việc, Requirements FROZEN (sinh bằng script, chép đúng từng ký tự từ brief), bản đồ slide → code, lỗi slide, kế hoạch phase có checklist, checklist FR/NFR, Progress Log, Decisions Log, Blockers. |
| `docs/PROJECT_BRIEF.md` | Bản gốc của brief (đã `git mv` từ thư mục gốc vào `docs/`). |
| `docs/SETUP_ENV.md` | Từng bước cài Flutter trên máy này, kèm lý do và cách tự làm lại. |
| `.gitignore` | Mẫu chuẩn của Flutter + `*.jks`, `*.keystore`, `android/key.properties`, `*.apk`, `*.aab`, `.env`, `coverage/`. |
| `.gitattributes` | Ép xuống dòng kiểu LF cho mọi file văn bản (trừ `.bat`/`.cmd`). |
| `pubspec.yaml`, `lib/main.dart`, `test/widget_test.dart`, `android/`, `ios/` | Khung do `flutter create --org vn.edu.vku --project-name vku_expense_ocr --platforms android,ios .` sinh ra. |
| `analysis_options.yaml` | Lint chặt: `strict-casts`, `strict-inference`, `strict-raw-types` + các rule `prefer_const_constructors`, `prefer_final_locals`, `always_declare_return_types`, `avoid_print`, `use_build_context_synchronously`, `unawaited_futures`, `always_use_package_imports`… |
| `android/gradle.properties` | Giảm heap của Gradle từ 8 GB xuống 3 GB cho vừa máy 8 GB RAM. |
| `README.md`, `docs/TEST_REPORT.md` | Khung, sẽ hoàn thiện dần. |

### Vì sao làm vậy

- **Cài Flutter vào `D:\flutter`, cache ra `D:\dev-cache`:** ổ C: chỉ còn ~9.5 GB. Flutter SDK, cache pub và Gradle cộng lại vài GB. Biến `PUB_CACHE` và `GRADLE_USER_HOME` phải được đặt *trước* lần chạy `flutter` đầu tiên, nếu không cache đã kịp rơi vào C:. (Xem `docs/SETUP_ENV.md`.)
- **JDK 21 cho Gradle, không đụng `java` 1.8 trên PATH:** template Flutter 3.47 dùng AGP 9.1 + Gradle 9.3.1, cần JDK ≥ 17. `flutter config --jdk-dir` chỉ đổi JDK cho Flutter/Gradle, các phần mềm khác của bạn vẫn dùng Java 1.8 như cũ.
- **Repo git riêng trong thư mục dự án:** ổ `D:\` đã có một repo git ở gốc. Repo lồng có `.git` riêng nên git dùng repo gần nhất, lịch sử dự án không lẫn vào repo `D:\`.
- **`.gitattributes` với `eol=lf`:** Git for Windows mặc định `core.autocrlf=true`, nên file trên đĩa có thể là CRLF (`\r\n`) trong khi repo lưu LF (`\n`). File do `flutter create` sinh ra trên Windows đều là CRLF. Ép LF giúp `dart format --set-exit-if-changed` và diff trên GitHub ổn định.
- **Lint chặt từ đầu:** sửa cảnh báo khi code còn ít thì rẻ hơn nhiều so với cuối dự án. Các rule bám theo slide: `const` widget (W7 s15–16), không tính toán nặng / không dùng `context` sai sau `await` (W7 s26–30), `final` cho biến cục bộ.
- **Giảm heap Gradle:** template đặt `-Xmx8G` đúng bằng toàn bộ RAM máy. Lúc build, Windows phải đẩy RAM ra `C:\pagefile.sys` (phình lên 7.8 GB) khiến ổ C: hụt 1.8 GB. 3 GB vẫn đủ để build.
- **Cài NDK bằng tay:** Gradle tự cài NDK thất bại do lỗi của `sdkmanager.bat` bản mới (tách tên gói tại dấu `;`). Gọi thẳng Android CLI thì cài được. Chi tiết ở `docs/SETUP_ENV.md` mục 8.1.

**Ghi chú `flutter doctor -v` (theo yêu cầu của bạn):**

| Mục | Kết quả | Xử lý |
|---|---|---|
| Android toolchain | ✔ xanh (SDK 36.0.0, Java 21, all licenses accepted) | — |
| Chrome | ✔ có sẵn | Bỏ qua, dự án chỉ build Android |
| Visual Studio | ✘ chưa cài | **Bỏ qua**, chỉ cần cho ứng dụng Windows desktop |
| Android Studio | không xuất hiện trong báo cáo | **Bỏ qua**, SDK và JDK đã cấu hình trực tiếp cho Flutter |
| Flutter | ⚠ "not on your path" | Chỉ xảy ra với tiến trình mở trước khi sửa PATH. Mở lại VS Code là hết |

### Khái niệm cần hiểu

- **FROZEN requirements:** đặc tả yêu cầu bị "đóng băng", không được sửa để né lỗi. Không làm được thì báo blocker, không âm thầm hạ cấp tính năng.
- **Quality Gate:** chuỗi kiểm tra bắt buộc sau mỗi phase: `dart format` → `flutter analyze` → `flutter test` → `flutter build apk --debug`. Xanh hết mới được merge vào `main`.
- **Static analysis / lint:** công cụ đọc code *mà không chạy* để tìm lỗi tiềm ẩn. `strict-casts` cấm ép kiểu ngầm từ `dynamic`; `strict-inference` bắt khai báo kiểu khi trình biên dịch không suy ra được; `strict-raw-types` cấm dùng generic thiếu tham số kiểu (như `List` thay vì `List<int>`).
- **Gradle / AGP / NDK:** Gradle là hệ thống build của Android. AGP (Android Gradle Plugin) dạy Gradle cách build app Android. NDK là bộ công cụ cho mã native C/C++, Flutter cần nó để xử lý thư viện `libflutter.so`.
- **Conventional Commits:** quy ước `type(scope): subject`, ví dụ `chore(lint): ...`, `build(android): ...`, giúp lịch sử commit dễ đọc và có thể tự sinh CHANGELOG.
- **`git merge --no-ff` và tag:** `--no-ff` luôn tạo một commit merge, nên trên GitHub nhìn rõ "nhánh phase này gồm những commit nào". Tag `phase-0` đánh dấu mốc để quay lại khi cần.

### Kết quả kiểm thử

| Bước | Lệnh | Kết quả |
|---|---|---|
| 1 | `dart format --output=none --set-exit-if-changed lib test` | ✔ 0 file thay đổi |
| 2 | `flutter analyze` | ✔ No issues found |
| 3 | `flutter test` | ✔ 1/1 test pass (test mặc định "Counter increments smoke test") |
| 4 | `flutter build apk --debug` | ✔ `build/app/outputs/flutter-apk/app-debug.apk` |
| 5 | Thiết bị | ⚠ **Chưa test trên thiết bị** (chưa có máy Android kết nối). Có checklist thủ công trong `docs/TEST_REPORT.md` |

### Cách tự kiểm tra bằng tay

1. Đóng hẳn VS Code rồi mở lại, mở terminal: `flutter --version` → Flutter 3.47.6, Dart 3.13.5.
2. `flutter doctor -v` → mục Android toolchain có `[√]`.
3. Trong thư mục dự án: `flutter test` → All tests passed.
4. Cắm điện thoại (bật *USB debugging*), `flutter devices` thấy máy, `flutter run` → app đếm số mặc định hiện lên, bấm nút + thì số tăng.

### Danh sách commit

```
docs(phase-0): record environment setup and phase 0 results   (commit cuối của phase)
e1d2d9d build(android): cap gradle heap for 8 GB RAM dev machine
f815476 chore(lint): enable stricter analysis options
fceeba6 chore: scaffold flutter project
c297ebd docs: add CLAUDE.md with frozen requirements and phase plan
62c186e chore: add gitignore and gitattributes
```

Commit gốc trên `main` trước khi tách nhánh: `16f40ff docs: add original project brief`.

---

## Phase 1 — Nền tảng: models, theme, router, cấu trúc thư mục

**Trạng thái:** ✅ hoàn tất (merge vào `main`, tag `phase-1`).

### Mục tiêu phase

Dựng "khung xương" của app: thư viện, cấu trúc thư mục, các model dữ liệu, theme, định dạng tiền/ngày, hàm bỏ dấu tiếng Việt và điều hướng 3 tab. Chưa có tính năng nghiệp vụ; các màn hình mới là placeholder.

FR/NFR liên quan: **NFR-4** (cấu trúc thư mục), **FR-5.5** (5 danh mục), **FR-7.1/7.2** (router), một phần **FR-3.1** (bỏ dấu), **FR-2.2** (model `OcrLine`), **FR-3.6** (model `ParsedReceipt`), **FR-8.1** (theme M3), **FR-8.3** (định dạng tiền/ngày).

### Đã làm gì

| File | Class / hàm | Vai trò |
|---|---|---|
| `pubspec.yaml` | — | Thêm 11 gói runtime + `flutter_localizations`, 3 gói dev. Phiên bản thực tế ghi ở Decisions Log D-012. |
| `android/app/src/main/AndroidManifest.xml` | — | Quyền `CAMERA`, gỡ `RECORD_AUDIO`, khai báo `UCropActivity` cho `image_cropper`. |
| `android/app/build.gradle.kts` | — | `minSdk = 24` (camera cần ≥ 23, ML Kit ≥ 21). |
| `ios/Runner/Info.plist` | — | Chuỗi xin quyền camera / thư viện ảnh / micro (bằng tiếng Việt). |
| `lib/core/text_normalizer.dart` | `TextNormalizer.removeDiacritics`, `.normalize` | Bỏ dấu tiếng Việt (kể cả `đ/Đ`, dấu kết hợp NFD), chữ thường, gộp khoảng trắng. |
| `lib/core/formatters.dart` | `Formatters.vnd`, `.groupDigits`, `.date` | `150000 → "150.000 đ"`, `dd/MM/yyyy`. |
| `lib/core/app_theme.dart` | `AppTheme.light/.dark` | `ColorScheme.fromSeed(Color(0xFF2C4570))` cho cả sáng và tối. |
| `lib/core/router.dart` | `createAppRouter`, `AppRoutes` | GoRouter: 3 tab trong `StatefulShellRoute.indexedStack`, `/review` (nhận `extra`), `/expense/:id`, trang 404. |
| `lib/state/router_provider.dart` | `routerProvider` | Tạo router **một lần** cho mỗi `ProviderScope`. |
| `lib/models/expense_category.dart` | `enum ExpenseCategory` | 5 danh mục + nhãn tiếng Việt + icon + màu (switch expression). |
| `lib/models/expense.dart` | `Expense` | Giao dịch bất biến, `amount` là `int`, `toMap/fromMap`, `copyWith`. |
| `lib/models/ocr_line.dart` | `OcrLine` | Dòng chữ + `Rect boundingBox`: model riêng, không phụ thuộc ML Kit. |
| `lib/models/parsed_receipt.dart`, `field_confidence.dart` | `ParsedReceipt`, `FieldConfidence` | Kết quả parse: mọi trường nullable + độ tin cậy `high/low/missing`. |
| `lib/widgets/state_message.dart` | `StateMessage` | Khối icon + tiêu đề + mô tả dùng chung cho trạng thái rỗng/lỗi. |
| `lib/screens/...` | `HomeShell`, `DashboardScreen`, `ScanScreen`, `HistoryScreen`, `ReviewScreen` | Khung màn hình. `HomeShell` chứa `NavigationBar` M3. |
| `lib/app.dart`, `lib/main.dart` | `VkuExpenseApp`, `main()` | `ProviderScope` → `MaterialApp.router`, locale `vi_VN`, `initializeDateFormatting`. |

### Vì sao làm vậy (liên hệ slide)

- **`amount` là `int`, không phải `double` (lỗi slide số 7):** tiền Việt không có phần lẻ. `double` biểu diễn số nhị phân nên `0.1 + 0.2 != 0.3`; cộng dồn nhiều giao dịch sẽ lệch vài đồng. `int` luôn chính xác.
- **Enum + switch expression (W7 s14):** `label`, `icon`, `color` viết bằng `switch (this) { food => ..., ... }`. Switch expression trên enum là *exhaustive*: nếu ai đó thêm danh mục thứ 6 mà quên một nhánh, chương trình **không biên dịch được**. Nhờ vậy ràng buộc "đúng 5 danh mục" được trình biên dịch kiểm tra.
- **Model bất biến + `const` constructor + initializer list (W7 s15):** `ParsedReceipt` dùng `assert` trong initializer list để bảo đảm "giá trị `null` ⇔ độ tin cậy `missing`". Ghép nhầm (ví dụ có số tiền mà vẫn đánh dấu missing) sẽ bị báo ngay khi chạy debug/test.
- **Null safety (W7 s12):** mọi trường của `ParsedReceipt` đều nullable vì parser có thể không tìm thấy. Màn Review sẽ dùng `??` để điền giá trị mặc định.
- **Records + patterns (W7 s13–14):** `ReviewScreen` chọn câu mô tả bằng `switch ((expenseId, receipt)) { (final int id, _) => ..., (null, final ParsedReceipt _) => ..., (null, null) => ... }`, tức là so khớp trên một record 2 phần tử.
- **`OcrLine` riêng thay vì dùng thẳng `TextLine` của ML Kit (FR-2.2):** parser chỉ biết `OcrLine`, nên unit test tự tạo dữ liệu với tọa độ giả mà không cần điện thoại hay ML Kit.
- **Router nằm trong provider (W8 s14–18, W7 s30):** nếu tạo `GoRouter(...)` trong `build()`, mỗi lần rebuild sẽ có router mới và mất lịch sử điều hướng. Đặt trong `Provider` thì router được tạo một lần, có `ref.onDispose(router.dispose)` để giải phóng.
- **`StatefulShellRoute.indexedStack` thay vì `ShellRoute` (W8 s20–24):** mỗi tab giữ stack và trạng thái riêng (ví dụ vị trí cuộn trong Lịch sử) khi chuyển qua lại.
- **Gỡ quyền micro:** plugin camera tự khai báo `RECORD_AUDIO` để quay video. App chỉ chụp ảnh, nên dùng `tools:node="remove"` để không xin quyền thừa.
- **Lựa chọn đã cân nhắc:** dùng `freezed` để sinh `copyWith/==` tự động. **Không chọn** vì cần `build_runner` (code sinh tự động có thể phải `// ignore`, trái quy tắc 2.2) và viết tay giúp hiểu rõ hơn.

### Khái niệm cần hiểu

- **Bỏ dấu & NFC/NFD:** chữ "ế" có thể lưu thành **1 ký tự** (dạng dựng sẵn, NFC) hoặc **3 ký tự** "e" + dấu mũ + dấu sắc (dạng tách, NFD). `TextNormalizer` xử lý cả hai: tra bảng cho dạng NFC, xóa các ký tự dấu kết hợp U+0300–U+036F cho dạng NFD.
- **NBSP:** `NumberFormat` của locale vi_VN đặt **khoảng trắng không ngắt** (U+00A0) giữa số và `đ`, trông như dấu cách thường nhưng không cho xuống dòng ở đó. Test so sánh đúng ký tự này.
- **`ValueGetter` trong `copyWith`:** `copyWith(imagePath: null)` không phân biệt được "giữ nguyên" với "xóa". Truyền hàm `() => null` thì rõ ràng là "đặt về null".
- **Provider override trong test:** `ProviderScope(overrides: [routerProvider.overrideWithValue(router)])` cho test tự chọn trang bắt đầu (ví dụ `/expense/42`) mà không sửa code app.
- **`tools:node="remove"`:** chỉ thị cho *manifest merger* của Android: khi gộp manifest của app với manifest của các plugin, xóa phần tử này.

### Kết quả kiểm thử

| Bước | Kết quả |
|---|---|
| `dart format --set-exit-if-changed lib test` | ✔ 0 thay đổi |
| `flutter analyze` | ✔ No issues found |
| `flutter test` | ✔ **48/48** pass |
| `flutter test --coverage` | 85.3% dòng (214/251) |
| `flutter build apk --debug` | ✔ (lần đầu 12.5 phút do tải ML Kit/CameraX/uCrop; Gradle tự cài CMake 3.22.1 vào `D:\Android\SDK\cmake`) |
| Thiết bị | ⚠ **Chưa test trên thiết bị**: chưa cắm máy. Checklist ở `docs/TEST_REPORT.md` |

Phân bổ test: `app_router_test` 7 · `text_normalizer_test` 10 · `formatters_test` 6 · `app_theme_test` 3 · `expense_test` 9 · `expense_category_test` 7 · `parsed_receipt_test` 6.

Test counter mặc định của template đã được **thay** bằng `app_router_test.dart`: app counter không còn tồn tại nên test cũ không còn ứng với yêu cầu nào. Lý do ghi trong commit `feat(router)`.

### Cách tự kiểm tra bằng tay

1. `flutter run` trên điện thoại: app mở ở tab **Tổng quan**, thanh dưới có 3 tab *Tổng quan / Quét / Lịch sử*.
2. Bấm từng tab: tiêu đề AppBar đổi theo.
3. Bật dark mode của điện thoại: app chuyển sang nền tối (theme theo hệ thống).
4. Xoay ngang: không có sọc vàng-đen báo tràn (overflow).

### Danh sách commit

```
87f6864 feat(router): add go_router shell with three tabs and placeholder screens
4cdf6f3 feat(models): add expense, category, OCR line and parsed receipt models
0c6c4a9 feat(core): add theme, formatters and Vietnamese text normalizer
c912023 build: add phase 1 dependencies and native platform config
docs(phase-1): record phase 1 results   (commit cuối của phase)
```

---

## Phase 2 — ReceiptParser (TDD)

**Trạng thái:** ✅ hoàn tất (merge vào `main`, tag `phase-2`).

### Mục tiêu phase

Viết "bộ não" đọc hóa đơn, phần nặng điểm nhất của rubric (3.5đ). Đầu vào là các dòng chữ OCR kèm vị trí. Đầu ra là tên cửa hàng, tổng tiền, ngày, gợi ý danh mục, mỗi trường kèm độ tin cậy.

FR liên quan: **FR-2.3** (ghép hàng), **FR-3.1 → FR-3.7** (chuẩn hóa, tổng tiền, ngày, tên cửa hàng, danh mục, `ParsedReceipt`, bảng regex).

### TDD hiện rõ trong lịch sử Git

TDD (Test-Driven Development) = **viết test trước, code sau**. Vòng lặp: 🔴 *Red* (test fail vì chưa có code) → 🟢 *Green* (viết vừa đủ code cho test pass) → 🔵 *Refactor* (dọn code, test vẫn xanh).

| # | Commit | Trạng thái test sau commit |
|---|---|---|
| 1 | `test(parser): add 23 receipt fixtures with expected fields and tests` | 🔴 mọi test mới **không biên dịch được** (chưa có `ReceiptParser`, `RowGrouper`) |
| 2 | `refactor(models): keep parser-facing models free of Flutter imports` | 🔵 48 test cũ vẫn xanh |
| 3 | `feat(core): add OCR-tolerant keyword key and digit repair` | 🟢 6 test chuẩn hóa OCR xanh |
| 4 | `feat(parser): group OCR lines into rows by vertical overlap` | 🟢 11 test row grouper xanh |
| 5 | `feat(parser): extract totals with keyword tiers and exclusions` | 🟢 34 test tổng tiền xanh; ngày, tên, danh mục còn 🔴 |
| 6 | `feat(parser): extract and validate receipt dates` | 🟢 20 test ngày xanh |
| 7 | `feat(parser): pick the merchant name from the header rows` | 🟢 22 test tên cửa hàng xanh |
| 8 | `feat(parser): suggest a category with Dart 3 pattern matching` | 🟢 28 test danh mục xanh; benchmark: merchant 22/23 |
| 9 | `fix(parser): skip founding-year taglines when picking the merchant` | 🔴→🟢 thêm test mới trước, rồi sửa; benchmark 23/23 |
| 10 | `docs(parser): add regex table generated from the parser source` | — |

**Không có giá trị kỳ vọng nào bị sửa sau commit 1.** Có hai thay đổi ở file test cũ, đều ghi rõ trong commit: thêm một dòng `import` cho `expense_category_test.dart` (commit 2, assertion giữ nguyên) và thêm test slogan (commit 9, chỉ thêm, không sửa).

### Đã làm gì

| File | Vai trò |
|---|---|
| `test/fixtures/receipts/*.txt` (23 file) | Hóa đơn tổng hợp: Co.op Mart, WinMart, Bách Hóa Xanh, Lotte Mart, Highlands, Phúc Long, The Coffee House, Circle K, GS25, Fahasa, Grab, Be, CGV, Thế Giới Di Động, CellphoneS, quán cơm, hóa đơn tiếng Anh, tiệm photo, trà sữa (OCR nhiễu), ảnh bị cắt, karaoke, Phở 24 (OCR đọc 0 thành O), bánh mì (ảnh nghiêng). |
| `test/fixtures/receipts/expected.dart` | Kết quả đúng của từng hóa đơn, viết **trước** khi có parser. |
| `test/fixtures/receipts/known_limitations.dart` | Sổ ghi các trường parser chắc chắn sai, kèm lý do. Hiện **rỗng**. |
| `test/support/receipt_fixture.dart` | Biến file `.txt` thành danh sách `OcrLine` có tọa độ giả lập, trả về theo **từng cột** giống ML Kit. |
| `lib/services/row_grouper.dart`, `lib/models/receipt_row.dart` | `RowGrouper`: ghép các dòng cùng độ cao thành một hàng (FR-2.3). |
| `lib/services/receipt_parser.dart` | `ReceiptParser`: `extractTotal`, `extractDate`, `extractMerchant`, `suggestCategory`, `parse`. |
| `lib/services/receipt_keywords.dart` | Toàn bộ bảng từ khóa (tổng tiền, loại trừ, tên, 5 danh mục). Tách riêng để dễ đọc và dễ bổ sung. |
| `lib/core/text_normalizer.dart` | Thêm `ocrKey` (gộp ký tự OCR hay nhầm) và `repairDigits` (sửa O/l trong số). |
| `lib/core/category_style.dart` | Icon và màu danh mục, chuyển ra khỏi model để parser không phụ thuộc Flutter. |
| `test/services/parser_purity_test.dart` | Test kiến trúc: dò toàn bộ chuỗi `import` của parser và row grouper, bảo đảm không có `package:flutter` hay ML Kit. |
| `docs/REGEX_TABLE.md`, `tool/regex_table/` | Bảng 29 regex cho báo cáo, sinh tự động từ mã nguồn. |

### Vì sao làm vậy (liên hệ slide)

- **Ghép hàng theo bounding box thay vì `split('\n')` (sửa lỗi slide W8 s42):** ML Kit trả chữ theo *khối*. Cột nhãn bên trái ("Tổng tiền hàng", "Tổng thanh toán") là một khối, cột số bên phải ("260.000", "245.000") là khối khác. Tách theo `\n` sẽ thấy "Tổng thanh toán" và "245.000" ở hai dòng xa nhau. `RowGrouper` dựa vào tọa độ Y để ghép lại.
- **Bỏ dấu trước khi so khớp (sửa lỗi slide W8 s42):** regex `tong tien|thanh toan` của slide không khớp "Tổng tiền". Mọi so khớp đều chạy trên chữ đã bỏ dấu, nhưng giá trị trả về giữ nguyên chữ gốc (FR-3.1).
- **Records làm kết quả trung gian (W7 s13):** mỗi hàm trả về `(int amount, FieldConfidence confidence)?`, tức là một cặp giá trị không cần tạo class riêng. Records so sánh bằng giá trị, nên test viết gọn: `expect(total(rows), (150000, high))`.
- **Pattern matching (W7 s14):** `suggestCategory` dùng `switch ((byName, byContent))` trên record, *list pattern* `[final first, final second, ...] when first.value > second.value` để phát hiện hòa, và một `switch` *exhaustive* trên enum (thêm danh mục thứ 6 mà quên từ điển là lỗi biên dịch).
- **Null safety (W7 s12):** không chắc thì trả `null` chứ không đoán bừa. Ví dụ không có ngày thì `date = null`, và màn Review sẽ gợi ý ngày hôm nay.
- **Parser là Dart thuần:** chỉ làm việc với chuỗi, nên ~150 test chạy trong vài giây, không cần điện thoại hay ML Kit. Đây là lý do FR-2.2 yêu cầu model `OcrLine` riêng.
- **Lựa chọn đã cân nhắc nhưng không dùng:**
  - *So khớp mờ bằng khoảng cách Levenshtein* cho lỗi OCR: mạnh hơn nhưng khó giải thích và dễ khớp nhầm. Bảng gộp ký tự (`ocrKey`) đơn giản và đủ cho các lỗi hay gặp (l↔i, 0↔o).
  - *Lấy số lớn nhất làm tổng* (cách đơn giản nhất): sai ngay với hóa đơn có "Tiền khách đưa 500.000" lớn hơn tổng. Vì vậy chỉ dùng làm phương án dự phòng (fallback), với độ tin cậy thấp.
  - *Học máy (ML) để phân loại hàng:* cần dữ liệu lớn, không giải thích được, vượt phạm vi môn học.

### Khái niệm cần hiểu

- **Row grouping theo bounding box:** mỗi dòng OCR có hình chữ nhật bao quanh (`Rect`). Hai dòng cùng một hàng nếu phần **chồng lấp theo chiều dọc** ≥ 50% chiều cao của dòng thấp hơn:

  ```
  y=100 ┌──────────────┐            ┌─────────┐ y=102
        │ Tổng thanh   │            │ 245.000 │        chồng lấp 18/20 px = 90% → cùng hàng
  y=120 └──────────────┘            └─────────┘ y=122
  ```

  Dòng mới được so với **dải trung bình** của hàng chứ không so với dòng vừa thêm. Nhờ vậy ba dòng xếp kiểu bậc thang (A chạm B, B chạm C) không bị dồn hết vào một hàng.
- **Phân loại hàng theo từ khóa đầu tiên:** mỗi hàng được gán một loại (thanh toán cuối / tổng / tạm tính / tiền khách đưa / không phải tổng / liên hệ) theo từ khóa **xuất hiện sớm nhất**. Nếu cùng vị trí thì từ khóa **dài hơn** thắng: "Tổng chiết khấu" là giảm giá chứ không phải tổng, dù bắt đầu bằng "tổng".
- **Ưu tiên tổng tiền (FR-3.2):** thanh toán cuối > tổng > tạm tính. Cùng mức thì lấy hàng **thấp hơn** trên hóa đơn. Nhãn nằm một mình thì lấy hàng chỉ có số ngay bên dưới. Không có từ khóa nào thì lấy số lớn nhất, độ tin cậy thấp.
- **Lookbehind / lookahead trong regex:** `(?<![a-z0-9])` nghĩa là "ký tự đứng trước không phải chữ/số". Ví dụ `(?<![a-z0-9])tel(?![a-z0-9])` khớp "Tel:" nhưng không khớp "Hotel".
- **Back-reference `\2`:** trong regex ngày, `\2` bắt dấu phân cách thứ hai phải giống dấu thứ nhất, nên "14/09/2026" khớp còn "14/09-2026" thì không.
- **Kiểm tra ngày có thật:** `DateTime(2026, 4, 31)` không báo lỗi mà tự đổi thành 01/05/2026. Vì vậy parser dựng `DateTime` rồi so lại tháng/ngày; lệch là ngày không tồn tại.
- **Sổ known limitations:** bộ benchmark so khớp **chính xác** tập trường sai với sổ. Trường sai mà chưa có trong sổ thì test fail (regression). Trường trong sổ mà đã đúng thì test cũng fail, buộc phải gỡ khỏi sổ. Cơ chế này không `skip` test nào.

### Kết quả kiểm thử

| Bước | Kết quả |
|---|---|
| `dart format --set-exit-if-changed lib test` | ✔ 0 thay đổi |
| `flutter analyze` | ✔ No issues found |
| `flutter test` | ✔ **201/201** (48 cũ + 153 mới) |
| `flutter test --coverage` | **94.9%** dòng (461/486); `receipt_parser.dart` 99.4%, `row_grouper.dart` 94.3% |
| `flutter build apk --debug` | ✔ |
| Thiết bị | ⚠ **Chưa test trên thiết bị** (Phase 2 không có giao diện mới) |

Phân bổ 153 test mới: tổng tiền 34 · ngày 20 · tên cửa hàng 23 · danh mục 28 · parse 4 · row grouper 11 · kiến trúc 2 · chuẩn hóa OCR 6 · benchmark fixture 25.

**Độ chính xác trên bộ 23 fixture** (`build/reports/receipt_parser_accuracy.md`):

| Trường | Đúng | Ghi chú |
|---|---|---|
| Tổng tiền | **23/23** | Lần chạy benchmark đầu tiên đã 23/23 |
| Ngày | **23/23** | Lần chạy đầu 23/23 |
| Danh mục | **23/23** | Lần chạy đầu 23/23 |
| Tên cửa hàng | **23/23** | Lần chạy đầu **22/23** (sai `bookworm_english.txt`: chọn slogan "Books & Stationery since 2001"); sửa bằng commit `fix(parser)` |

Không fixture nào phải ghi vào sổ known limitations.

⚠️ **Đọc con số này cho đúng:**
1. Fixture là hóa đơn **tổng hợp** do chính người viết parser soạn. Dù kỳ vọng được viết trước, người viết vẫn biết các quy tắc sẽ làm, nên 23/23 là con số **lạc quan**. Độ chính xác thật phải đo bằng hóa đơn thật ở Phase 3 (có điện thoại).
2. `banh_mi_skewed.txt` (ảnh nghiêng ~4.6°) pass phần tổng tiền nhưng các hàng đã bị **xô lệch**: "Tổng tiền hàng" bị ghép với "10.000 20.000" của hàng trên. Tổng thanh toán vẫn đúng chỉ vì nhãn "Thanh toán" đứng một mình và số "90.000" rơi xuống hàng ngay dưới. **Không** nên kết luận parser chịu được ảnh nghiêng.
3. `cellphones.txt` pass phần tên cửa hàng một phần nhờ may: slogan "Hệ thống bán lẻ điện thoại, laptop" bị loại vì chứa "điện thoại" (vốn là từ khóa nhãn số điện thoại). Slogan không chứa từ khóa nào vẫn có thể thắng dòng thương hiệu ngắn.

### Hạn chế đã biết

- **Ảnh nghiêng** > ~3°: số tiền trôi sang hàng dưới. Hướng khắc phục: khung căn chỉnh ở Phase 6, hoặc ước lượng góc nghiêng từ các dòng rồi xoay lại (chưa làm).
- **Slogan dài hơn tên thương hiệu** (không chứa từ khóa loại trừ): FR-3.4 chọn hàng nhiều chữ cái nhất nên chọn nhầm slogan.
- **Số bị OCR chèn dấu cách** ("245 000"), **"k"** ("45k"), **phần thập phân** ("150.000,00"): chưa đọc được.
- **Ngày kiểu Mỹ** MM/DD/YYYY, **ISO** YYYY-MM-DD, **"ngày 14 tháng 9 năm 2026"**: chưa hỗ trợ (FR-3.3 không yêu cầu).
- **Từ điển danh mục** chỉ chứa các thương hiệu và từ phổ biến. Cửa hàng lạ không có từ khóa → `null`, người dùng tự chọn ở Review (đúng FR-3.5).

### Cách tự kiểm tra bằng tay

1. Chạy riêng bộ benchmark rồi mở báo cáo:
   ```powershell
   flutter test test/services/receipt_fixtures_test.dart
   notepad build/reports/receipt_parser_accuracy.md
   ```
2. Thử nghiệm: mở một fixture, ví dụ `test/fixtures/receipts/gs25.txt`, sửa "Tổng cộng:" thành "Tong cong" rồi chạy lại. Test vẫn pass nhờ bỏ dấu. Hoàn tác bằng `git checkout -- test/fixtures`.
3. Thêm hóa đơn của chính bạn: tạo file `.txt` mới (định dạng trong `test/fixtures/receipts/README.md`), thêm một `ReceiptExpectation` vào `expected.dart`, rồi chạy benchmark.
4. Xem bảng regex: `docs/REGEX_TABLE.md`. Sau khi sửa regex, sinh lại bằng `python tool/regex_table/gen_regex_table.py`.

### Danh sách commit

```
865904c docs(parser): add regex table generated from the parser source
a532b39 fix(parser): skip founding-year taglines when picking the merchant
1ddc7a0 feat(parser): suggest a category with Dart 3 pattern matching
3706551 feat(parser): pick the merchant name from the header rows
ac514b2 feat(parser): extract and validate receipt dates
96e3502 feat(parser): extract totals with keyword tiers and exclusions
c4ddb5e feat(parser): group OCR lines into rows by vertical overlap
09d44ff feat(core): add OCR-tolerant keyword key and digit repair
6ad465e refactor(models): keep parser-facing models free of Flutter imports
794a4e4 test(parser): add 23 receipt fixtures with expected fields and tests
docs(phase-2): record phase 2 results   (commit cuối của phase)
```

---

## Phase 3 — Dịch vụ OCR (ML Kit)

**Trạng thái:** ✅ hoàn tất (merge vào `main`, tag `phase-3`). ⚠ Phần đánh giá trên **điện thoại thật** còn nợ (NFR-6), mới chạy trên emulator.

### Mục tiêu phase

Nối parser ở Phase 2 với ML Kit để đọc ảnh thật: ảnh → OCR → ghép hàng → parse → `ParsedReceipt` + thời gian xử lý. Sau đó đo độ chính xác trên hóa đơn thật (đáp án đã khóa bằng SHA-256) và sửa các lỗi tổng quát mà lần đo đầu phát hiện.

FR liên quan: **FR-2.1** (TextRecognizer Latin, offline), **FR-2.2** (adapter ML Kit → `OcrLine`), **FR-2.3** (ghép hàng, thêm khử nghiêng), **FR-2.4** (đo `Stopwatch`), **FR-2.5** (`close()`), **FR-4.5** (một phần: widget "Xem văn bản OCR gốc"), NFR-2 (parse chạy trong isolate).

### Đã làm gì

| File | Vai trò |
|---|---|
| `lib/services/ocr_service.dart` | Interface `OcrService` + `MlKitOcrService`: `TextRecognizer(script: latin)`, `InputImage.fromFilePath`, đo `processImage` bằng `Stopwatch` và ghi log, `close()` giải phóng recognizer. Hàm `ocrLinesFrom` chuyển `RecognizedText` → `List<OcrLine>` ở mức `TextLine`, giữ 4 góc (`cornerPoints`). |
| `lib/models/ocr_line.dart` | Thêm `cornerPoints` (tùy chọn) để tính góc nghiêng. |
| `lib/services/row_grouper.dart` | `estimateSkew`: ước lượng góc nghiêng từ cạnh trên của các dòng, xoay ngược lại trước khi ghép hàng. Chọn **hướng chung của nhiều dòng nhất** (±10°) để chữ nền không làm lệch kết quả. |
| `lib/services/receipt_scan_service.dart` | Pipeline `ReceiptScanService`: OCR → `RowGrouper` → `ReceiptParser` trong `Isolate.run`. Ảnh hỏng/thiếu không ném lỗi mà trả `ParsedReceipt` rỗng (mọi trường `missing`) kèm thông báo tiếng Việt. |
| `lib/state/ocr_providers.dart` | `ocrServiceProvider` (gọi `close()` khi dispose), `receiptScanServiceProvider`, `pickGalleryImageProvider` (test thay được thư viện ảnh). |
| `lib/screens/debug/ocr_debug_screen.dart` | Màn debug **tạm** `/debug/ocr` (mở từ tab Quét): chọn ảnh → chạy pipeline thật → xem kết quả, độ tin cậy, văn bản gốc. Sẽ bị xóa ở Phase 7. |
| `lib/widgets/ocr_text_panel.dart` | Khối "Xem văn bản OCR gốc" + thời gian OCR, tách riêng để màn Review (Phase 7) dùng lại cho FR-4.5. |
| `integration_test/ocr_eval_test.dart`, `integration_test/ocr_eval/` | Bài đánh giá chạy **trên thiết bị**: kiểm tra lại hash, chạy ML Kit thật trên từng ảnh, chấm theo quy tắc đã khóa, xuất `report.json` + `report.md`. |
| `tool/ocr_eval/run_ocr_eval.ps1` | Một lệnh: kiểm tra hash → đẩy ảnh lên máy → chạy test → kéo báo cáo về `D:\receipts-test\reports\` (ngoài repo) → xóa ảnh trên máy. |
| `lib/services/receipt_parser.dart`, `receipt_keywords.dart` | Các bản sửa tổng quát sau lần đo đầu (xem mục dưới). |
| `test/...` | Test adapter với đối tượng ML Kit dựng tay, service qua platform channel giả lập, pipeline với `FakeOcrService` (chỉ nằm trong `test/`), deskew, chấm điểm, màn debug, 8 fixture mới. |

### Lần đo đầu → sửa → đo lại

1. **Lần đầu** (mã nguồn `54eba91`, emulator API 33): main tổng tiền **10/19**, ngày 14/19, tên cửa hàng 7/19.
2. **Viết test trước** (`c74447e`, 🔴): mỗi lỗi quan sát được viết thành một **quy tắc tổng quát** kèm fixture tổng hợp, không chép nguyên một ảnh nào.
3. **Sửa code** (`4ee3458`, `17e6d79`, `7a04bd7`, `18f299a`, 🟢):
   - Fallback ưu tiên số viết như tiền (có dấu phân cách hoặc `đ`) hơn số trơn (số phiếu, giờ).
   - Đọc số có 2 chữ số thập phân `123,100.00`, khoảng trắng chèn sau dấu phân cách, `đ` bị đọc thành `0`/`6`.
   - Nhãn tổng dài chấp nhận sai 1 ký tự (`1ONG CONG`), nhãn viết tắt (`T.Cộng`), "Tổng:" của bảng VAT xếp yếu hơn.
   - Máy POS in tiền khách đưa dưới nhãn tổng → dùng `khách đưa − tiền thối` nếu số đó có trên hóa đơn.
   - Bỏ tiêu đề bảng ("Mặt hàng", "Đơn giá") khỏi ứng viên tên cửa hàng; đọc tên tháng tiếng Anh; quần áo/phụ kiện là Gear.
   - Góc nghiêng theo hướng đa số.
4. **Đo lại** (`18f299a`): main tổng tiền **16/19**, ngày **15/19**, danh mục đúng 11/19, tên cửa hàng vẫn 7/19. Không trường nào tụt.

### Vì sao làm vậy (liên hệ slide)

- **Interface + adapter (W8 s41 pipeline):** parser chỉ biết `OcrLine`, không biết ML Kit. Nhờ vậy ~200 test parser chạy trên máy tính trong vài giây, còn ML Kit chỉ cần test ở tầng adapter.
- **Future/async (W7 s17) và isolate (W7 s30):** `processImage` là `Future`; ghép hàng và parse chạy trong `Isolate.run` để không chặn UI thread. Các trường được chép ra biến cục bộ để closure không giữ tham chiếu tới recognizer native (không gửi được qua isolate).
- **Vòng đời (W7 s26–29, NFR-3):** provider gọi `close()` khi bị hủy, bảo đảm recognizer native được giải phóng (FR-2.5).
- **Không ném lỗi ra UI:** ảnh hỏng vẫn cho người dùng nhập tay, đúng tinh thần "người dùng kiểm tra lại ở Review".
- **Lựa chọn đã cân nhắc:**
  - *Gọi ML Kit trực tiếp trong màn hình:* nhanh nhưng không test được và vi phạm FR-2.2.
  - *Cộng vector tất cả các dòng để tính góc nghiêng* (bản đầu): đơn giản, nhưng chữ in xoay ngang trên túi phía sau hóa đơn kéo lệch góc → thay bằng "hướng đa số".
  - *Sửa lỗi OCR bằng so khớp mờ toàn bộ:* chỉ áp dụng sai 1 ký tự cho nhãn dài ≥ 8 ký tự; từ ngắn như "tổng" mà cho sai 1 ký tự sẽ khớp nhầm rất nhiều.

### Khái niệm cần hiểu

- **`cornerPoints` và góc nghiêng:** ML Kit trả 4 góc của mỗi dòng theo chiều kim đồng hồ từ góc trên-trái. Vector từ góc trên-trái tới góc trên-phải cho hướng dòng chữ; `atan2(dy, dx)` ra góc. Xoay mọi điểm ngược góc đó thì các dòng trở lại nằm ngang, rồi mới ghép hàng.
- **`Stopwatch`:** đồng hồ bấm giờ của Dart; `start()` trước `processImage`, đọc `elapsedMilliseconds` sau đó. Chỉ đo phần OCR, không tính thời gian chọn ảnh.
- **Platform channel giả lập trong test:** ML Kit gọi code Android qua `MethodChannel`. Test đăng ký handler giả để kiểm tra app gửi đúng tham số (script Latin, đường dẫn ảnh) và đóng đúng recognizer, không cần điện thoại.
- **Integration test trên thiết bị:** khác unit test, chạy app thật trên Android (`flutter test integration_test/... -d <máy>`), nên dùng được ML Kit thật.
- **Khóa đáp án bằng SHA-256:** hash của `ground_truth.csv` được ghi trước khi chạy. Đổi một ký tự trong đáp án thì hash đổi và công cụ dừng lại, không thể "sửa đáp án cho khớp kết quả".
- **Dữ liệu đã thấy (in-sample):** sửa code sau khi xem lỗi của chính bộ ảnh thì lần đo lại trên bộ đó sẽ đẹp hơn thực tế. Vì vậy 16/19 phải đọc là con số lạc quan.

### Kết quả kiểm thử

| Bước | Kết quả |
|---|---|
| `dart format --set-exit-if-changed lib test integration_test tool` | ✔ 0 thay đổi |
| `flutter analyze` | ✔ No issues found |
| `flutter test` | ✔ **272/272** (201 cũ + 71 mới) |
| `flutter test --coverage` | **95.6%** dòng (693/725); `ocr_service.dart` 100%, `receipt_scan_service.dart` 100%, `row_grouper.dart` 100%, `receipt_parser.dart` 99.6% |
| `flutter build apk --debug` | ✔ |
| Benchmark fixture | **31/31** ở cả 4 trường (23 cũ + 8 mới), sổ known limitations rỗng |
| Hóa đơn thật, emulator `vku_test_api33` | xem bảng dưới |
| Điện thoại thật | ⚠ **Chưa test** (NFR-6 còn nợ) |

**Hóa đơn thật** (22 ảnh, hash `ground_truth.csv` đã kiểm tra trước mỗi lần chấm):

| Set | Lần | Tên cửa hàng | Tổng tiền | Ngày | Danh mục đúng / không / sai | OCR trung vị |
|---|---|---|---|---|---|---|
| main (19) | đầu | 7 | 10 | 14 | 10 / 5 / 4 | 4947 ms |
| main (19) | sau sửa | 7 | **16** | **15** | 11 / 4 / 4 | 5036 ms |
| edge (3) | đầu | 1 | 2 | 2 | 1 / 1 / 1 | 4694 ms |
| edge (3) | sau sửa | 1 | 2 | 2 | 2 / 1 / 0 | 5286 ms |

Chi tiết từng ảnh và nguyên nhân từng lỗi: `docs/TEST_REPORT.md`, mục "Độ chính xác trên hóa đơn thật".

### Hạn chế đã biết

- **Tên cửa hàng chỉ 7/19:** logo in kiểu chữ đặc biệt bị OCR đọc sai ("HIGHANDS CUFFE"); hàng địa chỉ không có từ khóa "Đ/c" không bị loại; ảnh không có tên cửa hàng nhưng parser vẫn chọn một hàng. Màn Review sẽ đánh dấu trường này để người dùng sửa.
- **OCR làm mất dấu `/` trong ngày** ("06/02026", "1207/2023") hoặc đọc 7 thành T → ngày `null`.
- **Ngày trong số hiệu văn bản pháp lý** ở đầu hóa đơn có thể bị lấy nhầm.
- **Hóa đơn tổng = 0** (giảm 100%) không biểu diễn được vì số tiền tối thiểu là 1.000 đ.
- **Thời gian OCR** (~5 giây) đo trên emulator x86_64, **không** dùng cho báo cáo hiệu năng; phải đo lại trên máy thật.
- Ảnh trong bộ đánh giá đã được xem khi sửa code → cần bộ ảnh mới để đo độ chính xác khách quan.

### Cách tự kiểm tra bằng tay

1. Mở emulator hoặc cắm điện thoại, rồi chạy đánh giá (tự kiểm tra hash, báo cáo ghi ra `D:\receipts-test\reports\`):
   ```powershell
   powershell -ExecutionPolicy Bypass -File tool\ocr_eval\run_ocr_eval.ps1                       # máy đầu tiên trong adb devices
   powershell -ExecutionPolicy Bypass -File tool\ocr_eval\run_ocr_eval.ps1 -DeviceId R58M12ABCDE
   ```
2. `flutter run` → tab **Quét** → mở màn debug OCR → chọn một ảnh hóa đơn → xem kết quả, mở "Xem văn bản OCR gốc".
3. Bật chế độ máy bay rồi quét lại: vẫn chạy (model ML Kit đóng gói trong APK).
4. Checklist đầy đủ: `docs/TEST_REPORT.md`, mục "Phase 3".

### Danh sách commit

```
18f299a fix(ocr): estimate skew from the dominant text direction
7a04bd7 fix(parser): skip table headers, read month names, clothes are Gear
17e6d79 fix(parser): tolerate misread total labels and cash printed as total
4ee3458 fix(parser): read decimal and OCR-split amounts, prefer real money
c74447e test(parser): add failing tests for patterns seen on real receipts
b0e0b8a docs(claude): mark phase 3 in progress
54eba91 fix(ocr): let the app read evaluation data pushed by adb
bd112b4 docs(readme): note that the regex table tool needs Python
d9e886c test(ocr): add one-command real-receipt OCR evaluation
a3babc5 feat(debug): add temporary OCR debug screen
4f89e1d feat(ocr): add receipt scan pipeline with failure handling
baaf321 feat(ocr): add ML Kit text recognition service and adapter
5f274d1 feat(ocr): deskew row grouping using text corner points
f981731 test(ocr): add rotated receipt fixtures and deskew tests
docs(phase-3): record phase 3 results   (commit cuối của phase)
```

---

## Phase 4 — CSDL & lưu ảnh

**Trạng thái:** ✅ hoàn tất (merge vào `main`, tag `phase-4`). ⚠ **Chưa chạy trên thiết bị**: phase này không bật emulator (máy 8 GB RAM); kiểm tra trên Android thật nằm trong checklist thủ công.

### Mục tiêu phase

Lưu giao dịch bền vững trên máy: bảng `expenses` trong SQLite, lớp repository cho CRUD và truy vấn, lưu ảnh hóa đơn kèm thumbnail vào thư mục của app, xóa giao dịch thì xóa luôn ảnh.

FR liên quan: **FR-5.1** (schema, version, `onUpgrade`), **FR-5.2** (CRUD qua `ExpenseRepository`), **FR-5.3** (lưu ảnh + thumbnail trong isolate), **FR-5.4** (xóa file ảnh; phần Undo làm ở Phase 5/8), NFR-2 (thumbnail ngoài UI thread).

### TDD trong lịch sử Git

| # | Commit | Trạng thái test |
|---|---|---|
| 1 | `test(db): add failing tests for database, repository and image storage` | 🔴 49 test mới không biên dịch được (chưa có 3 service) |
| 2 | `feat(db): open the expenses database with versioned migrations` | 🟢 10 test DB xanh |
| 3 | `feat(db): add ExpenseRepository with a sqflite implementation` | 🟢 22 test repository xanh |
| 4 | `feat(storage): save receipt photos with thumbnails made off the UI thread` | 🔴→🟢 lần chạy đầu 16/17: ảnh rác làm bộ giải mã ném `RangeError` chứ không trả `null` → sửa code để bắt mọi lỗi giải mã, test giữ nguyên |
| 5 | `style(db): drop arguments equal to their defaults` | 🔵 `dart fix` cho lint, giá trị test không đổi |
| 6 | `test(db): add on-device check for sqflite and photo storage` | integration test chạy trên Android (chưa chạy) |

### Đã làm gì

| File | Vai trò |
|---|---|
| `lib/services/database_service.dart` | `DatabaseService.open()`: mở `vku_expense.db`, tạo bảng `expenses` (version 1) và index trên cột `date`. `schemaMigrations` chứa SQL cho từng version sau này; `onCreate` chạy v1 rồi mọi bước, `onUpgrade` chỉ chạy bước còn thiếu. |
| `lib/services/expense_repository.dart` | Interface `ExpenseRepository` + `SqfliteExpenseRepository`: `insert`, `getAll` (mới nhất trước), `getById`, `update` (tự cập nhật `updatedAt`), `delete` (trả về bản ghi đã xóa để Undo), `getBetween` (khoảng ngày), `totalsByCategory` (SQL `SUM ... GROUP BY`). |
| `lib/services/image_storage_service.dart` | `ImageStorageService.save()`: copy ảnh vào `<documents>/receipts/`, tạo thumbnail JPEG rộng 256 px trong `Isolate.run`. `delete()` / `deleteFilesOf()`: xóa ảnh + thumbnail, bỏ qua file đã mất. Hàm thuần `createThumbnail()` để test. |
| `test/services/database_service_test.dart` | 10 test: kiểu cột, NOT NULL, AUTOINCREMENT, index, `onUpgrade`. |
| `test/services/sqflite_expense_repository_test.dart` | 22 test: CRUD, thứ tự, kiểu INTEGER, biên ngày, tổng theo danh mục. |
| `test/services/image_storage_service_test.dart` | 17 test: lưu, thumbnail, EXIF, lỗi, xóa, xóa giao dịch kèm ảnh (FR-5.4). |
| `integration_test/storage_test.dart` | Chạy sqflite thật + `path_provider` thật trên Android, dùng file DB và thư mục riêng rồi dọn sạch. |

### Vì sao làm vậy (liên hệ slide)

- **ID là `INTEGER PRIMARY KEY AUTOINCREMENT` (sửa lỗi slide W8 s28):** slide dùng `UniqueKey().toString()` làm ID; chuỗi đó không bền qua các lần chạy app và không sắp xếp được. `AUTOINCREMENT` còn bảo đảm ID của dòng đã xóa **không bị dùng lại**, nên `ValueKey(id)` ở danh sách (W7 s19–24) không bao giờ trỏ nhầm sang giao dịch khác.
- **`amount` là `INTEGER` (sửa lỗi slide: số tiền `double`):** VND không có phần lẻ. Test kiểm tra bằng `typeof(amount)` của SQLite chứ không chỉ đọc lại trong Dart.
- **Ngày lưu epoch ms (`INTEGER`):** so sánh và sắp xếp bằng số rất nhanh, có index. Lưu chuỗi `"09/10/2026"` thì sắp xếp sai (so sánh theo ký tự).
- **Future/async (W7 s17):** mọi thao tác DB và file đều trả `Future`, UI không bị chặn.
- **Isolate cho thumbnail (W7 s30, NFR-2):** giải mã một ảnh 12 MP có thể mất hàng trăm ms (chưa đo trên máy thật), trong khi một khung hình chỉ có 16 ms. Chỉ **hai đường dẫn** được gửi qua isolate; isolate tự đọc và ghi file, không phải chép hàng chục MB điểm ảnh qua lại.
- **Interface repository:** Phase 5 sẽ test state bằng repository giả mà không cần SQLite.
- **Lựa chọn đã cân nhắc:**
  - *Xóa file ảnh ngay trong `repository.delete`:* gọn nhưng làm hỏng Undo (ảnh đã mất khi người dùng bấm hoàn tác). Vì vậy tách thành hai bước (D-032).
  - *`onUpgrade` kiểu "xóa bảng tạo lại":* đơn giản nhưng **mất hết dữ liệu**. Dùng danh sách migration (D-030).
  - *Truy vấn `date BETWEEN start AND 23:59:59.999`:* dễ quên mili giây cuối. Dùng khoảng nửa mở `[0h ngày đầu, 0h ngày sau ngày cuối)` (D-031).
  - *Lưu ảnh dạng BLOB trong DB:* làm DB phình to, đọc danh sách chậm; FR-5.3 yêu cầu DB chỉ lưu đường dẫn.

### Khái niệm cần hiểu

- **Schema version và migration:** mỗi lần đổi cấu trúc bảng thì tăng `version`. sqflite so version trong file DB với version app yêu cầu: file mới thì gọi `onCreate`, file cũ hơn thì gọi `onUpgrade(old, new)`. Ở đây `onUpgrade` chạy lần lượt các bước `old+1 … new`.
- **Transaction và rollback:** sqflite chạy `onCreate`/`onUpgrade` trong một transaction. Nếu một bước lỗi thì mọi thay đổi bị hủy, DB giữ nguyên version cũ và dữ liệu cũ. Test "refuses to upgrade when a step is missing" chứng minh điều này.
- **Khoảng nửa mở `[a, b)`:** gồm `a`, không gồm `b`. Tuần T2–CN = `[0h T2, 0h T2 tuần sau)`. Không cần quan tâm giây hay mili giây cuối ngày.
- **`DateTime(2026, 12, 31 + 1)`:** Dart tự chuyển thành 01/01/2027, nên cộng một ngày không cần tự xử lý cuối tháng/năm.
- **EXIF orientation:** điện thoại thường lưu ảnh "nằm ngang" kèm một cờ "hãy xoay 90°". `bakeOrientation` xoay thật các điểm ảnh, để thumbnail hiện đúng chiều ở mọi nơi.
- **`Exception` và `Error` trong Dart:** `Exception` là lỗi dự kiến (file không có); `Error` thường là lỗi lập trình. Riêng bộ giải mã ảnh lại ném `RangeError` khi gặp file hỏng, nên ở đúng chỗ đó code bắt mọi lỗi và báo "ảnh bị hỏng".
- **`sqflite_common_ffi`:** chạy SQLite thật trên máy tính (qua FFI) với cùng API sqflite, nên test DB chạy trong vài giây mà không cần điện thoại.

### Kết quả kiểm thử

| Bước | Kết quả |
|---|---|
| `dart format --set-exit-if-changed lib test integration_test tool` | ✔ 0 thay đổi |
| `flutter analyze` | ✔ No issues found |
| `flutter test` | ✔ **321/321** (272 cũ + 49 mới) |
| `flutter test --coverage` | **95.5%** dòng (799/837); `database_service.dart` 19/21, `expense_repository.dart` 45/46, `image_storage_service.dart` 42/45 (dòng chưa phủ là đường dẫn mặc định cần nền tảng thật: `getDatabasesPath`, `path_provider`) |
| `flutter build apk --debug` | ✔ |
| Thiết bị | ⚠ **Chưa test trên thiết bị** (không bật emulator theo yêu cầu); `integration_test/storage_test.dart` chờ chạy |

Bảng ca biên chi tiết: `docs/TEST_REPORT.md`, mục "Phase 4 — Ca biên CSDL & lưu ảnh".

### Hạn chế đã biết

- Chưa kiểm chứng plugin sqflite và `path_provider` thật trên Android (chỉ FFI trên Windows).
- DB lưu **đường dẫn tuyệt đối**; trên iOS thư mục app có thể đổi sau khi cập nhật (D-035). Dự án chỉ nộp APK Android.
- Undo (FR-5.4) chưa có: Phase 5 thêm `restore` vào notifier, Phase 8 thêm SnackBar.
- Thời gian tạo thumbnail chưa đo trên máy thật.

### Cách tự kiểm tra bằng tay

1. Chạy riêng test DB và ảnh:
   ```powershell
   flutter test test/services/database_service_test.dart test/services/sqflite_expense_repository_test.dart test/services/image_storage_service_test.dart
   ```
2. Thử phá để thấy test bắt lỗi: trong `expense_repository.dart`, đổi `<` thành `<=` ở `_inDayRange` rồi chạy lại. Test "a single day covers that whole day only" sẽ fail vì giao dịch lúc 00:00 hôm sau bị tính vào. Hoàn tác bằng `git checkout -- lib`.
3. Khi có điện thoại: `flutter test integration_test/storage_test.dart -d <máy>`.
4. Checklist đầy đủ: `docs/TEST_REPORT.md`, mục "Phase 4".

### Danh sách commit

```
f3d2b10 test(db): add on-device check for sqflite and photo storage
8e353ac style(db): drop arguments equal to their defaults
d915528 feat(storage): save receipt photos with thumbnails made off the UI thread
50c5f52 feat(db): add ExpenseRepository with a sqflite implementation
5ae7d40 feat(db): open the expenses database with versioned migrations
f034d34 test(db): add failing tests for database, repository and image storage
docs(phase-4): record phase 4 results   (commit cuối của phase)
```

---

## Phase 5 — State management (Riverpod 2)

**Trạng thái:** ✅ hoàn tất (merge vào `main`, tag `phase-5`). ⚠ **Chưa chạy trên thiết bị** (không bật emulator theo yêu cầu); `flutter_riverpod` giữ **2.6.1**.

### Mục tiêu phase

Đặt toàn bộ "app state" vào Riverpod: danh sách giao dịch, các tổng dẫn xuất cho Dashboard và biểu đồ, tuần/tháng đang chọn, chế độ sáng/tối được lưu, trạng thái quét. Hoàn tất phần logic của FR-5.4: xóa có Undo, ảnh chỉ bị xóa khi hết thời gian Undo, và dọn ảnh mồ côi khi khởi động.

FR liên quan: **FR-5.4** (logic Undo + xóa ảnh), **FR-6.5** (dữ liệu tự cập nhật cho biểu đồ), **FR-8.1** (themeMode được lưu), **FR-8.4** (`AsyncValue` cho loading/lỗi).

### TDD trong lịch sử Git

| # | Commit | Trạng thái test |
|---|---|---|
| 1 | `test(state): add failing tests for Riverpod state and derived totals` | 🔴 62 test mới không biên dịch được |
| 2 | `feat(core): add calendar ranges and weekly / category totals` | 🟢 test tuần/danh mục xanh |
| 3 | `feat(storage): sweep orphan receipt photos and add a settings store` | 🟢 test dọn rác, kho cài đặt xanh |
| 4 | `feat(state): add expense list notifier with an Undo window` | 🟢 18 test danh sách + Undo, 7 test tuần/tháng xanh |
| 5 | `feat(state): save the theme mode and track scan states` | 🟢 test theme, quét xanh |
| 6 | `feat(app): open storage and sweep orphan photos before the first frame` | 🟢 383/383 |

Thay đổi ở test cũ: `test/app_router_test.dart` chỉ thêm override kho cài đặt (vì app giờ đọc chế độ sáng/tối đã lưu), không đổi assertion. `test/models/expense_totals_test.dart` được `dart fix` bỏ tham số trùng mặc định, giá trị giữ nguyên.

### Đã làm gì

| File | Vai trò |
|---|---|
| `lib/state/storage_providers.dart` | Các phụ thuộc thay được trong test: `clockProvider`, `databaseProvider` (mở trong `main()`), `expenseRepositoryProvider`, `imageStorageProvider`, `settingsStoreProvider`. |
| `lib/state/expense_providers.dart` | `expenseListProvider` (`AsyncNotifier`): `add`, `edit`, `remove`, `restore`, `commitDeletion`. `selectedMonthProvider`, `selectedWeekProvider` (có `previous/next/select/showCurrent`). Dẫn xuất: `monthExpensesProvider`, `categoryTotalsProvider`, `monthTotalProvider`, `weeklyTotalsProvider`. |
| `lib/state/theme_mode_provider.dart` | `themeModeProvider`: đọc lựa chọn đã lưu, `select(mode)` áp dụng ngay rồi lưu. `app.dart` truyền vào `MaterialApp.themeMode`. |
| `lib/state/scan_controller.dart` | `scanControllerProvider`: `sealed class ScanState` gồm `ScanIdle`, `ScanProcessing`, `ScanCompleted` (result), `ScanFailed` (error). |
| `lib/state/app_startup.dart` | `createStartupOverrides()`: mở DB, `SharedPreferences`, dọn ảnh mồ côi, trả về override cho `ProviderScope`. |
| `lib/core/date_ranges.dart` | Đầu ngày / đầu tuần (Thứ Hai) / đầu tháng, cộng ngày/tháng theo giờ địa phương. |
| `lib/models/weekly_totals.dart`, `category_totals.dart` | Tổng 7 ngày và tổng 5 danh mục kèm tỷ lệ; so sánh bằng giá trị (cho `shouldRepaint` ở Phase 9). |
| `lib/services/settings_store.dart` | Interface `SettingsStore` + bản dùng `shared_preferences`. |
| `lib/services/image_storage_service.dart` | Thêm `deleteUnreferenced()`: xóa file trong `receipts/` không còn bản ghi nào trỏ tới. |
| `test/support/` | `FakeExpenseRepository` (trong bộ nhớ), `FakeImageStorage` (ghi lại file bị yêu cầu xóa), `MemorySettingsStore`. Chỉ nằm trong `test/`. |

### Vòng đời một lần xóa (FR-5.4, D-032)

```
vuốt xóa ──► remove(id) ──► state bỏ id NGAY (đồng bộ) ──► DB xóa dòng ──► hẹn giờ 5 s
                                                                      │
              ┌──────────── bấm "Hoàn tác" trong 5 s ─────────────────┤
              ▼                                                       ▼
        restore(id): hủy hẹn giờ,                       hết 5 s / SnackBar đóng / app đóng:
        chèn lại đúng dòng cũ (cùng id),                xóa ảnh + thumbnail
        ảnh vẫn còn nguyên
```

Nếu app bị tắt đột ngột trong 5 s đó, ảnh thành "mồ côi". Lần mở app sau, `createStartupOverrides` xóa các ảnh này trước khi hiện giao diện.

### Vì sao làm vậy (liên hệ slide)

- **Ephemeral vs App state (W8 s4–6):** danh sách giao dịch, tuần/tháng đang chọn, chế độ sáng/tối là app state (nhiều màn cùng dùng) → Riverpod. Flash, vòng lấy nét ở Phase 6 vẫn là `setState`.
- **`AsyncNotifier`, `ref.watch/read`, `AsyncValue` (W8 s14–18):** `build()` tải dữ liệu; provider dẫn xuất dùng `whenData`, nên trạng thái loading/lỗi của danh sách tự lan sang mọi tổng (FR-8.4).
- **Declarative UI = f(state) (W7 s5):** Dashboard và biểu đồ chỉ đọc `categoryTotalsProvider`/`weeklyTotalsProvider`; thêm/sửa/xóa ở bất kỳ đâu thì chúng tự vẽ lại (FR-6.5). Không có chỗ nào phải "nhớ gọi refresh".
- **Pattern matching / sealed class (W7 s14):** `ScanState` là `sealed`; một `switch` ở màn quét (Phase 6) thiếu trạng thái nào sẽ là lỗi biên dịch.
- **Lựa chọn đã cân nhắc:**
  - *Lưu theme bằng bảng `settings` (migration version 2):* thử được đường `onUpgrade` thật, nhưng một cài đặt không đáng để đổi schema FR-5.1. Chọn `shared_preferences` (D-036).
  - *Xóa ảnh ngay khi xóa dòng:* đơn giản nhưng Undo sẽ trả về bản ghi mất ảnh.
  - *Tổng theo danh mục bằng SQL `SUM`:* nhanh với dữ liệu lớn, nhưng phải tự gọi lại sau mỗi thao tác. Tính trong Dart từ một danh sách duy nhất thì luôn đúng (D-043).
  - *`FutureProvider` mở DB:* mọi provider phía sau phải xử lý loading của DB. Mở trong `main()` rồi override thì gọn hơn (D-038).

### Khái niệm cần hiểu

- **Provider dẫn xuất:** provider tính từ provider khác. `monthTotalProvider` ← `categoryTotalsProvider` ← `monthExpensesProvider` ← (`expenseListProvider` + `selectedMonthProvider`). Đổi tháng hay thêm giao dịch thì cả chuỗi tự tính lại.
- **Override:** thay giá trị của một provider trong một phạm vi. App thật override `databaseProvider` bằng DB đã mở; test override `expenseRepositoryProvider` bằng repository giả.
- **`ProviderContainer`:** "ProviderScope không cần widget", dùng trong unit test để đọc provider và gọi notifier.
- **`fakeAsync`:** chạy code trong một "đồng hồ giả". `async.elapse(Duration(seconds: 5))` cho hẹn giờ 5 s nổ ngay lập tức, nên test Undo không phải chờ thật.
- **Khoảng nửa mở cho tuần:** `[T2 00:00, T2 tuần sau 00:00)`. CN 23:59:59.999 nằm trong, T2 00:00 tuần sau nằm ngoài.
- **Số thế hệ (generation) trong `ScanController`:** mỗi lần quét hoặc hủy thì tăng một số đếm. Kết quả OCR trả về muộn chỉ được nhận nếu số đếm chưa đổi, nên hủy giữa chừng không bị kết quả cũ ghi đè.

### Kết quả kiểm thử

| Bước | Kết quả |
|---|---|
| `dart format --set-exit-if-changed lib test integration_test tool` | ✔ 0 thay đổi |
| `flutter analyze` | ✔ No issues found |
| `flutter test` | ✔ **383/383** (321 cũ + 62 mới) |
| `flutter test --coverage` | **95.0%** dòng (1003/1056); `scan_controller.dart` 22/22, `theme_mode_provider.dart` 7/7, `date_ranges.dart` 12/12, `expense_providers.dart` 80/85 |
| `flutter build apk --debug` | ✔ |
| Kiểm tra test bắt lỗi | Cố ý đặt hẹn giờ Undo = 0 s → 3 test đỏ; cố ý sai biên cuối tuần → 4 test đỏ; đã khôi phục |
| Thiết bị | ⚠ **Chưa test trên thiết bị** |

Phân bổ 62 test mới: danh sách + Undo 18 · tổng tuần/danh mục 10 · mốc ngày 7 · tuần/tháng đang chọn 7 · quét 7 · theme 4 + 1 widget · dọn ảnh mồ côi 4 · kho cài đặt 2 · khởi động 2. Bảng ca biên: `docs/TEST_REPORT.md`, mục "Phase 5".

### Hạn chế đã biết

- Chưa chạy trên Android: `main()` giờ mở DB và `SharedPreferences` trước `runApp`, cần xác nhận trên máy thật (đã ghi vào Việc còn nợ).
- Nếu mở DB thất bại khi khởi động, app chưa có màn hình lỗi riêng (sẽ xem lại ở Phase 10).
- Chưa có UI dùng các provider này: SnackBar Undo (Phase 8), nút chuyển theme (Phase 10), màn quét (Phase 6).
- Tổng được tính lại từ toàn bộ danh sách mỗi khi danh sách đổi; phù hợp dữ liệu cá nhân, không tối ưu cho hàng chục nghìn dòng.

### Cách tự kiểm tra bằng tay

1. Chạy riêng test state:
   ```powershell
   flutter test test/state
   ```
2. Xem `fakeAsync` hoạt động: trong `expense_providers.dart`, đổi `undoWindow` thành `Duration(seconds: 10)` rồi chạy `flutter test test/state/expense_list_notifier_test.dart`. Test vẫn dùng đúng hằng số nên vẫn xanh, và vẫn chạy tức thì. Hoàn tác bằng `git checkout -- lib`.
3. Khi có điện thoại: `flutter run`, đổi dark mode trong cài đặt điện thoại, đóng hẳn rồi mở lại app.

### Danh sách commit

```
cc8aeda feat(app): open storage and sweep orphan photos before the first frame
e78faf4 feat(state): save the theme mode and track scan states
240b4af feat(state): add expense list notifier with an Undo window
2a9e914 feat(storage): sweep orphan receipt photos and add a settings store
3f7ce51 feat(core): add calendar ranges and weekly / category totals
2513af0 test(state): add failing tests for Riverpod state and derived totals
docs(phase-5): record phase 5 results   (commit cuối của phase)
```

---

## Phase 6 — Camera capture

**Trạng thái:** ✅ hoàn tất phần code (merge vào `main`, tag `phase-6`). ⚠ FR-1: **code + test máy tính xong, CHƯA xác minh trên điện thoại thật**. Đã smoke test 1 lần trên emulator + webcam.

### Mục tiêu phase

Thay tab Quét giữ chỗ bằng màn camera thật: preview trực tiếp, flash, chạm lấy nét, khung căn chỉnh, chụp rồi cắt theo khung, chỉnh tay bằng `image_cropper`, chọn ảnh thư viện, xử lý quyền. Sau đó chạy OCR và mở màn Review.

FR liên quan: **FR-1.1 → FR-1.7**, NFR-3 (vòng đời camera), NFR-2 (cắt ảnh trong isolate).

### TDD trong lịch sử Git

| # | Commit | Trạng thái test |
|---|---|---|
| 1 | `test(camera): add failing tests for capture, frame crop and camera UI` | 🔴 55 test mới không biên dịch được |
| 2 | `feat(camera): map the receipt frame onto the captured photo` | 🟢 17 test hình học xanh ngay lần đầu |
| 3 | `feat(camera): crop photos upright to the frame on a background isolate` | 🔴→🟢 test thuần kỳ vọng sai: bộ giải mã JPEG của gói `image` **đã tự xoay theo EXIF**. Sửa test cho đúng hành vi thư viện (D-047); 4 test ảnh EXIF thật giữ nguyên |
| 4 | `feat(camera): wrap the camera plugin behind a testable interface` | 🟢 9 test lớp bọc camera |
| 5 | `feat(camera): draw the receipt frame overlay with CustomPainter` | 🔴→🟢 test vẽ đặt `SizedBox` sai chỗ (bị ép theo màn test 800×600); sửa bố cục test |
| 6 | `feat(scan): add the camera screen with frame crop, flash and focus` | 🔴→🟢 hai lỗi: vòng xoay "đang xử lý" chạy sau hộp thoại (lỗi giao diện thật, sửa code); `app_router_test` chạm vào plugin camera thật (thêm camera giả vào phần chuẩn bị) |
| 7 | `build(deps): pin permission_handler to 12.x for compileSdk 36` | build debug lỗi với 13.x (đòi compileSdk 37) → ghim 12.0.3 |
| 8 | `test(camera): add an on-device camera smoke test` | chạy 1 lần trên emulator + webcam: pass |

### Đã làm gì

| File | Vai trò |
|---|---|
| `lib/screens/scan/camera_screen.dart` | `CameraScreen` (thay `scan_screen.dart`): preview `cover`, khung căn chỉnh, nút flash, chạm lấy nét có vòng chỉ báo, nút chụp, nút thư viện, các màn lỗi (thiếu quyền / không có camera / lỗi khác), xử lý vòng đời. |
| `lib/services/camera_service.dart` | Interface `ReceiptCamera` + `CameraSource`, bản chạy thật `PluginReceiptCamera` (`enableAudio: false`, `ResolutionPreset.veryHigh`), `CaptureFlash`, `CameraFailure` (sealed) và hàm ánh xạ mã lỗi plugin. |
| `lib/core/frame_geometry.dart` | Hàm thuần: khung hình hóa đơn, vị trí `BoxFit.cover`, điểm chạm → tọa độ preview, khung → vùng cắt trên ảnh (có xoay EXIF, padding, kẹp mép). |
| `lib/services/image_crop_service.dart` | Giải mã → xoay đứng → cắt → JPEG, chạy trong `Isolate.run`; bản không cắt cho ảnh thư viện. |
| `lib/services/manual_cropper.dart` | Interface `ManualCropper` + bản dùng `image_cropper` (uCrop). |
| `lib/widgets/receipt_frame_overlay.dart` | `ReceiptFramePainter`: lớp tối có lỗ hình hóa đơn + góc đánh dấu. |
| `lib/state/camera_providers.dart` | Provider cho nguồn camera, dịch vụ cắt, màn chỉnh tay, `openAppSettings`. |
| `lib/core/router.dart`, `review_screen.dart` | `/review` nhận thêm `ScanResult` qua `extra` (ảnh, kết quả parse, thời gian OCR) cho Phase 7. |
| `integration_test/camera_smoke_test.dart` | Smoke test trên máy/emulator: preview → chụp → cắt → OCR thật → Review. |
| `test/support/fake_camera.dart` | Camera giả, nguồn camera giả, dịch vụ cắt giả, màn chỉnh tay giả (chỉ trong `test/`). |

### Luồng chụp một hóa đơn

```
[preview + khung] ──chụp──► ảnh gốc (EXIF) ──Isolate: xoay đứng + cắt theo khung (+3%)──► ảnh cắt
      ▲                                                                                   │
      │                                                                     image_cropper (chỉnh tay)
      │  quay lại: mở camera lại                                              │ Hủy → "Đã hủy quét."
      │                                                                       ▼
      └──────────── Review ◄── ScanCompleted ◄── OCR + parse (scanControllerProvider)
                       ▲
                       └── ScanFailed → hộp thoại "Nhập tay" (Review kèm ảnh, các trường trống)
```

Camera được **trả** (dispose) trước bước chỉnh tay và mở lại khi quay về, vì OCR và màn Review cần bộ nhớ.

### Vì sao làm vậy (liên hệ slide)

- **Thêm gói `camera` (sửa lỗi slide W7 s42–43):** slide chỉ dùng `image_picker`, không có preview trực tiếp, flash hay lấy nét. `image_picker` vẫn được giữ làm đường vào phụ (FR-1.6).
- **Stack + CustomPainter (W7 s32–39, W8 s30–34):** preview, lớp tối, vòng lấy nét và thanh nút là các lớp chồng nhau trong `Stack`. Lớp tối là một `Path` kiểu even-odd: hình chữ nhật ngoài trừ đi khung, nên khung "trong suốt".
- **Ephemeral state (W8 s4–6):** flash, vòng lấy nét, trạng thái camera chỉ màn này cần → `setState`. Kết quả quét dùng ở màn khác → `scanControllerProvider` (Riverpod).
- **Lifecycle và `dispose()` (W7 s26–29, NFR-3):** `WidgetsBindingObserver` trả camera khi app vào nền và mở lại khi quay về; `dispose()` của màn luôn đóng camera.
- **Tính toán nặng ngoài `build()` (W7 s30):** giải mã/xoay/cắt ảnh 12 MP chạy trong `Isolate.run`.
- **Interface cho camera:** widget test chạy với camera giả trên máy tính; trên máy thật mới dùng `CameraController`.
- **Lựa chọn đã cân nhắc:**
  - *Khóa màn camera ở hướng dọc:* đơn giản hóa phép quy đổi, nhưng FR-8.2 yêu cầu màn ngang không lỗi. Thay vào đó tỷ lệ preview được tính theo hướng máy, giống `CameraPreview`.
  - *Đưa ảnh gốc cho `image_cropper` tự chọn vùng:* plugin không nhận vùng cắt khởi tạo, người dùng phải kéo lại từ đầu. Tự cắt theo khung trước (D-049).
  - *Kiểm tra quyền trước bằng `permission_handler`:* thừa, vì plugin `camera` tự xin quyền và báo `CameraAccessDenied`. Chỉ dùng `openAppSettings()`.

### Khái niệm cần hiểu

- **BoxFit.cover:** phóng ảnh cho tới khi **phủ kín** khung, phần thừa ở hai cạnh bị cắt. Preview 9:16 trên màn 20:9 bị cắt bớt hai bên, nên điểm chạm ở mép màn **không** phải mép của preview. `FrameGeometry.coverRect` tính đúng phần bị cắt này.
- **Ba hệ tọa độ:** viewport (điểm logic trên màn) → preview (luồng camera) → ảnh (điểm ảnh thật). Khung vẽ trên màn phải đi qua cả ba mới ra vùng cắt đúng trên ảnh.
- **EXIF orientation:** camera thường lưu ảnh "nằm ngang" kèm tag "xoay 90° để xem". Phải xoay trước khi cắt, nếu không vùng cắt sẽ lệch sang chỗ khác. Gói `image` tự xoay ảnh JPEG khi giải mã.
- **`AppLifecycleState`:** `inactive` (mất focus, ví dụ có hộp thoại hệ thống), `paused` (vào nền), `resumed` (quay lại). Camera là tài nguyên dùng chung: giữ nó khi app ở nền sẽ khiến app khác không mở được camera.
- **`TickerMode`:** widget cho biết cây con có đang "được hiển thị" hay không. `StatefulShellRoute.indexedStack` giữ mọi tab sống nhưng tắt `TickerMode` ở tab bị ẩn, nên màn camera biết khi nào cần trả camera.
- **Số thế hệ (generation):** camera mở chậm (xin quyền, khởi tạo). Nếu trong lúc đó người dùng rời tab, camera mở xong sẽ bị đóng ngay thay vì được dùng.

### Kết quả kiểm thử

| Bước | Kết quả |
|---|---|
| `dart format --set-exit-if-changed lib test integration_test tool` | ✔ 0 thay đổi |
| `flutter analyze` | ✔ No issues found |
| `flutter test` | ✔ **438/438** (383 cũ + 55 mới) |
| `flutter test --coverage` | **91.5%** dòng (1400/1530); `frame_geometry.dart` 49/49, `receipt_frame_overlay.dart` 30/30, `camera_screen.dart` 257/283. Thấp nhất: `camera_service.dart` 26/60 và `manual_cropper.dart` 1/7, là phần gọi plugin thật chỉ chạy được trên máy |
| `flutter build apk --debug` | ✔ (sau khi ghim `permission_handler` 12.0.3) |
| Smoke test **emulator + webcam** (1 lần) | ✔ preview → chụp → cắt 418×672 → OCR 11.275 ms (0 hàng chữ, webcam không nhìn vào hóa đơn) → Review sau 26.775 ms |
| Điện thoại thật | ⚠ **Chưa xác minh** |

Phân bổ 55 test mới: hình học 17 · cắt ảnh 8 · overlay 3 · lớp bọc camera 9 · màn camera 17 · router 1. Bảng chi tiết: `docs/TEST_REPORT.md`, mục "Phase 6".

### Hạn chế đã biết

- Chưa thử trên điện thoại: tỷ lệ preview, vùng cắt có khớp khung không, flash, lấy nét, `image_cropper`, quyền, vòng đời (checklist trong CLAUDE.md, mục Việc còn nợ).
- Phép quy đổi khung giả định ảnh chụp và preview cùng khung nhìn (D-046). Máy nào cho ảnh chụp khác tỷ lệ preview có thể bị lệch vài phần trăm; padding 3% chỉ bù được một phần.
- Máy không có flash chỉ được phát hiện khi bấm nút flash lần đầu (D-045).
- Smoke test trên emulator không thử `image_cropper` (activity native) và không có hóa đơn thật trước webcam.
- Màn debug OCR (Phase 3) vẫn còn, mở từ nút trên AppBar; sẽ xóa ở Phase 7.

### Cách tự kiểm tra bằng tay

1. Chạy test camera trên máy tính:
   ```powershell
   flutter test test/core/frame_geometry_test.dart test/services/image_crop_service_test.dart test/screens/camera_screen_test.dart
   ```
2. Thử phép quy đổi: trong `frame_geometry_test.dart`, đổi `padding: 0` của ví dụ 20:9 thành `0.03` rồi chạy lại, xem vùng cắt rộng thêm bao nhiêu.
3. Trên điện thoại: làm checklist "Phase 6" trong `docs/TEST_REPORT.md`, rồi chạy `flutter test integration_test/camera_smoke_test.dart -d <máy>` với một hóa đơn thật trước camera.
4. Trên emulator có webcam: xem `docs/SETUP_ENV.md` mục 12.

### Danh sách commit

```
58643b9 test(camera): add an on-device camera smoke test
dca6e0e build(deps): pin permission_handler to 12.x for compileSdk 36
9f7a484 feat(scan): add the camera screen with frame crop, flash and focus
e4deea9 feat(camera): draw the receipt frame overlay with CustomPainter
b804a12 feat(camera): wrap the camera plugin behind a testable interface
0f78e93 feat(camera): crop photos upright to the frame on a background isolate
8f8f6b0 feat(camera): map the receipt frame onto the captured photo
cfd883d test(camera): add failing tests for capture, frame crop and camera UI
docs(phase-6): record phase 6 results   (commit cuối của phase)
```

---

## Phase 7 — Màn Review & Verification

**Trạng thái:** ✅ hoàn tất (merge vào `main`, tag `phase-7`). ⚠ **Chưa thử trên thiết bị** (không bật emulator theo yêu cầu); mọi kiểm thử là widget test trên máy tính.

### Mục tiêu phase

Màn hình bắt buộc của đề: người dùng **kiểm tra lại** dữ liệu OCR trước khi lưu. Cùng một màn dùng cho ba việc: xác nhận hóa đơn vừa quét, thêm thủ công, sửa giao dịch đã lưu. Hoàn tất phần còn dở của FR-2.4 (hiện thời gian OCR) và FR-4.5 (văn bản OCR gốc), và gỡ màn debug tạm của Phase 3.

FR liên quan: **FR-4.1 → FR-4.9**, **FR-2.4**, **FR-4.5**.

### TDD trong lịch sử Git

| # | Commit | Trạng thái test |
|---|---|---|
| 1 | `test(review): add failing tests for the Review & Verification screen` | 🔴 55 test mới không biên dịch được |
| 2 | `feat(core): format VND amounts while typing and validate the form` | 🟢 22 test ô số tiền + validator xanh ngay lần đầu |
| 3 | `feat(state): save a reviewed expense with its photo, cleaning up on failure` | 🟢 4 test lưu an toàn xanh |
| 4 | `feat(review): add the Review & Verification form in its three modes` | 🔴→🟢 lần chạy đầu 12 test đỏ. **Lỗi thật trong code:** form dùng `ListView` nên các trường dưới chưa được dựng, và `Form.validate()` bỏ qua chúng → đổi sang `SingleChildScrollView` + `Column`. **Lỗi trong test mới:** 2 test dán số tiền đọc nhầm giao dịch có sẵn; 2 test hủy bấm back trong cùng khung hình với lúc gõ (thêm `pump()`); test màn nhỏ chạm vào ô nằm ngoài màn (thêm `ensureVisible`) |
| 5 | `refactor(scan): remove the temporary OCR debug screen` | 🟢 489/489 |

Ghi chú lịch sử Git: lần commit đầu, việc xóa hai file debug (đã `git rm` từ trước) bị lọt vào commit `feat(core)`, làm commit đó không build được. Vì nhánh chưa merge, đã `git reset --soft` về commit test rồi commit lại đúng nội dung (không dùng `rebase -i`, không `--amend` commit đã merge).

### Đã làm gì

| File | Vai trò |
|---|---|
| `lib/screens/review/review_screen.dart` | `ReviewScreen`: chọn chế độ; chế độ sửa đọc giao dịch từ `expenseListProvider` (`AsyncValue.when`: đang tải / lỗi / không tìm thấy). `_ReviewForm`: `Form` + `GlobalKey<FormState>`, ô tên, ô số tiền, chọn ngày, chip danh mục, dấu độ tin cậy, ảnh, văn bản OCR, nút Lưu, `PopScope` hỏi khi hủy. |
| `lib/screens/review/review_draft.dart` | `ReviewMode` (scan / manual / edit) và `ReviewDraft`: giá trị khởi đầu của form cho từng chế độ (ngày thiếu → gợi ý hôm nay nhưng vẫn đánh dấu "missing"). |
| `lib/core/amount_input.dart` | `AmountInput.parse/format` và `VndAmountInputFormatter` (FR-4.6). |
| `lib/core/expense_validators.dart` | Validator của bốn trường, thông báo tiếng Việt (FR-4.3). |
| `lib/widgets/confidence_note.dart` | `ConfidenceNote` (icon + chú thích dưới trường) và `MerchantWarningBanner` (banner đầu form cho tên cửa hàng). |
| `lib/widgets/receipt_image_view.dart` | Ảnh hóa đơn; chạm → xem toàn màn với `InteractiveViewer` (FR-4.1). |
| `lib/state/expense_providers.dart` | `addWithPhoto`: lưu ảnh + thumbnail → ghi DB; ghi DB lỗi thì xóa ảnh vừa lưu. |
| `lib/widgets/ocr_text_panel.dart` | Thời gian OCR thành tùy chọn (chế độ sửa không có). |
| Đã xóa | `lib/screens/debug/ocr_debug_screen.dart`, route `/debug/ocr`, nút debug ở màn camera, `test/screens/ocr_debug_screen_test.dart`. |

### Lưu an toàn (yêu cầu 5)

```
Lưu ─► validate() ─► ImageStorageService.save (ảnh + thumbnail)
                         │ lỗi ảnh → báo lỗi, KHÔNG ghi DB
                         ▼
                     repository.insert
                         │ lỗi DB → xóa ảnh + thumbnail vừa lưu → báo lỗi, màn hình vẫn mở
                         ▼
                     SnackBar "Đã lưu giao dịch." → quay về
```

### Vì sao làm vậy (liên hệ slide)

- **Form, `GlobalKey<FormState>`, validator, `FocusNode` (W8 s26–28):** đúng mẫu của slide; thêm `TextInputAction.next` để chuyển ô và `dispose()` mọi controller/focus node (W7 s26–29).
- **Ephemeral state:** giá trị đang nhập, dấu độ tin cậy, trạng thái "đang lưu" chỉ màn này cần → `setState`. Danh sách giao dịch là app state → lưu qua notifier, Dashboard và Lịch sử tự cập nhật (FR-6.5).
- **Pattern matching (W7 s14):** chọn chế độ bằng `switch ((scan, receipt))`; icon/chú thích theo độ tin cậy bằng `switch` trên enum.
- **Null safety (W7 s12):** `ParsedReceipt` có trường null khi không đọc được; form xử lý bằng `??` và `case final x?` thay vì `!`.
- **Lựa chọn đã cân nhắc:**
  - *`ListView` cho form dài:* nhẹ hơn, nhưng `Form.validate()` bỏ qua trường chưa dựng (D-051).
  - *Chỉ tô màu viền trường không chắc chắn:* không đủ cho người khó phân biệt màu, nên luôn kèm icon và chữ (D-052).
  - *Dùng `NumberFormat` của `intl` trong bộ định dạng ô số tiền:* phải đồng bộ locale và khó kiểm soát vị trí con trỏ. Tự chèn dấu chấm thì đơn giản và thuần.
  - *Cho phép lưu 0 đ (hóa đơn giảm giá toàn bộ):* đề yêu cầu "số nguyên dương", nên vẫn chặn và giải thích lý do trong thông báo.

### Khái niệm cần hiểu

- **`TextInputFormatter`:** chạy mỗi lần nội dung ô thay đổi, nhận giá trị cũ và mới (gồm cả vị trí con trỏ) và trả về giá trị sẽ hiển thị. Để con trỏ không nhảy: đếm số **chữ số** đứng trước con trỏ, định dạng lại, rồi đặt con trỏ sau đúng số chữ số đó.
- **`PopScope`:** chặn việc rời màn. `canPop: false` thì nút back (AppBar, Android, cử chỉ) không đóng màn mà gọi `onPopInvokedWithResult`, nơi ta hỏi xác nhận. `Navigator.pop()` gọi trực tiếp thì không bị chặn, nên dùng sau khi lưu thành công.
- **`FormField<T>`:** biến mọi widget (bộ chọn ngày, hàng chip) thành một trường của `Form`, có `validator` và `errorText` như `TextFormField`.
- **Dựng lười (lazy) của `ListView`:** chỉ dựng phần tử gần màn hình. Phần tử chưa dựng thì không có `State`, nên `Form` không biết tới nó.
- **Dọn dẹp khi thất bại (rollback thủ công):** ảnh nằm trên ổ đĩa, DB là SQLite, hai nơi không chung một transaction. Vì vậy phải tự xóa ảnh khi bước ghi DB thất bại.

### Kết quả kiểm thử

| Bước | Kết quả |
|---|---|
| `dart format --set-exit-if-changed lib test integration_test tool` | ✔ 0 thay đổi |
| `flutter analyze` | ✔ No issues found |
| `flutter test` | ✔ **489/489** (438 cũ − 4 test màn debug đã xóa + 55 mới) |
| `flutter test --coverage` | **92.8%** dòng (1731/1866); `review_screen.dart` 232/235, `review_draft.dart` 40/40, `expense_validators.dart` 14/14, `confidence_note.dart` 39/39, `amount_input.dart` 53/55 |
| `flutter build apk --debug` | ✔ |
| Kiểm tra test bắt lỗi | Bỏ bước xóa ảnh khi DB lỗi → 2 test đỏ; `canPop: true` → 2 test hủy đỏ; đã khôi phục |
| Thiết bị | ⚠ **Chưa test trên thiết bị** |

Phân bổ 55 test mới: màn Review 28 · ô số tiền 11 · validator 11 · lưu an toàn 4 · khung văn bản OCR 1. Bảng chi tiết: `docs/TEST_REPORT.md`, mục "Phase 7".

### Hạn chế đã biết

- Chưa thử trên máy thật: bàn phím số, bộ chọn ngày tiếng Việt, phóng to ảnh, lưu ảnh thật (checklist Phase 7 trong `docs/TEST_REPORT.md`).
- Hủy khi **chưa sửa** gì sau khi quét thì không hỏi (đúng FR-4.8), nên ảnh cắt tạm còn nằm trong thư mục cache cho tới khi hệ điều hành dọn.
- Chế độ sửa không đổi được ảnh hóa đơn (chỉ xem); muốn thay ảnh thì xóa và quét lại.
- Văn bản dán có phần thập phân viết bằng dấu chấm cả hai chỗ (ví dụ "150.000.00") sẽ bị đọc thành 15000000; hiếm gặp, và người dùng nhìn thấy số ngay trong ô.

### Cách tự kiểm tra bằng tay

1. Chạy test của màn Review:
   ```powershell
   flutter test test/screens/review_screen_test.dart test/core/amount_input_test.dart test/core/expense_validators_test.dart
   ```
2. Thử phá: trong `review_screen.dart`, đổi `SingleChildScrollView` + `Column` lại thành `ListView` rồi chạy test, xem những test nào đỏ và vì sao.
3. Trên điện thoại: làm checklist "Phase 7" trong `docs/TEST_REPORT.md`.

### Danh sách commit

```
14b3b6b refactor(scan): remove the temporary OCR debug screen
b35b1f1 feat(review): add the Review & Verification form in its three modes
72ee993 feat(state): save a reviewed expense with its photo, cleaning up on failure
b31f433 feat(core): format VND amounts while typing and validate the form
308713f test(review): add failing tests for the Review & Verification screen
docs(phase-7): record phase 7 results   (commit cuối của phase)
```
