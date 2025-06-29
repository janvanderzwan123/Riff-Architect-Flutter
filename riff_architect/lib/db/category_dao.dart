import 'package:riff_architect/db/riff_database.dart';
import 'package:sqflite_common/sqlite_api.dart';

class CategoryDao {
  static Future<Database> get _db async => await RiffDatabase.db;

  static Future<void> insertCategory(String name) async {
    final db = await _db;
    await db.insert(
      'categories',
      {'name': name},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<List<String>> getAllCategories() async {
    final db = await _db;
    final result = await db.query('categories');
    return result.map((row) => row['name'] as String).toList();
  }

  static Future<void> deleteCategory(String name) async {
    final db = await _db;
    await db.delete('categories', where: 'name = ?', whereArgs: [name]);
  }

  static Future<void> renameCategory(String oldName, String newName) async {
    final db = await _db;
    await db.update(
      'categories',
      {'name': newName},
      where: 'name = ?',
      whereArgs: [oldName],
    );
  }
}
