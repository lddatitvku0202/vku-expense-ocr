import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final RegExp _directive = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

List<String> _importsOf(File file) => [
  for (final m in _directive.allMatches(file.readAsStringSync())) m.group(1)!,
];

/// Package names under `dependencies:` / `dev_dependencies:` of pubspec.yaml.
Set<String> _declaredPackages() {
  final names = <String>{};
  var inDeps = false;
  for (final line in File('pubspec.yaml').readAsLinesSync()) {
    if (RegExp(r'^\S').hasMatch(line)) {
      inDeps =
          line.startsWith('dependencies:') ||
          line.startsWith('dev_dependencies:');
      continue;
    }
    final match = RegExp(r'^  ([a-z0-9_]+):').firstMatch(line);
    if (inDeps && match != null) names.add(match.group(1)!);
  }
  return names;
}

/// Every package in pubspec.lock, direct or transitive.
Set<String> _lockedPackages() => {
  for (final m in RegExp(
    r'^  ([a-z0-9_]+):$',
    multiLine: true,
  ).allMatches(File('pubspec.lock').readAsStringSync()))
    m.group(1)!,
};

void main() {
  test('no chart library anywhere in the dependencies (brief 3.3, 2.1)', () {
    final packages = {..._declaredPackages(), ..._lockedPackages()};
    expect(packages, isNotEmpty);
    expect(packages.where((p) => p.contains('chart')), isEmpty);
    for (final banned in [
      'fl_chart',
      'syncfusion_flutter_charts',
      'graphic',
      'pie_chart',
    ]) {
      expect(packages, isNot(contains(banned)));
    }
  });

  test('no file in lib/ imports a chart package', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final file in files) {
      for (final uri in _importsOf(file)) {
        final isPackage =
            uri.startsWith('package:') &&
            !uri.startsWith('package:vku_expense_ocr/');
        expect(
          isPackage && uri.contains('chart'),
          isFalse,
          reason: '${file.path}: $uri',
        );
      }
    }
  });

  test('chart geometry is pure: only dart:math and dart:ui', () {
    final imports = _importsOf(File('lib/widgets/charts/chart_geometry.dart'));
    expect(imports.toSet().difference({'dart:math', 'dart:ui'}), isEmpty);
  });

  test('the charts draw with CustomPainter', () {
    for (final name in [
      'donut_chart_painter.dart',
      'weekly_bar_painter.dart',
    ]) {
      final source = File('lib/widgets/charts/$name').readAsStringSync();
      expect(source, contains('extends CustomPainter'), reason: name);
    }
  });
}
