import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vku_expense_ocr/models/parsed_receipt.dart';
import 'package:vku_expense_ocr/screens/dashboard/dashboard_screen.dart';
import 'package:vku_expense_ocr/screens/debug/ocr_debug_screen.dart';
import 'package:vku_expense_ocr/screens/history/history_screen.dart';
import 'package:vku_expense_ocr/screens/review/review_screen.dart';
import 'package:vku_expense_ocr/screens/scan/camera_screen.dart';
import 'package:vku_expense_ocr/screens/shell/home_shell.dart';
import 'package:vku_expense_ocr/services/receipt_scan_service.dart';
import 'package:vku_expense_ocr/widgets/state_message.dart';

/// Route paths used across the app (W8 s20–24).
abstract final class AppRoutes {
  static const String dashboard = '/dashboard';
  static const String scan = '/scan';
  static const String history = '/history';

  /// Review form; the parsed receipt travels in `extra` (FR-7.2).
  static const String review = '/review';

  /// Edit form for a saved expense, with the id as a path parameter.
  static const String expensePattern = '/expense/:id';

  static String expense(int id) => '/expense/$id';

  /// Temporary OCR check screen (Phase 3, removed in Phase 7).
  static const String ocrDebug = '/debug/ocr';
}

/// Creates the app router.
///
/// A factory instead of a global so every test (and every [ProviderScope])
/// gets a fresh router with its own navigation state.
GoRouter createAppRouter({String initialLocation = AppRoutes.dashboard}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.scan,
                builder: (context, state) => const CameraScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.history,
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.review,
        builder: (context, state) => switch (state.extra) {
          // From the camera or gallery: photo, parsed fields, OCR time.
          final ScanResult scan => ReviewScreen(
            receipt: scan.receipt,
            scan: scan,
          ),
          final ParsedReceipt receipt => ReviewScreen(receipt: receipt),
          _ => const ReviewScreen(),
        },
      ),
      GoRoute(
        path: AppRoutes.expensePattern,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) return const _NotFoundScreen();
          return ReviewScreen(expenseId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.ocrDebug,
        builder: (context, state) => const OcrDebugScreen(),
      ),
    ],
    errorBuilder: (context, state) => const _NotFoundScreen(),
  );
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Không tìm thấy')),
      body: SafeArea(
        child: StateMessage(
          icon: Icons.search_off,
          title: 'Trang không tồn tại',
          action: FilledButton(
            onPressed: () => context.go(AppRoutes.dashboard),
            child: const Text('Về Tổng quan'),
          ),
        ),
      ),
    );
  }
}
