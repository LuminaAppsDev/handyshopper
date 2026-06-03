import 'dart:async';

import 'package:flutter/material.dart';
import 'package:handyshopper/data/database_service.dart';
import 'package:handyshopper/models/store.dart';

/// Manages the stores of the active list.
///
/// Scoped to the active list and wired via `ChangeNotifierProxyProvider` like
/// `CategoryProvider`, so changing the active list re-scopes its stores.
class StoreProvider with ChangeNotifier {
  /// Creates a [StoreProvider] backed by [_db].
  StoreProvider(this._db);

  final DatabaseService _db;

  List<Store> _stores = [];
  int? _listId;

  /// The stores of the active list, ordered by manual position.
  List<Store> get stores => _stores;

  /// Points this provider at the list with [listId] and reloads its stores.
  ///
  /// A no-op when [listId] is already active.
  void setActiveList(int? listId) {
    if (listId == _listId) {
      return;
    }
    _listId = listId;
    unawaited(fetchStores());
  }

  /// Loads the active list's stores.
  Future<void> fetchStores() async {
    final listId = _listId;
    if (listId == null) {
      _stores = [];
      notifyListeners();
      return;
    }
    _stores = await _db.getStores(listId);
    notifyListeners();
  }

  /// Adds a store named [name].
  Future<void> addStore(String name) async {
    final listId = _listId;
    if (listId == null) {
      return;
    }
    await _db.insertStore(
      Store(listId: listId, name: name, sortOrder: _stores.length),
    );
    await fetchStores();
  }

  /// Renames the store with [id].
  Future<void> renameStore(int id, String name) async {
    final store = _stores.firstWhere((s) => s.id == id)..name = name;
    await _db.updateStore(store);
    await fetchStores();
  }

  /// Deletes the store with [id].
  Future<void> deleteStore(int id) async {
    await _db.deleteStore(id);
    await fetchStores();
  }
}
