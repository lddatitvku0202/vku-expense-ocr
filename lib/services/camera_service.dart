import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Flash settings offered by the camera screen, in the order the flash
/// button cycles through them (FR-1.2).
enum CaptureFlash {
  off,
  auto,
  always,
  torch;

  CaptureFlash get next => values[(index + 1) % values.length];

  FlashMode get pluginMode => switch (this) {
    off => FlashMode.off,
    auto => FlashMode.auto,
    always => FlashMode.always,
    torch => FlashMode.torch,
  };
}

/// Why the camera cannot be used. [message] is Vietnamese, for the user.
sealed class CameraFailure implements Exception {
  const CameraFailure();

  String get message;
}

/// The user refused camera access (FR-1.7).
final class CameraPermissionDenied extends CameraFailure {
  const CameraPermissionDenied();

  @override
  String get message =>
      'Ứng dụng cần quyền camera để chụp hóa đơn. Hãy mở Cài đặt, chọn '
      'Quyền, rồi cho phép Camera. Bạn vẫn có thể chọn ảnh từ thư viện.';
}

/// The device has no camera at all.
final class CameraUnavailable extends CameraFailure {
  const CameraUnavailable();

  @override
  String get message =>
      'Thiết bị này không có camera. Bạn vẫn có thể chọn ảnh hóa đơn từ '
      'thư viện.';
}

/// Anything else (camera busy, plugin missing, hardware error).
final class CameraError extends CameraFailure {
  const CameraError(this.details);

  /// Technical details for the log, not shown to the user.
  final String details;

  @override
  String get message =>
      'Không mở được camera. Hãy thử lại hoặc chọn ảnh từ thư viện.';

  @override
  String toString() => 'CameraError($details)';
}

/// Error codes the camera plugins use when access was refused: CameraX
/// on Android sends `CameraAccessDenied`; iOS also has the other two.
const Set<String> _permissionCodes = {
  'CameraAccessDenied',
  'CameraAccessDeniedWithoutPrompt',
  'CameraAccessRestricted',
};

/// Maps anything the camera plugin throws to a [CameraFailure].
CameraFailure cameraFailureFrom(Object error) => switch (error) {
  final CameraFailure failure => failure,
  CameraException(:final code) when _permissionCodes.contains(code) =>
    const CameraPermissionDenied(),
  CameraException(:final code, :final description) => CameraError(
    '$code: $description',
  ),
  _ => CameraError('$error'),
};

/// The back camera if there is one, otherwise the first camera.
CameraDescription? pickBackCamera(List<CameraDescription> cameras) {
  for (final camera in cameras) {
    if (camera.lensDirection == CameraLensDirection.back) return camera;
  }
  return cameras.isEmpty ? null : cameras.first;
}

/// The camera as the scan screen uses it. Wraps [CameraController] so the
/// screen can be widget-tested with a fake camera.
abstract interface class ReceiptCamera {
  /// Starts the camera; asks for permission the first time. Throws a
  /// [CameraFailure].
  Future<void> initialize();

  /// Width / height of the preview as displayed (portrait or landscape,
  /// following the device orientation).
  double get previewAspectRatio;

  bool get focusPointSupported;
  bool get exposurePointSupported;

  Widget buildPreview();

  /// Throws a [CameraFailure] when the device has no flash unit.
  Future<void> setFlash(CaptureFlash mode);

  /// [point] goes from (0, 0) top-left to (1, 1) bottom-right of the
  /// displayed preview.
  Future<void> setFocusPoint(Offset point);
  Future<void> setExposurePoint(Offset point);

  /// Takes a still photo and returns its file path.
  Future<String> takePicture();

  Future<void> dispose();
}

/// Opens cameras; replaced by a fake in tests.
abstract interface class CameraSource {
  /// The back camera, not yet initialized, or `null` when the device has
  /// no camera. Throws a [CameraFailure] when cameras cannot be listed.
  Future<ReceiptCamera?> openBackCamera();
}

class PluginCameraSource implements CameraSource {
  const PluginCameraSource();

  @override
  Future<ReceiptCamera?> openBackCamera() async {
    final List<CameraDescription> cameras;
    try {
      cameras = await availableCameras();
    } on Object catch (error) {
      throw cameraFailureFrom(error);
    }
    final camera = pickBackCamera(cameras);
    return camera == null ? null : PluginReceiptCamera(camera);
  }
}

/// [ReceiptCamera] on the `camera` plugin.
class PluginReceiptCamera implements ReceiptCamera {
  PluginReceiptCamera(CameraDescription description)
    : controller = CameraController(
        description,
        // 1080p-class stills: enough pixels for small receipt text.
        ResolutionPreset.veryHigh,
        // Stills only: no microphone permission (removed from the
        // manifest in Phase 1, D-014).
        enableAudio: false,
      );

  final CameraController controller;

  @override
  Future<void> initialize() async {
    try {
      await controller.initialize();
    } on Object catch (error) {
      throw cameraFailureFrom(error);
    }
  }

  @override
  double get previewAspectRatio {
    final value = controller.value;
    final orientation =
        value.lockedCaptureOrientation ?? value.deviceOrientation;
    final landscape =
        orientation == DeviceOrientation.landscapeLeft ||
        orientation == DeviceOrientation.landscapeRight;
    // value.aspectRatio is the sensor's landscape ratio; CameraPreview
    // rotates the stream the same way.
    return landscape ? value.aspectRatio : 1 / value.aspectRatio;
  }

  @override
  bool get focusPointSupported => controller.value.focusPointSupported;

  @override
  bool get exposurePointSupported => controller.value.exposurePointSupported;

  @override
  Widget buildPreview() => CameraPreview(controller);

  @override
  Future<void> setFlash(CaptureFlash mode) async {
    try {
      await controller.setFlashMode(mode.pluginMode);
    } on Object catch (error) {
      throw cameraFailureFrom(error);
    }
  }

  @override
  Future<void> setFocusPoint(Offset point) => controller.setFocusPoint(point);

  @override
  Future<void> setExposurePoint(Offset point) =>
      controller.setExposurePoint(point);

  @override
  Future<String> takePicture() async {
    try {
      return (await controller.takePicture()).path;
    } on Object catch (error) {
      throw cameraFailureFrom(error);
    }
  }

  @override
  Future<void> dispose() => controller.dispose();
}
