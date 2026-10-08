import 'package:flutter/material.dart';
import 'package:vku_expense_ocr/widgets/state_message.dart';

/// "Lịch sử" tab: list of saved expenses.
///
/// Placeholder until Phase 8 adds the list.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử')),
      body: const SafeArea(
        child: StateMessage(
          icon: Icons.receipt_long_outlined,
          title: 'Lịch sử chi tiêu',
          message: 'Danh sách giao dịch đã lưu sẽ hiển thị tại đây.',
        ),
      ),
    );
  }
}
