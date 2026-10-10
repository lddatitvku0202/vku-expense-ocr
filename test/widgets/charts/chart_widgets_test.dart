import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/models/category_totals.dart';
import 'package:vku_expense_ocr/models/expense.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/models/weekly_totals.dart';
import 'package:vku_expense_ocr/widgets/charts/donut_chart.dart';
import 'package:vku_expense_ocr/widgets/charts/donut_chart_painter.dart';
import 'package:vku_expense_ocr/widgets/charts/weekly_bar_chart.dart';
import 'package:vku_expense_ocr/widgets/charts/weekly_bar_painter.dart';

Expense _e(int amount, ExpenseCategory c, [DateTime? date]) => Expense(
  merchant: 'm',
  amount: amount,
  date: date ?? DateTime(2026, 10, 6),
  category: c,
  createdAt: DateTime(2026, 10, 6),
  updatedAt: DateTime(2026, 10, 6),
);

/// Food 50 %, Study 25 %, Gear 25 % → slices 0, 1, 3 (enum order).
final _totals = CategoryTotals.of([
  _e(100000, ExpenseCategory.food),
  _e(50000, ExpenseCategory.study),
  _e(50000, ExpenseCategory.gear),
]);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(1080, 1920),
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size / 3,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
}

DonutChartPainter _donutPainter(WidgetTester tester) =>
    tester.widget<CustomPaint>(find.byKey(DonutChart.paintKey)).painter!
        as DonutChartPainter;

WeeklyBarPainter _barPainter(WidgetTester tester) =>
    tester.widget<CustomPaint>(find.byKey(WeeklyBarChart.paintKey)).painter!
        as WeeklyBarPainter;

/// Global position of the ring at [clockwiseFromNoon] radians.
Offset _ringPoint(WidgetTester tester, double clockwiseFromNoon) {
  final box = tester.getRect(find.byKey(DonutChart.paintKey));
  final ring = DonutChartPainter.ringFor(box.size);
  return box.topLeft +
      ring.center +
      Offset(
        ring.radius * math.sin(clockwiseFromNoon),
        -ring.radius * math.cos(clockwiseFromNoon),
      );
}

