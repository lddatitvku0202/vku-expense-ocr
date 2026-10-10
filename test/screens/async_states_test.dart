import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/core/router.dart';
import 'package:vku_expense_ocr/screens/dashboard/dashboard_screen.dart';
import 'package:vku_expense_ocr/screens/history/history_screen.dart';
import 'package:vku_expense_ocr/screens/review/review_screen.dart';
import 'package:vku_expense_ocr/services/camera_service.dart';
import 'package:vku_expense_ocr/widgets/charts/donut_chart.dart';
import 'package:vku_expense_ocr/widgets/charts/weekly_bar_chart.dart';

import '../support/app_harness.dart';
import '../support/fake_camera.dart';
import '../support/fake_expense_repository.dart';

/// Loading, empty and error states of every screen that waits for data
/// (FR-8.4).
void main() {
  group('Dashboard', () {
    testWidgets('loading: spinners, no chart yet', (tester) async {
      final gate = Completer<void>();
      final repo = FakeExpenseRepository()..getAllGate = gate.future;
      await pumpApp(tester, repository: repo, settle: false);

      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.byKey(DonutChart.paintKey), findsNothing);
      expect(find.byKey(WeeklyBarChart.paintKey), findsNothing);
      expect(tester.takeException(), isNull);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('empty: 0 đ, a message in the month and in the week', (
      tester,
    ) async {
      await pumpApp(tester, repository: FakeExpenseRepository());

      expect(find.text('Chưa có giao dịch trong tháng này'), findsOneWidget);
      expect(find.byKey(DonutChart.emptyKey), findsOneWidget);
      expect(find.byKey(WeeklyBarChart.emptyKey), findsOneWidget);
    });

    testWidgets('error: a message, and "Thử lại" loads the data again', (
      tester,
    ) async {
      final repo = FakeExpenseRepository(stressExpenses())
        ..failGetAll = Exception('disk I/O error');
      await pumpApp(tester, repository: repo);

      expect(find.text('Không tải được dữ liệu'), findsOneWidget);
      expect(find.byKey(DonutChart.paintKey), findsNothing);

      repo.failGetAll = null;
      await tester.tap(find.byKey(DashboardScreen.retryKey));
      await tester.pumpAndSettle();
      expect(find.text('Không tải được dữ liệu'), findsNothing);
      expect(find.byKey(DonutChart.paintKey), findsOneWidget);
    });
  });

  group('History', () {
    testWidgets('loading: a spinner', (tester) async {
      final gate = Completer<void>();
      final repo = FakeExpenseRepository()..getAllGate = gate.future;
      await pumpApp(
        tester,
        repository: repo,
        location: AppRoutes.history,
        settle: false,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      gate.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('empty: "no expenses yet" with a way to scan', (tester) async {
      await pumpApp(
        tester,
        repository: FakeExpenseRepository(),
        location: AppRoutes.history,
      );
      expect(find.text('Chưa có giao dịch nào'), findsOneWidget);
      expect(find.text('Quét hóa đơn'), findsOneWidget);
    });

    testWidgets('error: a message, and "Thử lại" loads the list again', (
      tester,
    ) async {
      final repo = FakeExpenseRepository(stressExpenses())
        ..failGetAll = Exception('disk I/O error');
      await pumpApp(tester, repository: repo, location: AppRoutes.history);
      expect(find.text('Không tải được lịch sử'), findsOneWidget);

      repo.failGetAll = null;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Không tải được lịch sử'), findsNothing);
      expect(find.byType(HistoryScreen), findsOneWidget);
      expect(find.text('Fahasa'), findsOneWidget);
    });
  });

  group('Detail (edit form)', () {
    testWidgets('loading: a spinner under the title', (tester) async {
      final gate = Completer<void>();
      final repo = FakeExpenseRepository(stressExpenses())
        ..getAllGate = gate.future;
      await pumpApp(
        tester,
        repository: repo,
        pushed: AppRoutes.expense(2),
        settle: false,
      );
      expect(find.text('Sửa giao dịch'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(ReviewScreen.merchantFieldKey), findsOneWidget);
    });

    testWidgets('error: a message and a retry', (tester) async {
      final repo = FakeExpenseRepository(stressExpenses())
        ..failGetAll = Exception('disk I/O error');
      await pumpApp(tester, repository: repo, pushed: AppRoutes.expense(2));
      expect(find.text('Không tải được giao dịch'), findsOneWidget);

      repo.failGetAll = null;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.byKey(ReviewScreen.merchantFieldKey), findsOneWidget);
    });

    testWidgets('not found: a message', (tester) async {
      await pumpApp(tester, pushed: AppRoutes.expense(999));
      expect(find.text('Không tìm thấy giao dịch'), findsOneWidget);
    });
  });

  group('Camera', () {
    testWidgets('starting: a spinner while the camera opens', (tester) async {
      await pumpApp(
        tester,
        location: AppRoutes.scan,
        cameraSource: FakeCameraSource(FakeReceiptCamera.new),
        settle: false,
      );
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('error: a message, "Thử lại" and the gallery', (tester) async {
      var broken = true;
      final source = FakeCameraSource(
        () => FakeReceiptCamera(
          initializeError: broken ? const CameraError('busy') : null,
        ),
      );
      await pumpApp(tester, location: AppRoutes.scan, cameraSource: source);

      expect(find.text('Không mở được camera'), findsOneWidget);
      expect(find.text('Chọn ảnh từ thư viện'), findsOneWidget);

      broken = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Không mở được camera'), findsNothing);
      expect(find.byKey(const Key('fake-preview')), findsOneWidget);
    });
  });
}
