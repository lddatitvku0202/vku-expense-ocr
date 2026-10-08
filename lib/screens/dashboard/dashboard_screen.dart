import 'package:flutter/material.dart';
import 'package:vku_expense_ocr/widgets/state_message.dart';

/// "Tổng quan" tab: monthly total, category donut and weekly bars.
///
/// Placeholder until Phases 8–9 add the data and the charts.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tổng quan')),
      body: const SafeArea(
        child: StateMessage(
          icon: Icons.pie_chart_outline,
          title: 'Tổng quan chi tiêu',
          message: 'Biểu đồ chi tiêu sẽ hiển thị tại đây.',
        ),
      ),
    );
  }
}
