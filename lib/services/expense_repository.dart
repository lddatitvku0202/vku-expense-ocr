import 'package:sqflite/sqflite.dart';
import 'package:vku_expense_ocr/models/expense.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/services/database_service.dart';

/// Storage of expenses, independent of the database engine (FR-5.2).
///
/// State and screens depend on this interface only, so tests can swap in
/// an in-memory fake.
abstract interface class ExpenseRepository {
  /// Saves [expense] and returns it with its database id. An expense that
  /// already has an id (one being restored by Undo) keeps it.
  Future<Expense> insert(Expense expense);

  /// Every expense, newest date first (ties: most recently added first).
  Future<List<Expense>> getAll();

  Future<Expense?> getById(int id);

  /// Replaces the saved row of [expense] and returns it with a fresh
  /// `updatedAt`. Throws [ArgumentError] when [expense] has no id and
  /// [StateError] when its row no longer exists.
  Future<Expense> update(Expense expense);

  /// Deletes the row and returns what was deleted (for Undo), or `null`
  /// when no row had that id. Photo files are not touched; see
  /// `ImageStorageService.deleteFilesOf`.
  Future<Expense?> delete(int id);

  /// Expenses from the start of [firstDay] to the end of [lastDay], both
  /// days included, newest first. Times of day in the arguments are
  /// ignored.
  Future<List<Expense>> getBetween(DateTime firstDay, DateTime lastDay);

  /// Sum of amounts per category, optionally limited to a day range like
  /// [getBetween]. Categories without expenses are left out.
  Future<Map<ExpenseCategory, int>> totalsByCategory({
    DateTime? firstDay,
    DateTime? lastDay,
  });
}

/// [ExpenseRepository] backed by the sqflite `expenses` table.
class SqfliteExpenseRepository implements ExpenseRepository {
  SqfliteExpenseRepository(this._db, {this._clock = DateTime.now});

  final Database _db;
  final DateTime Function() _clock;

  static const String _table = DatabaseService.tableExpenses;
  static const String _newestFirst =
      '${Expense.columnDate} DESC, ${Expense.columnId} DESC';
  static const String _inDayRange =
      '${Expense.columnDate} >= ? AND ${Expense.columnDate} < ?';

  @override
  Future<Expense> insert(Expense expense) async {
    final id = await _db.insert(_table, expense.toMap());
    return expense.copyWith(id: id);
  }

  @override
  Future<List<Expense>> getAll() async {
    final rows = await _db.query(_table, orderBy: _newestFirst);
    return rows.map(Expense.fromMap).toList();
  }

  @override
  Future<Expense?> getById(int id) async {
    final rows = await _db.query(
      _table,
      where: '${Expense.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Expense.fromMap(rows.first);
  }

  @override
  Future<Expense> update(Expense expense) async {
    final id = expense.id;
    if (id == null) {
      throw ArgumentError.value(expense, 'expense', 'has not been saved');
    }
    final updated = expense.copyWith(updatedAt: _clock());
    final count = await _db.update(
      _table,
      updated.toMap(),
      where: '${Expense.columnId} = ?',
      whereArgs: [id],
    );
    if (count == 0) throw StateError('No expense with id $id');
    return updated;
  }

  @override
  Future<Expense?> delete(int id) => _db.transaction((txn) async {
    final rows = await txn.query(
      _table,
      where: '${Expense.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    await txn.delete(_table, where: '${Expense.columnId} = ?', whereArgs: [id]);
    return Expense.fromMap(rows.first);
  });

  @override
  Future<List<Expense>> getBetween(DateTime firstDay, DateTime lastDay) async {
    final rows = await _db.query(
      _table,
      where: _inDayRange,
      whereArgs: _dayBounds(firstDay, lastDay),
      orderBy: _newestFirst,
    );
    return rows.map(Expense.fromMap).toList();
  }

  @override
  Future<Map<ExpenseCategory, int>> totalsByCategory({
    DateTime? firstDay,
    DateTime? lastDay,
  }) async {
    final (where, args) = switch ((firstDay, lastDay)) {
      (null, null) => (null, null),
      (final DateTime first, final DateTime last) => (
        _inDayRange,
        _dayBounds(first, last),
      ),
      _ => throw ArgumentError('Give both firstDay and lastDay, or neither'),
    };
    final rows = await _db.query(
      _table,
      columns: [
        Expense.columnCategory,
        'SUM(${Expense.columnAmount}) AS total',
      ],
      where: where,
      whereArgs: args,
      groupBy: Expense.columnCategory,
    );
    return {
      for (final row in rows)
        ExpenseCategory.fromDbValue(row[Expense.columnCategory]! as String):
            row['total']! as int,
    };
  }

  /// Epoch-ms bounds `[start of firstDay, start of the day after lastDay)`.
  /// A half-open range includes 23:59:59.999 of [lastDay] without having to
  /// pick a "last millisecond".
  static List<int> _dayBounds(DateTime firstDay, DateTime lastDay) {
    final start = DateTime(firstDay.year, firstDay.month, firstDay.day);
    final end = DateTime(lastDay.year, lastDay.month, lastDay.day + 1);
    if (!end.isAfter(start)) {
      throw ArgumentError('lastDay $lastDay is before firstDay $firstDay');
    }
    return [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch];
  }
}
