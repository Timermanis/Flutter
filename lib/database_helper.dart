import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
//import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    // Incremented database filename to force table upgrades automatically
    _database = await _initDB('supplements_stack_v5.db'); 
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // --- ADD THIS METHOD INSIDE YOUR DATABASEHELPER CLASS IN lib/database_helper.dart ---

Future<List<Map<String, dynamic>>> fetchAllCommentsWithSupplements() async {
  final db = await instance.database;
  
  // Uses a INNER JOIN to tie comment text rows directly to the supplement's text name
  return await db.rawQuery('''
    SELECT 
      comments.id AS comment_id,
      comments.comment_text,
      comments.date_added,
      supplements.supplement AS supplement_name,
      supplements.brand AS supplement_brand
    FROM comments
    INNER JOIN supplements ON comments.supplement_id = supplements.id
    ORDER BY comments.id DESC -- Newest global notes first
  ''');
}


  Future _createDB(Database db, int version) async {
    // Main supplements table
    await db.execute('''
      CREATE TABLE supplements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplement TEXT,
        dosage TEXT,
        times_per_day INTEGER,
        start_date TEXT,
        brand TEXT,
        is_active INTEGER DEFAULT 1
      )
    ''');

    // --- NEW COMMENTS TABLE ---
    await db.execute('''
      CREATE TABLE comments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplement_id INTEGER,
        comment_text TEXT,
        date_added TEXT,
        FOREIGN KEY (supplement_id) REFERENCES supplements (id) ON DELETE CASCADE
      )
    ''');

    // Seed mock configurations
    int d3Id = await db.insert('supplements', {
      'supplement': 'Vitamin D3',
      'dosage': '5000 IU',
      'times_per_day': 1,
      'start_date': '2026-01-10',
      'brand': 'Nordic Naturals',
      'is_active': 1
    });

    // Seed initial sample comment
    await db.insert('comments', {
      'supplement_id': d3Id,
      'comment_text': 'Take with a meal containing healthy fats for better absorption.',
      'date_added': '2026-10-24'
    });
  }

  Future<List<Map<String, dynamic>>> fetchActiveSupplements() async {
    final db = await instance.database;
    return await db.rawQuery('SELECT * FROM supplements WHERE is_active = 1 ORDER BY id DESC');
  }

  Future<List<Map<String, dynamic>>> fetchAllSupplements() async {
    final db = await instance.database;
    return await db.rawQuery('SELECT * FROM supplements ORDER BY is_active DESC, id DESC');
  }

  Future<int> insertSupplement(Map<String, dynamic> row) async {
    final db = await instance.database;
    final Map<String, dynamic> completeRow = Map.from(row)..putIfAbsent('is_active', () => 1);
    return await db.insert('supplements', completeRow);
  }

  Future<int> updateSuspensionStatus(int id, bool suspend) async {
    final db = await instance.database;
    return await db.update(
      'supplements',
      {'is_active': suspend ? 0 : 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- NEW COMMENTS METHODS ---
  Future<int> insertComment(int supplementId, String commentText) async {
    final db = await instance.database;
    return await db.insert('comments', {
      'supplement_id': supplementId,
      'comment_text': commentText,
      'date_added': DateTime.now().toString().split(' ')[0], // YYYY-MM-DD
    });
  }

  Future<List<Map<String, dynamic>>> fetchCommentsForSupplement(int supplementId) async {
    final db = await instance.database;
    return await db.query(
      'comments',
      where: 'supplement_id = ?',
      whereArgs: [supplementId],
      orderBy: 'id DESC', // Newest comments first
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) await db.close();
  }
}
