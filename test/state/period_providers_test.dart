import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/models/expense.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/state/expense_providers.dart';
import 'package:vku_expense_ocr/state/storage_providers.dart';

import '../support/fake_expense_repository.dart';
import '../support/fake_image_storage.dart';

Expense _e(int id, int amount, DateTime date) => Expense(
  id: id,
  merchant: 'm$id',
  amount: amount,
  date: date,
  category: ExpenseCategory.food,
  createdAt: date,
  updatedAt: date,
);

void main() {
  ProviderContainer container(DateTime now, List<Expense> expenses) {
    final c = ProviderContainer(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(
          FakeExpenseRepository(expenses),
        ),
        imageStorageProvider.overrideWithValue(FakeImageStorage()),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('selectedWeekProvider', () {
    test('starts at Monday 00:00 of the current week', () {
      final c = container(DateTime(2026, 10, 11, 23, 59, 59, 999), const []);
      expect(c.read(selectedWeekProvider), DateTime(2026, 10, 5));
    });

    test('previous / next / select move by whole weeks across years', () {
      final c = container(DateTime(2027, 1, 2), const []);
      final week = c.read(selectedWeekProvider.notifier);
      expect(c.read(selectedWeekProvider), DateTime(2026, 12, 28));

      week.next();
      expect(c.read(selectedWeekProvider), DateTime(2027, 1, 4));
      week
        ..previous()
        ..previous();
      expect(c.read(selectedWeekProvider), DateTime(2026, 12, 21));
      week.select(DateTime(2026, 10, 9, 15));
      expect(c.read(selectedWeekProvider), DateTime(2026, 10, 5));
      week.showCurrent();
      expect(c.read(selectedWeekProvider), DateTime(2026, 12, 28));
    });
  });

  group('weeklyTotalsProvider', () {
    final expenses = [
      _e(
        1,
        1000,
        DateTime(2026, 12, 27, 23, 59, 59, 999),
      ), // Sunday, week of 21/12
      _e(2, 2000, DateTime(2026, 12, 28)), // Monday 00:00
      _e(3, 3000, DateTime(2026, 12, 31, 23)),
      _e(4, 4000, DateTime(2027)),
      _e(5, 5000, DateTime(2027, 1, 3, 23, 59, 59, 999)), // Sunday
      _e(6, 6000, DateTime(2027, 1, 4)), // next Monday
    ];

    test(
      '7 days Monday → Sunday of the selected week, across New Year',
      () async {
        final c = container(DateTime(2027, 1, 1, 12), expenses);
        await c.read(expenseListProvider.future);

        final week = c.read(weeklyTotalsProvider).requireValue;
        expect(week.weekStart, DateTime(2026, 12, 28));
        expect(week.days, [2000, 0, 0, 3000, 4000, 0, 5000]);
      },
    );

    test('follows the selected week', () async {
      final c = container(DateTime(2027, 1, 1, 12), expenses);
      await c.read(expenseListProvider.future);

      c.read(selectedWeekProvider.notifier).previous();
      expect(c.read(weeklyTotalsProvider).requireValue.days, [
        0,
        0,
        0,
        0,
        0,
        0,
        1000,
      ]);
      c.read(selectedWeekProvider.notifier)
        ..next()
        ..next();
      expect(c.read(weeklyTotalsProvider).requireValue.days, [
        6000,
        0,
        0,
        0,
        0,
        0,
        0,
      ]);
    });
  });

  group(
    'selectedMonthProvider / monthTotalProvider / categoryTotalsProvider',
    () {
      final expenses = [
        _e(1, 1000, DateTime(2026, 9, 30, 23, 59, 59, 999)),
        _e(2, 2000, DateTime(2026, 10)),
        _e(3, 3000, DateTime(2026, 10, 31, 23, 59, 59, 999)),
        _e(4, 4000, DateTime(2026, 11)),
      ];

      test(
        'month total counts only the selected month, both ends included',
        () async {
          final c = container(DateTime(2026, 10, 15), expenses);
          await c.read(expenseListProvider.future);

          expect(c.read(selectedMonthProvider), DateTime(2026, 10));
          expect(c.read(monthTotalProvider).requireValue, 5000);
          expect(
            c
                .read(categoryTotalsProvider)
                .requireValue
                .amountOf(ExpenseCategory.food),
            5000,
          );
        },
      );

      test('previous / next month change every month-based total', () async {
        final c = container(DateTime(2026, 10, 15), expenses);
        await c.read(expenseListProvider.future);

        c.read(selectedMonthProvider.notifier).previous();
        expect(c.read(selectedMonthProvider), DateTime(2026, 9));
        expect(c.read(monthTotalProvider).requireValue, 1000);

        c.read(selectedMonthProvider.notifier)
          ..next()
          ..next();
        expect(c.read(monthTotalProvider).requireValue, 4000);
      });

      test(
        'an empty month has 5 zero categories and isEmpty for the chart',
        () async {
          final c = container(DateTime(2025, 1, 15), expenses);
          await c.read(expenseListProvider.future);

          final totals = c.read(categoryTotalsProvider).requireValue;
          expect(totals.amounts.length, 5);
          expect(totals.isEmpty, isTrue);
          expect(totals.shares.values, everyElement(0.0));
          expect(c.read(monthTotalProvider).requireValue, 0);
        },
      );
    },
  );
}
