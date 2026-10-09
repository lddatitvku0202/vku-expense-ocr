import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vku_expense_ocr/core/frame_geometry.dart';
import 'package:vku_expense_ocr/core/router.dart';
import 'package:vku_expense_ocr/models/parsed_receipt.dart';
import 'package:vku_expense_ocr/services/camera_service.dart';
import 'package:vku_expense_ocr/services/image_crop_service.dart';
import 'package:vku_expense_ocr/services/receipt_scan_service.dart';
import 'package:vku_expense_ocr/state/camera_providers.dart';
import 'package:vku_expense_ocr/state/ocr_providers.dart';
import 'package:vku_expense_ocr/state/scan_controller.dart';
import 'package:vku_expense_ocr/widgets/receipt_frame_overlay.dart';
import 'package:vku_expense_ocr/widgets/state_message.dart';

/// "Quét" tab: live viewfinder with flash, tap to focus and the receipt
/// frame (FR-1.1 to FR-1.7).
///
/// Flash, focus ring and camera status are ephemeral UI state kept in
/// `setState` (W8 s4–6); the scan itself goes through
/// `scanControllerProvider`.
///
/// The camera is held only while it can be seen: it is released when the
/// app goes to the background, when another tab is shown (StatefulShellRoute
/// turns TickerMode off for hidden tabs) and while a photo is cropped,
/// read or reviewed (NFR-3).
class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  static const Key flashButtonKey = Key('camera-flash');
  static const Key shutterKey = Key('camera-shutter');
  static const Key galleryKey = Key('camera-gallery');
  static const Key previewAreaKey = Key('camera-preview-area');
  static const Key frameOverlayKey = Key('camera-frame-overlay');
  static const Key focusRingKey = Key('camera-focus-ring');
  static const Key openSettingsKey = Key('camera-open-settings');

  /// Height of the shutter bar at the bottom; the frame stays above it.
  static const double controlsHeight = 112;

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

