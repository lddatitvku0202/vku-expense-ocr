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

  /// Chart and badge colour, readable in both light and dark themes.
  Color get color => switch (this) {
    ExpenseCategory.food => const Color(0xFFEF6C00),
    ExpenseCategory.study => const Color(0xFF1E88E5),
    ExpenseCategory.travel => const Color(0xFF43A047),
    ExpenseCategory.gear => const Color(0xFF8E24AA),
    ExpenseCategory.entertainment => const Color(0xFFE53935),
  };
}
