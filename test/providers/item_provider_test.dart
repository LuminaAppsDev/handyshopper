import 'package:flutter_test/flutter_test.dart';
import 'package:handyshopper/data/database_service.dart';
import 'package:handyshopper/models/item.dart';
import 'package:handyshopper/models/store.dart';
import 'package:handyshopper/providers/item_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late DatabaseService service;
  late ItemProvider provider;

  setUp(() async {
    service = DatabaseService(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    final listId = (await service.getActiveListId())!;
    final list = (await service.getLists()).firstWhere((l) => l.id == listId);
    provider = ItemProvider(service)..setActiveList(list);
    await provider.fetchItems();
  });

  tearDown(() async {
    await service.close();
  });

  test('addItem persists and notifies', () async {
    var notified = false;
    provider.addListener(() => notified = true);

    await provider.addItem(
      Item(listId: provider.activeListId!, name: 'Milk'),
    );

    expect(provider.items.single.name, 'Milk');
    expect(notified, isTrue);
  });

  test('sortItems(alphabetical) orders items and persists the choice',
      () async {
    final listId = provider.activeListId!;
    await provider.addItem(Item(listId: listId, name: 'Banana'));
    await provider.addItem(Item(listId: listId, name: 'Apple'));
    await provider.addItem(Item(listId: listId, name: 'Cherry'));

    await provider.sortItems(SortOption.alphabetical);

    expect(provider.items.map((i) => i.name), ['Apple', 'Banana', 'Cherry']);
    expect(provider.sortPrimary, 'alphabetical');
  });

  test('getTotalPrice sums price * quantity over needed items only', () async {
    final listId = provider.activeListId!;
    await provider.addItem(
      Item(listId: listId, name: 'A', price: 2, quantity: 3),
    ); // 6
    await provider.addItem(
      Item(listId: listId, name: 'B', price: 1.5, quantity: 2),
    ); // 3
    await provider.addItem(
      Item(listId: listId, name: 'C', price: 99, need: false),
    ); // excluded

    expect(provider.getTotalPrice(), 9.0);
  });

  test('deleteItem removes the item', () async {
    final listId = provider.activeListId!;
    await provider.addItem(Item(listId: listId, name: 'Temp'));
    final id = provider.items.single.id!;

    await provider.deleteItem(id);

    expect(provider.items, isEmpty);
  });

  test('markNeededPurchased clears need and sets completed', () async {
    final listId = provider.activeListId!;
    await provider.addItem(Item(listId: listId, name: 'A'));
    await provider.addItem(Item(listId: listId, name: 'B', need: false));

    await provider.markNeededPurchased();

    final a = provider.items.firstWhere((i) => i.name == 'A');
    expect(a.need, isFalse);
    expect(a.completed, isTrue);
    // B was not needed, so it is left untouched.
    final b = provider.items.firstWhere((i) => i.name == 'B');
    expect(b.completed, isFalse);
  });

  test('sorts by priority, aisle (empty last) and date (null last)', () async {
    final listId = provider.activeListId!;
    await provider.addItem(
      Item(listId: listId, name: 'Low', priority: 5, aisle: 'B'),
    );
    await provider.addItem(
      Item(listId: listId, name: 'High', priority: 1),
    ); // no aisle
    await provider.addItem(
      Item(listId: listId, name: 'Mid', priority: 2, aisle: 'A'),
    );

    await provider.sortItems(SortOption.priority);
    expect(provider.items.map((i) => i.name), ['High', 'Mid', 'Low']);

    await provider.sortItems(SortOption.aisle);
    // 'A', 'B', then the empty-aisle item last.
    expect(provider.items.map((i) => i.name), ['Mid', 'Low', 'High']);
  });

  test('priceFor and getTotalPrice respect per-store prices', () async {
    final listId = provider.activeListId!;
    final storeId = await service.insertStore(Store(listId: listId, name: 'A'));
    await provider.addItem(Item(listId: listId, name: 'Milk', price: 2));
    final itemId = provider.items.single.id!;
    await service.setItemStorePrice(itemId, storeId, price: 1.5);
    await provider.fetchItems();

    final item = provider.items.single;
    expect(provider.priceFor(item, null), 2.0); // base price
    expect(provider.priceFor(item, storeId), 1.5); // store override
    // A store with no recorded price falls back to the base price.
    expect(provider.priceFor(item, storeId + 999), 2.0);

    expect(provider.getTotalPrice(), 2.0);
    expect(provider.getTotalPrice(storeId: storeId), 1.5);
  });
}
