import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/core/router.dart';
import 'package:vku_expense_ocr/screens/dashboard/dashboard_screen.dart';
import 'package:vku_expense_ocr/screens/history/history_screen.dart';
import 'package:vku_expense_ocr/screens/review/review_screen.dart';
import 'package:vku_expense_ocr/screens/scan/camera_screen.dart';
import 'package:vku_expense_ocr/services/camera_service.dart';

import '../support/app_harness.dart';
import '../support/fake_camera.dart';

typedef _Open = Future<void> Function(
  WidgetTester tester,
  Size size,
  double scale,
  ThemeMode mode,
);

/// The five screens of the app (FR-8.2): each opens the real app on that
/// screen, with data that stresses the layout.
final Map<String, _Open> _screens = {
  'Dashboard': (tester, size, scale, mode) =>
      pumpApp(tester, size: size, textScale: scale, themeMode: mode),
  'Camera': (tester, size, scale, mode) => pumpApp(
    tester,
    size: size,
    textScale: scale,
    themeMode: mode,
    location: AppRoutes.scan,
  ),
  'Camera (permission denied)': (tester, size, scale, mode) => pumpApp(
    tester,
    size: size,
    textScale: scale,
    themeMode: mode,
    location: AppRoutes.scan,
    cameraSource: FakeCameraSource(
      () => FakeReceiptCamera(initializeError: const CameraPermissionDenied()),
    ),
  ),
  'Review (scan, every warning)': (tester, size, scale, mode) => pumpApp(
    tester,
    size: size,
    textScale: scale,
    themeMode: mode,
    pushed: AppRoutes.review,
    pushedExtra: worstCaseScan(),
  ),
  'History': (tester, size, scale, mode) => pumpApp(
    tester,
    size: size,
    textScale: scale,
    themeMode: mode,
    location: AppRoutes.history,
  ),
  'Detail (edit /expense/1)': (tester, size, scale, mode) => pumpApp(
    tester,
    size: size,
    textScale: scale,
    themeMode: mode,
    pushed: AppRoutes.expense(1),
  ),
};

/// Logical sizes (FR-8.2): small phone, common phone, tall phone, landscape.
const _sizes = <String, Size>{
  '320x480': Size(320, 480),
  '360x640': Size(360, 640),
  '411x891': Size(411, 891),
  'landscape 891x411': Size(891, 411),
};

const _scales = <double>[1, 1.5];

void main() {
  group('no RenderFlex overflow (FR-8.2)', () {
    for (final MapEntry(key: screen, value: open) in _screens.entries) {
      for (final MapEntry(key: sizeName, value: size) in _sizes.entries) {
        for (final scale in _scales) {
          testWidgets('$screen · $sizeName · text ${scale}x', (tester) async {
            await open(tester, size, scale, ThemeMode.light);
            expect(tester.takeException(), isNull);
            await scrollThrough(tester);
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  });

  group('every screen renders in the light and the dark theme', () {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      for (final MapEntry(key: screen, value: open) in _screens.entries) {
        testWidgets('$screen · ${mode.name}', (tester) async {
          await open(tester, const Size(360, 640), 1, mode);

          final brightness = Theme.of(
            tester.element(find.byType(Scaffold).last),
          ).brightness;
          expect(
            brightness,
            mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
          );
          await scrollThrough(tester);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  testWidgets('the screens are the ones the app really shows', (tester) async {
    await pumpApp(tester);
    expect(find.byType(DashboardScreen), findsOneWidget);
    await pumpApp(tester, location: AppRoutes.history);
    expect(find.byType(HistoryScreen), findsOneWidget);
    await pumpApp(tester, location: AppRoutes.scan);
    expect(find.byType(CameraScreen), findsOneWidget);
    await pumpApp(tester, pushed: AppRoutes.review);
    expect(find.byType(ReviewScreen), findsOneWidget);
  });
}
