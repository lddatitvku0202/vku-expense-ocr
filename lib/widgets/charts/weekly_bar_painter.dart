import 'package:flutter/material.dart';
import 'package:vku_expense_ocr/core/formatters.dart';
import 'package:vku_expense_ocr/widgets/charts/chart_geometry.dart';

/// Draws the weekly bars (FR-6.3): seven rounded bars (`drawRRect`) from
/// Monday to Sunday that grow from the baseline with [progress], day
/// labels under them and short values above them, both by [TextPainter].
/// Today's bar and the [selectedIndex] bar get their own colours.
class WeeklyBarPainter extends CustomPainter {
  const WeeklyBarPainter({
    required this.values,
    required this.progress,
    required this.selectedIndex,
    required this.todayIndex,
    required this.barColor,
    required this.todayColor,
    required this.selectedColor,
    required this.labelColor,
    required this.textScaler,
  });

  /// Seven amounts in dong, Monday first.
  final List<int> values;
  final double progress;
  final int? selectedIndex;

  /// Index of today in this week, or `null` when today is another week.
  final int? todayIndex;
  final Color barColor;
  final Color todayColor;
  final Color selectedColor;
  final Color labelColor;
  final TextScaler textScaler;

  static const List<String> dayLabels = [
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
    'CN',
  ];

  /// Plot margins: values above, day labels below.
  static const BarLayout layout = BarLayout(
    left: 4,
    top: 22,
    right: 4,
    bottom: 26,
    gap: 10,
  );

  /// Full-height bar rectangles for [values] in a canvas of [size]; shared
  /// with the widget's hit-test.
  static List<Rect> barRectsFor(Size size, List<int> values) =>
      barRects(values, size, layout);

  @override
  void paint(Canvas canvas, Size size) {
    final rects = barRectsFor(size, values);
    final t = progress.clamp(0.0, 1.0);
    for (var i = 0; i < rects.length; i++) {
      final full = rects[i];
      // Grow from the baseline: the top moves up with the animation.
      final grown = Rect.fromLTRB(
        full.left,
        full.bottom - full.height * t,
        full.right,
        full.bottom,
      );
      final color = i == selectedIndex
          ? selectedColor
          : (i == todayIndex ? todayColor : barColor);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          grown,
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        ),
        Paint()..color = color,
      );

      final bold = i == todayIndex || i == selectedIndex;
      _label(
        canvas,
        dayLabels[i],
        Offset(full.center.dx, full.bottom + 6),
        bold: bold,
        maxWidth: full.width + layout.gap,
      );
      if (values[i] > 0 && t > 0) {
        _label(
          canvas,
          Formatters.compactVnd(values[i]),
          Offset(full.center.dx, grown.top - 4),
          bold: bold,
          maxWidth: full.width + layout.gap,
          above: true,
          fontSize: 10,
        );
      }
    }
  }

  void _label(
    Canvas canvas,
    String text,
    Offset anchor, {
    required bool bold,
    required double maxWidth,
    bool above = false,
    double fontSize = 12,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: labelColor,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
      // Labels must fit their column even with large system text.
      textScaler: textScaler.clamp(maxScaleFactor: 1.3),
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    painter.paint(
      canvas,
      Offset(
        anchor.dx - painter.width / 2,
        above ? anchor.dy - painter.height : anchor.dy,
      ),
    );
  }

  /// Repaints when the data, a colour, the animation, today or the
  /// selection changes (FR-6.4).
  @override
  bool shouldRepaint(WeeklyBarPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.todayIndex != todayIndex ||
      oldDelegate.barColor != barColor ||
      oldDelegate.todayColor != todayColor ||
      oldDelegate.selectedColor != selectedColor ||
      oldDelegate.labelColor != labelColor ||
      oldDelegate.textScaler != textScaler ||
      !_sameValues(oldDelegate.values, values);

  static bool _sameValues(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
