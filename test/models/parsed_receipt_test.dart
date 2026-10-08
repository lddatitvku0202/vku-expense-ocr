import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/models/field_confidence.dart';
import 'package:vku_expense_ocr/models/ocr_line.dart';
import 'package:vku_expense_ocr/models/parsed_receipt.dart';

void main() {
  group('ParsedReceipt', () {
    test('empty() marks every field as missing', () {
      const receipt = ParsedReceipt.empty(rawText: '???');
      expect(receipt.merchant, isNull);
      expect(receipt.total, isNull);
      expect(receipt.date, isNull);
      expect(receipt.suggestedCategory, isNull);
      expect(receipt.rawText, '???');
      expect(receipt.merchantConfidence, FieldConfidence.missing);
      expect(receipt.totalConfidence, FieldConfidence.missing);
      expect(receipt.dateConfidence, FieldConfidence.missing);
      expect(receipt.categoryConfidence, FieldConfidence.missing);
    });

    test('keeps per-field confidence', () {
      final receipt = ParsedReceipt(
        merchant: 'CIRCLE K',
        total: 45000,
        date: DateTime(2026, 10, 2),
        suggestedCategory: ExpenseCategory.food,
        rawText: 'CIRCLE K\nTOTAL 45,000',
        merchantConfidence: FieldConfidence.high,
        totalConfidence: FieldConfidence.low,
        dateConfidence: FieldConfidence.high,
        categoryConfidence: FieldConfidence.low,
      );
      expect(receipt.totalConfidence.needsReview, isTrue);
      expect(receipt.merchantConfidence.needsReview, isFalse);
    });

    test('rejects a value whose confidence says missing', () {
      expect(
        () => ParsedReceipt(
          total: 1000,
          rawText: '',
          merchantConfidence: FieldConfidence.missing,
          totalConfidence: FieldConfidence.missing,
          dateConfidence: FieldConfidence.missing,
          categoryConfidence: FieldConfidence.missing,
        ),
        throwsAssertionError,
      );
    });

    test('rejects a non-positive total', () {
      expect(
        () => ParsedReceipt(
          total: 0,
          rawText: '',
          merchantConfidence: FieldConfidence.missing,
          totalConfidence: FieldConfidence.low,
          dateConfidence: FieldConfidence.missing,
          categoryConfidence: FieldConfidence.missing,
        ),
        throwsAssertionError,
      );
    });
  });

  group('FieldConfidence.needsReview', () {
    test('is true for low and missing only', () {
      expect(FieldConfidence.high.needsReview, isFalse);
      expect(FieldConfidence.low.needsReview, isTrue);
      expect(FieldConfidence.missing.needsReview, isTrue);
    });
  });

  group('OcrLine', () {
    test('compares by text and bounding box', () {
      const a = OcrLine(text: 'TOTAL', boundingBox: Rect.fromLTWH(1, 2, 3, 4));
      const b = OcrLine(text: 'TOTAL', boundingBox: Rect.fromLTWH(1, 2, 3, 4));
      const c = OcrLine(text: 'TOTAL', boundingBox: Rect.fromLTWH(1, 2, 3, 5));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}
