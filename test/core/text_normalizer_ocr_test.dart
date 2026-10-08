import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/core/text_normalizer.dart';

void main() {
  group('TextNormalizer.ocrKey', () {
    test('folds letters OCR confuses inside keywords', () {
      expect(TextNormalizer.ocrKey('Tong tlen'), 'tong tien');
      expect(TextNormalizer.ocrKey('T0NG C0NG'), 'tong cong');
      expect(TextNormalizer.ocrKey('TỔNG TIỀN'), 'tong tien');
    });

    test('folds keywords the same way, so both sides still match', () {
      expect(TextNormalizer.ocrKey('Total'), TextNormalizer.ocrKey('TOTAI'));
      expect(TextNormalizer.ocrKey('Hotline'), 'hotiine');
    });

    test('builds on normalize()', () {
      expect(TextNormalizer.ocrKey('  Khách   phải trả '), 'khach phai tra');
    });
  });

  group('TextNormalizer.repairDigits', () {
    test('turns O into 0 inside amounts and years', () {
      expect(TextNormalizer.repairDigits('139.5OO'), '139.500');
      expect(TextNormalizer.repairDigits('24/10/2O26'), '24/10/2026');
      expect(
        TextNormalizer.repairDigits('Tổng cộng 1O5.OOO đ'),
        'Tổng cộng 105.000 đ',
      );
    });

    test('turns I, l and | into 1 inside numbers', () {
      expect(TextNormalizer.repairDigits('2l/10/2026'), '21/10/2026');
      expect(TextNormalizer.repairDigits('45.I00'), '45.100');
    });

    test('leaves words and short codes alone', () {
      const text = 'LOTTE Mart Lô A2 Sữa 1L Phở 24 OK';
      expect(TextNormalizer.repairDigits(text), text);
    });
  });
}
