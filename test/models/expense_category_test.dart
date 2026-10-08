import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/core/category_style.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';

void main() {
  test('has exactly the five required categories', () {
    expect(ExpenseCategory.values.map((c) => c.name), [
      'food',
      'study',
      'travel',
      'gear',
      'entertainment',
    ]);
  });

  test('every category has its Vietnamese label', () {
    expect(ExpenseCategory.food.label, 'Ăn uống');
    expect(ExpenseCategory.study.label, 'Học tập');
    expect(ExpenseCategory.travel.label, 'Di chuyển');
    expect(ExpenseCategory.gear.label, 'Thiết bị');
    expect(ExpenseCategory.entertainment.label, 'Giải trí');
  });

  test('every category has its own icon', () {
    expect(ExpenseCategory.food.icon, Icons.restaurant);
    expect(ExpenseCategory.study.icon, Icons.menu_book);
    expect(ExpenseCategory.travel.icon, Icons.two_wheeler);
    expect(ExpenseCategory.gear.icon, Icons.devices_other);
    expect(ExpenseCategory.entertainment.icon, Icons.movie);
  });

  test('labels, icons and colours are all distinct', () {
    const values = ExpenseCategory.values;
    expect(values.map((c) => c.label).toSet(), hasLength(values.length));
    expect(values.map((c) => c.icon).toSet(), hasLength(values.length));
    expect(values.map((c) => c.color).toSet(), hasLength(values.length));
  });

  test('colours are fully opaque so chart slices never blend', () {
    for (final category in ExpenseCategory.values) {
      expect(category.color.a, 1.0, reason: category.name);
    }
  });

  group('database value', () {
    test('round-trips through fromDbValue', () {
      for (final category in ExpenseCategory.values) {
        expect(ExpenseCategory.fromDbValue(category.dbValue), category);
      }
    });

    test('rejects values outside the five categories', () {
      expect(
        () => ExpenseCategory.fromDbValue('shopping'),
        throwsFormatException,
      );
      expect(() => ExpenseCategory.fromDbValue('Food'), throwsFormatException);
    });
  });
}
