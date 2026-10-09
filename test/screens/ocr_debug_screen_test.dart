import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/screens/debug/ocr_debug_screen.dart';
import 'package:vku_expense_ocr/services/receipt_scan_service.dart';
import 'package:vku_expense_ocr/state/ocr_providers.dart';

import '../support/fake_ocr_service.dart';
import '../support/receipt_fixture.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester, {
    required FakeOcrService ocr,
    String? pickedPath = '/fake/coopmart.jpg',
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pickGalleryImageProvider.overrideWithValue(() async => pickedPath),
          receiptScanServiceProvider.overrideWithValue(
            ReceiptScanService(ocr: ocr),
          ),
        ],
        child: const MaterialApp(home: OcrDebugScreen()),
      ),
    );
  }

  Future<void> pickAndWait(WidgetTester tester) async {
    await tester.tap(find.text('Chọn ảnh hóa đơn'));
    // Parsing runs on a real background isolate.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('starts with an empty state', (tester) async {
    await pumpScreen(tester, ocr: FakeOcrService());
    expect(find.text('Chưa có ảnh'), findsOneWidget);
  });

  testWidgets('shows parsed fields and the raw OCR text of the photo', (
    tester,
  ) async {
    final ocr = FakeOcrService(
      lines: loadFixtureLines('coopmart_hue.txt'),
      elapsed: const Duration(milliseconds: 420),
    );
    await pumpScreen(tester, ocr: ocr);
    await pickAndWait(tester);

    expect(ocr.recognizedPaths, ['/fake/coopmart.jpg']);
    expect(find.text('CO.OPMART HUẾ'), findsOneWidget);
    expect(find.textContaining('245.000'), findsWidgets);
    expect(find.text('14/09/2026'), findsOneWidget);
    expect(find.text('Ăn uống'), findsOneWidget);
    // The raw-text panel sits below the fold of the lazy ListView.
    await tester.scrollUntilVisible(find.textContaining('420 ms'), 200);
    expect(find.textContaining('420 ms'), findsOneWidget);
    expect(find.textContaining('Tổng thanh toán 245.000'), findsOneWidget);
  });

  testWidgets('cancelling the picker changes nothing', (tester) async {
    final ocr = FakeOcrService();
    await pumpScreen(tester, ocr: ocr, pickedPath: null);
    await pickAndWait(tester);

    expect(ocr.recognizedPaths, isEmpty);
    expect(find.text('Chưa có ảnh'), findsOneWidget);
  });

  testWidgets('a broken image shows an error instead of crashing', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      ocr: FakeOcrService(error: PlatformException(code: 'bad image')),
    );
    await pickAndWait(tester);

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.textContaining('Không đọc được ảnh'), findsOneWidget);
    expect(find.text('— không tìm thấy'), findsNWidgets(4));
  });
}
