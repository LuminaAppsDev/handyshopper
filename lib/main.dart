import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'localization/app_localizations.dart';
import 'providers/product_provider.dart';
import 'providers/settings_provider.dart';
import 'models/product.dart';
import 'settings_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize settings provider before running the app
  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings(); // Load settings

  runApp(MyApp(settingsProvider: settingsProvider));
}

class MyApp extends StatelessWidget {
  final SettingsProvider settingsProvider;

  const MyApp({super.key, required this.settingsProvider});

  @override
  Widget build(BuildContext context) {
    // Setting up MultiProvider to manage state using ProductProvider and SettingsProvider
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
            themeMode: ThemeMode.system, // Use system theme mode
            locale: settingsProvider.locale, // Use the locale from SettingsProvider
            supportedLocales: const [
              // List of supported locales
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
            // Define localization delegates
            localizationsDelegates: const [
              AppLocalizations.delegate, // Custom localizations delegate
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

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  ProductListScreenState createState() => ProductListScreenState();
}

class ProductListScreenState extends State<ProductListScreen> {
  final PageController _pageController = PageController(initialPage: 1);
  int _currentPageIndex = 1; // Default to "Need" list

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
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
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: Text(AppLocalizations.of(context).translate('sort_by_name')),
              onTap: () {
                Navigator.pop(context);
                Provider.of<ProductProvider>(context, listen: false).sortProducts(SortOption.alphabetical);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort),
              title: Text(AppLocalizations.of(context).translate('sort_by_quantity')),
              onTap: () {
                Navigator.pop(context);
                Provider.of<ProductProvider>(context, listen: false).sortProducts(SortOption.quantity);
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: Text(AppLocalizations.of(context).translate('sort_by_price')),
              onTap: () {
                Navigator.pop(context);
                Provider.of<ProductProvider>(context, listen: false).sortProducts(SortOption.price);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drag_handle),
              title: Text(AppLocalizations.of(context).translate('sort_manually')),
              onTap: () {
                Navigator.pop(context);
                Provider.of<ProductProvider>(context, listen: false).sortProducts(SortOption.manual);
                setState(() {
                  _currentPageIndex = _currentPageIndex; // Rebuild to show reorderable list
                });
              },
            ),
          ],
        );
      },
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          _buildProductList(context, false), // "All" list
          _buildProductList(context, true),  // "Need" list
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Consumer<ProductProvider>(
          builder: (context, provider, child) {
            final totalPrice = provider.getTotalPrice();
            return Row(
              mainAxisAlignment: MainAxisAlignment.start,
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
                    foregroundColor: _currentPageIndex == 0 ? Colors.blue : Colors.black,
                  ),
                  child: Text(AppLocalizations.of(context).translate('all')),
                ),
                TextButton(
                  onPressed: () {
                    _pageController.jumpToPage(1);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: _currentPageIndex == 1 ? Colors.blue : Colors.black,
                  ),
                  child: Text(AppLocalizations.of(context).translate('need_list')),
                ),
                if (_currentPageIndex == 1) // Show total only in "Need" list
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      '${AppLocalizations.of(context).translate('total')}: ${Provider.of<SettingsProvider>(context).currencySymbol}${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.sort),
                  onPressed: () => _showSortingOptions(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductList(BuildContext context, bool showNeedOnly) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        if (provider.products.isEmpty) {
          return Center(child: Text(AppLocalizations.of(context).translate('no_products')));
        }

        final products = showNeedOnly
            ? provider.products.where((product) => product.need).toList()
            : provider.products;

        return ReorderableListView(
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final product = products.removeAt(oldIndex);
              products.insert(newIndex, product);
              provider.updateProductOrder(products, setManual: true);
            });
          },
          children: products.map((product) {
            return ListTile(
              key: ValueKey(product.id),
              leading: Checkbox(
                value: showNeedOnly ? false : product.need,
                onChanged: (value) {
                  product.need = showNeedOnly ? !(value ?? false) : (value ?? false);
                  provider.updateProduct(product);
                },
              ),
              title: Text(product.name),
              subtitle: Text('Q: ${product.quantity}${product.price != null ? ' - ${settingsProvider.currencySymbol}${product.price!.toStringAsFixed(2)}' : ''}'),
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
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String name = product?.name ?? '';
        int quantity = product?.quantity ?? 1;
        double? price = product?.price;
        bool need = product?.need ?? true;

        final quantityController = TextEditingController(text: quantity.toString());
        final priceController = TextEditingController(text: price?.toString() ?? '');

        return AlertDialog(
          title: Text(product == null
              ? AppLocalizations.of(context).translate('add_product')
              : AppLocalizations.of(context).translate('edit_product')),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('name')),
                    controller: TextEditingController(text: name),
                    inputFormatters: [LengthLimitingTextInputFormatter(64)],
                    onChanged: (value) {
                      name = value;
                    },
                    onSubmitted: (_) {
                      _submitProduct(context, productProvider, product, name, quantity, price, need);
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('quantity')),
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                    onTap: () {
                      quantityController.clear();
                    },
                    onChanged: (value) {
                      quantity = int.tryParse(value) ?? 1;
                      if (quantity > 9999) {
                        quantity = 9999;
                      }
                    },
                    onSubmitted: (_) {
                      _submitProduct(context, productProvider, product, name, quantity, price, need);
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: AppLocalizations.of(context).translate('price'), hintText: 'Optional'),
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}|,?\d{0,2}')),
                      LengthLimitingTextInputFormatter(12), // Limiting total digits including decimal
                    ],
                    onTap: () {
                      priceController.clear();
                    },
                    onChanged: (value) {
                      // Convert comma to dot for international users
                      value = value.replaceAll(',', '.');
                      price = double.tryParse(value);
                      // Limit the value to a maximum of 1,000,000,000
                      if (price != null && price! > 1000000000) {
                        price = 1000000000;
                      }
                    },
                    onSubmitted: (_) {
                      _submitProduct(context, productProvider, product, name, quantity, price, need);
                    },
                  ),
                  CheckboxListTile(
                    title: Text(AppLocalizations.of(context).translate('need')),
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
              child: Text(AppLocalizations.of(context).translate('cancel')),
            ),
            TextButton(
              onPressed: () {
                _submitProduct(context, productProvider, product, name, quantity, price, need);
              },
              child: Text(product == null ? AppLocalizations.of(context).translate('add_product') : AppLocalizations.of(context).translate('update')),
            ),
          ],
        );
      },
    );
  }

  void _submitProduct(BuildContext context, ProductProvider provider, Product? product, String name, int quantity, double? price, bool need) {
    if (name.isNotEmpty) {
      if (product == null) {
        final newProduct = Product(name: name, quantity: quantity, price: price != null ? double.parse(price.toStringAsFixed(2)) : null, need: need);
        provider.addProduct(newProduct);
      } else {
        final updatedProduct = Product(
          id: product.id,
          name: name,
          quantity: quantity,
          price: price != null ? double.parse(price.toStringAsFixed(2)) : null,
          need: need,
        );
        provider.updateProduct(updatedProduct);
      }
      Navigator.of(context).pop();
      setState(() {});
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, int productId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).translate('delete_product')),
          content: Text(AppLocalizations.of(context).translate('delete_confirmation')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context).translate('cancel')),
            ),
            TextButton(
              onPressed: () {
                Provider.of<ProductProvider>(context, listen: false).deleteProduct(productId);
                Navigator.of(context).pop();
                setState(() {});
              },
              child: Text(AppLocalizations.of(context).translate('delete_product')),
            ),
          ],
        );
      },
    );
  }
}
