import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('journal.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDb);
  }

  Future _createDb(Database db, int version) async {
    await db.execute('''CREATE TABLE journals(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    snippet TEXT,
    date TEXT,
    mood INTEGER,
    image_path TEXT)''');
  }

  Future<int> create(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('journals', row);
  }

  Future<List<Map<String, dynamic>>> readAllJournals() async {
    final db = await instance.database;
    final result = await db.query('journals', orderBy: 'id DESC');
    return result;
  }

  Future<int> update(Map<String, dynamic> row) async {
    final db = await instance.database;
    int id = row['id'];
    return await db.update('journals', row, where: 'id=?', whereArgs: [id]);
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return db.delete('journals', where: 'id = ?', whereArgs: [id]);
  }
}
