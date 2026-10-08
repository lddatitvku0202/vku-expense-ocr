import 'package:flutter/material.dart';
import 'package:vku_expense_ocr/models/parsed_receipt.dart';
import 'package:vku_expense_ocr/widgets/state_message.dart';

/// Review & verification form (FR-4).
///
/// One screen serves three modes (FR-4.9):
/// - review a freshly scanned receipt ([receipt] is set),
/// - add an expense manually (nothing set),
/// - edit a saved expense ([expenseId] is set, route `/expense/:id`).
///
/// Placeholder until Phase 7 adds the form.
class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key, this.receipt, this.expenseId});

  final ParsedReceipt? receipt;
  final int? expenseId;

  @override
  Widget build(BuildContext context) {
    final title = expenseId != null ? 'Sửa giao dịch' : 'Xác nhận hóa đơn';
    final message = switch ((expenseId, receipt)) {
      (final int id, _) => 'Giao dịch #$id',
      (null, final ParsedReceipt _) => 'Dữ liệu đọc từ hóa đơn',
      (null, null) => 'Thêm giao dịch thủ công',
    };
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: StateMessage(
          icon: Icons.fact_check_outlined,
          title: title,
          message: message,
        ),
      ),
    );
  }
}
