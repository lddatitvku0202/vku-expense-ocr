import 'package:flutter/foundation.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/models/field_confidence.dart';

/// Result of parsing one receipt (FR-3.6).
///
/// Every field is nullable (W7 s12): the parser leaves a field `null` rather
/// than guessing, and the user completes it on the Review screen. Each field
/// carries its own [FieldConfidence].
@immutable
class ParsedReceipt {
  const ParsedReceipt({
    this.merchant,
    this.total,
    this.date,
    this.suggestedCategory,
    required this.rawText,
    required this.merchantConfidence,
    required this.totalConfidence,
    required this.dateConfidence,
    required this.categoryConfidence,
  }) : assert(
         (merchant == null) == (merchantConfidence == FieldConfidence.missing),
         'merchantConfidence must be missing exactly when merchant is null',
       ),
       assert(
         (total == null) == (totalConfidence == FieldConfidence.missing),
         'totalConfidence must be missing exactly when total is null',
       ),
       assert(
         (date == null) == (dateConfidence == FieldConfidence.missing),
         'dateConfidence must be missing exactly when date is null',
       ),
       assert(
         (suggestedCategory == null) ==
             (categoryConfidence == FieldConfidence.missing),
         'categoryConfidence must be missing exactly when category is null',
       ),
       assert(total == null || total > 0, 'total must be positive');

  /// A receipt where nothing could be extracted, e.g. a blank photo.
  const ParsedReceipt.empty({this.rawText = ''})
    : merchant = null,
      total = null,
      date = null,
      suggestedCategory = null,
      merchantConfidence = FieldConfidence.missing,
      totalConfidence = FieldConfidence.missing,
      dateConfidence = FieldConfidence.missing,
      categoryConfidence = FieldConfidence.missing;

  final String? merchant;

  /// Amount to pay in dong.
  final int? total;
  final DateTime? date;
  final ExpenseCategory? suggestedCategory;

  /// Full OCR text, one logical row per line.
  final String rawText;

  final FieldConfidence merchantConfidence;
  final FieldConfidence totalConfidence;
  final FieldConfidence dateConfidence;
  final FieldConfidence categoryConfidence;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParsedReceipt &&
          other.merchant == merchant &&
          other.total == total &&
          other.date == date &&
          other.suggestedCategory == suggestedCategory &&
          other.rawText == rawText &&
          other.merchantConfidence == merchantConfidence &&
          other.totalConfidence == totalConfidence &&
          other.dateConfidence == dateConfidence &&
          other.categoryConfidence == categoryConfidence;

  @override
  int get hashCode => Object.hash(
    merchant,
    total,
    date,
    suggestedCategory,
    rawText,
    merchantConfidence,
    totalConfidence,
    dateConfidence,
    categoryConfidence,
  );

  @override
  String toString() =>
      'ParsedReceipt(merchant: $merchant [${merchantConfidence.name}], '
      'total: $total [${totalConfidence.name}], '
      'date: $date [${dateConfidence.name}], '
      'category: ${suggestedCategory?.name} [${categoryConfidence.name}])';
}
