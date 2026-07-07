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
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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
        category TEXT DEFAULT '',
        remarks TEXT DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        mobile TEXT NOT NULL,
        photo TEXT,
        is_starred INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE merchant_favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        upi_id TEXT NOT NULL,
        category TEXT DEFAULT '',
        usage_count INTEGER DEFAULT 1,
        last_used_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE requests ADD COLUMN category TEXT DEFAULT ""');
      await db.execute('ALTER TABLE requests ADD COLUMN remarks TEXT DEFAULT ""');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS merchant_favorites (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          upi_id TEXT NOT NULL,
          category TEXT DEFAULT '',
          usage_count INTEGER DEFAULT 1,
          last_used_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE favorites ADD COLUMN is_starred INTEGER DEFAULT 0');
    }
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

  Future<int> updateFavorite(Favorite favorite) async {
    final db = await database;
    return await db.update(
      'favorites',
      favorite.toMap(),
      where: 'id = ?',
      whereArgs: [favorite.id],
    );
  }

  // --- Statistics ---
  Future<Map<String, dynamic>> getGlobalStats() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(amount) as total_amount, COUNT(*) as total_count FROM requests');
    if (result.isNotEmpty && result.first['total_amount'] != null) {
      return {
        'total_amount': (result.first['total_amount'] as num).toDouble(),
        'total_count': result.first['total_count'] as int,
      };
    }
    return {'total_amount': 0.0, 'total_count': 0};
  }

  Future<Map<String, double>> getCategoryBreakdown() async {
    final db = await database;
    final result = await db.rawQuery('SELECT category, SUM(amount) as total_amount FROM requests GROUP BY category');
    final Map<String, double> breakdown = {};
    for (var row in result) {
      final category = (row['category'] as String?)?.isNotEmpty == true ? row['category'] as String : 'Other';
      breakdown[category] = (breakdown[category] ?? 0) + (row['total_amount'] as num).toDouble();
    }
    return breakdown;
  }

  // --- Merchant Favorites ---
  Future<int> upsertMerchantFavorite(String name, String upiId, String category) async {
    final db = await database;
    final existing = await db.query(
      'merchant_favorites',
      where: 'upi_id = ?',
      whereArgs: [upiId],
    );
    if (existing.isNotEmpty) {
      final fav = existing.first;
      final count = (fav['usage_count'] as int) + 1;
      await db.update(
        'merchant_favorites',
        {
          'usage_count': count,
          'last_used_at': DateTime.now().toIso8601String(),
          'category': category,
        },
        where: 'id = ?',
        whereArgs: [fav['id']],
      );
      return fav['id'] as int;
    }
    return await db.insert('merchant_favorites', {
      'name': name,
      'upi_id': upiId,
      'category': category,
      'usage_count': 1,
      'last_used_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getMerchantFavorites() async {
    final db = await database;
    return await db.query(
      'merchant_favorites',
      orderBy: 'usage_count DESC, last_used_at DESC',
    );
  }

  Future<int> deleteMerchantFavorite(int id) async {
    final db = await database;
    return await db.delete('merchant_favorites', where: 'id = ?', whereArgs: [id]);
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
