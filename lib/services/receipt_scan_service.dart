import 'dart:developer' as developer;
import 'dart:isolate';

import 'package:meta/meta.dart';
import 'package:vku_expense_ocr/models/parsed_receipt.dart';
import 'package:vku_expense_ocr/services/ocr_service.dart';
import 'package:vku_expense_ocr/services/receipt_parser.dart';
import 'package:vku_expense_ocr/services/row_grouper.dart';

/// Outcome of scanning one receipt photo.
@immutable
class ScanResult {
  const ScanResult({
    required this.imagePath,
    required this.receipt,
    required this.rows,
    required this.ocrDuration,
    this.error,
  });

  final String imagePath;

  /// Parsed fields; every field is missing when recognition failed.
  final ParsedReceipt receipt;

  /// Logical rows after grouping, top to bottom (also in `receipt.rawText`).
  final List<String> rows;

  /// Time spent in OCR (FR-2.4); zero when recognition failed.
  final Duration ocrDuration;

  /// Vietnamese message for the user when the image could not be read.
  final String? error;

  bool get failed => error != null;
}

/// The receipt pipeline: image → OCR → row grouping → parsing (W8 s41).
///
/// Never throws for a bad image: a broken or unreadable file yields a
/// [ScanResult] whose receipt has every field missing plus an [error], so
/// the Review screen can still open for manual entry.
class ReceiptScanService {
  ReceiptScanService({
    required this._ocr,
    this._grouper = const RowGrouper(),
    this._parser = const ReceiptParser(),
  });

  final OcrService _ocr;
  final RowGrouper _grouper;
  final ReceiptParser _parser;

  Future<ScanResult> scan(String imagePath) async {
    final OcrResult ocr;
    try {
      ocr = await _ocr.recognize(imagePath);
    } on Exception catch (error) {
      developer.log(
        'OCR failed for $imagePath',
        name: 'vku_expense_ocr.scan',
        error: error,
      );
      return ScanResult(
        imagePath: imagePath,
        receipt: const ParsedReceipt.empty(),
        rows: const [],
        ocrDuration: Duration.zero,
        error: 'Không đọc được ảnh hóa đơn. Hãy chụp lại hoặc nhập tay.',
      );
    }

    // Grouping and regex parsing run on a background isolate (NFR-2,
    // W7 s30). Copy the fields into locals so the closure does not capture
    // `this` (and with it the native recognizer).
    final grouper = _grouper;
    final parser = _parser;
    final lines = ocr.lines;
    final (rows, receipt) = await Isolate.run(() {
      final rows = [for (final row in grouper.group(lines)) row.text];
      return (rows, parser.parse(rows));
    });

    return ScanResult(
      imagePath: imagePath,
      receipt: receipt,
      rows: rows,
      ocrDuration: ocr.elapsed,
    );
  }
}
