/// The five fixed spending categories (FR-3.5, FR-5.5).
///
/// Pure Dart so the receipt parser can return it without depending on
/// Flutter. Icon and colour live in `ExpenseCategoryStyle`
/// (`lib/core/category_style.dart`).
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
