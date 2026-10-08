import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/models/field_confidence.dart';
import 'package:vku_expense_ocr/services/receipt_parser.dart';

void main() {
  const parser = ReceiptParser();
  DateTime? date(List<String> rows) => parser.extractDate(rows)?.$1;

  group('formats (FR-3.3)', () {
    final cases = {
      '14/09/2026': DateTime(2026, 9, 14),
      '14-09-2026': DateTime(2026, 9, 14),
      '14.09.2026': DateTime(2026, 9, 14),
      '14/09/26': DateTime(2026, 9, 14),
      '4/9/2026': DateTime(2026, 9, 4),
      'Ngày: 14/09/2026 18:42': DateTime(2026, 9, 14),
      '18:42:10 14/09/2026': DateTime(2026, 9, 14),
      'Thời gian: 09.10.2026 - 10:47': DateTime(2026, 10, 9),
      '14 / 09 / 2026': DateTime(2026, 9, 14),
      'Ngày 24/10/2O26': DateTime(2026, 10, 24),
    };
    for (final MapEntry(key: row, value: expected) in cases.entries) {
      test('reads "$row"', () {
        expect(date([row]), expected);
      });
    }
  });

  group('validation (FR-3.3)', () {
    test('rejects dates that do not exist', () {
      expect(date(['45/13/2026']), isNull);
      expect(date(['31/04/2026']), isNull);
      expect(date(['29/02/2026']), isNull);
      expect(date(['00/10/2026']), isNull);
    });

    test('accepts 29 February in a leap year', () {
      expect(date(['29/02/2028']), DateTime(2028, 2, 29));
    });

    test('maps two-digit years to 20YY', () {
      expect(date(['07/10/26']), DateTime(2026, 10, 7));
      expect(date(['01/01/99']), DateTime(2099));
    });

    test('a time alone is not a date', () {
      expect(date(['18:42', '22:31:05']), isNull);
    });

    test('does not read amounts, phones or codes as dates', () {
      expect(
        date(['Tổng: 1.250.000', 'ĐT: 0905.123.456', 'Mã: BE-15102026-88213']),
        isNull,
      );
    });

    test('returns null when no date is printed', () {
      expect(parser.extractDate(['Cơm gà 35.000']), isNull);
      expect(parser.extractDate(const []), isNull);
    });
  });

  group('choosing between dates', () {
    test('prefers the date labelled as the transaction date', () {
      final rows = [
        'Suất chiếu: 20:15 17/10/2026',
        'Ngày giao dịch: 16/10/2026 19:02',
      ];
      expect(date(rows), DateTime(2026, 10, 16));
    });

    test('uses the first date when none is labelled', () {
      expect(
        date(['05-10-2026 08:12', 'HSD: 05-11-2026']),
        DateTime(2026, 10, 5),
      );
    });

    test('a labelled or unique date has high confidence', () {
      expect(parser.extractDate(['Ngày: 14/09/2026']), (
        DateTime(2026, 9, 14),
        FieldConfidence.high,
      ));
      expect(parser.extractDate(['05-10-2026 08:12']), (
        DateTime(2026, 10, 5),
        FieldConfidence.high,
      ));
    });

    test('a guess among several unlabelled dates has low confidence', () {
      expect(parser.extractDate(['05-10-2026', '05-11-2026']), (
        DateTime(2026, 10, 5),
        FieldConfidence.low,
      ));
    });
  });
}
