import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/core/app_theme.dart';

void main() {
  test('seed colour is VKU Navy', () {
    expect(AppTheme.seedColor, const Color(0xFF2C4570));
  });

  test('light and dark themes are Material 3 with matching brightness', () {
    expect(AppTheme.light.useMaterial3, isTrue);
    expect(AppTheme.dark.useMaterial3, isTrue);
    expect(AppTheme.light.colorScheme.brightness, Brightness.light);
    expect(AppTheme.dark.colorScheme.brightness, Brightness.dark);
  });

  test('both themes are generated from the same seed', () {
    final light = ColorScheme.fromSeed(seedColor: AppTheme.seedColor);
    final dark = ColorScheme.fromSeed(
      seedColor: AppTheme.seedColor,
      brightness: Brightness.dark,
    );
    expect(AppTheme.light.colorScheme.primary, light.primary);
    expect(AppTheme.dark.colorScheme.primary, dark.primary);
  });
}
