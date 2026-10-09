import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vku_expense_ocr/app.dart';
import 'package:vku_expense_ocr/core/router.dart';
import 'package:vku_expense_ocr/models/parsed_receipt.dart';
import 'package:vku_expense_ocr/screens/dashboard/dashboard_screen.dart';
import 'package:vku_expense_ocr/screens/history/history_screen.dart';
import 'package:vku_expense_ocr/screens/review/review_screen.dart';
import 'package:vku_expense_ocr/screens/scan/camera_screen.dart';
import 'package:vku_expense_ocr/services/receipt_scan_service.dart';
import 'package:vku_expense_ocr/state/router_provider.dart';
import 'package:vku_expense_ocr/state/storage_providers.dart';

import 'support/memory_settings_store.dart';

void main() {
  /// Pumps the real app with a router that starts at [location].
  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    String location = AppRoutes.dashboard,
  }) async {
    final router = createAppRouter(initialLocation: location);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routerProvider.overrideWithValue(router),
          settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
        ],
        child: const VkuExpenseApp(),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('app starts on the dashboard tab without errors', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
        ],
        child: const VkuExpenseApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('navigation bar has the three required tabs', (tester) async {
    await pumpApp(tester);

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    final labels = bar.destinations.whereType<NavigationDestination>().map(
      (d) => d.label,
    );
    expect(labels, ['Tổng quan', 'Quét', 'Lịch sử']);
    expect(bar.selectedIndex, 0);
  });

  testWidgets('tapping tabs switches screens', (tester) async {
    final router = await pumpApp(tester);

    await tester.tap(find.text('Lịch sử').last);
    await tester.pumpAndSettle();
    expect(find.byType(HistoryScreen), findsOneWidget);
    expect(router.state.uri.path, AppRoutes.history);

    await tester.tap(find.text('Quét').last);
    await tester.pumpAndSettle();
    expect(find.byType(CameraScreen), findsOneWidget);
    expect(router.state.uri.path, AppRoutes.scan);

    await tester.tap(find.text('Tổng quan').last);
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('/expense/:id opens the edit form with the id', (tester) async {
    await pumpApp(tester, location: AppRoutes.expense(42));

    final screen = tester.widget<ReviewScreen>(find.byType(ReviewScreen));
    expect(screen.expenseId, 42);
    expect(find.text('Sửa giao dịch'), findsWidgets);
  });

  testWidgets('/review receives the parsed receipt through extra', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    const receipt = ParsedReceipt.empty(rawText: 'TOTAL');

    unawaited(router.push(AppRoutes.review, extra: receipt));
    await tester.pumpAndSettle();

    final screen = tester.widget<ReviewScreen>(find.byType(ReviewScreen));
    expect(screen.receipt, same(receipt));
    expect(screen.expenseId, isNull);
  });

  testWidgets('/review receives a scan result (photo + parse) through extra', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    const result = ScanResult(
      imagePath: '/cache/cropped.jpg',
      receipt: ParsedReceipt.empty(rawText: 'TOTAL'),
      rows: ['TOTAL'],
      ocrDuration: Duration(milliseconds: 900),
    );

    unawaited(router.push(AppRoutes.review, extra: result));
    await tester.pumpAndSettle();

    final screen = tester.widget<ReviewScreen>(find.byType(ReviewScreen));
    expect(screen.scan, same(result));
    expect(screen.receipt, same(result.receipt));
  });

  testWidgets('/review without extra opens manual entry', (tester) async {
    await pumpApp(tester, location: AppRoutes.review);

    final screen = tester.widget<ReviewScreen>(find.byType(ReviewScreen));
    expect(screen.receipt, isNull);
    expect(find.text('Thêm giao dịch thủ công'), findsOneWidget);
  });

  testWidgets('unknown or malformed paths show the not-found page', (
    tester,
  ) async {
    await pumpApp(tester, location: '/expense/abc');
    expect(find.text('Trang không tồn tại'), findsOneWidget);

    await tester.tap(find.text('Về Tổng quan'));
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);
  });
}
