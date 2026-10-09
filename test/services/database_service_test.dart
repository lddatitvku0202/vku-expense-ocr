import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vku_expense_ocr/services/database_service.dart';

void main() {
  sqfliteFfiInit();

  late Directory tempDir;
  late String dbPath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('vku_db_test_');
    dbPath = p.join(tempDir.path, 'expenses.db');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  Future<Map<String, Map<String, Object?>>> columnsOf(Database db) async {
    final rows = await db.rawQuery(
      'PRAGMA table_info(${DatabaseService.tableExpenses})',
    );
    return {for (final row in rows) row['name']! as String: row};
  }

  Map<String, Object?> row(String merchant, int amount) => {
    'merchant': merchant,
    'amount': amount,
    'date': DateTime(2026, 10, 1).millisecondsSinceEpoch,
    'category': 'food',
    'image_path': '/receipts/$merchant.jpg',
    'thumb_path': '/receipts/${merchant}_thumb.jpg',
    'raw_text': 'raw $merchant',
    'created_at': 1,
    'updated_at': 2,
  };

  group('schema version 1 (FR-5.1)', () {
    test('creates the expenses table with the required columns', () async {
      final db = await DatabaseService(factory: databaseFactoryFfi)
          .open(dbPath);
      addTearDown(db.close);

      expect(await db.getVersion(), DatabaseService.schemaVersion);
      expect(DatabaseService.schemaVersion, 1);

      final columns = await columnsOf(db);
      expect(columns.keys, [
        'id',
        'merchant',
        'amount',
        'date',
        'category',
        'image_path',
        'thumb_path',
        'raw_text',
        'created_at',
        'updated_at',
      ]);

      String type(String name) => columns[name]!['type']! as String;
      bool notNull(String name) => columns[name]!['notnull'] == 1;

      expect(type('id'), 'INTEGER');
      expect(columns['id']!['pk'], 1);
      for (final name in ['amount', 'date', 'created_at', 'updated_at']) {
        expect(type(name), 'INTEGER', reason: name);
        expect(notNull(name), isTrue, reason: name);
      }
      for (final name in ['merchant', 'category']) {
        expect(type(name), 'TEXT', reason: name);
        expect(notNull(name), isTrue, reason: name);
      }
      for (final name in ['image_path', 'thumb_path', 'raw_text']) {
        expect(type(name), 'TEXT', reason: name);
        expect(notNull(name), isFalse, reason: name);
      }
    });

    test('id is AUTOINCREMENT: ids of deleted rows are never reused', () async {
      final db = await DatabaseService(factory: databaseFactoryFfi)
          .open(dbPath);
      addTearDown(db.close);

      final sql =
          (await db.rawQuery(
                "SELECT sql FROM sqlite_master WHERE name = 'expenses'",
              )).single['sql']!
              as String;
      expect(sql.toUpperCase(), contains('AUTOINCREMENT'));

      final first = await db.insert(
        DatabaseService.tableExpenses,
        row('A', 1000),
      );
      await db.delete(
        DatabaseService.tableExpenses,
        where: 'id = ?',
        whereArgs: [first],
      );
      final second = await db.insert(
        DatabaseService.tableExpenses,
        row('B', 2000),
      );
      expect(second, greaterThan(first));
    });

    test('rejects rows that miss a NOT NULL column', () async {
      final db = await DatabaseService(factory: databaseFactoryFfi)
          .open(dbPath);
      addTearDown(db.close);

      final incomplete = row('A', 1000)..remove('amount');
      expect(
        () => db.insert(DatabaseService.tableExpenses, incomplete),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('indexes the date column used by range queries', () async {
      final db = await DatabaseService(factory: databaseFactoryFfi)
          .open(dbPath);
      addTearDown(db.close);

      final indexes = await db.rawQuery(
        "PRAGMA index_list('${DatabaseService.tableExpenses}')",
      );
      final indexedColumns = <String>[];
      for (final index in indexes) {
        final info = await db.rawQuery("PRAGMA index_info('${index['name']}')");
        indexedColumns.addAll(info.map((c) => c['name']! as String));
      }
      expect(indexedColumns, contains('date'));
    });

    test('reopening at the same version keeps the data', () async {
      final service = DatabaseService(factory: databaseFactoryFfi);
      final db = await service.open(dbPath);
      await db.insert(DatabaseService.tableExpenses, row('A', 1000));
      await db.close();

      final reopened = await service.open(dbPath);
      addTearDown(reopened.close);
      expect(await reopened.query(DatabaseService.tableExpenses), hasLength(1));
    });
  });

  group('onUpgrade', () {
    // A hypothetical version 2 that adds a column, to prove that upgrading
    // from version 1 migrates in place instead of recreating the table.
    const v2 = {
      2: ['ALTER TABLE expenses ADD COLUMN note TEXT'],
    };

    test('upgrading from version 1 keeps every row and value', () async {
      final v1 = await DatabaseService(factory: databaseFactoryFfi)
          .open(dbPath);
      await v1.insert(DatabaseService.tableExpenses, row('Highlands', 59000));
      await v1.insert(DatabaseService.tableExpenses, row('Fahasa', 1250000));
      final before = await v1.query(
        DatabaseService.tableExpenses,
        orderBy: 'id',
      );
      await v1.close();

      final upgraded = await DatabaseService(
        factory: databaseFactoryFfi,
        version: 2,
        migrations: v2,
      ).open(dbPath);
      addTearDown(upgraded.close);

      expect(await upgraded.getVersion(), 2);
      expect((await columnsOf(upgraded)).keys, contains('note'));
      final after = await upgraded.query(
        DatabaseService.tableExpenses,
        orderBy: 'id',
      );
      expect(after, hasLength(2));
      for (var i = 0; i < before.length; i++) {
        expect({...after[i]}..remove('note'), before[i]);
        expect(after[i]['note'], isNull);
      }
    });

    test('a fresh install at a later version gets the same schema', () async {
      final db = await DatabaseService(
        factory: databaseFactoryFfi,
        version: 2,
        migrations: v2,
      ).open(dbPath);
      addTearDown(db.close);

      expect((await columnsOf(db)).keys, contains('note'));
    });

    test(
      'runs every step between the old and the new version in order',
      () async {
        final v1 = await DatabaseService(factory: databaseFactoryFfi)
            .open(dbPath);
        await v1.insert(DatabaseService.tableExpenses, row('A', 1000));
        await v1.close();

        final db = await DatabaseService(
          factory: databaseFactoryFfi,
          version: 3,
          migrations: const {
            2: ['ALTER TABLE expenses ADD COLUMN note TEXT'],
            3: ["UPDATE expenses SET note = 'migrated' WHERE note IS NULL"],
          },
        ).open(dbPath);
        addTearDown(db.close);

        final rows = await db.query(DatabaseService.tableExpenses);
        expect(rows.single['note'], 'migrated');
        expect(rows.single['merchant'], 'A');
      },
    );

    test(
      'refuses to upgrade when a step is missing, leaving data untouched',
      () async {
        final v1 = await DatabaseService(factory: databaseFactoryFfi)
            .open(dbPath);
        await v1.insert(DatabaseService.tableExpenses, row('A', 1000));
        await v1.close();

        await expectLater(
          DatabaseService(factory: databaseFactoryFfi, version: 2).open(dbPath),
          throwsA(isA<StateError>()),
        );

        final again = await DatabaseService(factory: databaseFactoryFfi)
            .open(dbPath);
        addTearDown(again.close);
        expect(await again.getVersion(), 1);
        expect(await again.query(DatabaseService.tableExpenses), hasLength(1));
      },
    );

    test(
      'the shipped migrations cover every version up to the current one',
      () {
        for (var v = 2; v <= DatabaseService.schemaVersion; v++) {
          expect(DatabaseService.schemaMigrations, contains(v));
        }
      },
    );
  });
}
