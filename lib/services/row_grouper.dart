import 'dart:math' as math;
import 'dart:ui' show Offset;

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
/// Tilted or sideways photos are handled first: the tilt is estimated from
/// the lines' corner points ([estimateSkew]) and every line is rotated back
/// before the overlap test, so "upright" rows exist again.
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

  /// Angle of the text baseline in radians (0 = upright, π/2 = text runs
  /// downwards, i.e. the photo was taken sideways), or 0 without corners.
  ///
  /// Each line's direction is its top edge (top-left → top-right). The
  /// dominant direction is the one shared by the most lines (within
  /// [_window]); ties go to more text length. Only lines near it are then
  /// averaged, as summed vectors, so long lines count more and angles near
  /// ±180° do not wrap. Text at another angle in the photo (a shopping bag,
  /// a sign) cannot outvote the receipt's many lines.
  static double estimateSkew(List<OcrLine> lines) {
    final edges = <({double angle, Offset vector})>[];
    for (final line in lines) {
      final corners = line.cornerPoints;
      if (corners == null || corners.length < 2) continue;
      final edge = corners[1] - corners[0];
      if (edge.distance == 0) continue;
      edges.add((angle: edge.direction, vector: edge));
    }
    if (edges.isEmpty) return 0;

    List<Offset> near(double angle) => [
      for (final e in edges)
        if (_angleBetween(e.angle, angle) <= _window) e.vector,
    ];
    double length(List<Offset> vectors) =>
        vectors.fold(0, (sum, v) => sum + v.distance);

    var best = near(edges.first.angle);
    for (final e in edges.skip(1)) {
      final group = near(e.angle);
      if (group.length > best.length ||
          (group.length == best.length && length(group) > length(best))) {
        best = group;
      }
    }
    final sum = best.fold(Offset.zero, (a, b) => a + b);
    return math.atan2(sum.dy, sum.dx);
  }

  /// Lines within ±10° count as the same direction.
  static const double _window = 10 * math.pi / 180;

  /// Smallest absolute difference between two angles, in [0, π].
  static double _angleBetween(double a, double b) {
    final d = (a - b) % (2 * math.pi);
    return d > math.pi ? 2 * math.pi - d : d;
  }

  /// Groups [lines] into rows ordered top to bottom, each sorted left to
  /// right (in the deskewed frame). Blank lines are dropped.
  List<ReceiptRow> group(List<OcrLine> lines) {
    final skew = estimateSkew(lines);
    final cos = math.cos(-skew);
    final sin = math.sin(-skew);
    Offset upright(Offset p) =>
        Offset(p.dx * cos - p.dy * sin, p.dx * sin + p.dy * cos);

    final visible = [
      for (final line in lines)
        if (line.text.trim().isNotEmpty) _Band.of(line, upright),
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

/// Extent of one line after deskewing; zero-height lines count as 1 px.
class _Band {
  _Band(this.line, this.left, this.top, this.bottom);

  factory _Band.of(OcrLine line, Offset Function(Offset) upright) {
    final box = line.boundingBox;
    final corners =
        line.cornerPoints ??
        [box.topLeft, box.topRight, box.bottomRight, box.bottomLeft];
    final points = corners.map(upright).toList();
    final top = points.map((p) => p.dy).reduce(math.min);
    final bottom = points.map((p) => p.dy).reduce(math.max);
    final left = points.map((p) => p.dx).reduce(math.min);
    return _Band(line, left, top, math.max(bottom, top + 1));
  }

  final OcrLine line;
  final double left;
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

  final List<_Band> _bands = [];
  double _sumTop = 0;
  double _sumBottom = 0;

  void add(_Band band) {
    _bands.add(band);
    _sumTop += band.top;
    _sumBottom += band.bottom;
  }

  double overlapRatio(_Band band) {
    final rowTop = _sumTop / _bands.length;
    final rowBottom = _sumBottom / _bands.length;
    final overlap =
        math.min(band.bottom, rowBottom) - math.max(band.top, rowTop);
    if (overlap <= 0) return 0;
    final shorter = math.min(band.bottom - band.top, rowBottom - rowTop);
    return overlap / shorter;
  }

  ReceiptRow build() => ReceiptRow([
    for (final band in [..._bands]..sort((a, b) => a.left.compareTo(b.left)))
      band.line,
  ]);
}
