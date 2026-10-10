# Bàn giao — việc bạn cần tự làm

Mã nguồn, kiểm thử trên máy tính, APK release đã ký và báo cáo nguồn đã xong. Phần còn lại **cần điện thoại thật, tài khoản GitHub và bản thân bạn**. Làm theo thứ tự dưới đây (ưu tiên giảm dần).

> ⏰ **Hạn nộp: Chủ nhật cuối Tuần 8, 23:59. Trễ bị trừ 1 điểm mỗi ngày.** Nếu thiếu thời gian, thứ tự cứu điểm là: **(6)–(7) repo + APK** → **(5) PDF** → **(1) điện thoại thật** → **(4) video** → phần còn lại.

Quy ước lệnh: PowerShell, chạy trong `D:\Start Github\Projects\vku-ocr-expense`. Trước mọi lệnh `flutter`/`gradle` đặt:

```powershell
$env:GRADLE_USER_HOME = 'D:\dev-cache\gradle'
$env:PUB_CACHE        = 'D:\dev-cache\pub'
$flutter = 'D:\flutter\bin\flutter.bat'
```

## 0. Trạng thái hiện tại (để bạn biết cái gì đã làm)

| | |
|---|---|
| Test | 717 test pass, độ phủ 94,5%, `flutter analyze` 0 issue |
| APK | `build\app\outputs\flutter-apk\app-release.apk` (89,3 MiB, đã ký, **không có quyền INTERNET**); đã chạy trên **emulator** |
| **Chưa làm** | Chạy trên điện thoại thật; ảnh chụp màn hình; video; PDF; repo GitHub; Release |
| Placeholder cần điền | ngày nộp, link APK, link video, ảnh chụp (trong `docs/REPORT.md` và `README.md`) |

---

## 1. Sao lưu keystore (làm ngay, 2 phút)

Mất keystore thì không cập nhật được app đã phát hành bằng cùng chữ ký.

```powershell
$dest = 'E:\backup-vku'          # đổi thành USB / nơi an toàn NGOÀI máy này
New-Item -ItemType Directory -Force $dest | Out-Null
Copy-Item "$env:USERPROFILE\vku-keys\upload-keystore.jks" $dest
Copy-Item "D:\Start Github\Projects\vku-ocr-expense\android\key.properties" $dest
Get-FileHash "$env:USERPROFILE\vku-keys\upload-keystore.jks","$dest\upload-keystore.jks" -Algorithm SHA256   # hai hash phải GIỐNG nhau
```

Kiểm tra bản sao dùng được (dấu vân tay SHA-256 phải là `59:AF:14:29:9B:CE:AF:98:…:C2:9B:D1:04`; mật khẩu nằm trong `key.properties`):

```powershell
& 'C:\Program Files\Eclipse Adoptium\jdk-21.0.6.7-hotspot\bin\keytool.exe' -list -v -keystore "$dest\upload-keystore.jks" -alias upload
```

Không đưa hai file này lên GitHub, Drive công khai hay gửi qua chat.

---

## 2. Mượn điện thoại và chạy checklist trên máy thật

Mục tiêu: chuyển các mục "chưa xác minh trên máy thật" thành đã xác minh (hoặc phát hiện lỗi sớm). Cần: điện thoại Android 7.0+ (API 24+), cáp USB.

### 2.1. Chuẩn bị điện thoại và kết nối
1. **Cài đặt → Thông tin điện thoại → bấm 7 lần "Số bản dựng"** để bật tùy chọn nhà phát triển, rồi bật **Gỡ lỗi USB**.
2. Cắm cáp, chọn "Cho phép gỡ lỗi USB" trên điện thoại.
3. ```powershell
   $adb = "$env:ANDROID_HOME\platform-tools\adb.exe"
   & $adb devices            # phải thấy một dòng "<serial>    device"
   ```
   Ghi lại `<serial>` dùng cho các lệnh bên dưới.

### 2.2. Cài APK release và thử bằng tay (làm TRƯỚC các test tự động)
Dùng **đúng file APK sẽ đem nộp** để file đã thử chính là file phát hành.

