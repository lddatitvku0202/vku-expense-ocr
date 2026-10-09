import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vku_expense_ocr/models/expense.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/services/database_service.dart';
import 'package:vku_expense_ocr/services/expense_repository.dart';

void main() {
  sqfliteFfiInit();

  late Database db;
  late SqfliteExpenseRepository repo;
  var now = DateTime(2026, 10, 9, 20);

  setUp(() async {
    db = await DatabaseService(factory: databaseFactoryFfi)
        .open(inMemoryDatabasePath);
    now = DateTime(2026, 10, 9, 20);
    repo = SqfliteExpenseRepository(db, clock: () => now);
  });

  tearDown(() => db.close());

  Expense expense(
    String merchant,
    int amount,
    DateTime date, {
    ExpenseCategory category = ExpenseCategory.food,
    String? imagePath,
    String? thumbPath,
  }) => Expense(
    merchant: merchant,
    amount: amount,
    date: date,
    category: category,
    imagePath: imagePath,
    thumbPath: thumbPath,
    rawText: 'raw $merchant',
    createdAt: DateTime(2026, 10, 9, 8),
    updatedAt: DateTime(2026, 10, 9, 8),
  );

  group('insert / getById', () {
    test('assigns an id and round-trips every field', () async {
      final saved = await repo.insert(
        expense(
          'Highlands Coffee',
          59000,
          DateTime(2026, 10, 8, 9, 30, 15, 250),
          imagePath: '/docs/receipts/a.jpg',
          thumbPath: '/docs/receipts/a_thumb.jpg',
        ),
      );

      expect(saved.id, isNotNull);
      expect(await repo.getById(saved.id!), saved);
    });

    test('stores amount as INTEGER and dates as epoch milliseconds', () async {
      final date = DateTime(2026, 10, 8, 9, 30);
      final saved = await repo.insert(expense('Fahasa', 1250000, date));

      final raw = (await db.rawQuery(
        'SELECT typeof(amount) ta, typeof(date) td, typeof(created_at) tc, '
        'typeof(updated_at) tu, amount, date, created_at FROM expenses '
        'WHERE id = ?',
        [saved.id],
      )).single;
      expect(raw['ta'], 'integer');
      expect(raw['td'], 'integer');
      expect(raw['tc'], 'integer');
      expect(raw['tu'], 'integer');
      expect(raw['amount'], 1250000);
      expect(raw['date'], date.millisecondsSinceEpoch);
      expect(
        raw['created_at'],
        DateTime(2026, 10, 9, 8).millisecondsSinceEpoch,
      );
    });

    test('ids keep increasing', () async {
      final a = await repo.insert(expense('A', 1000, DateTime(2026, 10, 1)));
      final b = await repo.insert(expense('B', 2000, DateTime(2026, 10, 1)));
      expect(b.id, greaterThan(a.id!));
    });

    test('getById returns null for an unknown id', () async {
      expect(await repo.getById(999), isNull);
    });

    test('re-inserting a deleted expense keeps its id (undo)', () async {
      final saved = await repo.insert(
        expense('A', 1000, DateTime(2026, 10, 1)),
      );
      final removed = await repo.delete(saved.id!);

      final restored = await repo.insert(removed!);
      expect(restored, saved);
      expect(await repo.getById(saved.id!), saved);
    });
  });

  group('getAll', () {
    test('sorts by date, newest first, then by id', () async {
      final oct1 = await repo.insert(
        expense('Oct 1', 1000, DateTime(2026, 10, 1)),
      );
      final oct5a = await repo.insert(
        expense('Oct 5 a', 1000, DateTime(2026, 10, 5)),
      );
      final sep30 = await repo.insert(
        expense('Sep 30', 1000, DateTime(2026, 9, 30)),
      );
      final oct5b = await repo.insert(
        expense('Oct 5 b', 1000, DateTime(2026, 10, 5)),
      );

      expect(await repo.getAll(), [oct5b, oct5a, oct1, sep30]);
    });

    test('is empty for a new database', () async {
      expect(await repo.getAll(), isEmpty);
    });
  });

  group('update', () {
    test('changes the row and stamps updatedAt', () async {
      final saved = await repo.insert(
        expense('Circle K', 25000, DateTime(2026, 10, 2)),
      );
      now = DateTime(2026, 10, 9, 21, 15);

      final updated = await repo.update(
        saved.copyWith(
          merchant: 'Circle K Lê Duẩn',
          amount: 27000,
          category: ExpenseCategory.food,
          thumbPath: () => null,
        ),
      );

      expect(updated.merchant, 'Circle K Lê Duẩn');
      expect(updated.amount, 27000);
      expect(updated.updatedAt, DateTime(2026, 10, 9, 21, 15));
      expect(updated.createdAt, saved.createdAt);
      expect(updated.thumbPath, isNull);
      expect(await repo.getById(saved.id!), updated);
    });

    test('does not touch other rows', () async {
      final a = await repo.insert(expense('A', 1000, DateTime(2026, 10, 1)));
      final b = await repo.insert(expense('B', 2000, DateTime(2026, 10, 1)));

      await repo.update(a.copyWith(amount: 5000));
      expect(await repo.getById(b.id!), b);
    });

    test('rejects an expense that was never saved', () async {
      expect(
        () => repo.update(expense('A', 1000, DateTime(2026, 10, 1))),
        throwsArgumentError,
      );
    });

    test('fails for an id that no longer exists', () async {
      final saved = await repo.insert(
        expense('A', 1000, DateTime(2026, 10, 1)),
      );
      await repo.delete(saved.id!);

      expect(() => repo.update(saved), throwsStateError);
    });
  });

  group('delete', () {
    test('removes the row and returns it', () async {
      final a = await repo.insert(expense('A', 1000, DateTime(2026, 10, 1)));
      final b = await repo.insert(expense('B', 2000, DateTime(2026, 10, 2)));

      expect(await repo.delete(a.id!), a);
      expect(await repo.getAll(), [b]);
      expect(await repo.getById(a.id!), isNull);
    });

    test('returns null for an unknown id', () async {
      expect(await repo.delete(42), isNull);
    });
  });

  group('getBetween (day range, inclusive)', () {
    late Expense dayBeforeLastMs;
    late Expense firstDayStart;
    late Expense midRange;
    late Expense lastDayEnd;
    late Expense dayAfterStart;

    setUp(() async {
      dayBeforeLastMs = await repo.insert(
        expense('before', 1000, DateTime(2026, 10, 4, 23, 59, 59, 999)),
      );
      firstDayStart = await repo.insert(
        expense('first', 2000, DateTime(2026, 10, 5)),
      );
      midRange = await repo.insert(
        expense('mid', 3000, DateTime(2026, 10, 8, 12)),
      );
      lastDayEnd = await repo.insert(
        expense('last', 4000, DateTime(2026, 10, 11, 23, 59, 59, 999)),
      );
      dayAfterStart = await repo.insert(
        expense('after', 5000, DateTime(2026, 10, 12)),
      );
    });

    test(
      'includes 00:00:00.000 of the first day and 23:59:59.999 of the last',
      () async {
        final result = await repo.getBetween(
          DateTime(2026, 10, 5),
          DateTime(2026, 10, 11),
        );

        expect(result, [lastDayEnd, midRange, firstDayStart]);
        expect(result, isNot(contains(dayBeforeLastMs)));
        expect(result, isNot(contains(dayAfterStart)));
      },
    );

    test('ignores the time of day of its arguments', () async {
      final result = await repo.getBetween(
        DateTime(2026, 10, 5, 18, 30),
        DateTime(2026, 10, 11, 0, 1),
      );
      expect(result, [lastDayEnd, midRange, firstDayStart]);
    });

    test('a single day covers that whole day only', () async {
      expect(
        await repo.getBetween(DateTime(2026, 10, 12), DateTime(2026, 10, 12)),
        [dayAfterStart],
      );
      expect(
        await repo.getBetween(DateTime(2026, 10, 4), DateTime(2026, 10, 4)),
        [dayBeforeLastMs],
      );
    });

    test('works across a month and a year boundary', () async {
      final dec31 = await repo.insert(
        expense('dec31', 1000, DateTime(2026, 12, 31, 23, 59, 59, 999)),
      );
      final jan1 = await repo.insert(
        expense('jan1', 1000, DateTime(2027, 1, 1)),
      );
      await repo.insert(expense('jan2', 1000, DateTime(2027, 1, 2)));

      expect(
        await repo.getBetween(DateTime(2026, 12, 31), DateTime(2027, 1, 1)),
        [jan1, dec31],
      );
    });

    test('rejects a range that ends before it starts', () async {
      expect(
        () => repo.getBetween(DateTime(2026, 10, 11), DateTime(2026, 10, 5)),
        throwsArgumentError,
      );
    });
  });

  group('totalsByCategory', () {
    setUp(() async {
      await repo.insert(expense('a', 50000, DateTime(2026, 10, 1)));
      await repo.insert(expense('b', 25000, DateTime(2026, 10, 31, 23, 59)));
      await repo.insert(
        expense(
          'c',
          120000,
          DateTime(2026, 10, 15),
          category: ExpenseCategory.study,
        ),
      );
      await repo.insert(
        expense(
          'd',
          300000,
          DateTime(2026, 11, 1),
          category: ExpenseCategory.gear,
        ),
      );
    });

    test('sums every expense when no range is given', () async {
      expect(await repo.totalsByCategory(), {
        ExpenseCategory.food: 75000,
        ExpenseCategory.study: 120000,
        ExpenseCategory.gear: 300000,
      });
    });

    test('limits the sums to a day range', () async {
      expect(
        await repo.totalsByCategory(
          firstDay: DateTime(2026, 10, 1),
          lastDay: DateTime(2026, 10, 31),
        ),
        {ExpenseCategory.food: 75000, ExpenseCategory.study: 120000},
      );
    });

    test('is empty when nothing matches', () async {
      expect(
        await repo.totalsByCategory(
          firstDay: DateTime(2025, 1, 1),
          lastDay: DateTime(2025, 1, 31),
        ),
        isEmpty,
      );
    });

    test('returns int sums without rounding for large amounts', () async {
      await repo.insert(
        expense(
          'big',
          9007199254,
          DateTime(2026, 10, 2),
          category: ExpenseCategory.travel,
        ),
      );
      final totals = await repo.totalsByCategory();
      expect(totals[ExpenseCategory.travel], 9007199254);
      expect(totals[ExpenseCategory.travel], isA<int>());
    });
  });
}
