import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/widgets/charts/chart_geometry.dart';

const _size = Size(200, 200);
const _center = Offset(100, 100);
const _radius = 80.0;
const _stroke = 20.0;

/// A point on the ring's centre line at [clockwiseFromNoon] radians.
Offset _at(double clockwiseFromNoon, [double radius = _radius]) => Offset(
  _center.dx + radius * math.sin(clockwiseFromNoon),
  _center.dy - radius * math.cos(clockwiseFromNoon),
);

int? _hit(List<SliceArc> slices, Offset point) => angleToSliceIndex(
  point,
  center: _center,
  size: _size,
  slices: slices,
  radius: _radius,
  strokeWidth: _stroke,
);

void main() {
  group('percentages', () {
    test('fractions of the total that add up to 1', () {
      final p = percentages([75000, 120000, 0, 5000, 0]);
      expect(p, hasLength(5));
      expect(p[0], closeTo(0.375, 1e-12));
      expect(p[2], 0);
      expect(p.fold<double>(0, (a, b) => a + b), closeTo(1, 1e-12));
    });

    test('all zero: all zero, no NaN', () {
      expect(percentages([0, 0, 0]), [0.0, 0.0, 0.0]);
    });
  });

  group('donutSlices', () {
    test('start at 12 o\'clock and go clockwise, one per input', () {
      final slices = donutSlices([0.25, 0.75]);
      expect(slices, hasLength(2));
      expect(slices[0].start, closeTo(-math.pi / 2, 1e-12));
      expect(slices[0].sweep, closeTo(math.pi / 2, 1e-12));
      expect(slices[1].start, closeTo(0, 1e-12));
      expect(slices[1].sweep, closeTo(3 * math.pi / 2, 1e-12));
    });

    test('a single 100 % slice is the full circle', () {
      final slices = donutSlices([0, 1, 0]);
      expect(slices[1].sweep, closeTo(2 * math.pi, 1e-12));
      expect(slices[0].sweep, 0);
      expect(slices[2].sweep, 0);
    });

    test('sweeps add up to a full circle, tiny slices included', () {
      final fractions = [0.995, 0.001, 0.001, 0.001, 0.002];
      final total = donutSlices(fractions)
          .fold<double>(0, (a, s) => a + s.sweep);
      expect(total, closeTo(2 * math.pi, 1e-9));
    });

    test('a custom start angle shifts every slice', () {
      final slices = donutSlices([0.5, 0.5], startAngle: 0);
      expect(slices[0].start, 0);
      expect(slices[1].start, closeTo(math.pi, 1e-12));
    });
  });

  group('normalizeAngle', () {
    test('maps any angle into [0, 2π)', () {
      expect(normalizeAngle(0), 0);
      expect(normalizeAngle(-math.pi / 2), closeTo(3 * math.pi / 2, 1e-12));
      expect(normalizeAngle(2 * math.pi), closeTo(0, 1e-12));
      expect(normalizeAngle(5 * math.pi), closeTo(math.pi, 1e-12));
      expect(normalizeAngle(2 * math.pi - 1e-15), lessThan(2 * math.pi));
    });
  });

  group('isPointInRing', () {
    test('inside the stroke band only', () {
      bool inRing(Offset p) => isPointInRing(
        p,
        center: _center,
        radius: _radius,
        strokeWidth: _stroke,
      );
      expect(inRing(_at(0)), isTrue);
      expect(inRing(_at(1, _radius - _stroke / 2 + 0.5)), isTrue);
      expect(inRing(_at(1, _radius + _stroke / 2 - 0.5)), isTrue);
      expect(inRing(_center), isFalse, reason: 'the hole');
      expect(inRing(_at(1, _radius - _stroke / 2 - 1)), isFalse);
      expect(inRing(_at(1, _radius + _stroke / 2 + 1)), isFalse);
    });
  });

  group('angleToSliceIndex (atan2 hit-test, FR-6.2)', () {
    final quarters = donutSlices([0.25, 0.25, 0.25, 0.25]);

    test('12, 3, 6 and 9 o\'clock with four equal slices', () {
      expect(_hit(quarters, _at(0)), 0, reason: '12h starts slice 0');
      expect(_hit(quarters, _at(math.pi / 2)), 1, reason: '3h');
      expect(_hit(quarters, _at(math.pi)), 2, reason: '6h');
      expect(_hit(quarters, _at(3 * math.pi / 2)), 3, reason: '9h');
    });

    test('first and last slice around 12 o\'clock', () {
      expect(_hit(quarters, _at(0.01)), 0);
      expect(_hit(quarters, _at(2 * math.pi - 0.01)), 3);
    });

    test('a boundary belongs to the slice that starts there', () {
      final halves = donutSlices([0.5, 0.5]);
      expect(_hit(halves, _at(math.pi - 1e-6)), 0);
      expect(_hit(halves, _at(math.pi)), 1);
      expect(_hit(halves, _at(math.pi + 1e-6)), 1);
    });

    test('empty slices are skipped', () {
      final slices = donutSlices([0, 0.5, 0, 0.5, 0]);
      expect(_hit(slices, _at(0.1)), 1);
      expect(_hit(slices, _at(math.pi + 0.1)), 3);
    });

    test('a single 100 % slice is hit everywhere on the ring', () {
      final slices = donutSlices([0, 0, 1, 0, 0]);
      for (var a = 0.0; a < 2 * math.pi; a += 0.5) {
        expect(_hit(slices, _at(a)), 2, reason: 'angle $a');
      }
    });

    test('tiny slices (< 1 %) can still be hit at their middle', () {
      final fractions = [0.995, 0.001, 0.002, 0.002];
      final slices = donutSlices(fractions);
      for (var i = 0; i < slices.length; i++) {
        final middle = slices[i].start + slices[i].sweep / 2 + math.pi / 2;
        expect(_hit(slices, _at(middle)), i, reason: 'slice $i');
      }
    });

    test('the hole, outside the ring and outside the canvas give null', () {
      expect(_hit(quarters, _center), isNull);
      expect(_hit(quarters, _at(1, 40)), isNull);
      expect(_hit(quarters, _at(1, 99)), isNull);
      expect(_hit(quarters, const Offset(-5, 100)), isNull);
      expect(_hit(quarters, const Offset(100, 250)), isNull);
    });

    test('no data gives null', () {
      expect(_hit(donutSlices([0, 0, 0]), _at(1)), isNull);
    });
  });

  group('barScaleMax', () {
    test('the largest value, so the highest bar is full height', () {
      expect(barScaleMax([0, 50000, 30000]), 50000);
    });

    test('all zero (or empty) gives 1, never 0', () {
      expect(barScaleMax([0, 0, 0]), 1);
      expect(barScaleMax(const []), 1);
    });
  });

  group('barRects (FR-6.3)', () {
    const size = Size(360, 200);
    const layout = BarLayout(left: 10, top: 20, right: 10, bottom: 30, gap: 8);

    test('7 bars, left to right, equal widths and gaps', () {
      final rects = barRects([1, 2, 3, 4, 5, 6, 7], size, layout);
      expect(rects, hasLength(7));
      final width = (360 - 10 - 10 - 6 * 8) / 7;
      for (var i = 0; i < 7; i++) {
        expect(rects[i].width, closeTo(width, 1e-9));
        expect(rects[i].left, closeTo(10 + i * (width + 8), 1e-9));
      }
    });

    test('bottoms sit on size.height - bottom margin (y grows downwards)', () {
      final rects = barRects([1, 2, 0, 4, 5, 6, 7], size, layout);
      for (final r in rects) {
        expect(r.bottom, 170);
      }
    });

    test(
      'the highest value fills the plot height, others are proportional',
      () {
        final rects = barRects([10, 5, 0, 0, 0, 0, 20], size, layout);
        const plot = 200 - 20 - 30;
        expect(rects[6].top, closeTo(20, 1e-9));
        expect(rects[6].height, closeTo(plot, 1e-9));
        expect(rects[0].height, closeTo(plot / 2, 1e-9));
        expect(rects[1].height, closeTo(plot / 4, 1e-9));
      },
    );

    test('a 0 bar keeps a visible stub of minHeight (D-062)', () {
      final rects = barRects([0, 100, 0, 0, 0, 0, 0], size, layout);
      expect(rects[0].height, layout.minHeight);
      expect(rects[0].bottom, 170);
      expect(layout.minHeight, greaterThan(0));
    });

    test('all zero: only stubs, no division by zero', () {
      final rects = barRects(List.filled(7, 0), size, layout);
      for (final r in rects) {
        expect(r.height, layout.minHeight);
        expect(r.top.isFinite, isTrue);
      }
    });

    test('a small value is never drawn lower than the stub', () {
      final rects = barRects([1, 1000000, 0, 0, 0, 0, 0], size, layout);
      expect(rects[0].height, layout.minHeight);
    });
  });

  group('barIndexAt (tap a column)', () {
    const size = Size(360, 200);
    const layout = BarLayout(left: 10, top: 20, right: 10, bottom: 30, gap: 8);

    test('any height of a column selects it, also a 0-stub column', () {
      final rects = barRects([0, 5, 0, 0, 0, 0, 9], size, layout);
      for (var i = 0; i < 7; i++) {
        expect(barIndexAt(Offset(rects[i].center.dx, 60), size, 7, layout), i);
      }
    });

    test('a tap in a gap goes to the nearest column', () {
      final rects = barRects(List.filled(7, 1), size, layout);
      expect(barIndexAt(Offset(rects[2].right + 3, 100), size, 7, layout), 2);
      expect(barIndexAt(Offset(rects[3].left - 3, 100), size, 7, layout), 3);
    });

    test('outside the plot gives null', () {
      expect(barIndexAt(const Offset(5, 100), size, 7, layout), isNull);
      expect(barIndexAt(const Offset(355, 100), size, 7, layout), isNull);
      expect(barIndexAt(const Offset(100, -1), size, 7, layout), isNull);
      expect(barIndexAt(const Offset(100, 201), size, 7, layout), isNull);
    });
  });
}
