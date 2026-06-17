import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'schema.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Database get db {
    if (_db == null) throw StateError('Database not initialised. Call init() first.');
    return _db!;
  }

  Future<void> init() async {
    if (_db != null) return;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'medcenter.db');

    _db = await openDatabase(
      path,
      version: Schema.version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        // sqflite on Android only allows rawQuery (not execute) in onConfigure.
        // foreign_keys must be enabled here, before any transactions open.
        await db.rawQuery('PRAGMA foreign_keys = ON');
      },
      onOpen: (db) async {
        // WAL mode via rawQuery — safe every open, SQLite ignores if already set.
        await db.rawQuery('PRAGMA journal_mode = WAL');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    for (final sql in Schema.all) {
      await db.execute(sql);
    }
    // Seed default counters
    final batch = db.batch();
    for (final key in ['patient', 'appointment', 'invoice', 'receipt', 'prescription', 'lab']) {
      batch.insert('counters', {'key': key, 'value': 0},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit();
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // V1 → V2: add new columns (ignore errors if column already exists)
      for (final sql in Schema.v2Migrations) {
        try {
          await db.execute(sql);
        } catch (_) {
          // Column already exists — safe to ignore
        }
      }
    }
  }

  /// Atomically increment and return the next counter value
  Future<int> nextCounter(String key) async {
    return await db.transaction((txn) async {
      await txn.rawUpdate(
          'UPDATE counters SET value = value + 1 WHERE key = ?', [key]);
      final rows = await txn.query('counters',
          columns: ['value'], where: 'key = ?', whereArgs: [key]);
      return rows.first['value'] as int;
    });
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
    List<String>? columns,
  }) =>
      db.query(table,
          columns: columns,
          where: where,
          whereArgs: whereArgs,
          orderBy: orderBy,
          limit: limit,
          offset: offset);

  Future<int> insert(String table, Map<String, dynamic> values,
          {ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.replace}) =>
      db.insert(table, values, conflictAlgorithm: conflictAlgorithm);

  Future<int> update(String table, Map<String, dynamic> values,
          {String? where, List<Object?>? whereArgs}) =>
      db.update(table, values, where: where, whereArgs: whereArgs);

  Future<int> delete(String table,
          {String? where, List<Object?>? whereArgs}) =>
      db.delete(table, where: where, whereArgs: whereArgs);

  Future<List<Map<String, dynamic>>> rawQuery(String sql,
          [List<Object?>? args]) =>
      db.rawQuery(sql, args);

  Future<int> rawUpdate(String sql, [List<Object?>? args]) =>
      db.rawUpdate(sql, args);

  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) =>
      db.transaction(action);

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
