import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:vku_expense_ocr/models/expense.dart';

/// Paths of a receipt photo copied into app storage and its thumbnail.
typedef StoredReceipt = ({String imagePath, String thumbPath});

/// A receipt photo could not be stored. [message] is shown to the user.
class ImageStorageException implements Exception {
  const ImageStorageException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'ImageStorageException: $message${cause == null ? '' : ' ($cause)'}';
}

/// Keeps receipt photos in `<app documents>/receipts/` (FR-5.3, FR-5.4).
///
/// The database stores only the paths returned by [save]. Thumbnails are
/// decoded, resized and encoded on a background isolate because decoding
/// a 12 MP JPEG takes far longer than a frame (NFR-2, W7 s30).
class ImageStorageService {
  ImageStorageService({Future<Directory> Function()? documentsDirectory})
    : _documents = documentsDirectory ?? getApplicationDocumentsDirectory;

  static const String folderName = 'receipts';

  /// Width of list thumbnails in pixels; the height keeps the aspect ratio.
  static const int thumbnailWidth = 256;

  final Future<Directory> Function() _documents;
  int _counter = 0;

  Future<Directory> receiptsDirectory() async =>
      Directory(p.join((await _documents()).path, folderName));

  /// Copies the photo at [sourcePath] (for example the cropper's output in
  /// the cache folder) into the receipts folder and writes its JPEG
  /// thumbnail next to it.
  ///
  /// Throws [ImageStorageException] when the source is missing or is not a
  /// readable image; no partial files are left behind.
  Future<StoredReceipt> save(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw ImageStorageException('Không tìm thấy ảnh hóa đơn: $sourcePath');
    }
    final dir = await receiptsDirectory();
    await dir.create(recursive: true);

    final name =
        'receipt_${DateTime.now().microsecondsSinceEpoch}_${_counter++}';
    final extension = p.extension(sourcePath).toLowerCase();
    final imagePath = p.join(
      dir.path,
      '$name${extension.isEmpty ? '.jpg' : extension}',
    );
    final thumbPath = p.join(dir.path, '${name}_thumb.jpg');

    try {
      await source.copy(imagePath);
      await Isolate.run(
        () => _writeThumbnail(imagePath, thumbPath, thumbnailWidth),
      );
    } on Exception catch (error) {
      await delete([imagePath, thumbPath]);
      if (error is ImageStorageException) rethrow;
      throw ImageStorageException('Không lưu được ảnh hóa đơn.', error);
    }
    return (imagePath: imagePath, thumbPath: thumbPath);
  }

  /// Deletes the given files. `null` paths and files that are already gone
  /// are skipped, so deleting an expense never fails because of a lost
  /// photo. Paths outside the receipts folder are never deleted.
  Future<void> delete(Iterable<String?> paths) async {
    final root = p.canonicalize((await receiptsDirectory()).path);
    for (final path in paths) {
      if (path == null) continue;
      if (!p.isWithin(root, p.canonicalize(path))) {
        developer.log(
          'Refusing to delete $path outside $root',
          name: 'vku_expense_ocr.storage',
        );
        continue;
      }
      try {
        await File(path).delete();
      } on PathNotFoundException {
        // Already gone: nothing to do.
      }
    }
  }

  /// Deletes the photo and thumbnail of [expense] (FR-5.4).
  Future<void> deleteFilesOf(Expense expense) =>
      delete([expense.imagePath, expense.thumbPath]);
}

/// Runs on the background isolate: reads, shrinks and writes in one go so
/// only two paths cross the isolate boundary, not megabytes of pixels.
void _writeThumbnail(String imagePath, String thumbPath, int width) {
  final bytes = File(imagePath).readAsBytesSync();
  File(thumbPath).writeAsBytesSync(createThumbnail(bytes, width: width));
}

/// Encodes a JPEG at most [width] pixels wide from image [bytes] in any
/// format the `image` package reads. The EXIF orientation is applied first
/// so phone photos come out upright; smaller images are not enlarged.
Uint8List createThumbnail(List<int> bytes, {required int width}) {
  final img.Image? decoded;
  try {
    decoded = img.decodeImage(Uint8List.fromList(bytes));
  } on Object catch (error) {
    // Decoders throw RangeError and friends on truncated or random bytes;
    // a damaged photo is bad input, not a bug, so report it to the user.
    throw ImageStorageException('Ảnh hóa đơn bị hỏng.', error);
  }
  if (decoded == null) {
    throw const ImageStorageException('Tệp không phải là ảnh.');
  }
  final upright = img.bakeOrientation(decoded);
  final small = upright.width > width
      ? img.copyResize(
          upright,
          width: width,
          interpolation: img.Interpolation.average,
        )
      : upright;
  return img.encodeJpg(small, quality: 85);
}
