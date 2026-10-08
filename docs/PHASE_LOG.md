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
