# Bảng regex của bộ phân tích hóa đơn (FR-3.7)

> Nguồn cho mục "Bảng regex OCR" của báo cáo. Regex được **trích tự động từ mã nguồn** (`lib/core/text_normalizer.dart`, `lib/services/receipt_parser.dart`, `lib/services/receipt_keywords.dart`) và mọi ví dụ khớp / không khớp đã được chạy thử trước khi ghi file. Sinh lại sau khi sửa regex: `python tool/regex_table/gen_regex_table.py`.

## Cách một hàng hóa đơn được xử lý

1. `RowGrouper` ghép các dòng ML Kit cùng độ cao thành **một hàng** (FR-2.3, dùng hình học, không dùng regex).
2. `repairDigits` (R3) sửa chữ O/l lẫn trong số → `normalize` (R1, R2) bỏ dấu, chữ thường, gộp khoảng trắng.
3. `ocrKey` gộp ký tự OCR hay nhầm (bảng bên dưới) để so khớp từ khóa (R4–R10, R18–R20, R25–R29).
4. Trước khi tìm số tiền (R15): xóa số sau nhãn liên hệ (R10 + R11), ngày (R12), giờ (R13), đơn giá (R14).

| Ký tự OCR | Gộp thành (chỉ khi so khớp từ khóa) | Ví dụ |
|---|---|---|
| `0` | `o` | `T0NG C0NG` → `tong cong` |
| `1`, `l`, `\|` | `i` | `Tong tlen` → `tong tien`; từ khóa `total` → `totai` ở cả hai phía |

## Bảng tổng hợp

| ID | Pattern | Dùng ở |
|---|---|---|
| R1 | Dấu kết hợp (dạng NFD) | `TextNormalizer.removeDiacritics` |
| R2 | Khoảng trắng liên tiếp | `TextNormalizer.normalize` |
| R3 | Token giống số (sửa chữ OCR đọc nhầm) | `TextNormalizer.repairDigits` |
| R4 | Từ khóa "thanh toán cuối cùng" (ưu tiên 3) | `receipt_keywords.dart` → `finalTotalKeywords` (17 từ khóa) |
| R5 | Từ khóa tổng chung (ưu tiên 2) | `receipt_keywords.dart` → `totalKeywords` (6 từ khóa) |
| R6 | "Cộng:" đầu hàng (ưu tiên 2) | `_kindPatterns` |
| R7 | Từ khóa tạm tính (ưu tiên 1) | `receipt_keywords.dart` → `subtotalKeywords` (9 từ khóa) |
| R8 | Tiền khách đưa, tiền thối, đặt cọc | `receipt_keywords.dart` → `tenderKeywords` (19 từ khóa) |
| R9 | Hàng có tiền nhưng không phải tổng | `receipt_keywords.dart` → `notTotalKeywords` (34 từ khóa) |
| R10 | Nhãn số điện thoại / MST / số chứng từ | `receipt_keywords.dart` → `contactKeywords` (34 từ khóa) |
| R11 | Dãy số sau nhãn liên hệ | `_RowScan.of` (dùng `matchAsPrefix` ngay sau R10) |
| R12 | Ngày (để xóa trước khi tìm tiền) | `_RowScan.of` |
| R13 | Giờ | `_RowScan.of` |
| R14 | Đơn giá trong "số lượng × đơn giá" | `_RowScan.of` (xóa nhóm 1) |
| R15 | Số tiền | `_RowScan.of` |
| R16 | Đơn vị tiền tệ | `_RowScan.of` (kiểm tra hàng chỉ có số tiền) |
| R17 | Ngày DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY, DD/MM/YY | `ReceiptParser.extractDate` |
| R18 | Nhãn ngày giao dịch | `_dateLabel` (dựng bằng `_keywordPattern`) |
| R19 | Hàng không phải tên cửa hàng | `receipt_keywords.dart` → `notNameKeywords` (47 từ khóa) |
| R20 | Dòng pháp nhân | `receipt_keywords.dart` → `companyKeywords` (12 từ khóa) |
| R21 | Địa chỉ có số nhà | `ReceiptParser._isNotName` |
| R22 | Giá tiền trong hàng (hàng món ăn) | `ReceiptParser._isNotName` |
| R23 | Chữ cái Unicode | `ReceiptParser.extractMerchant` |
| R24 | Chữ số | `ReceiptParser._isNotName` |
| R25 | Ăn uống (food) | `receipt_keywords.dart` → `foodKeywords` (95 từ khóa) |
| R26 | Học tập (study) | `receipt_keywords.dart` → `studyKeywords` (38 từ khóa) |
| R27 | Di chuyển (travel) | `receipt_keywords.dart` → `travelKeywords` (56 từ khóa) |
| R28 | Thiết bị (gear) | `receipt_keywords.dart` → `gearKeywords` (64 từ khóa) |
| R29 | Giải trí (entertainment) | `receipt_keywords.dart` → `entertainmentKeywords` (35 từ khóa) |

