import 'package:meta/meta.dart';
import 'package:vku_expense_ocr/core/date_ranges.dart';
import 'package:vku_expense_ocr/models/expense.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/models/field_confidence.dart';
import 'package:vku_expense_ocr/models/parsed_receipt.dart';
import 'package:vku_expense_ocr/services/receipt_scan_service.dart';

/// The three ways into the Review screen (FR-4.9).
enum ReviewMode {
  /// Fields parsed from a receipt photo, to be checked.
  scan,

  /// Empty form, no photo.
  manual,

  /// A saved expense (`/expense/:id`).
  edit;

  String get title => switch (this) {
    scan => 'Xác nhận hóa đơn',
    manual => 'Thêm giao dịch thủ công',
    edit => 'Sửa giao dịch',
  };
}

/// What the Review form starts with, whatever the mode.
@immutable
class ReviewDraft {
  const ReviewDraft({
    required this.mode,
    this.merchant = '',
    this.amount,
    this.date,
    this.category,
    this.merchantConfidence = FieldConfidence.high,
    this.amountConfidence = FieldConfidence.high,
    this.dateConfidence = FieldConfidence.high,
    this.categoryConfidence = FieldConfidence.high,
    this.imagePath,
    this.ocrRows,
    this.ocrDuration,
    this.scanError,
    this.rawText,
    this.existing,
  });

  /// From the camera or gallery. A missing date is pre-filled with
  /// [today] (FR-3.3) but stays marked as missing.
  factory ReviewDraft.fromScan(ScanResult scan, {required DateTime today}) =>
      ReviewDraft._fromReceipt(
        scan.receipt,
        today: today,
        imagePath: scan.imagePath,
        rows: scan.rows,
        ocrDuration: scan.failed ? null : scan.ocrDuration,
        scanError: scan.error,
      );

  /// From a parsed receipt alone (no photo).
  factory ReviewDraft.fromReceipt(
    ParsedReceipt receipt, {
    required DateTime today,
  }) => ReviewDraft._fromReceipt(
    receipt,
    today: today,
    rows: _lines(receipt.rawText),
  );

  factory ReviewDraft._fromReceipt(
    ParsedReceipt receipt, {
    required DateTime today,
    required List<String> rows,
    String? imagePath,
    Duration? ocrDuration,
    String? scanError,
  }) => ReviewDraft(
    mode: ReviewMode.scan,
    merchant: receipt.merchant ?? '',
    amount: receipt.total,
    date: receipt.date ?? DateRanges.startOfDay(today),
    category: receipt.suggestedCategory,
    merchantConfidence: receipt.merchantConfidence,
    amountConfidence: receipt.totalConfidence,
    dateConfidence: receipt.dateConfidence,
    categoryConfidence: receipt.categoryConfidence,
    imagePath: imagePath,
    ocrRows: rows,
    ocrDuration: ocrDuration,
    scanError: scanError,
    rawText: receipt.rawText.isEmpty ? null : receipt.rawText,
  );

  /// Manual entry: empty fields, today's date, nothing to flag.
  factory ReviewDraft.manual({required DateTime today}) =>
      ReviewDraft(mode: ReviewMode.manual, date: DateRanges.startOfDay(today));

  /// Editing a saved expense: its values, its photo and stored OCR text.
  factory ReviewDraft.fromExpense(Expense expense) => ReviewDraft(
    mode: ReviewMode.edit,
    merchant: expense.merchant,
    amount: expense.amount,
    date: expense.date,
    category: expense.category,
    imagePath: expense.imagePath,
    ocrRows: switch (expense.rawText) {
      final String text when text.trim().isNotEmpty => _lines(text),
      _ => null,
    },
    rawText: expense.rawText,
    existing: expense,
  );

  final ReviewMode mode;
  final String merchant;
  final int? amount;
  final DateTime? date;
  final ExpenseCategory? category;
  final FieldConfidence merchantConfidence;
  final FieldConfidence amountConfidence;
  final FieldConfidence dateConfidence;
  final FieldConfidence categoryConfidence;

  /// Receipt photo: a temporary crop (scan) or the stored copy (edit).
  final String? imagePath;

  /// Rows for "Xem văn bản OCR gốc"; `null` hides the section.
  final List<String>? ocrRows;
  final Duration? ocrDuration;

  /// Why the photo could not be read, shown above the form.
  final String? scanError;

  /// OCR text saved with the expense (`raw_text`).
  final String? rawText;

  /// The saved expense being edited.
  final Expense? existing;

  static List<String> _lines(String text) => [
    for (final line in text.split('\n'))
      if (line.trim().isNotEmpty) line,
  ];
}
