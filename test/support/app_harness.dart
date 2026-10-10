import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vku_expense_ocr/app.dart';
import 'package:vku_expense_ocr/core/router.dart';
import 'package:vku_expense_ocr/models/expense.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/models/field_confidence.dart';
import 'package:vku_expense_ocr/models/parsed_receipt.dart';
import 'package:vku_expense_ocr/services/camera_service.dart';
import 'package:vku_expense_ocr/services/expense_repository.dart';
import 'package:vku_expense_ocr/services/receipt_scan_service.dart';
import 'package:vku_expense_ocr/state/camera_providers.dart';
import 'package:vku_expense_ocr/state/router_provider.dart';
import 'package:vku_expense_ocr/state/storage_providers.dart';
import 'package:vku_expense_ocr/state/theme_mode_provider.dart';

import 'fake_camera.dart';
import 'fake_expense_repository.dart';
import 'fake_image_storage.dart';
import 'memory_settings_store.dart';

/// Friday 09/10/2026 20:00 for every harness-driven test.
final DateTime harnessNow = DateTime(2026, 10, 9, 20);

/// Expenses that stress layouts: long names, big amounts, every category,
/// photos, dates in the selected month and week.
List<Expense> stressExpenses() {
  Expense e(
    int id,
    String merchant,
    int amount,
    DateTime date,
    ExpenseCategory category,
  ) => Expense(
    id: id,
    merchant: merchant,
    amount: amount,
    date: date,
    category: category,
    imagePath: '/docs/receipts/$id.jpg',
    thumbPath: '/docs/receipts/${id}_thumb.jpg',
    rawText: 'RAW $merchant\nTổng $amount',
    createdAt: date,
    updatedAt: date,
  );
  return [
    e(
      1,
      'Siêu thị Co.opmart Huế Vincom Center Landmark 81 chi nhánh 5',
      123456789,
      DateTime(2026, 10, 5, 9),
      ExpenseCategory.food,
    ),
    e(2, 'Fahasa', 245000, DateTime(2026, 10, 6, 14), ExpenseCategory.study),
    e(3, 'Grab', 45000, DateTime(2026, 10, 7, 8), ExpenseCategory.travel),
    e(
      4,
      'Thế Giới Di Động',
      19990000,
      DateTime(2026, 10, 8, 10),
      ExpenseCategory.gear,
    ),
    e(
      5,
      'CGV Cinemas',
      180000,
      DateTime(2026, 10, 9, 19),
      ExpenseCategory.entertainment,
    ),
    e(
      6,
      'Highlands Coffee',
      59000,
      DateTime(2026, 10, 2, 9),
      ExpenseCategory.food,
    ),
  ];
}

/// A scan whose every field needs review: banner, icons and captions all
/// show, the widest the Review form gets.
ScanResult worstCaseScan() => const ScanResult(
  imagePath: '/cache/scan/receipt.jpg',
  receipt: ParsedReceipt(
    merchant: 'HICANOS toEFEF',
    total: 245000,
    rawText: 'HICANOS toEFEF\nTong 245.000',
    merchantConfidence: FieldConfidence.low,
    totalConfidence: FieldConfidence.low,
    dateConfidence: FieldConfidence.missing,
    categoryConfidence: FieldConfidence.missing,
  ),
  rows: ['HICANOS toEFEF', 'Tong 245.000'],
  ocrDuration: Duration(milliseconds: 4200),
);

/// Result of [pumpApp].
class AppHarness {
  AppHarness(this.router, this.container);

  final GoRouter router;
  final ProviderContainer container;
}

/// Pumps the real app (router, shell, theme) with fakes underneath.
///
/// [size] is in logical pixels (device pixel ratio 1). [location] is one of
/// the tabs; [pushed] is then pushed on top (Review, edit form).
Future<AppHarness> pumpApp(
  WidgetTester tester, {
  Size size = const Size(360, 640),
  double textScale = 1,
  ThemeMode themeMode = ThemeMode.light,
  String location = AppRoutes.dashboard,
  String? pushed,
  Object? pushedExtra,
  ExpenseRepository? repository,
  CameraSource? cameraSource,
  MemorySettingsStore? settings,
  bool settle = true,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });

  final router = createAppRouter(initialLocation: location);
  addTearDown(router.dispose);
  final store =
      settings ??
      MemorySettingsStore({ThemeModeNotifier.storageKey: themeMode.name});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        routerProvider.overrideWithValue(router),
        expenseRepositoryProvider.overrideWithValue(
          repository ?? FakeExpenseRepository(stressExpenses()),
        ),
        imageStorageProvider.overrideWithValue(FakeImageStorage()),
        clockProvider.overrideWithValue(() => harnessNow),
        settingsStoreProvider.overrideWithValue(store),
        cameraSourceProvider.overrideWithValue(
          cameraSource ?? FakeCameraSource(FakeReceiptCamera.new),
        ),
      ],
      child: const VkuExpenseApp(),
    ),
  );
  settle ? await tester.pumpAndSettle() : await tester.pump();
  if (pushed != null) {
    unawaited(router.push(pushed, extra: pushedExtra));
    settle ? await tester.pumpAndSettle() : await tester.pump();
  }
  final container = ProviderScope.containerOf(
    tester.element(find.byType(VkuExpenseApp)),
  );
  return AppHarness(router, container);
}

/// Scrolls the first scrollable to its end and back, so lazily built
/// content is laid out as well.
Future<void> scrollThrough(WidgetTester tester) async {
  final scrollable = find.byType(Scrollable);
  if (scrollable.evaluate().isEmpty) return;
  await tester.drag(scrollable.first, const Offset(0, -4000));
  await tester.pumpAndSettle();
  await tester.drag(scrollable.first, const Offset(0, 4000));
  await tester.pumpAndSettle();
}
