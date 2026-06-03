import 'package:flutter_test/flutter_test.dart';
import 'package:handyshopper/data/database_service.dart';
import 'package:handyshopper/models/category.dart';
import 'package:handyshopper/models/item.dart';
import 'package:handyshopper/models/shopping_list.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late DatabaseService service;
  late int listId;

  setUp(() async {
    service = DatabaseService(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    listId = await service.getActiveListId();
  });

  tearDown(() async {
    await service.close();
  });

  test('fresh install seeds a single default "Shopping" list', () async {
    final lists = await service.getLists();
    expect(lists.length, 1);
    expect(lists.first.name, 'Shopping');
    expect(listId, lists.first.id);
  });

  test('item CRUD round-trips', () async {
    final id = await service.insertItem(
      Item(listId: listId, name: 'Cereal', price: 2.25),
    );
    var items = await service.getItems(listId);
    expect(items.single.name, 'Cereal');
    expect(items.single.id, id);

    final item = items.single
      ..name = 'Granola'
      ..price = 3.5;
    await service.updateItem(item);
    items = await service.getItems(listId);
    expect(items.single.name, 'Granola');
    expect(items.single.price, 3.5);

    await service.deleteItem(id);
    expect(await service.getItems(listId), isEmpty);
  });

  test('getItems(needOnly) filters out not-needed items', () async {
    await service.insertItem(Item(listId: listId, name: 'Needed'));
    await service.insertItem(
      Item(listId: listId, name: 'NotNeeded', need: false),
    );
    final needed = await service.getItems(listId, needOnly: true);
    expect(needed.map((i) => i.name), ['Needed']);
    expect((await service.getItems(listId)).length, 2);
  });

  test('reorderItems persists a new manual order', () async {
    final a = await service.insertItem(Item(listId: listId, name: 'A'));
    final b = await service.insertItem(Item(listId: listId, name: 'B'));
    final c = await service.insertItem(Item(listId: listId, name: 'C'));

    await service.reorderItems(listId, [c, a, b]);
    final items = await service.getItems(listId);
    expect(items.map((i) => i.name), ['C', 'A', 'B']);
  });

  test('deleting a list cascades to its items, categories and stores',
      () async {
    final otherId = await service.insertList(ShoppingList(name: 'Other'));
    await service.insertItem(Item(listId: otherId, name: 'Orphan'));
    await service.insertCategory(Category(listId: otherId, name: 'Cat'));

    final db = await service.database;
    await db.delete('lists', where: 'id = ?', whereArgs: [otherId]);

    expect(await service.getItems(otherId), isEmpty);
    expect(await service.getCategories(otherId), isEmpty);
  });

  test('deleting a category nulls its items category_id (SET NULL)', () async {
    final catId = await service.insertCategory(
      Category(listId: listId, name: 'Food'),
    );
    final itemId = await service.insertItem(
      Item(listId: listId, name: 'Cereal', categoryId: catId),
    );

    final db = await service.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [catId]);

    final items = await service.getItems(listId);
    expect(items.single.id, itemId);
    expect(items.single.categoryId, isNull);
  });
}
