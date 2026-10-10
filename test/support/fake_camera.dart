import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:vku_expense_ocr/services/camera_service.dart';
import 'package:vku_expense_ocr/services/image_crop_service.dart';
import 'package:vku_expense_ocr/services/manual_cropper.dart';

/// Camera double for widget tests (test/ only): records every call and can
/// be told to fail like a real device would.
class FakeReceiptCamera implements ReceiptCamera {
  FakeReceiptCamera({
    this.focusPointSupported = true,
    this.exposurePointSupported = true,
    this.previewAspectRatio = 9 / 16,
    this.initializeError,
    this.flashError,
    this.initializeGate,
  });

  @override
  final bool focusPointSupported;
  @override
  final bool exposurePointSupported;
  @override
  final double previewAspectRatio;

  /// Thrown by [initialize], e.g. [CameraPermissionDenied].
  final CameraFailure? initializeError;

  /// Thrown by [setFlash] for any mode but off (a device without flash).
  final CameraFailure? flashError;

  /// When set, [initialize] waits for it (a camera that is still opening).
  final Future<void>? initializeGate;

  bool initialized = false;
  bool disposed = false;
  final List<CaptureFlash> flashModes = [];
  final List<Offset> focusPoints = [];
  final List<Offset> exposurePoints = [];
  int pictures = 0;

  @override
  Future<void> initialize() async {
    if (initializeGate case final gate?) await gate;
    if (initializeError case final error?) throw error;
    initialized = true;
  }

  @override
  Widget buildPreview() =>
      const ColoredBox(key: Key('fake-preview'), color: Color(0xFF000000));

  @override
  Future<void> setFlash(CaptureFlash mode) async {
    if (mode != CaptureFlash.off && flashError != null) throw flashError!;
    flashModes.add(mode);
  }

  @override
  Future<void> setFocusPoint(Offset point) async => focusPoints.add(point);

  @override
  Future<void> setExposurePoint(Offset point) async =>
      exposurePoints.add(point);

  @override
  Future<String> takePicture() async => '/cache/capture_${++pictures}.jpg';

  @override
  Future<void> dispose() async => disposed = true;
}

/// Hands out a new [FakeReceiptCamera] on every open, like reopening the
/// real camera after the app comes back to the foreground.
class FakeCameraSource implements CameraSource {
  FakeCameraSource(this.create);

  /// Returns `null` to simulate a device without a camera.
  final FakeReceiptCamera? Function() create;
  final List<FakeReceiptCamera> opened = [];

  FakeReceiptCamera? get last => opened.isEmpty ? null : opened.last;

  @override
  Future<ReceiptCamera?> openBackCamera() async {
    final camera = create();
    if (camera != null) opened.add(camera);
    return camera;
  }
}

/// Crop service double: no decoding, just records requests.
class FakeImageCropService implements ImageCropService {
  final List<(String, FrameCropRequest)> frameCrops = [];
  final List<String> uprightCopies = [];

  @override
  Future<String> cropToFrame(String path, FrameCropRequest request) async {
    frameCrops.add((path, request));
    return '/cache/cropped_${frameCrops.length}.jpg';
  }

  @override
  Future<String> uprightCopy(String path) async {
    uprightCopies.add(path);
    return '/cache/upright_${uprightCopies.length}.jpg';
  }
}

/// image_cropper double: returns a fixed path or `null` (user cancelled).
class FakeManualCropper implements ManualCropper {
  FakeManualCropper({this.cancel = false});

  bool cancel;
  final List<String> adjusted = [];

  @override
  Future<String?> adjust(String path) async {
    adjusted.add(path);
    return cancel ? null : '$path.adjusted.jpg';
  }
}
