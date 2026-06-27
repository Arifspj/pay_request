import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/payment_request.dart';
import '../models/favorite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'pay_request.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        merchant_name TEXT NOT NULL,
        upi_id TEXT NOT NULL,
        amount REAL NOT NULL,
        invoice_path TEXT,
        contact_name TEXT,
        contact_number TEXT,
        status TEXT NOT NULL DEFAULT 'Pending',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        mobile TEXT NOT NULL,
        photo TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // --- Requests ---
  Future<int> insertRequest(PaymentRequest request) async {
    final db = await database;
    return await db.insert('requests', request.toMap());
  }

  Future<List<PaymentRequest>> getRequests({int limit = 20}) async {
    final db = await database;
    final maps = await db.query(
      'requests',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps.map((map) => PaymentRequest.fromMap(map)).toList();
  }

  Future<int> updateRequest(PaymentRequest request) async {
    final db = await database;
    return await db.update(
      'requests',
      request.toMap(),
      where: 'id = ?',
      whereArgs: [request.id],
    );
  }

  Future<int> deleteRequest(int id) async {
    final db = await database;
    return await db.delete('requests', where: 'id = ?', whereArgs: [id]);
  }

  // --- Favorites ---
  Future<int> insertFavorite(Favorite favorite) async {
    final db = await database;
    return await db.insert('favorites', favorite.toMap());
  }

  Future<List<Favorite>> getFavorites() async {
    final db = await database;
    final maps = await db.query('favorites', orderBy: 'name ASC');
    return maps.map((map) => Favorite.fromMap(map)).toList();
  }

  Future<int> deleteFavorite(int id) async {
    final db = await database;
    return await db.delete('favorites', where: 'id = ?', whereArgs: [id]);
  }

  // --- Settings ---
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isEmpty) return null;
    return maps.first['value'] as String;
  }

  Future<Map<String, String>> getAllSettings() async {
    final db = await database;
    final maps = await db.query('settings');
    return {for (var m in maps) m['key'] as String: m['value'] as String};
  }
}
