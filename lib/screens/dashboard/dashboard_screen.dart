import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vku_expense_ocr/core/date_ranges.dart';
import 'package:vku_expense_ocr/core/formatters.dart';
import 'package:vku_expense_ocr/core/router.dart';
import 'package:vku_expense_ocr/state/expense_providers.dart';
import 'package:vku_expense_ocr/state/storage_providers.dart';

/// "Tổng quan" tab: total of the selected month and, from Phase 9, the
/// category donut and the weekly bars (FR-7.1).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const Key monthTotalKey = Key('dashboard-month-total');
  static const Key previousMonthKey = Key('dashboard-previous-month');
  static const Key nextMonthKey = Key('dashboard-next-month');
  static const Key donutSlotKey = Key('dashboard-donut-slot');
  static const Key weeklySlotKey = Key('dashboard-weekly-slot');
  static const Key addButtonKey = Key('dashboard-add');

  /// From this width the two charts sit side by side (FR-8.2).
  static const double wideLayoutWidth = 600;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tổng quan')),
      floatingActionButton: FloatingActionButton.extended(
        key: addButtonKey,
        // No extra: the Review screen opens in manual mode (FR-4.9).
        onPressed: () => context.push(AppRoutes.review),
        icon: const Icon(Icons.edit_note),
        label: const Text('Thêm thủ công'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= wideLayoutWidth;
            const donut = _ChartSlot(
              key: donutSlotKey,
              icon: Icons.donut_large,
              title: 'Chi tiêu theo danh mục',
            );
            const weekly = _ChartSlot(
              key: weeklySlotKey,
              icon: Icons.bar_chart,
              title: 'Chi tiêu theo tuần',
            );
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                const _MonthSummary(),
                const SizedBox(height: 16),
                if (wide)
                  const IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: donut),
                        SizedBox(width: 16),
                        Expanded(child: weekly),
                      ],
                    ),
                  )
                else ...[
                  donut,
                  const SizedBox(height: 16),
                  weekly,
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Month selector and the month total; rebuilds only for these providers
/// (NFR-2).
class _MonthSummary extends ConsumerWidget {
  const _MonthSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final month = ref.watch(selectedMonthProvider);
    final current = DateRanges.startOfMonth(ref.watch(clockProvider)());
    final total = ref.watch(monthTotalProvider);
    final count = ref.watch(
      monthExpensesProvider.select((value) => value.valueOrNull?.length),
    );
    final notifier = ref.read(selectedMonthProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  key: DashboardScreen.previousMonthKey,
                  tooltip: 'Tháng trước',
                  onPressed: notifier.previous,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    'Tháng ${month.month}/${month.year}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: DashboardScreen.nextMonthKey,
                  tooltip: 'Tháng sau',
                  // No future months: nothing can be spent there yet.
                  onPressed: month.isBefore(current) ? notifier.next : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            Text('Tổng chi tiêu', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            total.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Text(
                'Không tải được dữ liệu',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              data: (amount) => FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  Formatters.vnd(amount),
                  key: DashboardScreen.monthTotalKey,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(switch (count) {
              null => '',
              0 => 'Chưa có giao dịch trong tháng này',
              final n => '$n giao dịch',
            }, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Place reserved for a Phase 9 chart.
class _ChartSlot extends StatelessWidget {
  const _ChartSlot({super.key, required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 48, color: theme.colorScheme.outline),
                    const SizedBox(height: 8),
                    Text(
                      'Biểu đồ đang được xây dựng',
                      style: theme.textTheme.bodySmall,
                    ),
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
