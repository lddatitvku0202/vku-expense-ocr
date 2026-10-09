// Camera smoke test on a device or emulator (Phase 6):
// live preview → capture → crop to the frame → real ML Kit OCR → /review.
//
//   flutter test integration_test/camera_smoke_test.dart -d <device id>
//
// The camera permission must be granted (the test waits up to 2 minutes
// for it), e.g. with `adb shell pm grant vn.edu.vku.vku_expense_ocr
// android.permission.CAMERA` once the app is installed.
//
// The image_cropper screen is a native Android activity that a Flutter
// test cannot tap, so it is replaced here by a pass-through; opening it is
// on the manual checklist for a real phone (docs/TEST_REPORT.md).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vku_expense_ocr/app.dart';
import 'package:vku_expense_ocr/screens/review/review_screen.dart';
import 'package:vku_expense_ocr/screens/scan/camera_screen.dart';
import 'package:vku_expense_ocr/services/manual_cropper.dart';
import 'package:vku_expense_ocr/state/app_startup.dart';
import 'package:vku_expense_ocr/state/camera_providers.dart';

/// Test-only stand-in for the native crop screen: keeps the frame crop.
class _PassThroughCropper implements ManualCropper {
  @override
  Future<String?> adjust(String path) async => path;
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  required Duration timeout,
  required String what,
}) async {
  final end = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('Timed out waiting for $what');
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('preview, capture, frame crop, OCR and Review', (tester) async {
    await initializeDateFormatting('vi_VN');
    final waitStart = DateTime.now();
    while (!await Permission.camera.isGranted) {
      if (DateTime.now().difference(waitStart) > const Duration(minutes: 2)) {
        fail('Camera permission was not granted');
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    final overrides = await createStartupOverrides();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...overrides,
          manualCropperProvider.overrideWithValue(_PassThroughCropper()),
        ],
        child: const VkuExpenseApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quét').last);
    await _pumpUntil(
      tester,
      () => find.byType(CameraScreen).evaluate().isNotEmpty,
      timeout: const Duration(seconds: 10),
      what: 'the camera screen',
    );

    // Live preview (FR-1.1): the shutter is enabled once the camera runs.
    await _pumpUntil(
      tester,
      () {
        final shutter = find.byKey(CameraScreen.shutterKey);
        return shutter.evaluate().isNotEmpty &&
            tester.widget<GestureDetector>(shutter).onTap != null;
      },
      timeout: const Duration(seconds: 30),
      what: 'the live preview',
    );
    expect(find.byKey(CameraScreen.frameOverlayKey), findsOneWidget);
    final viewport = tester.getSize(find.byKey(CameraScreen.previewAreaKey));
    debugPrint('SMOKE preview area ${viewport.width} x ${viewport.height}');
    await tester.pump(const Duration(seconds: 2)); // let exposure settle

    // Capture → crop → OCR → Review.
    final started = DateTime.now();
    await tester.tap(find.byKey(CameraScreen.shutterKey));
    await _pumpUntil(
      tester,
      () => find.byType(ReviewScreen).evaluate().isNotEmpty,
      timeout: const Duration(seconds: 90),
      what: 'the Review screen',
    );
    final review = tester.widget<ReviewScreen>(find.byType(ReviewScreen));
    final scan = review.scan;
    expect(scan, isNotNull, reason: 'Review gets the ScanResult');
    final cropped = img.decodeJpg(File(scan!.imagePath).readAsBytesSync())!;
    debugPrint(
      'SMOKE review after ${DateTime.now().difference(started).inMilliseconds}'
      ' ms; crop ${cropped.width} x ${cropped.height}; '
      'OCR ${scan.ocrDuration.inMilliseconds} ms; rows ${scan.rows.length}; '
      'error ${scan.error}',
    );
    expect(cropped.height, greaterThan(cropped.width), reason: 'portrait crop');
    expect(tester.takeException(), isNull);
  });
}
