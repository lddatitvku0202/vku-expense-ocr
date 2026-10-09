import 'package:meta/meta.dart';
import 'package:vku_expense_ocr/models/expense.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';

/// Spending per category for the donut chart (FR-6.1).
///
/// Always holds all five categories (0 when nothing was spent), in
/// [ExpenseCategory.values] order, so slices keep a stable order and colour.
@immutable
class CategoryTotals {
  const CategoryTotals._(this.amounts);

  factory CategoryTotals.of(Iterable<Expense> expenses) {
    final sums = {for (final c in ExpenseCategory.values) c: 0};
    for (final expense in expenses) {
      sums[expense.category] = sums[expense.category]! + expense.amount;
    }
    return CategoryTotals._(Map.unmodifiable(sums));
  }

  /// Amount in dong for every category.
  final Map<ExpenseCategory, int> amounts;

  int amountOf(ExpenseCategory category) => amounts[category]!;

  int get total => amounts.values.fold(0, (sum, amount) => sum + amount);

  /// Nothing spent: the chart shows its empty state instead (FR-6.6).
  bool get isEmpty => total == 0;

  /// Fraction of [total] between 0 and 1; 0 for every category when the
  /// total is 0, so callers never divide by zero.
  double shareOf(ExpenseCategory category) {
    final total = this.total;
    return total == 0 ? 0 : amountOf(category) / total;
  }

  /// [shareOf] for every category; sums to 1 unless [isEmpty].
  Map<ExpenseCategory, double> get shares => {
    for (final c in ExpenseCategory.values) c: shareOf(c),
  };

  @override
  bool operator ==(Object other) =>
      other is CategoryTotals &&
      ExpenseCategory.values.every((c) => other.amounts[c] == amounts[c]);

  @override
  int get hashCode =>
      Object.hashAll(ExpenseCategory.values.map((c) => amounts[c]));

  @override
  String toString() => 'CategoryTotals($amounts)';
}
