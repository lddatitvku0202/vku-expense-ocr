# Báo cáo kiểm thử

## Tổng hợp theo phase

| Phase | Số test | Pass / Fail | Coverage | Format | Analyze | Build debug | Test trên thiết bị |
|---|---|---|---|---|---|---|---|
| 0 | 1 | 1 / 0 | — | ✔ | ✔ 0 issue | ✔ | ⚠ Chưa test trên thiết bị (chưa có máy kết nối) |

## Độ chính xác parser trên bộ fixture

_Sẽ bổ sung ở Phase 2._

## Checklist test thủ công trên thiết bị

> Đánh dấu `[x]` khi bạn đã tự kiểm tra trên máy Android thật. Ghi tên máy và phiên bản Android.

### Phase 0 — Khởi tạo

Thiết bị: `__________` · Android `____`

- [ ] `flutter devices` liệt kê được điện thoại.
- [ ] `flutter run` cài và mở app không lỗi (màn hình đếm số mặc định của Flutter).
- [ ] Bấm nút `+` thì số tăng (app phản hồi bình thường).
