import 'package:handyshopper/models/category.dart';
import 'package:handyshopper/models/item.dart';
import 'package:handyshopper/models/item_store_price.dart';
import 'package:handyshopper/models/shopping_list.dart';
import 'package:handyshopper/models/store.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Owns the single SQLite connection and exposes typed CRUD operations.
///
/// Persistence is deliberately separated from app state (the providers) so the
/// schema, migration, and queries can be unit-tested off-device by injecting a
/// [DatabaseFactory] (e.g. `databaseFactoryFfi`).
class DatabaseService {
  /// Creates a [DatabaseService].
  ///
  /// In production no arguments are needed. Tests may pass [factory] (such as
  /// `databaseFactoryFfi`) and an in-memory or temporary [path].
  DatabaseService({DatabaseFactory? factory, String? path})
      : _factory = factory,
        _path = path;

  /// The current schema version.
  static const int schemaVersion = 3;

  /// The on-disk database file name (unchanged from v1 to preserve user data).
  static const String dbFileName = 'product_database.db';

  /// `app_meta` key holding the active list id.
  static const String metaActiveListId = 'active_list_id';

  /// `app_meta` key holding the schema version.
  static const String metaSchemaVersion = 'schema_version';

  final DatabaseFactory? _factory;
  final String? _path;
  Database? _db;
  Future<Database>? _opening;

  /// Returns the open database, opening it on first access.
  ///
  /// Concurrent first-access calls share a single [_open] future so the
  /// database is never opened twice.
  Future<Database> get database async {
    final existing = _db;
    if (existing != null) {
      return existing;
    }
    final opening = _opening ??= _open();
    try {
      return _db = await opening;
    } catch (_) {
      _opening = null; // allow a later retry
      rethrow;
    }
  }

