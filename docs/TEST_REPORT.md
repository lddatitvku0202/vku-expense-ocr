# Báo cáo kiểm thử

## Tổng hợp theo phase

| Phase | Số test | Pass / Fail | Coverage | Format | Analyze | Build debug | Test trên thiết bị |
|---|---|---|---|---|---|---|---|
| 0 | 1 | 1 / 0 | — | ✔ | ✔ 0 issue | ✔ | ⚠ Chưa test trên thiết bị (chưa có máy kết nối) |
| 1 | 48 | 48 / 0 | 85.3% dòng | ✔ | ✔ 0 issue | ✔ | ⚠ Chưa test trên thiết bị (chưa có máy kết nối) |
| 2 | 201 | 201 / 0 | 94.9% dòng | ✔ | ✔ 0 issue | ✔ | ⚠ Chưa test trên thiết bị (Phase 2 không có UI mới) |
| 3 | 272 | 272 / 0 | 95.6% dòng | ✔ | ✔ 0 issue | ✔ | 🟨 Emulator `vku_test_api33` (API 33): đánh giá 22 hóa đơn thật tự động. ⚠ **Chưa test trên điện thoại thật** |

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


### Phase 3 — Dịch vụ OCR (màn debug tạm)

Đã chạy trên emulator `vku_test_api33` (API 33) bằng công cụ chấm tự động, xem mục "Độ chính xác trên hóa đơn thật". **Chưa test trên điện thoại thật.**

Thiết bị: `__________` · Android `____`

- [ ] Tab **Quét** có nút mở màn debug OCR (`/debug/ocr`).
- [ ] Bấm chọn ảnh → mở thư viện ảnh; chọn một hóa đơn → hiện vòng loading, **giao diện không bị đứng**.
- [ ] Hiện tên cửa hàng, tổng tiền, ngày, danh mục kèm độ tin cậy; trường không đọc được ghi là thiếu (không crash).
- [ ] Mở "Xem văn bản OCR gốc" → thấy các hàng chữ đã ghép và thời gian OCR (ms).
- [ ] Bật **chế độ máy bay** rồi quét lại → vẫn nhận dạng được (OCR offline, NFR-1).
- [ ] Chọn một file không phải ảnh hoặc ảnh hỏng → hiện thông báo lỗi tiếng Việt, app không crash.
- [ ] Hủy chọn ảnh (bấm Back trong thư viện) → quay lại màn debug, không lỗi.
- [ ] Chạy đánh giá trên máy thật và ghi kết quả vào mục độ chính xác:
      `powershell -ExecutionPolicy Bypass -File tool\ocr_eval\run_ocr_eval.ps1 -DeviceId <serial>`
