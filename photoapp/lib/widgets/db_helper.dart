import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static Database? _database;

  // Initialize or get the existing database
  static Future<Database> getDatabase() async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'photo_management.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE user_data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cookie TEXT,
            server TEXT
          )
        ''');
      },
    );
  }

  // Get the stored cookie and server address (if any)
  static Future<Map<String, String?>> getCookieAndServer() async {
    final db = await getDatabase();
    List<Map<String, dynamic>> result = await db.query('user_data', limit: 1);
    if (result.isNotEmpty) {
      return {
        'cookie': result.first['cookie'] as String?,
        'server': result.first['server'] as String?,
      };
    }
    return {'cookie': null, 'server': null};
  }

  // Save a new cookie and server address to the database
  static Future<void> saveCookieAndServer(String cookie, String server) async {
    final db = await getDatabase();
    await db.insert(
      'user_data',
      {
        'cookie': cookie,
        'server': server,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Clear the stored cookie and server address
  static Future<void> clearCookieAndServer() async {
    final db = await getDatabase();
    await db.delete('user_data');
  }
}