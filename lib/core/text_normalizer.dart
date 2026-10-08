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
}
