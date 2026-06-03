import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:handyshopper/data/database_service.dart';
import 'package:handyshopper/models/category.dart';
import 'package:handyshopper/models/item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  DatabaseService newService() => DatabaseService(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      );

  test('export -> JSON -> import round-trips into a fresh database', () async {
    final source = newService();
    final listId = (await source.getActiveListId())!;
    final catId =
        await source.insertCategory(Category(listId: listId, name: 'Food'));
    await source.insertItem(
      Item(listId: listId, name: 'Milk', categoryId: catId, price: 1.25),
    );
    await source.insertItem(Item(listId: listId, name: 'Eggs', need: false));

    // Simulate writing to and reading back from a file.
    final encoded = jsonEncode(await source.exportData());
    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    await source.close();

    final target = newService();
    // Remove the target's own seeded default so we compare like-for-like.
    final seeded = await target.getLists();
    for (final l in seeded) {
      await target.deleteList(l.id!);
    }
    final imported = await target.importData(decoded);
    expect(imported, 1);

    final lists = await target.getLists();
    expect(lists.single.name, 'Shopping');
    final items = await target.getItems(lists.single.id!);
    expect(items.map((i) => i.name).toSet(), {'Milk', 'Eggs'});
    final milk = items.firstWhere((i) => i.name == 'Milk');
    expect(milk.price, 1.25);
    final cats = await target.getCategories(lists.single.id!);
    expect(milk.categoryId, cats.single.id); // FK remapped on import
    await target.close();
  });

  test('import is additive and assigns fresh ids', () async {
    final source = newService();
    final listId = (await source.getActiveListId())!;
    await source.insertItem(Item(listId: listId, name: 'Milk'));
    final data = jsonDecode(jsonEncode(await source.exportData()))
        as Map<String, dynamic>;
    await source.close();

    final target = newService();
    final before = (await target.getLists()).length; // seeded default = 1
    await target.importData(data);
    await target.importData(data); // twice
    final after = await target.getLists();

    expect(after.length, before + 2); // additive, nothing replaced
    final ids = after.map((l) => l.id).toSet();
    expect(ids.length, after.length); // all ids unique
    await target.close();
  });

  test('import sanitizes hostile JSON: drops unknown keys, coerces bools',
      () async {
    final service = newService();
    final hostile = {
      'lists': [
        {
          'name': 'Evil',
          'bogus_column': 'DROP TABLE items', // unknown key -> dropped
          'items': [
            {
              'name': 'Item',
              'taxable': true, // JSON bool -> coerced to 1
              'rm_rf': {'nested': 'object'}, // non-primitive -> dropped
            },
          ],
        },
      ],
    };

    final count = await service.importData(hostile); // must not throw
    expect(count, 1);
    final list = (await service.getLists()).firstWhere((l) => l.name == 'Evil');
    final items = await service.getItems(list.id!);
    expect(items.single.name, 'Item');
    expect(items.single.taxable, isTrue); // bool coerced and round-tripped
    await service.close();
  });

  test('import truncates an over-long text field', () async {
    final service = newService();
    final hostile = {
      'lists': [
        {
          'name': 'A' * (DatabaseService.maxImportStringLength + 500),
          'items': [
            {
              'name': 'Item',
              'note': 'B' * (DatabaseService.maxImportStringLength + 500),
            },
          ],
        },
      ],
    };
    await service.importData(hostile);
    final list =
        (await service.getLists()).firstWhere((l) => l.name.startsWith('A'));
    expect(list.name.length, DatabaseService.maxImportStringLength);
    final items = await service.getItems(list.id!);
    expect(items.single.note!.length, DatabaseService.maxImportStringLength);
    await service.close();
  });

  test('import rejects a file exceeding the list cap', () async {
    final service = newService();
    final tooMany = {
      'lists': List.generate(
        DatabaseService.maxImportLists + 1,
        (i) => {'name': 'L$i'},
      ),
    };
    await expectLater(service.importData(tooMany), throwsArgumentError);
    await service.close();
  });
}