## A. Chuẩn hóa văn bản (FR-3.1) — `lib/core/text_normalizer.dart`

### R1. Dấu kết hợp (dạng NFD)

```regex
[\u0300-\u036F]
```

- **Dùng ở:** `TextNormalizer.removeDiacritics`
- **Mục đích:** Xóa dấu thanh/dấu mũ khi chữ tiếng Việt ở dạng tách (NFD), ví dụ "e" + dấu mũ + dấu huyền.
- **Ví dụ khớp:** `T + i + e + U+0302 + U+0300 + n` (dạng NFD)
- **Ví dụ không khớp:** `Tiền`, `Tien`
- **Giới hạn đã biết:** Chỉ phủ khối U+0300–U+036F (đủ cho tiếng Việt). Chữ dựng sẵn (NFC) được xử lý bằng bảng tra, không bằng regex.

### R2. Khoảng trắng liên tiếp

```regex
\s+
```

- **Dùng ở:** `TextNormalizer.normalize`
- **Mục đích:** Gộp mọi chuỗi khoảng trắng (space, tab, xuống dòng) thành một dấu cách.
- **Ví dụ khớp:** `Khách   phải	trả`
- **Ví dụ không khớp:** `Tổng`
- **Giới hạn đã biết:** —

### R3. Token giống số (sửa chữ OCR đọc nhầm)

```regex
(?<![A-Za-z])[0-9OoIl|][0-9OoIl|.,/:\-]*[0-9OoIl|](?![A-Za-z])
```

- **Dùng ở:** `TextNormalizer.repairDigits`
- **Mục đích:** Tìm token gồm chữ số lẫn các chữ trông giống số (O, o, I, l, |). Nếu token có ≥ 2 chữ số thật thì đổi O/o → 0, I/l/| → 1.
- **Ví dụ khớp:** `139.5OO`, `24/10/2O26`, `2l/10/2026`
- **Ví dụ không khớp:** `LOTTE Mart`, `Lô A2`, `Sữa 1L`
- **Giới hạn đã biết:** Không sửa token dính liền chữ cái ("1O5.OOOd" khi OCR đọc "đ" thành "d"). Không sửa S→5, B→8 (dễ sai).

## B. Từ khóa tổng tiền và loại trừ (FR-3.2) — `lib/services/receipt_parser.dart`

### R4. Từ khóa "thanh toán cuối cùng" (ưu tiên 3)

```regex
(?<![a-z0-9])(?:<từ khóa 1>|<từ khóa 2>|…)(?![a-z0-9])
```

- **Dùng ở:** `receipt_keywords.dart` → `finalTotalKeywords` (17 từ khóa)
- **Mục đích:** Hàng chứa số tiền khách thực trả sau giảm giá/VAT.
- **Từ khóa (17):** `tong thanh toan`, `tong tien thanh toan`, `tong so tien thanh toan`, `tong cong thanh toan`, `can thanh toan`, `phai thanh toan`, `con phai thanh toan`, `khach phai tra`, `khach can tra`, `tong phai tra`, `phai tra`, `amount due`, `total due`, `grand total`, `total payment`, `total amount`, `net total`
- **Ví dụ khớp:** `Tổng thanh toán 245.000`, `TONG TIEN THANH TOAN 139,500`, `Khách phải trả 100.000đ`, `Amount due 945,250`
- **Ví dụ không khớp:** `Tổng tiền hàng 260.000`, `Tổng cộng 119.000`
- **Giới hạn đã biết:** Khuôn mẫu chung của mọi bảng từ khóa: từ khóa được bỏ dấu + gộp ký tự OCR (`ocrKey`), sắp dài trước ngắn, có ranh giới từ. Ở cùng vị trí, từ khóa dài hơn thắng ("tong tien thanh toan" thắng "tong tien").

### R5. Từ khóa tổng chung (ưu tiên 2)

```regex
(?<![a-z0-9])(?:<từ khóa 1>|<từ khóa 2>|…)(?![a-z0-9])
```

- **Dùng ở:** `receipt_keywords.dart` → `totalKeywords` (6 từ khóa)
- **Mục đích:** Hàng tổng tiền thông thường. "Tong tlen", "T0NG C0NG" vẫn khớp nhờ `ocrKey` (l→i, 0→o).
- **Từ khóa (6):** `tong cong`, `tong tien`, `tong`, `total`, `thanh toan`, `da thanh toan`
- **Ví dụ khớp:** `Tổng cộng / Total 94.000 đ`, `Tong tlen 155,000`, `T0NG CONG 70.000d`, `Thanh toán MoMo`
- **Ví dụ không khớp:** `Subtotal 49,000`, `Thời gian: 10:47`
- **Giới hạn đã biết:** "tong" đơn lẻ cũng khớp, nên "Tổng đài", "Tổng số lượng" cần bảng R8/R9 (dài hơn) để thắng.

