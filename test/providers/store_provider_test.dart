import 'package:flutter_test/flutter_test.dart';
import 'package:handyshopper/data/database_service.dart';
import 'package:handyshopper/models/shopping_list.dart';
import 'package:handyshopper/providers/store_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late DatabaseService service;
  late StoreProvider provider;
  late int listId;

  setUp(() async {
    service = DatabaseService(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    listId = (await service.getActiveListId())!;
    provider = StoreProvider(service)..setActiveList(listId);
    await provider.fetchStores();
  });

  tearDown(() async {
    await service.close();
  });

  test('add, rename and delete stores', () async {
    await provider.addStore('Aldi');
    expect(provider.stores.single.name, 'Aldi');

    final id = provider.stores.single.id!;
    await provider.renameStore(id, 'Lidl');
    expect(provider.stores.single.name, 'Lidl');

    await provider.deleteStore(id);
    expect(provider.stores, isEmpty);
  });

  test('stores are scoped to the active list', () async {
    await provider.addStore('Aldi');
    final otherListId = await service.insertList(ShoppingList(name: 'Other'));

    provider.setActiveList(otherListId);
    await provider.fetchStores();
    expect(provider.stores, isEmpty);

    provider.setActiveList(listId);
    await provider.fetchStores();
    expect(provider.stores.single.name, 'Aldi');
  });
}
