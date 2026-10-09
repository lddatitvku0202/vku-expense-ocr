import 'dart:math' as math;
import 'dart:ui';

/// Geometry shared by the camera screen and the crop service (FR-1.3 to
/// FR-1.5). Pure functions on `dart:ui` value types, so they run in unit
/// tests and on background isolates.
///
/// Three coordinate spaces are involved:
/// - **viewport**: the widget area showing the preview, logical pixels;
/// - **preview**: the camera stream, shown with `BoxFit.cover` (so parts of
///   it are cut off at two edges);
/// - **image**: the captured photo, upright (after EXIF rotation), pixels.
///
/// Assumption (D-046): the photo and the preview are centred crops of the
/// same camera view, as with CameraX using one resolution preset for both;
/// the photo is mapped onto the preview with `BoxFit.cover` as well.
abstract final class FrameGeometry {
  /// Width / height of the alignment frame. A till receipt is about 80 mm
  /// wide and much longer; 0.62 keeps a whole short receipt in view.
  static const double receiptAspectRatio = 0.62;

  /// The alignment frame: the largest [aspectRatio] rectangle centred in
  /// [area] that leaves a margin of [margin] × the shorter side (FR-1.4).
  static Rect receiptFrame(
    Size area, {
    double aspectRatio = receiptAspectRatio,
    double margin = 0.08,
  }) {
    final inset = area.shortestSide * margin;
    final maxWidth = math.max(1.0, area.width - 2 * inset);
    final maxHeight = math.max(1.0, area.height - 2 * inset);
    var width = maxWidth;
    var height = width / aspectRatio;
    if (height > maxHeight) {
      height = maxHeight;
      width = height * aspectRatio;
    }
    return Rect.fromCenter(
      center: area.center(Offset.zero),
      width: width,
      height: height,
    );
  }

  /// Where [content] lands when painted centred into [viewport] with
  /// `BoxFit.cover` (it may extend past the viewport on two sides).
  static Rect coverRect(Size content, Size viewport) {
    final scale = math.max(
      viewport.width / content.width,
      viewport.height / content.height,
    );
    final size = content * scale;
    return Rect.fromCenter(
      center: viewport.center(Offset.zero),
      width: size.width,
      height: size.height,
    );
  }

  /// A tap in the viewport as a point on the covered [content], from (0, 0)
  /// top-left to (1, 1) bottom-right: what `setFocusPoint` expects.
  static Offset viewportToNormalized(
    Offset point,
    Size content,
    Size viewport,
  ) {
    final shown = coverRect(content, viewport);
    return Offset(
      ((point.dx - shown.left) / shown.width).clamp(0.0, 1.0),
      ((point.dy - shown.top) / shown.height).clamp(0.0, 1.0),
    );
  }

  /// Maps the alignment [frame] (viewport coordinates) to a crop rectangle
  /// in the upright photo (FR-1.5).
  ///
  /// [storedImageSize] is the photo as decoded, before applying its EXIF
  /// rotation of [quarterTurns] clockwise quarter turns; the result is in
  /// the upright photo. [padding] widens the crop by that fraction of its
  /// size on every side, so a small misalignment does not cut text off.
  /// The result is clamped to the photo, in whole pixels, at least 1 × 1.
  static Rect frameToImageCrop({
    required Rect frame,
    required Size viewport,
    required double previewAspectRatio,
    required Size storedImageSize,
    int quarterTurns = 0,
    double padding = 0.03,
  }) {
    final image = quarterTurns.isOdd
        ? storedImageSize.flipped
        : storedImageSize;

    // Viewport → preview (covered), then preview → photo (covered).
    final preview = coverRect(Size(previewAspectRatio, 1), viewport);
    final photoInPreview = coverRect(image, preview.size);
    final scale = image.width / photoInPreview.width;
    final origin = preview.topLeft + photoInPreview.topLeft;
    final mapped = Rect.fromLTRB(
      (frame.left - origin.dx) * scale,
      (frame.top - origin.dy) * scale,
      (frame.right - origin.dx) * scale,
      (frame.bottom - origin.dy) * scale,
    );

    final padded = Rect.fromLTRB(
      mapped.left - mapped.width * padding,
      mapped.top - mapped.height * padding,
      mapped.right + mapped.width * padding,
      mapped.bottom + mapped.height * padding,
    );
    final left = padded.left.floorToDouble().clamp(0.0, image.width - 1);
    final top = padded.top.floorToDouble().clamp(0.0, image.height - 1);
    final right = padded.right.ceilToDouble().clamp(left + 1, image.width);
    final bottom = padded.bottom.ceilToDouble().clamp(top + 1, image.height);
    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// Clockwise quarter turns that display a photo with EXIF [orientation]
  /// upright. Mirrored orientations (2, 4, 5, 7) return the turns with the
  /// same effect on the size; missing or invalid tags count as upright.
  static int quarterTurnsForExif(int? orientation) => switch (orientation) {
    3 || 4 => 2,
    5 || 6 => 1,
    7 || 8 => 3,
    _ => 0,
  };
}
