import 'package:flutter_test/flutter_test.dart';
import 'package:handyshopper/data/database_service.dart';
import 'package:handyshopper/models/item.dart';
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
    final listId = await service.getActiveListId();
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
}
