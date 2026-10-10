# Kịch bản video demo (2–3 phút)

Yêu cầu của đề: **quét trực tiếp một hóa đơn thật → parse → xác nhận ở Review → donut chart cập nhật có animation**. Kịch bản dưới đây dài khoảng **2 phút 45 giây**; nếu vượt 3 phút, rút cảnh 5 hoặc cảnh 7.

Có hai phương án quay. Cảnh và lời thoại giống nhau, chỉ khác cách quay và vài lưu ý.

| | (A) Điện thoại thật — **nên dùng** | (B) Emulator + webcam |
|---|---|---|
| Ưu | Thấy đúng camera, flash, lấy nét, độ mượt animation | Không cần mượn máy |
| Nhược | Cần mượn điện thoại | Không có flash / lấy nét thật; OCR mất 11–12 s (emulator 2 GB RAM); webcam dễ quay vào mặt người |
| Ghi hình | Quay màn hình có sẵn của máy, hoặc `adb shell screenrecord` | OBS hoặc Xbox Game Bar (`Win + Alt + R`) quay cửa sổ emulator |

---

## Chuẩn bị trước khi quay (làm cả hai phương án)

### 1. Dữ liệu mẫu để biểu đồ có nhiều danh mục
Cài `app-release.apk` bản sạch, rồi thêm **5–6 giao dịch trải trong tuần hiện tại** bằng nút "Thêm thủ công" (dữ liệu giả, không có thông tin cá nhân). **Ngày không được ở tương lai**, nên hãy quay vào **thứ Năm trở đi** để có đủ nhiều ngày; chỉ chọn các ngày từ thứ Hai đến hôm nay.

| Cửa hàng | Số tiền | Danh mục | Ngày (trong tuần hiện tại) |
|---|---:|---|---|
| Highlands Coffee | 59.000 | Ăn uống | Thứ Hai |
| Fahasa | 245.000 | Học tập | Thứ Ba |
| Grab | 45.000 | Di chuyển | Thứ Tư |
| Cửa hàng phụ kiện | 189.000 | Thiết bị | Thứ Năm |
| CGV | 180.000 | Giải trí | Thứ Sáu |
| Bách Hóa Xanh | 132.000 | Ăn uống | Thứ Sáu hoặc hôm nay |

Kiểm tra: tab **Tổng quan** thấy donut có 5 màu, cột tuần có nhiều cột khác chiều cao. **Hóa đơn sẽ quét trong video chưa được lưu** (để lưu ngay trước máy quay).

### 2. Hóa đơn thật để quét
- Chọn hóa đơn **in rõ, chữ đen, phẳng**, tên cửa hàng ở đầu, có dòng "Tổng thanh toán" và ngày.
- **Che hoặc chọn hóa đơn không có** số điện thoại, mã số thuế, số thẻ, tên khách (cả khung hình lẫn ảnh Review đều lộ nội dung này).
- Chuẩn bị luôn một hóa đơn dự phòng.

### 3. Điện thoại / máy
- Sạc đầy pin; bật **Không làm phiền** (tắt thông báo); tắt thông báo ứng dụng khác.
- Giao diện **sáng** lúc bắt đầu; độ sáng màn hình cao; ngôn ngữ tiếng Việt.
- Cấp sẵn quyền camera (để không quay cảnh hộp thoại xin quyền, trừ khi muốn).
- Xóa ảnh/thông báo cá nhân trong thư viện nếu có thể bị lộ ở bộ chọn ảnh.

### 4. Đặt hóa đơn và ánh sáng
- **Điện thoại thật:** đặt hóa đơn phẳng trên bàn màu tối, ánh sáng ban ngày từ bên hông (tránh đèn ngay trên đầu gây chói), cầm máy song song mặt bàn cách ~25 cm cho đến khi hóa đơn nằm trọn trong khung. Có thể kẹp hóa đơn bằng hai vật nặng ở hai mép.
- Quay thử một lần; xem lại xem chữ trong khung có đọc được không trước khi quay chính thức.

---

## Kịch bản theo cảnh

Mốc thời gian là mục tiêu, lệch ±5 giây là được.

