import 'package:image_cropper/image_cropper.dart';

/// Lets the user adjust the crop by hand (FR-1.5).
abstract interface class ManualCropper {
  /// Returns the path of the adjusted photo, or `null` when the user
  /// cancelled.
  Future<String?> adjust(String path);
}

/// [ManualCropper] on the `image_cropper` plugin (uCrop on Android, see the
/// `UCropActivity` in AndroidManifest.xml, D-014).
class ImageCropperManualCropper implements ManualCropper {
  const ImageCropperManualCropper();

  @override
  Future<String?> adjust(String path) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: path,
      compressQuality: 92,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Chỉnh vùng cắt',
          lockAspectRatio: false,
          initAspectRatio: CropAspectRatioPreset.original,
        ),
        IOSUiSettings(title: 'Chỉnh vùng cắt'),
      ],
    );
    return cropped?.path;
  }
}
