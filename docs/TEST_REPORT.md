# Báo cáo kiểm thử

## Tổng hợp theo phase

| Phase | Số test | Pass / Fail | Coverage | Format | Analyze | Build debug | Test trên thiết bị |
|---|---|---|---|---|---|---|---|
| 0 | 1 | 1 / 0 | — | ✔ | ✔ 0 issue | ✔ | ⚠ Chưa test trên thiết bị (chưa có máy kết nối) |
| 1 | 48 | 48 / 0 | 85.3% dòng | ✔ | ✔ 0 issue | ✔ | ⚠ Chưa test trên thiết bị (chưa có máy kết nối) |
| 2 | 201 | 201 / 0 | 94.9% dòng | ✔ | ✔ 0 issue | ✔ | ⚠ Chưa test trên thiết bị (Phase 2 không có UI mới) |
| 3 | 272 | 272 / 0 | 95.6% dòng | ✔ | ✔ 0 issue | ✔ | 🟨 Emulator `vku_test_api33` (API 33): đánh giá 22 hóa đơn thật tự động. ⚠ **Chưa test trên điện thoại thật** |
| 4 | 321 | 321 / 0 | 95.5% dòng | ✔ | ✔ 0 issue | ✔ | ⚠ **Chưa test trên thiết bị** (không bật emulator theo yêu cầu, máy 8 GB RAM). DB test bằng `sqflite_common_ffi`, ảnh bằng thư mục tạm |
| 5 | 383 | 383 / 0 | 95.0% dòng | ✔ | ✔ 0 issue | ✔ | ⚠ **Chưa test trên thiết bị** (không bật emulator theo yêu cầu). State test bằng `ProviderContainer` + repository/storage giả, `fakeAsync` cho Undo |
| 6 | 438 | 438 / 0 | 91.5% dòng | ✔ | ✔ 0 issue | ✔ | 🟨 **emulator + webcam**: smoke test 1 lần pass (preview → chụp → cắt → OCR → /review). ⚠ **Chưa xác minh trên điện thoại thật** |
| 7 | 489 | 489 / 0 | 92.8% dòng | ✔ | ✔ 0 issue | ✔ | ⚠ **Chưa test trên thiết bị** (không bật emulator theo yêu cầu). 55 test mới; 4 test của màn debug OCR bị xóa cùng màn |
| 8 | 514 | 514 / 0 | 93.1% dòng | ✔ | ✔ 0 issue | ✔ | ⚠ **Chưa test trên thiết bị**. `integration_test/app_flow_test.dart` đã viết, **chưa chạy** |
| 9 | 582 | 582 / 0 | 94.2% dòng | ✔ | ✔ 0 issue | ✔ | ⚠ **Chưa test trên thiết bị** (không bật emulator theo yêu cầu) |

## Độ chính xác parser trên bộ fixture

Bộ 23 hóa đơn tổng hợp trong `test/fixtures/receipts/`, chạy qua `RowGrouper` → `ReceiptParser` (`test/services/receipt_fixtures_test.dart`). Kỳ vọng viết trước khi có parser.

| Trường | Lần chạy đầu | Sau khi sửa | Known limitations |
|---|---|---|---|
| Tên cửa hàng | 22/23 | **23/23** | 0 |
| Tổng tiền | 23/23 | **23/23** | 0 |
| Ngày | 23/23 | **23/23** | 0 |
| Danh mục | 23/23 | **23/23** | 0 |

Lỗi ở lần chạy đầu: `bookworm_english.txt` chọn slogan "Books & Stationery since 2001" làm tên cửa hàng. Đã sửa bằng commit `fix(parser): skip founding-year taglines …`.

**Phase 3:** thêm 8 fixture tổng hợp (3 ảnh xoay: `tilted_minimart`, `tilted_cafe_ccw`, `sideways_bookshop`; 5 mẫu gặp trên hóa đơn thật: `pos_decimal_amounts`, `cash_tendered_label`, `tax_table_total`, `english_date_store`, `clothing_shop`), kỳ vọng viết trước khi sửa code. Kết quả: **31/31** ở cả 4 trường, sổ known limitations vẫn rỗng. Bảng chi tiết bên dưới là 23 fixture gốc của Phase 2.

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

## Độ chính xác trên hóa đơn thật (Phase 3, emulator)

Chạy bằng `tool/ocr_eval/run_ocr_eval.ps1`. Pipeline thật: ML Kit (model bundled, Latin) → `RowGrouper` (có deskew) → `ReceiptParser`, chạy trên emulator `vku_test_api33` (`sdk_gphone64_x86_64`, API 33, x86_64). Cả hai lần đều đã kiểm tra hash `ground_truth.csv` = `0ec90541…03ecc0` trước khi chấm, khớp. Báo cáo gốc (JSON + MD) nằm ngoài repo:

