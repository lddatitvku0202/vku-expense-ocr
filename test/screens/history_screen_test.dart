import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vku_expense_ocr/models/expense.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/screens/history/history_screen.dart';
import 'package:vku_expense_ocr/state/expense_providers.dart';
import 'package:vku_expense_ocr/state/storage_providers.dart';
import 'package:vku_expense_ocr/widgets/expense_summary_card.dart';

import '../support/fake_expense_repository.dart';
import '../support/fake_image_storage.dart';

final _now = DateTime(2026, 10, 9, 20);

Expense _e(int id, String merchant, DateTime date, ExpenseCategory category) =>
    Expense(
      id: id,
      merchant: merchant,
      amount: id * 10000,
      date: date,
      category: category,
      imagePath: '/docs/receipts/$id.jpg',
      thumbPath: '/docs/receipts/${id}_thumb.jpg',
      createdAt: date,
      updatedAt: date,
    );

final _highlands = _e(
  1,
  'Highlands',
  DateTime(2026, 10, 6),
  ExpenseCategory.food,
);
final _fahasa = _e(2, 'Fahasa', DateTime(2026, 10, 8), ExpenseCategory.study);
final _grab = _e(3, 'Grab', DateTime(2026, 10, 2), ExpenseCategory.travel);
final _circleK = _e(4, 'Circle K', DateTime(2026, 10, 9), ExpenseCategory.food);

