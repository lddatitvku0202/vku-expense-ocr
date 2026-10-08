"""Generate docs/REGEX_TABLE.md after checking every example.

Usage (from the repository root): python tool/regex_table/gen_regex_table.py
"""
import sys
import unicodedata

sys.path.insert(0, str(__import__("pathlib").Path(__file__).parent))

from regex_doc_lib import ROOT, check, keyword_regex  # noqa: E402
from regex_entries import GROUPS, KW_LEFT  # noqa: E402
from regex_entries2 import GROUPS2  # noqa: E402

groups = GROUPS + GROUPS2
for _, entries in groups:
    for e in entries:
        if e["id"] == "R18":
            e["regex"] = keyword_regex(["ngay", "date", "thoi gian", "time"], KW_LEFT)
        check(e)


def show(sample: str) -> str:
    if any(unicodedata.combining(c) for c in sample):
        marks = " + ".join(
            f"U+{ord(c):04X}" if unicodedata.combining(c) else c for c in sample
        )
        return f"`{marks}` (dạng NFD)"
    return f"`{sample}`"


out = []
w = out.append
w("# Bảng regex của bộ phân tích hóa đơn (FR-3.7)")
w("")
w("> Nguồn cho mục \"Bảng regex OCR\" của báo cáo. Regex được **trích tự động từ mã nguồn** "
  "(`lib/core/text_normalizer.dart`, `lib/services/receipt_parser.dart`, "
  "`lib/services/receipt_keywords.dart`) và mọi ví dụ khớp / không khớp đã được chạy thử trước khi ghi file. "
  "Sinh lại sau khi sửa regex: `python tool/regex_table/gen_regex_table.py`.")
w("")
w("## Cách một hàng hóa đơn được xử lý")
w("")
w("1. `RowGrouper` ghép các dòng ML Kit cùng độ cao thành **một hàng** (FR-2.3, dùng hình học, không dùng regex).")
w("2. `repairDigits` (R3) sửa chữ O/l lẫn trong số → `normalize` (R1, R2) bỏ dấu, chữ thường, gộp khoảng trắng.")
w("3. `ocrKey` gộp ký tự OCR hay nhầm (bảng bên dưới) để so khớp từ khóa (R4–R10, R18–R20, R25–R29).")
w("4. Trước khi tìm số tiền (R15): xóa số sau nhãn liên hệ (R10 + R11), ngày (R12), giờ (R13), đơn giá (R14).")
w("")
w("| Ký tự OCR | Gộp thành (chỉ khi so khớp từ khóa) | Ví dụ |")
w("|---|---|---|")
w("| `0` | `o` | `T0NG C0NG` → `tong cong` |")
w("| `1`, `l`, `\\|` | `i` | `Tong tlen` → `tong tien`; từ khóa `total` → `totai` ở cả hai phía |")
w("")
w("## Bảng tổng hợp")
w("")
w("| ID | Pattern | Dùng ở |")
w("|---|---|---|")
for _, entries in groups:
    for e in entries:
        w(f"| {e['id']} | {e['title']} | {e['where']} |")
w("")
for heading, entries in groups:
    w(f"## {heading}")
    w("")
    for e in entries:
        w(f"### {e['id']}. {e['title']}")
        w("")
        w("```regex")
        w(e["regex"])
        w("```")
        w("")
        w(f"- **Dùng ở:** {e['where']}")
        w(f"- **Mục đích:** {e['purpose']}")
        if e.get("keywords"):
            w(f"- **Từ khóa ({len(e['keywords'])}):** " + ", ".join(f"`{k}`" for k in e["keywords"]))
        w("- **Ví dụ khớp:** " + (", ".join(show(s) for s in e.get("match", [])) or "—"))
        w("- **Ví dụ không khớp:** " + (", ".join(show(s) for s in e.get("no_match", [])) or "—"))
        w(f"- **Giới hạn đã biết:** {e['notes']}")
        w("")

w("## Quy tắc không dùng regex")
w("")
w("| Trường | Quy tắc | Lý do |")
w("|---|---|---|")
w("| Tổng tiền | Phân loại hàng theo từ khóa **xuất hiện sớm nhất**; cùng vị trí thì từ khóa dài hơn thắng | \"Tổng chiết khấu\" là giảm giá dù bắt đầu bằng \"tổng\" |")
w("| Tổng tiền | Ưu tiên: thanh toán cuối (R4) > tổng (R5, R6) > tạm tính (R7); cùng mức thì **hàng thấp hơn** thắng | FR-3.2 |")
w("| Tổng tiền | Nhãn không có số → lấy hàng ngay dưới nếu hàng đó chỉ có số tiền | \"TỔNG CỘNG:\" một dòng, \"84.000\" dòng dưới |")
w("| Tổng tiền | Không có từ khóa → số tiền hợp lệ lớn nhất, độ tin cậy thấp; bỏ hàng R8 và R9 | FR-3.2 fallback |")
w("| Ngày | Dựng `DateTime(y, m, d)` rồi so lại `month`/`day`; năm ngoài 2000–2099 bị loại | `DateTime` tự cộng dồn 31/04 → 01/05 |")
w("| Tên cửa hàng | Chỉ xét **5 hàng đầu** khác rỗng; cần ≥ 3 chữ cái; bỏ hàng có dấu `:`; bỏ hàng có nhiều chữ số hơn chữ cái | FR-3.4 |")
w("| Tên cửa hàng | Chọn hàng **nhiều chữ cái nhất**; bằng nhau → hàng trên; chỉ có dòng pháp nhân → độ tin cậy thấp | FR-3.4 |")
w("| Danh mục | Tên cửa hàng khớp từ khóa → độ tin cậy cao (từ khóa dài nhất quyết định); nếu không, mỗi hàng bỏ phiếu, thắng rõ ràng → thấp, hòa → `null` | FR-3.5 |")
w("")
target = ROOT / "docs" / "REGEX_TABLE.md"
target.write_text("\n".join(out) + "\n", encoding="utf-8", newline="\n")
print(f"wrote {target} with {sum(len(e) for _, e in groups)} patterns")
