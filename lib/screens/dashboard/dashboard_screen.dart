import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vku_expense_ocr/core/date_ranges.dart';
import 'package:vku_expense_ocr/core/formatters.dart';
import 'package:vku_expense_ocr/core/router.dart';
import 'package:vku_expense_ocr/state/expense_providers.dart';
import 'package:vku_expense_ocr/state/storage_providers.dart';
import 'package:vku_expense_ocr/state/theme_mode_provider.dart';
import 'package:vku_expense_ocr/widgets/charts/donut_chart.dart';
import 'package:vku_expense_ocr/widgets/charts/weekly_bar_chart.dart';

/// "Tổng quan" tab: total of the selected month, the category donut and
/// the weekly bars (FR-7.1), side by side from 600 dp (FR-8.2).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const Key monthTotalKey = Key('dashboard-month-total');
  static const Key previousMonthKey = Key('dashboard-previous-month');
  static const Key nextMonthKey = Key('dashboard-next-month');
  static const Key donutSlotKey = Key('dashboard-donut-slot');
  static const Key weeklySlotKey = Key('dashboard-weekly-slot');
  static const Key addButtonKey = Key('dashboard-add');
  static const Key themeMenuKey = Key('dashboard-theme-menu');
  static const Key retryKey = Key('dashboard-retry');

  /// From this width the two charts sit side by side (FR-8.2).
  static const double wideLayoutWidth = 600;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng quan'),
        actions: const [_ThemeMenu()],
      ),
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
            const donut = _ChartCard(
              key: donutSlotKey,
              title: 'Chi tiêu theo danh mục',
              child: _CategoryDonut(),
            );
            const weekly = _ChartCard(
              key: weeklySlotKey,
              title: 'Chi tiêu theo tuần',
              child: _WeekBars(),
            );
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                const _MonthSummary(),
                const SizedBox(height: 16),
                if (wide)
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: donut),
                      SizedBox(width: 16),
                      Expanded(child: weekly),
                    ],
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

/// AppBar menu to choose the light, dark or system theme (FR-8.1).
class _ThemeMenu extends ConsumerWidget {
  const _ThemeMenu();

  static const _labels = {
    ThemeMode.light: ('Sáng', Icons.light_mode_outlined),
    ThemeMode.dark: ('Tối', Icons.dark_mode_outlined),
    ThemeMode.system: ('Theo hệ thống', Icons.brightness_auto_outlined),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);
    return PopupMenuButton<ThemeMode>(
      key: DashboardScreen.themeMenuKey,
      tooltip: 'Giao diện',
      icon: Icon(_labels[current]!.$2),
      initialValue: current,
      onSelected: (mode) async {
        final messenger = ScaffoldMessenger.of(context);
        try {
          await ref.read(themeModeProvider.notifier).select(mode);
        } on Object {
          // The new mode already applies; only saving it failed.
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Đã đổi giao diện nhưng không lưu được lựa chọn.'),
            ),
          );
        }
      },
      itemBuilder: (context) => [
        for (final MapEntry(key: mode, value: (label, icon)) in _labels.entries)
          PopupMenuItem<ThemeMode>(
            value: mode,
            child: Row(
              children: [
                Icon(icon),
                const SizedBox(width: 12),
                Expanded(child: Text(label)),
                if (mode == current) const Icon(Icons.check),
              ],
            ),
          ),
      ],
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
              error: (error, stack) => Column(
                children: [
                  Text(
                    'Không tải được dữ liệu',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  // The charts read the same list, so one retry fixes all.
                  TextButton.icon(
                    key: DashboardScreen.retryKey,
                    onPressed: () => ref.invalidate(expenseListProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
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

/// A titled card holding one chart.
class _ChartCard extends StatelessWidget {
  const _ChartCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

/// Donut of the selected month (FR-6.1); rebuilds only for its provider.
class _CategoryDonut extends ConsumerWidget {
  const _CategoryDonut();

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(categoryTotalsProvider)
      .when(
        loading: () => const _ChartLoading(),
        error: (error, stack) => const _ChartError(),
        data: (totals) => DonutChart(totals: totals),
      );
}

/// Bars of the selected week (FR-6.3), with week navigation.
class _WeekBars extends ConsumerWidget {
  const _WeekBars();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(clockProvider)();
    final currentWeek = DateRanges.startOfWeek(today);
    final notifier = ref.read(selectedWeekProvider.notifier);
    return ref
        .watch(weeklyTotalsProvider)
        .when(
          loading: () => const _ChartLoading(),
          error: (error, stack) => const _ChartError(),
          data: (week) => WeeklyBarChart(
            week: week,
            today: today,
            onPrevious: notifier.previous,
            // No future weeks.
            onNext: week.weekStart.isBefore(currentWeek) ? notifier.next : null,
          ),
        );
  }
}

class _ChartLoading extends StatelessWidget {
  const _ChartLoading();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 160,
    child: Center(child: CircularProgressIndicator()),
  );
}

class _ChartError extends StatelessWidget {
  const _ChartError();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 160,
    child: Center(
      child: Text(
        'Không tải được dữ liệu biểu đồ',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    ),
  );
}
