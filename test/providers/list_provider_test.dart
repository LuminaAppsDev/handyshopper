import 'package:flutter_test/flutter_test.dart';
import 'package:handyshopper/data/database_service.dart';
import 'package:handyshopper/providers/list_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late DatabaseService service;
  late ListProvider provider;

  setUp(() async {
    service = DatabaseService(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    provider = ListProvider(service);
    await provider.load();
  });

  tearDown(() async {
    await service.close();
  });

  test('load resolves the default list and active id', () {
    expect(provider.lists.length, 1);
    expect(provider.activeList!.name, 'Shopping');
    expect(provider.activeList!.id, provider.activeListId);
  });

  test('createList adds a list and setActive switches to it', () async {
    final newId = await provider.createList('Hardware');
    expect(provider.lists.length, 2);

    await provider.setActive(newId);
    expect(provider.activeListId, newId);
    expect(provider.activeList!.name, 'Hardware');
  });

  test('renameList updates the name', () async {
    final id = provider.activeListId!;
    await provider.renameList(id, 'Weekly');
    expect(provider.lists.firstWhere((l) => l.id == id).name, 'Weekly');
  });

  test('copyList duplicates under a "(copy)" name', () async {
    final id = provider.activeListId!;
    final copyId = await provider.copyList(id);
    expect(provider.lists.length, 2);
    expect(
      provider.lists.firstWhere((l) => l.id == copyId).name,
      'Shopping (copy)',
    );
  });

  test('deleting the active list re-resolves active to a remaining list',
      () async {
    final second = await provider.createList('Second');
    await provider.setActive(second);

    await provider.deleteList(second);

    expect(provider.lists.length, 1);
    expect(provider.activeListId, provider.lists.single.id);
  });

  test('deleting the last list leaves no active list', () async {
    await provider.deleteList(provider.activeListId!);
    expect(provider.lists, isEmpty);
    expect(provider.activeListId, isNull);
    expect(provider.activeList, isNull);
  });

  test('updateListSettings renames and toggles per-store prices', () async {
    final id = provider.activeListId!;
    expect(provider.activeList!.perStorePrices, isFalse);

    await provider.updateListSettings(
      id,
      name: 'Groceries',
      perStorePrices: true,
    );

    final list = provider.lists.firstWhere((l) => l.id == id);
    expect(list.name, 'Groceries');
    expect(list.perStorePrices, isTrue);
  });
}
