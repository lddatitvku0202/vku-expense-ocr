import 'dart:io';
import 'dart:ui' show Rect;

import 'package:vku_expense_ocr/models/ocr_line.dart';

/// Folder holding the `*.txt` receipt fixtures.
const fixtureDir = 'test/fixtures/receipts';

const double _rowPitch = 32;
const double _lineHeight = 20;
const double _firstTop = 40;
const double _defaultSkew = 0.01;
final RegExp _skewDirective = RegExp(r'^#\s*skew:\s*([0-9.]+)\s*$');

/// Reads `test/fixtures/receipts/<fileName>` as OCR lines.
List<OcrLine> loadFixtureLines(String fileName) =>
    ocrLinesFromFixture(File('$fixtureDir/$fileName').readAsStringSync());

/// Turns fixture text into the lines ML Kit would return for the photo.
///
/// Every ` | `-separated block becomes one [OcrLine] with a synthetic box.
/// Blocks right of the first one get ±4 px jitter plus `skew × x`, and the
/// lines are returned column by column, like ML Kit text blocks.
List<OcrLine> ocrLinesFromFixture(String source) {
  var skew = _defaultSkew;
  final rows = <String>[];
  for (final raw in source.split('\n')) {
    final line = raw.trimRight();
    if (line.isEmpty) continue;
    if (line.startsWith('#')) {
      final directive = _skewDirective.firstMatch(line);
      if (directive != null) skew = double.parse(directive.group(1)!);
      continue;
    }
    rows.add(line);
  }

  final columns = <List<OcrLine>>[];
  for (var r = 0; r < rows.length; r++) {
    final cells = rows[r].split(' | ');
    for (var c = 0; c < cells.length; c++) {
      final x = c == 0 ? 16.0 : 260.0 + (c - 1) * 110;
      final jitter = c == 0 ? 0.0 : ((r + c) % 3 - 1) * 4.0;
      final top = _firstTop + r * _rowPitch + jitter + skew * x;
      final width = cells[c].length * 9.0;
      while (columns.length <= c) {
        columns.add(<OcrLine>[]);
      }
      columns[c].add(
        OcrLine(
          text: cells[c],
          boundingBox: Rect.fromLTWH(x, top, width, _lineHeight),
        ),
      );
    }
  }
  return [for (final column in columns) ...column];
}
