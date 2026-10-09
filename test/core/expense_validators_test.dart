import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/core/expense_validators.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';

void main() {
  group('merchant', () {
    test('required, spaces do not count', () {
      expect(ExpenseValidators.merchant(null), 'Hãy nhập tên cửa hàng.');
      expect(ExpenseValidators.merchant('   '), 'Hãy nhập tên cửa hàng.');
      expect(ExpenseValidators.merchant('Co.opmart'), isNull);
    });

    test('at most 100 characters', () {
      expect(ExpenseValidators.merchant('a' * 100), isNull);
      expect(ExpenseValidators.merchant('a' * 101), contains('100'));
    });
  });

  group('amount (positive integer after removing separators)', () {
    test('valid amounts', () {
      for (final text in ['1', '150.000', '1.250.000', '999.999.999.999']) {
        expect(ExpenseValidators.amount(text), isNull, reason: text);
      }
    });

    test('empty', () {
      expect(ExpenseValidators.amount(''), 'Hãy nhập số tiền.');
      expect(ExpenseValidators.amount(null), 'Hãy nhập số tiền.');
    });

    test(
      '0 đ is refused with an explanation for fully discounted receipts',
      () {
        final message = ExpenseValidators.amount('0')!;
        expect(message, contains('lớn hơn 0'));
        expect(message, contains('giảm giá toàn bộ'));
      },
    );

    test('not a number', () {
      expect(ExpenseValidators.amount('abc'), contains('chữ số'));
    });

    test('too large', () {
      expect(
        ExpenseValidators.amount('1.000.000.000.000'),
        contains('quá lớn'),
      );
    });
  });

  group('date', () {
    final now = DateTime(2026, 10, 9, 20);

    test('today and the past are fine, any time of day', () {
      expect(
        ExpenseValidators.date(DateTime(2026, 10, 9, 23, 59), now: now),
        isNull,
      );
      expect(ExpenseValidators.date(DateTime(2020), now: now), isNull);
    });

    test('a future date is refused', () {
      expect(
        ExpenseValidators.date(DateTime(2026, 10, 10), now: now),
        'Ngày giao dịch không được ở tương lai.',
      );
      expect(
        ExpenseValidators.date(DateTime(2062, 9, 14), now: now),
        isNotNull,
      );
    });

    test('required', () {
      expect(
        ExpenseValidators.date(null, now: now),
        'Hãy chọn ngày giao dịch.',
      );
    });
  });

  test('category is required', () {
    expect(ExpenseValidators.category(null), 'Hãy chọn một danh mục.');
    for (final c in ExpenseCategory.values) {
      expect(ExpenseValidators.category(c), isNull);
    }
  });
}
