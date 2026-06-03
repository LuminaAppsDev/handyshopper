import 'package:flutter_test/flutter_test.dart';
import 'package:handyshopper/data/database_service.dart';
import 'package:handyshopper/models/shopping_list.dart';
import 'package:handyshopper/providers/category_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late DatabaseService service;
  late CategoryProvider provider;
  late int listId;

  setUp(() async {
    service = DatabaseService(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    listId = (await service.getActiveListId())!;
    provider = CategoryProvider(service)..setActiveList(listId);
    await provider.fetchCategories();
  });

  tearDown(() async {
    await service.close();
  });

  test('add, rename, setIcon and delete categories', () async {
    await provider.addCategory('Food', icon: '🥦');
    expect(provider.categories.single.name, 'Food');
    expect(provider.categories.single.icon, '🥦');

    final id = provider.categories.single.id!;
    await provider.renameCategory(id, 'Groceries');
    expect(provider.categories.single.name, 'Groceries');

    await provider.setIcon(id, '🛒');
    expect(provider.categories.single.icon, '🛒');

    await provider.setIcon(id, null);
    expect(provider.categories.single.icon, isNull);

    await provider.deleteCategory(id);
    expect(provider.categories, isEmpty);
  });

  test('categories are scoped to the active list', () async {
    await provider.addCategory('Food');
    final otherListId = await service.insertList(ShoppingList(name: 'Other'));
    provider.setActiveList(otherListId);
    await provider.fetchCategories();
    expect(provider.categories, isEmpty); // other list has none

    provider.setActiveList(listId);
    await provider.fetchCategories();
    expect(provider.categories.single.name, 'Food');
  });
}
