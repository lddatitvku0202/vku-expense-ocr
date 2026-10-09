/// Scoring rules for the real-receipt evaluation (TEST_REPORT: "Quy tắc
/// gán nhãn & chấm điểm hóa đơn thật"). Pure Dart, unit-tested in
/// `test/tooling/ocr_scoring_test.dart`.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:vku_expense_ocr/core/text_normalizer.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/services/receipt_scan_service.dart';

import 'ground_truth.dart';

enum CategoryOutcome { correct, none, wrong }

/// Letters and digits only, no accents, lower case: "CO.OPMART HUẾ" →
/// "coopmarthue".
String merchantKey(String text) =>
    TextNormalizer.removeDiacritics(text)
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]'), '');

/// Merchant rule: after [merchantKey], correct if the result contains or is
/// contained in an expected name and the shorter of the two has at least 4
/// characters. No expected name → correct only when nothing was found.
bool merchantMatches(String? actual, List<String> expected) {
  if (expected.isEmpty) return actual == null;
  if (actual == null) return false;
  final a = merchantKey(actual);
  for (final name in expected) {
    final e = merchantKey(name);
    if (math.min(a.length, e.length) < 4) continue;
    if (a.contains(e) || e.contains(a)) return true;
  }
  return false;
}

/// Exact match; an empty expected value is correct only for `null`.
bool valueMatches<T>(T? actual, T? expected) => actual == expected;

CategoryOutcome categoryOutcome(
  ExpenseCategory? actual,
  ExpenseCategory? expected,
) => switch ((actual, expected)) {
  (null, null) => CategoryOutcome.correct,
  (null, _) => CategoryOutcome.none,
  (final a, final e) when a == e => CategoryOutcome.correct,
  _ => CategoryOutcome.wrong,
};

@immutable
class ReceiptScore {
  const ReceiptScore({
    required this.truth,
    required this.scan,
    required this.merchantOk,
    required this.totalOk,
    required this.dateOk,
    required this.category,
  });

  final GroundTruthRow truth;
  final ScanResult scan;
  final bool merchantOk;
  final bool totalOk;
  final bool dateOk;
  final CategoryOutcome category;

  bool get allOk =>
      merchantOk && totalOk && dateOk && category == CategoryOutcome.correct;
}

ReceiptScore scoreReceipt(GroundTruthRow truth, ScanResult scan) {
  final receipt = scan.receipt;
  return ReceiptScore(
    truth: truth,
    scan: scan,
    merchantOk: merchantMatches(receipt.merchant, truth.merchants),
    totalOk: valueMatches(receipt.total, truth.total),
    dateOk: valueMatches(receipt.date, truth.date),
    category: categoryOutcome(receipt.suggestedCategory, truth.category),
  );
}

/// Accuracy of one set (`main` or `edge`).
@immutable
class SetSummary {
  const SetSummary({
    required this.set,
    required this.count,
    required this.merchant,
    required this.total,
    required this.date,
    required this.categoryCorrect,
    required this.categoryNone,
    required this.categoryWrong,
    required this.ocrMilliseconds,
  });

  factory SetSummary.of(String set, List<ReceiptScore> scores) => SetSummary(
    set: set,
    count: scores.length,
    merchant: scores.where((s) => s.merchantOk).length,
    total: scores.where((s) => s.totalOk).length,
    date: scores.where((s) => s.dateOk).length,
    categoryCorrect: scores
        .where((s) => s.category == CategoryOutcome.correct)
        .length,
    categoryNone: scores
        .where((s) => s.category == CategoryOutcome.none)
        .length,
    categoryWrong: scores
        .where((s) => s.category == CategoryOutcome.wrong)
        .length,
    ocrMilliseconds: [
      for (final s in scores)
        if (!s.scan.failed) s.scan.ocrDuration.inMilliseconds,
    ]..sort(),
  );

