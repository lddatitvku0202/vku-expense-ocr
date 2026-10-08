import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/models/field_confidence.dart';
import 'package:vku_expense_ocr/services/receipt_parser.dart';

void main() {
  const parser = ReceiptParser();
  String? merchant(List<String> rows) => parser.extractMerchant(rows)?.$1;

  test('picks the header row with the most letters', () {
    expect(merchant(['HIGHLANDS COFFEE', 'Vincom Huế']), 'HIGHLANDS COFFEE');
  });

  test('keeps the original spelling with accents', () {
    expect(merchant(['QUÁN CƠM BÀ NĂM']), 'QUÁN CƠM BÀ NĂM');
  });

  test('trims surrounding whitespace', () {
    expect(merchant(['   CIRCLE K   ']), 'CIRCLE K');
  });

  group('skips rows with contact or document keywords (FR-3.4)', () {
    // Each row has more letters than the real name, so it would win if the
    // keyword were not excluded.
    const rows = {
      'dia chi': 'Địa chỉ Trần Hưng Đạo Phường Phú Hòa Huế',
      'd/c': 'Đ/c Trần Hưng Đạo Phường Phú Hòa Huế',
      'dc:': 'DC: Trần Hưng Đạo Phường Phú Hòa Huế',
      'dt': 'ĐT Bàn Đặt Hàng Giao Tận Nơi Miễn Phí',
      'tel': 'Tel Customer Service Department',
      'hotline': 'Hotline Chăm Sóc Khách Hàng Toàn Quốc',
      'mst': 'MST Công Ty Thương Mại Dịch Vụ',
      'www': 'www.bachhoaxanhonline.com',
      'http': 'https://fahasabookstore.com',
      'hoa don': 'HÓA ĐƠN BÁN HÀNG GIÁ TRỊ GIA TĂNG',
    };
    for (final MapEntry(key: keyword, value: row) in rows.entries) {
      test('skips "$keyword"', () {
        expect(merchant([row, 'NHÀ SÁCH']), 'NHÀ SÁCH');
      });
    }
  });

  test('skips label: value rows', () {
    expect(merchant(['Thu ngân: Nguyễn Thị Thu Hương', 'KFC']), 'KFC');
  });

  test('skips street address lines without an address label', () {
    expect(
      merchant(['PHÚC LONG', '174 Bà Triệu, Phường Phú Hội, TP Huế']),
      'PHÚC LONG',
    );
  });

  test('skips rows that are mostly digits', () {
    expect(
      merchant(['MAGIAMGIA 8934588012345 8934588012346', 'QUÁN ĂN']),
      'QUÁN ĂN',
    );
  });

  test('ignores item rows that carry prices', () {
    final rows = [
      'Cà phê sữa đá 2 25.000 50.000',
      'Bạc xỉu 29.000',
      'Tổng cộng 79.000',
    ];
    expect(parser.extractMerchant(rows), isNull);
  });

  test('only looks at the first five rows', () {
    final rows = [
      'Đ/c: 6 Trần Hưng Đạo',
      'ĐT: 0234 3588 555',
      'MST: 0301175691',
      'www.coopmart.vn',
      'HÓA ĐƠN BÁN HÀNG',
      'CO.OPMART HUẾ',
    ];
    expect(parser.extractMerchant(rows), isNull);
  });

  group('company legal names', () {
    test('a brand line beats the long legal company name', () {
      final rows = [
        'WinMart+',
        'CÔNG TY CỔ PHẦN DỊCH VỤ THƯƠNG MẠI TỔNG HỢP WINCOMMERCE',
      ];
      expect(merchant(rows), 'WinMart+');
    });

    test('the legal name is a low-confidence fallback', () {
      expect(
        parser.extractMerchant([
          'CÔNG TY TNHH THƯƠNG MẠI ABC',
          'Đ/c: 12 Lê Lợi',
        ]),
        ('CÔNG TY TNHH THƯƠNG MẠI ABC', FieldConfidence.low),
      );
    });
  });

  test('a clear header name has high confidence', () {
    expect(
      parser.extractMerchant(['BÁCH HÓA XANH', 'Website: www.bachhoaxanh.com']),
      ('BÁCH HÓA XANH', FieldConfidence.high),
    );
  });

  test('returns null when no row looks like a name (FR-3.4)', () {
    expect(parser.extractMerchant(['12345', '---', '']), isNull);
    expect(parser.extractMerchant(const []), isNull);
  });
}
