import 'dart:async';

import 'package:flutter/material.dart';
import 'package:handyshopper/data/item_columns.dart';
import 'package:handyshopper/localization/app_localizations.dart';
import 'package:handyshopper/models/item.dart';
import 'package:handyshopper/models/shopping_list.dart';
import 'package:handyshopper/providers/category_provider.dart';
import 'package:handyshopper/providers/item_provider.dart';
import 'package:handyshopper/providers/list_provider.dart';
import 'package:handyshopper/providers/settings_provider.dart';
import 'package:handyshopper/providers/store_provider.dart';
import 'package:handyshopper/screens/checkout_screen.dart';
import 'package:handyshopper/screens/item_detail_screen.dart';
import 'package:handyshopper/screens/store_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Filter sentinel meaning "items with no category".
const int _uncategorizedFilter = -1;

/// Store-selector sentinel meaning "open the Edit Stores screen".
const int _editStoresAction = -2;

/// Displays the items of the active list with "All" and "Need" tabs and an
/// optional category filter.
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

  /// Active category filter: `null` = all, [_uncategorizedFilter] = no
  /// category, otherwise a category id.
  int? _categoryFilter;

  /// Selected store for per-store pricing: `null` = all stores (base price).
  int? _selectedStoreId;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int pageIndex) {
    setState(() => _currentPageIndex = pageIndex);
  }

  String _t(String key) => AppLocalizations.of(context).translate(key);

  void _addItem() => _openDetail(null);

  void _openDetail(Item? item) {
    unawaited(
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (context) => ItemDetailScreen(item: item),
        ),
      ),
    );
  }

  void _showSortingOptions(
    BuildContext context, {
    required bool showsPrice,
    required bool dated,
  }) {
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
              if (showsPrice)
                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: Text(
                    AppLocalizations.of(sheetContext)
                        .translate('sort_by_price'),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    unawaited(itemProvider.sortItems(SortOption.price));
                  },
                ),
              ListTile(
                leading: const Icon(Icons.low_priority),
                title: Text(
                  AppLocalizations.of(sheetContext)
                      .translate('sort_by_priority'),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  unawaited(itemProvider.sortItems(SortOption.priority));
                },
              ),
              if (showsPrice)
                ListTile(
                  leading: const Icon(Icons.alt_route),
                  title: Text(
                    AppLocalizations.of(sheetContext)
                        .translate('sort_by_aisle'),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    unawaited(itemProvider.sortItems(SortOption.aisle));
                  },
                ),
              if (dated)
                ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(
                    AppLocalizations.of(sheetContext).translate('sort_by_date'),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    unawaited(itemProvider.sortItems(SortOption.date));
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
    final activeList = context.watch<ListProvider>().activeList;
    final listName =
        activeList?.name ?? AppLocalizations.of(context).translate('title');
    // Price is a shopping-list concept; other styles hide it.
    final showsPrice =
        (activeList?.style ?? ListStyle.shopping) == ListStyle.shopping;
    final perStorePrices = activeList?.perStorePrices ?? false;
    final dated = activeList?.style == ListStyle.dated;
    final columnFlags = activeList?.columnFlags ?? 0;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          listName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          if (showsPrice && activeList != null)
            IconButton(
              icon: const Icon(Icons.point_of_sale),
              tooltip: _t('checkout'),
              onPressed: () {
                unawaited(
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => CheckoutScreen(
                        list: activeList,
                        storeId: _selectedStoreId,
                      ),
                    ),
                  ),
                );
              },
            ),
          if (perStorePrices) _buildStoreSelector(),
          _buildCategoryFilter(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                _buildItemList(
                  context,
                  showNeedOnly: false,
                  showsPrice: showsPrice,
                  columnFlags: columnFlags,
                ),
                _buildItemList(
                  context,
                  showNeedOnly: true,
                  showsPrice: showsPrice,
                  columnFlags: columnFlags,
                ),
              ],
            ),
          ),
          // The needed-items total is shown only on the "Need" tab, and only
          // for shopping-style lists.
          if (_currentPageIndex == 1 && showsPrice)
            Consumer<ItemProvider>(
              builder: (context, provider, child) {
                final totalPrice =
                    provider.getTotalPrice(storeId: _selectedStoreId);
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
                  onPressed: _addItem,
                ),
                TextButton(
                  onPressed: () => _pageController.jumpToPage(0),
                  style: TextButton.styleFrom(
                    foregroundColor: _currentPageIndex == 0
                        ? Colors.blue
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  child: Text(AppLocalizations.of(context).translate('all')),
                ),
                TextButton(
                  onPressed: () => _pageController.jumpToPage(1),
                  style: TextButton.styleFrom(
                    foregroundColor: _currentPageIndex == 1
                        ? Colors.blue
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  child: Text(
                    AppLocalizations.of(context).translate('need_list'),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.sort),
                  onPressed: () => _showSortingOptions(
                    context,
                    showsPrice: showsPrice,
                    dated: dated,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Consumer<CategoryProvider>(
      builder: (context, provider, child) {
        // If the filtered category was deleted, drop back to "all" so the list
        // doesn't silently appear empty.
        if (_categoryFilter != null &&
            _categoryFilter != _uncategorizedFilter &&
            !provider.categories.any((c) => c.id == _categoryFilter)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _categoryFilter = null);
            }
          });
        }
        return PopupMenuButton<int?>(
          icon: Icon(
            _categoryFilter == null ? Icons.filter_list : Icons.filter_list_alt,
          ),
          onSelected: (value) => setState(() => _categoryFilter = value),
          itemBuilder: (context) => [
            PopupMenuItem<int?>(child: Text(_t('all_categories'))),
            const PopupMenuItem<int?>(
              value: _uncategorizedFilter,
              child: _UncategorizedLabel(),
            ),
            ...provider.categories.map(
              (c) => PopupMenuItem<int?>(
                value: c.id,
                child: Text(c.icon == null ? c.name : '${c.icon}  ${c.name}'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStoreSelector() {
    return Consumer<StoreProvider>(
      builder: (context, provider, child) {
        // Reset to "all stores" if the selected store was deleted.
        if (_selectedStoreId != null &&
            !provider.stores.any((s) => s.id == _selectedStoreId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _selectedStoreId = null);
            }
          });
        }
        return PopupMenuButton<int?>(
          icon: const Icon(Icons.store),
          onSelected: (value) {
            if (value == _editStoresAction) {
              unawaited(
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const StoreScreen(),
                  ),
                ),
              );
              return;
            }
            setState(() => _selectedStoreId = value);
          },
          itemBuilder: (context) => [
            PopupMenuItem<int?>(child: Text(_t('all_stores'))),
            ...provider.stores.map(
              (s) => PopupMenuItem<int?>(value: s.id, child: Text(s.name)),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<int?>(
              value: _editStoresAction,
              child: Text(_t('edit_stores')),
            ),
          ],
        );
      },
    );
  }

  bool _matchesCategoryFilter(Item item) {
    if (_categoryFilter == null) {
      return true;
    }
    if (_categoryFilter == _uncategorizedFilter) {
      return item.categoryId == null;
    }
    return item.categoryId == _categoryFilter;
  }

  Widget _buildItemList(
    BuildContext context, {
    required bool showNeedOnly,
    required bool showsPrice,
    required int columnFlags,
  }) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final categoryIcons = {
      for (final c in context.watch<CategoryProvider>().categories)
        c.id: c.icon,
    };
    return Consumer<ItemProvider>(
      builder: (context, provider, child) {
        if (provider.items.isEmpty) {
          return Column(
            children: [
              const Spacer(),
              Center(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      AppLocalizations.of(context).translate('no_products'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          );
        }

        final items = provider.items
            .where(
              (item) =>
                  (!showNeedOnly || item.need) && _matchesCategoryFilter(item),
            )
            .toList();

        return ReorderableListView(
          onReorderItem: (oldIndex, newIndex) {
            // `items` may be filtered, so translate visible indices back onto
            // the full list before persisting the order.
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
            final insertAt = found == -1 ? full.length : found;
            full.insert(insertAt, moved);
            unawaited(provider.updateItemOrder(full, setManual: true));
          },
          children: items.map((item) {
            final displayPrice =
                showsPrice ? provider.priceFor(item, _selectedStoreId) : null;
            final emoji = categoryIcons[item.categoryId];
            final title = emoji == null ? item.name : '$emoji  ${item.name}';
            final subtitle = _composeSubtitle(
              item,
              columnFlags,
              displayPrice,
              settingsProvider.currencySymbol,
            );
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
              title: Text(title),
              subtitle: subtitle.isEmpty ? null : Text(subtitle),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () =>
                    _showDeleteConfirmationDialog(context, item.id!),
              ),
              onTap: () => _openDetail(item),
            );
          }).toList(),
        );
      },
    );
  }

  /// Builds the row subtitle from the list's enabled columns.
  String _composeSubtitle(
    Item item,
    int columnFlags,
    double? price,
    String currency,
  ) {
    final parts = <String>[];
    if (hasColumn(columnFlags, ItemColumn.quantity)) {
      final qty = item.quantity % 1 == 0
          ? item.quantity.toInt().toString()
          : item.quantity.toString();
      parts.add('Q: $qty${item.unit == null ? '' : ' ${item.unit}'}');
    }
    if (hasColumn(columnFlags, ItemColumn.price) && price != null) {
      parts.add('$currency${price.toStringAsFixed(2)}');
    }
    if (hasColumn(columnFlags, ItemColumn.priority)) {
      parts.add('P${item.priority}');
    }
    if (hasColumn(columnFlags, ItemColumn.aisle) &&
        (item.aisle?.isNotEmpty ?? false)) {
      parts.add(item.aisle!);
    }
    if (hasColumn(columnFlags, ItemColumn.date) && item.itemDate != null) {
      parts.add(
        DateFormat.yMd().format(
          DateTime.fromMillisecondsSinceEpoch(item.itemDate!),
        ),
      );
    }
    return parts.join(' · ');
  }

  void _showDeleteConfirmationDialog(BuildContext context, int itemId) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(_t('delete_product')),
            content: Text(_t('delete_confirmation')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(_t('cancel')),
              ),
              TextButton(
                onPressed: () {
                  unawaited(
                    Provider.of<ItemProvider>(context, listen: false)
                        .deleteItem(itemId),
                  );
                  Navigator.of(dialogContext).pop();
                },
                child: Text(_t('delete_product')),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A localized "Uncategorized" label (used inside a `const` popup item).
class _UncategorizedLabel extends StatelessWidget {
  const _UncategorizedLabel();

  @override
  Widget build(BuildContext context) {
    return Text(AppLocalizations.of(context).translate('uncategorized'));
  }
}
