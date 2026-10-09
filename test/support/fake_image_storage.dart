import 'dart:io';

import 'package:vku_expense_ocr/models/expense.dart';
import 'package:vku_expense_ocr/services/image_storage_service.dart';

/// Records which photo files state code asked to delete, without touching
/// the disk. Futures complete on microtasks, so it works inside `fakeAsync`
/// (real file IO does not).
class FakeImageStorage implements ImageStorageService {
  /// Every path passed to [delete], in call order (nulls dropped).
  final List<String> deletedPaths = [];

  @override
  Future<void> delete(Iterable<String?> paths) async {
    deletedPaths.addAll(paths.nonNulls);
  }

  @override
  Future<void> deleteFilesOf(Expense expense) =>
      delete([expense.imagePath, expense.thumbPath]);

  @override
  Future<int> deleteUnreferenced(Iterable<String?> referenced) async => 0;

  @override
  Future<Directory> receiptsDirectory() async => Directory('/fake/receipts');

  @override
  Future<StoredReceipt> save(String sourcePath) async =>
      (imagePath: '/fake/receipts/a.jpg', thumbPath: '/fake/receipts/a_t.jpg');
}
