// Smoke test: boots the app over an in-memory database and mocked
// preferences, and verifies the main screen renders.

import 'package:flutter_test/flutter_test.dart';
import 'package:handyshopper/data/database_service.dart';
import 'package:handyshopper/main.dart';
import 'package:handyshopper/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('boots to the lists screen and opens a list', (tester) async {
    final settingsProvider = SettingsProvider();
    await settingsProvider.loadSettings();

    await tester.pumpWidget(
      MyApp(
        settingsProvider: settingsProvider,
        // No-isolate factory: runs SQLite on the current isolate so the
        // tester's fake-async clock can advance the provider's load().
        databaseService: DatabaseService(
          factory: databaseFactoryFfiNoIsolate,
          path: inMemoryDatabasePath,
        ),
      ),
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
  });
}
