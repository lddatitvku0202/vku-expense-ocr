import 'package:flutter/material.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';

/// Icon and colour of each [ExpenseCategory] (FR-5.5).
///
/// Kept out of the enum so the model (and the receipt parser that returns
/// it) stays free of Flutter UI imports.
extension ExpenseCategoryStyle on ExpenseCategory {
  IconData get icon => switch (this) {
    ExpenseCategory.food => Icons.restaurant,
    ExpenseCategory.study => Icons.menu_book,
    ExpenseCategory.travel => Icons.two_wheeler,
    ExpenseCategory.gear => Icons.devices_other,
    ExpenseCategory.entertainment => Icons.movie,
  };

  /// Chart and badge colour on a light page.
  Color get color => switch (this) {
    ExpenseCategory.food => const Color(0xFFC25100),
    ExpenseCategory.study => const Color(0xFF1565C0),
    ExpenseCategory.travel => const Color(0xFF2E7D32),
    ExpenseCategory.gear => const Color(0xFF8E24AA),
    ExpenseCategory.entertainment => const Color(0xFFE53935),
  };

  /// The same hue lightened for a dark page, where [color] would be too
  /// dim to tell the chart slices apart (3:1 against the surface).
  Color get darkColor => switch (this) {
    ExpenseCategory.food => const Color(0xFFFFA040),
    ExpenseCategory.study => const Color(0xFF64B5F6),
    ExpenseCategory.travel => const Color(0xFF81C784),
    ExpenseCategory.gear => const Color(0xFFCE93D8),
    ExpenseCategory.entertainment => const Color(0xFFEF9A9A),
  };

  /// The colour to use on a page of the given [brightness].
  Color colorOn(Brightness brightness) =>
      brightness == Brightness.dark ? darkColor : color;
}