| # | Mốc | Cảnh | Thao tác trên màn hình | Lời thoại gợi ý |
|:--:|:--:|---|---|---|
| 1 | 0:00–0:12 | **Mở đầu** | Bật **chế độ máy bay** (thấy biểu tượng ✈ trên thanh trạng thái), mở app → tab **Tổng quan** với dữ liệu mẫu. | "VKU Expense OCR: quét hóa đơn, nhận dạng chữ ngay trên điện thoại, không cần mạng. Em tự bật chế độ máy bay để chứng minh app hoàn toàn offline." |
| 2 | 0:12–0:30 | **Tab Quét** | Mở tab **Quét**: preview trực tiếp, khung căn chỉnh. *(A)* Bấm nút flash đổi trạng thái; chạm vào hóa đơn để lấy nét (vòng vàng). *(B)* Bỏ flash/lấy nét. | "Camera hiển thị trực tiếp, có khung căn chỉnh theo tỷ lệ hóa đơn." |
| 3 | 0:30–0:45 | **Chụp và cắt** | Đặt hóa đơn vào khung → bấm **chụp** → màn **Chỉnh vùng cắt** (đã tự cắt theo khung), xác nhận ✓. | "Ảnh tự cắt theo khung, em có thể chỉnh tay trước khi nhận dạng." |
| 4 | 0:45–1:15 | **Kết quả parse** | Màn **Xác nhận hóa đơn**: tên cửa hàng, số tiền, ngày, danh mục đã điền sẵn. Chỉ vào trường có **dấu cảnh báo** (icon + chữ "Không chắc chắn"), mở **"Xem văn bản OCR gốc"** (có thời gian OCR). *(B: cắt đoạn chờ OCR, ghi chú "tua nhanh".)* | "Bộ phân tích regex tách tổng tiền, ngày, tên cửa hàng và gợi ý danh mục. Trường nào kém tin cậy được đánh dấu để em kiểm tra lại; đây là văn bản ML Kit đọc được và thời gian nhận dạng." |
| 5 | 1:15–1:30 | **Sửa ở Review** | Sửa **một trường** (ví dụ tên cửa hàng hoặc ngày; thấy dấu cảnh báo biến mất), chọn danh mục nếu chưa có, bấm **Lưu giao dịch** → SnackBar "Đã lưu giao dịch." | "Em sửa lại chỗ OCR đọc chưa chuẩn rồi lưu. Số tiền tự định dạng dấu chấm hàng nghìn." |
| 6 | 1:30–1:50 | **Donut cập nhật** | Sang tab **Tổng quan**: donut **quét lại có animation**, tổng tháng tăng; **chạm một lát** → lát nổi bật + chi tiết; xem legend (màu, số tiền, %). | "Biểu đồ tròn vẽ tay bằng CustomPainter, tự cập nhật khi có giao dịch mới và chạy lại animation. Chạm vào từng lát để xem chi tiết." |
| 7 | 1:50–2:05 | **Cột tuần** | Cuộn xuống biểu đồ cột: cột mọc lên, **chạm một cột** → số tiền của ngày; bấm **tuần trước** rồi quay lại. | "Biểu đồ cột 7 ngày từ thứ Hai đến Chủ nhật, chạm để xem số tiền, chuyển tuần bằng hai nút." |
| 8 | 2:05–2:30 | **Lịch sử, xóa và Hoàn tác** | Tab **Lịch sử**: danh sách có thumbnail, lọc bằng chip danh mục; **vuốt trái** một giao dịch → SnackBar → bấm **Hoàn tác** → giao dịch quay lại (cả ảnh). | "Lịch sử có thumbnail và lọc theo danh mục. Vuốt để xóa; trong 5 giây vẫn hoàn tác được, kể cả ảnh hóa đơn." |
| 9 | 2:30–2:45 | **Dark mode và kết** | Menu giao diện trên AppBar Tổng quan → **Tối** → xem Tổng quan nền tối; kết thúc ở Tổng quan. | "Giao diện sáng, tối hoặc theo hệ thống và được lưu lại. Cảm ơn thầy cô đã xem." |

Nếu thiếu thời gian: bỏ cảnh 7, hoặc rút cảnh 2.

---

## Phương án A — quay trên điện thoại thật

