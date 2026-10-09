import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vku_expense_ocr/models/expense.dart';
import 'package:vku_expense_ocr/models/expense_category.dart';
import 'package:vku_expense_ocr/services/database_service.dart';
import 'package:vku_expense_ocr/services/expense_repository.dart';
import 'package:vku_expense_ocr/services/image_storage_service.dart';

void main() {
  late Directory tempDir;
  late Directory documents;
  late ImageStorageService storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('vku_images_test_');
    documents = await Directory(p.join(tempDir.path, 'documents')).create();
    storage = ImageStorageService(documentsDirectory: () async => documents);
  });

  tearDown(() => tempDir.delete(recursive: true));

  /// Writes a [width] x [height] test photo outside the documents folder,
  /// like the cropper's output in the cache directory.
  String photo(int width, int height, {String name = 'crop.jpg'}) {
    final image = img.Image(width: width, height: height);
    img.fill(image, color: img.ColorRgb8(240, 240, 230));
    img.fillRect(
      image,
      x1: 0,
      y1: 0,
      x2: width ~/ 2,
      y2: height ~/ 4,
      color: img.ColorRgb8(20, 20, 20),
    );
    final path = p.join(tempDir.path, name);
    final bytes = name.endsWith('.png')
        ? img.encodePng(image)
        : img.encodeJpg(image);
    File(path).writeAsBytesSync(bytes);
    return path;
  }

  String receiptsPath() =>
      p.join(documents.path, ImageStorageService.folderName);

  group('save (FR-5.3)', () {
    test('copies the photo into <documents>/receipts/', () async {
      final source = photo(1200, 1800);
      final stored = await storage.save(source);

      expect(p.dirname(stored.imagePath), receiptsPath());
      expect(
        File(stored.imagePath).readAsBytesSync(),
        File(source).readAsBytesSync(),
      );
      expect(
        File(source).existsSync(),
        isTrue,
        reason: 'the source is copied, not moved',
      );
    });

    test(
      'creates a 256 px wide JPEG thumbnail keeping the aspect ratio',
      () async {
        final stored = await storage.save(photo(1200, 1800));

        expect(p.dirname(stored.thumbPath), receiptsPath());
        expect(stored.thumbPath, endsWith('.jpg'));
        final bytes = File(stored.thumbPath).readAsBytesSync();
        expect(img.JpegDecoder().isValidFile(bytes), isTrue);
        final thumb = img.decodeJpg(bytes)!;
        expect(thumb.width, ImageStorageService.thumbnailWidth);
        expect(ImageStorageService.thumbnailWidth, 256);
        expect(thumb.height, 384);
      },
    );

    test(
      'makes a JPEG thumbnail from a PNG and keeps the original format',
      () async {
        final stored = await storage.save(photo(800, 400, name: 'shot.png'));

        expect(stored.imagePath, endsWith('.png'));
        final thumb = img.decodeJpg(File(stored.thumbPath).readAsBytesSync())!;
        expect((thumb.width, thumb.height), (256, 128));
      },
    );

    test('does not enlarge photos narrower than the thumbnail', () async {
      final stored = await storage.save(photo(200, 300));

      final thumb = img.decodeJpg(File(stored.thumbPath).readAsBytesSync())!;
      expect((thumb.width, thumb.height), (200, 300));
    });

    test('applies the EXIF orientation so the thumbnail is upright', () async {
      final image = img.Image(width: 600, height: 300)
        ..exif.imageIfd.orientation = 6; // rotate 90° clockwise to display
      final source = p.join(tempDir.path, 'rotated.jpg');
      File(source).writeAsBytesSync(img.encodeJpg(image));

      final stored = await storage.save(source);
      final thumb = img.decodeJpg(File(stored.thumbPath).readAsBytesSync())!;
      expect((thumb.width, thumb.height), (256, 512));
    });

    test('gives every saved receipt its own file names', () async {
      final source = photo(400, 600);
      final a = await storage.save(source);
      final b = await storage.save(source);

      expect({
        a.imagePath,
        a.thumbPath,
        b.imagePath,
        b.thumbPath,
      }, hasLength(4));
    });

    test(
      'a missing source fails with ImageStorageException and leaves no files',
      () async {
        await expectLater(
          storage.save(p.join(tempDir.path, 'nope.jpg')),
          throwsA(isA<ImageStorageException>()),
        );
        final dir = Directory(receiptsPath());
        expect(
          dir.existsSync() ? dir.listSync() : const <FileSystemEntity>[],
          isEmpty,
        );
      },
    );

    test('an undecodable file fails and the copied photo is removed', () async {
      final source = p.join(tempDir.path, 'broken.jpg');
      File(source).writeAsStringSync('not an image');

      await expectLater(
        storage.save(source),
        throwsA(isA<ImageStorageException>()),
      );
      expect(Directory(receiptsPath()).listSync(), isEmpty);
    });
  });

  group('createThumbnail', () {
    test('returns JPEG bytes of the requested width', () {
      final bytes = img.encodePng(img.Image(width: 1000, height: 500));
      final thumb = img.decodeJpg(createThumbnail(bytes, width: 100))!;
      expect((thumb.width, thumb.height), (100, 50));
    });

    test('throws ImageStorageException for bytes that are not an image', () {
      expect(
        () => createThumbnail([1, 2, 3], width: 100),
        throwsA(isA<ImageStorageException>()),
      );
    });
  });

  group('delete', () {
    test('removes the photo and the thumbnail', () async {
      final stored = await storage.save(photo(400, 600));

      await storage.delete([stored.imagePath, stored.thumbPath]);
      expect(File(stored.imagePath).existsSync(), isFalse);
      expect(File(stored.thumbPath).existsSync(), isFalse);
    });

    test('ignores null paths and files that are already gone', () async {
      final stored = await storage.save(photo(400, 600));
      File(stored.imagePath).deleteSync();

      await storage.delete([null, stored.imagePath, stored.thumbPath]);
      expect(File(stored.thumbPath).existsSync(), isFalse);
    });

    test('works before anything was ever saved', () async {
      await storage.delete([p.join(receiptsPath(), 'ghost.jpg')]);
    });

    test('never deletes files outside the receipts folder', () async {
      final outside = photo(100, 100, name: 'gallery_original.jpg');
      final sneaky = p.join(receiptsPath(), '..', 'other.jpg');
      File(p.join(documents.path, 'other.jpg')).writeAsStringSync('keep');

      await storage.delete([outside, sneaky]);
      expect(File(outside).existsSync(), isTrue);
      expect(File(p.join(documents.path, 'other.jpg')).existsSync(), isTrue);
    });
  });

  group('deleting an expense together with its files (FR-5.4)', () {
    late Database db;
    late SqfliteExpenseRepository repo;

    setUp(() async {
      sqfliteFfiInit();
      db = await DatabaseService(factory: databaseFactoryFfi)
          .open(inMemoryDatabasePath);
      repo = SqfliteExpenseRepository(db);
    });

    tearDown(() => db.close());

    Future<Expense> savedWithPhoto() async {
      final stored = await storage.save(photo(600, 900));
      return repo.insert(
        Expense(
          merchant: 'Co.opmart',
          amount: 150000,
          date: DateTime(2026, 10, 9),
          category: ExpenseCategory.food,
          imagePath: stored.imagePath,
          thumbPath: stored.thumbPath,
          createdAt: DateTime(2026, 10, 9),
          updatedAt: DateTime(2026, 10, 9),
        ),
      );
    }

    test('removes the row, the photo and the thumbnail', () async {
      final saved = await savedWithPhoto();

      final removed = await repo.delete(saved.id!);
      await storage.deleteFilesOf(removed!);

      expect(await repo.getById(saved.id!), isNull);
      expect(File(saved.imagePath!).existsSync(), isFalse);
      expect(File(saved.thumbPath!).existsSync(), isFalse);
    });

    test('does not crash when the photo files were already lost', () async {
      final saved = await savedWithPhoto();
      File(saved.imagePath!).deleteSync();
      File(saved.thumbPath!).deleteSync();

      final removed = await repo.delete(saved.id!);
      await storage.deleteFilesOf(removed!);

      expect(await repo.getAll(), isEmpty);
    });

    test('handles a manual expense without any photo', () async {
      final saved = await repo.insert(
        Expense(
          merchant: 'Quán cơm',
          amount: 35000,
          date: DateTime(2026, 10, 9),
          category: ExpenseCategory.food,
          createdAt: DateTime(2026, 10, 9),
          updatedAt: DateTime(2026, 10, 9),
        ),
      );

      await storage.deleteFilesOf((await repo.delete(saved.id!))!);
      expect(await repo.getAll(), isEmpty);
    });
  });
}
