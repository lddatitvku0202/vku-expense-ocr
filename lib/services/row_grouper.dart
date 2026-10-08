import 'dart:math' as math;

import 'package:vku_expense_ocr/models/ocr_line.dart';
import 'package:vku_expense_ocr/models/receipt_row.dart';

/// Rebuilds the visual rows of a receipt from OCR lines (FR-2.3).
///
/// ML Kit returns text block by block, so a label in the left column and
/// its amount in the right column arrive far apart in the list. Splitting
/// the raw text on newlines (as in W8 s42) therefore separates "Tổng tiền"
/// from its amount. Instead, lines whose vertical extents overlap by at
/// least [minOverlapRatio] of the shorter height are merged into one row.
///
/// Pure Dart: works on [OcrLine], never on ML Kit types.
class RowGrouper {
  const RowGrouper({this.minOverlapRatio = 0.5})
    : assert(
        minOverlapRatio > 0 && minOverlapRatio <= 1,
        'minOverlapRatio must be in (0, 1]',
      );

  /// Minimum vertical overlap, as a fraction of the shorter height, for two
  /// pieces of text to count as the same row.
  final double minOverlapRatio;

  /// Groups [lines] into rows ordered top to bottom, each sorted left to
  /// right. Blank lines are dropped.
  List<ReceiptRow> group(List<OcrLine> lines) {
    final visible = [
      for (final line in lines)
        if (line.text.trim().isNotEmpty) _Band.of(line),
    ]..sort((a, b) => a.center.compareTo(b.center));

    final rows = <_RowBuilder>[];
    for (final band in visible) {
      final current = rows.isEmpty ? null : rows.last;
      if (current != null && current.overlapRatio(band) >= minOverlapRatio) {
        current.add(band);
      } else {
        rows.add(_RowBuilder(band));
      }
    }
    return [for (final row in rows) row.build()];
  }
}

/// Vertical extent of one line; zero-height boxes are treated as 1 px tall.
class _Band {
  _Band(this.line, this.top, this.bottom);

  factory _Band.of(OcrLine line) {
    final box = line.boundingBox;
    return _Band(line, box.top, math.max(box.bottom, box.top + 1));
  }

  final OcrLine line;
  final double top;
  final double bottom;

  double get center => (top + bottom) / 2;
}

/// A row under construction. New lines are compared with the row's average
/// band rather than with its last line, so a staircase of slightly
/// overlapping lines cannot chain into one tall row.
class _RowBuilder {
  _RowBuilder(_Band first) {
    add(first);
  }

  final List<OcrLine> _lines = [];
  double _sumTop = 0;
  double _sumBottom = 0;

  void add(_Band band) {
    _lines.add(band.line);
    _sumTop += band.top;
    _sumBottom += band.bottom;
  }

  double overlapRatio(_Band band) {
    final rowTop = _sumTop / _lines.length;
    final rowBottom = _sumBottom / _lines.length;
    final overlap =
        math.min(band.bottom, rowBottom) - math.max(band.top, rowTop);
    if (overlap <= 0) return 0;
    final shorter = math.min(band.bottom - band.top, rowBottom - rowTop);
    return overlap / shorter;
  }

  ReceiptRow build() => ReceiptRow(
    [..._lines]
      ..sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left)),
  );
}
