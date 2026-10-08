import 'dart:math' as math;

import 'package:vku_expense_ocr/core/text_normalizer.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/models/field_confidence.dart';
import 'package:vku_expense_ocr/models/parsed_receipt.dart';
import 'package:vku_expense_ocr/services/receipt_keywords.dart';

/// Heuristic regex parser for Vietnamese receipts (FR-3).
///
/// Works on the logical rows produced by `RowGrouper` (one string per
/// visual row, top to bottom). Pure Dart: no Flutter and no ML Kit, so
/// every rule is covered by plain unit tests.
///
/// Matching always uses normalized text (no accents, lower case, OCR
/// look-alikes folded) while returned values keep the original spelling.
class ReceiptParser {
  const ReceiptParser();

  /// Parses every field of a receipt (FR-3.6).
  ParsedReceipt parse(List<String> rows) {
    final lines = [
      for (final row in rows)
        if (row.trim().isNotEmpty) row.trim(),
    ];
    final total = extractTotal(lines);
    final date = extractDate(lines);
    final merchant = extractMerchant(lines);
    final category = suggestCategory(merchant: merchant?.$1, rows: lines);
    return ParsedReceipt(
      merchant: merchant?.$1,
      total: total?.$1,
      date: date?.$1,
      suggestedCategory: category?.$1,
      rawText: lines.join('\n'),
      merchantConfidence: merchant?.$2 ?? FieldConfidence.missing,
      totalConfidence: total?.$2 ?? FieldConfidence.missing,
      dateConfidence: date?.$2 ?? FieldConfidence.missing,
      categoryConfidence: category?.$2 ?? FieldConfidence.missing,
    );
  }

  /// Amount paid, in dong (FR-3.2).
  ///
  /// 1. Rows are classified by their first keyword: final total
  ///    ("tổng thanh toán") > total ("tổng cộng") > subtotal ("tổng tiền
  ///    hàng"). Cash tendered, change, discounts and taxes never count.
  /// 2. The best class wins; among equals the lowest row wins. A label
  ///    without an amount takes the amount-only row right below it.
  /// 3. Without any keyword, the largest valid amount is used with low
  ///    confidence.
  (int amount, FieldConfidence confidence)? extractTotal(List<String> rows) {
    final scans = [for (final row in rows) _RowScan.of(row)];
    ({int tier, int amount})? best;
    for (var i = 0; i < scans.length; i++) {
      final tier = scans[i].kind?.tier ?? 0;
      if (tier == 0) continue;
      var amounts = scans[i].amounts;
      if (amounts.isEmpty && i + 1 < scans.length && scans[i + 1].amountOnly) {
        amounts = scans[i + 1].amounts;
      }
      if (amounts.isEmpty) continue;
      if (best == null || tier >= best.tier) {
        best = (tier: tier, amount: amounts.reduce(math.max));
      }
    }
    if (best != null) {
      final subtotalOnly = best.tier == _RowKind.subtotal.tier;
      return (
        best.amount,
        subtotalOnly ? FieldConfidence.low : FieldConfidence.high,
      );
    }

    final fallback = [
      for (final scan in scans)
        if (scan.kind != _RowKind.tender && scan.kind != _RowKind.notTotal)
          ...scan.amounts,
    ];
    if (fallback.isEmpty) return null;
    return (fallback.reduce(math.max), FieldConfidence.low);
  }

  /// Transaction date (FR-3.3).
  ///
  /// Accepts DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY and DD/MM/YY, with or
  /// without a time; two-digit years mean 20YY and impossible dates such as
  /// 45/13/2026 or 31/04/2026 are rejected. A date on a row labelled
  /// "Ngày", "Date" or "Thời gian" wins over unlabelled ones (e.g. a cinema
  /// showtime); otherwise the first date is used, with low confidence when
  /// the receipt shows several different dates.
  (DateTime date, FieldConfidence confidence)? extractDate(List<String> rows) {
    final found = <({DateTime date, bool labelled})>[];
    for (final row in rows) {
      final norm = TextNormalizer.normalize(TextNormalizer.repairDigits(row));
      final labelled = _dateLabel.hasMatch(TextNormalizer.ocrKey(norm));
      for (final match in _datePattern.allMatches(norm)) {
        if (_validDate(match) case final date?) {
          found.add((date: date, labelled: labelled));
        }
      }
    }
    if (found.isEmpty) return null;

    for (final candidate in found) {
      if (candidate.labelled) return (candidate.date, FieldConfidence.high);
    }
    final distinct = found.map((candidate) => candidate.date).toSet();
    return (
      found.first.date,
      distinct.length == 1 ? FieldConfidence.high : FieldConfidence.low,
    );
  }

