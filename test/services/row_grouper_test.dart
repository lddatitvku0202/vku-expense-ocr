import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/models/ocr_line.dart';
import 'package:vku_expense_ocr/services/row_grouper.dart';

OcrLine line(
  String text,
  double left,
  double top, {
  double width = 100,
  double height = 20,
}) => OcrLine(text: text, boundingBox: Rect.fromLTWH(left, top, width, height));

void main() {
  const grouper = RowGrouper();

  List<String> texts(List<OcrLine> lines, [RowGrouper g = grouper]) =>
      g.group(lines).map((row) => row.text).toList();

  test('empty input gives no rows', () {
    expect(grouper.group(const []), isEmpty);
  });

  test('joins a left label and a right amount from separate blocks', () {
    // ML Kit returns the label column first, then the amount column.
    final lines = [
      line('Tổng tiền hàng', 10, 100),
      line('Tổng thanh toán', 10, 160),
      line('260.000', 300, 102),
      line('245.000', 300, 158),
    ];
    expect(texts(lines), ['Tổng tiền hàng 260.000', 'Tổng thanh toán 245.000']);
  });

  test('orders rows top to bottom and lines left to right', () {
    final lines = [
      line('C', 200, 50),
      line('A', 10, 10),
      line('D', 10, 50),
      line('B', 300, 12),
    ];
    expect(texts(lines), ['A B', 'D C']);
  });

  test('tolerates small vertical misalignment', () {
    // Overlap 12 px of 20 px = 0.6.
    final lines = [line('Tổng cộng', 10, 100), line('84.000', 320, 108)];
    expect(texts(lines), ['Tổng cộng 84.000']);
  });

  test('keeps lines apart when they overlap less than the threshold', () {
    // Overlap 8 px of 20 px = 0.4 < 0.5.
    final lines = [line('Giảm giá', 10, 100), line('15.000', 300, 112)];
    expect(texts(lines), ['Giảm giá', '15.000']);
  });

  test('the overlap threshold is configurable', () {
    final lines = [line('Giảm giá', 10, 100), line('15.000', 300, 112)];
    expect(texts(lines, const RowGrouper(minOverlapRatio: 0.3)), [
      'Giảm giá 15.000',
    ]);
  });

  test('groups a tall bold amount with its smaller label', () {
    final lines = [
      line('TỔNG CỘNG', 10, 200),
      line('1.018.710', 280, 192, height: 36),
    ];
    expect(texts(lines), ['TỔNG CỘNG 1.018.710']);
  });

  test('does not chain a staircase of lines into one row', () {
    // A–B overlap 0.55, B–C overlap 0.55, but C barely overlaps the A+B row.
    final lines = [line('A', 10, 0), line('B', 120, 9), line('C', 230, 18)];
    expect(texts(lines), ['A B', 'C']);
  });

  test('a row exposes its sorted lines and bounding box', () {
    final rows = grouper.group([
      line('B', 300, 10, width: 50),
      line('A', 10, 12, width: 80),
    ]);
    expect(rows.single.lines.map((l) => l.text), ['A', 'B']);
    expect(rows.single.bounds, const Rect.fromLTRB(10, 10, 350, 32));
  });

  test('drops blank lines and trims text', () {
    expect(texts([line('  ', 10, 10), line('  CIRCLE K ', 10, 40)]), [
      'CIRCLE K',
    ]);
  });

  test('handles zero-height boxes without dividing by zero', () {
    final lines = [line('x', 10, 10, height: 0), line('y', 50, 10, height: 0)];
    expect(texts(lines), ['x y']);
  });
}
