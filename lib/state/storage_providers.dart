import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:vku_expense_ocr/services/expense_repository.dart';
import 'package:vku_expense_ocr/services/image_storage_service.dart';
import 'package:vku_expense_ocr/services/settings_store.dart';

/// Current time. Overridden in tests so "this week" and "this month" are
/// fixed dates.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// The open SQLite database. Opened once in `main()` before `runApp`
/// (`createStartupOverrides`) and injected with an override, so every
/// provider below can be synchronous.
final databaseProvider = Provider<Database>(
  (ref) => throw UnimplementedError(
    'databaseProvider must be overridden (see createStartupOverrides)',
  ),
);

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => SqfliteExpenseRepository(
    ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
  ),
);

final imageStorageProvider = Provider<ImageStorageService>(
  (ref) => ImageStorageService(),
);

/// Loaded in `main()` like [databaseProvider], so the saved theme mode is
/// known before the first frame (no light-to-dark flash).
final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => throw UnimplementedError(
    'settingsStoreProvider must be overridden (see createStartupOverrides)',
  ),
);
