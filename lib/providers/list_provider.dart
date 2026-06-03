import 'dart:async';

import 'package:flutter/material.dart';
import 'package:handyshopper/data/database_service.dart';
import 'package:handyshopper/models/shopping_list.dart';

/// Manages the set of lists and tracks which one is active.
///
/// Owns list creation, renaming, copying and deletion, and resolves the active
/// list (validating it against the lists that actually exist, since lists can
/// be deleted down to zero).
class ListProvider with ChangeNotifier {
  /// Creates a [ListProvider] backed by [_db] and begins loading.
  ListProvider(this._db) {
    unawaited(load());
  }

  final DatabaseService _db;

  List<ShoppingList> _lists = [];
  int? _activeListId;

  /// All lists, ordered by their manual position.
  List<ShoppingList> get lists => _lists;

  /// The id of the active list, or `null` when there are no lists.
  int? get activeListId => _activeListId;

  /// The active list, or `null` if there are no lists.
  ShoppingList? get activeList {
    for (final list in _lists) {
      if (list.id == _activeListId) {
        return list;
      }
    }
    return null;
  }

  /// Loads all lists and resolves a valid active list.
  Future<void> load() async {
    _lists = await _db.getLists();
    final stored = await _db.getActiveListId();
    await _resolveActive(stored);
    notifyListeners();
  }

  /// Ensures [_activeListId] points at an existing list, falling back to the
  /// first list (persisted) or `null` when none remain.
  Future<void> _resolveActive(int? preferred) async {
    if (_lists.isEmpty) {
      _activeListId = null;
      return;
    }
    if (_lists.any((l) => l.id == preferred)) {
      _activeListId = preferred;
      return;
    }
    _activeListId = _lists.first.id;
    await _db.setActiveListId(_activeListId!);
  }

  /// Sets [id] as the active list and persists the choice.
  Future<void> setActive(int id) async {
    if (id == _activeListId) {
      return;
    }
    await _db.setActiveListId(id);
    _activeListId = id;
    notifyListeners();
  }

  /// Creates a new list and returns its id.
  Future<int> createList(
    String name, {
    ListStyle style = ListStyle.shopping,
    bool perStorePrices = false,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await _db.insertList(
      ShoppingList(
        name: name,
        style: style,
        perStorePrices: perStorePrices,
        sortOrder: _lists.length,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await load();
    return id;
  }

  /// Renames the list with [id].
  Future<void> renameList(int id, String name) async {
    final list = _lists.firstWhere((l) => l.id == id)
      ..name = name
      ..updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _db.updateList(list);
    await load();
  }

  /// Updates the editable settings of the list with [id].
  ///
  /// Turning [perStorePrices] off only hides the per-store UI; existing
  /// `item_store_prices` rows are preserved (non-destructive) so re-enabling
  /// the option restores them.
  Future<void> updateListSettings(
    int id, {
    required String name,
    required bool perStorePrices,
  }) async {
    final list = _lists.firstWhere((l) => l.id == id)
      ..name = name
      ..perStorePrices = perStorePrices
      ..updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _db.updateList(list);
    await load();
  }

  /// Sets the emoji [icon] of the list with [id] (`null` clears it).
  Future<void> setIcon(int id, String? icon) async {
    final list = _lists.firstWhere((l) => l.id == id)
      ..icon = icon
      ..updatedAt = DateTime.now().millisecondsSinceEpoch;
    await _db.updateList(list);
    await load();
  }

  /// Deletes the list with [id] (and all its contents).
  Future<void> deleteList(int id) async {
    await _db.deleteList(id);
    await load();
  }

  /// Duplicates the list with [id] as `<name> (copy)` and returns the new id.
  Future<int> copyList(int id) async {
    final source = _lists.firstWhere((l) => l.id == id);
    final newId = await _db.copyList(id, '${source.name} (copy)');
    await load();
    return newId;
  }
}
