import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vku_expense_ocr/widgets/charts/chart_geometry.dart';

/// One category of the donut: its share of the total and its colour.
typedef DonutSegment = ({double fraction, Color color});

/// Draws the category donut (FR-6.1): a stroked `drawArc` per category,
/// swept from 0 to [progress] of the full circle, with the total written
/// in the hole by a [TextPainter]. The [selectedIndex] slice is drawn
/// thicker (FR-6.2).
class DonutChartPainter extends CustomPainter {
  const DonutChartPainter({
    required this.segments,
    required this.progress,
    required this.selectedIndex,
    required this.trackColor,
    required this.textColor,
    required this.captionColor,
    required this.totalLabel,
    required this.compactTotalLabel,
    required this.textScaler,
  });

  final List<DonutSegment> segments;

  /// Animation value: 0 draws nothing, 1 the whole donut.
  final double progress;
  final int? selectedIndex;
  final Color trackColor;
  final Color textColor;
  final Color captionColor;

  /// Total in the hole, e.g. "1.250.000 đ" …
  final String totalLabel;

  /// … or this shorter form ("1,25tr đ") when the full one does not fit.
  final String compactTotalLabel;
  final TextScaler textScaler;

  static const double startAngle = -math.pi / 2;

  /// Extra stroke of the selected slice.
  static const double selectedStrokeFactor = 1.35;

  /// Centre, centre-line radius and stroke of the ring in a canvas of
  /// [size]; shared with the widget's hit-test so both agree.
  static ({Offset center, double radius, double strokeWidth}) ringFor(
    Size size,
  ) {
    final side = size.shortestSide;
    final stroke = side * 0.14;
    return (
      center: size.center(Offset.zero),
      // Room for the thicker selected stroke inside the canvas.
      radius: side / 2 - stroke * selectedStrokeFactor / 2,
      strokeWidth: stroke,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final ring = ringFor(size);
    final rect = Rect.fromCircle(center: ring.center, radius: ring.radius);

    canvas.drawCircle(
      ring.center,
      ring.radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring.strokeWidth,
    );

    // Sweep all slices together: at progress p only the first p of the
    // circle is drawn, slice by slice.
    final visibleEnd = startAngle + 2 * math.pi * progress.clamp(0.0, 1.0);
    final slices = donutSlices([for (final s in segments) s.fraction]);
    for (var i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final sweep = math.min(slice.sweep, visibleEnd - slice.start);
      if (sweep <= 0) continue;
      final selected = i == selectedIndex;
      canvas.drawArc(
        rect,
        slice.start,
        sweep,
        false,
        Paint()
          ..color = segments[i].color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt
          ..strokeWidth =
              ring.strokeWidth * (selected ? selectedStrokeFactor : 1),
      );
    }

    _paintTotal(canvas, ring.center, ring.radius - ring.strokeWidth / 2);
  }

  void _paintTotal(Canvas canvas, Offset center, double innerRadius) {
    // Text must stay inside the hole: about 80 % of its diameter.
    final maxWidth = innerRadius * 2 * 0.8;
    TextPainter layout(String text, double fontSize, Color color) =>
        TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              fontSize: fontSize,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
          textScaler: textScaler,
          maxLines: 1,
        )..layout();

    final fontSize = innerRadius * 0.28;
    var total = layout(totalLabel, fontSize, textColor);
    if (total.width > maxWidth) {
      total = layout(compactTotalLabel, fontSize, textColor);
    }
    if (total.width > maxWidth) {
      // Still too wide (huge text scale): shrink to fit.
      total = layout(
        compactTotalLabel,
        fontSize * maxWidth / total.width,
        textColor,
      );
    }
    final caption = TextPainter(
      text: TextSpan(
        text: 'Tổng',
        style: TextStyle(fontSize: fontSize * 0.6, color: captionColor),
      ),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout(maxWidth: maxWidth);

    final height = caption.height + total.height;
    caption.paint(canvas, center + Offset(-caption.width / 2, -height / 2));
    total.paint(
      canvas,
      center + Offset(-total.width / 2, -height / 2 + caption.height),
    );
  }

  /// Repaints when the data, a colour, the animation or the selection
  /// changes (FR-6.4), not only on progress as in the slides (W8 s33).
  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.textColor != textColor ||
      oldDelegate.captionColor != captionColor ||
      oldDelegate.totalLabel != totalLabel ||
      oldDelegate.compactTotalLabel != compactTotalLabel ||
      oldDelegate.textScaler != textScaler ||
      !_sameSegments(oldDelegate.segments, segments);

  static bool _sameSegments(List<DonutSegment> a, List<DonutSegment> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
