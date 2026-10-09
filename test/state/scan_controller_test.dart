import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/models/field_confidence.dart';
import 'package:vku_expense_ocr/models/ocr_line.dart';
import 'package:vku_expense_ocr/models/parsed_receipt.dart';
import 'package:vku_expense_ocr/services/receipt_scan_service.dart';
import 'package:vku_expense_ocr/state/ocr_providers.dart';
import 'package:vku_expense_ocr/state/scan_controller.dart';

import '../support/fake_ocr_service.dart';

/// Scan service whose result the test releases by hand.
class _ControlledScanService extends ReceiptScanService {
  _ControlledScanService() : super(ocr: FakeOcrService());

  final calls = <String>[];
  final completers = <Completer<ScanResult>>[];

  @override
  Future<ScanResult> scan(String imagePath) {
    calls.add(imagePath);
    final completer = Completer<ScanResult>();
    completers.add(completer);
    return completer.future;
  }
}

ScanResult _result(String path) => ScanResult(
  imagePath: path,
  receipt: const ParsedReceipt.empty(),
  rows: const [],
  ocrDuration: const Duration(milliseconds: 900),
);

void main() {
  ProviderContainer container(ReceiptScanService service) {
    final c = ProviderContainer(
      overrides: [receiptScanServiceProvider.overrideWithValue(service)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('starts idle', () {
    expect(
      container(_ControlledScanService()).read(scanControllerProvider),
      isA<ScanIdle>(),
    );
  });

  test(
    'idle → processing → result with the real pipeline and a fake OCR',
    () async {
      final c = container(
        ReceiptScanService(
          ocr: FakeOcrService(
            lines: const [
              OcrLine(
                text: 'CIRCLE K',
                boundingBox: Rect.fromLTWH(40, 10, 200, 30),
              ),
              OcrLine(
                text: 'Tổng tiền',
                boundingBox: Rect.fromLTWH(10, 300, 120, 24),
              ),
              OcrLine(
                text: '25.000',
                boundingBox: Rect.fromLTWH(300, 302, 90, 24),
              ),
            ],
          ),
        ),
      );
      final states = <ScanState>[];
      c.listen(scanControllerProvider, (_, next) => states.add(next));

      final future = c
          .read(scanControllerProvider.notifier)
          .scan('/cache/a.jpg');
      expect(c.read(scanControllerProvider), isA<ScanProcessing>());
      expect(
        (c.read(scanControllerProvider) as ScanProcessing).imagePath,
        '/cache/a.jpg',
      );
      await future;

      final state = c.read(scanControllerProvider);
      expect(state, isA<ScanCompleted>());
      final receipt = (state as ScanCompleted).result.receipt;
      expect(receipt.total, 25000);
      expect(receipt.totalConfidence, FieldConfidence.high);
      expect(states.map((s) => s.runtimeType), [ScanProcessing, ScanCompleted]);
    },
  );

  test(
    'OCR throwing → error state with a Vietnamese message and the photo path',
    () async {
      final c = container(
        ReceiptScanService(
          ocr: FakeOcrService(error: Exception('corrupt image')),
        ),
      );

      await c.read(scanControllerProvider.notifier).scan('/cache/broken.jpg');

      final state = c.read(scanControllerProvider);
      expect(state, isA<ScanFailed>());
      state as ScanFailed;
      expect(state.imagePath, '/cache/broken.jpg');
      expect(state.message, contains('Không đọc được'));
    },
  );

  test(
    'an unexpected error inside the pipeline also ends in the error state',
    () async {
      final service = _ControlledScanService();
      final c = container(service);

      final future = c
          .read(scanControllerProvider.notifier)
          .scan('/cache/a.jpg');
      service.completers.single.completeError(StateError('isolate crashed'));
      await future;

      final state = c.read(scanControllerProvider);
      expect(state, isA<ScanFailed>());
      expect((state as ScanFailed).message, isNotEmpty);
    },
  );

  test('a second scan while processing is ignored (double tap)', () async {
    final service = _ControlledScanService();
    final c = container(service);

    final first = c.read(scanControllerProvider.notifier).scan('/cache/a.jpg');
    await c.read(scanControllerProvider.notifier).scan('/cache/b.jpg');
    expect(service.calls, ['/cache/a.jpg']);

    service.completers.single.complete(_result('/cache/a.jpg'));
    await first;
    expect(
      (c.read(scanControllerProvider) as ScanCompleted).result.imagePath,
      '/cache/a.jpg',
    );
  });

  test(
    'reset while processing returns to idle and drops the late result',
    () async {
      final service = _ControlledScanService();
      final c = container(service);

      final future = c
          .read(scanControllerProvider.notifier)
          .scan('/cache/a.jpg');
      c.read(scanControllerProvider.notifier).reset();
      expect(c.read(scanControllerProvider), isA<ScanIdle>());

      service.completers.single.complete(_result('/cache/a.jpg'));
      await future;
      expect(c.read(scanControllerProvider), isA<ScanIdle>());
    },
  );

  test('after a result or an error a new scan can start', () async {
    final service = _ControlledScanService();
    final c = container(service);

    final first = c.read(scanControllerProvider.notifier).scan('/cache/a.jpg');
    service.completers.last.completeError(Exception('x'));
    await first;
    expect(c.read(scanControllerProvider), isA<ScanFailed>());

    final second = c.read(scanControllerProvider.notifier).scan('/cache/b.jpg');
    expect(c.read(scanControllerProvider), isA<ScanProcessing>());
    service.completers.last.complete(_result('/cache/b.jpg'));
    await second;
    expect(c.read(scanControllerProvider), isA<ScanCompleted>());
  });
}
