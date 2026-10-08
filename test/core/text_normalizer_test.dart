import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/core/text_normalizer.dart';

void main() {
  group('TextNormalizer.normalize', () {
    test('removes accents, lowercases and keeps word spacing', () {
      expect(
        TextNormalizer.normalize('Tổng Tiền Thanh Toán'),
        'tong tien thanh toan',
      );
    });

    test('maps Đ and đ to d', () {
      expect(TextNormalizer.normalize('Đ'), 'd');
      expect(TextNormalizer.normalize('đ'), 'd');
      expect(TextNormalizer.normalize('ĐƯỜNG Điện Biên'), 'duong dien bien');
    });

    test('collapses whitespace and trims', () {
      expect(
        TextNormalizer.normalize('  Khách \t phải\n  trả  '),
        'khach phai tra',
      );
    });

    test('keeps digits and punctuation unchanged', () {
      expect(
        TextNormalizer.normalize('Tổng cộng: 1.250.000 VNĐ'),
        'tong cong: 1.250.000 vnd',
      );
    });

    test('is idempotent', () {
      const input = 'Cần thanh toán';
      final once = TextNormalizer.normalize(input);
      expect(TextNormalizer.normalize(once), once);
    });
  });

  group('TextNormalizer.removeDiacritics', () {
    test('covers every Vietnamese vowel with all five tones', () {
      const lower =
          'àáạảã âầấậẩẫ ăằắặẳẵ èéẹẻẽ êềếệểễ ìíịỉĩ '
          'òóọỏõ ôồốộổỗ ơờớợởỡ ùúụủũ ưừứựửữ ỳýỵỷỹ đ';
      expect(
        TextNormalizer.removeDiacritics(lower),
        'aaaaa aaaaaa aaaaaa eeeee eeeeee iiiii '
        'ooooo oooooo oooooo uuuuu uuuuuu yyyyy d',
      );
      expect(
        TextNormalizer.removeDiacritics(lower.toUpperCase()),
        'AAAAA AAAAAA AAAAAA EEEEE EEEEEE IIIII '
        'OOOOO OOOOOO OOOOOO UUUUU UUUUUU YYYYY D',
      );
    });

    test('keeps the original case', () {
      expect(TextNormalizer.removeDiacritics('Phúc Long'), 'Phuc Long');
    });

    test('strips combining marks from decomposed (NFD) text', () {
      // "Tiền" written as T-i-e + U+0302 (circumflex) + U+0300 (grave) + n.
      const decomposed = 'Tie\u0302\u0300n';
      expect(TextNormalizer.removeDiacritics(decomposed), 'Tien');
    });

    test('maps the OCR look-alike Ð (U+00D0) to D', () {
      expect(TextNormalizer.removeDiacritics('ÐT'), 'DT');
    });

    test('returns ASCII input unchanged', () {
      const ascii = 'TOTAL 150,000 VND - Amount due';
      expect(TextNormalizer.removeDiacritics(ascii), ascii);
    });
  });
}
