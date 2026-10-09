import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vku_expense_ocr/core/frame_geometry.dart';
import 'package:vku_expense_ocr/models/parsed_receipt.dart';
import 'package:vku_expense_ocr/screens/scan/camera_screen.dart';
import 'package:vku_expense_ocr/services/camera_service.dart';
import 'package:vku_expense_ocr/services/receipt_scan_service.dart';
import 'package:vku_expense_ocr/state/camera_providers.dart';
import 'package:vku_expense_ocr/state/ocr_providers.dart';

import '../support/fake_camera.dart';
import '../support/fake_ocr_service.dart';

/// Scan service double: returns at once, optionally as a failed read.
class _FakeScanService extends ReceiptScanService {
  _FakeScanService({this.fail = false}) : super(ocr: FakeOcrService());

  final bool fail;
  final List<String> scanned = [];

  @override
  Future<ScanResult> scan(String imagePath) async {
    scanned.add(imagePath);
    return ScanResult(
      imagePath: imagePath,
      receipt: const ParsedReceipt.empty(),
      rows: const [],
      ocrDuration: const Duration(milliseconds: 800),
      error: fail
          ? 'Không đọc được ảnh hóa đơn. Hãy chụp lại hoặc nhập tay.'
          : null,
    );
  }
}

void main() {
  late FakeCameraSource source;
  late FakeImageCropService crops;
  late FakeManualCropper cropper;
  late _FakeScanService scans;
  late int settingsOpened;
  String? galleryPick;
  late ValueNotifier<bool> tabActive;

  setUp(() {
    source = FakeCameraSource(FakeReceiptCamera.new);
    crops = FakeImageCropService();
    cropper = FakeManualCropper();
    scans = _FakeScanService();
    settingsOpened = 0;
    galleryPick = '/gallery/receipt.jpg';
    tabActive = ValueNotifier(true);
  });

  /// Pumps the camera screen, by default at 360 x 640 logical pixels (a
  /// 16:9 phone). [tabActive] plays the role of StatefulShellRoute, which
  /// turns TickerMode off for hidden tabs.
  Future<void> pumpCamera(
    WidgetTester tester, {
    Size physicalSize = const Size(1080, 1920),
  }) async {
    tester.view
      ..physicalSize = physicalSize
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => ValueListenableBuilder(
            valueListenable: tabActive,
            builder: (context, active, child) =>
                TickerMode(enabled: active, child: child!),
            child: const CameraScreen(),
          ),
        ),
        GoRoute(
          path: '/review',
          builder: (context, state) {
            final result = state.extra! as ScanResult;
            return Scaffold(
              body: Text('review ${result.imagePath} ${result.error ?? 'ok'}'),
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cameraSourceProvider.overrideWithValue(source),
          imageCropServiceProvider.overrideWithValue(crops),
          manualCropperProvider.overrideWithValue(cropper),
          receiptScanServiceProvider.overrideWithValue(scans),
          pickGalleryImageProvider.overrideWithValue(() async => galleryPick),
          openAppSettingsProvider.overrideWithValue(() async {
            settingsOpened++;
            return true;
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder flashButton() => find.byKey(CameraScreen.flashButtonKey);
  IconData flashIcon(WidgetTester tester) => tester
      .widget<Icon>(
        find.descendant(of: flashButton(), matching: find.byType(Icon)),
      )
      .icon!;

  testWidgets(
    'shows the live preview with the receipt frame (FR-1.1, FR-1.4)',
    (tester) async {
      await pumpCamera(tester);

      expect(source.last!.initialized, isTrue);
      expect(find.byKey(const Key('fake-preview')), findsOneWidget);
      expect(find.byKey(CameraScreen.frameOverlayKey), findsOneWidget);
      expect(find.byKey(CameraScreen.shutterKey), findsOneWidget);
      expect(find.byKey(CameraScreen.galleryKey), findsOneWidget);
    },
  );

  testWidgets(
    'flash cycles off → auto → always → torch → off, icon follows (FR-1.2)',
    (tester) async {
      await pumpCamera(tester);
      expect(flashIcon(tester), Icons.flash_off);

      final expected = [
        (CaptureFlash.auto, Icons.flash_auto),
        (CaptureFlash.always, Icons.flash_on),
        (CaptureFlash.torch, Icons.flashlight_on),
        (CaptureFlash.off, Icons.flash_off),
      ];
      for (final (mode, icon) in expected) {
        await tester.tap(flashButton());
        await tester.pumpAndSettle();
        expect(source.last!.flashModes.last, mode);
        expect(flashIcon(tester), icon);
      }
    },
  );

  testWidgets('a camera without flash disables the button', (tester) async {
    source = FakeCameraSource(
      () => FakeReceiptCamera(flashError: const CameraError('no flash unit')),
    );
    await pumpCamera(tester);

    await tester.tap(flashButton());
    await tester.pumpAndSettle();

    expect(tester.widget<IconButton>(flashButton()).onPressed, isNull);
    expect(flashIcon(tester), Icons.flash_off);
    expect(find.text('Máy này không có đèn flash.'), findsOneWidget);
  });

  testWidgets(
    'tap to focus sends the preview point and shows the ring (FR-1.3)',
    (tester) async {
      await pumpCamera(tester);
      final preview = tester.getRect(find.byKey(CameraScreen.previewAreaKey));

      await tester.tapAt(preview.center);
      await tester.pump();

      final ring = find.byKey(CameraScreen.focusRingKey);
      expect(ring, findsOneWidget);
      expect(
        tester.getCenter(ring),
        offsetMoreOrLessEquals(preview.center, epsilon: 0.5),
      );
      final point = source.last!.focusPoints.single;
      expect(point.dx, closeTo(0.5, 0.01));
      expect(point.dy, closeTo(0.5, 0.01));
      expect(source.last!.exposurePoints.single, point);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(ring, findsNothing, reason: 'the ring fades away');
    },
  );

  testWidgets(
    'focus / exposure are only called when the camera supports them',
    (tester) async {
      source = FakeCameraSource(
        () => FakeReceiptCamera(focusPointSupported: false),
      );
      await pumpCamera(tester);

      await tester.tapAt(
        tester.getCenter(find.byKey(CameraScreen.previewAreaKey)),
      );
      await tester.pumpAndSettle();
      expect(source.last!.focusPoints, isEmpty);
      expect(source.last!.exposurePoints, hasLength(1));
    },
  );

  testWidgets('no focus or exposure point support: no ring, a short message', (
    tester,
  ) async {
    source = FakeCameraSource(
      () => FakeReceiptCamera(
        focusPointSupported: false,
        exposurePointSupported: false,
      ),
    );
    await pumpCamera(tester);

    await tester.tapAt(
      tester.getCenter(find.byKey(CameraScreen.previewAreaKey)),
    );
    await tester.pump();
    expect(find.byKey(CameraScreen.focusRingKey), findsNothing);
    expect(find.text('Máy này không hỗ trợ chạm để lấy nét.'), findsOneWidget);
  });

  testWidgets(
    'permission denied: explains, opens settings, still offers the gallery (FR-1.7)',
    (tester) async {
      source = FakeCameraSource(
        () =>
            FakeReceiptCamera(initializeError: const CameraPermissionDenied()),
      );
      await pumpCamera(tester);

      expect(find.text('Chưa có quyền dùng camera'), findsOneWidget);
      expect(find.textContaining('Cài đặt'), findsWidgets);
      expect(find.byKey(CameraScreen.shutterKey), findsNothing);

      await tester.tap(find.byKey(CameraScreen.openSettingsKey));
      await tester.pumpAndSettle();
      expect(settingsOpened, 1);
      expect(find.byKey(CameraScreen.galleryKey), findsOneWidget);
    },
  );

  testWidgets('coming back from settings retries the camera', (tester) async {
    var denied = true;
    source = FakeCameraSource(
      () => FakeReceiptCamera(
        initializeError: denied ? const CameraPermissionDenied() : null,
      ),
    );
    await pumpCamera(tester);
    expect(find.text('Chưa có quyền dùng camera'), findsOneWidget);

    denied = false; // the user allowed the camera in Settings
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fake-preview')), findsOneWidget);
    expect(source.last!.initialized, isTrue);
  });

  testWidgets('no camera: a message and the gallery still works (FR-1.6)', (
    tester,
  ) async {
    source = FakeCameraSource(() => null);
    await pumpCamera(tester);

    expect(find.text('Không tìm thấy camera'), findsOneWidget);
    await tester.tap(find.byKey(CameraScreen.galleryKey));
    await tester.pumpAndSettle();

    expect(crops.uprightCopies, ['/gallery/receipt.jpg']);
    expect(cropper.adjusted, ['/cache/upright_1.jpg']);
    expect(scans.scanned, ['/cache/upright_1.jpg.adjusted.jpg']);
    expect(
      find.text('review /cache/upright_1.jpg.adjusted.jpg ok'),
      findsOneWidget,
    );
  });

  testWidgets('cancelling the gallery picker changes nothing', (tester) async {
    galleryPick = null;
    await pumpCamera(tester);

    await tester.tap(find.byKey(CameraScreen.galleryKey));
    await tester.pumpAndSettle();
    expect(crops.uprightCopies, isEmpty);
    expect(scans.scanned, isEmpty);
  });

  testWidgets(
    'capture: crop to the frame, manual adjust, OCR, then /review (FR-1.5)',
    (tester) async {
      await pumpCamera(tester);
      final preview = tester.getRect(find.byKey(CameraScreen.previewAreaKey));
      final frame = tester.getRect(find.byKey(CameraScreen.frameOverlayKey));
      final camera = source.last!;

      await tester.tap(find.byKey(CameraScreen.shutterKey));
      await tester.pumpAndSettle();

      expect(camera.pictures, 1);
      final (path, request) = crops.frameCrops.single;
      expect(path, '/cache/capture_1.jpg');
      expect(request.viewport, preview.size);
      expect(request.previewAspectRatio, 9 / 16);
      expect(
        request.frame,
        FrameGeometry.receiptFrame(
          Size(preview.width, preview.height - CameraScreen.controlsHeight),
        ),
      );
      expect(
        frame.size,
        preview.size,
        reason: 'overlay covers the preview area',
      );
      expect(cropper.adjusted, ['/cache/cropped_1.jpg']);
      expect(scans.scanned, ['/cache/cropped_1.jpg.adjusted.jpg']);
      expect(
        camera.disposed,
        isTrue,
        reason: 'camera released before OCR and Review',
      );
      expect(
        find.text('review /cache/cropped_1.jpg.adjusted.jpg ok'),
        findsOneWidget,
      );

      // Back from Review: the camera is opened again.
      GoRouter.of(tester.element(find.textContaining('review'))).pop();
      await tester.pumpAndSettle();
      expect(source.opened, hasLength(2));
      expect(source.last!.initialized, isTrue);
    },
  );

  testWidgets(
    'cancelling the manual crop goes back to the camera without OCR',
    (tester) async {
      cropper.cancel = true;
      await pumpCamera(tester);

      await tester.tap(find.byKey(CameraScreen.shutterKey));
      await tester.pumpAndSettle();

      expect(scans.scanned, isEmpty);
      expect(find.text('Đã hủy quét.'), findsOneWidget);
      expect(source.last!.initialized, isTrue);
      expect(find.byKey(const Key('fake-preview')), findsOneWidget);
    },
  );

  testWidgets('an unreadable receipt offers manual entry with the photo', (
    tester,
  ) async {
    scans = _FakeScanService(fail: true);
    await pumpCamera(tester);

    await tester.tap(find.byKey(CameraScreen.shutterKey));
    await tester.pumpAndSettle();

    expect(find.textContaining('Không đọc được ảnh hóa đơn'), findsOneWidget);
    await tester.tap(find.text('Nhập tay'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        'review /cache/cropped_1.jpg.adjusted.jpg Không đọc được',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'releases the camera when the app goes inactive, reopens on resume (NFR-3)',
    (tester) async {
      await pumpCamera(tester);
      final first = source.last!;

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(first.disposed, isTrue);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(source.opened, hasLength(2));
      expect(source.last!.initialized, isTrue);
    },
  );

  testWidgets('releases the camera while its tab is hidden', (tester) async {
    await pumpCamera(tester);
    final first = source.last!;

    tabActive.value = false;
    await tester.pumpAndSettle();
    expect(first.disposed, isTrue);
    expect(source.opened, hasLength(1));

    tabActive.value = true;
    await tester.pumpAndSettle();
    expect(source.opened, hasLength(2));
    expect(source.last!.initialized, isTrue);
  });

  testWidgets('disposing the screen disposes the camera', (tester) async {
    await pumpCamera(tester);
    final camera = source.last!;

    await tester.pumpWidget(const SizedBox());
    expect(camera.disposed, isTrue);
  });

  testWidgets('no overflow in landscape', (tester) async {
    await pumpCamera(tester, physicalSize: const Size(1920, 1080));
    expect(tester.takeException(), isNull);
    expect(find.byKey(CameraScreen.shutterKey), findsOneWidget);
  });
}
