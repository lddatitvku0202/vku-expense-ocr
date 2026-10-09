import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/core/date_ranges.dart';

void main() {
  group('DateRanges.startOfWeek (Monday, local time)', () {
    test('every day of a week maps to its Monday at 00:00', () {
      // 05/10/2026 is a Monday, 11/10/2026 a Sunday.
      for (var day = 5; day <= 11; day++) {
        expect(
          DateRanges.startOfWeek(DateTime(2026, 10, day, 15, 30)),
          DateTime(2026, 10, 5),
          reason: 'day $day',
        );
      }
    });

    test('Sunday 23:59:59.999 belongs to the week before Monday 00:00', () {
      expect(
        DateRanges.startOfWeek(DateTime(2026, 10, 11, 23, 59, 59, 999)),
        DateTime(2026, 10, 5),
      );
      expect(
        DateRanges.startOfWeek(DateTime(2026, 10, 12)),
        DateTime(2026, 10, 12),
      );
    });

    test('a week that spans two months starts in the earlier month', () {
      // Mon 28/09/2026 … Sun 04/10/2026.
      expect(
        DateRanges.startOfWeek(DateTime(2026, 10, 2)),
        DateTime(2026, 9, 28),
      );
    });

    test('a week that spans New Year starts in the old year', () {
      // Mon 28/12/2026 … Sun 03/01/2027.
      expect(
        DateRanges.startOfWeek(DateTime(2027, 1, 3)),
        DateTime(2026, 12, 28),
      );
    });
  });

  group('other ranges', () {
    test('startOfDay drops the time', () {
      expect(
        DateRanges.startOfDay(DateTime(2026, 10, 9, 23, 59, 59, 999)),
        DateTime(2026, 10, 9),
      );
    });

    test('startOfMonth', () {
      expect(
        DateRanges.startOfMonth(DateTime(2026, 10, 31, 22)),
        DateTime(2026, 10),
      );
    });

    test('addDays and addMonths roll over months and years', () {
      expect(
        DateRanges.addDays(DateTime(2026, 12, 28), 7),
        DateTime(2027, 1, 4),
      );
      expect(
        DateRanges.addDays(DateTime(2026, 10, 5), -7),
        DateTime(2026, 9, 28),
      );
      expect(DateRanges.addMonths(DateTime(2026, 12), 1), DateTime(2027));
      expect(DateRanges.addMonths(DateTime(2026), -1), DateTime(2025, 12));
    });
  });
}
