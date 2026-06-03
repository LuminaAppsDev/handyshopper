import 'dart:async';

import 'package:flutter/material.dart';
import 'package:handyshopper/data/database_service.dart';
import 'package:handyshopper/models/category.dart';

/// Manages the categories of the active list.
///
/// Scoped to the active list and wired via `ChangeNotifierProxyProvider` like
/// `ItemProvider`, so changing the active list re-scopes its categories.
class CategoryProvider with ChangeNotifier {
  /// Creates a [CategoryProvider] backed by [_db].
  CategoryProvider(this._db);

  final DatabaseService _db;

  List<Category> _categories = [];
  int? _listId;

  /// The categories of the active list, ordered by manual position.
  List<Category> get categories => _categories;

  /// Points this provider at the list with [listId] and reloads its categories.
  ///
  /// A no-op when [listId] is already active.
  void setActiveList(int? listId) {
    if (listId == _listId) {
      return;
    }
    _listId = listId;
    unawaited(fetchCategories());
  }

  /// Loads the active list's categories.
  Future<void> fetchCategories() async {
    final listId = _listId;
    if (listId == null) {
      _categories = [];
      notifyListeners();
      return;
    }
    _categories = await _db.getCategories(listId);
    notifyListeners();
  }

  /// Adds a category named [name] with an optional [icon].
  Future<void> addCategory(String name, {String? icon}) async {
    final listId = _listId;
    if (listId == null) {
      return;
    }
    await _db.insertCategory(
      Category(
        listId: listId,
        name: name,
        icon: icon,
        sortOrder: _categories.length,
      ),
    );
    await fetchCategories();
  }

  /// Renames the category with [id].
  Future<void> renameCategory(int id, String name) async {
    final category = _categories.firstWhere((c) => c.id == id)..name = name;
    await _db.updateCategory(category);
    await fetchCategories();
  }

  /// Sets the [icon] of the category with [id].
  Future<void> setIcon(int id, String? icon) async {
    final category = _categories.firstWhere((c) => c.id == id)..icon = icon;
    await _db.updateCategory(category);
    await fetchCategories();
  }

  /// Deletes the category with [id].
  Future<void> deleteCategory(int id) async {
    await _db.deleteCategory(id);
    await fetchCategories();
  }
}
