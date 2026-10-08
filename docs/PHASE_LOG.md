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
