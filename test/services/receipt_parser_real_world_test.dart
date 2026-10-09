// Patterns found when the parser first met real receipt photos (Phase 3
// emulator evaluation). Every case is a general rule, written as a test
// before the fix; none is tied to one shop or one photo.
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/models/field_confidence.dart';
import 'package:vku_expense_ocr/services/receipt_parser.dart';

const high = FieldConfidence.high;
const low = FieldConfidence.low;

void main() {
  const parser = ReceiptParser();
  (int, FieldConfidence)? total(List<String> rows) => parser.extractTotal(rows);

  group('fallback prefers real money over bare numbers', () {
    test('a check or order number does not beat formatted amounts', () {
      expect(total(['Check: 126431', 'Phin sữa đá 55.000', 'Momo QR 55.000']), (
        55000,
        low,
      ));
    });

    test('a time printed without colons does not beat formatted amounts', () {
      expect(total(['Giờ in: 235900', 'Coca 2 25,000 50,000', 'Soda 25,000']), (
        50000,
        low,
      ));
    });

    test('a phone number further from its label is not an amount', () {
      expect(total(['DT Giao hang: 39256601', 'Banh 29,900.00']), (29900, low));
    });
  });

  group('more amount formats', () {
    test('two decimal places', () {
      expect(total(['Tong so tien thanh toan: 123,100.00']), (123100, high));
      expect(total(['Tổng thanh toán 245.000,00']), (245000, high));
    });

    test('a space OCR inserted after a thousands separator', () {
      expect(total(['Tong so tien thanh toan: 123, 100.00']), (123100, high));
      expect(total(['Tổng cộng 1. 250.000']), (1250000, high));
    });

    test('"đ" read as a trailing 0 or 6 after the last group', () {
      expect(total(['TỔNG CỘNG 184.0340']), (184034, high));
      expect(total(['Tổng cộng 45.8006']), (45800, high));
    });
  });

  group('total labels', () {
    test('abbreviated "T.Cộng" and "phải T.Toán"', () {
      expect(total(['Coca 2 25,000 50,000', 'T.Cộng 9 225,000']), (
        225000,
        high,
      ));
      expect(
        total([
          'Tổng tiền hàng 18.500',
          'TỔNG TIỀN PHẢI T.TOÁN 15.200',
          'TỔNG TIỀN ĐÃ GIẢM -3.300',
        ]),
        (15200, high),
      );
    });

    test('one misread character in a long label', () {
      expect(total(['1ONG CONG 184.034', 'Tong : 174.028 10.006']), (
        184034,
        high,
      ));
      expect(total([':T0NG CON6 349.688']), (349688, high));
    });

    test('a bare "Tổng:" row (tax table) loses to "Tổng cộng"', () {
      final rows = [
        'TỔNG CỘNG 100.000',
        'T.Suat GB chua co GTGT Thue GTGT',
        'Tong : 90.909 9.091',
      ];
      expect(total(rows), (100000, high));
    });
  });

  group('cash handed over printed as the total', () {
    test('uses cash minus change when that amount is on the receipt', () {
      final rows = [
        'Tổng tiền 49.300',
        'TỔNG TIỀN THANH TOÁN 60.000',
        'Tiền mặt 60.000',
        'Tiền trả lại 10.700',
      ];
      expect(total(rows), (49300, low));
    });

    test('also when label and amount sit on separate rows', () {
      final rows = [
        'Tổng tiền',
        '49.300',
        'TỔNG TIỀN THANH TOÁN 60.000',
        'Tiền mặt',
        '60.000',
        'Tiền trả lại 10.700',
      ];
      expect(total(rows), (49300, low));
    });

    test('leaves a normal receipt alone', () {
      final rows = [
        'Tổng cộng 184.034',
        'Tiền mặt 504.000',
        'Tiền thối lại -320.000',
      ];
      expect(total(rows), (184034, high));
    });
  });

  test('table headers are not the shop name', () {
    expect(
      parser.extractMerchant(['WinMart', 'Mặt hàng/giá SL KM T.Tiền'])?.$1,
      'WinMart',
    );
    expect(
      parser.extractMerchant(['QUÁN AN', 'Tên hàng SL Đơn giá Thành tiền'])?.$1,
      'QUÁN AN',
    );
  });

  group('dates with an English month name', () {
    final cases = {
      'Date:Tue 18 Jun 2024 09:49:29': DateTime(2024, 6, 18),
      'Date: 5 October 2025': DateTime(2025, 10, 5),
      'Oct 21, 2026 10:15': DateTime(2026, 10, 21),
    };
    for (final MapEntry(key: row, value: expected) in cases.entries) {
      test('reads "$row"', () {
        expect(parser.extractDate([row])?.$1, expected);
      });
    }

    test('rejects a day that does not exist', () {
      expect(parser.extractDate(['31 Feb 2026']), isNull);
    });
  });

  group('clothes and personal items are Gear', () {
    (ExpenseCategory, FieldConfidence)? suggest(List<String> rows) =>
        parser.suggestCategory(rows: rows);

    test('clothing rows', () {
      expect(suggest(['Áo sơ mi kẻ sọc - L 450.000', 'Quần tây - Vàng']), (
        ExpenseCategory.gear,
        low,
      ));
    });

    test('face masks', () {
      expect(suggest(['KHẨU TRANG Y TẾ 3 150.000']), (
        ExpenseCategory.gear,
        low,
      ));
    });

    test('a longer phrase wins inside one row ("sơ mi" is not "mì")', () {
      expect(suggest(['Áo sơ mi tay phồng 480.000']), (
        ExpenseCategory.gear,
        low,
      ));
    });

    test('a fashion shop name', () {
      expect(parser.suggestCategory(merchant: 'THỜI TRANG LAN ANH', rows: []), (
        ExpenseCategory.gear,
        high,
      ));
    });
  });
}
