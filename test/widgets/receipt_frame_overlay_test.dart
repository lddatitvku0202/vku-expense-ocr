import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/widgets/receipt_frame_overlay.dart';

void main() {
  const frame = Rect.fromLTWH(40, 80, 280, 480);
  const base = ReceiptFramePainter(
    frame: frame,
    scrimColor: Color(0x99000000),
    borderColor: Colors.white,
  );

  group('ReceiptFramePainter.shouldRepaint', () {
    test('false for identical settings', () {
      expect(
        base.shouldRepaint(
          const ReceiptFramePainter(
            frame: frame,
            scrimColor: Color(0x99000000),
            borderColor: Colors.white,
          ),
        ),
        isFalse,
      );
    });

    test('true when the frame, a colour or the stroke changes', () {
      expect(
        base.shouldRepaint(
          const ReceiptFramePainter(
            frame: Rect.fromLTWH(40, 80, 280, 481),
            scrimColor: Color(0x99000000),
            borderColor: Colors.white,
          ),
        ),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          const ReceiptFramePainter(
            frame: frame,
            scrimColor: Color(0x88000000),
            borderColor: Colors.white,
          ),
        ),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          const ReceiptFramePainter(
            frame: frame,
            scrimColor: Color(0x99000000),
            borderColor: Colors.amber,
          ),
        ),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          const ReceiptFramePainter(
            frame: frame,
            scrimColor: Color(0x99000000),
            borderColor: Colors.white,
            strokeWidth: 4,
          ),
        ),
        isTrue,
      );
    });
  });

  testWidgets('darkens outside the frame and leaves the frame clear', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 360,
          height: 640,
          child: CustomPaint(painter: base),
        ),
      ),
    );

    expect(
      find.byType(CustomPaint),
      paints..path(
        color: const Color(0x99000000),
        includes: const [Offset(10, 10), Offset(350, 630)],
        excludes: const [Offset(180, 320), Offset(45, 85)],
      ),
    );
  });
}
