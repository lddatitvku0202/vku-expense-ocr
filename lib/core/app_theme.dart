import 'package:flutter/material.dart';

/// Material 3 themes generated from the VKU Navy seed colour (FR-8.1).
abstract final class AppTheme {
  /// VKU Navy.
  static const Color seedColor = Color(0xFF2C4570);

  static final ThemeData light = _build(Brightness.light);

  static final ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: colorScheme,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      cardTheme: const CardThemeData(clipBehavior: Clip.antiAlias),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
