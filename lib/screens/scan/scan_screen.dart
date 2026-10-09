import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vku_expense_ocr/core/router.dart';
import 'package:vku_expense_ocr/widgets/state_message.dart';

/// "Quét" tab: live camera viewfinder for receipts.
///
/// Placeholder until Phase 6 adds the camera. Until then it links to the
/// temporary OCR debug screen (Phase 3).
class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét hóa đơn')),
      body: SafeArea(
        child: StateMessage(
          icon: Icons.document_scanner_outlined,
          title: 'Quét hóa đơn',
          message: 'Camera chụp hóa đơn sẽ hiển thị tại đây.',
          action: OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.ocrDebug),
            icon: const Icon(Icons.bug_report_outlined),
            label: const Text('Thử OCR với ảnh có sẵn'),
          ),
        ),
      ),
    );
  }
}
