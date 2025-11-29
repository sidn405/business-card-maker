import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/business_card.dart';

class DatabaseService {
  static Database? _database;
  static const String tableName = 'business_cards';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'business_cards.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        title TEXT,
        company TEXT,
        email TEXT,
        phone TEXT,
        website TEXT,
        address TEXT,
        notes TEXT,
        imagePath TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> initialize() async {
    await database;
  }

  Future<void> insertCard(BusinessCard card) async {
    final db = await database;
    await db.insert(
      tableName,
      card.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<BusinessCard>> getAllCards() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return BusinessCard.fromJson(maps[i]);
    });
  }

  Future<BusinessCard?> getCardById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return BusinessCard.fromJson(maps.first);
  }

  Future<void> updateCard(BusinessCard card) async {
    final db = await database;
    await db.update(
      tableName,
      card.toJson(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<void> deleteCard(String id) async {
    final db = await database;
    await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
