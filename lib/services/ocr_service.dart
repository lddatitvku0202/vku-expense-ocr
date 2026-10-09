import 'dart:developer' as developer;
import 'dart:ui' show Offset;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:meta/meta.dart';
import 'package:vku_expense_ocr/models/ocr_line.dart';

/// Lines found on one image and how long recognition took (FR-2.4).
@immutable
class OcrResult {
  const OcrResult({required this.lines, required this.elapsed});

  final List<OcrLine> lines;

  /// Time spent inside the recognizer only (image decoding included),
  /// measured with a [Stopwatch].
  final Duration elapsed;
}

/// Text recognition behind an interface, so the scan pipeline can be
/// tested with a fake and the rest of the app never sees ML Kit types.
abstract interface class OcrService {
  /// Recognizes the text in the image file at [imagePath].
  Future<OcrResult> recognize(String imagePath);

  /// Releases native resources (FR-2.5). The service must not be used
  /// afterwards.
  Future<void> close();
}

/// On-device Google ML Kit text recognition, Latin script (FR-2.1).
///
/// The Latin model is bundled in the APK, so recognition works offline.
class MlKitOcrService implements OcrService {
  /// The default `TextRecognizer()` uses `TextRecognitionScript.latin`,
  /// the script required by FR-2.1 (checked in `ocr_service_test.dart`).
  MlKitOcrService({TextRecognizer? recognizer})
    : _recognizer = recognizer ?? TextRecognizer();

  final TextRecognizer _recognizer;

  @override
  Future<OcrResult> recognize(String imagePath) async {
    final stopwatch = Stopwatch()..start();
    final recognized = await _recognizer.processImage(
      InputImage.fromFilePath(imagePath),
    );
    stopwatch.stop();
    final lines = ocrLinesFrom(recognized);
    developer.log(
      'OCR ${stopwatch.elapsedMilliseconds} ms, ${lines.length} lines '
      '($imagePath)',
      name: 'vku_expense_ocr.ocr',
    );
    return OcrResult(lines: lines, elapsed: stopwatch.elapsed);
  }

  @override
  Future<void> close() => _recognizer.close();
}

/// Adapter from ML Kit's [RecognizedText] to the app's [OcrLine] (FR-2.2).
///
/// Uses `TextLine` granularity (not blocks): a block may span the label
/// column only, while rows are rebuilt later by `RowGrouper`. Corner points
/// are kept so the grouper can undo a tilted photo.
List<OcrLine> ocrLinesFrom(RecognizedText recognized) => [
  for (final block in recognized.blocks)
    for (final line in block.lines)
      OcrLine(
        text: line.text,
        boundingBox: line.boundingBox,
        cornerPoints: line.cornerPoints.length == 4
            ? [
                for (final point in line.cornerPoints)
                  Offset(point.x.toDouble(), point.y.toDouble()),
              ]
            : null,
      ),
];