enum _Status { starting, ready, released, denied, noCamera, failed }

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  ReceiptCamera? _camera;
  _Status _status = _Status.starting;
  CameraFailure? _failure;

  CaptureFlash _flash = CaptureFlash.off;
  bool _flashAvailable = true;
  Offset? _focusPoint;
  Timer? _focusTimer;

  /// A photo is being taken, cropped, read or reviewed.
  bool _busy = false;

  /// The app itself is working (taking or cropping the photo), as opposed
  /// to waiting for the user in the cropper, a dialog or Review. Only then
  /// is the progress overlay shown.
  bool _working = false;
  bool _starting = false;
  bool _visible = true;
  bool _appActive = true;

  /// Bumped on every release so a camera that finishes starting after the
  /// screen was hidden is closed instead of used.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    final first = _generation == 0 && _camera == null && !_starting;
    if (visible == _visible && !first) return;
    _visible = visible;
    if (visible) {
      unawaited(_start());
    } else {
      unawaited(_release());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _appActive = true;
        unawaited(_start());
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _appActive = false;
        // Not while starting: the system permission dialog also makes the
        // app inactive, and closing the camera then would ask again.
        if (!_starting) unawaited(_release());
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusTimer?.cancel();
    _generation++;
    final camera = _camera;
    _camera = null;
    if (camera != null) unawaited(_disposeQuietly(camera));
    super.dispose();
  }

  // --- Camera lifecycle ------------------------------------------------------

  Future<void> _start() async {
    if (!_visible || !_appActive || _busy || _starting || _camera != null) {
      return;
    }
    _starting = true;
    final generation = ++_generation;
    if (mounted) setState(() => _status = _Status.starting);

    ReceiptCamera? camera;
    try {
      camera = await ref.read(cameraSourceProvider).openBackCamera();
      if (camera == null) {
        _finishStart(generation, _Status.noCamera, const CameraUnavailable());
        return;
      }
      await camera.initialize();
    } on CameraFailure catch (failure) {
      if (camera != null) await _disposeQuietly(camera);
      developer.log('Camera failed: $failure', name: 'vku_expense_ocr.camera');
      _finishStart(
        generation,
        failure is CameraPermissionDenied ? _Status.denied : _Status.failed,
        failure,
      );
      return;
    }

    if (generation != _generation || !mounted) {
      _starting = false;
      await _disposeQuietly(camera);
      return;
    }
    if (!_appActive || !_visible) {
      // Finished starting while the app was in the background (e.g. behind
      // the permission dialog) or the tab was hidden: close it again.
      _finishStart(generation, _Status.released, null);
      await _disposeQuietly(camera);
      return;
    }
    _camera = camera;
    _finishStart(generation, _Status.ready, null);
  }

  void _finishStart(int generation, _Status status, CameraFailure? failure) {
    _starting = false;
    if (generation != _generation || !mounted) return;
    setState(() {
      _status = status;
      _failure = failure;
      // A reopened camera starts with the flash off.
      _flash = CaptureFlash.off;
      _flashAvailable = true;
    });
  }

  Future<void> _release() async {
    _generation++;
    _starting = false;
    _focusTimer?.cancel();
    final camera = _camera;
    _camera = null;
    if (mounted && (_status == _Status.ready || _status == _Status.starting)) {
      setState(() {
        _status = _Status.released;
        _focusPoint = null;
      });
    }
    if (camera != null) await _disposeQuietly(camera);
  }

  static Future<void> _disposeQuietly(ReceiptCamera camera) async {
    try {
      await camera.dispose();
    } on Object catch (error) {
      developer.log(
        'Camera dispose failed',
        name: 'vku_expense_ocr.camera',
        error: error,
      );
    }
  }

  // --- Controls --------------------------------------------------------------

  Future<void> _cycleFlash() async {
    final camera = _camera;
    if (camera == null) return;
    final next = _flash.next;
    try {
      await camera.setFlash(next);
      if (mounted) setState(() => _flash = next);
    } on CameraFailure {
      // The plugin cannot tell in advance whether there is a flash unit;
      // the first refusal disables the button for this camera (D-045).
      if (!mounted) return;
      setState(() {
        _flash = CaptureFlash.off;
        _flashAvailable = false;
      });
      _showMessage('Máy này không có đèn flash.');
    }
  }

  void _focusAt(Offset position, Size viewport) {
    final camera = _camera;
    if (camera == null) return;
    final focus = camera.focusPointSupported;
    final exposure = camera.exposurePointSupported;
    if (!focus && !exposure) {
      _showMessage('Máy này không hỗ trợ chạm để lấy nét.');
      return;
    }
    final point = FrameGeometry.viewportToNormalized(
      position,
      Size(camera.previewAspectRatio, 1),
      viewport,
    );
    if (focus) unawaited(_quietly(camera.setFocusPoint(point)));
    if (exposure) unawaited(_quietly(camera.setExposurePoint(point)));

    setState(() => _focusPoint = position);
    _focusTimer?.cancel();
    _focusTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _focusPoint = null);
    });
  }

  static Future<void> _quietly(Future<void> call) async {
    try {
      await call;
    } on Object catch (error) {
      developer.log(
        'Focus / exposure failed',
        name: 'vku_expense_ocr.camera',
        error: error,
      );
    }
  }

  Future<void> _capture(Rect frame, Size viewport) async {
    final camera = _camera;
    if (camera == null || _busy) return;
    final aspect = camera.previewAspectRatio;
    setState(() => _busy = _working = true);
    try {
      final photo = await camera.takePicture();
      final cropped = await ref
          .read(imageCropServiceProvider)
          .cropToFrame(
            photo,
            FrameCropRequest(
              frame: frame,
              viewport: viewport,
              previewAspectRatio: aspect,
              deleteSource: true,
            ),
          );
      // The cropper, OCR and Review need memory; the camera is reopened
      // when the user comes back.
      await _release();
      _stopWorking();
      await _adjustScanAndReview(cropped);
    } on CameraFailure catch (failure) {
      _showMessage(failure.message);
    } on ImageCropException catch (error) {
      _showMessage(error.message);
    } finally {
      _finishBusy();
    }
  }

  Future<void> _pickFromGallery() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final picked = await ref.read(pickGalleryImageProvider)();
      if (picked == null || !mounted) return;
      setState(() => _working = true);
      await _release();
      final upright = await ref
          .read(imageCropServiceProvider)
          .uprightCopy(picked);
      _stopWorking();
      await _adjustScanAndReview(upright);
    } on ImageCropException catch (error) {
      _showMessage(error.message);
    } finally {
      _finishBusy();
    }
  }

  void _stopWorking() {
    if (mounted) setState(() => _working = false);
  }

  void _finishBusy() {
    if (!mounted) return;
    setState(() => _busy = _working = false);
    unawaited(_start());
  }

  /// Manual crop (FR-1.5) → OCR → Review. Returns when the user is back on
  /// this screen.
  Future<void> _adjustScanAndReview(String path) async {
    final adjusted = await ref.read(manualCropperProvider).adjust(path);
    if (!mounted) return;
    if (adjusted == null) {
      _showMessage('Đã hủy quét.');
      return;
    }

    final scan = ref.read(scanControllerProvider.notifier);
    await scan.scan(adjusted);
    if (!mounted) return;
    final outcome = ref.read(scanControllerProvider);
    switch (outcome) {
      case ScanCompleted(:final result):
        await context.push(AppRoutes.review, extra: result);
      case ScanFailed(:final message, :final imagePath):
        final manual = await _askManualEntry(message);
        if (manual && mounted) {
          await context.push(
            AppRoutes.review,
            extra: ScanResult(
              imagePath: imagePath,
              receipt: const ParsedReceipt.empty(),
              rows: const [],
              ocrDuration: Duration.zero,
              error: message,
            ),
          );
        }
      case ScanIdle() || ScanProcessing():
        break;
    }
    scan.reset();
  }

  Future<bool> _askManualEntry(String message) async {
    final manual = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error_outline),
        title: const Text('Không đọc được hóa đơn'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Chụp lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Nhập tay'),
          ),
        ],
      ),
    );
    return manual ?? false;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // --- UI --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final processing = ref.watch(
      scanControllerProvider.select((s) => s is ScanProcessing),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét hóa đơn'),
        actions: [
          IconButton(
            key: CameraScreen.flashButtonKey,
            tooltip: _flashAvailable
                ? 'Đèn flash: ${_flashLabel(_flash)}'
                : 'Không có đèn flash',
            onPressed: _camera != null && _flashAvailable && !_busy
                ? _cycleFlash
                : null,
            icon: Icon(_flashIcon(_flash)),
          ),
          // TEMPORARY (Phase 3): removed with the debug screen in Phase 7.
          IconButton(
            tooltip: 'Thử OCR (debug)',
            onPressed: () => context.push(AppRoutes.ocrDebug),
            icon: const Icon(Icons.bug_report_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: switch (_status) {
          _Status.denied => _failureView(
            icon: Icons.no_photography_outlined,
            title: 'Chưa có quyền dùng camera',
            showSettings: true,
          ),
          _Status.noCamera => _failureView(
            icon: Icons.videocam_off_outlined,
            title: 'Không tìm thấy camera',
          ),
          _Status.failed => _failureView(
            icon: Icons.error_outline,
            title: 'Không mở được camera',
            showRetry: true,
          ),
          _Status.starting ||
          _Status.ready ||
          _Status.released => _viewfinder(processing: processing),
        },
      ),
    );
  }

  Widget _failureView({
    required IconData icon,
    required String title,
    bool showSettings = false,
    bool showRetry = false,
  }) {
    return StateMessage(
      icon: icon,
      title: title,
      message: _failure?.message,
      action: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          if (showSettings)
            FilledButton.icon(
              key: CameraScreen.openSettingsKey,
              onPressed: () => ref.read(openAppSettingsProvider)(),
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Mở Cài đặt'),
            ),
          if (showRetry)
            FilledButton.icon(
              onPressed: () => unawaited(_start()),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          OutlinedButton.icon(
            key: CameraScreen.galleryKey,
            onPressed: _busy ? null : _pickFromGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Chọn ảnh từ thư viện'),
          ),
        ],
      ),
    );
  }

  Widget _viewfinder({required bool processing}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.biggest;
        final frame = FrameGeometry.receiptFrame(
          Size(
            viewport.width,
            math.max(1, viewport.height - CameraScreen.controlsHeight),
          ),
        );
        final camera = _camera;
        return Stack(
          children: [
            Positioned.fill(
              key: CameraScreen.previewAreaKey,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) => _focusAt(details.localPosition, viewport),
                child: ColoredBox(
                  color: Colors.black,
                  child: camera != null && _status == _Status.ready
                      ? ClipRect(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: 1000 * camera.previewAspectRatio,
                              height: 1000,
                              child: camera.buildPreview(),
                            ),
                          ),
                        )
                      : const SizedBox.expand(),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  key: CameraScreen.frameOverlayKey,
                  painter: ReceiptFramePainter(
                    frame: frame,
                    scrimColor: Colors.black54,
                    borderColor: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: math.max(4, frame.top - 32),
              child: const IgnorePointer(
                child: Text(
                  'Đặt hóa đơn nằm trọn trong khung',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            if (_focusPoint case final point?)
              Positioned(
                left: point.dx - _FocusRing.size / 2,
                top: point.dy - _FocusRing.size / 2,
                child: const IgnorePointer(
                  child: _FocusRing(key: CameraScreen.focusRingKey),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: CameraScreen.controlsHeight,
              child: _ShutterBar(
                onGallery: _busy ? null : _pickFromGallery,
                onShutter: camera != null && !_busy
                    ? () => _capture(frame, viewport)
                    : null,
              ),
            ),
            if (_status == _Status.starting && !_busy)
              const Center(child: CircularProgressIndicator()),
            if (_working || processing)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(
                          processing ? 'Đang đọc hóa đơn…' : 'Đang xử lý ảnh…',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static IconData _flashIcon(CaptureFlash mode) => switch (mode) {
    CaptureFlash.off => Icons.flash_off,
    CaptureFlash.auto => Icons.flash_auto,
    CaptureFlash.always => Icons.flash_on,
    CaptureFlash.torch => Icons.flashlight_on,
  };

  static String _flashLabel(CaptureFlash mode) => switch (mode) {
    CaptureFlash.off => 'tắt',
    CaptureFlash.auto => 'tự động',
    CaptureFlash.always => 'luôn bật',
    CaptureFlash.torch => 'đèn pin',
  };
}

class _ShutterBar extends StatelessWidget {
  const _ShutterBar({required this.onGallery, required this.onShutter});

  final VoidCallback? onGallery;
  final VoidCallback? onShutter;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton.filledTonal(
          key: CameraScreen.galleryKey,
          tooltip: 'Chọn ảnh từ thư viện',
          iconSize: 28,
          onPressed: onGallery,
          icon: const Icon(Icons.photo_library_outlined),
        ),
        Semantics(
          button: true,
          label: 'Chụp hóa đơn',
          child: GestureDetector(
            key: CameraScreen.shutterKey,
            onTap: onShutter,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: onShutter == null ? 0.4 : 1,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                padding: const EdgeInsets.all(5),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Keeps the shutter centred.
        const SizedBox(width: 48),
      ],
    );
  }
}

/// Focus indicator drawn where the user tapped (FR-1.3).
class _FocusRing extends StatelessWidget {
  const _FocusRing({super.key});

  static const double size = 72;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.4, end: 1),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.amber, width: 2),
        ),
      ),
    );
  }
}
