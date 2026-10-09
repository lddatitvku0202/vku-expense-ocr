import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vku_expense_ocr/models/expense.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/services/database_service.dart';
import 'package:vku_expense_ocr/services/expense_repository.dart';
import 'package:vku_expense_ocr/services/image_storage_service.dart';
import 'package:vku_expense_ocr/state/app_startup.dart';
import 'package:vku_expense_ocr/state/expense_providers.dart';
import 'package:vku_expense_ocr/state/storage_providers.dart';
import 'package:vku_expense_ocr/state/theme_mode_provider.dart';

import '../support/fake_expense_repository.dart';

void main() {
  sqfliteFfiInit();

  late Directory tempDir;
  late String dbPath;
  late ImageStorageService storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('vku_startup_test_');
    dbPath = p.join(tempDir.path, 'expenses.db');
    final documents = await Directory(p.join(tempDir.path, 'documents'))
        .create();
    storage = ImageStorageService(documentsDirectory: () async => documents);
  });

  tearDown(() => tempDir.delete(recursive: true));

  Future<StoredReceipt> savePhoto(String name) async {
    final source = p.join(tempDir.path, '$name.jpg');
    File(source)
        .writeAsBytesSync(img.encodeJpg(img.Image(width: 300, height: 400)));
    return storage.save(source);
  }

  Future<Database> openDb() =>
      DatabaseService(factory: databaseFactoryFfi).open(dbPath);

  test(
    'opens the database, removes orphan photos and loads settings',
    () async {
      final referenced = await savePhoto('kept');
      final orphan = await savePhoto('orphan'); // e.g. the app died during Undo

      final db = await openDb();
      await SqfliteExpenseRepository(db).insert(
        Expense(
          merchant: 'Co.opmart',
          amount: 150000,
          date: DateTime(2026, 10, 9),
          category: ExpenseCategory.food,
          imagePath: referenced.imagePath,
          thumbPath: referenced.thumbPath,
          createdAt: DateTime(2026, 10, 9),
          updatedAt: DateTime(2026, 10, 9),
        ),
      );
      await db.close();
      SharedPreferences.setMockInitialValues({
        ThemeModeNotifier.storageKey: 'dark',
      });

      final overrides = await createStartupOverrides(
        openDatabase: openDb,
        imageStorage: storage,
      );
      final container = ProviderContainer(overrides: overrides);
      addTearDown(() async {
        await container.read(databaseProvider).close();
        container.dispose();
      });

      expect(File(referenced.imagePath).existsSync(), isTrue);
      expect(File(referenced.thumbPath).existsSync(), isTrue);
      expect(File(orphan.imagePath).existsSync(), isFalse);
      expect(File(orphan.thumbPath).existsSync(), isFalse);

      final list = await container.read(expenseListProvider.future);
      expect(list.single.merchant, 'Co.opmart');
      expect(container.read(themeModeProvider), ThemeMode.dark);
    },
  );

  test(
    'removeOrphanReceipts never throws when the database cannot be read',
    () async {
      final photo = await savePhoto('a');
      final repo = FakeExpenseRepository()..failGetAll = Exception('corrupt');

      expect(await removeOrphanReceipts(repo, storage), 0);
      expect(
        File(photo.imagePath).existsSync(),
        isTrue,
        reason: 'nothing deleted blindly',
      );
    },
  );
}