```powershell
$apk = 'build\app\outputs\flutter-apk\app-release.apk'
& "$env:ANDROID_HOME\build-tools\37.0.0\apksigner.bat" verify --print-certs $apk     # chủ thể CN=Le Duy Dat
& $adb install -r $apk                       # lỗi "signatures do not match" thì: adb uninstall vn.edu.vku.vku_expense_ocr
```

Mở app và làm lần lượt (đánh dấu từng mục; ghi lại mục nào **lỗi**):

**Camera (FR-1)**
- [ ] Lần đầu mở tab **Quét** hiện hộp thoại xin quyền camera (không xin micro) → cho phép → thấy preview.
- [ ] Preview đúng tỷ lệ (vật tròn không méo), lấp đầy vùng xem.
- [ ] Nút flash đổi icon tắt → tự động → luôn bật → đèn pin; ở "đèn pin" đèn sáng thật.
- [ ] Chạm vào một dòng chữ: vòng vàng hiện đúng chỗ chạm, ảnh nét lại.
- [ ] Chụp một hóa đơn thật đặt trong khung → màn "Chỉnh vùng cắt" mở; vùng cắt **khớp khung**, không mất chữ ở mép; ảnh **không bị xoay** (thử cầm dọc và ngang).
- [ ] "Hủy" ở màn chỉnh → về camera. Xác nhận → "Đang đọc hóa đơn…" → màn Review.
- [ ] Nút thư viện: chọn một ảnh hóa đơn → chỉnh → Review.
- [ ] **Từ chối quyền** (Cài đặt → Ứng dụng → VKU Expense OCR → Quyền → Camera → Không cho phép), mở lại tab Quét: thấy hướng dẫn + nút "Mở Cài đặt"; bấm, cấp lại quyền, quay về: camera tự chạy.
- [ ] Bấm Home rồi mở lại app; đổi sang tab khác rồi quay lại tab Quét: camera vẫn chạy, không màn đen.

**Review, lưu, Lịch sử (FR-4, FR-5, FR-7)**
- [ ] Ô tên → bấm Next → sang ô số tiền, bàn phím **số**; gõ 1250000 → hiện `1.250.000`.
- [ ] Bàn phím mở: form cuộn được tới nút Lưu. Bộ chọn ngày bằng tiếng Việt, không cho chọn ngày sau hôm nay.
- [ ] Trường kém tin cậy có icon + chữ cảnh báo; tên cửa hàng kém tin cậy có banner màu ở đầu form.
- [ ] Mở "Xem văn bản OCR gốc": thấy các dòng chữ và **thời gian OCR (ms)** — **ghi lại số này**.
- [ ] Lưu → SnackBar → tab Lịch sử có giao dịch **kèm thumbnail**. Vuốt trái → "Hoàn tác" khôi phục (ảnh còn). Chạm giao dịch → màn sửa → lưu.
- [ ] Sửa một ô rồi bấm **nút Back của Android** → hỏi "Bỏ thay đổi?".

**Biểu đồ và giao diện (FR-6, FR-8)**
- [ ] Tab Tổng quan: donut quét một vòng, cột mọc lên **mượt** (không giật); thêm/xóa giao dịch rồi quay lại: số liệu đổi, animation chạy lại.
- [ ] Chạm từng lát donut (cả lát nhỏ, gần ranh giới) và từng cột (cả ngày 0 đ): chọn đúng.
- [ ] Menu giao diện (biểu tượng góc phải AppBar): Sáng / Tối / Theo hệ thống; đóng hẳn app, mở lại: lựa chọn còn nguyên. Ở nền tối, chữ và biểu đồ đọc rõ.
- [ ] Cài đặt → Cỡ chữ → **lớn nhất**, mở cả 5 màn (Tổng quan, Quét, Review, Lịch sử, sửa giao dịch): không có dải sọc vàng-đen. Xoay ngang: không overflow.
- [ ] Tên dưới biểu tượng app là **"VKU Expense OCR"**.

