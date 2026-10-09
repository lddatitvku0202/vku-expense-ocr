import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/widgets/ocr_text_panel.dart';

void main() {
  Future<void> pump(WidgetTester tester, List<String> rows) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OcrTextPanel(
              rows: rows,
              ocrDuration: const Duration(milliseconds: 345),
            ),
          ),
        ),
      );

  testWidgets('shows the OCR time and hides the text until expanded', (
    tester,
  ) async {
    await pump(tester, ['CO.OPMART HUẾ', 'Tổng thanh toán 245.000']);

    expect(find.text('Xem văn bản OCR gốc'), findsOneWidget);
    expect(find.textContaining('345 ms'), findsOneWidget);
    expect(find.textContaining('2 dòng'), findsOneWidget);
    expect(find.textContaining('Tổng thanh toán 245.000'), findsNothing);

    await tester.tap(find.text('Xem văn bản OCR gốc'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tổng thanh toán 245.000'), findsOneWidget);
  });

  testWidgets('says so when no text was recognized', (tester) async {
    await pump(tester, const []);
    await tester.tap(find.text('Xem văn bản OCR gốc'));
    await tester.pumpAndSettle();
    expect(
      find.text('Không nhận dạng được chữ nào trong ảnh.'),
      findsOneWidget,
    );
  });

  testWidgets('a saved expense without OCR time shows only the row count', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: OcrTextPanel(rows: ['A', 'B', 'C'])),
      ),
    );
    expect(find.text('3 dòng'), findsOneWidget);
    expect(find.textContaining('ms'), findsNothing);
  });
}
