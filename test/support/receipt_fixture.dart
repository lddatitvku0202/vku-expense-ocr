import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Offset, Rect;

import 'package:vku_expense_ocr/models/ocr_line.dart';

/// Folder holding the `*.txt` receipt fixtures.
const fixtureDir = 'test/fixtures/receipts';

const double _rowPitch = 32;
const double _lineHeight = 20;
const double _firstTop = 40;
const double _defaultSkew = 0.01;
final RegExp _skewDirective = RegExp(r'^#\s*skew:\s*(-?[0-9.]+)\s*$');
final RegExp _rotateDirective = RegExp(r'^#\s*rotate:\s*(-?[0-9.]+)\s*$');

/// Reads `test/fixtures/receipts/<fileName>` as OCR lines.
List<OcrLine> loadFixtureLines(String fileName) =>
    ocrLinesFromFixture(File('$fixtureDir/$fileName').readAsStringSync());

/// Turns fixture text into the lines ML Kit would return for the photo.
///
/// Every ` | `-separated block becomes one [OcrLine]. Blocks right of the
/// first one get ±4 px jitter. The whole layout is then sheared by
/// `# skew:` (default 0.01) and rotated by `# rotate:` degrees, and every
/// line carries its four corner points (clockwise from the text's top-left)
/// plus the axis-aligned bounding box of those corners, as ML Kit reports.
/// Lines are returned column by column, like ML Kit text blocks.
List<OcrLine> ocrLinesFromFixture(String source) {
  var skew = _defaultSkew;
  var degrees = 0.0;
  final rows = <String>[];
  for (final raw in source.split('\n')) {
    final line = raw.trimRight();
    if (line.isEmpty) continue;
    if (line.startsWith('#')) {
      if (_skewDirective.firstMatch(line) case final m?) {
        skew = double.parse(m.group(1)!);
      }
      if (_rotateDirective.firstMatch(line) case final m?) {
        degrees = double.parse(m.group(1)!);
      }
      continue;
    }
    rows.add(line);
  }

  final angle = degrees * math.pi / 180;
  Offset transform(Offset p) {
    final sheared = Offset(p.dx, p.dy + skew * p.dx);
    return Offset(
      sheared.dx * math.cos(angle) - sheared.dy * math.sin(angle),
      sheared.dx * math.sin(angle) + sheared.dy * math.cos(angle),
    );
  }

  final columns = <List<(String, List<Offset>)>>[];
  for (var r = 0; r < rows.length; r++) {
    final cells = rows[r].split(' | ');
    for (var c = 0; c < cells.length; c++) {
      final x = c == 0 ? 16.0 : 260.0 + (c - 1) * 110;
      final jitter = c == 0 ? 0.0 : ((r + c) % 3 - 1) * 4.0;
      final top = _firstTop + r * _rowPitch + jitter;
      final width = cells[c].length * 9.0;
      final corners = [
        Offset(x, top),
        Offset(x + width, top),
        Offset(x + width, top + _lineHeight),
        Offset(x, top + _lineHeight),
      ].map(transform).toList();
      while (columns.length <= c) {
        columns.add([]);
      }
      columns[c].add((cells[c], corners));
    }
  }

  // Shift everything into positive image coordinates.
  final all = [
    for (final column in columns)
      for (final (_, corners) in column) ...corners,
  ];
  final dx = 16 - all.map((p) => p.dx).reduce(math.min);
  final dy = 16 - all.map((p) => p.dy).reduce(math.min);

  return [
    for (final column in columns)
      for (final (text, corners) in column)
        _line(text, [for (final p in corners) p.translate(dx, dy)]),
  ];
}

OcrLine _line(String text, List<Offset> corners) {
  final xs = corners.map((p) => p.dx);
  final ys = corners.map((p) => p.dy);
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
