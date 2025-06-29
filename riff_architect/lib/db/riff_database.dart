import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class RiffDatabase {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    sqfliteFfiInit(); // Initialize FFI support

    databaseFactory = databaseFactoryFfi; // THIS is the required fix!

    Directory documentsDir = await getApplicationDocumentsDirectory();
    String path = join(documentsDir.path, 'riff_architect.db');

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE riffs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT,
              category TEXT,
              file_path TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE songs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT,
              file_path TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE categories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT
            )
          ''');
        },
      ),
    );
  }
}
