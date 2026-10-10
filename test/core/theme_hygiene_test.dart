import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Colours are chosen by the theme (FR-8.1): a fixed colour in a screen
/// can be unreadable on the other theme's background.
void main() {
  /// Files that may name colours: the theme itself, the category palette
  /// (FR-5.5, contrast-tested in contrast_test.dart), the camera
  /// viewfinder and the full-screen photo viewer (always dark).
  const allowed = {
    'lib/core/app_theme.dart',
    'lib/core/category_style.dart',
    'lib/screens/scan/camera_screen.dart',
    'lib/widgets/receipt_image_view.dart',
  };

  test('no fixed colour outside the theme, palette and camera files', () {
    final pattern = RegExp(r'Colors\.|Color\(0x');
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (allowed.contains(path)) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (pattern.hasMatch(lines[i])) offenders.add('$path:${i + 1}');
      }
    }
    expect(offenders, isEmpty);
  });

  test('the camera screen keeps its colours in one place', () {
    final source = File('lib/screens/scan/camera_screen.dart')
        .readAsStringSync();
    expect(RegExp(r'Colors\.').allMatches(source), hasLength(4));
    expect(source, contains('abstract final class _Viewfinder'));
  });
}
