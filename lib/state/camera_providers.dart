import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vku_expense_ocr/services/camera_service.dart';
import 'package:vku_expense_ocr/services/image_crop_service.dart';
import 'package:vku_expense_ocr/services/manual_cropper.dart';

/// Opens the device camera; a fake in widget tests.
final cameraSourceProvider = Provider<CameraSource>(
  (ref) => const PluginCameraSource(),
);

final imageCropServiceProvider = Provider<ImageCropService>(
  (ref) => ImageCropService(),
);

/// `image_cropper` screen for adjusting the crop by hand (FR-1.5).
final manualCropperProvider = Provider<ManualCropper>(
  (ref) => const ImageCropperManualCropper(),
);

/// Opens this app's page in the system Settings, where a refused camera
/// permission can be granted again (FR-1.7).
final openAppSettingsProvider = Provider<Future<bool> Function()>(
  (ref) => openAppSettings,
);
