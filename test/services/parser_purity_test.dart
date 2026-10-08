import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _package = 'package:vku_expense_ocr/';
final RegExp _directive = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

/// Every import URI reachable from `lib/<path>` through this package's files.
Set<String> transitiveImports(String path) {
  final seen = <String>{};
  final uris = <String>{};
  void visit(String libPath) {
    if (!seen.add(libPath)) return;
    final source = File('lib/$libPath').readAsStringSync();
    for (final match in _directive.allMatches(source)) {
      final uri = match.group(1)!;
      uris.add(uri);
      if (uri.startsWith(_package)) visit(uri.substring(_package.length));
    }
  }

  visit(path);
  return uris;
}

bool _isFlutterOrMlKit(String uri) =>
    uri.startsWith('package:flutter') || uri.contains('google_mlkit');

void main() {
  test('receipt parser is pure Dart: no Flutter, no ML Kit, no dart:ui', () {
    final imports = transitiveImports('services/receipt_parser.dart');
    expect(imports.where(_isFlutterOrMlKit), isEmpty);
    expect(imports, isNot(contains('dart:ui')));
  });

  test('row grouper uses no Flutter package and no ML Kit', () {
    // dart:ui is allowed here only for Rect, which FR-2.2 requires in OcrLine.
    final imports = transitiveImports('services/row_grouper.dart');
    expect(imports.where(_isFlutterOrMlKit), isEmpty);
  });
}
