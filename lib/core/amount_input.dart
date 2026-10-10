import 'package:flutter/services.dart';

/// Reading and writing VND amounts typed or pasted by the user (FR-4.6).
abstract final class AmountInput {
  /// Up to 999.999.999.999 đ, far above any personal expense.
  static const int maxDigits = 12;

  static final RegExp _currency = RegExp(r'vn[dđ]|đ', caseSensitive: false);
  static final RegExp _space = RegExp(r'\s+');
  static final RegExp _digitsOnly = RegExp(r'^\d+$');
  static final RegExp _separators = RegExp('[.,]');

  /// Grouped thousands with an optional 1–2 digit decimal part written
  /// with the *other* separator, e.g. "150.000,00" or "123,100.00" (POS
  /// printouts). VND has no minor unit, so the decimals are dropped.
  static final RegExp _grouped = RegExp(
    r'^(\d{1,3}(?:([.,])\d{3})+)(?:(?!\2)[.,](\d{1,2}))?$',
  );

  /// The amount in dong, or `null` when [text] is not an amount. Accepts
  /// "150000", "150.000", "150,000", "150.000đ", "150,000 VND",
  /// "1.250.000 VNĐ", "150.000,00".
  static int? parse(String? text) {
    if (text == null) return null;
    final cleaned = text.replaceAll(_currency, '').replaceAll(_space, '');
    if (cleaned.isEmpty) return null;
    if (_digitsOnly.hasMatch(cleaned)) return int.tryParse(cleaned);
    final match = _grouped.firstMatch(cleaned);
    if (match == null) return null;
    return int.tryParse(match.group(1)!.replaceAll(_separators, ''));
  }

  /// Thousands separated by dots, Vietnamese style: 1250000 → "1.250.000".
  static String format(int value) => _group(value.toString());

  static String _group(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

/// Formats the amount field as the user types: digits only, a dot every
/// three digits, the cursor kept next to the digit being edited (FR-4.6).
///
/// Pasted or autofilled text such as "150,000" or "150.000đ" is read with
/// [AmountInput.parse].
class VndAmountInputFormatter extends TextInputFormatter {
  const VndAmountInputFormatter();

  static final RegExp _nonDigit = RegExp(r'\D');
  static final RegExp _typed = RegExp(r'^[\d.]*$');
  static final RegExp _leadingZeros = RegExp('^0+');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    var cursor = newValue.selection.isValid
        ? newValue.selection.extentOffset.clamp(0, text.length)
        : text.length;

    if (!_typed.hasMatch(text)) {
      // Anything but digits and our own dots was pasted: parse it whole.
      final pasted = AmountInput.parse(text);
      if (pasted == null) return oldValue;
      return _result(pasted.toString(), null, oldValue);
    }

    // Backspace that only removed a dot: delete the digit before it, so the
    // cursor does not get stuck in front of the separator.
    final removedOneChar = oldValue.text.length - text.length == 1;
    if (removedOneChar &&
        newValue.selection.isCollapsed &&
        _digits(oldValue.text) == _digits(text) &&
        cursor > 0) {
      text = text.replaceRange(cursor - 1, cursor, '');
      cursor -= 1;
    }

    final digitsBeforeCursor = _digits(text.substring(0, cursor)).length;
    return _result(_digits(text), digitsBeforeCursor, oldValue);
  }

  /// [digitsBeforeCursor] `null` puts the cursor at the end.
  static TextEditingValue _result(
    String digits,
    int? digitsBeforeCursor,
    TextEditingValue oldValue,
  ) {
    var trimmed = digits.replaceFirst(_leadingZeros, '');
    final removedZeros = digits.length - trimmed.length;
    if (trimmed.isEmpty && digits.isNotEmpty) trimmed = '0';
    if (trimmed.length > AmountInput.maxDigits) return oldValue;

    final formatted = AmountInput._group(trimmed);
    var offset = formatted.length;
    if (digitsBeforeCursor != null) {
      final wanted = (digitsBeforeCursor - removedZeros).clamp(
        0,
        trimmed.length,
      );
      offset = _offsetAfterDigits(formatted, wanted);
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }

  static String _digits(String text) => text.replaceAll(_nonDigit, '');

  /// Position right after the [count]-th digit of [formatted].
  static int _offsetAfterDigits(String formatted, int count) {
    if (count == 0) return 0;
    var seen = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (formatted[i] != '.') seen++;
      if (seen == count) return i + 1;
    }
    return formatted.length;
  }
}