  Future<Database> _open() async {
    final factory = _factory ?? databaseFactory;
    final path = _path ?? join(await factory.getDatabasesPath(), dbFileName);
    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  /// Closes the database. Mainly used by tests.
  Future<void> close() async {
    await _db?.close();
    _db = null;
    _opening = null;
  }

  // --- Schema -------------------------------------------------------------

  Future<void> _onConfigure(Database db) async {
    // sqflite disables foreign keys by default; without this every ON DELETE
    // clause silently no-ops.
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createSchema(Database db) async {
    final batch = db.batch()
      ..execute('''
        CREATE TABLE app_meta(
          key TEXT PRIMARY KEY,
          value TEXT)''')
      ..execute('''
        CREATE TABLE lists(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          icon TEXT,
          style INTEGER NOT NULL DEFAULT 0,
          per_store_prices INTEGER NOT NULL DEFAULT 0,
          currency_symbol TEXT,
          tax_rate REAL NOT NULL DEFAULT 0,
          tax2_rate REAL NOT NULL DEFAULT 0,
          tax2_enabled INTEGER NOT NULL DEFAULT 0,
          default_priority INTEGER NOT NULL DEFAULT 3,
          sort_primary TEXT NOT NULL DEFAULT 'manual',
          sort_secondary TEXT,
          sort_descending INTEGER NOT NULL DEFAULT 0,
          learn_order INTEGER NOT NULL DEFAULT 0,
          column_flags INTEGER NOT NULL DEFAULT 0,
          sort_order INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER,
          updated_at INTEGER)''')
      ..execute('''
        CREATE TABLE categories(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          list_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          icon TEXT,
          sort_order INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(list_id) REFERENCES lists(id) ON DELETE CASCADE)''')
      ..execute('''
        CREATE TABLE stores(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          list_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          sort_order INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(list_id) REFERENCES lists(id) ON DELETE CASCADE)''')
      ..execute('''
        CREATE TABLE items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          list_id INTEGER NOT NULL,
          category_id INTEGER,
          name TEXT NOT NULL,
          quantity REAL NOT NULL DEFAULT 1,
          unit TEXT,
          price REAL,
          need INTEGER NOT NULL DEFAULT 1,
          completed INTEGER NOT NULL DEFAULT 0,
          note TEXT,
          taxable INTEGER NOT NULL DEFAULT 0,
          coupon INTEGER NOT NULL DEFAULT 0,
          priority INTEGER NOT NULL DEFAULT 3,
          aisle TEXT,
          item_date INTEGER,
          auto_delete INTEGER NOT NULL DEFAULT 0,
          private INTEGER NOT NULL DEFAULT 0,
          custom_text TEXT,
          alarm_at INTEGER,
          alarm_sound TEXT,
          sort_order INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER,
          updated_at INTEGER,
          FOREIGN KEY(list_id) REFERENCES lists(id) ON DELETE CASCADE,
          FOREIGN KEY(category_id) REFERENCES categories(id)
            ON DELETE SET NULL)''')
      ..execute('''
        CREATE TABLE item_store_prices(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          item_id INTEGER NOT NULL,
          store_id INTEGER NOT NULL,
          price REAL,
          aisle TEXT,
          UNIQUE(item_id, store_id),
          FOREIGN KEY(item_id) REFERENCES items(id) ON DELETE CASCADE,
          FOREIGN KEY(store_id) REFERENCES stores(id) ON DELETE CASCADE)''')
      ..execute('CREATE INDEX idx_categories_list ON categories(list_id)')
      ..execute('CREATE INDEX idx_stores_list ON stores(list_id)')
      ..execute('CREATE INDEX idx_items_list ON items(list_id)')
      ..execute('CREATE INDEX idx_items_list_need ON items(list_id, need)')
      ..execute('CREATE INDEX idx_items_category ON items(category_id)')
      ..execute('CREATE INDEX idx_isp_item ON item_store_prices(item_id)')
      ..execute('CREATE INDEX idx_isp_store ON item_store_prices(store_id)');
    await batch.commit(noResult: true);
  }

  Future<int> _seedDefaultList(DatabaseExecutor db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final listId = await db.insert(
      'lists',
      ShoppingList(name: 'Shopping', createdAt: now, updatedAt: now).toMap()
        ..remove('id'),
    );
    await db.insert('app_meta', {
      'key': metaActiveListId,
      'value': listId.toString(),
    });
    await db.insert('app_meta', {
      'key': metaSchemaVersion,
      'value': schemaVersion.toString(),
    });
    return listId;
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createSchema(db);
    await _seedDefaultList(db);
  }

  // --- Migration ----------------------------------------------------------

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Legacy v1 -> v2: quantity INTEGER -> REAL via table rebuild.
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
    if (oldVersion < 3) {
      await _migrateV2ToV3(db);
    }
  }

  /// Migrates the flat `products` table into the relational schema, preserving
  /// every row (and its id) inside a freshly created default list.
  Future<void> _migrateV2ToV3(Database db) async {
    await _createSchema(db);
    final listId = await _seedDefaultList(db);

    final legacy = await db.query('products');
    final order = await _legacyManualOrder();
    final sortedLegacy = _applyLegacyOrder(legacy, order);

    final now = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < sortedLegacy.length; i++) {
      final row = sortedLegacy[i];
      await db.insert('items', {
        'id': row['id'],
        'list_id': listId,
        'name': row['name'],
        'quantity': (row['quantity'] as num?)?.toDouble() ?? 1,
        'price': row['price'],
        'need': row['need'] ?? 1,
        'completed': 0,
        'priority': 3,
        'sort_order': i,
        'created_at': now,
        'updated_at': now,
      });
    }

    await db.execute('DROP TABLE products');
  }

