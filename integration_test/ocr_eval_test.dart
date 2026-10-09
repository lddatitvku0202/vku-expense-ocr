// Real-receipt OCR evaluation. Runs on any Android device or emulator.
//
// Do not run this file directly: use the one-command script, which checks
// the locked hash, copies the photos to the device, runs this test and
// pulls the report back:
//
//   powershell -ExecutionPolicy Bypass -File tool\ocr_eval\run_ocr_eval.ps1
//
// Input  : <app external files>/ocr_eval/ground_truth.csv + photos.
// Output : report.json and report.md in the same folder.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vku_expense_ocr/services/ocr_service.dart';
import 'package:vku_expense_ocr/services/receipt_scan_service.dart';

import 'ocr_eval/ground_truth.dart';
import 'ocr_eval/scoring.dart';

/// SHA-256 the script verified on the host; checked again on the device.
const expectedSha256 = String.fromEnvironment('GROUND_TRUTH_SHA256');
const deviceLabel = String.fromEnvironment(
  'EVAL_DEVICE',
  defaultValue: 'unknown device',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('scores the OCR pipeline against the locked ground truth', (
    tester,
  ) async {
    final external = await getExternalStorageDirectory();
    expect(external, isNotNull, reason: 'No external files directory');
    final dir = Directory('${external!.path}/ocr_eval');
    final csvFile = File('${dir.path}/ground_truth.csv');
    expect(
      csvFile.existsSync(),
      isTrue,
      reason: 'Run tool/ocr_eval/run_ocr_eval.ps1 to copy the data first',
    );

    final bytes = csvFile.readAsBytesSync();
    final actualSha256 = sha256.convert(bytes).toString();
    expect(expectedSha256, isNotEmpty, reason: 'GROUND_TRUTH_SHA256 not set');
    expect(
      actualSha256,
      expectedSha256.toLowerCase(),
      reason: 'ground_truth.csv on the device differs from the locked file',
    );

    final truths = parseGroundTruth(utf8.decode(bytes));
    final ocr = MlKitOcrService();
    final scanner = ReceiptScanService(ocr: ocr);
    final scores = <ReceiptScore>[];
    try {
      for (final truth in truths) {
        final image = File('${dir.path}/${truth.file}');
        expect(image.existsSync(), isTrue, reason: 'Missing ${truth.file}');
        final scan = await scanner.scan(image.path);
        scores.add(scoreReceipt(truth, scan));
        debugPrint(
          'OCR_EVAL ${truth.file}: ${scan.ocrDuration.inMilliseconds} ms'
          '${scan.failed ? ' (failed)' : ''}',
        );
      }
    } finally {
      await ocr.close();
    }

    final report = EvalReport(device: deviceLabel, scores: scores);
    final reports = {
      'report.json': report.toJson(),
      'report.md': report.toMarkdown(),
    };
    for (final MapEntry(key: name, value: content) in reports.entries) {
      final file = File('${dir.path}/$name')..writeAsStringSync(content);
      // Let `adb pull` (user shell) read the file the app just created.
      await Process.run('chmod', ['666', file.path]);
    }
    for (final summary in report.summaries) {
      debugPrint(
        'OCR_EVAL_SUMMARY ${summary.set}: n=${summary.count} '
        'merchant=${summary.merchant} total=${summary.total} '
        'date=${summary.date} category=${summary.categoryCorrect}/'
        '${summary.categoryNone}/${summary.categoryWrong} '
        'ocr_median_ms=${summary.medianOcrMs}',
      );
    }
    expect(scores, hasLength(truths.length));
  }, timeout: const Timeout(Duration(minutes: 20)));
}
