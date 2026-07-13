import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/category.dart';
import '../models/receipt.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'receipt_app.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE receipts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            imagePath TEXT NOT NULL,
            categoryId INTEGER NOT NULL,
            date TEXT NOT NULL,
            amount REAL NOT NULL,
            notes TEXT DEFAULT ''
          )
        ''');

        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE
          )
        ''');

        // Seed default categories
        final categories = ['Groceries', 'Dining', 'Utilities', 'Transport', 'Other'];
        for (final name in categories) {
          await db.insert('categories', {'name': name}, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      },
    );
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'name ASC');
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return db.insert('categories', category.toMap());
  }

  Future<List<Receipt>> getReceipts({String? search, int? categoryId}) async {
    final db = await database;

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (search != null && search.isNotEmpty) {
      whereClauses.add('title LIKE ?');
      whereArgs.add('%$search%');
    }

    if (categoryId != null) {
      whereClauses.add('categoryId = ?');
      whereArgs.add(categoryId);
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final maps = await db.query(
      'receipts',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC',
    );

    return maps.map((map) => Receipt.fromMap(map)).toList();
  }

  Future<Receipt?> getReceipt(int id) async {
    final db = await database;
    final maps = await db.query('receipts', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Receipt.fromMap(maps.first);
  }

  Future<int> insertReceipt(Receipt receipt) async {
    final db = await database;
    return db.insert('receipts', receipt.toMap());
  }

  Future<int> updateReceipt(Receipt receipt) async {
    final db = await database;
    return db.update(
      'receipts',
      receipt.toMap(),
      where: 'id = ?',
      whereArgs: [receipt.id],
    );
  }

  Future<int> deleteReceipt(int id) async {
    final db = await database;
    return db.delete('receipts', where: 'id = ?', whereArgs: [id]);
  }
}