  /// Reads the legacy manual order persisted in SharedPreferences, or an empty
  /// list when sort was not manual / no order was stored.
  ///
  /// Any failure degrades to an empty order rather than aborting the migration:
  /// items then fall back to their existing display order.
  Future<List<String>> _legacyManualOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sortOption = prefs.getString('sortOption') ?? 'manual';
      if (sortOption != 'manual') {
        return const [];
      }
      return prefs.getStringList('manualOrder') ?? const [];
    } on Object {
      return const [];
    }
  }

  /// Orders [rows] by the legacy [manualOrder] of stringified ids. Rows whose
  /// id is absent from [manualOrder] keep their original relative order and are
  /// appended after the ordered ones.
  List<Map<String, dynamic>> _applyLegacyOrder(
    List<Map<String, dynamic>> rows,
    List<String> manualOrder,
  ) {
    if (manualOrder.isEmpty) {
      return List<Map<String, dynamic>>.from(rows);
    }
    final indexed = List<Map<String, dynamic>>.from(rows);
    int rank(Map<String, dynamic> row) {
      final pos = manualOrder.indexOf(row['id'].toString());
      return pos == -1 ? manualOrder.length : pos;
    }

    indexed.sort((a, b) => rank(a).compareTo(rank(b)));
    return indexed;
  }

  // --- Lists --------------------------------------------------------------

  /// Returns all lists ordered by their manual position.
  Future<List<ShoppingList>> getLists() async {
    final db = await database;
    final rows = await db.query('lists', orderBy: 'sort_order, id');
    return rows.map(ShoppingList.fromMap).toList();
  }

  /// Inserts [list] and returns its new id.
  Future<int> insertList(ShoppingList list) async {
    final db = await database;
    return db.insert('lists', list.toMap()..remove('id'));
  }

  /// Updates [list]'s persisted columns.
  Future<void> updateList(ShoppingList list) async {
    final db = await database;
    await db.update(
      'lists',
      list.toMap(),
      where: 'id = ?',
      whereArgs: [list.id],
    );
  }

  /// Persists just the sort field of the list with [listId].
  ///
  /// Used by `ItemProvider` so it never has to mutate a shared list object.
  Future<void> updateListSort(int listId, String sortPrimary) async {
    final db = await database;
    await db.update(
      'lists',
      {
        'sort_primary': sortPrimary,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [listId],
    );
  }

  /// Deletes the list with [id]. Foreign-key cascade removes its categories,
  /// stores, items and per-store prices.
  Future<void> deleteList(int id) async {
    final db = await database;
    await db.delete('lists', where: 'id = ?', whereArgs: [id]);
  }

  /// Deep-copies the list with [id] under [newName], duplicating its
  /// categories, stores, items and per-store prices with fresh ids. Returns
  /// the new list id.
  Future<int> copyList(int id, String newName) async {
    final db = await database;
    return db.transaction((txn) async {
      final listRows = await txn.query(
        'lists',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (listRows.isEmpty) {
        throw ArgumentError('No list with id $id');
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      final listMap = Map<String, dynamic>.of(listRows.first)
        ..remove('id')
        ..['name'] = newName
        ..['created_at'] = now
        ..['updated_at'] = now;
      final newListId = await txn.insert('lists', listMap);

      final categoryIdMap = <int, int>{};
      for (final row in await txn.query(
        'categories',
        where: 'list_id = ?',
        whereArgs: [id],
      )) {
        final map = Map<String, dynamic>.of(row)
          ..remove('id')
          ..['list_id'] = newListId;
        categoryIdMap[row['id']! as int] = await txn.insert('categories', map);
      }

      final storeIdMap = <int, int>{};
      for (final row in await txn.query(
        'stores',
        where: 'list_id = ?',
        whereArgs: [id],
      )) {
        final map = Map<String, dynamic>.of(row)
          ..remove('id')
          ..['list_id'] = newListId;
        storeIdMap[row['id']! as int] = await txn.insert('stores', map);
      }

      final itemIdMap = <int, int>{};
      for (final row in await txn.query(
        'items',
        where: 'list_id = ?',
        whereArgs: [id],
      )) {
        final oldCategoryId = row['category_id'] as int?;
        final map = Map<String, dynamic>.of(row)
          ..remove('id')
          ..['list_id'] = newListId
          ..['category_id'] =
              oldCategoryId == null ? null : categoryIdMap[oldCategoryId];
        itemIdMap[row['id']! as int] = await txn.insert('items', map);
      }

      for (final row in await _storePriceRows(txn, id)) {
        final newItemId = itemIdMap[row['item_id']! as int];
        final newStoreId = storeIdMap[row['store_id']! as int];
        if (newItemId == null || newStoreId == null) {
          continue;
        }
        final map = Map<String, dynamic>.of(row)
          ..remove('id')
          ..['item_id'] = newItemId
          ..['store_id'] = newStoreId;
        await txn.insert('item_store_prices', map);
      }

      return newListId;
    });
  }

  /// Returns the per-store prices for every item in [listId].
  Future<List<ItemStorePrice>> getItemStorePricesForList(int listId) async {
    final db = await database;
    final rows = await _storePriceRows(db, listId);
    return rows.map(ItemStorePrice.fromMap).toList();
  }

  Future<List<Map<String, dynamic>>> _storePriceRows(
    DatabaseExecutor db,
    int listId,
  ) {
    return db.rawQuery(
      'SELECT isp.* FROM item_store_prices isp '
      'JOIN items i ON isp.item_id = i.id WHERE i.list_id = ?',
      [listId],
    );
  }

  /// Returns the stored active list id, or `null` when none is set.
  ///
  /// May reference a list that has since been deleted — callers
  /// (e.g. `ListProvider`) validate it against the current lists. Falls back to
  /// the first list when no id is stored, but never re-creates a deleted list.
  Future<int?> getActiveListId() async {
    final db = await database;
    final value = await _meta(db, metaActiveListId);
    if (value != null) {
      return int.parse(value);
    }
    final lists = await getLists();
    if (lists.isNotEmpty) {
      await setActiveListId(lists.first.id!);
      return lists.first.id;
    }
    return null;
  }

  /// Persists [listId] as the active list.
  Future<void> setActiveListId(int listId) async {
    final db = await database;
    await db.insert(
      'app_meta',
      {'key': metaActiveListId, 'value': listId.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> _meta(DatabaseExecutor db, String key) async {
    final rows = await db.query(
      'app_meta',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['value'] as String?;
  }

  // --- Items --------------------------------------------------------------

  /// Returns the items in [listId], optionally only those still needed,
  /// ordered by manual position.
  Future<List<Item>> getItems(int listId, {bool needOnly = false}) async {
    final db = await database;
    final rows = await db.query(
      'items',
      where: needOnly ? 'list_id = ? AND need = 1' : 'list_id = ?',
      whereArgs: [listId],
      orderBy: 'sort_order, id',
    );
    return rows.map(Item.fromMap).toList();
  }

  /// Inserts [item] and returns its new id.
  Future<int> insertItem(Item item) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    item
      ..createdAt ??= now
      ..updatedAt = now;
    return db.insert('items', item.toMap()..remove('id'));
  }

  /// Updates [item]'s persisted columns.
  Future<void> updateItem(Item item) async {
    final db = await database;
    item.updatedAt = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Deletes the item with [id].
  Future<void> deleteItem(int id) async {
    final db = await database;
    await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  /// Persists a new manual order for [listId] by writing each item's
  /// `sort_order` to its position in [orderedIds].
  Future<void> reorderItems(int listId, List<int> orderedIds) async {
    final db = await database;
    final batch = db.batch();
    for (var i = 0; i < orderedIds.length; i++) {
      batch.update(
        'items',
        {'sort_order': i},
        where: 'id = ? AND list_id = ?',
        whereArgs: [orderedIds[i], listId],
      );
    }
    await batch.commit(noResult: true);
  }

  // --- Categories & stores (CRUD foundation for later phases) -------------

  /// Returns the categories in [listId] ordered by manual position.
  Future<List<Category>> getCategories(int listId) async {
    final db = await database;
    final rows = await db.query(
      'categories',
      where: 'list_id = ?',
      whereArgs: [listId],
      orderBy: 'sort_order, id',
    );
    return rows.map(Category.fromMap).toList();
  }

  /// Inserts [category] and returns its new id.
  Future<int> insertCategory(Category category) async {
    final db = await database;
    return db.insert('categories', category.toMap()..remove('id'));
  }

  /// Returns the stores in [listId] ordered by manual position.
  Future<List<Store>> getStores(int listId) async {
    final db = await database;
    final rows = await db.query(
      'stores',
      where: 'list_id = ?',
      whereArgs: [listId],
      orderBy: 'sort_order, id',
    );
    return rows.map(Store.fromMap).toList();
  }

  /// Inserts [store] and returns its new id.
  Future<int> insertStore(Store store) async {
    final db = await database;
    return db.insert('stores', store.toMap()..remove('id'));
  }

  // --- Backup / export / import -------------------------------------------

  /// Serializes lists (all, or just [listIds]) into a JSON-able envelope.
  ///
  /// Each list nests its categories, stores and items; each item nests its
  /// per-store prices. Stored ids are retained only so [importData] can rebuild
  /// the relationships.
  Future<Map<String, dynamic>> exportData({List<int>? listIds}) async {
    final all = await getLists();
    final lists = listIds == null
        ? all
        : all.where((l) => listIds.contains(l.id)).toList();

    final exported = <Map<String, dynamic>>[];
    for (final list in lists) {
      final listId = list.id!;
      final categories = await getCategories(listId);
      final stores = await getStores(listId);
      final items = await getItems(listId);
      final prices = await getItemStorePricesForList(listId);

      final pricesByItem = <int, List<Map<String, dynamic>>>{};
      for (final price in prices) {
        (pricesByItem[price.itemId] ??= []).add(price.toMap()..remove('id'));
      }

      exported.add({
        ...list.toMap(),
        'categories': categories.map((c) => c.toMap()).toList(),
        'stores': stores.map((s) => s.toMap()).toList(),
        'items': items.map((item) {
          return item.toMap()..['storePrices'] = pricesByItem[item.id] ?? [];
        }).toList(),
      });
    }

    return {'appVersion': schemaVersion, 'lists': exported};
  }

  /// The maximum number of lists accepted from a single import, guarding
  /// against denial-of-service via an enormous file.
  static const int maxImportLists = 500;

  // Column allow-lists (excluding `id` and foreign keys, which are set
  // explicitly). Keys outside these sets in an imported file are discarded so
  // attacker-supplied JSON can never inject arbitrary SQLite columns.
  static const Set<String> _listColumns = {
    'name',
    'icon',
    'style',
    'per_store_prices',
    'currency_symbol',
    'tax_rate',
    'tax2_rate',
    'tax2_enabled',
    'default_priority',
    'sort_primary',
    'sort_secondary',
    'sort_descending',
    'learn_order',
    'column_flags',
    'sort_order',
    'created_at',
    'updated_at',
  };
  static const Set<String> _categoryColumns = {'name', 'icon', 'sort_order'};
  static const Set<String> _storeColumns = {'name', 'sort_order'};
  static const Set<String> _itemColumns = {
    'name',
    'quantity',
    'unit',
    'price',
    'need',
    'completed',
    'note',
    'taxable',
    'coupon',
    'priority',
    'aisle',
    'item_date',
    'auto_delete',
    'private',
    'custom_text',
    'alarm_at',
    'alarm_sound',
    'sort_order',
    'created_at',
    'updated_at',
  };
  static const Set<String> _priceColumns = {'price', 'aisle'};

  /// Imports lists from an [exportData] envelope. Always **additive**: every
  /// list is created anew with fresh ids (relationships remapped), so existing
  /// data is preserved and ids never collide. Returns the number of lists
  /// imported. Accepts both whole-app and single-list envelopes.
  ///
  /// Input is treated as untrusted: only known columns are kept and values are
  /// coerced to SQLite-safe primitives, so a malformed or hostile file cannot
  /// inject columns or crash the insert.
  Future<int> importData(Map<String, dynamic> json) async {
    final lists =
        (json['lists'] as List?)?.whereType<Map<String, dynamic>>().toList() ??
            const [];
    if (lists.isEmpty) {
      return 0;
    }
    if (lists.length > maxImportLists) {
      throw ArgumentError(
        'Import exceeds the maximum of $maxImportLists lists',
      );
    }
    final db = await database;
    await db.transaction((txn) async {
      for (final list in lists) {
        final newListId =
            await txn.insert('lists', _sanitize(list, _listColumns));

        final categoryIdMap = <int, int>{};
        for (final category in _childList(list, 'categories')) {
          final map = _sanitize(category, _categoryColumns)
            ..['list_id'] = newListId;
          final newId = await txn.insert('categories', map);
          final oldId = _asInt(category['id']);
          if (oldId != null) {
            categoryIdMap[oldId] = newId;
          }
        }

        final storeIdMap = <int, int>{};
        for (final store in _childList(list, 'stores')) {
          final map = _sanitize(store, _storeColumns)..['list_id'] = newListId;
          final newId = await txn.insert('stores', map);
          final oldId = _asInt(store['id']);
          if (oldId != null) {
            storeIdMap[oldId] = newId;
          }
        }

        for (final item in _childList(list, 'items')) {
          final oldCategoryId = _asInt(item['category_id']);
          final map = _sanitize(item, _itemColumns)
            ..['list_id'] = newListId
            ..['category_id'] =
                oldCategoryId == null ? null : categoryIdMap[oldCategoryId];
          final newItemId = await txn.insert('items', map);

          for (final price in _childList(item, 'storePrices')) {
            final newStoreId = storeIdMap[_asInt(price['store_id'])];
            if (newStoreId == null) {
              continue;
            }
            final priceMap = _sanitize(price, _priceColumns)
              ..['item_id'] = newItemId
              ..['store_id'] = newStoreId;
            await txn.insert('item_store_prices', priceMap);
          }
        }
      }
    });
    return lists.length;
  }

  List<Map<String, dynamic>> _childList(Map<String, dynamic> parent, String k) {
    return (parent[k] as List?)?.whereType<Map<String, dynamic>>().toList() ??
        const [];
  }

  /// Builds an insert map containing only [allowed] keys, coercing each value
  /// to a SQLite-bindable primitive (booleans become 0/1; lists, maps and other
  /// non-primitives are dropped).
  Map<String, Object?> _sanitize(
    Map<String, dynamic> src,
    Set<String> allowed,
  ) {
    final out = <String, Object?>{};
    for (final key in allowed) {
      if (!src.containsKey(key)) {
        continue;
      }
      final value = src[key];
      if (value == null || value is num || value is String) {
        out[key] = value;
      } else if (value is bool) {
        out[key] = value ? 1 : 0;
      }
    }
    return out;
  }

  int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }
}