  /// Builds the date of a [_datePattern] match, or `null` if it does not
  /// exist. `DateTime(2026, 4, 31)` silently becomes 1 May, so the day and
  /// month are compared after construction.
  static DateTime? _validDate(RegExpMatch match) {
    final day = int.parse(match[1]!);
    final month = int.parse(match[3]!);
    final yearText = match[4]!;
    final year = int.parse(yearText) + (yearText.length == 2 ? 2000 : 0);
    if (year < 2000 || year > 2099 || month < 1 || month > 12 || day < 1) {
      return null;
    }
    final date = DateTime(year, month, day);
    return date.month == month && date.day == day ? date : null;
  }

  /// Shop name from the header rows (FR-3.4).
  ///
  /// Looks at the first five non-empty rows, drops rows that are not a
  /// name (contact keywords, "label: value", street addresses, prices,
  /// mostly digits) and returns the row with the most letters, keeping its
  /// original spelling; ties go to the upper row. A legal entity line
  /// ("CÔNG TY TNHH …") is only used, with low confidence, when nothing
  /// else qualifies. Returns `null` when no row looks like a name.
  (String merchant, FieldConfidence confidence)? extractMerchant(
    List<String> rows,
  ) {
    String? name;
    var nameLetters = 0;
    String? company;
    var companyLetters = 0;
    final header = rows
        .map((row) => row.trim())
        .where((row) => row.isNotEmpty)
        .take(_merchantRows);
    for (final row in header) {
      final letters = _unicodeLetter.allMatches(row).length;
      if (letters < _minNameLetters || _isNotName(row, letters)) continue;
      if (_companyLine.hasMatch(TextNormalizer.ocrKey(row))) {
        if (letters > companyLetters) {
          (company, companyLetters) = (row, letters);
        }
      } else if (letters > nameLetters) {
        (name, nameLetters) = (row, letters);
      }
    }
    if (name != null) return (name, FieldConfidence.high);
    if (company != null) return (company, FieldConfidence.low);
    return null;
  }

  static bool _isNotName(String row, int letters) {
    if (row.contains(':')) return true; // "Hotline: …", "Ngày: …"
    if (_digit.allMatches(row).length > letters) return true;
    final norm = TextNormalizer.normalize(row);
    return _notNameKeyword.hasMatch(TextNormalizer.ocrKey(norm)) ||
        _houseNumber.hasMatch(norm) ||
        _price.hasMatch(norm);
  }

  /// Category guessed from the shop name or the receipt content (FR-3.5).
  ///
  /// A keyword in the merchant name ("Highlands", "Nhà sách", "Grab")
  /// gives high confidence; the longest matching keyword decides. Otherwise
  /// every row votes for the categories whose keywords it contains and a
  /// clear winner gets low confidence. A tie or no match returns `null`, so
  /// the user must choose on the Review screen.
  (ExpenseCategory category, FieldConfidence confidence)? suggestCategory({
    String? merchant,
    required List<String> rows,
  }) {
    final byName = merchant == null
        ? null
        : _categoryOf(TextNormalizer.ocrKey(merchant));
    return switch ((byName, _categoryFromContent(rows))) {
      (final ExpenseCategory category, _) => (category, FieldConfidence.high),
      (null, final ExpenseCategory category) => (category, FieldConfidence.low),
      (null, null) => null,
    };
  }

  /// Category of the longest keyword found in [key], if any.
  static ExpenseCategory? _categoryOf(String key) {
    ExpenseCategory? best;
    var bestLength = 0;
    for (final category in ExpenseCategory.values) {
      for (final match in _categoryPattern(category).allMatches(key)) {
        final length = match.end - match.start;
        if (length > bestLength) {
          best = category;
          bestLength = length;
        }
      }
    }
    return best;
  }

