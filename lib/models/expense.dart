import 'package:flutter/foundation.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';

/// One saved transaction, mirroring a row of the `expenses` table (FR-5.1).
///
/// Immutable: every change produces a new object through [copyWith].
/// [amount] is an `int` number of dong because VND has no minor unit, so a
/// `double` (as in the slides) would only add rounding errors.
@immutable
class Expense {
  const Expense({
    this.id,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    this.imagePath,
    this.thumbPath,
    this.rawText,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Builds an expense from a database row produced by [toMap].
  factory Expense.fromMap(Map<String, Object?> map) => Expense(
    id: map[columnId] as int?,
    merchant: map[columnMerchant]! as String,
    amount: map[columnAmount]! as int,
    date: DateTime.fromMillisecondsSinceEpoch(map[columnDate]! as int),
    category: ExpenseCategory.fromDbValue(map[columnCategory]! as String),
    imagePath: map[columnImagePath] as String?,
    thumbPath: map[columnThumbPath] as String?,
    rawText: map[columnRawText] as String?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      map[columnCreatedAt]! as int,
    ),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(
      map[columnUpdatedAt]! as int,
    ),
  );

  static const String columnId = 'id';
  static const String columnMerchant = 'merchant';
  static const String columnAmount = 'amount';
  static const String columnDate = 'date';
  static const String columnCategory = 'category';
  static const String columnImagePath = 'image_path';
  static const String columnThumbPath = 'thumb_path';
  static const String columnRawText = 'raw_text';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  /// Database id; `null` until the expense has been inserted.
  final int? id;
  final String merchant;

  /// Amount in Vietnamese dong.
  final int amount;

  /// Transaction date shown to the user.
  final DateTime date;
  final ExpenseCategory category;

  /// Cropped receipt photo inside the app documents directory, if any.
  final String? imagePath;

  /// Small JPEG preview of [imagePath] used by list items.
  final String? thumbPath;

  /// OCR text the expense was parsed from, kept for the "raw text" view.
  final String? rawText;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Columns for sqflite. Dates are stored as epoch milliseconds, so values
  /// below one millisecond are dropped.
  Map<String, Object?> toMap() => {
    if (id != null) columnId: id,
    columnMerchant: merchant,
    columnAmount: amount,
    columnDate: date.millisecondsSinceEpoch,
    columnCategory: category.dbValue,
    columnImagePath: imagePath,
    columnThumbPath: thumbPath,
    columnRawText: rawText,
    columnCreatedAt: createdAt.millisecondsSinceEpoch,
    columnUpdatedAt: updatedAt.millisecondsSinceEpoch,
  };

  /// Returns a copy with the given fields replaced.
  ///
  /// Nullable fields take a [ValueGetter] so they can also be cleared:
  /// `copyWith(imagePath: () => null)` removes the image path, while omitting
  /// the argument keeps the current value.
  Expense copyWith({
    int? id,
    String? merchant,
    int? amount,
    DateTime? date,
    ExpenseCategory? category,
    ValueGetter<String?>? imagePath,
    ValueGetter<String?>? thumbPath,
    ValueGetter<String?>? rawText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Expense(
    id: id ?? this.id,
    merchant: merchant ?? this.merchant,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    category: category ?? this.category,
    imagePath: imagePath != null ? imagePath() : this.imagePath,
    thumbPath: thumbPath != null ? thumbPath() : this.thumbPath,
    rawText: rawText != null ? rawText() : this.rawText,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense &&
          other.id == id &&
          other.merchant == merchant &&
          other.amount == amount &&
          other.date == date &&
          other.category == category &&
          other.imagePath == imagePath &&
          other.thumbPath == thumbPath &&
          other.rawText == rawText &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    merchant,
    amount,
    date,
    category,
    imagePath,
    thumbPath,
    rawText,
    createdAt,
    updatedAt,
  );

  @override
  String toString() =>
      'Expense(id: $id, merchant: $merchant, amount: $amount, '
      'date: $date, category: ${category.name})';
}