1. Điện thoại: bật **tùy chọn nhà phát triển** → **Gỡ lỗi USB** nếu muốn dùng `adb`.
2. Quay màn hình bằng công cụ có sẵn của máy (kéo thanh thông báo → **Ghi màn hình**; tắt hoặc bật micro tùy ý).
3. Hoặc dùng adb (mỗi file tối đa 3 phút):
   ```powershell
   adb shell screenrecord --time-limit 180 --bit-rate 8000000 /sdcard/demo.mp4
   adb pull /sdcard/demo.mp4 .
   adb shell rm /sdcard/demo.mp4
   ```
4. Thu lời thoại riêng bằng micro rồi ghép khi dựng; hoặc nói trực tiếp khi quay máy tính + điện thoại.

## Phương án B — quay trên emulator, webcam hướng vào hóa đơn

1. **Cấu hình AVD:** `vku_test_api33` đã đặt `hw.camera.back=webcam0` (xem `docs/SETUP_ENV.md` mục 12). Emulator 2 GB RAM chạy chậm và System UI hay báo "isn't responding"; nên tăng RAM trong `D:\dev-cache\avd\vku_test_api33.avd\config.ini` (`hw.ramSize=3072`), đóng các ứng dụng khác, rồi khởi động: `emulator -avd vku_test_api33 -no-snapshot-save -no-audio`.
2. **Cài app và dữ liệu mẫu** như mục chuẩn bị. Cấp quyền camera: `adb shell pm grant vn.edu.vku.vku_expense_ocr android.permission.CAMERA`.
3. **Đặt hóa đơn trước webcam:**
   - Đặt hóa đơn **phẳng trên mặt bàn**, nghiêng màn hình laptop để webcam **nhìn xuống bàn**, cách hóa đơn 25–35 cm (chữ phải rõ trong preview).
   - Nền bàn **tối, đơn sắc**; ánh sáng khuếch tán từ bên hông, tránh bóng tay và chói đèn lên giấy bóng.
   - Dùng hai vật nặng giữ hai mép hóa đơn cho phẳng.
4. **⚠ KHÔNG ĐỂ MẶT NGƯỜI LỌT VÀO KHUNG HÌNH.** Webcam laptop thường hướng về phía người ngồi. Trước khi quay:
   - Mở tab Quét và **nhìn preview**: chỉ được thấy bàn và hóa đơn, không có mặt, tay lộ mặt, ảnh gia đình, giấy tờ.
   - Nghiêng màn hình, hoặc đặt laptop trên giá để webcam không chiếu vào chỗ ngồi; đứng/ngồi ngoài tầm webcam khi quay.
   - Quay thử 10 giây, tua lại từng đoạn; **nếu thấy mặt dù chỉ một khung hình thì quay lại hoặc cắt bỏ**. Khi không dùng, che webcam hoặc đóng tab Quét.
5. **Bước chờ OCR:** trên emulator mất khoảng 11–12 giây. Khi dựng video có thể tua nhanh đoạn này, nhưng **phải ghi chú trên màn hình "(tua nhanh)"** và không nói thời gian OCR là của điện thoại; thời gian đo trên emulator **không** đại diện cho máy thật.
6. **Không nói** rằng flash và lấy nét hoạt động (webcam không có); bỏ phần đó ở cảnh 2.
7. Quay cửa sổ emulator bằng OBS (nguồn "Window Capture") hoặc `Win + Alt + R`; xuất MP4 1080p, ≤ 3 phút.

---

## Danh sách kiểm tra trước khi đăng video

- [ ] Độ dài 2–3 phút; nghe rõ lời; có đủ chuỗi **quét → parse → Review → lưu → donut cập nhật có animation**.
- [ ] Thấy chế độ máy bay ở cảnh 1 (nếu quay trên máy thật).
- [ ] Không có số điện thoại, mã số thuế, số thẻ, tên người, **hình người** ở bất kỳ khung hình nào; xem lại toàn bộ video ở tốc độ chậm.
- [ ] Không lộ thông báo cá nhân, tên tài khoản, số liên lạc trên thanh trạng thái.
- [ ] Đã ghi chú đoạn "tua nhanh" nếu có (phương án B).
- [ ] Điền link video vào `README.md` và `docs/REPORT.md`.
