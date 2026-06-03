import 'package:flutter_test/flutter_test.dart';
import 'package:handyshopper/data/database_service.dart';
import 'package:handyshopper/providers/list_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late DatabaseService service;

  setUp(() {
    service = DatabaseService(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
  });

  tearDown(() async {
    await service.close();
  });

  test('load resolves the default list and active id', () async {
    final provider = ListProvider(service);
    await provider.load();

    expect(provider.lists.length, 1);
    expect(provider.activeListId, isNotNull);
    expect(provider.activeList, isNotNull);
    expect(provider.activeList!.id, provider.activeListId);
  });
}
