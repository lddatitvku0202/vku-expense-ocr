// Database and photo storage on a real Android device or emulator, with the
// platform sqflite plugin and path_provider (the unit tests use
// sqflite_common_ffi and temporary folders on the computer instead).
//
//   flutter test integration_test/storage_test.dart -d <device id>
//
// Uses its own database file and documents sub-folder, removed at the end,
// so the app's real data is never touched.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:vku_expense_ocr/models/expense.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/services/database_service.dart';
import 'package:vku_expense_ocr/services/expense_repository.dart';
import 'package:vku_expense_ocr/services/image_storage_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('saves, queries and deletes an expense with its photo', (
    tester,
  ) async {
    final dbPath = p.join(await getDatabasesPath(), 'it_storage_test.db');
    await deleteDatabase(dbPath);
    final documents = await getApplicationDocumentsDirectory();
    final root = Directory(p.join(documents.path, 'it_storage_test'));
    final cache = await getTemporaryDirectory();
    final source = File(p.join(cache.path, 'it_receipt.jpg'))
      ..writeAsBytesSync(img.encodeJpg(img.Image(width: 1200, height: 1800)));

    final db = await DatabaseService().open(dbPath);
    try {
      final storage = ImageStorageService(documentsDirectory: () async => root);
      final repo = SqfliteExpenseRepository(db);

      final stored = await storage.save(source.path);
      expect(p.isWithin(root.path, stored.imagePath), isTrue);
      final thumb = img.decodeJpg(File(stored.thumbPath).readAsBytesSync())!;
      expect(thumb.width, ImageStorageService.thumbnailWidth);

      final saved = await repo.insert(
        Expense(
          merchant: 'Co.opmart Huế',
          amount: 1250000,
          date: DateTime(2026, 10, 9, 23, 59, 59, 999),
          category: ExpenseCategory.food,
          imagePath: stored.imagePath,
          thumbPath: stored.thumbPath,
          createdAt: DateTime(2026, 10, 9),
          updatedAt: DateTime(2026, 10, 9),
        ),
      );
      expect(await repo.getById(saved.id!), saved);
      expect(
        await repo.getBetween(DateTime(2026, 10, 9), DateTime(2026, 10, 9)),
        [saved],
      );
      expect(await repo.totalsByCategory(), {ExpenseCategory.food: 1250000});

      final removed = await repo.delete(saved.id!);
      await storage.deleteFilesOf(removed!);
      expect(await repo.getAll(), isEmpty);
      expect(File(stored.imagePath).existsSync(), isFalse);
      expect(File(stored.thumbPath).existsSync(), isFalse);
    } finally {
      await db.close();
      await deleteDatabase(dbPath);
      if (root.existsSync()) root.deleteSync(recursive: true);
      if (source.existsSync()) source.deleteSync();
    }
  });
}
