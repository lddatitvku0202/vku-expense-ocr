import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/models/field_confidence.dart';
import 'package:vku_expense_ocr/services/receipt_parser.dart';

const high = FieldConfidence.high;
const low = FieldConfidence.low;

void main() {
  const parser = ReceiptParser();
  (int, FieldConfidence)? total(List<String> rows) => parser.extractTotal(rows);

  group('amount formats (FR-3.2)', () {
    const cases = {
      'Tổng tiền 150.000': 150000,
      'Tổng tiền 150,000': 150000,
      'Tổng tiền 150000': 150000,
      'Tổng tiền 150.000đ': 150000,
      'Tổng tiền 150.000 đ': 150000,
      'Tổng tiền 150,000 VND': 150000,
      'Tổng tiền 150.000 VNĐ': 150000,
      'Tổng tiền 1.250.000': 1250000,
      'Tổng tiền: 150.000₫': 150000,
    };
    for (final MapEntry(key: row, value: amount) in cases.entries) {
      test('reads "$row"', () {
        expect(total([row]), (amount, high));
      });
    }
  });

  group('total keywords (FR-3.2)', () {
    const labels = [
      'Tổng thanh toán',
      'Thanh toán',
      'Tổng cộng',
      'Tổng tiền',
      'TOTAL',
      'Amount due',
      'Cần thanh toán',
      'Khách phải trả',
    ];
    for (final label in labels) {
      test('finds the amount after "$label"', () {
        expect(total(['Cà phê sữa 25.000', '$label 99.000', 'Cảm ơn']), (
          99000,
          high,
        ));
      });
    }
  });

  group('choosing between candidates', () {
    test('prefers the final amount over the subtotal', () {
      final rows = [
        'Tổng tiền hàng 260.000',
        'Giảm giá -15.000',
        'Tổng thanh toán 245.000',
      ];
      expect(total(rows), (245000, high));
    });

    test('final amount wins even when printed above the subtotal', () {
      expect(total(['Tổng thanh toán 245.000', 'Tổng tiền hàng 260.000']), (
        245000,
        high,
      ));
    });

    test('prefers the lower row among equal keywords', () {
      final rows = [
        'Tổng cộng 882.000',
        'VAT 10% 92.610',
        'Tổng cộng 1.018.710',
      ];
      expect(total(rows), (1018710, high));
    });

    test('a subtotal alone is used with low confidence', () {
      expect(total(['Tạm tính 114.000', 'Cảm ơn quý khách']), (114000, low));
    });

    test('takes the largest amount on the keyword row', () {
      expect(total(['Tổng cộng 5 món 245.000']), (245000, high));
      expect(total(['Tổng tiền 245.000 (gồm VAT 22.273)']), (245000, high));
    });

    test('reads the amount printed on the row below the label', () {
      expect(total(['Tổng cộng:', '84.000', 'Cảm ơn']), (84000, high));
    });

    test('does not borrow text from a non-amount row below the label', () {
      final rows = ['Tổng cộng:', 'Cảm ơn quý khách', 'Hotline 1900 6750'];
      expect(total(rows), isNull);
    });
  });

  group('exclusions (FR-3.2)', () {
    test('ignores phone, tax code, invoice number, date and time', () {
      final rows = [
        'Hotline: 1900 636467',
        'MST: 0301175691',
        'Số HĐ: 123456',
        'Ngày 14/09/2026 18:42',
        'Cơm gà 35.000',
        '= 94.000',
      ];
      expect(total(rows), (94000, low));
    });

    test('ignores a hotline printed on the total row', () {
      expect(total(['Tổng cộng 84.000 Hotline 19006750']), (84000, high));
    });

    test('ignores barcodes', () {
      expect(total(['Coca 10,000', '8934588012345']), (10000, low));
    });

    test('ignores the unit price in "quantity x unit price"', () {
      expect(total(['Bánh bao 10 x 12.000']), isNull);
      expect(total(['Trà đá 2 × 3.000', 'Cơm gà 35.000']), (35000, low));
    });

    test('ignores discounts written as negative amounts', () {
      expect(total(['Bánh 30.000', 'Giảm giá -50.000']), (30000, low));
      expect(total(['Bánh 30.000', 'Member discount (50,000)']), (30000, low));
    });

    test('ignores cash tendered and change', () {
      expect(
        total([
          'Tổng cộng 84.000',
          'Khách thanh toán 100.000',
          'Tiền thối 16.000',
        ]),
        (84000, high),
      );
      expect(total(['TOTAL 49,000', 'CASH 100,000', 'CHANGE 51,000']), (
        49000,
        high,
      ));
      expect(total(['Thanh toán 63.000', 'Tiền khách đưa 100.000']), (
        63000,
        high,
      ));
      expect(total(['Cơm 35.000', 'Tiền mặt 100.000']), (35000, low));
    });
  });

  group('OCR noise', () {
    test('tolerates misread letters in keywords', () {
      expect(total(['Tong tlen 155,000']), (155000, high));
      expect(total(['TONG TIEN 150.000']), (150000, high));
      expect(total(['T0NG THANH T0AN 63.000d']), (63000, high));
    });

    test('repairs the letter O read inside an amount', () {
      expect(total(['Tổng cộng 139.5OO']), (139500, high));
    });
  });

  group('fallback and missing (FR-3.2)', () {
    test('without keywords, takes the largest amount with low confidence', () {
      final rows = ['Cơm gà xối mỡ 35000', 'Canh chua 15000', '= 94000'];
      expect(total(rows), (94000, low));
    });

    test('returns null when the receipt has no amount', () {
      expect(total(const []), isNull);
      expect(total(['Cảm ơn quý khách', 'Hẹn gặp lại']), isNull);
    });
  });
}
