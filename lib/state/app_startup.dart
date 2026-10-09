import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:vku_expense_ocr/services/database_service.dart';
import 'package:vku_expense_ocr/services/expense_repository.dart';
import 'package:vku_expense_ocr/services/image_storage_service.dart';
import 'package:vku_expense_ocr/services/settings_store.dart';
import 'package:vku_expense_ocr/state/storage_providers.dart';

/// Opens what the providers need before the first frame and returns the
/// overrides for the root `ProviderScope`.
///
/// The orphan sweep runs here, before `runApp`, because no photo can be in
/// the middle of being saved yet; running it later could delete a photo
/// whose database row is about to be inserted.
Future<List<Override>> createStartupOverrides({
  Future<Database> Function()? openDatabase,
  ImageStorageService? imageStorage,
  Future<SharedPreferences> Function()? preferences,
}) async {
  final db = await (openDatabase ?? () => DatabaseService().open())();
  final images = imageStorage ?? ImageStorageService();
  final prefs = await (preferences ?? SharedPreferences.getInstance)();

  await removeOrphanReceipts(SqfliteExpenseRepository(db), images);

  return [
    databaseProvider.overrideWithValue(db),
    imageStorageProvider.overrideWithValue(images),
    settingsStoreProvider.overrideWithValue(
      SharedPreferencesSettingsStore(prefs),
    ),
  ];
}

/// Deletes photos in the receipts folder that no expense references (left
/// behind when the app was killed during an Undo window) and returns how
/// many. Never throws: if the database cannot be read, nothing is deleted.
Future<int> removeOrphanReceipts(
  ExpenseRepository repository,
  ImageStorageService images,
) async {
  try {
    final expenses = await repository.getAll();
    final count = await images.deleteUnreferenced([
      for (final e in expenses) ...[e.imagePath, e.thumbPath],
    ]);
    if (count > 0) {
      developer.log(
        'Removed $count orphan receipt files',
        name: 'vku_expense_ocr.startup',
      );
    }
    return count;
  } on Exception catch (error) {
    developer.log(
      'Orphan clean-up skipped',
      name: 'vku_expense_ocr.startup',
      error: error,
    );
    return 0;
  }
}
