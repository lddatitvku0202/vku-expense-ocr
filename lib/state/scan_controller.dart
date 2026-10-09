import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:vku_expense_ocr/services/receipt_scan_service.dart';
import 'package:vku_expense_ocr/state/ocr_providers.dart';

/// Where the scan of one receipt photo is: idle → processing → result
/// ([ScanCompleted]) or error ([ScanFailed]). A sealed class, so a
/// `switch` over it must handle every state (W7 s14).
@immutable
sealed class ScanState {
  const ScanState();
}

/// Nothing is being scanned.
final class ScanIdle extends ScanState {
  const ScanIdle();
}

/// OCR and parsing are running on [imagePath]; the UI shows a loader.
final class ScanProcessing extends ScanState {
  const ScanProcessing(this.imagePath);

  final String imagePath;
}

/// Text was recognized and parsed; the next step is the Review screen.
final class ScanCompleted extends ScanState {
  const ScanCompleted(this.result);

  final ScanResult result;
}

/// The photo could not be read. [message] is Vietnamese, for the user;
/// [imagePath] lets the UI offer manual entry with that photo.
final class ScanFailed extends ScanState {
  const ScanFailed(this.message, {required this.imagePath});

  final String message;
  final String imagePath;
}

final scanControllerProvider = NotifierProvider<ScanController, ScanState>(
  ScanController.new,
);

class ScanController extends Notifier<ScanState> {
  /// Bumped by every scan and reset, so a result that arrives after the
  /// user cancelled (or started over) is dropped.
  int _generation = 0;

  @override
  ScanState build() => const ScanIdle();

  /// Runs the pipeline on [imagePath]. Ignored while another scan is in
  /// progress (double tap on the shutter).
  Future<void> scan(String imagePath) async {
    if (state is ScanProcessing) return;
    final generation = ++_generation;
    state = ScanProcessing(imagePath);

    ScanState next;
    try {
      final result = await ref.read(receiptScanServiceProvider).scan(imagePath);
      next = switch (result.error) {
        final String error => ScanFailed(error, imagePath: imagePath),
        null => ScanCompleted(result),
      };
    } on Object catch (error, stack) {
      // The service already turns OCR failures into a result; anything that
      // still escapes (e.g. an isolate crash) must not leave the UI stuck.
      developer.log(
        'Scan failed for $imagePath',
        name: 'vku_expense_ocr.scan',
        error: error,
        stackTrace: stack,
      );
      next = ScanFailed(
        'Đã có lỗi khi xử lý ảnh. Hãy thử lại hoặc nhập tay.',
        imagePath: imagePath,
      );
    }
    if (generation == _generation) state = next;
  }

  /// Back to idle, e.g. when the user leaves the scan screen.
  void reset() {
    _generation++;
    state = const ScanIdle();
  }
}
