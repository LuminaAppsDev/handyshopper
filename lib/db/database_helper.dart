import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';

class DatabaseHelper {
  // Singleton pattern to ensure a single instance of DatabaseHelper
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // Table and column names
  final String tableName = 'products';
  final String columnId = 'id';
  final String columnName = 'name';
  final String columnQuantity = 'quantity';
  final String columnPrice = 'price';
  final String columnNeed = 'need';

  // Getter to initialize the database if not already done
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    // Get the database path
    String path = join(await getDatabasesPath(), 'handyshopper.db');
    // Open the database, creating it if it doesn't exist
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Create the products table
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnName TEXT NOT NULL,
        $columnQuantity REAL NOT NULL,
        $columnPrice REAL,
        $columnNeed INTEGER NOT NULL
      )
    ''');
  }

  // Upgrade the database schema
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE products RENAME TO old_products');
      await db.execute('''
        CREATE TABLE products (
          $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
          $columnName TEXT NOT NULL,
          $columnQuantity REAL NOT NULL,
          $columnPrice REAL,
          $columnNeed INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        INSERT INTO products ($columnId, $columnName, $columnQuantity, $columnPrice, $columnNeed)
        SELECT $columnId, $columnName, CAST($columnQuantity AS REAL), $columnPrice, $columnNeed FROM old_products
      ''');
      await db.execute('DROP TABLE old_products');
    }
  }

  // Insert a new product into the database
  Future<int> insertProduct(Product product) async {
    Database db = await database;
    return await db.insert(tableName, product.toMap());
  }

  // Retrieve all products from the database
  Future<List<Product>> getProducts() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(tableName);
    if (maps.isEmpty) return [];
    return List.generate(maps.length, (i) {
      return Product.fromMap(maps[i]);
    });
  }

  // Update an existing product in the database
  Future<int> updateProduct(Product product) async {
    Database db = await database;
    return await db.update(
      tableName,
      product.toMap(),
      where: '$columnId = ?',
      whereArgs: [product.id],
    );
  }

  // Delete a product from the database
  Future<int> deleteProduct(int id) async {
    Database db = await database;
    return await db.delete(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
}
