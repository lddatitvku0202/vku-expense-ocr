# Báo cáo kiểm thử

## Tổng hợp theo phase

| Phase | Số test | Pass / Fail | Coverage | Format | Analyze | Build debug | Test trên thiết bị |
|---|---|---|---|---|---|---|---|
| 0 | 1 | 1 / 0 | — | ✔ | ✔ 0 issue | ✔ | ⚠ Chưa test trên thiết bị (chưa có máy kết nối) |
| 1 | 48 | 48 / 0 | 85.3% dòng | ✔ | ✔ 0 issue | ✔ | ⚠ Chưa test trên thiết bị (chưa có máy kết nối) |
| 2 | 201 | 201 / 0 | 94.9% dòng | ✔ | ✔ 0 issue | ✔ | ⚠ Chưa test trên thiết bị (Phase 2 không có UI mới) |

## Độ chính xác parser trên bộ fixture

Bộ 23 hóa đơn tổng hợp trong `test/fixtures/receipts/`, chạy qua `RowGrouper` → `ReceiptParser` (`test/services/receipt_fixtures_test.dart`). Kỳ vọng viết trước khi có parser.

| Trường | Lần chạy đầu | Sau khi sửa | Known limitations |
|---|---|---|---|
| Tên cửa hàng | 22/23 | **23/23** | 0 |
| Tổng tiền | 23/23 | **23/23** | 0 |
| Ngày | 23/23 | **23/23** | 0 |
| Danh mục | 23/23 | **23/23** | 0 |

Lỗi ở lần chạy đầu: `bookworm_english.txt` chọn slogan "Books & Stationery since 2001" làm tên cửa hàng. Đã sửa bằng commit `fix(parser): skip founding-year taglines …`.

⚠️ Đây là dữ liệu tổng hợp do chính người viết parser soạn, nên con số lạc quan. Xem phần "Đọc con số này cho đúng" trong `docs/PHASE_LOG.md` (Phase 2), và đo lại bằng hóa đơn thật ở Phase 3.

Chi tiết từng fixture (✓ đúng, ✗ sai):

| Fixture | Merchant | Total | Date | Category |
|---|---|---|---|---|
| coopmart_hue.txt | ✓ | ✓ | ✓ | ✓ |
| winmart.txt | ✓ | ✓ | ✓ | ✓ |
| bach_hoa_xanh.txt | ✓ | ✓ | ✓ | ✓ |
| lotte_mart.txt | ✓ | ✓ | ✓ | ✓ |
| highlands_coffee.txt | ✓ | ✓ | ✓ | ✓ |
| phuc_long.txt | ✓ | ✓ | ✓ | ✓ |
| the_coffee_house.txt | ✓ | ✓ | ✓ | ✓ |
| circle_k.txt | ✓ | ✓ | ✓ | ✓ |
| gs25.txt | ✓ | ✓ | ✓ | ✓ |
| fahasa.txt | ✓ | ✓ | ✓ | ✓ |
| grab.txt | ✓ | ✓ | ✓ | ✓ |
| be.txt | ✓ | ✓ | ✓ | ✓ |
| cgv.txt | ✓ | ✓ | ✓ | ✓ |
| the_gioi_di_dong.txt | ✓ | ✓ | ✓ | ✓ |
| cellphones.txt | ✓ | ✓ | ✓ | ✓ |
| quan_com.txt | ✓ | ✓ | ✓ | ✓ |
| bookworm_english.txt | ✓ | ✓ | ✓ | ✓ |
| photocopy.txt | ✓ | ✓ | ✓ | ✓ |
| maycha_noisy.txt | ✓ | ✓ | ✓ | ✓ |
| cropped_cafe.txt | ✓ | ✓ | ✓ | ✓ |
| karaoke.txt | ✓ | ✓ | ✓ | ✓ |
| pho24_ocr_digits.txt | ✓ | ✓ | ✓ | ✓ |
| banh_mi_skewed.txt | ✓ | ✓ | ✓ | ✓ |

## Quy tắc gán nhãn & chấm điểm hóa đơn thật

