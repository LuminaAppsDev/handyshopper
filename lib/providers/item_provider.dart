import 'dart:async';

import 'package:flutter/material.dart';
import 'package:handyshopper/data/database_service.dart';
import 'package:handyshopper/models/item.dart';
import 'package:handyshopper/models/item_store_price.dart';
import 'package:handyshopper/models/shopping_list.dart';

/// The available sort options for the item list.
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

/// Manages the items of the active list and their persistence.
///
/// Replaces the former `ProductProvider`. Sort configuration now lives on the
/// list row (`sort_primary`) and manual order in `items.sort_order`, rather
/// than in SharedPreferences.
class ItemProvider with ChangeNotifier {
  /// Creates an [ItemProvider] backed by [_db].
  ItemProvider(this._db);

  final DatabaseService _db;

  List<Item> _items = [];
  int? _listId;
  String _sortPrimary = SortOption.manual.name;

  /// Per-store prices for the active list, keyed by itemId then storeId.
  Map<int, Map<int, ItemStorePrice>> _storePrices = {};

  /// The current items of the active list.
  List<Item> get items => _items;

  /// The id of the active list, or `null` before one is assigned.
  int? get activeListId => _listId;

  /// The persisted primary sort key of the active list.
  String get sortPrimary => _sortPrimary;

  /// Points this provider at [list] and reloads its items.
  ///
  /// A no-op when [list] is the already-active list, which prevents the
  /// proxy-provider wiring from triggering refetch loops. Only the list's id
  /// and sort key are copied — the provider never mutates the shared object.
  void setActiveList(ShoppingList? list) {
    if (list?.id == _listId) {
      return;
    }
    _listId = list?.id;
    _sortPrimary = list?.sortPrimary ?? SortOption.manual.name;
    unawaited(fetchItems());
  }

  /// Loads the active list's items, per-store prices, and applies the sort.
  Future<void> fetchItems() async {
    final listId = _listId;
    if (listId == null) {
      _items = [];
      _storePrices = {};
      notifyListeners();
      return;
    }
    _items = await _db.getItems(listId);
    final prices = await _db.getItemStorePricesForList(listId);
    _storePrices = {};
    for (final price in prices) {
      (_storePrices[price.itemId] ??= {})[price.storeId] = price;
    }
    _applySort(_sortOptionOf(_sortPrimary));
    notifyListeners();
  }

  /// Adds [item] to the active list and returns its new id.
  Future<int> addItem(Item item) async {
    final id = await _db.insertItem(item);
    await fetchItems();
    return id;
  }

  /// Updates [item].
  Future<void> updateItem(Item item) async {
    await _db.updateItem(item);
    await fetchItems();
  }

  /// Deletes the item with [id].
  Future<void> deleteItem(int id) async {
    await _db.deleteItem(id);
    await fetchItems();
  }

  /// Sorts the items by [option] and persists the choice on the list row.
  Future<void> sortItems(SortOption option) async {
    final listId = _listId;
    if (listId == null) {
      return;
    }
    _sortPrimary = option.name;
    await _db.updateListSort(listId, _sortPrimary);
    _applySort(option);
    notifyListeners();
  }

  /// Persists a new manual order, optionally switching the list to manual sort.
  Future<void> updateItemOrder(
    List<Item> orderedItems, {
    bool setManual = false,
  }) async {
    _items = orderedItems;
    final listId = _listId;
    if (listId != null) {
      await _db.reorderItems(
        listId,
        orderedItems.map((i) => i.id!).toList(),
      );
      if (setManual) {
        _sortPrimary = SortOption.manual.name;
        await _db.updateListSort(listId, _sortPrimary);
      }
    }
    notifyListeners();
  }

  /// The effective price of [item] at [storeId]: the store-specific price when
  /// one is recorded, otherwise the item's base price. `null` [storeId] always
  /// yields the base price.
  double? priceFor(Item item, int? storeId) {
    if (storeId == null || item.id == null) {
      return item.price;
    }
    return _storePrices[item.id]?[storeId]?.price ?? item.price;
  }

  /// The per-store prices recorded for [item] (storeId → row).
  Map<int, ItemStorePrice> storePricesFor(Item item) {
    return _storePrices[item.id] ?? const {};
  }

  /// Returns the total of all needed items (effective price × quantity),
  /// evaluated at [storeId] (base price when null).
  double getTotalPrice({int? storeId}) {
    return _items.where((item) => item.need).fold<double>(
          0,
          (total, item) =>
              total + (priceFor(item, storeId) ?? 0) * item.quantity,
        );
  }

  void _applySort(SortOption option) {
    switch (option) {
      case SortOption.alphabetical:
        _items.sort((a, b) => a.name.compareTo(b.name));
      case SortOption.quantity:
        _items.sort((a, b) => a.quantity.compareTo(b.quantity));
      case SortOption.price:
        // Sorts by the base price; a selected store's per-store price is
        // intentionally not considered here.
        _items.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
      case SortOption.manual:
        // Items already arrive ordered by sort_order from the database.
        break;
    }
  }

  SortOption _sortOptionOf(String key) {
    return SortOption.values.firstWhere(
      (o) => o.name == key,
      orElse: () => SortOption.manual,
    );
  }
}
