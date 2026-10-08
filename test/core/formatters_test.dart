import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/core/formatters.dart';

/// Non-breaking space that the vi_VN locale puts between amount and symbol.
const nbsp = '\u00A0';

void main() {
  group('Formatters.vnd', () {
    test('formats 150000 as "150.000 đ"', () {
      expect(Formatters.vnd(150000), '150.000$nbspđ');
    });

    test('uses dots as thousands separators for millions', () {
      expect(Formatters.vnd(1250000), '1.250.000$nbspđ');
    });

    test('has no decimal part', () {
      expect(Formatters.vnd(0), '0$nbspđ');
      expect(Formatters.vnd(999), '999$nbspđ');
    });

    test('renders the same as "150.000 đ" once NBSP is shown as a space', () {
      expect(Formatters.vnd(150000).replaceAll(nbsp, ' '), '150.000 đ');
    });
  });

  group('Formatters.groupDigits', () {
    test('groups thousands without a currency symbol', () {
      expect(Formatters.groupDigits(1250000), '1.250.000');
      expect(Formatters.groupDigits(500), '500');
    });
  });

  group('Formatters.date', () {
    test('formats as dd/MM/yyyy with zero padding', () {
      expect(Formatters.date(DateTime(2026, 10, 8)), '08/10/2026');
      expect(Formatters.date(DateTime(2026, 1, 31, 23, 59)), '31/01/2026');
    });
  });
}
