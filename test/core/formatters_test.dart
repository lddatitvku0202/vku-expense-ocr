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

  group('Formatters.compactVnd (chart labels)', () {
    test('short forms with a Vietnamese decimal comma', () {
      expect(Formatters.compactVnd(0), '0');
      expect(Formatters.compactVnd(950), '950');
      expect(Formatters.compactVnd(75000), '75k');
      expect(Formatters.compactVnd(59500), '59,5k');
      expect(Formatters.compactVnd(1000000), '1tr');
      expect(Formatters.compactVnd(1250000), '1,25tr');
      expect(Formatters.compactVnd(2500000000), '2,5 tỷ');
      expect(Formatters.compactVnd(123456789012), '123,46 tỷ');
    });
  });

  test('Formatters.percent: one decimal with a comma', () {
    expect(Formatters.percent(0.375), '37,5%');
    expect(Formatters.percent(0.5), '50,0%');
    expect(Formatters.percent(1), '100,0%');
    expect(Formatters.percent(0.0004), '0,0%');
  });
}
