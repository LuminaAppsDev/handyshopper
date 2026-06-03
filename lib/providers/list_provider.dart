import 'dart:async';

import 'package:flutter/material.dart';
import 'package:handyshopper/data/database_service.dart';
import 'package:handyshopper/models/shopping_list.dart';

/// Manages the set of lists and tracks which one is active.
///
/// In Phase 0 there is exactly one (default) list, but this provider is the
/// mechanism by which later phases will scope items to the selected list.
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

  /// The id of the active list, or `null` before loading completes.
  int? get activeListId => _activeListId;

  /// The active list, or `null` if not yet loaded.
  ShoppingList? get activeList {
    for (final list in _lists) {
      if (list.id == _activeListId) {
        return list;
      }
    }
    return null;
  }

  /// Loads all lists and resolves the active list id (seeding a default list
  /// if the database is empty).
  Future<void> load() async {
    _activeListId = await _db.getActiveListId();
    _lists = await _db.getLists();
    notifyListeners();
  }
}
