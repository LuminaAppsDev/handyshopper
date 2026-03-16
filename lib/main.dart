import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:handyshopper/localization/app_localizations.dart';
import 'package:handyshopper/models/product.dart';
import 'package:handyshopper/providers/product_provider.dart';
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
  const MyApp({required this.settingsProvider, super.key});

  /// The settings provider initialized before app launch.
  final SettingsProvider settingsProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => settingsProvider),
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
            home: const ProductListScreen(), // Set the home screen
            debugShowCheckedModeBanner: false, // Hide the debug banner
          );
        },
      ),
    );
  }
}

/// The main screen displaying the product list with "All" and "Need" tabs.
class ProductListScreen extends StatefulWidget {
  /// Creates a [ProductListScreen].
  const ProductListScreen({super.key});

  @override
  ProductListScreenState createState() => ProductListScreenState();
}

/// State for [ProductListScreen].
class ProductListScreenState extends State<ProductListScreen> {
  final PageController _pageController = PageController(initialPage: 1);
  int _currentPageIndex = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        Provider.of<ProductProvider>(context, listen: false).fetchProducts(),
      );
    });
  }

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
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.sort_by_alpha),
                title: Text(
                  AppLocalizations.of(context).translate('sort_by_name'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  unawaited(
                    Provider.of<ProductProvider>(context, listen: false)
                        .sortProducts(SortOption.alphabetical),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort),
                title: Text(
                  AppLocalizations.of(context).translate('sort_by_quantity'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  unawaited(
                    Provider.of<ProductProvider>(context, listen: false)
                        .sortProducts(SortOption.quantity),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: Text(
                  AppLocalizations.of(context).translate('sort_by_price'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  unawaited(
                    Provider.of<ProductProvider>(context, listen: false)
                        .sortProducts(SortOption.price),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.drag_handle),
                title: Text(
                  AppLocalizations.of(context).translate('sort_manually'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  unawaited(
                    Provider.of<ProductProvider>(context, listen: false)
                        .sortProducts(SortOption.manual),
                  );
                  setState(() {});
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
                _buildProductList(context, showNeedOnly: false),
                _buildProductList(context, showNeedOnly: true),
              ],
            ),
          ),
          if (_currentPageIndex == 1)
            Consumer<ProductProvider>(
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
                    _showAddProductDialog(context);
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

  Widget _buildProductList(
    BuildContext context, {
    required bool showNeedOnly,
  }) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        if (provider.products.isEmpty) {
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

        final products = showNeedOnly
            ? provider.products.where((product) => product.need).toList()
            : provider.products;

        return ReorderableListView(
          onReorder: (oldIndex, newIndex) {
            setState(() {
              var adjustedNewIndex = newIndex;
              if (adjustedNewIndex > oldIndex) {
                adjustedNewIndex -= 1;
              }
              final product = products.removeAt(oldIndex);
              products.insert(adjustedNewIndex, product);
              unawaited(
                provider.updateProductOrder(products, setManual: true),
              );
            });
          },
          children: products.map((product) {
            final quantityDisplay = product.quantity % 1 == 0
                ? product.quantity.toInt().toString()
                : product.quantity.toString();
            final priceStr = product.price != null
                ? ' - ${settingsProvider.currencySymbol}'
                    '${product.price!.toStringAsFixed(2)}'
                : '';
            return ListTile(
              key: ValueKey(product.id),
              leading: Checkbox(
                value: !showNeedOnly && product.need,
                onChanged: (value) {
                  product.need =
                      showNeedOnly ? !(value ?? false) : (value ?? false);
                  unawaited(provider.updateProduct(product));
                },
              ),
              title: Text(product.name),
              subtitle: Text('Q: $quantityDisplay$priceStr'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  _showDeleteConfirmationDialog(context, product.id!);
                },
              ),
              onTap: () {
                _showAddProductDialog(context, product: product);
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _showAddProductDialog(BuildContext context, {Product? product}) {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);

    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) {
          var name = product?.name ?? '';
          var quantity = product?.quantity ?? 1.0;
          var price = product?.price;
          var need = product?.need ?? true;

          final quantityController =
              TextEditingController(text: quantity.toString());
          final priceController =
              TextEditingController(text: price?.toString() ?? '');

          return AlertDialog(
            title: Text(
              product == null
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
                      controller: TextEditingController(text: name),
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(64),
                      ],
                      onChanged: (value) {
                        name = value;
                      },
                      onSubmitted: (_) {
                        _submitProduct(
                          context,
                          productProvider,
                          product,
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
                        _submitProduct(
                          context,
                          productProvider,
                          product,
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
                        _submitProduct(
                          context,
                          productProvider,
                          product,
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
                  _submitProduct(
                    context,
                    productProvider,
                    product,
                    name,
                    quantity,
                    price,
                    need,
                  );
                },
                child: Text(
                  product == null
                      ? AppLocalizations.of(context).translate('add_product')
                      : AppLocalizations.of(context).translate('update'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _submitProduct(
    BuildContext context,
    ProductProvider provider,
    Product? product,
    String name,
    double quantity,
    double? price,
    bool need,
  ) {
    if (name.isNotEmpty) {
      if (product == null) {
        final newProduct = Product(
          name: name,
          quantity: quantity,
          need: need,
          price: price != null ? double.parse(price.toStringAsFixed(2)) : null,
        );
        unawaited(provider.addProduct(newProduct));
      } else {
        final updatedProduct = Product(
          name: name,
          quantity: quantity,
          need: need,
          id: product.id,
          price: price != null ? double.parse(price.toStringAsFixed(2)) : null,
        );
        unawaited(provider.updateProduct(updatedProduct));
      }
      Navigator.of(context).pop();
      setState(() {});
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, int productId) {
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
                    Provider.of<ProductProvider>(context, listen: false)
                        .deleteProduct(productId),
                  );
                  Navigator.of(context).pop();
                  setState(() {});
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
