import 'dart:math' as math;
import 'dart:ui';

/// Pure geometry of the two charts (FR-6.1 to FR-6.3), kept out of the
/// painters so it can be unit-tested without drawing anything.
///
/// Canvas angles follow `Canvas.drawArc`: 0 is 3 o'clock and angles grow
/// clockwise, because the y axis points down. The donut starts at 12
/// o'clock, i.e. at -π/2.

/// One donut slice: [start] angle and [sweep] in radians.
typedef SliceArc = ({double start, double sweep});

/// Where a bar chart's plot sits inside its canvas, in logical pixels.
class BarLayout {
  const BarLayout({
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
    this.gap = 8,
    this.minHeight = 3,
  });

  final double left;

  /// Room above the highest bar (its value label).
  final double top;
  final double right;

  /// Room below the bars (the day labels).
  final double bottom;

  /// Space between two bars.
  final double gap;

  /// Height of a bar whose value is 0 or tiny, so every day keeps a visible
  /// stub on the baseline (D-062).
  final double minHeight;
}

const double _fullCircle = 2 * math.pi;

/// Fractions of the total, in input order; all 0 when the total is 0.
List<double> percentages(List<num> totals) {
  final sum = totals.fold<num>(0, (a, b) => a + b);
  return [for (final t in totals) sum == 0 ? 0.0 : t / sum];
}

/// Slices for [fractions] (summing to 1), clockwise from [startAngle].
/// Empty fractions get a zero sweep so indices still match the input.
List<SliceArc> donutSlices(
  List<double> fractions, {
  double startAngle = -math.pi / 2,
}) {
  final slices = <SliceArc>[];
  var start = startAngle;
  for (final fraction in fractions) {
    final sweep = fraction * _fullCircle;
    slices.add((start: start, sweep: sweep));
    start += sweep;
  }
  return slices;
}

/// [angle] mapped into [0, 2π).
double normalizeAngle(double angle) {
  final a = angle % _fullCircle;
  return a >= _fullCircle ? 0 : a;
}

/// Whether [point] lies on a ring of centre line [radius] drawn with a
/// stroke of [strokeWidth] (so between radius ± strokeWidth / 2).
bool isPointInRing(
  Offset point, {
  required Offset center,
  required double radius,
  required double strokeWidth,
}) {
  final distance = (point - center).distance;
  return distance >= radius - strokeWidth / 2 &&
      distance <= radius + strokeWidth / 2;
}

/// The slice under [point], or `null` for the hole, outside the ring or
/// outside the canvas (FR-6.2).
///
/// `atan2(dy, dx)` gives the canvas angle of the point (clockwise from
/// 3 o'clock); subtracting [startAngle] and normalising to [0, 2π) gives
/// its position along the donut, which is then matched against the
/// cumulative sweeps. A boundary belongs to the slice that starts there.
int? angleToSliceIndex(
  Offset point, {
  required Offset center,
  required Size size,
  required List<SliceArc> slices,
  required double radius,
  required double strokeWidth,
  double startAngle = -math.pi / 2,
}) {
  if (!(Offset.zero & size).contains(point)) return null;
  if (!isPointInRing(
    point,
    center: center,
    radius: radius,
    strokeWidth: strokeWidth,
  )) {
    return null;
  }
  final delta = point - center;
  final along = normalizeAngle(math.atan2(delta.dy, delta.dx) - startAngle);
  var end = 0.0;
  int? last;
  for (var i = 0; i < slices.length; i++) {
    final sweep = slices[i].sweep;
    if (sweep <= 0) continue;
    last = i;
    end += sweep;
    if (along < end) return i;
  }
  // Rounding can leave `along` a hair above the last cumulative end.
  return last;
}

/// The value drawn at full plot height: the largest value, or 1 when every
/// value is 0, so heights never divide by zero.
double barScaleMax(List<num> values) {
  final max = values.fold<num>(0, (a, b) => b > a ? b : a);
  return max > 0 ? max.toDouble() : 1;
}

double _barWidth(Size size, int count, BarLayout layout) => count == 0
    ? 0
    : math.max(
        0,
        (size.width - layout.left - layout.right - layout.gap * (count - 1)) /
            count,
      );

/// One rectangle per value, left to right, sharing the baseline
/// `size.height - layout.bottom` (the y axis points down). The largest
/// value fills the plot height; others are proportional, never lower than
/// [BarLayout.minHeight] (FR-6.3).
List<Rect> barRects(List<num> values, Size size, BarLayout layout) {
  final width = _barWidth(size, values.length, layout);
  final baseline = size.height - layout.bottom;
  final plot = math.max(0, baseline - layout.top);
  final scale = barScaleMax(values);
  return [
    for (var i = 0; i < values.length; i++)
      Rect.fromLTRB(
        layout.left + i * (width + layout.gap),
        baseline - math.max(layout.minHeight, plot * values[i] / scale),
        layout.left + i * (width + layout.gap) + width,
        baseline,
      ),
  ];
}

/// The column under [point] (any height, so a 0 stub is easy to tap); a
/// tap in a gap goes to the nearest column. `null` outside the plot.
int? barIndexAt(Offset point, Size size, int count, BarLayout layout) {
  if (count == 0 || !(Offset.zero & size).contains(point)) return null;
  final width = _barWidth(size, count, layout);
  final x = point.dx - layout.left;
  final span = layout.left + count * width + (count - 1) * layout.gap;
  if (x < 0 || point.dx > span) return null;
  final slot = width + layout.gap;
  final index = ((x + layout.gap / 2) / slot).floor();
  return index.clamp(0, count - 1);
}
