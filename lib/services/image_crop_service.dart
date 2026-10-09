import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:vku_expense_ocr/core/frame_geometry.dart';

/// What the camera screen showed when the photo was taken: enough to map
/// the alignment frame onto the photo (see [FrameGeometry.frameToImageCrop]).
@immutable
class FrameCropRequest {
  const FrameCropRequest({
    required this.frame,
    required this.viewport,
    required this.previewAspectRatio,
    this.padding = 0.03,
    this.deleteSource = false,
  });

  /// Alignment frame in viewport coordinates.
  final Rect frame;

  /// Size of the area showing the preview.
  final Size viewport;

  /// Preview width / height as displayed.
  final double previewAspectRatio;
  final double padding;

  /// Delete the full-size capture once the crop is written (camera photos
  /// are several MB in the cache folder).
  final bool deleteSource;
}

/// The photo could not be read or written. [message] is for the user.
class ImageCropException implements Exception {
  const ImageCropException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'ImageCropException: $message${cause == null ? '' : ' ($cause)'}';
}

/// Turns camera and gallery photos into upright JPEGs ready for OCR.
///
/// Decoding a 12 MP photo, applying its EXIF rotation and cropping take far
/// longer than a frame, so all of it runs in `Isolate.run` (NFR-2); only
/// paths and a few numbers cross the isolate boundary.
class ImageCropService {
  ImageCropService({Future<Directory> Function()? outputDirectory})
    : _output = outputDirectory ?? _defaultOutput;

  final Future<Directory> Function() _output;
  int _counter = 0;

  static Future<Directory> _defaultOutput() async =>
      Directory(p.join((await getTemporaryDirectory()).path, 'scan'));

  /// Crops a camera photo to the alignment frame (FR-1.5), after rotating it
  /// upright by its EXIF orientation, and returns the new file's path.
  Future<String> cropToFrame(String path, FrameCropRequest request) => _process(
    path,
    (stored, turns) => FrameGeometry.frameToImageCrop(
      frame: request.frame,
      viewport: request.viewport,
      previewAspectRatio: request.previewAspectRatio,
      storedImageSize: stored,
      quarterTurns: turns,
      padding: request.padding,
    ),
    deleteSource: request.deleteSource,
  );

  /// An upright copy of a gallery photo, uncropped (FR-1.6): the gallery
  /// photo was not taken through the frame, so the user crops it by hand.
  Future<String> uprightCopy(String path) => _process(
    path,
    (stored, turns) => Offset.zero & (turns.isOdd ? stored.flipped : stored),
  );

  Future<String> _process(
    String path,
    Rect Function(Size stored, int quarterTurns) cropFor, {
    bool deleteSource = false,
  }) async {
    final dir = await _output();
    await dir.create(recursive: true);
    final out = p.join(
      dir.path,
      'receipt_${DateTime.now().microsecondsSinceEpoch}_${_counter++}.jpg',
    );
    try {
      await Isolate.run(() {
        final source = File(path);
        File(out)
            .writeAsBytesSync(cropUpright(source.readAsBytesSync(), cropFor));
        if (deleteSource) source.deleteSync();
      });
    } on ImageCropException {
      rethrow;
    } on Exception catch (error) {
      throw ImageCropException('Không đọc được ảnh vừa chụp.', error);
    }
    return out;
  }
}

/// Decodes [bytes], asks [cropFor] for the crop (given the decoded size and
/// the EXIF quarter turns), rotates the photo upright, crops and encodes a
/// JPEG. The result carries no orientation tag, so every viewer and ML Kit
/// see the same upright pixels.
Uint8List cropUpright(
  List<int> bytes,
  Rect Function(Size stored, int quarterTurns) cropFor,
) {
  final img.Image? decoded;
  try {
    decoded = img.decodeImage(Uint8List.fromList(bytes));
  } on Object catch (error) {
    // Decoders throw RangeError on damaged files (see D-034).
    throw ImageCropException('Ảnh bị hỏng, không đọc được.', error);
  }
  if (decoded == null) {
    throw const ImageCropException('Tệp không phải là ảnh.');
  }
  final turns = FrameGeometry.quarterTurnsForExif(
    decoded.exif.imageIfd.orientation,
  );
  final rect = cropFor(
    Size(decoded.width.toDouble(), decoded.height.toDouble()),
    turns,
  );
  final upright = img.bakeOrientation(decoded);
  final cropped = img.copyCrop(
    upright,
    x: rect.left.round(),
    y: rect.top.round(),
    width: rect.width.round(),
    height: rect.height.round(),
  );
  return img.encodeJpg(cropped, quality: 92);
}
