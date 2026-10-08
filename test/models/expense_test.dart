import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/models/expense.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';

void main() {
  final full = Expense(
    id: 7,
    merchant: 'Highlands Coffee',
    amount: 59000,
    date: DateTime(2026, 10, 8, 9, 30),
    category: ExpenseCategory.food,
    imagePath: '/data/receipts/7.jpg',
    thumbPath: '/data/receipts/7_thumb.jpg',
    rawText: 'HIGHLANDS COFFEE\nTong thanh toan 59.000',
    createdAt: DateTime(2026, 10, 8, 9, 31, 5, 123),
    updatedAt: DateTime(2026, 10, 8, 9, 31, 5, 123),
  );

  group('Expense.toMap / fromMap', () {
    test('round-trips every field', () {
      expect(Expense.fromMap(full.toMap()), full);
    });

    test('round-trips an expense without optional fields', () {
      final minimal = Expense(
        merchant: 'Quán cơm Bà Năm',
        amount: 35000,
        date: DateTime(2026, 9, 30),
        category: ExpenseCategory.food,
        createdAt: DateTime(2026, 9, 30, 12),
        updatedAt: DateTime(2026, 9, 30, 12),
      );
      final restored = Expense.fromMap(minimal.toMap());
      expect(restored, minimal);
      expect(restored.id, isNull);
      expect(restored.imagePath, isNull);
    });

    test('uses the column names of the expenses table', () {
      expect(full.toMap().keys, [
        'id',
        'merchant',
        'amount',
        'date',
        'category',
        'image_path',
        'thumb_path',
        'raw_text',
        'created_at',
        'updated_at',
      ]);
    });

    test('omits id before the first insert so SQLite can assign it', () {
      expect(full.copyWith().toMap().containsKey('id'), isTrue);
      final unsaved = Expense.fromMap({...full.toMap()}..remove('id'));
      expect(unsaved.toMap().containsKey('id'), isFalse);
    });

    test('stores amount as int and dates as epoch milliseconds', () {
      final map = full.toMap();
      expect(map['amount'], isA<int>());
      expect(map['date'], DateTime(2026, 10, 8, 9, 30).millisecondsSinceEpoch);
      expect(map['category'], 'food');
    });

    test('rejects an unknown category', () {
      final map = {...full.toMap(), 'category': 'shopping'};
      expect(() => Expense.fromMap(map), throwsFormatException);
    });
  });

  group('Expense.copyWith', () {
    test('replaces only the given fields', () {
      final updated = full.copyWith(amount: 60000, merchant: 'Highlands');
      expect(updated.amount, 60000);
      expect(updated.merchant, 'Highlands');
      expect(updated.id, full.id);
      expect(updated.imagePath, full.imagePath);
    });

    test('can clear nullable fields with a ValueGetter', () {
      final cleared = full.copyWith(
        imagePath: () => null,
        thumbPath: () => null,
      );
      expect(cleared.imagePath, isNull);
      expect(cleared.thumbPath, isNull);
      expect(cleared.rawText, full.rawText);
    });

    test('without arguments returns an equal copy', () {
      expect(full.copyWith(), full);
      expect(full.copyWith().hashCode, full.hashCode);
    });
  });
}