void main() {
  group('DonutChart (FR-6.1, FR-6.2)', () {
    testWidgets('sweeps from 0 to 1 and finishes with pumpAndSettle', (
      tester,
    ) async {
      await _pump(tester, DonutChart(totals: _totals));

      expect(_donutPainter(tester).progress, lessThan(0.1));
      await tester.pump(const Duration(milliseconds: 300));
      final middle = _donutPainter(tester).progress;
      expect(middle, greaterThan(0));
      expect(middle, lessThan(1));
      await tester.pumpAndSettle();
      expect(_donutPainter(tester).progress, 1);
    });

    testWidgets('legend: colour, category, amount and percentage', (
      tester,
    ) async {
      await _pump(tester, DonutChart(totals: _totals));
      await tester.pumpAndSettle();

      final food = find.byKey(const Key('donut-legend-food'));
      expect(
        find.descendant(of: food, matching: find.text('Ăn uống')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: food, matching: find.text('100.000 đ')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: food, matching: find.text('50,0%')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('donut-legend-travel')),
        findsNothing,
        reason: '0 đ',
      );
      final painter = _donutPainter(tester);
      expect(painter.segments[0].color, isNot(painter.segments[1].color));
      expect(painter.totalLabel, '200.000 đ');
    });

    testWidgets(
      'tap a slice: highlighted + details; again or outside: cleared',
      (tester) async {
        await _pump(tester, DonutChart(totals: _totals));
        await tester.pumpAndSettle();

        // 3 o'clock is inside the food slice (first half of the circle).
        await tester.tapAt(_ringPoint(tester, math.pi / 2));
        await tester.pumpAndSettle();
        expect(_donutPainter(tester).selectedIndex, 0);
        expect(find.byKey(DonutChart.detailKey), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(DonutChart.detailKey),
            matching: find.textContaining('Ăn uống'),
          ),
          findsOneWidget,
        );

        // 7:30 is the study slice (50 % → 75 %).
        await tester.tapAt(_ringPoint(tester, 5 * math.pi / 4 - 0.2));
        await tester.pumpAndSettle();
        expect(_donutPainter(tester).selectedIndex, 1);

        await tester.tapAt(_ringPoint(tester, 5 * math.pi / 4 - 0.2));
        await tester.pumpAndSettle();
        expect(
          _donutPainter(tester).selectedIndex,
          isNull,
          reason: 'same slice again',
        );

        await tester.tapAt(_ringPoint(tester, math.pi / 2));
        await tester.pumpAndSettle();
        final centre = tester.getRect(find.byKey(DonutChart.paintKey)).center;
        await tester.tapAt(centre);
        await tester.pumpAndSettle();
        expect(
          _donutPainter(tester).selectedIndex,
          isNull,
          reason: 'tap in the hole',
        );
        expect(find.byKey(DonutChart.detailKey), findsNothing);
      },
    );

    testWidgets(
      'new data restarts the sweep; a vanished selection is cleared',
      (tester) async {
        await _pump(tester, DonutChart(totals: _totals));
        await tester.pumpAndSettle();
        await tester.tapAt(_ringPoint(tester, 5 * math.pi / 4 - 0.2));
        await tester.pumpAndSettle();
        expect(_donutPainter(tester).selectedIndex, 1);

        final withoutStudy = CategoryTotals.of([
          _e(100000, ExpenseCategory.food),
          _e(50000, ExpenseCategory.gear),
        ]);
        await _pump(tester, DonutChart(totals: withoutStudy));
        await tester.pump(const Duration(milliseconds: 16));

        expect(
          _donutPainter(tester).progress,
          lessThan(1),
          reason: 'animation restarted',
        );
        expect(_donutPainter(tester).selectedIndex, isNull);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(_donutPainter(tester).progress, 1);
      },
    );

    testWidgets('data changing in the middle of the animation is fine', (
      tester,
    ) async {
      await _pump(tester, DonutChart(totals: _totals));
      await tester.pump(const Duration(milliseconds: 200));

      await _pump(
        tester,
        DonutChart(
          totals: CategoryTotals.of([_e(80000, ExpenseCategory.travel)]),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await _pump(tester, DonutChart(totals: _totals));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(_donutPainter(tester).progress, 1);
      expect(_donutPainter(tester).segments[0].fraction, closeTo(0.5, 1e-9));
    });

    testWidgets('equal data does not restart the animation', (tester) async {
      await _pump(tester, DonutChart(totals: _totals));
      await tester.pumpAndSettle();
      await _pump(
        tester,
        DonutChart(
          totals: CategoryTotals.of([
            _e(100000, ExpenseCategory.food),
            _e(50000, ExpenseCategory.study),
            _e(50000, ExpenseCategory.gear),
          ]),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
      expect(_donutPainter(tester).progress, 1);
    });

    testWidgets('empty month: a message instead of an empty ring (FR-6.6)', (
      tester,
    ) async {
      await _pump(tester, DonutChart(totals: CategoryTotals.of(const [])));

      expect(find.byKey(DonutChart.emptyKey), findsOneWidget);
      expect(find.byKey(DonutChart.paintKey), findsNothing);
    });

    testWidgets('describes itself to screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, DonutChart(totals: _totals));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(RegExp('Biểu đồ tròn.*Ăn uống.*50,0%')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('a very large total is shortened to fit the hole', (
      tester,
    ) async {
      final huge = CategoryTotals.of([_e(123456789012, ExpenseCategory.gear)]);
      await _pump(
        tester,
        DonutChart(totals: huge),
        size: const Size(960, 1440),
      );
      await tester.pumpAndSettle();
      expect(_donutPainter(tester).compactTotalLabel, '123,46 tỷ đ');
      expect(tester.takeException(), isNull);
    });

    testWidgets('320 dp with 1.5x text: no overflow', (tester) async {
      await _pump(
        tester,
        DonutChart(totals: _totals),
        size: const Size(960, 1600),
        textScale: 1.5,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('WeeklyBarChart (FR-6.3)', () {
    // Week of Monday 05/10/2026; "today" is Friday 09/10.
    final week = WeeklyTotals.of([
      _e(59000, ExpenseCategory.food, DateTime(2026, 10, 6)),
      _e(30000, ExpenseCategory.food, DateTime(2026, 10, 8)),
      _e(120000, ExpenseCategory.food, DateTime(2026, 10, 11)),
    ], DateTime(2026, 10, 5));
    final today = DateTime(2026, 10, 9, 20);

    Widget chart({
      WeeklyTotals? totals,
      VoidCallback? onPrevious,
      VoidCallback? onNext,
    }) => WeeklyBarChart(
      week: totals ?? week,
      today: today,
      onPrevious: onPrevious ?? () {},
      onNext: onNext,
    );

    testWidgets('7 bars Monday → Sunday that grow and settle', (tester) async {
      await _pump(tester, chart());
      expect(_barPainter(tester).values, [0, 59000, 0, 30000, 0, 0, 120000]);
      expect(_barPainter(tester).progress, lessThan(0.1));
      await tester.pumpAndSettle();
      expect(_barPainter(tester).progress, 1);
    });

    testWidgets('shows the week range and highlights today', (tester) async {
      await _pump(tester, chart());
      await tester.pumpAndSettle();

      expect(find.text('05/10 – 11/10/2026'), findsOneWidget);
      expect(_barPainter(tester).todayIndex, 4);
    });

    testWidgets('tap a bar: the amount of that day', (tester) async {
      await _pump(tester, chart());
      await tester.pumpAndSettle();
      final box = tester.getRect(find.byKey(WeeklyBarChart.paintKey));
      final rects = WeeklyBarPainter.barRectsFor(
        box.size,
        _barPainter(tester).values,
      );

      await tester.tapAt(box.topLeft + rects[6].center);
      await tester.pumpAndSettle();
      expect(_barPainter(tester).selectedIndex, 6);
      expect(
        find.descendant(
          of: find.byKey(WeeklyBarChart.detailKey),
          matching: find.text('CN 11/10: 120.000 đ'),
        ),
        findsOneWidget,
      );

      await tester.tapAt(box.topLeft + Offset(rects[2].center.dx, 10));
      await tester.pumpAndSettle();
      expect(_barPainter(tester).selectedIndex, 2);
      expect(find.text('T4 07/10: 0 đ'), findsOneWidget);

      await tester.tapAt(box.topLeft + Offset(rects[2].center.dx, 10));
      await tester.pumpAndSettle();
      expect(_barPainter(tester).selectedIndex, isNull);
    });

    testWidgets('previous / next buttons; next disabled when not given', (
      tester,
    ) async {
      var previous = 0;
      var next = 0;
      await _pump(
        tester,
        chart(onPrevious: () => previous++, onNext: () => next++),
      );
      await tester.tap(find.byKey(WeeklyBarChart.previousKey));
      await tester.tap(find.byKey(WeeklyBarChart.nextKey));
      expect((previous, next), (1, 1));

      await _pump(tester, chart());
      expect(
        tester.widget<IconButton>(find.byKey(WeeklyBarChart.nextKey)).onPressed,
        isNull,
      );
    });

    testWidgets(
      'another week restarts the animation and clears the selection',
      (tester) async {
        await _pump(tester, chart());
        await tester.pumpAndSettle();
        final box = tester.getRect(find.byKey(WeeklyBarChart.paintKey));
        final rects = WeeklyBarPainter.barRectsFor(
          box.size,
          _barPainter(tester).values,
        );
        await tester.tapAt(box.topLeft + rects[1].center);
        await tester.pumpAndSettle();
        expect(_barPainter(tester).selectedIndex, 1);

        final previousWeek = WeeklyTotals.of([
          _e(45000, ExpenseCategory.travel, DateTime(2026, 9, 30)),
        ], DateTime(2026, 9, 28));
        await _pump(tester, chart(totals: previousWeek));
        await tester.pump(const Duration(milliseconds: 16));
        expect(_barPainter(tester).progress, lessThan(1));
        expect(_barPainter(tester).selectedIndex, isNull);
        expect(
          _barPainter(tester).todayIndex,
          isNull,
          reason: 'today is not in that week',
        );
        await tester.pumpAndSettle();
        expect(find.text('28/09 – 04/10/2026'), findsOneWidget);
      },
    );

    testWidgets('a week without spending: message, navigation still there', (
      tester,
    ) async {
      await _pump(
        tester,
        chart(totals: WeeklyTotals.of(const [], DateTime(2026, 9, 21))),
      );

      expect(find.byKey(WeeklyBarChart.emptyKey), findsOneWidget);
      expect(find.byKey(WeeklyBarChart.paintKey), findsNothing);
      expect(find.byKey(WeeklyBarChart.previousKey), findsOneWidget);
    });

    testWidgets('describes itself to screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, chart());
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(
          RegExp('Biểu đồ cột.*05/10 – 11/10/2026.*CN 120.000'),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('320 dp with 1.5x text: no overflow', (tester) async {
      await _pump(tester, chart(), size: const Size(960, 1600), textScale: 1.5);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
