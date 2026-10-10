// End-to-end flow on a device or emulator (Phase 8):
// add an expense by hand → it shows in History → the Dashboard total
// changes → swipe it away → Undo brings it back.
//
//   flutter test integration_test/app_flow_test.dart -d <device id>
//
// Uses its own database file and documents sub-folder, removed at the end,
// so the app's real data is never touched.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:vku_expense_ocr/app.dart';
import 'package:vku_expense_ocr/screens/dashboard/dashboard_screen.dart';
import 'package:vku_expense_ocr/screens/review/review_screen.dart';
import 'package:vku_expense_ocr/services/database_service.dart';
import 'package:vku_expense_ocr/services/image_storage_service.dart';
import 'package:vku_expense_ocr/state/app_startup.dart';
import 'package:vku_expense_ocr/state/storage_providers.dart';
import 'package:vku_expense_ocr/widgets/expense_summary_card.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('manual entry → History → Dashboard total → delete → Undo', (
    tester,
  ) async {
    await initializeDateFormatting('vi_VN');
    Intl.defaultLocale = 'vi_VN';

    final dbPath = p.join(await getDatabasesPath(), 'it_app_flow.db');
    await deleteDatabase(dbPath);
    final documents = await getApplicationDocumentsDirectory();
    final root = Directory(p.join(documents.path, 'it_app_flow'));

    final overrides = await createStartupOverrides(
      openDatabase: () => DatabaseService().open(dbPath),
      imageStorage: ImageStorageService(documentsDirectory: () async => root),
    );
    final container = ProviderContainer(overrides: overrides);
    addTearDown(() async {
      await container.read(databaseProvider).close();
      container.dispose();
      await deleteDatabase(dbPath);
      if (root.existsSync()) root.deleteSync(recursive: true);
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const VkuExpenseApp(),
      ),
    );
    await tester.pumpAndSettle();

    String total() =>
        tester.widget<Text>(find.byKey(DashboardScreen.monthTotalKey)).data!;
    expect(total(), '0 đ', reason: 'fresh test database');

    // 1. Manual entry from the Dashboard.
    await tester.tap(find.byKey(DashboardScreen.addButtonKey));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(ReviewScreen.merchantFieldKey),
      'Quán cơm Bà Năm',
    );
    await tester.enterText(find.byKey(ReviewScreen.amountFieldKey), '35000');
    await tester.ensureVisible(find.byKey(const Key('category-food')));
    await tester.tap(find.byKey(const Key('category-food')));
    await tester.ensureVisible(find.byKey(ReviewScreen.saveButtonKey));
    await tester.tap(find.byKey(ReviewScreen.saveButtonKey));
    await tester.pumpAndSettle();

    // 2. The Dashboard total changed (the date defaults to today).
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(total(), '35.000 đ');

    // 3. It shows in History.
    await tester.tap(find.text('Lịch sử').last);
    await tester.pumpAndSettle();
    expect(find.byType(ExpenseSummaryCard), findsOneWidget);
    expect(find.text('Quán cơm Bà Năm'), findsOneWidget);

    // 4. Swipe it away, then Undo.
    await tester.drag(find.byType(ExpenseSummaryCard), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.byType(ExpenseSummaryCard), findsNothing);
    expect(find.text('Hoàn tác'), findsOneWidget);

    await tester.tap(find.text('Hoàn tác'));
    await tester.pumpAndSettle();
    expect(find.text('Quán cơm Bà Năm'), findsOneWidget);

    await tester.tap(find.text('Tổng quan').last);
    await tester.pumpAndSettle();
    expect(total(), '35.000 đ');
  });
}
