import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vku_expense_ocr/core/formatters.dart';
import 'package:vku_expense_ocr/models/field_confidence.dart';
import 'package:vku_expense_ocr/models/parsed_receipt.dart';
import 'package:vku_expense_ocr/services/receipt_scan_service.dart';
import 'package:vku_expense_ocr/state/ocr_providers.dart';
import 'package:vku_expense_ocr/widgets/ocr_text_panel.dart';
import 'package:vku_expense_ocr/widgets/state_message.dart';

/// TEMPORARY (Phase 3): pick a photo, run the real OCR pipeline and show
/// the raw text next to the parsed fields, to check OCR on a device before
/// the camera (Phase 6) and Review (Phase 7) exist. Removed in Phase 7;
/// [OcrTextPanel] moves into the Review screen (FR-4.5).
class OcrDebugScreen extends ConsumerStatefulWidget {
  const OcrDebugScreen({super.key});

  @override
  ConsumerState<OcrDebugScreen> createState() => _OcrDebugScreenState();
}

class _OcrDebugScreenState extends ConsumerState<OcrDebugScreen> {
  // Ephemeral UI state (W8 s4–6): only this screen cares about it.
  ScanResult? _result;
  bool _busy = false;

  Future<void> _pickAndScan() async {
    final path = await ref.read(pickGalleryImageProvider)();
    if (path == null || !mounted) return;
    setState(() => _busy = true);
    final result = await ref.read(receiptScanServiceProvider).scan(path);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Thử OCR (debug)')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton.icon(
              onPressed: _busy ? null : _pickAndScan,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Chọn ảnh hóa đơn'),
            ),
            const SizedBox(height: 12),
            if (_busy) const LinearProgressIndicator(),
            if (result == null && !_busy)
              const StateMessage(
                icon: Icons.document_scanner_outlined,
                title: 'Chưa có ảnh',
                message: 'Chọn một ảnh hóa đơn để xem kết quả OCR và parse.',
              ),
            if (result != null && !_busy) ...[
              if (result.error case final error?)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: ListTile(
                    leading: const Icon(Icons.error_outline),
                    title: Text(error),
                  ),
                ),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(result.imagePath),
                  height: 240,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    height: 80,
                    child: Center(child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _ParsedFields(receipt: result.receipt),
              const SizedBox(height: 12),
              OcrTextPanel(
                rows: result.rows,
                ocrDuration: result.ocrDuration,
                initiallyExpanded: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ParsedFields extends StatelessWidget {
  const _ParsedFields({required this.receipt});

  final ParsedReceipt receipt;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _FieldTile(
            label: 'Cửa hàng',
            value: receipt.merchant,
            confidence: receipt.merchantConfidence,
          ),
          _FieldTile(
            label: 'Tổng tiền',
            value: switch (receipt.total) {
              final int total => Formatters.vnd(total),
              null => null,
            },
            confidence: receipt.totalConfidence,
          ),
          _FieldTile(
            label: 'Ngày',
            value: switch (receipt.date) {
              final DateTime date => Formatters.date(date),
              null => null,
            },
            confidence: receipt.dateConfidence,
          ),
          _FieldTile(
            label: 'Danh mục',
            value: receipt.suggestedCategory?.label,
            confidence: receipt.categoryConfidence,
          ),
        ],
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  const _FieldTile({
    required this.label,
    required this.value,
    required this.confidence,
  });

  final String label;
  final String? value;
  final FieldConfidence confidence;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (icon, color) = switch (confidence) {
      FieldConfidence.high => (Icons.check_circle_outline, colors.primary),
      FieldConfidence.low => (Icons.warning_amber_outlined, colors.tertiary),
      FieldConfidence.missing => (Icons.help_outline, colors.error),
    };
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color),
      title: Text(label),
      subtitle: Text(value ?? '— không tìm thấy'),
      trailing: Text(confidence.name),
    );
  }
}
