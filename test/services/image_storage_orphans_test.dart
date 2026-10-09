import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:vku_expense_ocr/services/image_storage_service.dart';

void main() {
  late Directory tempDir;
  late Directory documents;
  late ImageStorageService storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('vku_orphans_test_');
    documents = await Directory(p.join(tempDir.path, 'documents')).create();
    storage = ImageStorageService(documentsDirectory: () async => documents);
  });

  tearDown(() => tempDir.delete(recursive: true));

  Future<StoredReceipt> saved() async {
    final source = p.join(
      tempDir.path,
      'src_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    File(source)
        .writeAsBytesSync(img.encodeJpg(img.Image(width: 300, height: 400)));
    return storage.save(source);
  }

  group('deleteUnreferenced (orphan clean-up)', () {
    test(
      'deletes receipts files that no expense references, keeps the rest',
      () async {
        final kept = await saved();
        final orphan = await saved();

        final count = await storage.deleteUnreferenced([
          kept.imagePath,
          kept.thumbPath,
          null,
        ]);

        expect(count, 2);
        expect(File(kept.imagePath).existsSync(), isTrue);
        expect(File(kept.thumbPath).existsSync(), isTrue);
        expect(File(orphan.imagePath).existsSync(), isFalse);
        expect(File(orphan.thumbPath).existsSync(), isFalse);
      },
    );

    test('matches referenced paths written in another form', () async {
      final kept = await saved();
      final dotted = p.join(
        p.dirname(kept.imagePath),
        '.',
        p.basename(kept.imagePath),
      );

      await storage.deleteUnreferenced([dotted, kept.thumbPath]);
      expect(File(kept.imagePath).existsSync(), isTrue);
    });

    test('never touches anything outside the receipts folder', () async {
      await saved();
      final sibling = File(p.join(documents.path, 'notes.txt'))
        ..writeAsStringSync('keep');
      final outside = File(p.join(tempDir.path, 'gallery.jpg'))
        ..writeAsStringSync('keep');
      final nested = Directory(
        p.join(documents.path, ImageStorageService.folderName, 'sub'),
      )..createSync();
      final nestedFile = File(p.join(nested.path, 'x.jpg'))
        ..writeAsStringSync('keep');

      await storage.deleteUnreferenced(const []);

      expect(sibling.existsSync(), isTrue);
      expect(outside.existsSync(), isTrue);
      expect(
        nestedFile.existsSync(),
        isTrue,
        reason: 'sub-folders are left alone',
      );
    });

    test('returns 0 when the receipts folder does not exist yet', () async {
      expect(await storage.deleteUnreferenced(const []), 0);
    });
  });
}
