/// Diacritic-insensitive text normalization for Vietnamese receipts (FR-3.1).
///
/// OCR output keeps Vietnamese accents ("Tổng tiền"), while keyword tables in
/// the parser are written without them ("tong tien"). Matching is therefore
/// done on the normalized form, and the original text is kept for display.
abstract final class TextNormalizer {
  /// Base letter for every precomposed Vietnamese character.
  static const Map<String, String> _groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    // "ð" (U+00F0) is a common OCR confusion for "đ".
    'd': 'đð',
    'A': 'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ',
    'E': 'ÈÉẸẺẼÊỀẾỆỂỄ',
    'I': 'ÌÍỊỈĨ',
    'O': 'ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ',
    'U': 'ÙÚỤỦŨƯỪỨỰỬỮ',
    'Y': 'ỲÝỴỶỸ',
    'D': 'ĐÐ',
  };

  static final Map<int, String> _lookup = {
    for (final MapEntry(key: base, value: accented) in _groups.entries)
      for (final codeUnit in accented.codeUnits) codeUnit: base,
  };

  /// Combining diacritical marks (U+0300–U+036F), produced when text arrives
  /// in decomposed (NFD) form, e.g. "e" + U+0302 instead of "ê".
  static final RegExp _combiningMarks = RegExp('[\u0300-\u036F]');

  static final RegExp _whitespace = RegExp(r'\s+');

  /// Replaces Vietnamese accented letters with their ASCII base letter and
  /// keeps the original letter case: "Đường" becomes "Duong".
  static String removeDiacritics(String input) {
    final buffer = StringBuffer();
    for (final codeUnit in input.codeUnits) {
      buffer.write(_lookup[codeUnit] ?? String.fromCharCode(codeUnit));
    }
    return buffer.toString().replaceAll(_combiningMarks, '');
  }

  /// Form used for keyword matching: no accents, lower case, single spaces.
  ///
  /// "  Tổng   Tiền Thanh Toán " becomes "tong tien thanh toan".
  static String normalize(String input) =>
      removeDiacritics(input).toLowerCase().replaceAll(_whitespace, ' ').trim();

  /// Look-alike characters folded to one representative by [ocrKey].
  static const Map<String, String> _ocrFold = {
    '0': 'o',
    '1': 'i',
    'l': 'i',
    '|': 'i',
  };

  /// Key for matching keywords in noisy OCR text.
  ///
  /// [normalize] plus folding of characters OCR confuses (0 → o and
  /// 1, l, | → i), so "Tong tlen" and "T0NG TIEN" both become "tong tien".
  /// Keywords must go through the same function before comparison:
  /// "total" becomes "totai" on both sides.
  static String ocrKey(String input) {
    final buffer = StringBuffer();
    for (final char in normalize(input).split('')) {
      buffer.write(_ocrFold[char] ?? char);
    }
    return buffer.toString();
  }

  /// A number-like token: digits mixed with letters that look like digits,
  /// not glued to other letters ("1O5.OOO", "24/10/2O26").
  static final RegExp _numberLike = RegExp(
    r'(?<![A-Za-z])[0-9OoIl|][0-9OoIl|.,/:\-]*[0-9OoIl|](?![A-Za-z])',
  );

  /// Replaces O/o with 0 and I/l/| with 1 inside number-like tokens that
  /// already contain at least two real digits, e.g. "139.5OO" → "139.500".
  ///
  /// Words ("LOTTE"), short codes ("A2", "1L") and plain text are untouched.
  static String repairDigits(String input) =>
      input.replaceAllMapped(_numberLike, (match) {
        final token = match[0]!;
        final digits = token.codeUnits.where((c) => c >= 0x30 && c <= 0x39);
        if (digits.length < 2) return token;
        return token
            .replaceAll(RegExp('[Oo]'), '0')
            .replaceAll(RegExp('[Il|]'), '1');
      });
}
