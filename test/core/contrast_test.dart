import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/core/app_theme.dart';
import 'package:vku_expense_ocr/core/category_style.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';

/// WCAG 2 contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  const themes = {'light': Brightness.light, 'dark': Brightness.dark};

  for (final MapEntry(key: name, value: brightness) in themes.entries) {
    final scheme =
        (brightness == Brightness.light ? AppTheme.light : AppTheme.dark)
            .colorScheme;

    group('$name theme: text pairs used by the app reach 4.5:1 (WCAG AA)', () {
      final pairs = <String, (Color, Color)>{
        'body text on the page': (scheme.onSurface, scheme.surface),
        'secondary text on the page': (scheme.onSurfaceVariant, scheme.surface),
        'month total (primary) on a card': (scheme.primary, scheme.surface),
        'missing-field note (error) on the page': (
          scheme.error,
          scheme.surface,
        ),
        'low-confidence note (tertiary) on the page': (
          scheme.tertiary,
          scheme.surface,
        ),
        'merchant banner, missing (error container)': (
          scheme.onErrorContainer,
          scheme.errorContainer,
        ),
        'merchant banner, low (tertiary container)': (
          scheme.onTertiaryContainer,
          scheme.tertiaryContainer,
        ),
        'delete swipe background': (
          scheme.onErrorContainer,
          scheme.errorContainer,
        ),
        'text on the donut track and thumbnails': (
          scheme.onSurface,
          scheme.surfaceContainerHighest,
        ),
      };
      for (final MapEntry(key: label, value: (fg, bg)) in pairs.entries) {
        test(label, () {
          expect(contrast(fg, bg), greaterThanOrEqualTo(4.5));
        });
      }
    });

    group('$name theme: category colours reach 3:1 as graphics', () {
      for (final category in ExpenseCategory.values) {
        final color = category.colorOn(brightness);
        test('${category.name} on the page', () {
          expect(contrast(color, scheme.surface), greaterThanOrEqualTo(3));
        });
        test('${category.name} on the donut track', () {
          expect(
            contrast(color, scheme.surfaceContainerHighest),
            greaterThanOrEqualTo(3),
          );
        });
      }

      test('the five colours stay different from each other', () {
        final colors = [
          for (final c in ExpenseCategory.values) c.colorOn(brightness),
        ];
        expect(colors.toSet(), hasLength(5));
      });
    });
  }

  test('the light palette is the one defined for FR-5.5', () {
    for (final category in ExpenseCategory.values) {
      expect(category.colorOn(Brightness.light), category.color);
    }
  });
}
