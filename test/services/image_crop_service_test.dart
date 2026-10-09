import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:vku_expense_ocr/core/frame_geometry.dart';
import 'package:vku_expense_ocr/services/image_crop_service.dart';

void main() {
  late Directory tempDir;
  late ImageCropService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('vku_crop_test_');
    service = ImageCropService(outputDirectory: () async => tempDir);
  });

  tearDown(() => tempDir.delete(recursive: true));

  /// A 1080 x 1920 upright test photo: white with a red 100 x 100 square in
  /// the top-left corner, so orientation and position can be checked.
  img.Image uprightPhoto() {
    final image = img.Image(width: 1080, height: 1920);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));
    img.fillRect(
      image,
      x1: 0,
      y1: 0,
      x2: 99,
      y2: 99,
      color: img.ColorRgb8(255, 0, 0),
    );
    return image;
  }

  /// Stores [upright] the way a phone camera does: pixels rotated to the
  /// sensor's orientation plus an EXIF tag that tells viewers how to turn it
  /// back.
  String storeWithExif(img.Image upright, int orientation) {
    final stored = switch (orientation) {
      6 => img.copyRotate(upright, angle: -90), // shown after turning 90° cw
      3 => img.copyRotate(upright, angle: 180),
      8 => img.copyRotate(upright, angle: 90),
      _ => upright,
    };
    stored.exif.imageIfd.orientation = orientation;
    final path = p.join(tempDir.path, 'photo_$orientation.jpg');
    File(path).writeAsBytesSync(img.encodeJpg(stored, quality: 95));
    return path;
  }

  bool isRed(img.Pixel px) => px.r > 200 && px.g < 80 && px.b < 80;

  const viewport = Size(360, 640);
  const frame = Rect.fromLTWH(0, 0, 180, 320); // top-left quarter

  group('cropToFrame (FR-1.5)', () {
    test('returns a JPEG of the mapped size', () async {
      final source = storeWithExif(uprightPhoto(), 1);
      final out = await service.cropToFrame(
        source,
        FrameCropRequest(
          frame: const Rect.fromLTWH(40, 80, 280, 480),
          viewport: viewport,
          previewAspectRatio: 9 / 16,
          padding: 0,
        ),
      );

      expect(p.isWithin(tempDir.path, out), isTrue);
      final cropped = img.decodeJpg(File(out).readAsBytesSync())!;
      expect((cropped.width, cropped.height), (840, 1440));
    });

    for (final orientation in [1, 6, 3, 8]) {
      test(
        'EXIF orientation $orientation is applied before cropping',
        () async {
          final source = storeWithExif(uprightPhoto(), orientation);
          final out = await service.cropToFrame(
            source,
            const FrameCropRequest(
              frame: frame,
              viewport: viewport,
              previewAspectRatio: 9 / 16,
              padding: 0,
            ),
          );

          final cropped = img.decodeJpg(File(out).readAsBytesSync())!;
          expect((cropped.width, cropped.height), (540, 960));
          expect(
            isRed(cropped.getPixel(20, 20)),
            isTrue,
            reason: 'red corner stays top-left',
          );
          expect(isRed(cropped.getPixel(500, 900)), isFalse);
          expect(
            cropped.exif.imageIfd.orientation ?? 1,
            1,
            reason: 'no rotation left to apply',
          );
        },
      );
    }

    test('an unreadable photo throws ImageCropException', () async {
      final source = p.join(tempDir.path, 'broken.jpg');
      File(source).writeAsStringSync('not a jpeg');

      await expectLater(
        service.cropToFrame(
          source,
          const FrameCropRequest(
            frame: frame,
            viewport: viewport,
            previewAspectRatio: 9 / 16,
          ),
        ),
        throwsA(isA<ImageCropException>()),
      );
    });
  });

  group('uprightCopy (gallery photos, FR-1.6)', () {
    test(
      'bakes the EXIF rotation into the pixels and keeps the full photo',
      () async {
        final source = storeWithExif(uprightPhoto(), 6);
        final out = await service.uprightCopy(source);

        final copy = img.decodeJpg(File(out).readAsBytesSync())!;
        expect((copy.width, copy.height), (1080, 1920));
        expect(isRed(copy.getPixel(20, 20)), isTrue);
      },
    );
  });

  group('cropUpright (pure)', () {
    test('uses the decoded size and EXIF turns to pick the crop', () {
      final bytes = img.encodeJpg(
        img.copyRotate(uprightPhoto(), angle: -90)
          ..exif.imageIfd.orientation = 6,
      );
      Size? seenStored;
      int? seenTurns;
      final out = cropUpright(bytes, (stored, turns) {
        seenStored = stored;
        seenTurns = turns;
        return const Rect.fromLTWH(0, 0, 100, 100);
      });

      expect(seenStored, const Size(1920, 1080));
      expect(seenTurns, FrameGeometry.quarterTurnsForExif(6));
      final cropped = img.decodeJpg(out)!;
      expect((cropped.width, cropped.height), (100, 100));
      expect(isRed(cropped.getPixel(50, 50)), isTrue);
    });
  });
}
