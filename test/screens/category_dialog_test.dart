import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handyshopper/data/database_service.dart';
import 'package:handyshopper/localization/app_localizations.dart';
import 'package:handyshopper/providers/category_provider.dart';
import 'package:handyshopper/screens/category_screen.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  testWidgets('cancelling the new-category dialog does not crash', (
    tester,
  ) async {
    // The provider is never fetched; the cancel path touches no database.
    final provider = CategoryProvider(
      DatabaseService(
        factory: databaseFactoryFfiNoIsolate,
        path: inMemoryDatabasePath,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate],
        supportedLocales: const [Locale('en')],
        home: ChangeNotifierProvider<CategoryProvider>.value(
          value: provider,
          child: const CategoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open the add-category dialog, then cancel it.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    // Pump through the dismiss animation: previously the dialog's TextField
    // rebuilt against a disposed controller here and threw.
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
