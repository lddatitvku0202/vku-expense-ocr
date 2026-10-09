import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/models/category_totals.dart';
import 'package:vku_expense_ocr/models/expense.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/models/weekly_totals.dart';

Expense _e(
  int amount,
  DateTime date, [
  ExpenseCategory c = ExpenseCategory.food,
]) => Expense(
  merchant: 'm',
  amount: amount,
  date: date,
  category: c,
  createdAt: date,
  updatedAt: date,
);

void main() {
  group('WeeklyTotals.of', () {
    test(
      'always has 7 days, Monday to Sunday, zero when nothing was spent',
      () {
        final week = WeeklyTotals.of(const [], DateTime(2026, 10, 8));
        expect(week.weekStart, DateTime(2026, 10, 5));
        expect(week.days, [0, 0, 0, 0, 0, 0, 0]);
        expect(week.isEmpty, isTrue);
        expect(week.max, 0);
        expect(week.dayAt(0), DateTime(2026, 10, 5));
        expect(week.dayAt(6), DateTime(2026, 10, 11));
      },
    );

    test('sums each day and ignores other weeks', () {
      final week = WeeklyTotals.of([
        _e(10000, DateTime(2026, 10, 5, 8)),
        _e(5000, DateTime(2026, 10, 5, 20)),
        _e(30000, DateTime(2026, 10, 8, 12)),
        _e(99000, DateTime(2026, 10, 4, 12)), // previous Sunday
        _e(99000, DateTime(2026, 10, 12, 12)), // next Monday
      ], DateTime(2026, 10, 9));

      expect(week.days, [15000, 0, 0, 30000, 0, 0, 0]);
      expect(week.total, 45000);
      expect(week.max, 30000);
    });

    test(
      'Sunday 23:59:59.999 is the last day; Monday 00:00 is the next week',
      () {
        final sunday = _e(1000, DateTime(2026, 10, 11, 23, 59, 59, 999));
        final monday = _e(2000, DateTime(2026, 10, 12));

        expect(WeeklyTotals.of([sunday, monday], DateTime(2026, 10, 5)).days, [
          0, 0, 0, 0, 0, 0, 1000, //
        ]);
        expect(WeeklyTotals.of([sunday, monday], DateTime(2026, 10, 12)).days, [
          2000, 0, 0, 0, 0, 0, 0, //
        ]);
      },
    );

    test('a week spanning two months', () {
      final week = WeeklyTotals.of([
        _e(1000, DateTime(2026, 9, 28)),
        _e(2000, DateTime(2026, 9, 30, 23, 59, 59, 999)),
        _e(3000, DateTime(2026, 10)),
        _e(4000, DateTime(2026, 10, 4, 23, 59)),
      ], DateTime(2026, 10, 2));

      expect(week.weekStart, DateTime(2026, 9, 28));
      expect(week.days, [1000, 0, 2000, 3000, 0, 0, 4000]);
    });

    test('a week spanning New Year', () {
      final week = WeeklyTotals.of([
        _e(1000, DateTime(2026, 12, 31, 23, 59, 59, 999)),
        _e(2000, DateTime(2027)),
        _e(3000, DateTime(2027, 1, 3, 12)),
        _e(9000, DateTime(2027, 1, 4)),
      ], DateTime(2027));

      expect(week.weekStart, DateTime(2026, 12, 28));
      expect(week.days, [0, 0, 0, 1000, 2000, 0, 3000]);
    });

    test('equal data gives equal objects (charts compare them to repaint)', () {
      final a = WeeklyTotals.of([
        _e(1000, DateTime(2026, 10, 5)),
      ], DateTime(2026, 10, 5));
      final b = WeeklyTotals.of([
        _e(1000, DateTime(2026, 10, 5)),
      ], DateTime(2026, 10, 6));
      final c = WeeklyTotals.of([
        _e(2000, DateTime(2026, 10, 5)),
      ], DateTime(2026, 10, 5));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('CategoryTotals.of', () {
    test('lists all 5 categories in enum order, 0 when nothing was spent', () {
      final totals = CategoryTotals.of([_e(50000, DateTime(2026, 10, 1))]);

      expect(totals.amounts.keys, ExpenseCategory.values);
      expect(totals.amounts, {
        ExpenseCategory.food: 50000,
        ExpenseCategory.study: 0,
        ExpenseCategory.travel: 0,
        ExpenseCategory.gear: 0,
        ExpenseCategory.entertainment: 0,
      });
    });

    test('sums per category and gives shares that add up to 1', () {
      final totals = CategoryTotals.of([
        _e(50000, DateTime(2026, 10, 1)),
        _e(25000, DateTime(2026, 10, 2)),
        _e(75000, DateTime(2026, 10, 3), ExpenseCategory.study),
        _e(50000, DateTime(2026, 10, 4), ExpenseCategory.gear),
      ]);

      expect(totals.total, 200000);
      expect(totals.amountOf(ExpenseCategory.food), 75000);
      expect(totals.shareOf(ExpenseCategory.food), closeTo(0.375, 1e-9));
      expect(totals.shareOf(ExpenseCategory.study), closeTo(0.375, 1e-9));
      expect(totals.shareOf(ExpenseCategory.gear), closeTo(0.25, 1e-9));
      expect(totals.shareOf(ExpenseCategory.travel), 0);
      expect(
        totals.shares.values.fold<double>(0, (a, b) => a + b),
        closeTo(1, 1e-9),
      );
      expect(totals.isEmpty, isFalse);
    });

    test(
      'all zero: shares are 0 (no division by zero) and isEmpty is true',
      () {
        final totals = CategoryTotals.of(const []);

        expect(totals.total, 0);
        expect(totals.isEmpty, isTrue);
        expect(totals.shares.values, everyElement(0.0));
        for (final c in ExpenseCategory.values) {
          expect(totals.shareOf(c).isNaN, isFalse);
        }
      },
    );

    test('equal data gives equal objects', () {
      expect(
        CategoryTotals.of([_e(1000, DateTime(2026, 10, 1))]),
        CategoryTotals.of([_e(1000, DateTime(2026, 9, 1))]),
      );
      expect(
        CategoryTotals.of([_e(1000, DateTime(2026, 10, 1))]),
        isNot(
          CategoryTotals.of([
            _e(1000, DateTime(2026, 10, 1), ExpenseCategory.gear),
          ]),
        ),
      );
    });
  });
}
