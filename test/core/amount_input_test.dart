import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/core/amount_input.dart';

TextEditingValue _v(String text, [int? cursor]) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: cursor ?? text.length),
);

void main() {
  group('AmountInput.parse', () {
    test('reads every format a receipt or a paste may use', () {
      const cases = {
        '150000': 150000,
        '150.000': 150000,
        '150,000': 150000,
        '150.000đ': 150000,
        '150.000 đ': 150000,
        '150,000 VND': 150000,
        '150.000 VNĐ': 150000,
        '1.250.000': 1250000,
        ' 1 250 000 ': 1250000,
        '150.000,00': 150000,
        '123,100.00': 123100,
        '0': 0,
      };
      for (final MapEntry(key: text, value: expected) in cases.entries) {
        expect(AmountInput.parse(text), expected, reason: text);
      }
    });

    test('returns null for empty or non-numeric input', () {
      for (final text in [null, '', '   ', 'đ', 'abc', '12a3', '-5']) {
        expect(AmountInput.parse(text), isNull, reason: '$text');
      }
    });
  });

  test('AmountInput.format groups thousands with dots', () {
    expect(AmountInput.format(0), '0');
    expect(AmountInput.format(999), '999');
    expect(AmountInput.format(1000), '1.000');
    expect(AmountInput.format(1250000), '1.250.000');
    expect(AmountInput.format(999999999999), '999.999.999.999');
  });

  group('VndAmountInputFormatter (FR-4.6)', () {
    const formatter = VndAmountInputFormatter();
    TextEditingValue type(TextEditingValue old, TextEditingValue next) =>
        formatter.formatEditUpdate(old, next);

    test('inserts dots while typing digit by digit', () {
      var value = TextEditingValue.empty;
      final shown = <String>[];
      for (final digit in '1250000'.split('')) {
        value = type(value, _v(value.text + digit));
        shown.add(value.text);
      }
      expect(shown, [
        '1',
        '12',
        '125',
        '1.250',
        '12.500',
        '125.000',
        '1.250.000',
      ]);
      expect(value.selection.baseOffset, value.text.length);
    });

    test('typing in the middle keeps the cursor after the new digit', () {
      // "1.250|.000", type 9: the text regroups to "12.509.000" and the
      // cursor must stay right after the 9, i.e. after the 5th digit.
      final result = type(_v('1.250.000', 5), _v('1.2509.000', 6));
      expect(result.text, '12.509.000');
      expect(result.selection.baseOffset, 6); // "12.509|.000"
    });

    test('deleting a digit in the middle keeps the cursor in place', () {
      // "1.25|0.000" → backspace removes "5".
      final result = type(_v('1.250.000', 4), _v('1.20.000', 3));
      expect(result.text, '120.000');
      expect(result.selection.baseOffset, 2); // "12|0.000"
    });

    test('backspace right after a dot deletes the digit before it', () {
      // "1.|250" → backspace would only remove the dot; remove "1" instead.
      final result = type(_v('1.250', 2), _v('1250', 1));
      expect(result.text, '250');
      expect(result.selection.baseOffset, 0);
    });

    test('pasting "150,000" or "150.000đ" gives 150.000', () {
      for (final pasted in ['150,000', '150.000đ', '150.000 VNĐ', '150000']) {
        final result = type(TextEditingValue.empty, _v(pasted));
        expect(result.text, '150.000', reason: pasted);
        expect(result.selection.baseOffset, result.text.length);
      }
    });

    test('drops leading zeros but keeps a single 0', () {
      expect(type(TextEditingValue.empty, _v('0')).text, '0');
      expect(type(_v('0'), _v('05')).text, '5');
      expect(type(_v('0'), _v('00')).text, '0');
    });

    test('rejects text that is not an amount and longer than 12 digits', () {
      final old = _v('1.000');
      expect(type(old, _v('1.000x')), old);
      expect(
        type(_v('999.999.999.999'), _v('999.999.999.9999')),
        _v('999.999.999.999'),
      );
    });

    test('clearing the field gives an empty field', () {
      expect(type(_v('5'), _v('')).text, '');
    });
  });
}
