import 'dart:math' as math;
import 'dart:ui' show Offset, Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/models/ocr_line.dart';
import 'package:vku_expense_ocr/services/row_grouper.dart';

/// A line laid out upright at (left, top), then rotated by [degrees] around
/// the origin, the way ML Kit reports text in a tilted photo: corner points
/// clockwise from the text's top-left, bounding box = axis-aligned hull.
OcrLine rotatedLine(
  String text,
  double left,
  double top,
  double degrees, {
  double width = 100,
  double height = 20,
}) {
  final angle = degrees * math.pi / 180;
  Offset rotate(Offset p) => Offset(
    p.dx * math.cos(angle) - p.dy * math.sin(angle),
    p.dx * math.sin(angle) + p.dy * math.cos(angle),
  );
  final corners = [
    Offset(left, top),
    Offset(left + width, top),
    Offset(left + width, top + height),
    Offset(left, top + height),
  ].map(rotate).toList();
  final xs = corners.map((c) => c.dx);
  final ys = corners.map((c) => c.dy);
  return OcrLine(
    text: text,
    boundingBox: Rect.fromLTRB(
      xs.reduce(math.min),
      ys.reduce(math.min),
      xs.reduce(math.max),
      ys.reduce(math.max),
    ),
    cornerPoints: corners,
  );
}

/// A small receipt: labels in a left block, amounts in a right block,
/// returned column by column like ML Kit text blocks.
List<OcrLine> tiltedReceipt(double degrees) => [
  rotatedLine('CỬA HÀNG AN BÌNH', 16, 40, degrees, width: 220),
  rotatedLine('Tổng tiền hàng', 16, 72, degrees, width: 150),
  rotatedLine('Giảm giá', 16, 104, degrees, width: 90),
  rotatedLine('Tổng thanh toán', 16, 136, degrees, width: 160),
  rotatedLine('71.500', 300, 72, degrees, width: 70),
  rotatedLine('-1.500', 300, 104, degrees, width: 70),
  rotatedLine('70.000', 300, 136, degrees, width: 70),
];

const expectedRows = [
  'CỬA HÀNG AN BÌNH',
  'Tổng tiền hàng 71.500',
  'Giảm giá -1.500',
  'Tổng thanh toán 70.000',
];

double degreesOf(double radians) => radians * 180 / math.pi;

void main() {
  const grouper = RowGrouper();
  List<String> texts(List<OcrLine> lines) =>
      grouper.group(lines).map((row) => row.text).toList();

  group('RowGrouper.estimateSkew', () {
    test('is zero when no line has corner points', () {
      final lines = [
        const OcrLine(text: 'A', boundingBox: Rect.fromLTWH(0, 0, 50, 20)),
      ];
      expect(RowGrouper.estimateSkew(lines), 0);
      expect(RowGrouper.estimateSkew(const []), 0);
    });

    for (final degrees in [8.0, -12.0, 90.0, 180.0]) {
      test('recovers a $degrees° tilt from the corner points', () {
        final skew = degreesOf(RowGrouper.estimateSkew(tiltedReceipt(degrees)));
        // 180° and -180° are the same orientation.
        final difference = ((skew - degrees + 540) % 360) - 180;
        expect(difference.abs(), lessThan(0.5));
      });
    }

    test('ignores long background text at another angle', () {
      // A shopping bag behind the receipt: two long lines printed sideways.
      final lines = [
        ...tiltedReceipt(8),
        rotatedLine('VINMART VINMART', 500, -300, 90, width: 420, height: 60),
        rotatedLine('VINMART', 600, -300, 90, width: 380, height: 60),
      ];
      expect(degreesOf(RowGrouper.estimateSkew(lines)), closeTo(8, 1));
      final rows = grouper.group(lines).map((r) => r.text).toList();
      for (final row in expectedRows) {
        expect(rows, contains(row));
      }
    });

    test('long lines weigh more than short noisy ones', () {
      final lines = [
        rotatedLine('Tổng thanh toán 70.000', 16, 40, 5, width: 300),
        rotatedLine('x', 16, 80, 40, width: 8),
      ];
      expect(degreesOf(RowGrouper.estimateSkew(lines)), closeTo(5, 1.5));
    });
  });

  group('grouping a tilted or rotated photo (deskew)', () {
    for (final degrees in [8.0, -12.0, 90.0, 180.0]) {
      test('rebuilds the rows of a receipt rotated by $degrees°', () {
        expect(texts(tiltedReceipt(degrees)), expectedRows);
      });
    }

    test('lines without corner points still group as before', () {
      final lines = [
        const OcrLine(
          text: 'Tổng cộng',
          boundingBox: Rect.fromLTWH(10, 100, 100, 20),
        ),
        const OcrLine(
          text: '84.000',
          boundingBox: Rect.fromLTWH(320, 104, 60, 20),
        ),
      ];
      expect(texts(lines), ['Tổng cộng 84.000']);
    });
  });

  test('OcrLine compares corner points too', () {
    final a = rotatedLine('A', 0, 0, 10);
    final b = rotatedLine('A', 0, 0, 10);
    final c = rotatedLine('A', 0, 0, 11);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(c));
  });
}
