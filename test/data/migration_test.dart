import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:handyshopper/data/database_service.dart';
import 'package:handyshopper/models/item.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Builds a legacy v2 database (single flat `products` table) at [path] and
/// inserts [rows], mirroring the pre-v2.0 schema.
Future<void> buildLegacyV2Db(
  String path,
  List<Map<String, dynamic>> rows,
) async {
  final db = await databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 2,
      onCreate: (db, version) => db.execute(
        'CREATE TABLE products(id INTEGER PRIMARY KEY, name TEXT, '
        'quantity REAL, price REAL, need INTEGER)',
      ),
    ),
  );
  for (final row in rows) {
    await db.insert('products', row);
  }
  await db.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory tempDir;
  late String dbPath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hs_migration_test');
    dbPath = join(tempDir.path, 'product_database.db');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('migrates all v2 rows into the default list with zero data loss',
      () async {
    // Legacy data: a null price, a fractional quantity, and a not-needed row.
    await buildLegacyV2Db(dbPath, [
      {'id': 1, 'name': 'Cereal', 'quantity': 1.0, 'price': 2.25, 'need': 1},
      {'id': 2, 'name': 'Milk', 'quantity': 1.5, 'price': 0.95, 'need': 1},
      {'id': 3, 'name': 'Eggs', 'quantity': 1.0, 'price': null, 'need': 0},
    ]);

    // Legacy manual order: Eggs, Cereal, Milk.
    SharedPreferences.setMockInitialValues({
      'sortOption': 'manual',
      'manualOrder': ['3', '1', '2'],
    });

    final service = DatabaseService(factory: databaseFactoryFfi, path: dbPath);
    final listId = await service.getActiveListId();
    final items = await service.getItems(listId);

    // Every row preserved, with its original id.
    expect(items.length, 3);
    expect(items.map((i) => i.id).toSet(), {1, 2, 3});

    final byId = {for (final i in items) i.id: i};
    expect(byId[1]!.name, 'Cereal');
    expect(byId[1]!.price, 2.25);
    expect(byId[2]!.quantity, 1.5); // fractional preserved
    expect(byId[3]!.price, isNull); // null price preserved
    expect(byId[3]!.need, isFalse); // not-needed preserved

    // sort_order reflects the legacy manual order (Eggs, Cereal, Milk).
    expect(items.map((i) => i.id).toList(), [3, 1, 2]);
    expect(items.map((i) => i.sortOrder).toList(), [0, 1, 2]);

    // All items belong to the seeded default list.
    expect(items.every((i) => i.listId == listId), isTrue);

    await service.close();
  });

  test('drops the legacy products table and advances the id sequence',
      () async {
    await buildLegacyV2Db(dbPath, [
      {'id': 1, 'name': 'Cereal', 'quantity': 1.0, 'price': 2.25, 'need': 1},
    ]);
    SharedPreferences.setMockInitialValues({});

    final service = DatabaseService(factory: databaseFactoryFfi, path: dbPath);
    final listId = await service.getActiveListId();
    final db = await service.database;

    // products table is gone.
    final tables = await db.query(
      'sqlite_master',
      where: 'type = ? AND name = ?',
      whereArgs: ['table', 'products'],
    );
    expect(tables, isEmpty);

    // A newly inserted item gets a fresh id past the migrated max (1).
    final newId = await service.insertItem(Item(listId: listId, name: 'Bread'));
    expect(newId, greaterThan(1));

    await service.close();
  });

  test('falls back to display order when no manual order was stored', () async {
    await buildLegacyV2Db(dbPath, [
      {'id': 1, 'name': 'Cereal', 'quantity': 1.0, 'price': 2.25, 'need': 1},
      {'id': 2, 'name': 'Milk', 'quantity': 1.0, 'price': 0.95, 'need': 1},
    ]);
    // Sort was alphabetical, so manualOrder is irrelevant/absent.
    SharedPreferences.setMockInitialValues({'sortOption': 'alphabetical'});

    final service = DatabaseService(factory: databaseFactoryFfi, path: dbPath);
    final listId = await service.getActiveListId();
    final items = await service.getItems(listId);

    expect(items.map((i) => i.id).toList(), [1, 2]);
    expect(items.map((i) => i.sortOrder).toList(), [0, 1]);

    await service.close();
  });
}
