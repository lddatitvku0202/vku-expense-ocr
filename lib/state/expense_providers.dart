import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vku_expense_ocr/core/date_ranges.dart';
import 'package:vku_expense_ocr/models/category_totals.dart';
import 'package:vku_expense_ocr/models/expense.dart';
import 'package:vku_expense_ocr/models/weekly_totals.dart';
import 'package:vku_expense_ocr/services/expense_repository.dart';
import 'package:vku_expense_ocr/services/image_storage_service.dart';
import 'package:vku_expense_ocr/state/storage_providers.dart';

/// Every saved expense, newest first: the app state of W8 s4–6. Screens and
/// charts read it (or a provider derived from it) and rebuild when it
/// changes (FR-6.5).
final expenseListProvider =
    AsyncNotifierProvider<ExpenseListNotifier, List<Expense>>(
      ExpenseListNotifier.new,
    );

/// A deleted expense whose photo files are kept until Undo is no longer
/// possible.
typedef _PendingDeletion = ({Expense expense, Timer timer});

class ExpenseListNotifier extends AsyncNotifier<List<Expense>> {
  /// How long a deletion can be undone. The History snack bar (Phase 8)
  /// uses the same duration.
  static const Duration undoWindow = Duration(seconds: 5);

  late ExpenseRepository _repository;
  late ImageStorageService _images;
  final Map<int, _PendingDeletion> _pending = {};

  @override
  Future<List<Expense>> build() {
    _repository = ref.watch(expenseRepositoryProvider);
    _images = ref.watch(imageStorageProvider);
    ref.onDispose(_commitAllDeletions);
    return _repository.getAll();
  }

  /// Saves a new expense and returns it with its id.
  Future<Expense> add(Expense expense) async {
    final saved = await _repository.insert(expense);
    await _reload();
    return saved;
  }

  /// Saves an expense from the Review screen: first copies [photoPath]
  /// into app storage with its thumbnail (FR-5.3), then inserts the row.
  ///
  /// If the insert fails, the photo files just written are deleted again,
  /// so a failed save leaves no orphan files, and the error is rethrown
  /// for the screen to show. If storing the photo fails, nothing is saved.
  Future<Expense> addWithPhoto(Expense expense, {String? photoPath}) async {
    if (photoPath == null) return add(expense);
    final stored = await _images.save(photoPath);
    try {
      return await add(
        expense.copyWith(
          imagePath: () => stored.imagePath,
          thumbPath: () => stored.thumbPath,
        ),
      );
    } on Object {
      await _deleteFiles([stored.imagePath, stored.thumbPath]);
      rethrow;
    }
  }

  /// Saves changes to an existing expense. When the photo was replaced, the
  /// old files are deleted once the new row is saved.
  ///
  /// Named `edit` because [AsyncNotifier] already has an `update` method.
  Future<Expense> edit(Expense expense) async {
    final id = expense.id;
    final previous = id == null ? null : await _repository.getById(id);
    final saved = await _repository.update(expense);
    await _reload();
    if (previous != null) {
      await _deleteFiles([
        if (previous.imagePath != saved.imagePath) previous.imagePath,
        if (previous.thumbPath != saved.thumbPath) previous.thumbPath,
      ]);
    }
    return saved;
  }

  /// Deletes an expense and returns it, or `null` for an unknown id.
  ///
  /// The list is updated synchronously, before the database call, because
  /// a swiped-away `Dismissible` must leave the tree on the next frame. The
  /// photo files stay on disk for [undoWindow] so [restore] can bring the
  /// expense back with its photo (FR-5.4, D-032).
  Future<Expense?> remove(int id) async {
    final current = state.valueOrNull ?? await future;
    state = AsyncData([
      for (final expense in current)
        if (expense.id != id) expense,
    ]);

    final Expense? removed;
    try {
      removed = await _repository.delete(id);
    } on Object {
      await _reload();
      rethrow;
    }
    if (removed == null) {
      await _reload();
      return null;
    }
    _pending.remove(id)?.timer.cancel();
    _pending[id] = (
      expense: removed,
      timer: Timer(undoWindow, () => unawaited(commitDeletion(id))),
    );
    return removed;
  }

  /// Undo: puts back an expense removed less than [undoWindow] ago, with
  /// its original id and photo. Returns `false` when the window has passed
  /// (the photo is gone, so nothing is restored).
  ///
  /// The id can always be kept: AUTOINCREMENT never hands out the id of a
  /// deleted row again (D-037).
  Future<bool> restore(int id) async {
    final pending = _pending.remove(id);
    if (pending == null) return false;
    pending.timer.cancel();
    try {
      await _repository.insert(pending.expense);
    } on Object {
      // Keep the deletion pending so the files are still cleaned up later.
      _pending[id] = (
        expense: pending.expense,
        timer: Timer(undoWindow, () => unawaited(commitDeletion(id))),
      );
      rethrow;
    }
    await _reload();
    return true;
  }

