import 'package:flutter/material.dart';

/// Collapsible "Xem văn bản OCR gốc" section with the OCR time (FR-4.5).
///
/// Shows the recognized rows exactly as the parser saw them, so the user
/// (and the developer) can tell an OCR mistake from a parsing mistake.
class OcrTextPanel extends StatelessWidget {
  const OcrTextPanel({
    super.key,
    required this.rows,
    required this.ocrDuration,
    this.initiallyExpanded = false,
  });

  /// Logical rows, top to bottom.
  final List<String> rows;
  final Duration ocrDuration;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: const Icon(Icons.text_snippet_outlined),
        title: const Text('Xem văn bản OCR gốc'),
        subtitle: Text(
          'Thời gian OCR: ${ocrDuration.inMilliseconds} ms · '
          '${rows.length} dòng',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rows.isEmpty)
            const Text('Không nhận dạng được chữ nào trong ảnh.')
          else
            SelectableText(
              rows.join('\n'),
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
        ],
      ),
    );
  }
}
