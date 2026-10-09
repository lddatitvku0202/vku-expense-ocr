/// Calendar arithmetic in local time for the charts and totals.
///
/// Every result is built with the `DateTime(y, m, d)` constructor instead of
/// adding a `Duration`: the constructor rolls over months and years
/// (`DateTime(2026, 12, 32)` is 01/01/2027) and always lands on local
/// midnight, even on days that are not 24 hours long in time zones with
/// daylight saving time.
abstract final class DateRanges {
  static DateTime startOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// Monday 00:00 of the week containing [value] (Vietnamese weeks run
  /// Thứ Hai → Chủ nhật).
  static DateTime startOfWeek(DateTime value) => DateTime(
    value.year,
    value.month,
    value.day - (value.weekday - DateTime.monday),
  );

  static DateTime startOfMonth(DateTime value) =>
      DateTime(value.year, value.month);

  static DateTime addDays(DateTime day, int days) =>
      DateTime(day.year, day.month, day.day + days);

  /// [month] must be the first day of a month (see [startOfMonth]).
  static DateTime addMonths(DateTime month, int months) =>
      DateTime(month.year, month.month + months);
}
