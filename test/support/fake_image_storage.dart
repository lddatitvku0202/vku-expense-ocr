import 'dart:io';

import 'package:vku_expense_ocr/models/expense.dart';
import 'package:vku_expense_ocr/services/image_storage_service.dart';

/// Records which photo files state code asked to delete, without touching
/// the disk. Futures complete on microtasks, so it works inside `fakeAsync`
/// (real file IO does not).
class FakeImageStorage implements ImageStorageService {
  /// Every path passed to [delete], in call order (nulls dropped).
  final List<String> deletedPaths = [];

  /// Every source passed to [save].
  final List<String> savedSources = [];

  /// Thrown by the next [save] when set (then cleared).
  ImageStorageException? failNextSave;

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

  /// Returns `/fake/receipts/receipt_<n>.jpg` and `..._thumb.jpg`.
  @override
  Future<StoredReceipt> save(String sourcePath) async {
    if (failNextSave case final error?) {
      failNextSave = null;
      throw error;
    }
    savedSources.add(sourcePath);
    final n = savedSources.length;
    return (
      imagePath: '/fake/receipts/receipt_$n.jpg',
      thumbPath: '/fake/receipts/receipt_${n}_thumb.jpg',
    );
  }
}
