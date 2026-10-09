import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/models/field_confidence.dart';
import 'package:vku_expense_ocr/models/parsed_receipt.dart';
import 'package:vku_expense_ocr/services/receipt_scan_service.dart';

import '../../integration_test/ocr_eval/ground_truth.dart';
import '../../integration_test/ocr_eval/scoring.dart';

const header =
    'file,merchant,merchant_alt,total,date,category,confidence,notes,set,verified';

GroundTruthRow truth({
  List<String> merchants = const ['HIGHLANDS COFFEE'],
  int? total = 55000,
  DateTime? date,
  ExpenseCategory? category = ExpenseCategory.food,
  String set = 'main',
}) => GroundTruthRow(
  file: 'x.jpg',
  merchants: merchants,
  total: total,
  date: date,
  category: category,
  set: set,
  confidence: 'high',
);

ScanResult scan({
  String? merchant,
  int? total,
  DateTime? date,
  ExpenseCategory? category,
  int ocrMs = 100,
}) => ScanResult(
  imagePath: 'x.jpg',
  receipt: ParsedReceipt(
    merchant: merchant,
    total: total,
    date: date,
    suggestedCategory: category,
    rawText: '',
    merchantConfidence: merchant == null
        ? FieldConfidence.missing
        : FieldConfidence.high,
    totalConfidence: total == null
        ? FieldConfidence.missing
        : FieldConfidence.high,
    dateConfidence: date == null
        ? FieldConfidence.missing
        : FieldConfidence.high,
    categoryConfidence: category == null
        ? FieldConfidence.missing
        : FieldConfidence.high,
  ),
  rows: const [],
  ocrDuration: Duration(milliseconds: ocrMs),
);

void main() {
  group('parseCsv', () {
    test('handles quotes, commas, doubled quotes and CRLF', () {
      const text = 'a,b,c\r\n1,"x, y","say ""hi"""\r\n2,,"multi\r\nline"\r\n';
      expect(parseCsv(text), [
        ['a', 'b', 'c'],
        ['1', 'x, y', 'say "hi"'],
        ['2', '', 'multi\r\nline'],
      ]);
    });

    test('ignores a UTF-8 byte order mark and a missing final newline', () {
      expect(parseCsv('${String.fromCharCode(0xFEFF)}a,b\n1,2'), [
        ['a', 'b'],
        ['1', '2'],
      ]);
    });
  });

  group('parseGroundTruth', () {
    test('reads totals, dates, categories and both merchant columns', () {
      final rows = parseGroundTruth(
        '$header\r\n'
        'a.jpg,CO.OPMART,"Co.opmart, Huế",245000,14/09/2026,Food,low,"n, x",main,yes\r\n'
        'b.jpg,,,0,,Gear,high,,edge,yes\r\n',
      );
      expect(rows, hasLength(2));
      expect(rows[0].merchants, ['CO.OPMART', 'Co.opmart, Huế']);
      expect(rows[0].total, 245000);
      expect(rows[0].date, DateTime(2026, 9, 14));
      expect(rows[0].category, ExpenseCategory.food);
      expect(rows[0].set, 'main');
      expect(rows[1].merchants, isEmpty);
      expect(rows[1].total, 0);
      expect(rows[1].date, isNull);
      expect(rows[1].category, ExpenseCategory.gear);
      expect(rows[1].set, 'edge');
    });

    test('rejects malformed values with the line number', () {
      expect(
        () => parseGroundTruth(
          '$header\na.jpg,A,,1000,31/02/2026,Food,high,,main,yes\n',
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Line 2'),
          ),
        ),
      );
      expect(
        () => parseGroundTruth(
          '$header\na.jpg,A,,1000,,Shopping,high,,main,yes\n',
        ),
        throwsFormatException,
      );
    });
  });

  group('merchantMatches', () {
    test('normalizes accents, case and punctuation', () {
      expect(merchantKey('CO.OPMART HUẾ'), 'coopmarthue');
      expect(merchantMatches('Co.opmart Huế', ['CO.OPMART HUẾ']), isTrue);
    });

    test('accepts containment in both directions', () {
      expect(merchantMatches('CIRCLE K VIETNAM', ['CIRCLE K']), isTrue);
      expect(merchantMatches('Highlands', ['HIGHLANDS COFFEE']), isTrue);
    });

    test('also accepts merchant_alt', () {
      expect(
        merchantMatches('VM VC HNI Liễu Giai', [
          'VinCommerce',
          'VM VC HNI Liễu Giai',
        ]),
        isTrue,
      );
    });

    test('needs at least 4 matching characters', () {
      expect(merchantMatches('CGV', ['CGV Vincom Huế']), isFalse);
      expect(merchantMatches('Big', ['Big C Garden MALL']), isFalse);
    });

    test('rejects unrelated names and missing results', () {
      expect(merchantMatches('Hóa đơn bán hàng', ['WinMart']), isFalse);
      expect(merchantMatches(null, ['WinMart']), isFalse);
    });

    test('an empty answer is correct only when nothing was found', () {
      expect(merchantMatches(null, const []), isTrue);
      expect(merchantMatches('Something', const []), isFalse);
    });
  });

  group('scoreReceipt', () {
    test('total and date match exactly; empty answers expect null', () {
      final s = scoreReceipt(
        truth(date: DateTime(2025, 10, 24)),
        scan(
          merchant: 'HIGHLANDS COFFEE',
          total: 55000,
          date: DateTime(2025, 10, 24),
        ),
      );
      expect((s.totalOk, s.dateOk), (true, true));

      final noDate = scoreReceipt(truth(), scan(total: 55000));
      expect(noDate.dateOk, isTrue);
      final extraDate = scoreReceipt(truth(), scan(date: DateTime(2025)));
      expect(extraDate.dateOk, isFalse);
      expect(extraDate.totalOk, isFalse);
    });

    test('category: correct, none or wrong', () {
      expect(
        scoreReceipt(truth(), scan(category: ExpenseCategory.food)).category,
        CategoryOutcome.correct,
      );
      expect(scoreReceipt(truth(), scan()).category, CategoryOutcome.none);
      expect(
        scoreReceipt(truth(), scan(category: ExpenseCategory.gear)).category,
        CategoryOutcome.wrong,
      );
    });
  });

  test('the report summarizes main and edge sets separately', () {
    final report = EvalReport(
      device: 'test',
      scores: [
        scoreReceipt(
          truth(),
          scan(
            merchant: 'HIGHLANDS COFFEE',
            total: 55000,
            category: ExpenseCategory.food,
            ocrMs: 300,
          ),
        ),
        scoreReceipt(truth(), scan(total: 1)),
        // A free (0 đ) receipt: the parser never returns 0, so it is wrong.
        scoreReceipt(truth(set: 'edge', total: 0), scan(ocrMs: 200)),
      ],
    );
    final summaries = {for (final s in report.summaries) s.set: s};
    expect(summaries.keys, ['edge', 'main']);
    final main = summaries['main']!;
    expect(
      (
        main.count,
        main.merchant,
        main.total,
        main.categoryCorrect,
        main.categoryNone,
      ),
      (2, 1, 1, 1, 1),
    );
    expect(main.ocrMilliseconds, [100, 300]);
    expect(main.medianOcrMs, 100);
    expect(summaries['edge']!.total, 0);
    expect(report.toMarkdown(), contains('| main | 2 | 1/2 | 1/2 |'));
    expect(report.toJson(), contains('"set": "edge"'));
  });
}
