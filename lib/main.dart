import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:handyshopper/data/database_service.dart';
import 'package:handyshopper/localization/app_localizations.dart';
import 'package:handyshopper/models/item.dart';
import 'package:handyshopper/providers/item_provider.dart';
import 'package:handyshopper/providers/list_provider.dart';
import 'package:handyshopper/providers/settings_provider.dart';
import 'package:handyshopper/settings_screen.dart';
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
            home: const ItemListScreen(), // Set the home screen
            debugShowCheckedModeBanner: false, // Hide the debug banner
          );
        },
      ),
    );
  }
}

/// The main screen displaying the item list with "All" and "Need" tabs.
class ItemListScreen extends StatefulWidget {
  /// Creates an [ItemListScreen].
  const ItemListScreen({super.key});

  @override
  ItemListScreenState createState() => ItemListScreenState();
}

/// State for [ItemListScreen].
class ItemListScreenState extends State<ItemListScreen> {
  final PageController _pageController = PageController(initialPage: 1);
  int _currentPageIndex = 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int pageIndex) {
    setState(() {
      _currentPageIndex = pageIndex;
    });
  }

  void _showSortingOptions(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.sort_by_alpha),
                title: Text(
                  AppLocalizations.of(sheetContext).translate('sort_by_name'),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  unawaited(itemProvider.sortItems(SortOption.alphabetical));
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort),
                title: Text(
                  AppLocalizations.of(sheetContext)
                      .translate('sort_by_quantity'),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  unawaited(itemProvider.sortItems(SortOption.quantity));
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: Text(
                  AppLocalizations.of(sheetContext).translate('sort_by_price'),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  unawaited(itemProvider.sortItems(SortOption.price));
                },
              ),
              ListTile(
                leading: const Icon(Icons.drag_handle),
                title: Text(
                  AppLocalizations.of(sheetContext).translate('sort_manually'),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  unawaited(itemProvider.sortItems(SortOption.manual));
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<SettingsProvider>(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.blue,
        title: Text(
          AppLocalizations.of(context).translate('title'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              unawaited(
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const SettingsScreen(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                _buildItemList(context, showNeedOnly: false),
                _buildItemList(context, showNeedOnly: true),
              ],
            ),
          ),
          if (_currentPageIndex == 1)
            Consumer<ItemProvider>(
              builder: (context, provider, child) {
                final totalPrice = provider.getTotalPrice();
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    '${AppLocalizations.of(context).translate('total')}: '
                    '${Provider.of<SettingsProvider>(context).currencySymbol}'
                    '${totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          BottomAppBar(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    _showAddItemDialog(context);
                  },
                ),
                TextButton(
                  onPressed: () {
                    _pageController.jumpToPage(0);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor:
                        _currentPageIndex == 0 ? Colors.blue : Colors.black,
                  ),
                  child: Text(
                    AppLocalizations.of(context).translate('all'),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _pageController.jumpToPage(1);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor:
                        _currentPageIndex == 1 ? Colors.blue : Colors.black,
                  ),
                  child: Text(
                    AppLocalizations.of(context).translate('need_list'),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.sort),
                  onPressed: () => _showSortingOptions(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(
    BuildContext context, {
    required bool showNeedOnly,
  }) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    return Consumer<ItemProvider>(
      builder: (context, provider, child) {
        if (provider.items.isEmpty) {
          return Column(
            children: [
              const Spacer(),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    AppLocalizations.of(context).translate('no_products'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const Spacer(),
            ],
          );
        }

        final items = showNeedOnly
            ? provider.items.where((item) => item.need).toList()
            : provider.items;

        return ReorderableListView(
          onReorderItem: (oldIndex, newIndex) {
            // `items` may be a filtered ("Need") view, so translate the visible
            // indices back onto the full list before persisting the order.
            final moved = items[oldIndex];
            final withoutMoved = List<Item>.of(items)..removeAt(oldIndex);
            final beforeId = newIndex < withoutMoved.length
                ? withoutMoved[newIndex].id
                : null;
            final full = List<Item>.of(provider.items)
              ..removeWhere((i) => i.id == moved.id);
            final found = beforeId == null
                ? -1
                : full.indexWhere((i) => i.id == beforeId);
            // Append when the anchor isn't found (e.g. dropped at the end).
            final insertAt = found == -1 ? full.length : found;
            full.insert(insertAt, moved);
            unawaited(provider.updateItemOrder(full, setManual: true));
          },
          children: items.map((item) {
            final quantityDisplay = item.quantity % 1 == 0
                ? item.quantity.toInt().toString()
                : item.quantity.toString();
            final priceStr = item.price != null
                ? ' - ${settingsProvider.currencySymbol}'
                    '${item.price!.toStringAsFixed(2)}'
                : '';
            return ListTile(
              key: ValueKey(item.id),
              // On the "All" tab the checkbox reflects/toggles `need`. On the
              // "Need" tab it acts as a check-off control: it renders unchecked
              // and tapping it clears `need`, removing the item from the view.
              leading: Checkbox(
                value: !showNeedOnly && item.need,
                onChanged: (value) {
                  item.need =
                      showNeedOnly ? !(value ?? false) : (value ?? false);
                  unawaited(provider.updateItem(item));
                },
              ),
              title: Text(item.name),
              subtitle: Text('Q: $quantityDisplay$priceStr'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  _showDeleteConfirmationDialog(context, item.id!);
                },
              ),
              onTap: () {
                _showAddItemDialog(context, item: item);
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _showAddItemDialog(BuildContext context, {Item? item}) {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);

    var name = item?.name ?? '';
    var quantity = item?.quantity ?? 1.0;
    var price = item?.price;
    var need = item?.need ?? true;

    // Created once and disposed when the dialog closes, so rebuilds (e.g.
    // toggling "need") don't recreate controllers or reset the cursor.
    final nameController = TextEditingController(text: name);
    final quantityController = TextEditingController(text: quantity.toString());
    final priceController =
        TextEditingController(text: price?.toString() ?? '');

    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              item == null
                  ? AppLocalizations.of(context).translate('add_product')
                  : AppLocalizations.of(context).translate('edit_product'),
            ),
            content: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context).translate('name'),
                      ),
                      controller: nameController,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(64),
                      ],
                      onChanged: (value) {
                        name = value;
                      },
                      onSubmitted: (_) {
                        _submitItem(
                          context,
                          itemProvider,
                          item,
                          name,
                          quantity,
                          price,
                          need,
                        );
                      },
                    ),
                    TextField(
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context).translate('quantity'),
                      ),
                      controller: quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}|,?\d{0,2}'),
                        ),
                        LengthLimitingTextInputFormatter(12),
                      ],
                      onTap: quantityController.clear,
                      onChanged: (value) {
                        final normalized = value.replaceAll(',', '.');
                        quantity = double.tryParse(normalized) ?? 1.0;
                        if (quantity > 9999) {
                          quantity = 9999;
                        }
                      },
                      onSubmitted: (_) {
                        _submitItem(
                          context,
                          itemProvider,
                          item,
                          name,
                          quantity,
                          price,
                          need,
                        );
                      },
                    ),
                    TextField(
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context).translate('price'),
                        hintText: 'Optional',
                      ),
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}|,?\d{0,2}'),
                        ),
                        LengthLimitingTextInputFormatter(12),
                      ],
                      onTap: priceController.clear,
                      onChanged: (value) {
                        final normalized = value.replaceAll(',', '.');
                        price = double.tryParse(normalized);
                        if (price != null && price! > 1000000000) {
                          price = 1000000000;
                        }
                      },
                      onSubmitted: (_) {
                        _submitItem(
                          context,
                          itemProvider,
                          item,
                          name,
                          quantity,
                          price,
                          need,
                        );
                      },
                    ),
                    CheckboxListTile(
                      title: Text(
                        AppLocalizations.of(context).translate('need'),
                      ),
                      value: need,
                      onChanged: (value) {
                        setState(() {
                          need = value ?? true;
                        });
                      },
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  AppLocalizations.of(context).translate('cancel'),
                ),
              ),
              TextButton(
                onPressed: () {
                  _submitItem(
                    context,
                    itemProvider,
                    item,
                    name,
                    quantity,
                    price,
                    need,
                  );
                },
                child: Text(
                  item == null
                      ? AppLocalizations.of(context).translate('add_product')
                      : AppLocalizations.of(context).translate('update'),
                ),
              ),
            ],
          );
        },
      ).whenComplete(() {
        nameController.dispose();
        quantityController.dispose();
        priceController.dispose();
      }),
    );
  }

  void _submitItem(
    BuildContext context,
    ItemProvider provider,
    Item? item,
    String name,
    double quantity,
    double? price,
    bool need,
  ) {
    if (name.isEmpty) {
      return;
    }
    final listId = item?.listId ?? provider.activeListId;
    if (listId == null) {
      return;
    }
    // Enforce the same caps as the input formatters at the write path, so the
    // limits hold even if a value bypasses the widget (paste, programmatic).
    final safeName = name.length > 64 ? name.substring(0, 64) : name;
    final safeQuantity = quantity.clamp(0, 9999).toDouble();
    final clampedPrice = price?.clamp(0, 1000000000).toDouble();
    final roundedPrice = clampedPrice != null
        ? double.parse(clampedPrice.toStringAsFixed(2))
        : null;
    if (item == null) {
      unawaited(
        provider.addItem(
          Item(
            listId: listId,
            name: safeName,
            quantity: safeQuantity,
            need: need,
            price: roundedPrice,
          ),
        ),
      );
    } else {
      item
        ..name = safeName
        ..quantity = safeQuantity
        ..need = need
        ..price = roundedPrice;
      unawaited(provider.updateItem(item));
    }
    Navigator.of(context).pop();
  }

  void _showDeleteConfirmationDialog(BuildContext context, int itemId) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              AppLocalizations.of(context).translate('delete_product'),
            ),
            content: Text(
              AppLocalizations.of(context).translate('delete_confirmation'),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  AppLocalizations.of(context).translate('cancel'),
                ),
              ),
              TextButton(
                onPressed: () {
                  unawaited(
                    Provider.of<ItemProvider>(context, listen: false)
                        .deleteItem(itemId),
                  );
                  Navigator.of(context).pop();
                },
                child: Text(
                  AppLocalizations.of(context).translate('delete_product'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