**Chế độ máy bay (NFR-1)**
- [ ] Bật **chế độ máy bay** (tắt cả Wi-Fi). Quét một hóa đơn → Review có dữ liệu → Lưu → Dashboard cập nhật. Tất cả phải chạy bình thường.
- [ ] Đóng hẳn app, mở lại: dữ liệu vẫn còn.

### 2.3. Chạy các test tích hợp trên máy thật
**Lưu ý:** các lệnh dưới đây cài **bản debug** (khác chữ ký) và sẽ gỡ bản release; làm **sau** khi đã thử xong 2.2.

```powershell
& $flutter test integration_test/app_flow_test.dart -d <serial>
& $flutter test integration_test/storage_test.dart  -d <serial>
```

Test camera cần quyền camera và một hóa đơn thật đặt trước camera sau. Test chờ tối đa 2 phút để có quyền: mở **cửa sổ PowerShell thứ hai** và, khi thấy dòng `Installing …`, chạy:

```powershell
& $adb shell pm grant vn.edu.vku.vku_expense_ocr android.permission.CAMERA
```

```powershell
& $flutter test integration_test/camera_smoke_test.dart -d <serial>      # in ra dòng SMOKE … crop …; OCR … ms; rows …
```

Ghi kết quả (pass/fail, số in ra) vào `docs/TEST_REPORT.md`, mục mới "Điện thoại thật".

### 2.4. Sau khi có kết quả: cập nhật tài liệu cho đúng sự thật
- Mục nào **pass**: đổi trạng thái 🟨/⚠ trong `docs/REPORT.md` (mục 2) và `README.md`; trong `CLAUDE.md` đánh `[x]` FR-1.1…1.7 và NFR-6 (ghi "xác minh trên <tên máy>, Android <phiên bản>"), gạch mục trong "Việc còn nợ".
- Mục nào **lỗi**: **không** giấu. Ghi vào `docs/REPORT.md` (mục 5–6) và `CLAUDE.md`. Muốn sửa: tạo nhánh `fix/<tên>`, viết test đỏ trước, sửa, chạy lại gate (`dart format`, `flutter analyze`, `flutter test`), merge `--no-ff`; nếu sửa sau khi đã tag, dùng tag mới `v1.0.1`.
- Đã sửa lỗi nào ở bản release thì **build lại APK và thử lại đúng file đó**.

---

## 3. Đo OCR trên điện thoại thật

