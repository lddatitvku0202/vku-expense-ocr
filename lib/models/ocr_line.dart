import 'dart:ui' show Offset, Rect;

import 'package:meta/meta.dart';

/// One line of recognized text with its position on the image (FR-2.2).
///
/// This is the app's own model, so the parser and the row grouper never
/// import ML Kit types and can be unit-tested with hand-made coordinates.
@immutable
class OcrLine {
  const OcrLine({
    required this.text,
    required this.boundingBox,
    this.cornerPoints,
  });

  final String text;

  /// Axis-aligned box in image pixels; the origin is the top-left corner.
  final Rect boundingBox;

  /// The four corners of the text, clockwise from the text's own top-left
  /// (ML Kit order). Unlike [boundingBox] they follow the text when the
  /// photo is tilted, which lets `RowGrouper` estimate the tilt. `null`
  /// when the source does not provide them.
  final List<Offset>? cornerPoints;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OcrLine &&
          other.text == text &&
          other.boundingBox == boundingBox &&
          _sameCorners(other.cornerPoints, cornerPoints);

  @override
  int get hashCode => Object.hash(text, boundingBox, switch (cornerPoints) {
    final List<Offset> corners => Object.hashAll(corners),
    null => null,
  });

  @override
  String toString() => 'OcrLine("$text", $boundingBox)';

  static bool _sameCorners(List<Offset>? a, List<Offset>? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
