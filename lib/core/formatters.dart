import 'package:intl/intl.dart';

/// Display formatting for money and dates (FR-8.3).
abstract final class Formatters {
  static final NumberFormat _vnd = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  static final NumberFormat _grouped = NumberFormat.decimalPattern('vi_VN');

  static final DateFormat _date = DateFormat('dd/MM/yyyy');

  /// Formats an amount of Vietnamese dong, e.g. 150000 → "150.000 đ".
  ///
  /// The space before "đ" is a non-breaking space (U+00A0) taken from the
  /// vi_VN locale data, so the symbol never wraps onto its own line.
  static String vnd(int amount) => _vnd.format(amount);

  /// Thousands separators only, e.g. 1250000 → "1.250.000".
  static String groupDigits(int value) => _grouped.format(value);

  /// Short amount for chart labels: 75000 → "75k", 1250000 → "1,25tr",
  /// 2500000000 → "2,5 tỷ" (at most two decimals, Vietnamese comma).
  static String compactVnd(int amount) => switch (amount) {
    >= 1000000000 => '${_short(amount / 1000000000)} tỷ',
    >= 1000000 => '${_short(amount / 1000000)}tr',
    >= 1000 => '${_short(amount / 1000)}k',
    _ => '$amount',
  };

  static String _short(double value) {
    final text = value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
    return text.replaceAll('.', ',');
  }

  /// A fraction as a percentage with one decimal: 0.375 → "37,5%".
  static String percent(double fraction) =>
      '${(fraction * 100).toStringAsFixed(1).replaceAll('.', ',')}%';

  /// Formats a date as dd/MM/yyyy, e.g. "08/10/2026".
  static String date(DateTime value) => _date.format(value);
}
