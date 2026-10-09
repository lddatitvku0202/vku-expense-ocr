import 'package:meta/meta.dart';
import 'package:vku_expense_ocr/core/date_ranges.dart';
import 'package:vku_expense_ocr/models/expense.dart';

/// Spending per day for one week, Monday (index 0) to Sunday (index 6),
/// for the weekly bar chart (FR-6.3).
@immutable
class WeeklyTotals {
  WeeklyTotals({required this.weekStart, required List<int> days})
    : assert(days.length == DateTime.daysPerWeek, 'a week has 7 days'),
      days = List.unmodifiable(days);

  /// Sums [expenses] into the week that contains [anyDay].
  factory WeeklyTotals.of(Iterable<Expense> expenses, DateTime anyDay) {
    final weekStart = DateRanges.startOfWeek(anyDay);
    final next = DateRanges.addDays(weekStart, DateTime.daysPerWeek);
    final days = List.filled(DateTime.daysPerWeek, 0);
    for (final expense in expenses) {
      final date = expense.date;
      if (date.isBefore(weekStart) || !date.isBefore(next)) continue;
      days[date.weekday - DateTime.monday] += expense.amount;
    }
    return WeeklyTotals(weekStart: weekStart, days: days);
  }

  /// Monday 00:00 local time.
  final DateTime weekStart;

  /// Seven amounts in dong, Monday first.
  final List<int> days;

  DateTime dayAt(int index) => DateRanges.addDays(weekStart, index);

  int get total => days.fold(0, (sum, day) => sum + day);

  /// Highest day, the 100% height of the bars.
  int get max => days.reduce((a, b) => a > b ? a : b);

  bool get isEmpty => total == 0;

  @override
  bool operator ==(Object other) =>
      other is WeeklyTotals &&
      other.weekStart == weekStart &&
      Iterable<int>.generate(DateTime.daysPerWeek)
          .every((i) => other.days[i] == days[i]);

  @override
  int get hashCode => Object.hash(weekStart, Object.hashAll(days));

  @override
  String toString() => 'WeeklyTotals($weekStart, $days)';
}