  final String set;
  final int count;
  final int merchant;
  final int total;
  final int date;
  final int categoryCorrect;
  final int categoryNone;
  final int categoryWrong;

  /// Sorted OCR times of the photos that could be read.
  final List<int> ocrMilliseconds;

  int? get medianOcrMs => ocrMilliseconds.isEmpty
      ? null
      : ocrMilliseconds[(ocrMilliseconds.length - 1) ~/ 2];
}

/// Everything one evaluation run produced.
class EvalReport {
  EvalReport({required this.device, required this.scores});

  /// Where the run happened, e.g. "sdk_gphone64_x86_64 (API 33)".
  final String device;
  final List<ReceiptScore> scores;

  List<SetSummary> get summaries => [
    for (final set in {for (final s in scores) s.truth.set}.toList()..sort())
      SetSummary.of(set, [
        for (final s in scores)
          if (s.truth.set == set) s,
      ]),
  ];

  String toJson() => const JsonEncoder.withIndent('  ').convert({
    'device': device,
    'summaries': [
      for (final s in summaries)
        {
          'set': s.set,
          'count': s.count,
          'merchant': s.merchant,
          'total': s.total,
          'date': s.date,
          'category_correct': s.categoryCorrect,
          'category_none': s.categoryNone,
          'category_wrong': s.categoryWrong,
          'ocr_ms_sorted': s.ocrMilliseconds,
        },
    ],
    'receipts': [
      for (final s in scores)
        {
          'file': s.truth.file,
          'set': s.truth.set,
          'merchant_ok': s.merchantOk,
          'total_ok': s.totalOk,
          'date_ok': s.dateOk,
          'category': s.category.name,
          'expected': {
            'merchants': s.truth.merchants,
            'total': s.truth.total,
            'date': s.truth.date?.toIso8601String(),
            'category': s.truth.category?.name,
          },
          'actual': {
            'merchant': s.scan.receipt.merchant,
            'total': s.scan.receipt.total,
            'date': s.scan.receipt.date?.toIso8601String(),
            'category': s.scan.receipt.suggestedCategory?.name,
            'confidence': {
              'merchant': s.scan.receipt.merchantConfidence.name,
              'total': s.scan.receipt.totalConfidence.name,
              'date': s.scan.receipt.dateConfidence.name,
              'category': s.scan.receipt.categoryConfidence.name,
            },
          },
          'ocr_ms': s.scan.ocrDuration.inMilliseconds,
          'error': s.scan.error,
          'rows': s.scan.rows,
        },
    ],
  });

  String toMarkdown() {
    final out = StringBuffer()
      ..writeln('# OCR evaluation — $device')
      ..writeln()
      ..writeln(
        '| Set | n | Merchant | Total | Date | Category ok / none / wrong '
        '| OCR median (ms) |',
      )
      ..writeln('|---|---|---|---|---|---|---|');
    for (final s in summaries) {
      out.writeln(
        '| ${s.set} | ${s.count} | ${s.merchant}/${s.count} '
        '| ${s.total}/${s.count} | ${s.date}/${s.count} '
        '| ${s.categoryCorrect} / ${s.categoryNone} / ${s.categoryWrong} '
        '| ${s.medianOcrMs ?? '-'} |',
      );
    }
    out
      ..writeln()
      ..writeln('| File | Set | Merchant | Total | Date | Category | OCR ms |')
      ..writeln('|---|---|---|---|---|---|---|');
    String mark(bool ok) => ok ? 'ok' : 'WRONG';
    for (final s in scores) {
      out.writeln(
        '| ${s.truth.file} | ${s.truth.set} | ${mark(s.merchantOk)} '
        '| ${mark(s.totalOk)} | ${mark(s.dateOk)} | ${s.category.name} '
        '| ${s.scan.failed ? 'failed' : s.scan.ocrDuration.inMilliseconds} |',
      );
    }
    return out.toString();
  }
}
