import 'package:flutter/material.dart';

/// Darkens the camera preview outside the alignment [frame] and outlines
/// the frame with corner marks (FR-1.4, W8 s30–34).
class ReceiptFramePainter extends CustomPainter {
  const ReceiptFramePainter({
    required this.frame,
    required this.scrimColor,
    required this.borderColor,
    this.strokeWidth = 3,
  });

  /// Frame in the painter's local coordinates.
  final Rect frame;
  final Color scrimColor;
  final Color borderColor;
  final double strokeWidth;

  static const double _cornerRadius = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final hole = RRect.fromRectAndRadius(
      frame,
      const Radius.circular(_cornerRadius),
    );
    // Even-odd fill: the outer rectangle minus the frame, so the frame stays
    // a clear window onto the preview.
    final scrim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(hole);
    canvas.drawPath(scrim, Paint()..color = scrimColor);

    final border = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawRRect(hole, border..color = borderColor.withValues(alpha: 0.5));

    // Bold corner marks, like a document scanner.
    border.color = borderColor;
    final arm = frame.shortestSide * 0.12;
    for (final (corner, dx, dy) in [
      (frame.topLeft, 1.0, 1.0),
      (frame.topRight, -1.0, 1.0),
      (frame.bottomLeft, 1.0, -1.0),
      (frame.bottomRight, -1.0, -1.0),
    ]) {
      canvas
        ..drawLine(corner, corner.translate(arm * dx, 0), border)
        ..drawLine(corner, corner.translate(0, arm * dy), border);
    }
  }

  /// Repaints only when something drawn changes (FR-6.4 applies the same
  /// rule to the charts): the frame, a colour or the stroke.
  @override
  bool shouldRepaint(ReceiptFramePainter oldDelegate) =>
      oldDelegate.frame != frame ||
      oldDelegate.scrimColor != scrimColor ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
