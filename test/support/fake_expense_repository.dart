import 'package:vku_expense_ocr/models/expense.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/services/expense_repository.dart';

/// In-memory [ExpenseRepository] for state tests. Mirrors the sqflite
/// implementation's contract: AUTOINCREMENT ids that are never reused,
/// newest-first ordering and inclusive day ranges. Every call completes on
/// a microtask, so it also works inside `fakeAsync`.
class FakeExpenseRepository implements ExpenseRepository {
  FakeExpenseRepository([Iterable<Expense> initial = const []]) {
    for (final expense in initial) {
      final id = expense.id ?? ++_lastId;
      if (id > _lastId) _lastId = id;
      _rows[id] = expense.copyWith(id: id);
    }
  }

  final Map<int, Expense> _rows = {};
  int _lastId = 0;

  /// Set to make the next call of that kind throw (then cleared).
  Exception? failNextInsert;
  Exception? failNextDelete;

  /// Makes every [getAll] throw while set.
  Exception? failGetAll;

  /// When set, [getAll] waits for it first (a loading state that can be
  /// released by the test).
  Future<void>? getAllGate;

  int insertCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;

  @override
  Future<Expense> insert(Expense expense) async {
    insertCalls++;
    if (failNextInsert case final error?) {
      failNextInsert = null;
      throw error;
    }
    final id = expense.id ?? ++_lastId;
    if (_rows.containsKey(id)) throw StateError('Duplicate id $id');
    if (id > _lastId) _lastId = id;
    return _rows[id] = expense.copyWith(id: id);
  }

  @override
  Future<List<Expense>> getAll() async {
    if (getAllGate case final gate?) await gate;
    if (failGetAll case final error?) throw error;
    return _sorted(_rows.values);
  }

  @override
  Future<Expense?> getById(int id) async => _rows[id];

  @override
  Future<Expense> update(Expense expense) async {
    updateCalls++;
    final id = expense.id;
    if (id == null) throw ArgumentError.value(expense, 'expense');
    if (!_rows.containsKey(id)) throw StateError('No expense with id $id');
    return _rows[id] = expense;
  }

  @override
  Future<Expense?> delete(int id) async {
    deleteCalls++;
    if (failNextDelete case final error?) {
      failNextDelete = null;
      throw error;
    }
    return _rows.remove(id);
  }

  @override
  Future<List<Expense>> getBetween(DateTime firstDay, DateTime lastDay) async {
    final start = DateTime(firstDay.year, firstDay.month, firstDay.day);
    final end = DateTime(lastDay.year, lastDay.month, lastDay.day + 1);
    return _sorted(
      _rows.values.where(
        (e) => !e.date.isBefore(start) && e.date.isBefore(end),
      ),
    );
  }

  @override
  Future<Map<ExpenseCategory, int>> totalsByCategory({
    DateTime? firstDay,
    DateTime? lastDay,
  }) async {
    final rows = firstDay != null && lastDay != null
        ? await getBetween(firstDay, lastDay)
        : _rows.values;
    final totals = <ExpenseCategory, int>{};
    for (final e in rows) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }

  static List<Expense> _sorted(Iterable<Expense> rows) =>
      rows.toList()..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        return byDate != 0 ? byDate : b.id!.compareTo(a.id!);
      });
}
