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
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _onUpgrade,
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
        updatedAt TEXT NOT NULL,
        template TEXT NOT NULL,
        colorTheme TEXT,
        logoPath TEXT
      )
    ''');
  }

  // ADD THIS METHOD FOR MIGRATION
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns for version 2
      await db.execute('ALTER TABLE business_cards ADD COLUMN template TEXT');
      await db.execute('ALTER TABLE business_cards ADD COLUMN colorTheme TEXT');
      await db.execute('ALTER TABLE business_cards ADD COLUMN logoPath TEXT');
      print('✅ Database upgraded to version 2: Added template, colorTheme, logoPath columns');
    }
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
