# Nhật ký học tập theo Phase

> Viết cho sinh viên đọc lại để hiểu **đã làm gì, vì sao, và tự kiểm tra thế nào**.
> Mỗi phase một mục. Thuật ngữ kỹ thuật giữ tiếng Anh khi cần, kèm giải thích.

---

## Phase 0 — Khởi tạo & môi trường

**Trạng thái:** 🟥 đang bị chặn (B-001 — chưa cài Flutter SDK). Mục này sẽ được viết tiếp khi phase hoàn tất.

### Mục tiêu phase

- Kiểm tra công cụ: Flutter 3.x / Dart 3, Android SDK, JDK + `keytool`, git.
- Dựng khung project Flutter (`flutter create`), repo git, `.gitignore` an toàn (không lộ keystore, APK…).
- Tạo `CLAUDE.md` — "bộ não" của dự án: quy tắc, yêu cầu đóng băng (FROZEN), kế hoạch phase, nhật ký tiến độ, quyết định kỹ thuật, blocker.
- Bật lint chặt hơn để code sạch ngay từ đầu (NFR-5).
- Chưa có FR nào được hiện thực ở phase này; đây là nền móng cho NFR-4, NFR-5.

### Đã làm gì (tới thời điểm hiện tại)

| File | Vai trò |
|---|---|
| `CLAUDE.md` | Quy tắc làm việc, Requirements FROZEN (chép nguyên văn từ brief bằng script để không sai một ký tự), bản đồ slide → code, lỗi slide, kế hoạch phase có checklist, checklist FR/NFR, Progress Log, Decisions Log, Blockers. |
| `docs/PROJECT_BRIEF.md` | Bản gốc của brief (đã `git mv` từ thư mục gốc vào `docs/`). |
| `.gitignore` | Mẫu chuẩn của Flutter + bổ sung `*.jks`, `*.keystore`, `android/key.properties`, `*.apk`, `*.aab`, `.env`, `coverage/`. |
| `.gitattributes` | Ép xuống dòng kiểu LF cho mọi file văn bản (trừ `.bat`/`.cmd`). |
| `README.md` | Khung README, hoàn thiện ở Phase 11. |
| `docs/TEST_REPORT.md` | Bảng tổng hợp kết quả kiểm thử theo phase. |

### Vì sao làm vậy

- **Repo git riêng trong thư mục dự án:** ổ `D:\` đã có một repo git ở gốc. Nếu không `git init` riêng, mọi commit sẽ lẫn vào repo đó. Repo lồng (nested) có thư mục `.git` riêng nên git sẽ dùng repo gần nhất.
- **`.gitattributes` với `eol=lf`:** Git for Windows mặc định `core.autocrlf=true`, nghĩa là file trên đĩa có thể là CRLF (`\r\n`) trong khi repo lưu LF (`\n`). `dart format --set-exit-if-changed` có thể coi đó là "chưa format". Ép LF giúp Quality Gate ổn định.
- **Ghi BLOCKER thay vì tự ý cài Flutter:** brief mục 2.3 quy định thiếu Flutter là BLOCKER, phải dừng lại hỏi. Cài SDK là thay đổi môi trường máy (tải 1–2 GB, sửa biến PATH) nên cần bạn đồng ý.

### Khái niệm cần hiểu

- **FROZEN requirements:** đặc tả yêu cầu bị "đóng băng" — không được sửa để né lỗi. Nếu một yêu cầu không làm được, phải báo blocker chứ không âm thầm hạ cấp tính năng.
- **Quality Gate:** chuỗi kiểm tra bắt buộc sau mỗi phase (format → analyze → test → build). Chỉ khi xanh hết mới được merge vào `main`.
- **Conventional Commits:** quy ước `type(scope): subject`, ví dụ `feat(parser): ...`, giúp lịch sử commit dễ đọc và có thể tự sinh CHANGELOG.

### Kết quả kiểm thử

Chưa chạy được (không có Flutter). Xem `docs/TEST_REPORT.md`.

### Cách tự kiểm tra bằng tay

Sau khi cài Flutter theo hướng dẫn ở mục **Blockers / Deviations** trong `CLAUDE.md`:

```powershell
flutter --version      # phải là Flutter 3.x, Dart 3.x
flutter doctor -v      # mục Android toolchain phải có dấu ✓
```

### Danh sách commit

_Sẽ bổ sung khi phase hoàn tất._
