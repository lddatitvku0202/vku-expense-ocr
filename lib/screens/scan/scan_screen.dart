import 'package:flutter/material.dart';
import 'package:vku_expense_ocr/widgets/state_message.dart';

/// "Quét" tab: live camera viewfinder for receipts.
///
/// Placeholder until Phase 6 adds the camera.
class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét hóa đơn')),
      body: const SafeArea(
        child: StateMessage(
          icon: Icons.document_scanner_outlined,
          title: 'Quét hóa đơn',
          message: 'Camera chụp hóa đơn sẽ hiển thị tại đây.',
        ),
      ),
    );
  }
}
