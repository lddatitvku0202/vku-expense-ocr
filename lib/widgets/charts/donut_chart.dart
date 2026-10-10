import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vku_expense_ocr/core/category_style.dart';
import 'package:vku_expense_ocr/core/formatters.dart';
import 'package:vku_expense_ocr/models/category_totals.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/widgets/charts/chart_geometry.dart';
import 'package:vku_expense_ocr/widgets/charts/donut_chart_painter.dart';

/// Animated, tappable donut of spending per category with its legend
/// (FR-6.1, FR-6.2, FR-6.6).
class DonutChart extends StatefulWidget {
  const DonutChart({super.key, required this.totals});

  final CategoryTotals totals;

  static const Key paintKey = Key('donut-paint');
  static const Key detailKey = Key('donut-detail');
  static const Key emptyKey = Key('donut-empty');

  static const Duration animationDuration = Duration(milliseconds: 900);

  /// Largest side of the donut, logical pixels.
  static const double maxSize = 240;

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: DonutChart.animationDuration,
  );
  late final CurvedAnimation _sweep = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  /// Ephemeral UI state: the highlighted slice.
  ExpenseCategory? _selected;

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void didUpdateWidget(DonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totals == widget.totals) return;
    // A slice that no longer exists cannot stay selected.
    if (_selected case final selected?
        when widget.totals.amountOf(selected) == 0) {
      _selected = null;
    }
    // New data: sweep again from the start (FR-6.5).
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _sweep.dispose();
    _controller.dispose();
    super.dispose();
  }

  List<double> get _fractions => [
    for (final c in ExpenseCategory.values) widget.totals.shareOf(c),
  ];

  void _onTap(Offset position, Size size) {
    final ring = DonutChartPainter.ringFor(size);
    final index = angleToSliceIndex(
      position,
      center: ring.center,
      size: size,
      slices: donutSlices(_fractions),
      radius: ring.radius,
      // As wide as a selected slice, so taps are forgiving.
      strokeWidth: ring.strokeWidth * DonutChartPainter.selectedStrokeFactor,
    );
    setState(() {
      final tapped = index == null ? null : ExpenseCategory.values[index];
      // Tapping the selected slice again, the hole or outside clears it.
      _selected = tapped == _selected ? null : tapped;
    });
  }

  String _semanticLabel() {
    final totals = widget.totals;
    final parts = [
      for (final c in ExpenseCategory.values)
        if (totals.amountOf(c) > 0)
          '${c.label} ${Formatters.vnd(totals.amountOf(c))} '
              '(${Formatters.percent(totals.shareOf(c))})',
    ];
    return 'Biểu đồ tròn chi tiêu theo danh mục, tổng '
        '${Formatters.vnd(totals.total)}. ${parts.join(', ')}.';
  }

  @override
  Widget build(BuildContext context) {
    final totals = widget.totals;
    final theme = Theme.of(context);
    if (totals.isEmpty) {
      return Padding(
        key: DonutChart.emptyKey,
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.donut_large, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 8),
            Text(
              'Chưa có chi tiêu trong tháng này',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    final segments = <DonutSegment>[
      for (final c in ExpenseCategory.values)
        (fraction: totals.shareOf(c), color: c.color),
    ];
    final selected = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final side = math.min(constraints.maxWidth, DonutChart.maxSize);
            final size = Size.square(side);
            return Center(
              child: Semantics(
                container: true,
                label: _semanticLabel(),
                child: ExcludeSemantics(
                  child: GestureDetector(
                    onTapUp: (details) => _onTap(details.localPosition, size),
                    child: SizedBox.fromSize(
                      size: size,
                      child: AnimatedBuilder(
                        animation: _sweep,
                        builder: (context, _) => CustomPaint(
                          key: DonutChart.paintKey,
                          painter: DonutChartPainter(
                            segments: segments,
                            progress: _sweep.value,
                            selectedIndex: selected?.index,
                            trackColor:
                                theme.colorScheme.surfaceContainerHighest,
                            textColor: theme.colorScheme.onSurface,
                            captionColor: theme.colorScheme.onSurfaceVariant,
                            totalLabel: Formatters.vnd(totals.total),
                            compactTotalLabel:
                                '${Formatters.compactVnd(totals.total)}'
                                ' đ',
                            textScaler: MediaQuery.textScalerOf(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (selected != null) ...[
          const SizedBox(height: 12),
          Container(
            key: DonutChart.detailKey,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(selected.icon, color: selected.color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${selected.label}: '
                    '${Formatters.vnd(totals.amountOf(selected))} · '
                    '${Formatters.percent(totals.shareOf(selected))}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        for (final c in ExpenseCategory.values)
          if (totals.amountOf(c) > 0)
            _LegendRow(
              key: Key('donut-legend-${c.name}'),
              category: c,
              amount: totals.amountOf(c),
              share: totals.shareOf(c),
              selected: c == selected,
              onTap: () => setState(() => _selected = c == selected ? null : c),
            ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    super.key,
    required this.category,
    required this.amount,
    required this.share,
    required this.selected,
    required this.onTap,
  });

  final ExpenseCategory category;
  final int amount;
  final double share;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(fontWeight: selected ? FontWeight.bold : FontWeight.normal);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: category.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                category.label,
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Amount and share shrink to fit rather than overflow on a
            // narrow screen or with large system text.
            Flexible(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(Formatters.vnd(amount), style: style),
                    const SizedBox(width: 8),
                    Text(Formatters.percent(share), style: style),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
