// Smoke test: boots the app over an in-memory database and mocked
// preferences, and verifies the main screen renders.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handyshopper/data/database_service.dart';
import 'package:handyshopper/main.dart';
import 'package:handyshopper/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late DatabaseService db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // No-isolate factory: runs SQLite on the current isolate so the tester's
    // fake-async clock can advance the provider's load(). In-memory keeps it
    // fast and fake-async-friendly.
    db = DatabaseService(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
  });

  tearDown(() async {
    await db.close();
  });

  // One end-to-end flow in a single widget test: a second testWidgets would
  // share the ffi ':memory:' database, so the whole journey lives here.
  testWidgets('boots, opens a list, and adds an item via the detail editor',
      (tester) async {
    final settingsProvider = SettingsProvider();
    await settingsProvider.loadSettings();
    await tester.pumpWidget(
      MyApp(settingsProvider: settingsProvider, databaseService: db),
    );
    await tester.pumpAndSettle();

    // Lists screen shows the app title and the seeded default list.
    expect(find.text('HandyShopper'), findsOneWidget);
    expect(find.text('Shopping'), findsOneWidget);

    // Tapping the list opens its (empty) item screen.
    await tester.tap(find.text('Shopping'));
    await tester.pumpAndSettle();
    expect(
      find.text('Use the + button to add items to the list.'),
      findsOneWidget,
    );

    // Open the detail screen, enter a name, and save.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Bread');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    // Back on the item list, the new item appears.
    expect(find.text('Bread'), findsOneWidget);
  });
}
