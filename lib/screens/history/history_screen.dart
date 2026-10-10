import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vku_expense_ocr/core/category_style.dart';
import 'package:vku_expense_ocr/core/router.dart';
import 'package:vku_expense_ocr/models/expense.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/state/expense_providers.dart';
import 'package:vku_expense_ocr/widgets/expense_summary_card.dart';
import 'package:vku_expense_ocr/widgets/state_message.dart';

/// "Lịch sử" tab: saved expenses, newest first (FR-7.3). Swipe to delete
/// with Undo (FR-5.4), filter by category, tap to edit (`/expense/:id`).
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  static const Key addButtonKey = Key('history-add');

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  /// Ephemeral UI state (W8 s4–6): `null` shows every category.
  ExpenseCategory? _filter;

  /// The expense whose Undo snack bar is showing, if any.
  int? _undoId;

  Future<void> _delete(Expense expense) async {
    final id = expense.id!;
    final notifier = ref.read(expenseListProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);

    // A second deletion replaces the first snack bar, so the first
    // deletion can no longer be undone: make it final now (photo included).
    if (_undoId case final previous? when previous != id) {
      unawaited(notifier.commitDeletion(previous));
    }
    _undoId = id;
    messenger.hideCurrentSnackBar();

    // Updates the list synchronously: the Dismissible leaves the tree on
    // the next frame.
    final Expense? removed;
    try {
      removed = await notifier.remove(id);
    } on Object {
      if (mounted) _showMessage(messenger, 'Không xóa được giao dịch.');
      return;
    }
    if (removed == null) return;

    // The snack bar decides: Undo restores, anything else is final.
    notifier.holdForUndo(id);
    final controller = messenger.showSnackBar(
      SnackBar(
        content: Text('Đã xóa "${removed.merchant}"'),
        // One constant for the snack bar and the notifier's Undo window.
        duration: ExpenseListNotifier.undoWindow,
        // A snack bar with an action stays until dismissed by default
        // (`persist = action != null` in Flutter 3.47); the deletion must
        // become final when the window ends.
        persist: false,
        action: SnackBarAction(
          label: 'Hoàn tác',
          onPressed: () => unawaited(_undo(notifier, messenger, id)),
        ),
      ),
    );
    final reason = await controller.closed;
    if (_undoId == id) _undoId = null;
    if (reason != SnackBarClosedReason.action) {
      unawaited(notifier.commitDeletion(id));
    }
  }

  Future<void> _undo(
    ExpenseListNotifier notifier,
    ScaffoldMessengerState messenger,
    int id,
  ) async {
    try {
      if (!await notifier.restore(id)) {
        _showMessage(messenger, 'Đã hết thời gian hoàn tác.');
      }
    } on Object {
      _showMessage(messenger, 'Không khôi phục được giao dịch.');
    }
  }

  static void _showMessage(ScaffoldMessengerState messenger, String text) =>
      messenger.showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expenseListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử')),
      floatingActionButton: FloatingActionButton.extended(
        key: HistoryScreen.addButtonKey,
        onPressed: () => context.push(AppRoutes.review),
        icon: const Icon(Icons.edit_note),
        label: const Text('Thêm thủ công'),
      ),
      body: SafeArea(
        child: expenses.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => StateMessage(
            icon: Icons.error_outline,
            title: 'Không tải được lịch sử',
            message: 'Hãy thử lại.',
            action: FilledButton(
              onPressed: () => ref.invalidate(expenseListProvider),
              child: const Text('Thử lại'),
            ),
          ),
          data: (all) {
            if (all.isEmpty) {
              return StateMessage(
                icon: Icons.receipt_long_outlined,
                title: 'Chưa có giao dịch nào',
                message: 'Hãy quét một hóa đơn ở tab Quét hoặc thêm thủ công.',
                action: OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.scan),
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: const Text('Quét hóa đơn'),
                ),
              );
            }
            final filter = _filter;
            final shown = filter == null
                ? all
                : [
                    for (final e in all)
                      if (e.category == filter) e,
                  ];
            return Column(
              children: [
                _FilterChips(
                  selected: filter,
                  onSelected: (c) => setState(() => _filter = c),
                ),
                Expanded(
                  child: shown.isEmpty
                      ? StateMessage(
                          icon: Icons.filter_alt_off_outlined,
                          title:
                              'Không có giao dịch thuộc danh mục '
                              '${filter!.label}',
                          action: TextButton(
                            onPressed: () => setState(() => _filter = null),
                            child: const Text('Xem tất cả'),
                          ),
                        )
                      : ListView.builder(
                          // Room for the floating button over the last card.
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
                          itemCount: shown.length,
                          itemBuilder: (context, index) {
                            final expense = shown[index];
                            return Dismissible(
                              // Stable identity across rebuilds (W7 s19–24).
                              key: ValueKey<int>(expense.id!),
                              direction: DismissDirection.endToStart,
                              background: const _DeleteBackground(),
                              onDismissed: (_) => unawaited(_delete(expense)),
                              child: ExpenseSummaryCard(
                                expense: expense,
                                onTap: () => context.push(
                                  AppRoutes.expense(expense.id!),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelected});

  final ExpenseCategory? selected;
  final ValueChanged<ExpenseCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    // Wrap, not a horizontal scroll: all six chips stay visible on a
    // narrow phone instead of hiding the last ones off screen.
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          ChoiceChip(
            key: const Key('history-filter-all'),
            label: const Text('Tất cả'),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          for (final category in ExpenseCategory.values)
            ChoiceChip(
              key: Key('history-filter-${category.name}'),
              avatar: Icon(category.icon, color: category.color, size: 18),
              label: Text(category.label),
              selected: selected == category,
              onSelected: (_) => onSelected(category),
            ),
        ],
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Xóa', style: TextStyle(color: scheme.onErrorContainer)),
          const SizedBox(width: 8),
          Icon(Icons.delete_outline, color: scheme.onErrorContainer),
        ],
      ),
    );
  }
}