  /// Category named by the most rows; `null` on a tie or without votes.
  static ExpenseCategory? _categoryFromContent(List<String> rows) {
    final votes = {for (final category in ExpenseCategory.values) category: 0};
    for (final row in rows) {
      final key = TextNormalizer.ocrKey(row);
      for (final category in ExpenseCategory.values) {
        if (_categoryPattern(category).hasMatch(key)) {
          votes.update(category, (count) => count + 1);
        }
      }
    }
    final ranked = votes.entries.where((entry) => entry.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return switch (ranked) {
      [] => null,
      [final only] => only.key,
      [final first, final second, ...] when first.value > second.value =>
        first.key,
      _ => null,
    };
  }

  /// Exhaustive switch: adding a sixth category without a keyword list
  /// does not compile.
  static RegExp _categoryPattern(ExpenseCategory category) =>
      switch (category) {
        ExpenseCategory.food => _foodPattern,
        ExpenseCategory.study => _studyPattern,
        ExpenseCategory.travel => _travelPattern,
        ExpenseCategory.gear => _gearPattern,
        ExpenseCategory.entertainment => _entertainmentPattern,
      };
}

/// What a row is about, decided by its first keyword.
enum _RowKind {
  finalTotal(3),
  total(2),
  subtotal(1),
  tender(0),
  notTotal(0),
  contact(0);

  const _RowKind(this.tier);

  /// Priority as a total candidate; 0 means never a total.
  final int tier;
}

/// Builds a keyword regex: alternatives folded like OCR text, longest
/// first (so "tong tien hang" wins over "tong tien" at the same position)
/// and bounded so "tel" does not match inside "hotel".
RegExp _keywordPattern(List<String> keywords) {
  final folded = keywords.map(TextNormalizer.ocrKey).toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  final body = folded.map(RegExp.escape).join('|');
  return RegExp('(?<![a-z0-9])(?:$body)(?![a-z0-9])');
}

final List<(RegExp, _RowKind)> _kindPatterns = [
  (_keywordPattern(finalTotalKeywords), _RowKind.finalTotal),
  (_keywordPattern(totalKeywords), _RowKind.total),
  // "Cộng: 110.000đ" on hand-written bills; only at the start of a row.
  (RegExp('^cong(?![a-z0-9])'), _RowKind.total),
  (_keywordPattern(subtotalKeywords), _RowKind.subtotal),
  (_keywordPattern(tenderKeywords), _RowKind.tender),
  (_keywordPattern(notTotalKeywords), _RowKind.notTotal),
  (_keywordPattern(contactKeywords), _RowKind.contact),
];

final RegExp _contactPattern = _keywordPattern(contactKeywords);

/// Number run after a contact label: "ĐT: (0234) 3588 555".
final RegExp _contactNumber = RegExp(r'[\s:.#/]*[(+]?\d[\d\s.,()+\-/]*');

/// Dates and times are blanked before looking for amounts, so "2026" in
/// "14/09/2026" or "18:42" are never read as money.
final RegExp _dateLike = RegExp(
  r'(?<!\d)\d{1,2}\s*([/.\-])\s*\d{1,2}\s*\1\s*(?:\d{4}|\d{2})(?!\d)',
);
final RegExp _timeLike = RegExp(
  r'(?<!\d)\d{1,2}\s*[:h]\s*\d{2}(?:\s*:\s*\d{2})?(?!\d)',
);

/// Day, separator, month, the same separator again, 4- or 2-digit year.
/// The back-reference `\2` rejects mixed separators such as "14/09-2026".
final RegExp _datePattern = RegExp(
  r'(?<!\d)(\d{1,2})\s*([/.\-])\s*(\d{1,2})\s*\2\s*(\d{4}|\d{2})(?!\d)',
);

/// Rows whose date is the transaction date.
final RegExp _dateLabel = _keywordPattern([
  'ngay',
  'date',
  'thoi gian',
  'time',
]);

/// Category keyword patterns. A dot before a keyword also counts as part of
/// a word, so "com" in "www.fahasa.com" is not "cơm".
RegExp _categoryKeywords(List<String> keywords) {
  final folded = keywords.map(TextNormalizer.ocrKey).toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  final body = folded.map(RegExp.escape).join('|');
  return RegExp('(?<![a-z0-9.])(?:$body)(?![a-z0-9])');
}

final RegExp _foodPattern = _categoryKeywords(foodKeywords);
final RegExp _studyPattern = _categoryKeywords(studyKeywords);
final RegExp _travelPattern = _categoryKeywords(travelKeywords);
final RegExp _gearPattern = _categoryKeywords(gearKeywords);
final RegExp _entertainmentPattern = _categoryKeywords(entertainmentKeywords);

/// FR-3.4: the shop name is searched in the first five rows only.
const int _merchantRows = 5;

/// Fewer letters than this is not enough to trust a row as a name.
const int _minNameLetters = 3;

final RegExp _unicodeLetter = RegExp(r'\p{L}', unicode: true);
final RegExp _digit = RegExp(r'\d');
final RegExp _notNameKeyword = _keywordPattern(notNameKeywords);
final RegExp _companyLine = _keywordPattern(companyKeywords);

/// A street address: house number followed by a word ("50A Hùng Vương").
/// Not "GS25" (digits glued to letters) nor "Phở 24" (no word after).
final RegExp _houseNumber = RegExp(r'(?<![a-z0-9])\d+[a-z]?\s+[a-z]');

/// A price with thousands separators or a currency mark: an item row.
final RegExp _price = RegExp(
  r'(?<![a-z0-9.,])(?:\d{1,3}(?:[.,]\d{3})+(?![.,]?\d)|\d{4,9}\s*(?:d|vnd|dong|₫)(?![a-z]))',
);

/// "2 x 15.000", "2,5 giờ x 180.000": the amount after "x" is a unit price.
final RegExp _unitPrice = RegExp(
  r'(?<![a-z0-9])\d+(?:[.,]\d+)?\s*(?:[a-z]+\s*)?[x×*]\s*'
  r'(\d{1,3}(?:[.,]\d{3})+|\d{4,9})',
);

/// Money: "150.000", "150,000", "150000", optionally followed by
/// "đ"/"vnd"/"dong" (already normalized) or "₫". Not part of a code such
/// as "M331", "A-2041", "#3021" or "3068B".
final RegExp _amount = RegExp(
  r'(?<![a-z0-9.,/:#\-])(\d{1,3}(?:[.,]\d{3})+|\d{4,9})(?![.,]?\d)'
  r'(?=(?:d|vnd|dong)?(?![a-z0-9]))',
);
final RegExp _currencyWord = RegExp('(?<![a-z])(?:vnd|dong|d)(?![a-z])');
final RegExp _separators = RegExp('[.,]');
final RegExp _letter = RegExp('[a-z]');

const int _minAmount = 1000;
const int _maxAmount = 999999999;

/// One row prepared for total extraction.
class _RowScan {
  _RowScan(this.kind, this.amounts, {required this.amountOnly});

