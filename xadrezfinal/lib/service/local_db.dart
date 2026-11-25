import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/chess_record.dart';

class LocalDb {
  LocalDb._();
  static final LocalDb instance = LocalDb._();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      join(await getDatabasesPath(), 'chess_records.db'),
      version: 3,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE records(
            id TEXT NOT NULL,
            userId TEXT NOT NULL,
            opponent TEXT NOT NULL,
            result TEXT NOT NULL,
            notes TEXT,
            date TEXT NOT NULL,
            latitude REAL,
            longitude REAL,
            imagePath TEXT,
            synced INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY(id, userId)
          )
        ''');
        await database.execute('''
          CREATE TABLE record_media(
            id TEXT NOT NULL,
            userId TEXT NOT NULL,
            imagePath TEXT NOT NULL,
            PRIMARY KEY(id, userId)
          )
        ''');
        await database.execute('''
          CREATE TABLE pending_deletes(
            id TEXT NOT NULL,
            userId TEXT NOT NULL,
            PRIMARY KEY(id, userId)
          )
        ''');
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await database.execute(
            "ALTER TABLE records ADD COLUMN userId TEXT NOT NULL DEFAULT ''",
          );
          await database.execute(
            "ALTER TABLE pending_deletes ADD COLUMN userId TEXT NOT NULL DEFAULT ''",
          );
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) {
            await database.rawUpdate(
              'UPDATE records SET userId = ? WHERE userId = ?',
              [uid, ''],
            );
            await database.rawUpdate(
              'UPDATE pending_deletes SET userId = ? WHERE userId = ?',
              [uid, ''],
            );
          }
        }
        if (oldVersion < 3) {
          await database.execute('''
            CREATE TABLE record_media(
              id TEXT NOT NULL,
              userId TEXT NOT NULL,
              imagePath TEXT NOT NULL,
              PRIMARY KEY(id, userId)
            )
          ''');
        }
      },
    );
    return _db!;
  }

  Future<List<ChessRecord>> all(String userId) async {
    final rows = await (await db).query(
      'records',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return rows.map(ChessRecord.fromMap).toList();
  }

  Future<void> save(String userId, ChessRecord record) async {
    final values = record.toMap()..['userId'] = userId;
    await (await db).insert(
      'records',
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String userId, String id) async {
    final database = await db;
    await database.insert(
      'pending_deletes',
      {'id': id, 'userId': userId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await database.delete(
      'records',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  Future<List<ChessRecord>> pending(String userId) async {
    final rows = await (await db).query(
      'records',
      where: 'synced = 0 AND userId = ?',
      whereArgs: [userId],
    );
    return rows.map(ChessRecord.fromMap).toList();
  }

  Future<List<String>> deletions(String userId) async {
    final rows = await (await db).query(
      'pending_deletes',
      columns: ['id'],
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return rows.map((row) => row['id'] as String).toList();
  }

  Future<void> removePendingRecord(String userId, String id) async {
    await (await db).delete(
      'records',
      where: 'id = ? AND userId = ? AND synced = 0',
      whereArgs: [id, userId],
    );
  }

  Future<void> clearDelete(String userId, String id) async {
    await (await db).delete(
      'pending_deletes',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  Future<void> saveMedia(String userId, String id, String? imagePath) async {
    if (imagePath == null) {
      await removeMedia(userId, id);
      return;
    }
    await (await db).insert(
      'record_media',
      {'id': id, 'userId': userId, 'imagePath': imagePath},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> mediaPath(String userId, String id) async {
    final rows = await (await db).query(
      'record_media',
      columns: ['imagePath'],
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['imagePath'] as String?;
  }

  Future<void> removeMedia(String userId, String id) async {
    await (await db).delete(
      'record_media',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }
}
