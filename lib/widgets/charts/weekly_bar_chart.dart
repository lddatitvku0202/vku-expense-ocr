import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vku_expense_ocr/core/date_ranges.dart';
import 'package:vku_expense_ocr/core/formatters.dart';
import 'package:vku_expense_ocr/models/weekly_totals.dart';
import 'package:vku_expense_ocr/widgets/charts/chart_geometry.dart';
import 'package:vku_expense_ocr/widgets/charts/weekly_bar_painter.dart';

/// Animated bars of one week, Monday → Sunday, with week navigation and
/// tap-to-read (FR-6.3, FR-6.6).
class WeeklyBarChart extends StatefulWidget {
  const WeeklyBarChart({
    super.key,
    required this.week,
    required this.today,
    required this.onPrevious,
    this.onNext,
  });

  final WeeklyTotals week;

  /// Highlighted when it falls in [week].
  final DateTime today;
  final VoidCallback? onPrevious;

  /// `null` disables "next week" (no future weeks).
  final VoidCallback? onNext;

  static const Key paintKey = Key('weekly-paint');
  static const Key detailKey = Key('weekly-detail');
  static const Key emptyKey = Key('weekly-empty');
  static const Key previousKey = Key('weekly-previous');
  static const Key nextKey = Key('weekly-next');

  static const Duration animationDuration = Duration(milliseconds: 700);
  static const double chartHeight = 200;

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: WeeklyBarChart.animationDuration,
  );
  late final CurvedAnimation _grow = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  /// Ephemeral UI state: the tapped day.
  int? _selected;

  static final DateFormat _dayMonth = DateFormat('dd/MM');

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void didUpdateWidget(WeeklyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Another week or other amounts: clear the selection and grow again.
    if (oldWidget.week != widget.week) {
      _selected = null;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _grow.dispose();
    _controller.dispose();
    super.dispose();
  }

  int? get _todayIndex {
    final start = widget.week.weekStart;
    final today = DateRanges.startOfDay(widget.today);
    final end = DateRanges.addDays(start, DateTime.daysPerWeek);
    if (today.isBefore(start) || !today.isBefore(end)) return null;
    return today.weekday - DateTime.monday;
  }

  String get _range {
    final start = widget.week.weekStart;
    final end = widget.week.dayAt(DateTime.daysPerWeek - 1);
    final first = start.year == end.year
        ? _dayMonth.format(start)
        : Formatters.date(start);
    return '$first – ${Formatters.date(end)}';
  }

  String _dayText(int index) =>
      '${WeeklyBarPainter.dayLabels[index]} '
      '${_dayMonth.format(widget.week.dayAt(index))}: '
      '${Formatters.vnd(widget.week.days[index])}';

  void _onTap(Offset position, Size size) {
    final index = barIndexAt(
      position,
      size,
      widget.week.days.length,
      WeeklyBarPainter.layout,
    );
    setState(() => _selected = index == _selected ? null : index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final week = widget.week;
    final selected = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              key: WeeklyBarChart.previousKey,
              tooltip: 'Tuần trước',
              onPressed: widget.onPrevious,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(_range, style: theme.textTheme.titleSmall),
              ),
            ),
            IconButton(
              key: WeeklyBarChart.nextKey,
              tooltip: 'Tuần sau',
              onPressed: widget.onNext,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        if (week.isEmpty)
          SizedBox(
            key: WeeklyBarChart.emptyKey,
            height: WeeklyBarChart.chartHeight * 0.6,
            child: Center(
              child: Text(
                'Không có chi tiêu trong tuần này',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          )
        else ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(
                constraints.maxWidth,
                WeeklyBarChart.chartHeight,
              );
              return Semantics(
                container: true,
                label:
                    'Biểu đồ cột chi tiêu tuần $_range: '
                    '${[for (var i = 0; i < 7; i++) '${WeeklyBarPainter.dayLabels[i]} ${Formatters.vnd(week.days[i])}'].join(', ')}.',
                child: ExcludeSemantics(
                  child: GestureDetector(
                    onTapUp: (details) => _onTap(details.localPosition, size),
                    child: SizedBox.fromSize(
                      size: size,
                      child: AnimatedBuilder(
                        animation: _grow,
                        builder: (context, _) => CustomPaint(
                          key: WeeklyBarChart.paintKey,
                          painter: WeeklyBarPainter(
                            values: week.days,
                            progress: _grow.value,
                            selectedIndex: selected,
                            todayIndex: _todayIndex,
                            barColor: theme.colorScheme.primary.withValues(
                              alpha: 0.45,
                            ),
                            todayColor: theme.colorScheme.primary,
                            selectedColor: theme.colorScheme.tertiary,
                            labelColor: theme.colorScheme.onSurface,
                            textScaler: MediaQuery.textScalerOf(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (selected != null)
            Padding(
              key: WeeklyBarChart.detailKey,
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _dayText(selected),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ],
    );
  }
}
