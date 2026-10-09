import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vku_expense_ocr/models/expense.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/screens/dashboard/dashboard_screen.dart';
import 'package:vku_expense_ocr/state/expense_providers.dart';
import 'package:vku_expense_ocr/state/storage_providers.dart';

import '../support/fake_expense_repository.dart';
import '../support/fake_image_storage.dart';

final _now = DateTime(2026, 10, 9, 20);

Expense _e(int id, int amount, DateTime date) => Expense(
  id: id,
  merchant: 'm$id',
  amount: amount,
  date: date,
  category: ExpenseCategory.food,
  createdAt: date,
  updatedAt: date,
);

void main() {
  late FakeExpenseRepository repo;

  setUp(() {
    repo = FakeExpenseRepository([
      _e(1, 150000, DateTime(2026, 10, 2)),
      _e(2, 1100000, DateTime(2026, 10, 9, 8)),
      _e(3, 45000, DateTime(2026, 9, 30)),
    ]);
  });

  Future<ProviderContainer> pumpDashboard(
    WidgetTester tester, {
    Size physicalSize = const Size(1080, 2400),
  }) async {
    tester.view
      ..physicalSize = physicalSize
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/review',
          builder: (context, state) =>
              Scaffold(body: Text('manual entry ${state.extra}')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(repo),
          imageStorageProvider.overrideWithValue(FakeImageStorage()),
          clockProvider.overrideWithValue(() => _now),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(DashboardScreen)),
    );
  }

  Finder total() => find.byKey(DashboardScreen.monthTotalKey);
  String totalText(WidgetTester tester) => tester.widget<Text>(total()).data!;

  testWidgets('shows the total of the selected month (October 2026)', (
    tester,
  ) async {
    await pumpDashboard(tester);

    expect(find.text('Tháng 10/2026'), findsOneWidget);
    expect(totalText(tester), '1.250.000 đ');
    expect(find.text('2 giao dịch'), findsOneWidget);
  });

  testWidgets('month buttons move the month; next stops at the current month', (
    tester,
  ) async {
    await pumpDashboard(tester);

    IconButton next() =>
        tester.widget<IconButton>(find.byKey(DashboardScreen.nextMonthKey));
    expect(next().onPressed, isNull, reason: 'no future months');

    await tester.tap(find.byKey(DashboardScreen.previousMonthKey));
    await tester.pumpAndSettle();
    expect(find.text('Tháng 9/2026'), findsOneWidget);
    expect(totalText(tester), '45.000 đ');
    expect(next().onPressed, isNotNull);

    await tester.tap(find.byKey(DashboardScreen.previousMonthKey));
    await tester.pumpAndSettle();
    expect(totalText(tester), '0 đ');
    expect(find.text('Chưa có giao dịch trong tháng này'), findsOneWidget);

    await tester.tap(find.byKey(DashboardScreen.nextMonthKey));
    await tester.tap(find.byKey(DashboardScreen.nextMonthKey));
    await tester.pumpAndSettle();
    expect(find.text('Tháng 10/2026'), findsOneWidget);
  });

  testWidgets('the total follows new expenses (FR-6.5)', (tester) async {
    final c = await pumpDashboard(tester);

    await c
        .read(expenseListProvider.notifier)
        .add(_e(9, 50000, DateTime(2026, 10, 9, 12)).copyWithoutId());
    await tester.pumpAndSettle();
    expect(totalText(tester), '1.300.000 đ');
  });

  testWidgets('keeps a place for the two Phase 9 charts', (tester) async {
    await pumpDashboard(tester);
    expect(find.byKey(DashboardScreen.donutSlotKey), findsOneWidget);
    expect(find.byKey(DashboardScreen.weeklySlotKey), findsOneWidget);
  });

  testWidgets('wide screens put the two chart places side by side (FR-8.2)', (
    tester,
  ) async {
    await pumpDashboard(tester, physicalSize: const Size(2400, 1080));
    final donut = tester.getRect(find.byKey(DashboardScreen.donutSlotKey));
    final weekly = tester.getRect(find.byKey(DashboardScreen.weeklySlotKey));
    expect(donut.top, weekly.top);
    expect(weekly.left, greaterThan(donut.right - 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Thêm thủ công" opens the Review form without a photo', (
    tester,
  ) async {
    await pumpDashboard(tester);

    await tester.tap(find.byKey(DashboardScreen.addButtonKey));
    await tester.pumpAndSettle();
    expect(find.text('manual entry null'), findsOneWidget);
  });
}

extension on Expense {
  /// A new, unsaved copy (the repository assigns the id).
  Expense copyWithoutId() => Expense(
    merchant: merchant,
    amount: amount,
    date: date,
    category: category,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