### R6. "Cộng:" đầu hàng (ưu tiên 2)

```regex
^cong(?![a-z0-9])
```

- **Dùng ở:** `_kindPatterns`
- **Mục đích:** Hóa đơn viết tay chỉ ghi "Cộng: 110.000đ". Chỉ tính khi ở đầu hàng.
- **Ví dụ khớp:** `Cộng: 110.000đ`, `Công ty TNHH`
- **Ví dụ không khớp:** `Đối diện cổng KTX VKU`
- **Giới hạn đã biết:** Regex cũng khớp "Công ty TNHH", nhưng khi phân loại R9 ("cong ty", dài hơn) thắng; "Cộng tiền hàng" thì R7 thắng.

### R7. Từ khóa tạm tính (ưu tiên 1)

```regex
(?<![a-z0-9])(?:<từ khóa 1>|<từ khóa 2>|…)(?![a-z0-9])
```

- **Dùng ở:** `receipt_keywords.dart` → `subtotalKeywords` (9 từ khóa)
- **Mục đích:** Tổng trước giảm giá/VAT; chỉ dùng khi không có R4/R5 và cho độ tin cậy thấp.
- **Từ khóa (9):** `tong tien hang`, `cong tien hang`, `tong gia tri hang`, `tien hang`, `tam tinh`, `thanh tien`, `subtotal`, `sub total`, `sub-total`
- **Ví dụ khớp:** `Tổng tiền hàng 260.000`, `Tạm tính / Subtotal`, `Thành tiền 119.000`, `SUBTOTAL 49,000`
- **Ví dụ không khớp:** `Tổng thanh toán 245.000`
- **Giới hạn đã biết:** —

### R8. Tiền khách đưa, tiền thối, đặt cọc

```regex
(?<![a-z0-9])(?:<từ khóa 1>|<từ khóa 2>|…)(?![a-z0-9])
```

- **Dùng ở:** `receipt_keywords.dart` → `tenderKeywords` (19 từ khóa)
- **Mục đích:** Những hàng này không bao giờ là tổng chi (thường lớn hơn tổng).
- **Từ khóa (19):** `tien khach dua`, `khach dua`, `tien khach tra`, `khach tra`, `khach thanh toan`, `tien mat`, `tien thua`, `tien thoi`, `tien tra lai`, `thoi lai`, `tra lai`, `tien du`, `da coc`, `dat coc`, `con lai`, `cash`, `change`, `tendered`, `received`
- **Ví dụ khớp:** `Tiền khách đưa 500.000`, `Khách thanh toán 100.000`, `CASH 100,000`, `Tiền thối lại 255.000`, `Đã cọc: 500.000đ`
- **Ví dụ không khớp:** `Cashier: Minh`, `Tổng cộng 84.000`
- **Giới hạn đã biết:** "Thanh toán bằng tiền mặt" khớp R5 trước (vị trí sớm hơn) nên vẫn là hàng tổng.

### R9. Hàng có tiền nhưng không phải tổng

```regex
(?<![a-z0-9])(?:<từ khóa 1>|<từ khóa 2>|…)(?![a-z0-9])
```

- **Dùng ở:** `receipt_keywords.dart` → `notTotalKeywords` (34 từ khóa)
- **Mục đích:** Giảm giá, thuế, số lượng, điểm tích lũy, hình thức thanh toán, tiêu đề chứng từ.
- **Từ khóa (34):** `giam gia`, `ma giam gia`, `tong giam gia`, `chiet khau`, `tong chiet khau`, `khuyen mai`, `tong khuyen mai`, `uu dai`, `discount`, `voucher`, `thue`, `tien thue`, `tong thue`, `tong tien thue`, `vat`, `tax`, `phi dich vu`, `service charge`, `so luong`, `tong so luong`, `sl`, `tong sl`, `qty`, `quantity`, `diem`, `tich luy`, `points`, `hinh thuc`, `phuong thuc`, `payment method`, `hoa don`, `phieu`, `bien nhan`, `cong ty`
- **Ví dụ khớp:** `Giảm giá thành viên -15.000`, `VAT 8% (đã bao gồm) 8.815`, `Tổng số lượng 5`, `Điểm tích lũy 451`
- **Ví dụ không khớp:** `Tổng cộng 1.018.710`
- **Giới hạn đã biết:** Phân loại theo từ khóa xuất hiện sớm nhất: "Tổng tiền 245.000 (gồm VAT)" vẫn là hàng tổng vì "tong tien" đứng trước "vat".

### R10. Nhãn số điện thoại / MST / số chứng từ

```regex
(?<![a-z0-9])(?:<từ khóa 1>|<từ khóa 2>|…)(?![a-z0-9])
```