  factory _RowScan.of(String row) {
    final norm = TextNormalizer.normalize(TextNormalizer.repairDigits(row));
    final key = TextNormalizer.ocrKey(norm);
    final chars = norm.split('');
    void blank(int start, int end) {
      for (var i = start; i < end; i++) {
        chars[i] = ' ';
      }
    }

    for (final label in _contactPattern.allMatches(key)) {
      final number = _contactNumber.matchAsPrefix(norm, label.end);
      if (number != null) blank(label.end, number.end);
    }
    for (final match in [
      ..._dateLike.allMatches(norm),
      ..._timeLike.allMatches(norm),
    ]) {
      blank(match.start, match.end);
    }
    for (final match in _unitPrice.allMatches(norm)) {
      blank(match.end - match[1]!.length, match.end);
    }

    final cleaned = chars.join();
    final amounts = <int>[];
    for (final match in _amount.allMatches(cleaned)) {
      final before = cleaned.substring(0, match.start).trimRight();
      if (before.endsWith('-') || before.endsWith('(')) continue;
      final digits = match[1]!;
      if (digits.startsWith('0')) continue;
      final value = int.parse(digits.replaceAll(_separators, ''));
      if (value >= _minAmount && value <= _maxAmount) amounts.add(value);
    }
    final rest = cleaned
        .replaceAll(_amount, ' ')
        .replaceAll(_currencyWord, ' ');
    return _RowScan(
      _classify(key),
      amounts,
      amountOnly: amounts.isNotEmpty && !_letter.hasMatch(rest),
    );
  }

  /// Kind of the row, or `null` when it has no keyword (e.g. an item).
  final _RowKind? kind;

  /// Valid amounts on the row after all exclusions.
  final List<int> amounts;

  /// True for a row that is nothing but an amount, like "84.000".
  final bool amountOnly;

  /// The keyword that appears first decides; at the same position the
  /// longer keyword wins ("tong chiet khau" over "tong").
  static _RowKind? _classify(String key) {
    _RowKind? kind;
    var index = key.length + 1;
    var length = 0;
    for (final (pattern, patternKind) in _kindPatterns) {
      final match = pattern.firstMatch(key);
      if (match == null) continue;
      final matchLength = match.end - match.start;
      if (match.start < index ||
          (match.start == index && matchLength > length)) {
        kind = patternKind;
        index = match.start;
        length = matchLength;
      }
    }
    return kind;
  }
}
