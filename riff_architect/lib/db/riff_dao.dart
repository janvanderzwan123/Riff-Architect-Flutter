import 'package:riff_architect/db/riff_database.dart';
import 'package:riff_architect/models/riff.dart';

class RiffDao {
  static Future<List<Riff>> getAllRiffs() async {
    final db = await RiffDatabase.db;
    final List<Map<String, dynamic>> maps = await db.query('riffs');
    return List.generate(maps.length, (i) => Riff.fromMap(maps[i]));
  }

  static Future<int> insertRiff(Riff riff) async {
    final db = await RiffDatabase.db;
    return await db.insert('riffs', riff.toMap());
  }

  static Future<int> deleteRiff(int id) async {
    final db = await RiffDatabase.db;
    return await db.delete('riffs', where: 'id = ?', whereArgs: [id]);
  }
}
