import 'dart:async';

import 'package:flutter/material.dart';
import 'package:handyshopper/models/product.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// The available sort options for the product list.
enum SortOption {
  /// Sort alphabetically by name.
  alphabetical,

  /// Sort by quantity.
  quantity,

  /// Sort by price.
  price,

  /// Manual user-defined order.
  manual,
}

/// Manages the product list state and database persistence.
class ProductProvider with ChangeNotifier {
  /// Creates a [ProductProvider] and loads products from the database.
  ProductProvider() {
    unawaited(fetchProducts());
  }

  List<Product> _products = [];
  late Database _db;

  /// The current list of products.
  List<Product> get products => _products;

  /// Loads all products from the database.
  Future<void> fetchProducts() async {
    _db = await _initDb();
    final List<Map<String, dynamic>> maps = await _db.query('products');

    _products = List.generate(maps.length, (i) {
      return Product(
        id: maps[i]['id'] as int?,
        name: maps[i]['name'] as String,
        quantity: (maps[i]['quantity'] as num).toDouble(),
        price: (maps[i]['price'] as num?)?.toDouble(),
        need: maps[i]['need'] == 1,
      );
    });

    final prefs = await SharedPreferences.getInstance();
    final sortOption = prefs.getString('sortOption') ?? 'manual';
    if (sortOption == 'manual') {
      final order = prefs.getStringList('manualOrder') ?? [];
      if (order.isNotEmpty) {
        _products.sort(
          (a, b) => order
              .indexOf(a.id.toString())
              .compareTo(order.indexOf(b.id.toString())),
        );
      }
    } else {
      await sortProducts(
        SortOption.values
            .firstWhere((e) => e.toString() == 'SortOption.$sortOption'),
      );
    }

    notifyListeners();
  }

  Future<Database> _initDb() async {
    return openDatabase(
      join(await getDatabasesPath(), 'product_database.db'),
      version: 2,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE products(id INTEGER PRIMARY KEY, name TEXT, '
          'quantity REAL, price REAL, need INTEGER)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE products RENAME TO old_products');
          await db.execute(
            'CREATE TABLE products(id INTEGER PRIMARY KEY, name TEXT, '
            'quantity REAL, price REAL, need INTEGER)',
          );
          await db.execute(
            'INSERT INTO products (id, name, quantity, price, need) '
            'SELECT id, name, CAST(quantity AS REAL), price, need '
            'FROM old_products',
          );
          await db.execute('DROP TABLE old_products');
        }
      },
    );
  }

  /// Adds a new product to the list and database.
  Future<void> addProduct(Product product) async {
    await _db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await fetchProducts();
  }

  /// Updates an existing product in the list and database.
  Future<void> updateProduct(Product product) async {
    await _db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
    // Reload the list of products
    await fetchProducts();
  }

  /// Deletes a product from the list and database.
  Future<void> deleteProduct(int id) async {
    await _db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    // Reload the list of products
    await fetchProducts();
  }

  /// Sorts products by the given [option].
  Future<void> sortProducts(SortOption option) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sortOption', option.toString().split('.').last);

    switch (option) {
      case SortOption.alphabetical:
        _products.sort((a, b) => a.name.compareTo(b.name));
      case SortOption.quantity:
        _products.sort((a, b) => a.quantity.compareTo(b.quantity));
      case SortOption.price:
        _products.sort((a, b) => a.price?.compareTo(b.price ?? 0) ?? 0);
      case SortOption.manual:
        final order = prefs.getStringList('manualOrder') ?? [];
        if (order.isNotEmpty) {
          _products.sort(
            (a, b) => order
                .indexOf(a.id.toString())
                .compareTo(order.indexOf(b.id.toString())),
          );
        }
    }
    notifyListeners();
  }

  /// Updates the product order and optionally sets sort mode to manual.
  Future<void> updateProductOrder(
    List<Product> sortedProducts, {
    bool setManual = false,
  }) async {
    _products = sortedProducts;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'manualOrder',
      _products.map((p) => p.id.toString()).toList(),
    );

    if (setManual) {
      await prefs.setString(
        'sortOption',
        SortOption.manual.toString().split('.').last,
      );
    }

    notifyListeners();
  }

  /// Returns the total price of all needed products.
  double getTotalPrice() {
    return _products.where((product) => product.need).fold<double>(
          0,
          (total, product) => total + (product.price ?? 0) * product.quantity,
        );
  }
}
