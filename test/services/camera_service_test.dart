import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/services/camera_service.dart';

void main() {
  group('cameraFailureFrom', () {
    test('permission codes of Android (CameraX) and iOS become CameraPermissionDenied', () {
      for (final code in [
        'CameraAccessDenied',
        'CameraAccessDeniedWithoutPrompt',
        'CameraAccessRestricted',
      ]) {
        expect(
          cameraFailureFrom(CameraException(code, 'denied')),
          isA<CameraPermissionDenied>(),
          reason: code,
        );
      }
    });

    test('other camera errors keep their code in the details', () {
      final failure = cameraFailureFrom(
        CameraException('CameraPermissionsRequestOngoing', 'busy'),
      );
      expect(failure, isA<CameraError>());
      expect(
        (failure as CameraError).details,
        contains('CameraPermissionsRequestOngoing'),
      );
    });

    test('a missing plugin (tests, unsupported platform) is a CameraError', () {
      expect(
        cameraFailureFrom(MissingPluginException('no camera plugin')),
        isA<CameraError>(),
      );
    });

    test('failures already mapped are returned unchanged', () {
      const failure = CameraUnavailable();
      expect(cameraFailureFrom(failure), same(failure));
    });

    test('every failure has a Vietnamese message for the user', () {
      for (final failure in const [
        CameraPermissionDenied(),
        CameraUnavailable(),
        CameraError('x'),
      ]) {
        expect(failure.message, isNotEmpty);
      }
    });
  });

  group('PluginReceiptCamera', () {
    const back = CameraDescription(
      name: '0',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 90,
    );

    test('never records audio (enableAudio: false, D-014)', () {
      final camera = PluginReceiptCamera(back);
      expect(camera.controller.enableAudio, isFalse);
    });

    test('asks for a high resolution for OCR', () {
      final camera = PluginReceiptCamera(back);
      expect(camera.controller.resolutionPreset, ResolutionPreset.veryHigh);
    });
  });

  test('CaptureFlash maps onto the plugin FlashMode', () {
    expect(CaptureFlash.off.pluginMode, FlashMode.off);
    expect(CaptureFlash.auto.pluginMode, FlashMode.auto);
    expect(CaptureFlash.always.pluginMode, FlashMode.always);
    expect(CaptureFlash.torch.pluginMode, FlashMode.torch);
    expect(CaptureFlash.torch.next, CaptureFlash.off);
    expect(CaptureFlash.off.next, CaptureFlash.auto);
  });

  test('pickBackCamera prefers the back lens, falls back to the first', () {
    const front = CameraDescription(
      name: '1',
      lensDirection: CameraLensDirection.front,
      sensorOrientation: 270,
    );
    const back = CameraDescription(
      name: '0',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 90,
    );
    expect(pickBackCamera(const [front, back]), back);
    expect(pickBackCamera(const [front]), front);
    expect(pickBackCamera(const []), isNull);
  });
}
