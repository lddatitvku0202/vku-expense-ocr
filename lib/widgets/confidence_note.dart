import 'package:flutter/material.dart';
import 'package:vku_expense_ocr/models/field_confidence.dart';

/// Inline mark under a field the parser was unsure of (FR-4.4): an icon
/// and a caption, so it does not rely on colour alone. Nothing for
/// [FieldConfidence.high].
class ConfidenceNote extends StatelessWidget {
  const ConfidenceNote({
    super.key,
    required this.confidence,
    required this.lowText,
    required this.missingText,
  });

  final FieldConfidence confidence;
  final String lowText;
  final String missingText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, text, color) = switch (confidence) {
      FieldConfidence.high => (null, '', scheme.onSurface),
      FieldConfidence.low => (Icons.help_outline, lowText, scheme.tertiary),
      FieldConfidence.missing => (
        Icons.error_outline,
        missingText,
        scheme.error,
      ),
    };
    if (icon == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// The merchant warning: a filled banner at the top of the form. The
/// merchant name was the weakest field in the Phase 3 evaluation (7/19 on
/// real receipts), so its warning is the most prominent one.
class MerchantWarningBanner extends StatelessWidget {
  const MerchantWarningBanner({super.key, required this.confidence});

  final FieldConfidence confidence;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final missing = confidence == FieldConfidence.missing;
    final background = missing
        ? scheme.errorContainer
        : scheme.tertiaryContainer;
    final foreground = missing
        ? scheme.onErrorContainer
        : scheme.onTertiaryContainer;
    return Semantics(
      liveRegion: true,
      child: Card(
        color: background,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                missing ? Icons.error : Icons.warning_amber_rounded,
                size: 32,
                color: foreground,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      missing
                          ? 'Không đọc được tên cửa hàng'
                          : 'Tên cửa hàng có thể bị đọc sai',
                      style: textTheme.titleMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      missing
                          ? 'Hãy nhập tên cửa hàng ở ô bên dưới.'
                          : 'Không chắc chắn — hãy kiểm tra lại. Đây là '
                                'thông tin ứng dụng hay đọc sai nhất.',
                      style: textTheme.bodyMedium?.copyWith(color: foreground),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
