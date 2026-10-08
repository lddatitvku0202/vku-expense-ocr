/// Keyword tables used by `ReceiptParser` (FR-3.2, FR-3.4).
///
/// Every keyword is written in normalized form (no accents, lower case) and
/// matched against `TextNormalizer.ocrKey` text, so OCR text with or without
/// accents ("Tổng tiền", "TONG TIEN", "Tong tlen") matches the same entry.
library;

/// The amount the customer finally pays, after discounts and VAT.
const finalTotalKeywords = [
  'tong thanh toan',
  'tong tien thanh toan',
  'tong so tien thanh toan',
  'tong cong thanh toan',
  'can thanh toan',
  'phai thanh toan',
  'con phai thanh toan',
  'khach phai tra',
  'khach can tra',
  'tong phai tra',
  'phai tra',
  'amount due',
  'total due',
  'grand total',
  'total payment',
  'total amount',
  'net total',
];

/// Generic totals (FR-3.2 list). "cong" alone only counts at row start.
const totalKeywords = [
  'tong cong',
  'tong tien',
  'tong',
  'total',
  'thanh toan',
  'da thanh toan',
];

/// Sum of the items before discounts or VAT: used only as a last resort.
const subtotalKeywords = [
  'tong tien hang',
  'cong tien hang',
  'tong gia tri hang',
  'tien hang',
  'tam tinh',
  'thanh tien',
  'subtotal',
  'sub total',
  'sub-total',
];

/// Cash handed over, change, deposits: never the expense amount.
const tenderKeywords = [
  'tien khach dua',
  'khach dua',
  'tien khach tra',
  'khach tra',
  'khach thanh toan',
  'tien mat',
  'tien thua',
  'tien thoi',
  'tien tra lai',
  'thoi lai',
  'tra lai',
  'tien du',
  'da coc',
  'dat coc',
  'con lai',
  'cash',
  'change',
  'tendered',
  'received',
];

/// Rows that carry money but are not the total: discounts, taxes,
/// quantities, loyalty points, payment methods, document titles.
const notTotalKeywords = [
  'giam gia',
  'ma giam gia',
  'tong giam gia',
  'chiet khau',
  'tong chiet khau',
  'khuyen mai',
  'tong khuyen mai',
  'uu dai',
  'discount',
  'voucher',
  'thue',
  'tien thue',
  'tong thue',
  'tong tien thue',
  'vat',
  'tax',
  'phi dich vu',
  'service charge',
  'so luong',
  'tong so luong',
  'sl',
  'tong sl',
  'qty',
  'quantity',
  'diem',
  'tich luy',
  'points',
  'hinh thuc',
  'phuong thuc',
  'payment method',
  'hoa don',
  'phieu',
  'bien nhan',
  'cong ty',
];

/// Labels whose following number is a phone, tax code or document number,
/// never an amount (FR-3.2 exclusions, FR-3.4 contact rows).
const contactKeywords = [
  'dt',
  'dien thoai',
  'sdt',
  'tel',
  'phone',
  'hotline',
  'tong dai',
  'zalo',
  'fax',
  'mst',
  'ma so thue',
  'tax code',
  'vat reg',
  'so hd',
  'so hoa don',
  'hoa don so',
  'ma hd',
  'hd',
  'so ct',
  'so chung tu',
  'so phieu',
  'so',
  'ma',
  'ma don',
  'ma giao dich',
  'invoice no',
  'receipt no',
  'receipt',
  'order',
  'imei',
  'serial',
  's/n',
  'stk',
  'so tai khoan',
];
