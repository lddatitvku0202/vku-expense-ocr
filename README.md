# VKU Expense OCR

Ứng dụng Flutter quản lý chi tiêu cá nhân: chụp hóa đơn giấy, nhận dạng chữ **on-device** bằng Google ML Kit, tự tách **tổng tiền / ngày / tên cửa hàng** bằng bộ phân tích regex, cho người dùng kiểm tra lại, lưu cục bộ bằng `sqflite` và trực quan hóa chi tiêu bằng biểu đồ vẽ tay (`CustomPainter`).

> Mini-Project 3 — môn *Cross-Platform Mobile App Development*, Khoa Khoa học Máy tính, VKU.

🚧 **README khung** — sẽ được hoàn thiện ở Phase 11 (tính năng, ảnh chụp, kiến trúc, lệnh build, link APK).

## Tính năng

_Sẽ bổ sung (checklist FR)._

## Ảnh chụp màn hình

_Sẽ bổ sung (`docs/screenshots/`)._

## Kiến trúc

_Sẽ bổ sung (sơ đồ pipeline + cấu trúc thư mục `lib/core|models|services|state|widgets|screens`)._

## Công nghệ

Flutter 3.x · Dart 3 · Riverpod 2 · go_router · sqflite · google_mlkit_text_recognition · camera · CustomPainter.

## Cài đặt & chạy

```bash
flutter pub get
flutter run
flutter test
flutter build apk --release
```

## Công cụ phát triển (không cần để build hay chạy app)

| Công cụ | Cần | Khi nào dùng |
|---|---|---|
| `tool/regex_table/gen_regex_table.py` | **Python 3** | Chỉ khi sửa regex trong `lib/services/receipt_parser.dart` / `receipt_keywords.dart`: sinh lại `docs/REGEX_TABLE.md` (`python tool/regex_table/gen_regex_table.py`). |
| `tool/ocr_eval/run_ocr_eval.ps1` | PowerShell, `adb`, thiết bị Android đã cắm | Chấm độ chính xác OCR trên ảnh hóa đơn thật (dữ liệu nằm ngoài repo, mặc định `D:\receipts-test`). Xem `docs/TEST_REPORT.md`. |

## Tải APK

_Sẽ bổ sung._

## Hạn chế

_Sẽ bổ sung._

## Tác giả

_Sẽ bổ sung._
