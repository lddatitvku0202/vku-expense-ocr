import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vku_expense_ocr/services/ocr_service.dart';
import 'package:vku_expense_ocr/services/receipt_scan_service.dart';

/// The single ML Kit recognizer of the app. Closed when the provider is
/// disposed, so the native model is released (FR-2.5).
final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = MlKitOcrService();
  ref.onDispose(() => unawaited(service.close()));
  return service;
});

/// Image → OCR → rows → [ParsedReceipt] pipeline.
final receiptScanServiceProvider = Provider<ReceiptScanService>(
  (ref) => ReceiptScanService(ocr: ref.watch(ocrServiceProvider)),
);

/// Opens the system photo picker and returns the chosen file path, or
/// `null` when the user cancels (FR-1.6). A provider so tests can replace
/// the platform picker.
final pickGalleryImageProvider = Provider<Future<String?> Function()>(
  (ref) =>
      () async =>
          (await ImagePicker().pickImage(source: ImageSource.gallery))?.path,
);
