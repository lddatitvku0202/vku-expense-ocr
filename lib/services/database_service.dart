import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:vku_expense_ocr/models/expense.dart';

/// Opens the local SQLite database and keeps its schema up to date (FR-5.1).
///
/// The schema is defined once, as version 1 ([_createVersion1]), plus one
/// list of SQL statements per later version ([schemaMigrations]). A fresh
/// install runs version 1 and then every migration, an existing install
/// runs only the migrations it has not seen yet. Both paths therefore end
/// with the same tables, and upgrading never drops data.
class DatabaseService {
  DatabaseService({
    DatabaseFactory? factory,
    this.version = schemaVersion,
    this.migrations = schemaMigrations,
  }) : _factory = factory ?? databaseFactory;

  static const String fileName = 'vku_expense.db';
  static const String tableExpenses = 'expenses';

  /// Current schema version shipped with the app.
  static const int schemaVersion = 1;

  /// SQL that turns version `n - 1` into version `n`, keyed by `n`.
  ///
  /// To change the schema: bump [schemaVersion] and add its statements here
  /// (for example `ALTER TABLE expenses ADD COLUMN note TEXT`). Never edit
  /// [_createVersion1], or existing users would end up with a different
  /// schema than new ones.
  static const Map<int, List<String>> schemaMigrations = {};

  final DatabaseFactory _factory;

  /// Schema version this instance opens; tests pass a higher one.
  final int version;
  final Map<int, List<String>> migrations;

  /// Opens (and creates or upgrades) the database at [path], by default
  /// `vku_expense.db` in the platform's databases folder.
  Future<Database> open([String? path]) async {
    final file = path ?? p.join(await _factory.getDatabasesPath(), fileName);
    return _factory.openDatabase(
      file,
      options: OpenDatabaseOptions(
        version: version,
        onCreate: (db, version) async {
          await _createVersion1(db);
          await _migrate(db, from: 1, to: version);
        },
        onUpgrade: (db, oldVersion, newVersion) =>
            _migrate(db, from: oldVersion, to: newVersion),
      ),
    );
  }

  static Future<void> _createVersion1(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $tableExpenses (
        ${Expense.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${Expense.columnMerchant} TEXT NOT NULL,
        ${Expense.columnAmount} INTEGER NOT NULL,
        ${Expense.columnDate} INTEGER NOT NULL,
        ${Expense.columnCategory} TEXT NOT NULL,
        ${Expense.columnImagePath} TEXT,
        ${Expense.columnThumbPath} TEXT,
        ${Expense.columnRawText} TEXT,
        ${Expense.columnCreatedAt} INTEGER NOT NULL,
        ${Expense.columnUpdatedAt} INTEGER NOT NULL
      )''');
    // History and the charts always filter or sort by date.
    await db.execute(
      'CREATE INDEX idx_${tableExpenses}_date '
      'ON $tableExpenses (${Expense.columnDate})',
    );
  }

  /// Runs the steps `from + 1 … to` in order. sqflite wraps `onCreate` and
  /// `onUpgrade` in a transaction, so a failing step rolls everything back
  /// and the database stays at its old version with its data intact.
  Future<void> _migrate(
    DatabaseExecutor db, {
    required int from,
    required int to,
  }) async {
    for (var next = from + 1; next <= to; next++) {
      final steps = migrations[next];
      if (steps == null) {
        throw StateError('No migration to database version $next');
      }
      for (final sql in steps) {
        await db.execute(sql);
      }
    }
  }
}
