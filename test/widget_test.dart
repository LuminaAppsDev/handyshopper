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

  testWidgets('app boots and shows the title and empty state', (tester) async {
    final settingsProvider = SettingsProvider();
    await settingsProvider.loadSettings();

    await tester.pumpWidget(
      MyApp(
        settingsProvider: settingsProvider,
        databaseService: DatabaseService(
          factory: databaseFactoryFfi,
          path: inMemoryDatabasePath,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('HandyShopper'), findsOneWidget);
    expect(
      find.text('Use the + button to add items to the list.'),
      findsOneWidget,
    );
  });
}
