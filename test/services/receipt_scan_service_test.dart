import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/models/field_confidence.dart';
import 'package:vku_expense_ocr/models/ocr_line.dart';
import 'package:vku_expense_ocr/models/parsed_receipt.dart';
import 'package:vku_expense_ocr/services/receipt_scan_service.dart';

import '../support/fake_ocr_service.dart';
import '../support/receipt_fixture.dart';

void main() {
  test('runs OCR, groups rows and parses the receipt', () async {
    final ocr = FakeOcrService(
      lines: loadFixtureLines('coopmart_hue.txt'),
      elapsed: const Duration(milliseconds: 345),
    );
    final result = await ReceiptScanService(ocr: ocr).scan('/img/coop.jpg');

    expect(ocr.recognizedPaths, ['/img/coop.jpg']);
    expect(result.failed, isFalse);
    expect(result.imagePath, '/img/coop.jpg');
    expect(result.ocrDuration, const Duration(milliseconds: 345));
    expect(result.receipt.total, 245000);
    expect(result.receipt.totalConfidence, FieldConfidence.high);
    expect(result.receipt.merchant, 'CO.OPMART HUẾ');
    expect(result.receipt.date, DateTime(2026, 9, 14));
    expect(result.receipt.suggestedCategory, ExpenseCategory.food);
    // Label and amount from separate OCR blocks end up on one row.
    expect(result.rows, contains('Tổng thanh toán 245.000'));
    expect(result.receipt.rawText, result.rows.join('\n'));
  });

  test(
    'an image without text gives a receipt with every field missing',
    () async {
      final result = await ReceiptScanService(ocr: FakeOcrService())
          .scan('/img/blank.jpg');

      expect(result.failed, isFalse);
      expect(result.rows, isEmpty);
      expect(result.receipt, const ParsedReceipt.empty());
    },
  );

  test('unreadable OCR text never crashes the pipeline', () async {
    final noise = [
      const OcrLine(text: '~~~', boundingBox: Rect.fromLTWH(0, 0, 40, 20)),
      const OcrLine(text: '|||', boundingBox: Rect.fromLTWH(0, 40, 40, 20)),
    ];
    final result = await ReceiptScanService(ocr: FakeOcrService(lines: noise))
        .scan('/img/noise.jpg');

    expect(result.failed, isFalse);
    expect(result.receipt.total, isNull);
    expect(result.receipt.merchantConfidence, FieldConfidence.missing);
  });

  group('broken images', () {
    for (final error in <Exception>[
      PlatformException(code: 'InputImageConverterError'),
      const FileSystemException('Cannot open file', '/img/missing.jpg'),
    ]) {
      test(
        '${error.runtimeType} returns an empty receipt with a message',
        () async {
          final result = await ReceiptScanService(
            ocr: FakeOcrService(error: error),
          ).scan('/img/missing.jpg');

          expect(result.failed, isTrue);
          expect(result.error, isNotEmpty);
          expect(result.receipt, const ParsedReceipt.empty());
          expect(result.rows, isEmpty);
          expect(result.ocrDuration, Duration.zero);
        },
      );
    }
  });
}