Bộ 22 ảnh và `ground_truth.csv` nằm ở `D:\receipts-test\` (ngoài repo; công cụ tự kiểm tra SHA-256 của file đáp án, sai thì dừng):

```powershell
powershell -ExecutionPolicy Bypass -File tool\ocr_eval\run_ocr_eval.ps1 -DeviceId <serial> -Flutter 'D:\flutter\bin\flutter.bat'
```

Báo cáo lưu ở `D:\receipts-test\reports\<thời-gian>_<serial>\report.md` (+ `report.json`). Chép bảng tổng hợp (main / edge) và **thời gian OCR trung vị trên máy thật** vào `docs/TEST_REPORT.md` và vào mục 4 của `docs/REPORT.md` (thêm dòng "điện thoại thật" cạnh dòng emulator; **không sửa số cũ**). Số trên máy thật có thể khác số trên emulator; ghi đúng số đo được.

### Bộ ảnh mới (holdout) — nên làm để có con số khách quan
Số 16/19 là lạc quan vì parser đã được sửa sau khi xem lỗi của bộ 22 ảnh. Để đo khách quan:
1. Thu 15–20 hóa đơn **mới** (chưa từng dùng), chụp bằng điện thoại; đặt vào `D:\receipts-holdout\` (ngoài repo).
2. Tự viết `ground_truth.csv` cùng định dạng với `D:\receipts-test\ground_truth.csv` (cột `file, merchant, merchant_alt, total, date, category, confidence, notes, set, verified`; quy tắc gán nhãn trong `docs/TEST_REPORT.md`).
3. **Khóa hash trước khi chạy:** `Get-FileHash D:\receipts-holdout\ground_truth.csv -Algorithm SHA256`, ghi hash vào `docs/TEST_REPORT.md`.
4. **Không sửa parser** trước lần chạy này. Chạy đúng **một lần**:
   ```powershell
   powershell -ExecutionPolicy Bypass -File tool\ocr_eval\run_ocr_eval.ps1 -DeviceId <serial> -DataDir 'D:\receipts-holdout' -ExpectedSha256 '<hash-vừa-khóa>' -Flutter 'D:\flutter\bin\flutter.bat'
   ```
5. Ghi kết quả (cả khi tệ) vào `docs/TEST_REPORT.md` và `docs/REPORT.md`.

---

## 4. Chụp ảnh sáng/tối cho báo cáo

Danh sách ảnh và cách đặt tên: `docs/screenshots/README.md` (`dashboard_light.png`, `dashboard_dark.png`, `scan.png`, `review.png`, `history.png`, `donut_selected.png`).

```powershell
& $adb exec-out screencap -p > docs\screenshots\dashboard_light.png
```

- Chụp trên **điện thoại thật**, dữ liệu mẫu giả (xem `docs/DEMO_SCRIPT.md`).
- **Không** để lộ ảnh hóa đơn thật, hình người, số điện thoại, tên tài khoản trên thanh trạng thái. Ảnh Review hiện ảnh hóa đơn: dùng hóa đơn mẫu đã che thông tin.
- Thu nhỏ ảnh về rộng ≤ 540 px.
- Chèn vào báo cáo: thay đoạn `**[ẢNH 1 …]**` ở mục 4 của `docs/REPORT.md` bằng một bảng 1 hàng 4 ảnh:
  ```markdown
  | Tổng quan (sáng) | Tổng quan (tối) | Quét | Review |
  |---|---|---|---|
  | ![](screenshots/dashboard_light.png) | ![](screenshots/dashboard_dark.png) | ![](screenshots/scan.png) | ![](screenshots/review.png) |
  ```
  (đã thử: thêm 4 ảnh như vậy, báo cáo vẫn **3 trang**). Thêm cả bảng vào `README.md` (mục "Ảnh chụp màn hình").

---

## 5. Quay video demo

Làm theo `docs/DEMO_SCRIPT.md` (kịch bản 2–3 phút, hai phương án: điện thoại thật hoặc emulator + webcam). **Cẩn thận khung hình: không để mặt người hay thông tin cá nhân lọt vào.** Đăng lên YouTube (chế độ "Không công khai" cũng được) và giữ lại link.

---

## 6. Xuất PDF báo cáo

1. Mở `docs/REPORT.md`, điền các chỗ trong ngoặc `[...]`: **ngày nộp**, **link APK**, **link video**, ảnh (mục 4); sửa trạng thái 🟨 → ✅ theo kết quả mục 2.
2. Xuất PDF (không có `pandoc` trên máy này), cách khuyến nghị:
   ```powershell
   python tool\report\md_to_pdf.py                 # docs\REPORT.md -> docs\REPORT.pdf, dùng Microsoft Edge
   ```
   Công cụ in số trang và **báo lỗi nếu ngoài 2–4 trang**; không cho cỡ chữ nhỏ hơn 10pt (`--font-pt 10.5` để chữ lớn hơn). Bản hiện tại: **3 trang, chữ 10pt**.
3. Cách khác: VS Code → cài tiện ích **Markdown PDF** → mở `docs/REPORT.md` → `Ctrl+Shift+P` → "Markdown PDF: Export (pdf)"; hoặc mở file trong trình xem Markdown rồi in ra PDF; hoặc dán vào Word, đặt chữ **≥ 10pt**, lề 1,2–1,5 cm, "Save as PDF".
4. Mở PDF kiểm tra bằng mắt: **2–4 trang**, bảng không bị cắt, ảnh rõ.
5. Nộp bản PDF; có thể `git add docs/REPORT.pdf` để lưu cùng repo.

---

## 7. Tạo repo GitHub và đẩy mã lên

1. Trên GitHub (tài khoản `lddatitvku0202`): **New repository** → tên **`vku-expense-ocr`**, **Public**, **để trống** (KHÔNG tick README, .gitignore, license).
2. **Kiểm tra sạch trước khi đẩy** (repo công khai, mọi lịch sử đều lộ):
   ```powershell
   git status --short                                              # phải rỗng
   git ls-files | Select-String "jks|keystore|key.properties|\.apk|\.aab|\.png|\.jpe?g"   # chỉ được thấy ảnh trong thư mục của ứng dụng nếu có; không có keystore/apk
   git log --all --name-only --format="" | Sort-Object -Unique | Select-String "jks|keystore|key.properties|\.apk|\.aab|\.jpe?g"    # phải rỗng
   ```
3. Đẩy:
   ```powershell
   git remote add origin https://github.com/lddatitvku0202/vku-expense-ocr.git
   git push -u origin main
   git push origin --tags
   ```
   Chỉ cần `main` và tag (các nhánh `phase/*` đã được merge nên không cần đẩy). Nếu GitHub hỏi đăng nhập, dùng Personal Access Token hoặc Git Credential Manager.
4. Mở `https://github.com/lddatitvku0202/vku-expense-ocr`: kiểm tra `README.md` hiển thị đúng, sơ đồ Mermaid dựng được, `git log` sạch.

---

## 8. Tạo Release v1.0.0 và đính kèm APK

1. Thử lại lần cuối bằng **đúng file APK sẽ phát hành** (bước 2.2). Nếu cần build lại: `& $flutter build apk --release`, rồi `apksigner verify --print-certs` (chủ thể `CN=Le Duy Dat`), rồi thử lại trên điện thoại (APK build lại không giống từng byte với bản trước).
2. Ghi lại hash để người khác kiểm tra: `Get-FileHash build\app\outputs\flutter-apk\app-release.apk -Algorithm SHA256`.
3. Trên GitHub: **Releases → Draft a new release** → chọn tag **`v1.0.0`** → tiêu đề "VKU Expense OCR v1.0.0" → mô tả (tính năng chính, **hạn chế** đã nêu trong README, hash SHA-256) → kéo `app-release.apk` vào "Attach binaries" → **Publish release**.
   Hoặc bằng GitHub CLI (nếu đã cài `gh`):
   ```powershell
   gh release create v1.0.0 build\app\outputs\flutter-apk\app-release.apk --title "VKU Expense OCR v1.0.0" --notes-file CHANGELOG.md
   ```
4. Chép **link tải trực tiếp** của file APK (dạng `https://github.com/lddatitvku0202/vku-expense-ocr/releases/download/v1.0.0/app-release.apk`) và thử tải về điện thoại.

---

## 9. Điền link rồi nộp bài

1. Điền link APK và link video vào **`README.md`** (mục "Tải APK") và **`docs/REPORT.md`** (mục 1); xuất lại PDF (bước 6).
2. Commit và đẩy: `git add -A; git commit -m "docs: add release and video links"; git push`. (Tag `v1.0.0` vẫn đúng; chỉ có thêm commit tài liệu.)
3. Nộp theo yêu cầu của đề, **3 sản phẩm**:
   - [ ] **Link APK** (GitHub Releases) + video demo 2–3 phút.
   - [ ] **Link GitHub public** `https://github.com/lddatitvku0202/vku-expense-ocr` (có `README.md` hướng dẫn cài đặt và lệnh build).
   - [ ] **Báo cáo PDF 2–4 trang** (`docs/REPORT.pdf`).
4. Nhắc lại: **Chủ nhật 23:59, trễ trừ 1 điểm/ngày.**

---

## Phụ lục — việc còn nợ chưa có bước ở trên

Danh sách đầy đủ nằm ở mục "Việc còn nợ" trong `CLAUDE.md`. Ngoài các bước trên còn có:
- Chạy `flutter run` trên Android để xác nhận khởi động (mở DB, dọn ảnh mồ côi) không lỗi: đã bao gồm khi cài và mở APK ở mục 2.2.
- Phase 12 (tùy chọn, `MethodChannel`) **chưa làm**; không bắt buộc theo rubric.