- **Dùng ở:** `receipt_keywords.dart` → `contactKeywords` (34 từ khóa)
- **Mục đích:** Dãy số ngay sau các nhãn này bị xóa trước khi tìm số tiền.
- **Từ khóa (34):** `dt`, `dien thoai`, `sdt`, `tel`, `phone`, `hotline`, `tong dai`, `zalo`, `fax`, `mst`, `ma so thue`, `tax code`, `vat reg`, `so hd`, `so hoa don`, `hoa don so`, `ma hd`, `hd`, `so ct`, `so chung tu`, `so phieu`, `so`, `ma`, `ma don`, `ma giao dich`, `invoice no`, `receipt no`, `receipt`, `order`, `imei`, `serial`, `s/n`, `stk`, `so tai khoan`
- **Ví dụ khớp:** `ĐT: (0234) 3588 555`, `Hotline 19006750`, `MST: 0301175691`, `Số HĐ: 123456`
- **Ví dụ không khớp:** `Hotel Saigon`, `Total 49,000`
- **Giới hạn đã biết:** Chỉ xóa dãy số liền sau nhãn; số điện thoại không có nhãn ("0905 123 456") bị loại nhờ R15 (số 0 đầu, < 4 chữ số).

### R11. Dãy số sau nhãn liên hệ

```regex
[\s:.#/]*[(+]?\d[\d\s.,()+\-/]*
```

- **Dùng ở:** `_RowScan.of` (dùng `matchAsPrefix` ngay sau R10)
- **Mục đích:** Lấy phần ": (0234) 3588 555" sau "ĐT" để xóa.
- **Ví dụ khớp:** `: (0234) 3588 555`, ` 19006750`
- **Ví dụ không khớp:** —
- **Giới hạn đã biết:** Nếu số tiền đứng ngay sau số điện thoại chỉ cách dấu cách ("MST 0301175691 245.000") thì cũng bị xóa theo.

### R12. Ngày (để xóa trước khi tìm tiền)

```regex
(?<!\d)\d{1,2}\s*([/.\-])\s*\d{1,2}\s*\1\s*(?:\d{4}|\d{2})(?!\d)
```

- **Dùng ở:** `_RowScan.of`
- **Mục đích:** Xóa ngày để "2026" trong "14/09/2026" không bị đọc thành 2.026đ.
- **Ví dụ khớp:** `14/09/2026`, `11-10-26`, `09.10.2026`
- **Ví dụ không khớp:** `1.250.000`, `0905.123.456`
- **Giới hạn đã biết:** Cùng cấu trúc với R18 nhưng không cần nhóm bắt.

### R13. Giờ

```regex
(?<!\d)\d{1,2}\s*[:h]\s*\d{2}(?:\s*:\s*\d{2})?(?!\d)
```

- **Dùng ở:** `_RowScan.of`
- **Mục đích:** Xóa giờ "18:42", "22:31:05", "18h42".
- **Ví dụ khớp:** `18:42`, `22:31:05`, `18h42`
- **Ví dụ không khớp:** `1.250.000`, `Bàn: 12`
- **Giới hạn đã biết:** —

### R14. Đơn giá trong "số lượng × đơn giá"

```regex
(?<![a-z0-9])\d+(?:[.,]\d+)?\s*(?:[a-z]+\s*)?[x×*]\s*(\d{1,3}(?:[.,]\d{3})+|\d{4,9})
```

