import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:vku_expense_ocr/app.dart';
import 'package:vku_expense_ocr/state/app_startup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load Vietnamese date symbols before any DateFormat is used.
  await initializeDateFormatting('vi_VN');
  Intl.defaultLocale = 'vi_VN';
  // Database, settings and the orphan photo sweep, before the first frame.
  final overrides = await createStartupOverrides();
  runApp(ProviderScope(overrides: overrides, child: const VkuExpenseApp()));
}
