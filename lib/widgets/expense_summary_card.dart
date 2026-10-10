import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vku_expense_ocr/core/category_style.dart';
import 'package:vku_expense_ocr/core/formatters.dart';
import 'package:vku_expense_ocr/models/expense.dart';

/// One History item, from the Week 7 lab (W7 s45, FR-7.3): the category
/// icon in a circle, merchant and date stacked with
/// `CrossAxisAlignment.start`, the amount as "###.### đ", in a `Card` with
/// an `InkWell`, plus the receipt thumbnail when there is one.
class ExpenseSummaryCard extends StatelessWidget {
  const ExpenseSummaryCard({super.key, required this.expense, this.onTap});

  final Expense expense;
  final VoidCallback? onTap;

  static const Key thumbnailKey = Key('expense-card-thumbnail');
  static const Key missingThumbnailKey = Key('expense-card-thumbnail-missing');

  /// Side of the square thumbnail, logical pixels.
  static const int thumbnailSize = 48;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = expense.category;
    final color = category.colorOn(theme.brightness);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(category.icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.merchant,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.date(expense.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // A huge amount (or large system text) shrinks instead of
              // pushing the row past the card; the name keeps the rest.
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.32,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    Formatters.vnd(expense.amount),
                    maxLines: 1,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (expense.thumbPath case final path?) ...[
                const SizedBox(width: 12),
                _Thumbnail(path: path, label: category.label),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.path, required this.label});

  final String path;
  final String label;

  @override
  Widget build(BuildContext context) {
    const size = ExpenseSummaryCard.thumbnailSize;
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return ClipRRect(
      key: ExpenseSummaryCard.thumbnailKey,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.square(
        dimension: size.toDouble(),
        child: Image.file(
          File(path),
          // Decode at display size: a list of full-size JPEGs would use
          // tens of MB (NFR-2).
          cacheWidth: pixels,
          fit: BoxFit.cover,
          semanticLabel: 'Ảnh hóa đơn $label',
          // The file can be gone (cleared storage, restored backup): show
          // an icon instead of an error.
          errorBuilder: (context, error, stackTrace) => ColoredBox(
            key: ExpenseSummaryCard.missingThumbnailKey,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.image_not_supported_outlined, size: 20),
          ),
        ),
      ),
    );
  }
}
