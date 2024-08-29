import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    // Get the directory to store the database
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String dbPath = join(documentsDirectory.path, 'games_database.db');

    // Check if the database already exists
    
    if (FileSystemEntity.typeSync(dbPath) == FileSystemEntityType.notFound) {
    // Load the database from assets and write to the local file
    ByteData data = await rootBundle.load('assets/databases/games_database.db');
    List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await File(dbPath).writeAsBytes(bytes, flush: true);
    print('Database copied, will open now');
  } else {
    print('Database already exists, opening now');
  }

    // Open the database
    return await openDatabase(dbPath);
  }

  //CRUD operators

  Future<int> insertGame(Map<String, dynamic> game) async {
    Database db = await database;
    return await db.insert('games', game);
  }

  Future<List<Map<String, dynamic>>> getGames() async {
    Database db = await database;
    return await db.query('games');
  }
  Future<int> updateGame(Map<String, dynamic> game) async {
    Database db = await database;
    int id = game['id'];
    return await db.update('games', game, where: 'id = ?', whereArgs: [id]);
  }
  Future<int> deleteGame(int id) async {
    Database db = await database;
    return await db.delete('games', where: 'id = ?', whereArgs: [id]);
  }
}
