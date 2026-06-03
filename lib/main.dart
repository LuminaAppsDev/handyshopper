import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:handyshopper/data/database_service.dart';
import 'package:handyshopper/localization/app_localizations.dart';
import 'package:handyshopper/providers/item_provider.dart';
import 'package:handyshopper/providers/list_provider.dart';
import 'package:handyshopper/providers/settings_provider.dart';
import 'package:handyshopper/screens/lists_screen.dart';
import 'package:handyshopper/services/share_service.dart';
import 'package:provider/provider.dart';

/// Entry point for the HandyShopper app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();

  runApp(MyApp(settingsProvider: settingsProvider));
}

/// Root widget that configures providers, theming, and localization.
class MyApp extends StatelessWidget {
  /// Creates a [MyApp] with the given [settingsProvider].
  ///
  /// [databaseService] may be supplied to inject a test database; when omitted
  /// a default on-device [DatabaseService] is created.
  const MyApp({
    required this.settingsProvider,
    this.databaseService,
    super.key,
  });

  /// The settings provider initialized before app launch.
  final SettingsProvider settingsProvider;

  /// An optional injected database service (used by tests).
  final DatabaseService? databaseService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DatabaseService>(
          create: (_) => databaseService ?? DatabaseService(),
        ),
        Provider<ShareService>(create: (_) => ShareService()),
        ChangeNotifierProvider(
          create: (ctx) => ListProvider(ctx.read<DatabaseService>()),
        ),
        ChangeNotifierProxyProvider<ListProvider, ItemProvider>(
          create: (ctx) => ItemProvider(ctx.read<DatabaseService>()),
          update: (ctx, listProvider, itemProvider) =>
              itemProvider!..setActiveList(listProvider.activeList),
        ),
        ChangeNotifierProvider.value(value: settingsProvider),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            title: 'HandyShopper',
            // Define themes for light and dark modes
            theme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.dark,
            ),
            locale: settingsProvider.locale,
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('de', 'DE'),
              Locale('ja', 'JP'),
              Locale('fr', 'FR'),
              Locale('it', 'IT'),
              Locale('es', 'ES'),
              Locale('ko', 'KR'),
              Locale('ru', 'RU'),
              Locale('zh', 'CN'),
              Locale('hi', 'IN'),
              Locale('bn', 'BD'),
              Locale('pt', 'PT'),
              Locale('vi', 'VN'),
              Locale('tr', 'TR'),
              Locale('mr', 'IN'),
              Locale('te', 'IN'),
              Locale('pa', 'IN'),
              Locale('ta', 'IN'),
              Locale('fa', 'IR'),
              Locale('ur', 'PK'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const ListsScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
