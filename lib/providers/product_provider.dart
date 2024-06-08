import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

enum SortOption { alphabetical, quantity, price, manual }

class ProductProvider with ChangeNotifier {
  // List to hold all products
  List<Product> _products = [];
  late Database _db;

  // Getter to retrieve the list of products
  List<Product> get products => _products;

  ProductProvider() {
    fetchProducts();
  }

  // Method to load all products from the database
  Future<void> fetchProducts() async {
    _db = await _initDb();
    // Retrieve products from the database
    final List<Map<String, dynamic>> maps = await _db.query('products');

    _products = List.generate(maps.length, (i) {
      return Product(
        id: maps[i]['id'],
        name: maps[i]['name'],
        quantity: maps[i]['quantity'],
        price: maps[i]['price'],
        need: maps[i]['need'] == 1,
      );
    });

    final prefs = await SharedPreferences.getInstance();
    final sortOption = prefs.getString('sortOption') ?? 'manual';
    if (sortOption == 'manual') {
      final order = prefs.getStringList('manualOrder') ?? [];
      if (order.isNotEmpty) {
        _products.sort((a, b) => order.indexOf(a.id.toString()).compareTo(order.indexOf(b.id.toString())));
      }
    } else {
      sortProducts(SortOption.values.firstWhere((e) => e.toString() == 'SortOption.$sortOption'));
    }

    // Notify listeners about the change
    notifyListeners();
  }

  Future<Database> _initDb() async {
    return openDatabase(
      join(await getDatabasesPath(), 'product_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE products(id INTEGER PRIMARY KEY, name TEXT, quantity INTEGER, price REAL, need INTEGER)',
        );
      },
      version: 1,
    );
  }

  // Method to add a new product to the list and database
  Future<void> addProduct(Product product) async {
    // Insert the product into the database
    await _db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // Reload the list of products
    fetchProducts();
  }

  // Method to update an existing product in the list and database
  Future<void> updateProduct(Product product) async {
    // Update the product in the database
    await _db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
    // Reload the list of products
    fetchProducts();
  }

  // Method to delete a product from the list and database
  Future<void> deleteProduct(int id) async {
    // Delete the product from the database
    await _db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    // Reload the list of products
    fetchProducts();
  }

  // Method to sort products by name
  void sortProducts(SortOption option) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('sortOption', option.toString().split('.').last);

    switch (option) {
      case SortOption.alphabetical:
      // Method to sort products by name
        _products.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.quantity:
        // Method to sort products by quantity
        _products.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case SortOption.price:
        // Method to sort products by price
        _products.sort((a, b) => a.price?.compareTo(b.price ?? 0) ?? 0);
        break;
      case SortOption.manual:
      // Method to manually reorder products and save the order persistently
        final order = prefs.getStringList('manualOrder') ?? [];
        if (order.isNotEmpty) {
          _products.sort((a, b) => order.indexOf(a.id.toString()).compareTo(order.indexOf(b.id.toString())));
        }
        break;
    }
    notifyListeners();
  }

  Future<void> updateProductOrder(List<Product> sortedProducts, {bool setManual = false}) async {
    _products = sortedProducts;
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('manualOrder', _products.map((p) => p.id.toString()).toList());

    if (setManual) {
      prefs.setString('sortOption', SortOption.manual.toString().split('.').last);
    }
    
    notifyListeners();
  }
}
