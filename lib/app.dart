import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vku_expense_ocr/core/app_theme.dart';
import 'package:vku_expense_ocr/state/router_provider.dart';
import 'package:vku_expense_ocr/state/theme_mode_provider.dart';

/// Root widget: Material 3 light/dark themes with the saved theme mode,
/// Vietnamese locale and the GoRouter configuration.
class VkuExpenseApp extends ConsumerWidget {
  const VkuExpenseApp({super.key});

  static const Locale locale = Locale('vi', 'VN');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'VKU Expense OCR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      locale: locale,
      supportedLocales: const [locale, Locale('en', 'US')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
    );
  }
}
