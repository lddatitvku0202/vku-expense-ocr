import 'package:flutter/material.dart';

/// The five fixed spending categories (FR-3.5, FR-5.5).
///
/// Display data is derived with Dart 3 switch expressions (W7 s14): the
/// compiler checks that every category is handled, so adding a sixth value
/// without updating each switch is a compile error.
enum ExpenseCategory {
  food,
  study,
  travel,
  gear,
  entertainment;

  /// Vietnamese label shown in the UI.
  String get label => switch (this) {
    food => 'Ăn uống',
    study => 'Học tập',
    travel => 'Di chuyển',
    gear => 'Thiết bị',
    entertainment => 'Giải trí',
  };

  IconData get icon => switch (this) {
    food => Icons.restaurant,
    study => Icons.menu_book,
    travel => Icons.two_wheeler,
    gear => Icons.devices_other,
    entertainment => Icons.movie,
  };

  /// Chart and badge colour, readable in both light and dark themes.
  Color get color => switch (this) {
    food => const Color(0xFFEF6C00),
    study => const Color(0xFF1E88E5),
    travel => const Color(0xFF43A047),
    gear => const Color(0xFF8E24AA),
    entertainment => const Color(0xFFE53935),
  };

  /// Value stored in the `category` column of the database.
  String get dbValue => name;

  /// Inverse of [dbValue]. Throws [FormatException] for unknown values so a
  /// corrupted row is never silently shown under the wrong category.
  static ExpenseCategory fromDbValue(String value) {
    for (final category in values) {
      if (category.dbValue == value) return category;
    }
    throw FormatException('Unknown expense category', value);
  }
}