- **Dùng ở:** `_RowScan.of` (xóa nhóm 1)
- **Mục đích:** Số tiền sau "x" là đơn giá, không phải tổng.
- **Ví dụ khớp:** `Bánh bao 10 x 12.000`, `Trà đá 2 × 3.000`, `2,5 giờ x 180.000`
- **Ví dụ không khớp:** `Trà đá x2 4.000`, `Tra Sua (L) x1 65,000`
- **Giới hạn đã biết:** Không nhận dạng được khi không có ký hiệu x/×/* ("2 | 15.000 | 30.000") – trường hợp này không ảnh hưởng tổng.

### R15. Số tiền

```regex
(?<![a-z0-9.,/:#\-])(\d{1,3}(?:[.,]\d{3})+|\d{4,9})(?![.,]?\d)(?=(?:d|vnd|dong)?(?![a-z0-9]))
```

- **Dùng ở:** `_RowScan.of`
- **Mục đích:** Đọc 150.000 / 150,000 / 150000 kèm "đ", "VNĐ", "VND", "₫". Sau regex còn lọc: bỏ số bắt đầu bằng 0, số < 1.000 hoặc > 999.999.999, số đứng sau "-" hoặc "(" (giảm giá).
- **Ví dụ khớp:** `150.000`, `150,000`, `150000`, `150.000đ`, `150.000 đ`, `150,000 VND`, `150.000 VNĐ`, `1.250.000`, `₫44.000`
- **Ví dụ không khớp:** `Logitech M331`, `#A-2041`, `Store #3021`, `AKKO 3068B`, `0,85`, `11.2 km`, `8934588012345`, `-15.000`
- **Giới hạn đã biết:** Không đọc được "1.250.000,00" (phần thập phân), "45k", số bị OCR chèn dấu cách ("245 000").

### R16. Đơn vị tiền tệ

```regex
(?<![a-z])(?:vnd|dong|d)(?![a-z])
```

- **Dùng ở:** `_RowScan.of` (kiểm tra hàng chỉ có số tiền)
- **Mục đích:** Bỏ "đ/VND/đồng" để nhận ra hàng chỉ gồm số tiền, ví dụ "84.000 VNĐ" dưới nhãn "Tổng cộng:".
- **Ví dụ khớp:** `84.000 VNĐ`, `84.000 đ`
- **Ví dụ không khớp:** `Đà Nẵng`
- **Giới hạn đã biết:** —

## C. Ngày (FR-3.3) — `lib/services/receipt_parser.dart`

### R17. Ngày DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY, DD/MM/YY

```regex
(?<!\d)(\d{1,2})\s*([/.\-])\s*(\d{1,2})\s*\2\s*(\d{4}|\d{2})(?!\d)
```

- **Dùng ở:** `ReceiptParser.extractDate`
- **Mục đích:** Nhóm 1 = ngày, nhóm 2 = dấu phân cách, nhóm 3 = tháng, nhóm 4 = năm. `\2` bắt buộc hai dấu phân cách giống nhau. Sau regex: năm 2 chữ số → 20YY, kiểm tra ngày tồn tại bằng cách dựng `DateTime` rồi so lại ngày/tháng.
- **Ví dụ khớp:** `14/09/2026`, `14-09-2026`, `14.09.2026`, `14/09/26`, `4/9/2026`, `14 / 09 / 2026`, `18:42:10 14/09/2026`
- **Ví dụ không khớp:** `14/09-2026`, `1.250.000`, `0905.123.456`, `BE-15102026-88213`, `18:42`
- **Giới hạn đã biết:** Regex vẫn khớp "45/13/2026", "31/04/2026", "29/02/2026"; bước kiểm tra sau regex mới loại chúng. Không hỗ trợ dạng MM/DD/YYYY của Mỹ, YYYY-MM-DD, "ngày 14 tháng 9 năm 2026".

### R18. Nhãn ngày giao dịch

```regex
(?<![a-z0-9])(?:thoi\ gian|ngay|date|time)(?![a-z0-9])
```

- **Dùng ở:** `_dateLabel` (dựng bằng `_keywordPattern`)
- **Mục đích:** Ngày trên hàng có nhãn được ưu tiên hơn ngày không nhãn (ví dụ giờ chiếu phim).
- **Ví dụ khớp:** `Ngày giao dịch: 16/10/2026`, `Date: 19/10/2026`, `Thời gian: 15/10/2026`
- **Ví dụ không khớp:** `Suất chiếu: 20:15 17/10/2026`, `HSD: 05-11-2026`
- **Giới hạn đã biết:** "Ngày hết hạn" cũng khớp nhãn này (chưa phân biệt).

## D. Tên cửa hàng (FR-3.4) — `lib/services/receipt_parser.dart`

### R19. Hàng không phải tên cửa hàng

```regex
(?<![a-z0-9])(?:<từ khóa 1>|<từ khóa 2>|…)(?![a-z0-9])
```

- **Dùng ở:** `receipt_keywords.dart` → `notNameKeywords` (47 từ khóa)
- **Mục đích:** Gồm danh sách của FR-3.4 (địa chỉ, Đ/c, ĐT, Tel, Hotline, MST, www, http, hóa đơn) và các nhãn liên hệ, tiêu đề chứng từ, nhãn ngày/nhân viên, slogan năm thành lập, từ địa chỉ không nhập nhằng.
- **Từ khóa (47):** `dia chi`, `d/c`, `dc`, `dt`, `tel`, `hotline`, `mst`, `www`, `http`, `https`, `hoa don`, `dien thoai`, `sdt`, `phone`, `fax`, `email`, `website`, `zalo`, `tong dai`, `ma so thue`, `tax code`, `phieu`, `bien nhan`, `bien lai`, `receipt`, `invoice`, `bill`, `ticket`, `ve xem phim`, `ngay`, `date`, `thoi gian`, `thu ngan`, `cashier`, `nhan vien`, `since`, `est`, `established`, `founded`, `thanh lap`, `tu nam`, `thanh pho`, `huyen`, `tttm`, `street`, `ward`, `district`
- **Ví dụ khớp:** `Hotline: 1900 6750`, `www.coopmart.vn`, `HÓA ĐƠN BÁN HÀNG`, `VÉ XEM PHIM / MOVIE TICKET`, `Books & Stationery since 2001`
- **Ví dụ không khớp:** `HIGHLANDS COFFEE`, `Nhà sách Phương Nam`, `GS25 Lý Thường Kiệt`
- **Giới hạn đã biết:** Cố ý không có "phường", "kiệt", "tầng" vì trùng tên riêng. Slogan không chứa từ khóa nào (ví dụ "Hệ thống bán lẻ điện thoại, laptop" nếu không có chữ "điện thoại") vẫn có thể thắng dòng thương hiệu ngắn.

### R20. Dòng pháp nhân

```regex
(?<![a-z0-9])(?:<từ khóa 1>|<từ khóa 2>|…)(?![a-z0-9])
```

- **Dùng ở:** `receipt_keywords.dart` → `companyKeywords` (12 từ khóa)
- **Mục đích:** "CÔNG TY CỔ PHẦN …" chỉ là phương án dự phòng (độ tin cậy thấp) khi không có dòng tên nào khác.
- **Từ khóa (12):** `cong ty`, `cty`, `tnhh`, `co phan`, `cp`, `jsc`, `ltd`, `llc`, `corp`, `corporation`, `company`, `inc`
- **Ví dụ khớp:** `CÔNG TY TNHH GS RETAIL VIỆT NAM`, `CTY CP THƯƠNG MẠI BÁCH HÓA XANH`
- **Ví dụ không khớp:** `CO.OPMART HUẾ`, `WinMart+`
- **Giới hạn đã biết:** —

### R21. Địa chỉ có số nhà

```regex
(?<![a-z0-9])\d+[a-z]?\s+[a-z]
```

- **Dùng ở:** `ReceiptParser._isNotName`
- **Mục đích:** Dòng địa chỉ không có nhãn: số nhà (có thể kèm 1 chữ) rồi một từ.
- **Ví dụ khớp:** `50A Hùng Vương, TP. Huế`, `174 Bà Triệu`, `WM+ HUE 25 Lê Lợi`
- **Ví dụ không khớp:** `GS25 Lý Thường Kiệt`, `PHỞ 24`, `Phở 24 - Vincom Plaza Huế`
- **Giới hạn đã biết:** Tên có số đứng trước chữ ("7 Eleven" viết không gạch) bị loại nhầm.

### R22. Giá tiền trong hàng (hàng món ăn)

```regex
(?<![a-z0-9.,])(?:\d{1,3}(?:[.,]\d{3})+(?![.,]?\d)|\d{4,9}\s*(?:d|vnd|dong|₫)(?![a-z]))
```

- **Dùng ở:** `ReceiptParser._isNotName`
- **Mục đích:** Hàng có giá (có dấu phân cách hoặc ký hiệu tiền) là hàng món, không phải tên.
- **Ví dụ khớp:** `Cà phê sữa đá 2 25.000 50.000`, `Bạc xỉu 29000đ`
- **Ví dụ không khớp:** `PHỞ 24`, `Books since 2001`, `Cơm gà 35000`
- **Giới hạn đã biết:** Giá viết liền không ký hiệu ("35000") không bị coi là giá, để không loại nhầm "Phở 2000".

### R23. Chữ cái Unicode

```regex
\p{L}   (unicode: true)
```

- **Dùng ở:** `ReceiptParser.extractMerchant`
- **Mục đích:** Đếm chữ cái (kể cả có dấu) để chọn hàng nhiều chữ nhất; cần ≥ 3 chữ.
- **Ví dụ khớp:** `Phở`, `ĐT`
- **Ví dụ không khớp:** `12345`, `---`
- **Giới hạn đã biết:** —

### R24. Chữ số

```regex
\d
```

- **Dùng ở:** `ReceiptParser._isNotName`
- **Mục đích:** Hàng có nhiều chữ số hơn chữ cái bị loại ("tỷ lệ chữ số cao").
- **Ví dụ khớp:** `8934588012345`
- **Ví dụ không khớp:** `CIRCLE K`
- **Giới hạn đã biết:** —

## E. Gợi ý danh mục (FR-3.5) — `lib/services/receipt_parser.dart`

### R25. Ăn uống (food)

```regex
(?<![a-z0-9.])(?:<từ khóa 1>|<từ khóa 2>|…)(?![a-z0-9])
```

- **Dùng ở:** `receipt_keywords.dart` → `foodKeywords` (95 từ khóa)
- **Mục đích:** Thương hiệu F&B, siêu thị, cửa hàng tiện lợi và từ chung về đồ ăn uống.
- **Từ khóa (95):** `highlands`, `phuc long`, `the coffee house`, `starbucks`, `katinat`, `cong caphe`, `trung nguyen`, `gong cha`, `koi the`, `maycha`, `tocotoco`, `phe la`, `kfc`, `lotteria`, `jollibee`, `mcdonald`, `pizza hut`, `dominos`, `the pizza company`, `pho 24`, `circle k`, `gs25`, `familymart`, `family mart`, `ministop`, `7-eleven`, `coopmart`, `co.opmart`, `coop food`, `winmart`, `vinmart`, `bach hoa xanh`, `lotte mart`, `big c`, `aeon`, `emart`, `mega market`, `quan an`, `quan com`, `com`, `pho bo`, `pho ga`, `bun bo`, `bun cha`, `bun`, `mi`, `banh mi`, `banh`, `nuong`, `nha hang`, `restaurant`, `bakery`, `cafe`, `ca phe`, `caphe`, `coffee`, `tea`, `tra sua`, `tra da`, `tra dao`, `tra xanh`, `tra chanh`, `tra sen`, `sinh to`, `nuoc ep`, `nuoc suoi`, `nuoc ngot`, `an vat`, `do an`, `thuc pham`, `supermarket`, `minimart`, `mart`, `tap hoa`, `food`, `drink`, `sua tuoi`, `sua chua`, `bac xiu`, `pizza`, `burger`, `ga ran`, `chicken`, `hai san`, `bbq`, `buffet`, `kimbap`, `snack`, `rau`, `thit`, `trung ga`, `gao`, `coca`, `pepsi`, `xuc xich`
- **Ví dụ khớp:** `HIGHLANDS COFFEE`, `QUÁN CƠM BÀ NĂM`, `CO.OPMART HUẾ`, `Cà phê sữa đá`
- **Ví dụ không khớp:** `www.fahasa.com`, `Khách phải trả`, `Tặng kèm`
- **Giới hạn đã biết:** Mẫu danh mục coi dấu chấm phía trước là một phần của từ, nên "com" trong ".com" không phải "cơm". Các từ trùng nghĩa khi bỏ dấu ("trả/trà", "sửa/sữa", "kèm/kem", "lầu/lẩu", "phố/phở") chỉ dùng trong cụm.

### R26. Học tập (study)

```regex
(?<![a-z0-9.])(?:<từ khóa 1>|<từ khóa 2>|…)(?![a-z0-9])
```

- **Dùng ở:** `receipt_keywords.dart` → `studyKeywords` (38 từ khóa)
- **Mục đích:** Nhà sách, văn phòng phẩm, photocopy, giáo trình, học phí.
- **Từ khóa (38):** `nha sach`, `fahasa`, `phuong nam`, `tien tho`, `sach giao khoa`, `sach tham khao`, `book`, `books`, `bookstore`, `bookshop`, `library`, `thu vien`, `van phong pham`, `vpp`, `stationery`, `photo`, `photocopy`, `copy`, `in tai lieu`, `in an`, `tai lieu`, `giao trinh`, `vo`, `but bi`, `but chi`, `but long`, `thuoc ke`, `giay a4`, `hoc phi`, `khoa hoc`, `course`, `hoc tap`, `school`, `university`, `ielts`, `toeic`, `notebook`, `highlighter`
- **Ví dụ khớp:** `NHÀ SÁCH FAHASA HUẾ`, `PHOTO COPY THANH TÂM`, `Vở kẻ ngang`
- **Ví dụ không khớp:** `Rau sạch Đà Lạt`
- **Giới hạn đã biết:** "sách" đơn lẻ không dùng vì trùng "sạch".

### R27. Di chuyển (travel)

```regex
(?<![a-z0-9.])(?:<từ khóa 1>|<từ khóa 2>|…)(?![a-z0-9])
```

- **Dùng ở:** `receipt_keywords.dart` → `travelKeywords` (56 từ khóa)
- **Mục đích:** Gọi xe, taxi, vé xe/tàu/máy bay, xăng, gửi xe, khách sạn.
- **Từ khóa (56):** `grab`, `grabbike`, `grabcar`, `becar`, `bebike`, `be group`, `xanh sm`, `gojek`, `taxi`, `mai linh`, `vinasun`, `xe om`, `xe buyt`, `bus`, `vexere`, `futa`, `phuong trang`, `nha xe`, `ve xe`, `xe khach`, `limousine`, `vietjet`, `vietnam airlines`, `bamboo airways`, `airline`, `flight`, `chuyen bay`, `san bay`, `airport`, `ve tau`, `duong sat`, `xang`, `xang dau`, `petrolimex`, `pvoil`, `gui xe`, `bai xe`, `parking`, `phi cau duong`, `toll`, `cuoc phi`, `cuoc xe`, `gia cuoc`, `quang duong`, `khoang cach`, `diem don`, `diem den`, `chuyen di`, `trip`, `ride`, `khach san`, `hotel`, `homestay`, `resort`, `agoda`, `traveloka`
- **Ví dụ khớp:** `Grab`, `beCar`, `Phụ phí sân bay`, `Petrolimex`
- **Ví dụ không khớp:** `Bé Mặn quán`, `Vé xem phim`
- **Giới hạn đã biết:** Không dùng "be" đơn lẻ (trùng "bé"), chỉ beCar/beBike/be group.

### R28. Thiết bị (gear)

```regex
(?<![a-z0-9.])(?:<từ khóa 1>|<từ khóa 2>|…)(?![a-z0-9])
```

- **Dùng ở:** `receipt_keywords.dart` → `gearKeywords` (64 từ khóa)
- **Mục đích:** Chuỗi điện máy, hãng công nghệ, phụ kiện, bảo hành, IMEI.
- **Từ khóa (64):** `the gioi di dong`, `thegioididong`, `tgdd`, `dien may xanh`, `dien may cho lon`, `nguyen kim`, `fpt shop`, `cellphones`, `phong vu`, `an phat`, `hacom`, `gearvn`, `hoang ha mobile`, `di dong viet`, `viettel store`, `apple`, `samsung`, `xiaomi`, `oppo`, `logitech`, `razer`, `asus`, `dell`, `lenovo`, `jbl`, `sony`, `anker`, `dien thoai di dong`, `smartphone`, `iphone`, `ipad`, `macbook`, `laptop`, `may tinh`, `computer`, `pc`, `tai nghe`, `headphone`, `earbuds`, `loa`, `speaker`, `chuot`, `mouse`, `ban phim`, `keyboard`, `man hinh`, `monitor`, `cap sac`, `cu sac`, `sac du phong`, `pin du phong`, `usb`, `o cung`, `ssd`, `the nho`, `router`, `bluetooth`, `smartwatch`, `phu kien`, `linh kien`, `dien tu`, `electronics`, `bao hanh`, `imei`
- **Ví dụ khớp:** `THẾ GIỚI DI ĐỘNG`, `CellphoneS`, `Tai nghe Bluetooth`, `Bảo hành: 12 tháng`
- **Ví dụ không khớp:** `Điện thoại: 0234 3588 555`
- **Giới hạn đã biết:** "điện thoại" đơn lẻ không dùng vì là nhãn số điện thoại trên mọi hóa đơn.

### R29. Giải trí (entertainment)

```regex
(?<![a-z0-9.])(?:<từ khóa 1>|<từ khóa 2>|…)(?![a-z0-9])
```

- **Dùng ở:** `receipt_keywords.dart` → `entertainmentKeywords` (35 từ khóa)
- **Mục đích:** Rạp phim, karaoke, bida, game, vé sự kiện.
- **Từ khóa (35):** `cgv`, `lotte cinema`, `galaxy cinema`, `bhd`, `beta cinemas`, `cinestar`, `cinema`, `cinemas`, `rap chieu`, `rap phim`, `phim`, `movie`, `ve xem phim`, `suat chieu`, `phong chieu`, `2d`, `3d`, `imax`, `karaoke`, `bida`, `billiard`, `bowling`, `game`, `gaming`, `playstation`, `netflix`, `spotify`, `concert`, `su kien`, `event`, `cong vien`, `khu vui choi`, `vui choi`, `escape room`, `ticketbox`
- **Ví dụ khớp:** `CGV Vincom Huế`, `KARAOKE NICE`, `Suất chiếu 20:15`
- **Ví dụ không khớp:** `Vé xe khách`
- **Giới hạn đã biết:** —

## Quy tắc không dùng regex

| Trường | Quy tắc | Lý do |
|---|---|---|
| Tổng tiền | Phân loại hàng theo từ khóa **xuất hiện sớm nhất**; cùng vị trí thì từ khóa dài hơn thắng | "Tổng chiết khấu" là giảm giá dù bắt đầu bằng "tổng" |
| Tổng tiền | Ưu tiên: thanh toán cuối (R4) > tổng (R5, R6) > tạm tính (R7); cùng mức thì **hàng thấp hơn** thắng | FR-3.2 |
| Tổng tiền | Nhãn không có số → lấy hàng ngay dưới nếu hàng đó chỉ có số tiền | "TỔNG CỘNG:" một dòng, "84.000" dòng dưới |
| Tổng tiền | Không có từ khóa → số tiền hợp lệ lớn nhất, độ tin cậy thấp; bỏ hàng R8 và R9 | FR-3.2 fallback |
| Ngày | Dựng `DateTime(y, m, d)` rồi so lại `month`/`day`; năm ngoài 2000–2099 bị loại | `DateTime` tự cộng dồn 31/04 → 01/05 |
| Tên cửa hàng | Chỉ xét **5 hàng đầu** khác rỗng; cần ≥ 3 chữ cái; bỏ hàng có dấu `:`; bỏ hàng có nhiều chữ số hơn chữ cái | FR-3.4 |
| Tên cửa hàng | Chọn hàng **nhiều chữ cái nhất**; bằng nhau → hàng trên; chỉ có dòng pháp nhân → độ tin cậy thấp | FR-3.4 |
| Danh mục | Tên cửa hàng khớp từ khóa → độ tin cậy cao (từ khóa dài nhất quyết định); nếu không, mỗi hàng bỏ phiếu, thắng rõ ràng → thấp, hòa → `null` | FR-3.5 |

