import 'dart:ui' show Rect;

import 'package:meta/meta.dart';

/// One line of recognized text with its position on the image (FR-2.2).
///
/// This is the app's own model, so the parser and the row grouper never
/// import ML Kit types and can be unit-tested with hand-made coordinates.
@immutable
class OcrLine {
  const OcrLine({required this.text, required this.boundingBox});

  final String text;

  /// Position in image pixels; the origin is the top-left corner.
  final Rect boundingBox;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OcrLine &&
          other.text == text &&
          other.boundingBox == boundingBox;

  @override
  int get hashCode => Object.hash(text, boundingBox);

  @override
  String toString() => 'OcrLine("$text", $boundingBox)';
}
