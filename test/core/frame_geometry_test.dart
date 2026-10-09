import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/core/frame_geometry.dart';

/// Viewports of common phones in portrait, logical pixels.
const _viewports = {
  '16:9': Size(360, 640),
  '4:3': Size(600, 800),
  '20:9': Size(360, 800),
};

/// Preview aspect ratios as displayed in portrait (width / height).
const _previewAspects = {'9:16': 9 / 16, '3:4': 3 / 4, '9:20': 9 / 20};

/// Stored photo sizes (as written by the camera, before EXIF rotation).
const _photos = {
  '4000x3000': Size(4000, 3000),
  '1920x1080': Size(1920, 1080),
  '1080x2400': Size(1080, 2400),
};

Matcher _rectCloseTo(Rect expected, [double tolerance = 1.0]) =>
    predicate<Rect>(
      (r) =>
          (r.left - expected.left).abs() <= tolerance &&
          (r.top - expected.top).abs() <= tolerance &&
          (r.right - expected.right).abs() <= tolerance &&
          (r.bottom - expected.bottom).abs() <= tolerance,
      'within $tolerance px of $expected',
    );

void main() {
  group('receiptFrame (FR-1.4)', () {
    for (final MapEntry(key: name, value: viewport) in _viewports.entries) {
      test('$name: centred, inside the viewport, receipt-shaped', () {
        final frame = FrameGeometry.receiptFrame(viewport);

        expect(Offset.zero & viewport, _contains(frame));
        expect(frame.center.dx, closeTo(viewport.width / 2, 0.001));
        expect(frame.center.dy, closeTo(viewport.height / 2, 0.001));
        expect(
          frame.width / frame.height,
          closeTo(FrameGeometry.receiptAspectRatio, 0.001),
        );
        expect(frame.width, greaterThan(viewport.width * 0.5));
      });
    }

    test('a wide (landscape) viewport is limited by its height', () {
      const viewport = Size(800, 360);
      final frame = FrameGeometry.receiptFrame(viewport);
      expect(Offset.zero & viewport, _contains(frame));
      expect(frame.height, lessThan(viewport.height));
      expect(
        frame.width / frame.height,
        closeTo(FrameGeometry.receiptAspectRatio, 0.001),
      );
    });
  });

  group('coverRect / viewportToNormalized (tap to focus, FR-1.3)', () {
    test(
      'content wider than the viewport overflows left and right equally',
      () {
        final rect = FrameGeometry.coverRect(
          const Size(9, 16),
          const Size(360, 800),
        );
        expect(rect.height, 800);
        expect(rect.width, closeTo(450, 0.001));
        expect(rect.left, closeTo(-45, 0.001));
        expect(rect.top, 0);
      },
    );

    test('the viewport centre is the preview centre', () {
      final p = FrameGeometry.viewportToNormalized(
        const Offset(180, 400),
        const Size(9, 16),
        const Size(360, 800),
      );
      expect(p.dx, closeTo(0.5, 1e-9));
      expect(p.dy, closeTo(0.5, 1e-9));
    });

    test('accounts for the cropped margins of a covered preview', () {
      // Preview 450 x 800 shown from x = -45: viewport x = 0 is preview x = 45.
      final p = FrameGeometry.viewportToNormalized(
        Offset.zero,
        const Size(9, 16),
        const Size(360, 800),
      );
      expect(p.dx, closeTo(45 / 450, 1e-9));
      expect(p.dy, 0);
    });

    test('results always stay within 0..1', () {
      final p = FrameGeometry.viewportToNormalized(
        const Offset(-50, 900),
        const Size(9, 16),
        const Size(360, 800),
      );
      expect(p, const Offset(0, 1));
    });
  });

  group('frameToImageCrop (FR-1.5)', () {
    test(
      'same aspect everywhere: the frame scales straight onto the photo',
      () {
        final crop = FrameGeometry.frameToImageCrop(
          frame: const Rect.fromLTWH(40, 80, 280, 480),
          viewport: const Size(360, 640),
          previewAspectRatio: 9 / 16,
          storedImageSize: const Size(1080, 1920),
          padding: 0,
        );
        expect(crop, _rectCloseTo(const Rect.fromLTWH(120, 240, 840, 1440)));
      },
    );

    test('20:9 viewport covered by a 9:16 preview (worked example)', () {
      // The 9:16 preview covers the 1080 x 2400 viewport at 1350 x 2400,
      // starting at x = -135. The photo fills the preview, scale 1080 / 1350
      // = 0.8: x 100 → (100 + 135) * 0.8 = 188, y 300 → 300 * 0.8 = 240.
      final crop = FrameGeometry.frameToImageCrop(
        frame: const Rect.fromLTRB(100, 300, 980, 2100),
        viewport: const Size(1080, 2400),
        previewAspectRatio: 9 / 16,
        storedImageSize: const Size(1080, 1920),
        padding: 0,
      );
      expect(crop, _rectCloseTo(const Rect.fromLTRB(188, 240, 892, 1680)));
    });

    test('padding widens the crop a little on every side', () {
      final crop = FrameGeometry.frameToImageCrop(
        frame: const Rect.fromLTWH(40, 80, 280, 480),
        viewport: const Size(360, 640),
        previewAspectRatio: 9 / 16,
        storedImageSize: const Size(1080, 1920),
        padding: 0.05,
      );
      expect(crop, _rectCloseTo(const Rect.fromLTRB(78, 168, 1002, 1752)));
    });

    test('a frame touching the edges is clamped to the photo', () {
      final crop = FrameGeometry.frameToImageCrop(
        frame: const Offset(0, 0) & const Size(360, 640),
        viewport: const Size(360, 640),
        previewAspectRatio: 9 / 16,
        storedImageSize: const Size(1080, 1920),
        padding: 0.1,
      );
      expect(crop, const Rect.fromLTWH(0, 0, 1080, 1920));
    });

    test(
      'EXIF rotation: a landscape-stored portrait photo gives the upright crop',
      () {
        const frame = Rect.fromLTWH(40, 80, 280, 480);
        Rect crop(Size stored, int turns) => FrameGeometry.frameToImageCrop(
          frame: frame,
          viewport: const Size(360, 640),
          previewAspectRatio: 9 / 16,
          storedImageSize: stored,
          quarterTurns: turns,
          padding: 0,
        );

        final upright = crop(const Size(1080, 1920), 0);
        expect(crop(const Size(1920, 1080), 1), upright);
        expect(crop(const Size(1080, 1920), 2), upright);
        expect(crop(const Size(1920, 1080), 3), upright);
      },
    );

    test('a centred frame maps to a centred crop whatever the aspects', () {
      for (final viewport in _viewports.values) {
        for (final aspect in _previewAspects.values) {
          for (final photo in _photos.values) {
            final frame = FrameGeometry.receiptFrame(viewport);
            final crop = FrameGeometry.frameToImageCrop(
              frame: frame,
              viewport: viewport,
              previewAspectRatio: aspect,
              storedImageSize: photo,
              quarterTurns: photo.width > photo.height ? 1 : 0,
            );
            final upright = photo.width > photo.height ? photo.flipped : photo;
            expect(crop.center.dx, closeTo(upright.width / 2, 1.0));
            expect(crop.center.dy, closeTo(upright.height / 2, 1.0));
          }
        }
      }
    });

    test('the crop is always inside the photo, whole pixels, never empty', () {
      final frames = <Rect Function(Size)>[
        FrameGeometry.receiptFrame,
        (v) => Offset.zero & v,
        (v) => Rect.fromLTWH(0, 0, v.width / 3, v.height / 5),
        (v) => Rect.fromLTRB(v.width * 0.7, v.height * 0.8, v.width, v.height),
        (v) => Rect.fromLTWH(v.width / 2, v.height / 2, 1, 1),
      ];
      var cases = 0;
      for (final viewport in [..._viewports.values, const Size(800, 360)]) {
        for (final aspect in [..._previewAspects.values, 16 / 9, 4 / 3]) {
          for (final photo in _photos.values) {
            for (var turns = 0; turns < 4; turns++) {
              for (final makeFrame in frames) {
                final crop = FrameGeometry.frameToImageCrop(
                  frame: makeFrame(viewport),
                  viewport: viewport,
                  previewAspectRatio: aspect,
                  storedImageSize: photo,
                  quarterTurns: turns,
                );
                final upright = turns.isOdd ? photo.flipped : photo;
                final reason =
                    'viewport $viewport aspect $aspect photo $photo turns $turns';
                expect(Offset.zero & upright, _contains(crop), reason: reason);
                expect(crop.width, greaterThanOrEqualTo(1), reason: reason);
                expect(crop.height, greaterThanOrEqualTo(1), reason: reason);
                for (final v in [
                  crop.left,
                  crop.top,
                  crop.right,
                  crop.bottom,
                ]) {
                  expect(v, v.roundToDouble(), reason: reason);
                }
                cases++;
              }
            }
          }
        }
      }
      expect(cases, 4 * 5 * 3 * 4 * 5);
    });
  });

  group('quarterTurnsForExif', () {
    test('maps EXIF orientation tags to clockwise quarter turns', () {
      expect(FrameGeometry.quarterTurnsForExif(1), 0);
      expect(FrameGeometry.quarterTurnsForExif(6), 1);
      expect(FrameGeometry.quarterTurnsForExif(3), 2);
      expect(FrameGeometry.quarterTurnsForExif(8), 3);
    });

    test(
      'mirrored tags keep their size effect; missing or invalid tags are 0',
      () {
        expect(FrameGeometry.quarterTurnsForExif(2).isEven, isTrue);
        expect(FrameGeometry.quarterTurnsForExif(4).isEven, isTrue);
        expect(FrameGeometry.quarterTurnsForExif(5).isOdd, isTrue);
        expect(FrameGeometry.quarterTurnsForExif(7).isOdd, isTrue);
        expect(FrameGeometry.quarterTurnsForExif(null), 0);
        expect(FrameGeometry.quarterTurnsForExif(42), 0);
      },
    );
  });
}

Matcher _contains(Rect inner) => predicate<Rect>(
  (outer) =>
      inner.left >= outer.left - 1e-9 &&
      inner.top >= outer.top - 1e-9 &&
      inner.right <= outer.right + 1e-9 &&
      inner.bottom <= outer.bottom + 1e-9,
  'contains $inner',
);
