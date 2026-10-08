import 'dart:ui' show Rect;

import 'package:meta/meta.dart';
import 'package:vku_expense_ocr/models/ocr_line.dart';

/// One visual row of a receipt: OCR lines at the same height, sorted left
/// to right (FR-2.3). Built by `RowGrouper`.
@immutable
class ReceiptRow {
  ReceiptRow(List<OcrLine> lines)
    : assert(lines.isNotEmpty, 'a row needs at least one line'),
      lines = List.unmodifiable(lines),
      text = lines
          .map((line) => line.text.trim())
          .where((text) => text.isNotEmpty)
          .join(' ');

  /// Lines of the row, left to right.
  final List<OcrLine> lines;

  /// Line texts joined by single spaces, e.g. "Tổng cộng 84.000".
  final String text;

  /// Smallest rectangle containing every line of the row.
  Rect get bounds => lines
      .map((line) => line.boundingBox)
      .reduce((a, b) => a.expandToInclude(b));

  @override
  String toString() => 'ReceiptRow("$text")';
}
