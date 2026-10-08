import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/models/field_confidence.dart';
import 'package:vku_expense_ocr/models/parsed_receipt.dart';
import 'package:vku_expense_ocr/services/receipt_parser.dart';

void main() {
  const parser = ReceiptParser();

  test('combines every field into a ParsedReceipt (FR-3.6)', () {
    final rows = [
      'HIGHLANDS COFFEE',
      'Ngày: 05/10/2026 08:12',
      'Phin Sữa Đá 39.000',
      'TỔNG CỘNG 39.000',
    ];
    final result = parser.parse(rows);

    expect(result.merchant, 'HIGHLANDS COFFEE');
    expect(result.merchantConfidence, FieldConfidence.high);
    expect(result.total, 39000);
    expect(result.totalConfidence, FieldConfidence.high);
    expect(result.date, DateTime(2026, 10, 5));
    expect(result.dateConfidence, FieldConfidence.high);
    expect(result.suggestedCategory, ExpenseCategory.food);
    expect(result.categoryConfidence, FieldConfidence.high);
  });

  test('keeps the original rows as raw text, one per line', () {
    final result = parser.parse(['  Phúc Long  ', '', 'Tổng cộng 55.000']);
    expect(result.rawText, 'Phúc Long\nTổng cộng 55.000');
  });

  test('an empty receipt has every field missing', () {
    expect(parser.parse(const []), const ParsedReceipt.empty());
  });

  test('unreadable text never throws and leaves every field missing', () {
    final result = parser.parse(['~~~', '.,;:', '|||', '']);
    expect(result.merchant, isNull);
    expect(result.total, isNull);
    expect(result.date, isNull);
    expect(result.suggestedCategory, isNull);
    expect(result.totalConfidence, FieldConfidence.missing);
    expect(result.rawText, '~~~\n.,;:\n|||');
  });
}
