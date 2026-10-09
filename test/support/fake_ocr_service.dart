import 'package:vku_expense_ocr/models/ocr_line.dart';
import 'package:vku_expense_ocr/services/ocr_service.dart';

/// Test double for [OcrService]. Lives in `test/` only: production code
/// never returns canned OCR results.
class FakeOcrService implements OcrService {
  FakeOcrService({
    this.lines = const [],
    this.elapsed = const Duration(milliseconds: 120),
    this.error,
  });

  final List<OcrLine> lines;
  final Duration elapsed;

  /// Thrown by [recognize] when set, e.g. to simulate a broken image.
  final Exception? error;

  final List<String> recognizedPaths = [];
  bool closed = false;

  @override
  Future<OcrResult> recognize(String imagePath) async {
    recognizedPaths.add(imagePath);
    if (error case final error?) throw error;
    return OcrResult(lines: lines, elapsed: elapsed);
  }

  @override
  Future<void> close() async => closed = true;
}