| Lần | Mã nguồn | Báo cáo |
|---|---|---|
| Lần đầu (trước khi sửa) | `54eba91` (`lib/` giống hệt `bd112b4`; commit này chỉ sửa quyền thư mục của công cụ chấm) | `D:\receipts-test\reports\20261009_103712_emulator-5554\` |
| Sau khi sửa | `18f299a` | `D:\receipts-test\reports\20261009_231902_emulator-5554\` |

Hai con số trên đều đọc từ file báo cáo, không ước lượng.

### Tổng hợp

| Set | n | Tên cửa hàng | Tổng tiền | Ngày | Danh mục đúng / không gợi ý / sai | OCR trung vị (ms) |
|---|---|---|---|---|---|---|
| main, lần đầu | 19 | 7/19 | 10/19 | 14/19 | 10 / 5 / 4 | 4947 |
| **main, sau sửa** | 19 | **7/19** | **16/19** | **15/19** | **11 / 4 / 4** | 5036 |
| edge, lần đầu | 3 | 1/3 | 2/3 | 2/3 | 1 / 1 / 1 | 4694 |
| **edge, sau sửa** | 3 | **1/3** | **2/3** | **2/3** | **2 / 1 / 0** | 5286 |

Không có trường nào **tụt** từ đúng sang sai giữa hai lần. Thời gian OCR (main, sau sửa): nhỏ nhất 3901 ms, lớn nhất 6604 ms. Đây là emulator x86_64 chạy CPU, **không** đại diện cho điện thoại thật.

⚠️ **Đọc con số sau sửa cho đúng:** các bản sửa được thiết kế **sau khi** xem lỗi của chính 22 ảnh này. Mỗi bản sửa là một quy tắc tổng quát, có test và fixture tổng hợp riêng viết trước (commit `c74447e`), không có code nhận diện riêng ảnh nào. Dù vậy, bộ ảnh không còn là dữ liệu "chưa thấy". Vì thế 16/19 tổng tiền là con số **lạc quan**, và độ chính xác thật phải đo lại trên hóa đơn mới, chụp bằng điện thoại thật.

### Chi tiết từng hóa đơn

✓ đúng · ✗ sai · ∅ không gợi ý danh mục · `A→B` là lần đầu → sau sửa.

| File | Set | Tên cửa hàng | Tổng tiền | Ngày | Danh mục |
|---|---|---|---|---|---|
| bigc_01.png | main | ✗ | ✗ | ✓ | ∅ |
| bigc_02.jpg | main | ✗ | ✗→✓ | ✗ | ✓ |
| bigc_03.jpg | main | ✗ | ✓ | ✓ | ✓ |
| bigc_04.jpg | main | ✓ | ✗ | ✗ | ✓ |
| circlek_01.jpg | main | ✓ | ✓ | ✗→✓ | ✓ |
| coopmart_01.jpg | main | ✗ | ✓ | ✓ | ✓ |
| coopmart_02.jpg | main | ✓ | ✗→✓ | ✓ | ✓ |
| highlands_01.jpg | main | ✗ | ✗→✓ | ✓ | ∅ |
| highlands_03.jpg | main | ✗ | ✓ | ✗ | ✓ |
| megamarket_01.jpg | main | ✗ | ✓ | ✓ | ∅ |
| photoandbike_01.jpg | main | ✓ | ✓ | ✓ | ✗ |
| tientho_01.jpg | main | ✗ | ✗ | ✓ | ✗ |
| unknown_01.png | main | ✗ | ✗→✓ | ✓ | ✗ |
| unknown_02.png | main | ✓ | ✓ | ✓ | ∅→✓ |
| vincommerce_01.jpg | main | ✗ | ✗→✓ | ✓ | ∅ |
| vinhnguyenres_01.jpg | main | ✓ | ✗→✓ | ✓ | ✓ |
| vinmart_01.jpg | main | ✗ | ✓ | ✓ | ✓ |
| winmart_01.jpg | main | ✗ | ✓ | ✗ | ✗ |
| winmart_02.jpg | main | ✓ | ✓ | ✓ | ✓ |
| highlands_02.jpg | edge | ✓ | ✗ | ✓ | ✓ |
| thietbisieuthi_01.jpg | edge | ✗ | ✓ | ✓ | ∅ |
| unknown_03.jpg | edge | ✗ | ✓ | ✗ | ✗→✓ |

### Nguyên nhân lỗi ở lần đầu và bản sửa tương ứng

| Lỗi quan sát được (lần đầu) | Hóa đơn | Bản sửa (quy tắc tổng quát) |
|---|---|---|
| Không có từ khóa → fallback lấy số trơn lớn nhất (số phiếu, giờ không có dấu `:`) | unknown_01, vincommerce_01 | Fallback ưu tiên số viết **như tiền** (có phân cách nghìn hoặc ký hiệu tiền), số trơn chỉ dùng khi không còn gì khác (`4ee3458`) |
| Số có 2 chữ số thập phân `123,100.00`, OCR chèn dấu cách `123, 100.00`, `đ` bị đọc thành `0`/`6` ở cuối (`184.0340`) | vinhnguyenres_01, bigc_02 | Đọc phần thập phân dùng dấu phân cách khác; ghép lại khoảng trắng sau dấu phân cách; bỏ một `0`/`6` thừa sau nhóm cuối (`4ee3458`) |
| Nhãn tổng bị OCR sai một ký tự (`1ONG CONG`), viết tắt (`T.Cộng`) | bigc_02, highlands_01 | Nhãn dài ≥ 8 ký tự chấp nhận sai 1 ký tự; thêm `T.Cộng`, `phải T.Toán`; "Tổng:" trơn của bảng VAT xếp mức yếu hơn (`17e6d79`) |
| Máy POS in **tiền khách đưa** dưới nhãn "Tổng tiền thanh toán" | coopmart_02 | Nếu tổng = tiền khách đưa và có tiền thối, dùng `khách đưa − tiền thối` khi số đó có in trên hóa đơn (`17e6d79`) |
| Ngày có tên tháng tiếng Anh | circlek_01 | Đọc `18 Jun 2024`, `5 October 2025`, `Oct 21, 2026` (`7a04bd7`) |
| Danh mục: quần áo/khẩu trang chưa là Gear; "sơ mi" bị tính là "mì" | unknown_02, unknown_03 | Bổ sung từ khóa Gear theo quy tắc gán nhãn; mỗi hàng chỉ bỏ phiếu cho từ khóa dài nhất (`7a04bd7`) |
| Chữ nền (túi in chữ xoay ngang) kéo lệch góc nghiêng → cả khối hóa đơn bị dồn vào một hàng | ảnh chụp có nền | Ước lượng góc theo **hướng chung của nhiều dòng nhất** (±10°) thay vì cộng tất cả (`18f299a`) |

### Known limitations (lỗi còn lại sau sửa, không sửa ở Phase 3)

**Tên cửa hàng (main 7/19) là điểm yếu nhất.** Nguyên nhân chính:

| Nguyên nhân | Hóa đơn | Ví dụ (đáp án → parser trả) |
|---|---|---|
| Logo/thương hiệu in kiểu chữ đặc biệt, OCR đọc sai | highlands_01, highlands_03, thietbisieuthi_01, winmart_01, tientho_01 | "HIGHLANDS COFFEE" → "HIGHANDS CUFFE", "HICANOS toEFEF"; "WinMart" → "WMNK Carn vang Ta"; "NHÀ SÁCH TIẾN THỌ" → "THO" |
| Đáp án là "không có" (ảnh không thấy tên cửa hàng) nhưng parser vẫn chọn một hàng | bigc_03, unknown_01, unknown_03, vinmart_01 | → "Cty TNH TH", tên món ăn, địa chỉ facebook, tên sản phẩm |
| Hàng địa chỉ không chứa từ khóa địa chỉ (không có "Đ/c", "Địa chỉ") nên không bị loại | coopmart_01, megamarket_01, vincommerce_01 | → "R1versfde, s0 2, Pho Long Ten II…", "AN KHANH, P. AN PHU…", "Tầng B1 -TTA…" |
| Ghép hàng gộp pháp nhân + tên siêu thị, OCR đọc T thành I | bigc_02 | "BIG C LE TRONG TAN" → "…BIG C LE IRONG TAN" |
| Logo dạng hình, không có chữ | bigc_01 | "Big C Vinh Phuc" → "So Luorg t tesg 5" (dòng "Số lượng") |

**Tổng tiền (main 3 sai, edge 1 sai):**

| Hóa đơn | Đáp án → parser | Nguyên nhân |
|---|---|---|
| bigc_01 | 54.282 → 21.900 | OCR đọc nhãn tổng thành "Tong .087 4.15" (mất số), không còn nhãn nào dùng được → fallback |
| bigc_04 | 349.688 → 500.000 | Ảnh bị cắt, hàng tổng không có trong ảnh; chỉ còn "500,000" (tiền khách đưa) không nhãn → fallback |
| tientho_01 | 10.000 → 20.000 | OCR đọc "10,000" thành "1 LD,000" và "i,000" ở cả hai hàng tổng → fallback lấy cột thành tiền |
| highlands_02 (edge) | 0 → 69.000 | Giảm giá 100%, hàng "Tổng tiền:" không in số → fallback lấy giá món. Parser chỉ nhận số tiền từ 1.000 đ trở lên (`_minAmount`), nên không bao giờ trả 0 |

**Ngày (main 4 sai, edge 1 sai):**

| Hóa đơn | Đáp án → parser | Nguyên nhân |
|---|---|---|
| bigc_02 | 07/05/2020 → null | OCR đọc "07/05/2020" thành "0T/O5/2020" (T thay 7) |
| bigc_04 | null → 27/05/2010 | Lấy nhầm ngày trong số hiệu văn bản pháp lý in đầu hóa đơn ("…ngày 27/05/10…") |
| highlands_03 | 27/06/2025 → null | Hàng ngày bị OCR đọc thành chuỗi vô nghĩa ("FurgzIAE/ 2025 051") |
| winmart_01 | 06/03/2026 → null | OCR mất dấu `/`: "06/02026" |
| unknown_03 (edge) | 12/07/2023 → null | OCR mất dấu `/`: "1207/2023" |

**Danh mục (main 4 sai, 4 không gợi ý):** photoandbike_01, unknown_01, tientho_01 gợi ý Study sai; winmart_01 gợi ý Gear sai (tên hàng thực phẩm bị OCR đọc sai). bigc_01, highlands_01, megamarket_01, vincommerce_01 không gợi ý vì tên cửa hàng sai nên mất từ khóa thương hiệu. Không gợi ý là hành vi đúng thiết kế (FR-3.5: người dùng bắt buộc chọn ở Review).

Phần lớn lỗi còn lại bắt nguồn từ **chất lượng OCR** (logo, chữ mờ, ảnh cắt, ảnh chụp lại từ màn hình) chứ không từ regex. Hướng cải thiện: khung căn chỉnh và chạm lấy nét ở Phase 6 cho ảnh rõ hơn; màn Review (Phase 7) đánh dấu các trường độ tin cậy thấp để người dùng sửa.

⚠️ **Chưa đánh giá trên điện thoại Android thật** (NFR-6). Thời gian OCR và độ chính xác trên máy thật, với ảnh chụp trực tiếp bằng camera, còn nợ; sẽ đo khi có máy (dùng cùng lệnh `run_ocr_eval.ps1 -DeviceId <serial>`).

## Phase 4 — Ca biên CSDL & lưu ảnh

Chạy trên máy tính: `sqflite_common_ffi` (DB in-memory hoặc file trong thư mục tạm) và thư mục tạm cho ảnh. 49 test mới, tất cả pass.

| Ca biên | Test | Kết quả |
|---|---|---|
| Xóa giao dịch có file ảnh/thumbnail **đã bị mất** | `image_storage_service_test.dart` › "does not crash when the photo files were already lost" | ✔ không crash, dòng bị xóa |
| Xóa giao dịch nhập tay (không có ảnh) | › "handles a manual expense without any photo" | ✔ |
| Khoảng ngày: 00:00:00.000 ngày đầu **có**, 23:59:59.999 ngày cuối **có**, 23:59:59.999 hôm trước **không**, 00:00 hôm sau **không** | `sqflite_expense_repository_test.dart` › nhóm `getBetween` | ✔ |
| Khoảng ngày qua cuối tháng/năm (31/12 → 01/01) | › "works across a month and a year boundary" | ✔ |
| Giờ trong tham số bị bỏ qua; khoảng ngược → `ArgumentError` | › nhóm `getBetween` | ✔ |
| `onUpgrade` từ version 1 → 2 (version 2 giả định thêm cột): mọi dòng và giá trị giữ nguyên | `database_service_test.dart` › "upgrading from version 1 keeps every row and value" | ✔ |
| Nâng cấp nhiều bước (1 → 3) chạy đúng thứ tự | › "runs every step … in order" | ✔ |
| Thiếu bước migration → lỗi, DB vẫn ở version 1, dữ liệu còn nguyên (rollback) | › "refuses to upgrade when a step is missing…" | ✔ |
| `amount`, `date`, `created_at`, `updated_at` lưu kiểu INTEGER (kiểm tra bằng `typeof()` của SQLite) | › "stores amount as INTEGER and dates as epoch milliseconds" | ✔ |
| Ảnh hỏng / không tồn tại → `ImageStorageException`, không để lại file dở | `image_storage_service_test.dart` › nhóm `save` | ✔ |
| Không xóa file nằm ngoài `receipts/` (kể cả đường dẫn có `..`) | › "never deletes files outside the receipts folder" | ✔ |

## Phase 5 — State management: ca biên

62 test mới, tất cả pass. Thời gian Undo được điều khiển bằng `fakeAsync`, không chờ thời gian thật (18 test của danh sách giao dịch chạy dưới 1 giây).

| Nhóm | Ca kiểm tra | File test |
|---|---|---|
| Undo (FR-5.4) | Trong 5 s ảnh **còn**; đúng 4,999 s vẫn còn, đến 5 s mới xóa | `test/state/expense_list_notifier_test.dart` |
| | Undo trong thời gian cho phép: bản ghi quay lại **cùng id**, ảnh không bao giờ bị xóa (hẹn giờ đã hủy) | 〃 |
| | Undo sau 5 s: trả `false`, không khôi phục bản ghi mất ảnh | 〃 |
| | `commitDeletion` (SnackBar đóng sớm) xóa ngay, chỉ xóa một lần | 〃 |
| | Hai lần xóa có hai hẹn giờ riêng; giao dịch nhập tay không có ảnh thì không xóa file nào | 〃 |
| | Undo thất bại (DB lỗi): vẫn chờ xóa, file vẫn được dọn sau đó | 〃 |
| | Hủy state (đóng app) khi đang chờ: xóa file ngay | 〃 |
| | `remove` cập nhật danh sách **đồng bộ**, trước khi DB xong; DB lỗi thì giao dịch quay lại | 〃 |
| | `edit` thay ảnh → xóa ảnh cũ; `edit` thất bại → không xóa gì | 〃 |
| Dọn ảnh mồ côi | Khởi động: ảnh không còn bản ghi bị xóa, ảnh có bản ghi giữ nguyên | `test/state/app_startup_test.dart` |
| | Không đụng file ngoài `receipts/`, thư mục con, đường dẫn viết khác dạng (`./`) vẫn được nhận ra | `test/services/image_storage_orphans_test.dart` |
| | DB không đọc được → không xóa gì, không crash | `test/state/app_startup_test.dart` |
| Tuần (T2 → CN) | Luôn 7 phần tử; CN 23:59:59.999 thuộc tuần cũ, T2 00:00 thuộc tuần mới | `test/models/expense_totals_test.dart`, `test/core/date_ranges_test.dart` |
| | Tuần vắt qua 2 tháng (28/09 → 04/10/2026), qua năm mới (28/12/2026 → 03/01/2027) | 〃, `test/state/period_providers_test.dart` |
| | Chuyển tuần trước/sau qua năm mới | `test/state/period_providers_test.dart` |
| Danh mục | Luôn đủ 5 danh mục (0 nếu không chi), tỷ lệ cộng lại = 1 | `test/models/expense_totals_test.dart` |
| | Tất cả = 0: tỷ lệ = 0 (không chia cho 0, không NaN), `isEmpty` cho trạng thái rỗng | 〃, `period_providers_test.dart` |
| Tổng tháng | Đúng biên đầu/cuối tháng; đổi tháng thì mọi tổng đổi theo | `test/state/period_providers_test.dart` |
| Dẫn xuất | Thêm / sửa / xóa / Undo → danh sách, tổng tháng, danh mục, tuần đều cập nhật; loading và lỗi DB lan sang các provider dẫn xuất | `test/state/expense_list_notifier_test.dart` |
| Theme (FR-8.1) | Mặc định theo hệ thống; chọn → áp dụng + lưu; lần chạy sau đọc lại (qua `shared_preferences`); giá trị lạ → hệ thống; `MaterialApp.themeMode` đổi theo | `test/state/theme_mode_provider_test.dart`, `test/services/settings_store_test.dart`, `test/app_theme_mode_test.dart` |
| Quét | idle → processing → result với pipeline thật + OCR giả; OCR ném lỗi → error (tiếng Việt, kèm đường dẫn ảnh); lỗi bất ngờ trong pipeline → error; bấm 2 lần bị bỏ qua; `reset` khi đang chạy bỏ kết quả đến muộn | `test/state/scan_controller_test.dart` |

**Kiểm tra test có thật sự bắt lỗi:** đã cố ý làm hỏng code hai lần rồi chạy lại. Lần 1 đặt hẹn giờ xóa ảnh thành 0 s: 3 test Undo đỏ. Lần 2 đổi biên cuối tuần (`!isBefore(next)` thành `isAfter(next)`): 4 test tuần đỏ. Sau đó khôi phục code.

## Phase 6 — Camera capture

### Test trên máy tính (55 test mới, tất cả pass)

| Nhóm | Ca kiểm tra | File test |
|---|---|---|
| Khung → vùng cắt (FR-1.5) | Viewport 16:9 / 4:3 / 20:9 (dọc) và 1 viewport ngang; preview 9:16, 3:4, 9:20, 16:9, 4:3; `BoxFit.cover`; ảnh 4000×3000, 1920×1080, 1080×2400; xoay EXIF 0/90/180/270; 5 kiểu khung (khung chuẩn, toàn màn, góc trên trái, góc dưới phải, khung 1 px): **1.200 tổ hợp, vùng cắt luôn nằm trong ảnh, số nguyên, ≥ 1×1** | `test/core/frame_geometry_test.dart` |
| | Ví dụ tính tay: cùng tỷ lệ → nhân thẳng; viewport 20:9 + preview 9:16 → (188, 240, 892, 1680); padding 5%; khung chạm mép bị kẹp vào ảnh | 〃 |
| | Ảnh lưu nằm ngang + EXIF 90° cho cùng vùng cắt với ảnh lưu đứng; khung giữa → vùng cắt giữa ở mọi tỷ lệ | 〃 |
| Khung căn chỉnh (FR-1.4) | Nằm giữa, trong viewport, tỷ lệ 0,62 ở cả dọc lẫn ngang | 〃 |
| Chạm lấy nét (FR-1.3) | Điểm chạm → tọa độ 0..1 trên preview có tính phần bị cắt của `cover`; luôn kẹp trong 0..1 | 〃 |
| Cắt ảnh thật | JPEG lưu với EXIF 1/6/3/8: kích thước đúng 540×960, ô đỏ đánh dấu vẫn ở góc trên trái, không còn tag xoay | `test/services/image_crop_service_test.dart` |
| | Cắt theo khung ra đúng 840×1440; ảnh hỏng → `ImageCropException`; ảnh thư viện được xoay đứng, giữ nguyên khung hình | 〃 |
| Overlay | `shouldRepaint` đúng khi khung, màu nền, màu viền, nét vẽ đổi; vùng ngoài khung bị phủ tối, trong khung trong suốt | `test/widgets/receipt_frame_overlay_test.dart` |
| Lớp bọc camera | `enableAudio == false`; `ResolutionPreset.veryHigh`; mã `CameraAccessDenied` (CameraX) và mã iOS → thiếu quyền; plugin vắng mặt → lỗi chung; chọn camera sau; vòng flash | `test/services/camera_service_test.dart` |
| Màn camera (camera giả) | Preview + khung + nút chụp + nút thư viện; vòng flash tắt → tự động → luôn bật → đèn pin → tắt với icon tương ứng; máy không có flash → nút bị vô hiệu + thông báo | `test/screens/camera_screen_test.dart` |
| | Chạm lấy nét: vòng chỉ báo hiện đúng chỗ chạm rồi tự tắt; điểm (0,5; 0,5) gửi cho camera; chỉ gọi focus/exposure khi máy hỗ trợ; không hỗ trợ cả hai → không vòng, có thông báo | 〃 |
| | Từ chối quyền → hướng dẫn + nút "Mở Cài đặt" (gọi `openAppSettings`) + chọn ảnh thư viện; quay lại app → thử mở camera lại | 〃 |
| | Không có camera → thông báo, chọn ảnh thư viện vẫn chạy đến `/review` | 〃 |
| | Chụp → cắt theo khung (đúng viewport, tỷ lệ preview, khung) → chỉnh tay → OCR → `/review`; camera được trả trước khi OCR, mở lại khi quay về | 〃 |
| | Hủy chỉnh tay → quay lại camera, không OCR; OCR không đọc được → hộp thoại "Nhập tay" mở Review kèm ảnh | 〃 |
| | App inactive → trả camera, resumed → mở lại; tab bị ẩn (TickerMode) → trả camera; đóng màn → dispose; màn ngang không overflow | 〃 |

**Kiểm tra test có thật sự bắt lỗi:** cố ý bỏ kiểm tra `focusPointSupported` → test "focus / exposure are only called when supported" đỏ; cố ý không trả camera khi inactive → test vòng đời đỏ. Đã khôi phục code.

### Smoke test trên emulator — nhãn **emulator + webcam**

| Mục | Giá trị |
|---|---|
| Ngày | 10/10/2026, đúng 1 lần chạy |
| Thiết bị | AVD `vku_test_api33` (API 33, x86_64), `hw.camera.back=webcam0` (Integrated Webcam của laptop) |
| Lệnh | `flutter test integration_test/camera_smoke_test.dart -d emulator-5554` (+ `adb shell pm grant … CAMERA`) |
| Kết quả | ✔ **pass** (`01:13 +1: All tests passed!`) |
| Preview | ✔ camera khởi tạo, nút chụp bật; vùng xem 320 × 480 dp; ảnh chụp màn hình cho thấy hình webcam trong khung căn chỉnh |
| Chụp → cắt theo khung | ✔ ảnh cắt 418 × 672 px, dọc |
| OCR | ✔ chạy ML Kit thật: 11.275 ms, **0 hàng chữ** (webcam không nhìn vào hóa đơn nào, nên chỉ thử được luồng chạy, không thử được độ chính xác) |
| Chụp → `/review` | ✔ 26.775 ms, màn Review nhận `ScanResult`, không exception |

Hạn chế của lần smoke test này (không được coi là đã test):
- **`image_cropper` không được thử**: màn cắt của uCrop là activity native, integration test không bấm được, nên trong smoke test bước chỉnh tay được thay bằng bước cho ảnh đi thẳng qua (chỉ nằm trong `integration_test/`).
- Flash, chạm lấy nét, từ chối quyền, chuyển app không thử trên emulator (webcam không có flash, emulator không có điểm lấy nét thật).
- Trong lúc chạy, System UI của emulator báo "isn't responding" (máy 8 GB RAM, Gradle vừa build xong). App vẫn chạy bên dưới và test pass. Ảnh chụp màn hình bị hộp thoại này che một phần.
- Ảnh chụp màn hình có hình xung quanh laptop từ webcam nên **không** đưa vào repo (lưu tạm ngoài repo).

## Phase 7 — Màn Review & Verification

55 test mới, tất cả pass (widget test trên máy tính, chưa thử trên máy thật).

| Nhóm | Ca kiểm tra | File test |
|---|---|---|
| Hiển thị (FR-4.1, 4.2, 4.5, 2.4) | Ảnh + tên + số tiền "245.000" + ngày "14/09/2026" + chip "Ăn uống" từ kết quả quét; chạm ảnh → `InteractiveViewer`; "Xem văn bản OCR gốc" có thời gian OCR 420 ms và các dòng chữ; ảnh không đọc được → thông báo, form vẫn dùng được | `test/screens/review_screen_test.dart` |
| Độ tin cậy (FR-4.4) | Trường `high` không có dấu; tên cửa hàng `missing` → banner đầu form có icon `error` + "Không đọc được tên cửa hàng", nằm trên ô nhập; `low` → icon cảnh báo + "Không chắc chắn — hãy kiểm tra lại"; số tiền / ngày / danh mục có icon + chú thích riêng; ngày thiếu → điền tạm hôm nay; sửa trường → dấu biến mất | 〃 |
| Validator (FR-4.3) | Tên rỗng / chỉ có dấu cách / > 100 ký tự; số tiền rỗng, không phải số, quá 12 chữ số; **hóa đơn 0 đ bị chặn** kèm giải thích "giảm giá toàn bộ"; ngày tương lai (năm đọc nhầm 2062) bị chặn; bộ chọn ngày không cho quá hôm nay; chưa chọn danh mục | `test/core/expense_validators_test.dart`, `review_screen_test.dart` |
| Ô số tiền (FR-4.6) | Gõ từng chữ số → 1 → 1.250 → … → 1.250.000; gõ chữ số ở giữa chuỗi → con trỏ đứng ngay sau chữ số vừa gõ; xóa giữa chuỗi; xóa ngay sau dấu chấm; dán "150,000", "150.000đ", "150.000 VNĐ" → 150.000 và lưu 150000; số 0 ở đầu; hơn 12 chữ số bị từ chối | `test/core/amount_input_test.dart`, `review_screen_test.dart` |
| Lưu (FR-4.8, FR-5.3) | Từ kết quả quét: lưu ảnh + thumbnail rồi `add`, đủ trường, SnackBar "Đã lưu giao dịch.", quay về | `review_screen_test.dart`, `test/state/expense_list_notifier_test.dart` |
| | **Ghi DB lỗi sau khi đã lưu ảnh: ảnh + thumbnail vừa lưu bị xóa, báo lỗi, màn hình không đóng, dữ liệu đã nhập còn nguyên**; lưu ảnh lỗi → không ghi DB | 〃 |
| Ba chế độ (FR-4.9) | Thêm thủ công: không ảnh, ô trống, ngày hôm nay, lưu không gọi lưu ảnh; sửa `/expense/7`: nạp giá trị, lưu gọi `edit` (không `insert`), giữ giờ cũ khi không đổi ngày, SnackBar "Đã cập nhật giao dịch."; id không tồn tại → "Không tìm thấy giao dịch" | `review_screen_test.dart` |
| Hủy (FR-4.8) | Chưa sửa → back quay về ngay; đã sửa → nút back AppBar hỏi "Bỏ thay đổi?" ("Tiếp tục sửa" giữ nguyên dữ liệu, "Bỏ thay đổi" quay về, không lưu); nút back Android cũng hỏi | 〃 |
| Bàn phím, bố cục (FR-4.7) | Ô tên `TextInputAction.next` → Next chuyển sang ô số tiền (bàn phím số); màn 320×480 và màn ngang 640×360 với bàn phím chiếm 45% chiều cao: không overflow, cuộn tới được nút Lưu | 〃 |

**Kiểm tra test có thật sự bắt lỗi:** cố ý bỏ bước xóa ảnh khi ghi DB lỗi → 2 test đỏ; cố ý đặt `canPop: true` → 2 test hủy đỏ. Đã khôi phục code.

**Lỗi test phát hiện trong code:** form ban đầu dùng `ListView` (dựng trường kiểu lười), khiến nút Lưu và ô danh mục chưa tồn tại khi chưa cuộn, nên `Form.validate()` có thể bỏ qua chúng. Đã đổi sang `SingleChildScrollView` + `Column` (D-051).

## Phase 8 — Lịch sử & Dashboard

25 test mới, tất cả pass (widget test trên máy tính).

| Nhóm | Ca kiểm tra | File test |
|---|---|---|
| Card (FR-7.3) | Bố cục bài lab Week 7: icon danh mục trong `CircleAvatar`, tên + ngày xếp dọc với `CrossAxisAlignment.start`, "150.000 đ", `Card` + `InkWell`; thumbnail giải mã nhỏ (`cacheWidth` = 48 × tỷ lệ điểm ảnh); **file thumbnail mất → icon thay thế, không crash** | `test/widgets/expense_summary_card_test.dart` |
| Lịch sử | Mới nhất trước; `ListView.builder` + `Dismissible` + `ValueKey<int>(id)`; chip lọc theo danh mục; chạm card → `/expense/:id`; nút "Thêm thủ công" | `test/screens/history_screen_test.dart` |
| | Hai trạng thái rỗng: "Chưa có giao dịch nào" (DB trống, không hiện chip) và "Không có giao dịch thuộc danh mục Giải trí" (có nút "Xem tất cả") | 〃 |
| Undo (FR-5.4) | SnackBar có `duration == ExpenseListNotifier.undoWindow`; **đúng một cửa sổ Undo sau khi vuốt SnackBar vẫn hiện, bấm "Hoàn tác" khôi phục bản ghi và ảnh không bị xóa**; hết thời gian → xóa hẳn cả ảnh và thumbnail | 〃 |
| | **Xóa liên tiếp 2 giao dịch:** SnackBar thứ hai thay thế SnackBar thứ nhất, giao dịch thứ nhất bị chốt xóa ngay (kể cả ảnh), Undo chỉ khôi phục giao dịch thứ hai | 〃 |
| | Card bị vuốt rời danh sách ngay, không có lỗi "dismissed Dismissible is still part of the tree"; `holdForUndo` giữ lần xóa cho tới khi SnackBar quyết định | 〃, `test/state/expense_list_notifier_test.dart` |
| Dashboard | Tổng tháng theo `selectedMonthProvider` (1.250.000 đ, "2 giao dịch"); nút tháng trước/sau, không cho sang tháng tương lai; tháng rỗng → 0 đ + "Chưa có giao dịch trong tháng này"; thêm giao dịch → tổng đổi ngay; hai chỗ cho biểu đồ Phase 9, xếp cạnh nhau ở màn rộng; nút "Thêm thủ công" mở Review không ảnh | `test/screens/dashboard_screen_test.dart` |

**Lỗi test phát hiện trong code:**
- SnackBar có nút hành động mặc định **không tự đóng** trong Flutter 3.47 (`persist = action != null`), nên lần xóa không bao giờ được chốt. Đã đặt `persist: false` (D-058).
- Chip lọc trong hàng cuộn ngang bị khuất ở màn 360 dp. Đã đổi sang `Wrap` (D-060).

**Kiểm tra test có thật sự bắt lỗi:** cố ý bỏ `holdForUndo` → test "Undo while the snack bar shows…" đỏ (khi đó hẹn giờ 5 s xóa ảnh trước khi SnackBar đóng). Đã khôi phục code.

### Integration test luồng chính (chưa chạy)

`integration_test/app_flow_test.dart`: thêm thủ công từ Dashboard → tổng tháng thành 35.000 đ → xuất hiện ở Lịch sử → vuốt xóa → "Hoàn tác" → giao dịch quay lại, tổng vẫn 35.000 đ. Dùng file DB `it_app_flow.db` và thư mục ảnh riêng, xóa khi xong.

```powershell
flutter test integration_test/app_flow_test.dart -d <device id>
```

⚠ **Chưa chạy** (chưa có thiết bị; Phase 8 không bật emulator). Đã ghi vào Việc còn nợ trong `CLAUDE.md`.

## Phase 9 — Biểu đồ CustomPainter

68 test mới, tất cả pass (máy tính). Phần hình học (`chart_geometry.dart`) và hai painter được phủ 100% dòng.

| Nhóm | Ca kiểm tra | File test |
|---|---|---|
| Hình học donut | Tỷ lệ cộng lại = 1, tất cả 0 không NaN; lát bắt đầu 12h theo chiều kim đồng hồ; 1 lát 100% = cả vòng; nhiều lát < 1% cộng đủ 2π; chuẩn hóa góc về [0, 2π) | `test/widgets/charts/chart_geometry_test.dart` |
| Hit-test `atan2` (FR-6.2) | 4 lát đều: 12h → 0, 3h → 1, 6h → 2, 9h → 3; sát 12h hai phía → lát đầu / lát cuối; ranh giới thuộc lát bắt đầu tại đó; lát rỗng bị bỏ qua; lát < 1% chạm trúng ở giữa; **lỗ giữa, ngoài vòng, ngoài vùng vẽ → null**; không có dữ liệu → null | 〃 |
| Hình học cột (FR-6.3) | 7 cột đều, khoảng cách đều; đáy ở `size.height − lề dưới`; cột lớn nhất cao hết vùng vẽ, cột khác tỷ lệ; cột 0 có chân 3 px (D-062); tất cả 0 không chia cho 0; chạm theo cột (cả khe giữa hai cột), ngoài vùng → null | 〃 |
| `shouldRepaint` (FR-6.4) | Mỗi painter: không vẽ lại khi giống hệt; vẽ lại khi **dữ liệu** đổi, khi **màu** đổi, khi **progress** đổi, khi **phần tử chọn** đổi (cột: cả "hôm nay") — mỗi tiêu chí một test | `test/widgets/charts/chart_painters_test.dart` |
| Vẽ | Donut: vòng nền + một `drawArc` cho mỗi lát khác 0; cột: 7 `drawRRect` | 〃 |
| DonutChart | Quét 0 → 1, xong với `pumpAndSettle`; legend màu/tên/số tiền/%; chạm lát → nổi bật + chi tiết, chạm lại / lỗ giữa → bỏ chọn; dữ liệu mới → quét lại, lát đang chọn biến mất → bỏ chọn; **dữ liệu đổi giữa chừng animation không lỗi**; dữ liệu bằng nhau không chạy lại; tháng rỗng → thông điệp; Semantics; tổng 123 tỷ → "123,46 tỷ đ"; 320 dp chữ 1,5× không overflow | `test/widgets/charts/chart_widgets_test.dart` |
| WeeklyBarChart | 7 cột mọc lên rồi dừng; khoảng ngày "05/10 – 11/10/2026"; hôm nay nổi bật; chạm cột → "CN 11/10: 120.000 đ", cột 0 → "0 đ", chạm lại → bỏ chọn; tuần khác → chạy lại, bỏ chọn; nút tuần trước/sau; tuần rỗng → thông điệp, vẫn chuyển tuần được; Semantics; 320 dp chữ 1,5× | 〃 |
| Dashboard (FR-6.5, FR-8.2) | Biểu đồ lấy đúng tháng/tuần; thêm, sửa, xóa giao dịch → cả hai biểu đồ cập nhật và animation chạy lại; nút tuần không vượt tuần hiện tại; 320 dp và màn ngang với chữ 1,5×, cuộn hết trang: không overflow; ≥ 600 dp hai biểu đồ cạnh nhau | `test/screens/dashboard_screen_test.dart` |
| Kiến trúc | Không có gói nào chứa "chart" trong `pubspec.yaml` / `pubspec.lock` (và không có `fl_chart`, `syncfusion_flutter_charts`…); không file nào trong `lib/` import gói chart; `chart_geometry.dart` chỉ import `dart:math`, `dart:ui`; hai painter `extends CustomPainter` | `test/widgets/charts/chart_architecture_test.dart` |
| Định dạng | `compactVnd`: 75k, 59,5k, 1tr, 1,25tr, 2,5 tỷ; `percent`: 37,5% | `test/core/formatters_test.dart` |

**Lỗi test phát hiện trong code:** dòng legend tràn (RenderFlex overflow 18 px và 82 px) ở 320 dp khi chữ hệ thống 1,5× hoặc số tiền rất lớn. Đã sửa bằng `FittedBox` cho cụm số tiền + % (D-067).

**Kiểm tra test có thật sự bắt lỗi (chỉ phần hình học):**

| Đột biến | Test đỏ |
|---|---|
| `angleToSliceIndex` bỏ `− startAngle` (đo góc từ 3h thay vì 12h) | 7 test (5 test hit-test hình học + 2 test chạm donut) |
| `barRects` bỏ chiều cao tối thiểu | 3 test (chân cột 0, tất cả 0, giá trị rất nhỏ) |
| `barRects` treo cột từ mép trên xuống | 2 test (đáy cột, chân cột 0) |

Lần đầu thử đột biến thứ ba bằng cách đổi `baseline` thành `layout.top + plot`; giá trị đó bằng đúng `baseline` (đột biến tương đương), nên không test nào đỏ. Đã làm lại bằng một đột biến thật như trong bảng. Code đã khôi phục sau mỗi lần.

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
- [ ] *(Kết quả OCR trên hóa đơn thật xem ở màn Review từ Phase 7: chụp hoặc chọn ảnh → Review → "Xem văn bản OCR gốc". Độ chính xác đo bằng công cụ ở mục Phase 3.)*


### Phase 3 — Dịch vụ OCR

Đã chạy trên emulator `vku_test_api33` (API 33) bằng công cụ chấm tự động, xem mục "Độ chính xác trên hóa đơn thật". **Chưa test trên điện thoại thật.** Màn debug OCR của Phase 3 đã được gỡ ở Phase 7; kết quả OCR giờ xem ở màn Review (checklist Phase 6–7).

Thiết bị: `__________` · Android `____`

- [ ] Bật **chế độ máy bay** rồi quét một hóa đơn → vẫn nhận dạng được (OCR offline, NFR-1).
- [ ] Chọn một ảnh hỏng từ thư viện → thông báo tiếng Việt, app không crash.
- [ ] Chạy đánh giá trên máy thật và ghi kết quả vào mục độ chính xác:
      `powershell -ExecutionPolicy Bypass -File tool\ocr_eval\run_ocr_eval.ps1 -DeviceId <serial>`

### Phase 4 — CSDL & lưu ảnh (chưa có giao diện mới)

Phase này chưa nối DB vào màn hình nào (Phase 5 làm state, Phase 7 làm Review). Trên máy thật chỉ cần kiểm tra plugin sqflite và `path_provider` thật:

Thiết bị: `__________` · Android `____`

- [ ] `flutter test integration_test/storage_test.dart -d <máy>` → pass (lưu ảnh + thumbnail vào thư mục documents thật, insert/truy vấn/xóa bằng sqflite thật, file được xóa).
- [ ] `flutter run` → app vẫn mở bình thường ở tab **Tổng quan**.

### Phase 5 — State management (chưa có giao diện mới, trừ chế độ sáng/tối)

Thiết bị: `__________` · Android `____`

- [ ] `flutter run` → app mở bình thường. Từ phase này `main()` mở DB và `shared_preferences` trước khung hình đầu: không màn hình đỏ, không treo ở màn hình trắng.
- [ ] Đổi Dark mode trong cài đặt điện thoại → app đổi theo (mặc định "theo hệ thống").
- [ ] Đóng hẳn app rồi mở lại → vẫn mở bình thường (DB mở lại được, dọn ảnh mồ côi không lỗi).
- [ ] *(Nút chuyển sáng/tối/hệ thống có ở Phase 10; khi đó kiểm tra lựa chọn còn nguyên sau khi mở lại app.)*

### Phase 6 — Camera capture (bắt buộc làm trên điện thoại thật)

Thiết bị: `__________` · Android `____`

- [ ] Lần đầu mở tab **Quét**: hiện hộp thoại xin quyền camera (không xin micro). Cho phép → thấy preview.
- [ ] Preview **đúng tỷ lệ** (vật tròn không bị méo), lấp đầy vùng xem, không viền đen lạ.
- [ ] Nút **flash** đổi icon tắt → tự động → luôn bật → đèn pin; ở chế độ đèn pin đèn sáng thật; chụp ở "luôn bật" thì đèn nháy.
- [ ] **Chạm lấy nét**: chạm vào một dòng chữ → vòng vàng hiện đúng chỗ chạm, ảnh nét lại ở chỗ đó.
- [ ] Chụp một hóa đơn thật đặt trong khung → màn chỉnh vùng cắt (`image_cropper`) **mở được**; vùng cắt sẵn **khớp với khung** đã thấy (không lệch, không mất chữ ở mép).
- [ ] Ảnh sau khi cắt **không bị xoay** (thử cả lúc cầm máy dọc và ngang).
- [ ] Bấm "Hủy" ở màn chỉnh → quay về camera, có thông báo "Đã hủy quét."
- [ ] Xác nhận cắt → hiện "Đang đọc hóa đơn…" → sang màn Review.
- [ ] Nút thư viện: chọn một ảnh hóa đơn → màn chỉnh → Review.
- [ ] **Từ chối quyền** (hoặc tắt quyền camera trong Cài đặt) → mở lại tab Quét: thấy hướng dẫn + nút "Mở Cài đặt". Bấm → vào trang cài đặt của app, **cấp lại quyền**, quay về → camera tự chạy lại.
- [ ] **Chuyển app** (Home rồi quay lại, hoặc mở app khác) khi đang ở tab Quét → camera vẫn chạy, không màn đen, không crash.
- [ ] Chuyển sang tab khác rồi quay lại tab Quét → camera chạy lại (đèn báo camera của Android tắt khi rời tab).
- [ ] Xoay ngang điện thoại ở tab Quét → không có dải sọc vàng-đen (overflow).

### Phase 7 — Màn Review & Verification

Thiết bị: `__________` · Android `____`

- [ ] Quét một hóa đơn → màn Review hiện ảnh, các trường đã điền; chạm ảnh → phóng to bằng hai ngón.
- [ ] Trường không chắc chắn có **icon + dòng chú thích**; nếu tên cửa hàng không chắc, banner màu ở đầu form nổi bật nhất.
- [ ] Ô tên → bấm **Next** trên bàn phím → con trỏ sang ô số tiền, bàn phím **số** hiện ra.
- [ ] Gõ 1250000 → thấy 1.250.000; đặt con trỏ giữa chuỗi rồi gõ/xóa → con trỏ không nhảy; dán "150,000" → 150.000.
- [ ] Bàn phím mở: form cuộn được tới nút Lưu, không có dải sọc vàng-đen (cả dọc lẫn ngang).
- [ ] Bộ chọn ngày hiện **tiếng Việt**, không cho chọn ngày sau hôm nay.
- [ ] Để trống tên / nhập 0 / chưa chọn danh mục → bấm Lưu → thông báo tiếng Việt dưới từng ô.
- [ ] Lưu hợp lệ → SnackBar "Đã lưu giao dịch." → quay về camera. (Lịch sử hiển thị ở Phase 8.)
- [ ] Sửa một ô rồi bấm nút **back của Android** → hỏi "Bỏ thay đổi?".
- [ ] Mở "Xem văn bản OCR gốc" → thấy các dòng chữ và thời gian OCR (ms); ghi lại thời gian OCR trên máy thật cho báo cáo.

### Phase 8 — Lịch sử & Dashboard

Thiết bị: `__________` · Android `____`

- [ ] `flutter test integration_test/app_flow_test.dart -d <máy>` → pass.
- [ ] Tab **Lịch sử**: giao dịch mới nhất ở trên, có thumbnail cho giao dịch có ảnh, cuộn mượt với nhiều giao dịch.
- [ ] Chạm chip danh mục → danh sách lọc đúng; danh mục không có giao dịch → thông báo riêng + "Xem tất cả".
- [ ] Vuốt trái một giao dịch → biến mất, SnackBar "Đã xóa …" + "Hoàn tác" khoảng 5 giây; bấm "Hoàn tác" → quay lại, thumbnail vẫn hiện.
- [ ] Vuốt xóa hai giao dịch liên tiếp → chỉ hoàn tác được giao dịch thứ hai.
- [ ] Chạm một giao dịch → mở màn Sửa; sửa số tiền → Lưu → Lịch sử và Dashboard cập nhật.
- [ ] Tab **Tổng quan**: tổng tháng đúng; nút tháng trước/sau đổi tháng và tổng; không sang được tháng sau tháng hiện tại.
- [ ] Nút "Thêm thủ công" → màn Review trống, không ảnh.
- [ ] Xoay ngang ở Lịch sử và Tổng quan → không overflow; Tổng quan đặt hai khung biểu đồ cạnh nhau.

### Phase 9 — Biểu đồ CustomPainter

Thiết bị: `__________` · Android `____`

- [ ] Mở tab **Tổng quan**: donut quét một vòng, cột mọc lên **mượt** (không giật, không nháy).
- [ ] Thêm / sửa / xóa một giao dịch rồi quay lại Tổng quan: số liệu đổi và animation chạy lại.
- [ ] Chạm từng lát donut, cả **lát nhỏ** và chỗ **gần ranh giới** hai lát: lát được chọn đúng, dày hơn, hiện chi tiết; chạm lại hoặc chạm lỗ giữa → bỏ chọn.
- [ ] Chạm từng cột (kể cả ngày 0 đ): hiện đúng ngày và số tiền; ngày hôm nay có màu đậm.
- [ ] Nút tuần trước/sau: khoảng ngày đổi, không sang được tuần sau tuần hiện tại.
- [ ] Tháng/tuần không có chi tiêu: thấy thông điệp thay vì biểu đồ trống.
- [ ] Cài đặt → cỡ chữ lớn nhất: chữ trong lỗ donut không tràn, legend không có dải sọc vàng-đen.
- [ ] Xoay ngang (hoặc máy tính bảng): donut và cột nằm cạnh nhau.
- [ ] Bật **TalkBack**: chạm vào biểu đồ → đọc mô tả (danh mục, số tiền, %; các ngày trong tuần).
