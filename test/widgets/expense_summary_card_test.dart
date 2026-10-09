import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:vku_expense_ocr/core/category_style.dart';
import 'package:vku_expense_ocr/models/expense.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/widgets/expense_summary_card.dart';

Expense _expense({String? thumbPath}) => Expense(
  id: 3,
  merchant: 'Highlands Coffee',
  amount: 150000,
  date: DateTime(2026, 10, 8, 9, 30),
  category: ExpenseCategory.food,
  thumbPath: thumbPath,
  createdAt: DateTime(2026, 10, 8),
  updatedAt: DateTime(2026, 10, 8),
);

void main() {
  Future<void> pumpCard(
    WidgetTester tester,
    Expense expense, {
    VoidCallback? onTap,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ExpenseSummaryCard(expense: expense, onTap: onTap),
      ),
    ),
  );

  testWidgets(
    'Week 7 lab layout: icon in a circle, name over date, amount (FR-7.3)',
    (tester) async {
      await pumpCard(tester, _expense());

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect((avatar.child! as Icon).icon, ExpenseCategory.food.icon);
      expect(find.text('Highlands Coffee'), findsOneWidget);
      expect(find.text('08/10/2026'), findsOneWidget);
      expect(find.text('150.000 đ'), findsOneWidget);

      final column = tester.widget<Column>(
        find
            .ancestor(
              of: find.text('Highlands Coffee'),
              matching: find.byType(Column),
            )
            .first,
      );
      expect(column.crossAxisAlignment, CrossAxisAlignment.start);
      expect(
        tester.getTopLeft(find.text('08/10/2026')).dy,
        greaterThan(tester.getTopLeft(find.text('Highlands Coffee')).dy),
      );
      expect(
        find.ancestor(of: find.byType(InkWell), matching: find.byType(Card)),
        findsOneWidget,
      );
    },
  );

  testWidgets('tapping the card calls onTap', (tester) async {
    var taps = 0;
    await pumpCard(tester, _expense(), onTap: () => taps++);
    await tester.tap(find.byType(ExpenseSummaryCard));
    expect(taps, 1);
  });

  testWidgets('no thumbnail path: no thumbnail', (tester) async {
    await pumpCard(tester, _expense());
    expect(find.byKey(ExpenseSummaryCard.thumbnailKey), findsNothing);
  });

  testWidgets('shows the thumbnail, decoded small (cacheWidth)', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('vku_card_test_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = p.join(dir.path, 't.jpg');
    File(path)
        .writeAsBytesSync(img.encodeJpg(img.Image(width: 256, height: 384)));

    await pumpCard(tester, _expense(thumbPath: path));
    final image = tester.widget<Image>(
      find.descendant(
        of: find.byKey(ExpenseSummaryCard.thumbnailKey),
        matching: find.byType(Image),
      ),
    );
    final provider = image.image as ResizeImage;
    expect(
      provider.width,
      ExpenseSummaryCard.thumbnailSize * 3,
      reason: 'test view is 3x',
    );
    expect(find.byKey(ExpenseSummaryCard.missingThumbnailKey), findsNothing);
  });

  testWidgets('a lost thumbnail file shows a placeholder icon, no crash', (
    tester,
  ) async {
    await pumpCard(tester, _expense(thumbPath: '/nowhere/lost_thumb.jpg'));
    // Let the real file read fail, then rebuild with the error builder.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();

    expect(find.byKey(ExpenseSummaryCard.missingThumbnailKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