void main() {
  late FakeExpenseRepository repo;
  late FakeImageStorage storage;

  setUp(() {
    repo = FakeExpenseRepository([_highlands, _fahasa, _grab, _circleK]);
    storage = FakeImageStorage();
  });

  Future<ProviderContainer> pumpHistory(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HistoryScreen()),
        GoRoute(
          path: '/expense/:id',
          builder: (context, state) =>
              Scaffold(body: Text('edit ${state.pathParameters['id']}')),
        ),
        GoRoute(
          path: '/review',
          builder: (context, state) =>
              const Scaffold(body: Text('manual entry')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(repo),
          imageStorageProvider.overrideWithValue(storage),
          clockProvider.overrideWithValue(() => _now),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(HistoryScreen)),
    );
  }

  List<String> shownMerchants(WidgetTester tester) {
    final cards =
        tester
            .widgetList<ExpenseSummaryCard>(find.byType(ExpenseSummaryCard))
            .toList()
          ..sort(
            (a, b) => tester
                .getTopLeft(find.byWidget(a))
                .dy
                .compareTo(tester.getTopLeft(find.byWidget(b)).dy),
          );
    return [for (final card in cards) card.expense.merchant];
  }

  Future<void> swipeAway(WidgetTester tester, int id) async {
    await tester.drag(find.byKey(ValueKey<int>(id)), const Offset(-600, 0));
    await tester.pumpAndSettle();
  }

  testWidgets('lists every expense, newest first (FR-7.3)', (tester) async {
    await pumpHistory(tester);

    expect(shownMerchants(tester), ['Circle K', 'Fahasa', 'Highlands', 'Grab']);
    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(Dismissible), findsNWidgets(4));
    expect(find.byKey(const ValueKey<int>(4)), findsOneWidget);
  });

  testWidgets('category chips filter the list', (tester) async {
    await pumpHistory(tester);

    await tester.tap(find.byKey(const Key('history-filter-food')));
    await tester.pumpAndSettle();
    expect(shownMerchants(tester), ['Circle K', 'Highlands']);

    await tester.tap(find.byKey(const Key('history-filter-study')));
    await tester.pumpAndSettle();
    expect(shownMerchants(tester), ['Fahasa']);

    await tester.tap(find.byKey(const Key('history-filter-all')));
    await tester.pumpAndSettle();
    expect(shownMerchants(tester), hasLength(4));
  });

  testWidgets('empty: "no expenses yet" with a way to add one', (tester) async {
    repo = FakeExpenseRepository();
    await pumpHistory(tester);

    expect(find.text('Chưa có giao dịch nào'), findsOneWidget);
    expect(find.byKey(const Key('history-filter-food')), findsNothing);
  });

  testWidgets('empty filter: says the selected category has no expenses', (
    tester,
  ) async {
    await pumpHistory(tester);

    await tester.tap(find.byKey(const Key('history-filter-entertainment')));
    await tester.pumpAndSettle();
    expect(
      find.text('Không có giao dịch thuộc danh mục Giải trí'),
      findsOneWidget,
    );
    expect(find.text('Chưa có giao dịch nào'), findsNothing);

    await tester.tap(find.text('Xem tất cả'));
    await tester.pumpAndSettle();
    expect(shownMerchants(tester), hasLength(4));
  });

  testWidgets('tapping a card opens /expense/:id (FR-7.2)', (tester) async {
    await pumpHistory(tester);

    await tester.tap(find.text('Fahasa'));
    await tester.pumpAndSettle();
    expect(find.text('edit 2'), findsOneWidget);
  });

  testWidgets('the add button opens manual entry', (tester) async {
    await pumpHistory(tester);

    await tester.tap(find.byKey(HistoryScreen.addButtonKey));
    await tester.pumpAndSettle();
    expect(find.text('manual entry'), findsOneWidget);
  });

  group('swipe to delete + Undo (FR-5.4)', () {
    testWidgets('the snack bar lasts exactly the shared Undo window', (
      tester,
    ) async {
      await pumpHistory(tester);
      await swipeAway(tester, 2);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.duration, ExpenseListNotifier.undoWindow);
      expect(find.text('Đã xóa "Fahasa"'), findsOneWidget);
    });

    testWidgets(
      'Undo while the snack bar shows restores the expense and its photo',
      (tester) async {
        final c = await pumpHistory(tester);
        await swipeAway(tester, 2);
        expect(shownMerchants(tester), ['Circle K', 'Highlands', 'Grab']);

        // Exactly one Undo window after the swipe the snack bar is still
        // showing (its timer starts after the entry animation); a deletion
        // timer started at the swipe would already have removed the photo.
        await tester.pump(ExpenseListNotifier.undoWindow);
        expect(find.text('Hoàn tác'), findsOneWidget);
        expect(storage.deletedPaths, isEmpty);

        await tester.tap(find.text('Hoàn tác'));
        await tester.pumpAndSettle();

        expect(shownMerchants(tester), [
          'Circle K',
          'Fahasa',
          'Highlands',
          'Grab',
        ]);
        expect(await repo.getById(2), _fahasa);
        await tester.pump(ExpenseListNotifier.undoWindow * 2);
        expect(storage.deletedPaths, isEmpty, reason: 'the photo is kept');
        expect(
          c.read(expenseListProvider.notifier).isPendingDeletion(2),
          isFalse,
        );
      },
    );

    testWidgets(
      'when the snack bar times out the deletion is final, photo included',
      (tester) async {
        await pumpHistory(tester);
        await swipeAway(tester, 2);

        await tester.pump(
          ExpenseListNotifier.undoWindow + const Duration(seconds: 1),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsNothing);
        expect(storage.deletedPaths, [
          '/docs/receipts/2.jpg',
          '/docs/receipts/2_thumb.jpg',
        ]);
        expect(await repo.getById(2), isNull);
      },
    );

    testWidgets(
      'two deletions in a row: the second snack bar replaces the first',
      (tester) async {
        await pumpHistory(tester);

        await swipeAway(tester, 2); // Fahasa
        await swipeAway(tester, 1); // Highlands

        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('Đã xóa "Highlands"'), findsOneWidget);
        expect(find.text('Đã xóa "Fahasa"'), findsNothing);
        // The first deletion is final, photo included.
        expect(storage.deletedPaths, [
          '/docs/receipts/2.jpg',
          '/docs/receipts/2_thumb.jpg',
        ]);

        await tester.tap(find.text('Hoàn tác'));
        await tester.pumpAndSettle();

        expect(shownMerchants(tester), ['Circle K', 'Highlands', 'Grab']);
        expect(await repo.getById(1), _highlands);
        expect(await repo.getById(2), isNull);
        await tester.pump(ExpenseListNotifier.undoWindow * 2);
        expect(
          storage.deletedPaths,
          hasLength(2),
          reason: 'Highlands photo kept',
        );
      },
    );

    testWidgets(
      'a swiped card leaves the list at once (no Dismissible error)',
      (tester) async {
        await pumpHistory(tester);
        await swipeAway(tester, 4);

        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey<int>(4)), findsNothing);
      },
    );
  });
}
