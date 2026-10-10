# Ảnh chụp màn hình

Thư mục này đang **để trống**. Hãy chụp trên điện thoại thật rồi đặt các file sau vào đây, sau đó thêm bảng vào `README.md` (mẫu có sẵn ở mục "Ảnh chụp màn hình").

## Cần chụp

| File | Màn hình | Ghi chú |
|---|---|---|
| `dashboard_light.png` | Tổng quan, giao diện **sáng** | Có tổng tháng, donut và cột tuần có dữ liệu |
| `dashboard_dark.png` | Tổng quan, giao diện **tối** | Dùng menu giao diện ở góc phải AppBar |
| `scan.png` | Tab Quét | Khung căn chỉnh; đặt hóa đơn mẫu (không có thông tin cá nhân) trước camera |
| `review.png` | Màn Review sau khi quét | Thấy ảnh, các trường và dấu cảnh báo nếu có |
| `history.png` | Lịch sử | Có thumbnail và chip lọc danh mục |
| `donut_selected.png` | Donut khi chạm một lát | Thấy lát nổi bật và dòng chi tiết |

## Cách chụp

- Điện thoại: giữ nút nguồn + giảm âm lượng, rồi chép file qua USB. Hoặc: `adb exec-out screencap -p > dashboard_light.png`.
- Chụp dọc, cùng một máy; đặt tên đúng như bảng trên (chữ thường, gạch dưới).
- Nên thu nhỏ về chiều rộng ≤ 540 px để repo nhẹ.

## ⚠ Quyền riêng tư

**Không đưa vào repo:**
- ảnh hóa đơn thật (có tên, số điện thoại, mã số thuế, số thẻ),
- ảnh có **hình người** (ví dụ ảnh chụp màn hình lúc camera đang hướng vào mặt),
- dữ liệu giao dịch cá nhân thật.

Hãy dùng một hóa đơn mẫu hoặc dữ liệu giả, và che các thông tin nhạy cảm trước khi commit.