  /// Ends the Undo window early (the snack bar was dismissed) and deletes
  /// the photo files now.
  Future<void> commitDeletion(int id) async {
    final pending = _pending.remove(id);
    if (pending == null) return;
    pending.timer.cancel();
    await _deleteFiles([pending.expense.imagePath, pending.expense.thumbPath]);
  }

  bool isPendingDeletion(int id) => _pending.containsKey(id);

  /// Keeps a removed expense restorable for as long as a snack bar offers
  /// Undo for it: the [undoWindow] timer is cancelled and the caller must
  /// end the hold with [restore] or [commitDeletion].
  ///
  /// The snack bar uses the same [undoWindow] as its duration, but its
  /// timer only starts once it has slid in; without the hold the photo
  /// could be deleted while "Hoàn tác" is still on screen. If the app is
  /// closed meanwhile, disposing the state (or the startup orphan sweep)
  /// still removes the files.
  void holdForUndo(int id) {
    final pending = _pending[id];
    if (pending == null) return;
    pending.timer.cancel();
  }

  /// When the state is torn down (app closing), Undo is no longer possible.
  void _commitAllDeletions() {
    final pending = _pending.values.toList();
    _pending.clear();
    for (final p in pending) {
      p.timer.cancel();
      unawaited(_deleteFiles([p.expense.imagePath, p.expense.thumbPath]));
    }
  }

  Future<void> _reload() async {
    state = await AsyncValue.guard(_repository.getAll);
  }

  /// File clean-up never fails the user's action: a leftover file is
  /// removed by the orphan sweep on the next start.
  Future<void> _deleteFiles(List<String?> paths) async {
    if (paths.nonNulls.isEmpty) return;
    try {
      await _images.delete(paths);
    } on Exception catch (error) {
      developer.log(
        'Could not delete $paths',
        name: 'vku_expense_ocr.state',
        error: error,
      );
    }
  }
}

/// First day of the month shown on the Dashboard.
final selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, DateTime>(
  SelectedMonthNotifier.new,
);

class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateRanges.startOfMonth(ref.watch(clockProvider)());

  void previous() => state = DateRanges.addMonths(state, -1);

  void next() => state = DateRanges.addMonths(state, 1);

  void select(DateTime anyDay) => state = DateRanges.startOfMonth(anyDay);

  void showCurrent() => select(ref.read(clockProvider)());
}

/// Monday 00:00 of the week shown by the weekly bar chart (FR-6.3).
final selectedWeekProvider = NotifierProvider<SelectedWeekNotifier, DateTime>(
  SelectedWeekNotifier.new,
);

class SelectedWeekNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateRanges.startOfWeek(ref.watch(clockProvider)());

  void previous() => state = DateRanges.addDays(state, -DateTime.daysPerWeek);

  void next() => state = DateRanges.addDays(state, DateTime.daysPerWeek);

  void select(DateTime anyDay) => state = DateRanges.startOfWeek(anyDay);

  void showCurrent() => select(ref.read(clockProvider)());
}

/// Expenses of the selected month (both ends included).
final monthExpensesProvider = Provider<AsyncValue<List<Expense>>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final next = DateRanges.addMonths(month, 1);
  return ref
      .watch(expenseListProvider)
      .whenData(
        (expenses) => [
          for (final e in expenses)
            if (!e.date.isBefore(month) && e.date.isBefore(next)) e,
        ],
      );
});

/// All five categories of the selected month with their shares (donut).
final categoryTotalsProvider = Provider<AsyncValue<CategoryTotals>>(
  (ref) => ref.watch(monthExpensesProvider).whenData(CategoryTotals.of),
);

/// Total spending of the selected month.
final monthTotalProvider = Provider<AsyncValue<int>>(
  (ref) => ref.watch(categoryTotalsProvider).whenData((t) => t.total),
);

/// Seven daily totals, Monday → Sunday, of the selected week.
final weeklyTotalsProvider = Provider<AsyncValue<WeeklyTotals>>((ref) {
  final weekStart = ref.watch(selectedWeekProvider);
  return ref
      .watch(expenseListProvider)
      .whenData((expenses) => WeeklyTotals.of(expenses, weekStart));
});
