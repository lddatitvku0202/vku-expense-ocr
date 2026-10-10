import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/widgets/charts/donut_chart_painter.dart';
import 'package:vku_expense_ocr/widgets/charts/weekly_bar_painter.dart';

const _segments = <DonutSegment>[
  (fraction: 0.5, color: Color(0xFFEF6C00)),
  (fraction: 0.25, color: Color(0xFF1E88E5)),
  (fraction: 0, color: Color(0xFF43A047)),
  (fraction: 0.25, color: Color(0xFF8E24AA)),
  (fraction: 0, color: Color(0xFFE53935)),
];

DonutChartPainter _donut({
  List<DonutSegment> segments = _segments,
  double progress = 1,
  int? selectedIndex,
  Color trackColor = const Color(0xFFEEEEEE),
  Color textColor = const Color(0xFF000000),
  String totalLabel = '200.000 đ',
}) => DonutChartPainter(
  segments: segments,
  progress: progress,
  selectedIndex: selectedIndex,
  trackColor: trackColor,
  textColor: textColor,
  captionColor: const Color(0xFF666666),
  totalLabel: totalLabel,
  compactTotalLabel: '200k đ',
  textScaler: TextScaler.noScaling,
);

WeeklyBarPainter _bars({
  List<int> values = const [0, 59000, 0, 30000, 0, 0, 120000],
  double progress = 1,
  int? selectedIndex,
  int? todayIndex = 4,
  Color barColor = const Color(0xFF90A4AE),
  Color todayColor = const Color(0xFF2C4570),
  Color selectedColor = const Color(0xFFEF6C00),
}) => WeeklyBarPainter(
  values: values,
  progress: progress,
  selectedIndex: selectedIndex,
  todayIndex: todayIndex,
  barColor: barColor,
  todayColor: todayColor,
  selectedColor: selectedColor,
  labelColor: const Color(0xFF333333),
  textScaler: TextScaler.noScaling,
);

void main() {
  group('DonutChartPainter.shouldRepaint (FR-6.4)', () {
    test('identical inputs: no repaint', () {
      expect(_donut().shouldRepaint(_donut()), isFalse);
    });

    test('data changed', () {
      final other = [..._segments]
        ..[0] = (fraction: 0.4, color: _segments[0].color);
      other[2] = (fraction: 0.1, color: _segments[2].color);
      expect(_donut().shouldRepaint(_donut(segments: other)), isTrue);
      expect(_donut().shouldRepaint(_donut(totalLabel: '210.000 đ')), isTrue);
    });

    test('colour changed', () {
      final recoloured = [..._segments]
        ..[1] = (fraction: 0.25, color: const Color(0xFF000000));
      expect(_donut().shouldRepaint(_donut(segments: recoloured)), isTrue);
      expect(
        _donut().shouldRepaint(_donut(trackColor: const Color(0xFF333333))),
        isTrue,
      );
      expect(
        _donut().shouldRepaint(_donut(textColor: const Color(0xFFFFFFFF))),
        isTrue,
      );
    });

    test('progress changed', () {
      expect(
        _donut(progress: 0.5).shouldRepaint(_donut(progress: 0.6)),
        isTrue,
      );
    });

    test('selected slice changed', () {
      expect(_donut().shouldRepaint(_donut(selectedIndex: 1)), isTrue);
      expect(
        _donut(selectedIndex: 1).shouldRepaint(_donut(selectedIndex: 3)),
        isTrue,
      );
    });
  });

  group('WeeklyBarPainter.shouldRepaint (FR-6.4)', () {
    test('identical inputs: no repaint', () {
      expect(_bars().shouldRepaint(_bars()), isFalse);
    });

    test('data changed', () {
      expect(
        _bars().shouldRepaint(
          _bars(values: const [0, 59000, 0, 30000, 0, 0, 125000]),
        ),
        isTrue,
      );
    });

    test('colour changed', () {
      expect(
        _bars().shouldRepaint(_bars(barColor: const Color(0xFF000000))),
        isTrue,
      );
      expect(
        _bars().shouldRepaint(_bars(todayColor: const Color(0xFF000000))),
        isTrue,
      );
      expect(
        _bars().shouldRepaint(_bars(selectedColor: const Color(0xFF000000))),
        isTrue,
      );
    });

    test('progress changed', () {
      expect(_bars(progress: 0.2).shouldRepaint(_bars(progress: 0.3)), isTrue);
    });

    test('selected bar or today changed', () {
      expect(_bars().shouldRepaint(_bars(selectedIndex: 3)), isTrue);
      expect(_bars().shouldRepaint(_bars(todayIndex: 5)), isTrue);
    });
  });

  testWidgets('the donut draws one arc per non-empty slice over a track', (
    tester,
  ) async {
    await tester.pumpWidget(
      Center(
        child: SizedBox.square(
          dimension: 200,
          child: CustomPaint(painter: _donut()),
        ),
      ),
    );
    expect(
      find.byType(CustomPaint),
      paints
        ..circle(color: const Color(0xFFEEEEEE))
        ..arc(color: const Color(0xFFEF6C00))
        ..arc(color: const Color(0xFF1E88E5))
        ..arc(color: const Color(0xFF8E24AA)),
    );
  });

  testWidgets('the weekly chart draws 7 rounded bars', (tester) async {
    await tester.pumpWidget(
      Center(
        child: SizedBox(
          width: 360,
          height: 200,
          child: CustomPaint(painter: _bars()),
        ),
      ),
    );
    expect(
      find.byType(CustomPaint),
      paints
        ..rrect()
        ..rrect()
        ..rrect()
        ..rrect()
        ..rrect()
        ..rrect()
        ..rrect(),
    );
  });
}
