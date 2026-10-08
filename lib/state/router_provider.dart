import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vku_expense_ocr/core/router.dart';

/// Single [GoRouter] for the app, created once per [ProviderScope].
///
/// Building the router inside `build()` would recreate it (and reset the
/// navigation stack) on every rebuild, so it lives in a provider instead.
final routerProvider = Provider<GoRouter>((ref) {
  final router = createAppRouter();
  ref.onDispose(router.dispose);
  return router;
});
