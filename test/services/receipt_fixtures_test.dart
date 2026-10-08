import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/core/text_normalizer.dart';
import 'package:vku_expense_ocr/models/parsed_receipt.dart';
import 'package:vku_expense_ocr/services/receipt_parser.dart';
import 'package:vku_expense_ocr/services/row_grouper.dart';

import '../fixtures/receipts/expected.dart';
import '../fixtures/receipts/known_limitations.dart';
import '../support/receipt_fixture.dart';

/// End-to-end benchmark: fixture → OCR lines → rows → ParsedReceipt.
void main() {
  const grouper = RowGrouper();
  const parser = ReceiptParser();

  ParsedReceipt parseFixture(String file) {
    final rows = grouper
        .group(loadFixtureLines(file))
        .map((row) => row.text)
        .toList();
    return parser.parse(rows);
  }

  Map<ReceiptField, String> wrongFields(
    ReceiptExpectation expected,
    ParsedReceipt actual,
  ) {
    final wrong = <ReceiptField, String>{};
    final merchantOk = switch ((expected.merchant, actual.merchant)) {
      (null, null) => true,
      (final List<String> names, final String name) =>
        names
            .map(TextNormalizer.normalize)
            .contains(TextNormalizer.normalize(name)),
      _ => false,
    };
    if (!merchantOk) {
      wrong[ReceiptField.merchant] =
          'expected ${expected.merchant}, got ${actual.merchant}';
    }
    if (actual.total != expected.total) {
      wrong[ReceiptField.total] =
          'expected ${expected.total}, got ${actual.total}';
    }
    final actualDate = switch (actual.date) {
      final DateTime d => (d.year, d.month, d.day),
      null => null,
    };
    if (actualDate != expected.date) {
      wrong[ReceiptField.date] = 'expected ${expected.date}, got $actualDate';
    }
    if (actual.suggestedCategory != expected.category) {
      wrong[ReceiptField.category] =
          'expected ${expected.category}, got ${actual.suggestedCategory}';
    }
    return wrong;
  }

  test('there are at least 15 fixtures, each with an expectation', () {
    final files = Directory(fixtureDir)
        .listSync()
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last)
        .where((name) => name.endsWith('.txt'))
        .toSet();
    expect(files.length, greaterThanOrEqualTo(15));
    expect(receiptExpectations.map((e) => e.file).toSet(), files);
    expect(knownLimitations.keys.toSet().difference(files), isEmpty);
  });

  for (final expected in receiptExpectations) {
    test('${expected.file} parses as expected', () {
      final actual = parseFixture(expected.file);
      final wrong = wrongFields(expected, actual);
      final known =
          knownLimitations[expected.file] ?? const <ReceiptField, String>{};
      expect(
        wrong.keys.toSet(),
        known.keys.toSet(),
        reason: 'Mismatches: $wrong\n$actual\nRows:\n${actual.rawText}',
      );
    });
  }

  test('writes the per-field accuracy report', () {
    final correct = {for (final field in ReceiptField.values) field: 0};
    final table = <String>[
      '| Fixture | Merchant | Total | Date | Category |',
      '|---|---|---|---|---|',
    ];
    for (final expected in receiptExpectations) {
      final wrong = wrongFields(expected, parseFixture(expected.file));
      final marks = <String>[];
      for (final field in ReceiptField.values) {
        if (wrong.containsKey(field)) {
          marks.add('✗');
        } else {
          marks.add('✓');
          correct.update(field, (count) => count + 1);
        }
      }
      table.add('| ${expected.file} | ${marks.join(' | ')} |');
    }
    final count = receiptExpectations.length;
    final summary = [
      for (final field in ReceiptField.values)
        '- ${field.name}: ${correct[field]}/$count',
    ];
    final report = File('build/reports/receipt_parser_accuracy.md')
      ..createSync(recursive: true)
      ..writeAsStringSync([...summary, '', ...table].join('\n'));
    expect(report.existsSync(), isTrue);
  });
}