Dùng ở Phase 3 để đo parser trên ảnh hóa đơn thật trong `D:\receipts-test\` (ngoài repo). Đáp án (`ground_truth.csv`) do bạn duyệt và chốt **trước** khi chạy OCR/parser trên các ảnh này.

**Gán nhãn**

- `total` = số phải thanh toán in trên hóa đơn, số nguyên VND.
- Chỉ suy ra từ nội dung thấy trong ảnh, không dùng kiến thức ngoài ảnh.
- Ô trống nghĩa là đáp án đúng là **"không có"**.
- `Gear` = đồ dùng / thiết bị / quần áo / phụ kiện.

**Chấm điểm**

| Trường | Quy tắc |
|---|---|
| `total` | Khớp chính xác số nguyên. |
| `date` | Khớp chính xác; đáp án trống → đúng khi parser trả `null`. |
| `merchant` | So sau chuẩn hóa (bỏ dấu, chữ thường, bỏ ký tự không phải chữ/số). Đúng nếu kết quả **chứa** hoặc **nằm trong** `merchant` hoặc `merchant_alt` (tối thiểu 4 ký tự). Đáp án trống → đúng khi parser trả `null`. |
| `category` | Báo 3 nhóm: **đúng** / **không gợi ý** (`null`) / **gợi ý sai**. |

Báo cáo riêng hai nhóm `set=main` và `set=edge`.

## Ground truth đã khóa

| Mục | Giá trị |
|---|---|
| File | `D:\receipts-test\ground_truth.csv` (ngoài repo, không commit ảnh) |
| SHA-256 | `0ec9054112e46ecebf22f87b5d12dec588c9aea5c52eacad37f2ae134d03ecc0` |
| Kích thước | 6.451 byte (UTF-8, không BOM, xuống dòng CRLF) |
| Số hóa đơn | **22** (`main` 19 · `edge` 3: `highlands_02.jpg`, `thietbisieuthi_01.jpg`, `unknown_03.jpg`) |
| Cột | `file, merchant, merchant_alt, total, date, category, confidence, notes, set, verified` |
| Ngày khóa | 2026-10-09 |

Trước mỗi lần đánh giá ở Phase 3 phải kiểm tra hash; **không khớp thì dừng lại, không chấm điểm**:

```powershell
(Get-FileHash 'D:\receipts-test\ground_truth.csv' -Algorithm SHA256).Hash
# phải bằng 0EC9054112E46ECEBF22F87B5D12DEC588C9AEA5C52EACAD37F2AE134D03ECC0
```

## Checklist test thủ công trên thiết bị

> Đánh dấu `[x]` khi bạn đã tự kiểm tra trên máy Android thật. Ghi tên máy và phiên bản Android.

### Phase 0 — Khởi tạo

Thiết bị: `__________` · Android `____`

- [ ] `flutter devices` liệt kê được điện thoại.
- [ ] `flutter run` cài và mở app không lỗi (màn hình đếm số mặc định của Flutter).
- [ ] Bấm nút `+` thì số tăng (app phản hồi bình thường).

### Phase 1 — Nền tảng (khung app, 3 tab)

Thiết bị: `__________` · Android `____`

- [ ] App mở ở tab **Tổng quan**, không màn hình đỏ báo lỗi.
- [ ] Thanh điều hướng dưới có đúng 3 tab: *Tổng quan*, *Quét*, *Lịch sử*; bấm tab nào thì tiêu đề AppBar đổi theo tab đó.
- [ ] Bấm lại tab đang chọn không làm app lỗi.
- [ ] Bật **Dark mode** trong cài đặt điện thoại → app chuyển nền tối; tắt → nền sáng.
- [ ] Xoay ngang màn hình ở cả 3 tab → không có dải sọc vàng-đen (overflow).
- [ ] Nút Back của Android ở tab Tổng quan thoát app bình thường.
- [ ] Khi cài lần đầu, app **chưa** xin quyền camera hay micro (quyền camera chỉ được xin ở Phase 6).

### Phase 2 — ReceiptParser (không có giao diện mới)

Phase này chỉ thêm logic thuần Dart, chưa nối vào màn hình. Trên máy chỉ cần xác nhận app vẫn chạy:

- [ ] `flutter run` → app vẫn mở bình thường ở tab **Tổng quan** (không lỗi khởi động sau khi thêm parser).
- [ ] *(Phase 3 sẽ có màn hình debug chọn ảnh hóa đơn thật → xem raw text và kết quả parse. Khi đó hãy ghi độ chính xác trên hóa đơn thật vào đây.)*

