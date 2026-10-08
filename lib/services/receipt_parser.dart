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
  (DateTime date, FieldConfidence confidence)? extractDate(List<String> rows) =>
      null;

  /// Shop name from the header rows (FR-3.4).
  (String merchant, FieldConfidence confidence)? extractMerchant(
    List<String> rows,
  ) => null;

  /// Category guessed from the shop name or the receipt content (FR-3.5).
  (ExpenseCategory category, FieldConfidence confidence)? suggestCategory({
    String? merchant,
    required List<String> rows,
  }) => null;
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
