/// Reading the reviewed `ground_truth.csv` of real receipt photos.
///
/// The CSV lives outside the repository (it describes real receipts); only
/// this reader and the scoring code are versioned.
library;

import 'package:meta/meta.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';

/// Expected values for one photo. Empty cells mean "the correct answer is
/// that there is none" (see TEST_REPORT, labelling rules).
@immutable
class GroundTruthRow {
  const GroundTruthRow({
    required this.file,
    required this.merchants,
    required this.total,
    required this.date,
    required this.category,
    required this.set,
    required this.confidence,
  });

  final String file;

  /// Non-empty values of `merchant` and `merchant_alt`.
  final List<String> merchants;
  final int? total;
  final DateTime? date;
  final ExpenseCategory? category;

  /// `main` or `edge`; results are reported per set.
  final String set;

  /// Labeller's confidence: `high` or `low`.
  final String confidence;
}

/// Parses the ground-truth CSV. Throws [FormatException] naming the line on
/// any malformed value, so a bad file stops the evaluation early.
List<GroundTruthRow> parseGroundTruth(String source) {
  final records = parseCsv(source);
  if (records.isEmpty) throw const FormatException('ground_truth.csv is empty');
  final header = records.first;
  int column(String name) {
    final index = header.indexOf(name);
    if (index < 0) throw FormatException('Missing column "$name"');
    return index;
  }

  final file = column('file');
  final merchant = column('merchant');
  final merchantAlt = column('merchant_alt');
  final total = column('total');
  final date = column('date');
  final category = column('category');
  final set = column('set');
  final confidence = column('confidence');

  final rows = <GroundTruthRow>[];
  for (var i = 1; i < records.length; i++) {
    final r = records[i];
    if (r.every((cell) => cell.trim().isEmpty)) continue;
    if (r.length != header.length) {
      throw FormatException(
        'Line ${i + 1}: ${r.length} columns, expected ${header.length}',
      );
    }
    try {
      rows.add(
        GroundTruthRow(
          file: r[file].trim(),
          merchants: [
            for (final m in [r[merchant], r[merchantAlt]])
              if (m.trim().isNotEmpty) m.trim(),
          ],
          total: _parseTotal(r[total]),
          date: _parseDate(r[date]),
          category: _parseCategory(r[category]),
          set: r[set].trim(),
          confidence: r[confidence].trim(),
        ),
      );
    } on FormatException catch (error) {
      throw FormatException('Line ${i + 1}: ${error.message}', error.source);
    }
  }
  return rows;
}

int? _parseTotal(String cell) {
  final text = cell.trim();
  if (text.isEmpty) return null;
  final value = int.tryParse(text);
  if (value == null || value < 0) throw FormatException('Bad total', cell);
  return value;
}

final RegExp _dmy = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');

DateTime? _parseDate(String cell) {
  final text = cell.trim();
  if (text.isEmpty) return null;
  final match = _dmy.firstMatch(text);
  if (match == null) throw FormatException('Bad date (dd/MM/yyyy)', cell);
  final day = int.parse(match[1]!);
  final month = int.parse(match[2]!);
  final year = int.parse(match[3]!);
  final date = DateTime(year, month, day);
  if (date.month != month || date.day != day) {
    throw FormatException('Date does not exist', cell);
  }
  return date;
}

ExpenseCategory? _parseCategory(String cell) {
  final text = cell.trim().toLowerCase();
  if (text.isEmpty) return null;
  for (final category in ExpenseCategory.values) {
    if (category.name == text) return category;
  }
  throw FormatException('Unknown category', cell);
}

/// Minimal RFC 4180 reader: quoted fields with commas, doubled quotes and
/// line breaks; CRLF or LF line endings; a leading BOM is ignored.
List<List<String>> parseCsv(String source) {
  final text = source.startsWith('\uFEFF') ? source.substring(1) : source;
  final records = <List<String>>[];
  var record = <String>[];
  final field = StringBuffer();
  var quoted = false;
  var i = 0;

  void endField() {
    record.add(field.toString());
    field.clear();
  }

  void endRecord() {
    endField();
    records.add(record);
    record = <String>[];
  }

  while (i < text.length) {
    final char = text[i];
    if (quoted) {
      if (char == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i += 2;
          continue;
        }
        quoted = false;
      } else {
        field.write(char);
      }
      i++;
      continue;
    }
    switch (char) {
      case '"':
        quoted = true;
      case ',':
        endField();
      case '\r':
        if (i + 1 < text.length && text[i + 1] == '\n') i++;
        endRecord();
      case '\n':
        endRecord();
      default:
        field.write(char);
    }
    i++;
  }
  if (field.isNotEmpty || record.isNotEmpty) endRecord();
  return records;
}
