import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:handyshopper/data/database_service.dart';
import 'package:handyshopper/localization/app_localizations.dart';
import 'package:handyshopper/models/item.dart';
import 'package:handyshopper/models/shopping_list.dart';
import 'package:handyshopper/models/store.dart';
import 'package:handyshopper/providers/category_provider.dart';
import 'package:handyshopper/providers/item_provider.dart';
import 'package:handyshopper/providers/list_provider.dart';
import 'package:handyshopper/providers/settings_provider.dart';
import 'package:handyshopper/providers/store_provider.dart';
import 'package:handyshopper/screens/category_screen.dart';
import 'package:handyshopper/screens/note_editor_screen.dart';
import 'package:handyshopper/screens/store_screen.dart';
import 'package:provider/provider.dart';

/// Full-screen editor for adding or editing an item.
///
/// Replaces the former add/edit dialog and is structured to grow as later
/// phases add priority, aisle, units, tax and stores.
class ItemDetailScreen extends StatefulWidget {
  /// Creates an [ItemDetailScreen]; [item] is null when adding a new item.
  const ItemDetailScreen({this.item, super.key});

  /// The item being edited, or `null` to add a new one.
  final Item? item;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late bool _need;
  late int? _categoryId;
  late String _note;

  // Per-store edits keyed by storeId; persisted on save.
  final Map<int, String> _storePrice = {};
  final Map<int, String> _storeAisle = {};
  late bool _storePricesLoaded;

  static final _decimalFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'^\d*[.,]?\d{0,2}'),
  );

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _quantityController =
        TextEditingController(text: (item?.quantity ?? 1.0).toString());
    _priceController =
        TextEditingController(text: item?.price?.toString() ?? '');
    _need = item?.need ?? true;
    _categoryId = item?.categoryId;
    _note = item?.note ?? '';
    // Existing items load their per-store prices; new items start empty.
    _storePricesLoaded = item?.id == null;
    if (item?.id != null) {
      unawaited(_loadStorePrices(item!.id!));
    }
  }

  Future<void> _loadStorePrices(int itemId) async {
    final rows = await context.read<DatabaseService>().getItemStorePrices(
          itemId,
        );
    if (!mounted) {
      return;
    }
    setState(() {
      for (final row in rows) {
        if (row.price != null) {
          _storePrice[row.storeId] = row.price.toString();
        }
        if (row.aisle != null) {
          _storeAisle[row.storeId] = row.aisle!;
        }
      }
      _storePricesLoaded = true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String _t(String key) => AppLocalizations.of(context).translate(key);

  Future<void> _editNote() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (context) => NoteEditorScreen(initialText: _note),
      ),
    );
    if (result != null) {
      setState(() => _note = result);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    final provider = context.read<ItemProvider>();
    final db = context.read<DatabaseService>();
    final stores = context.read<StoreProvider>().stores;
    final perStorePrices =
        context.read<ListProvider>().activeList?.perStorePrices ?? false;
    final navigator = Navigator.of(context);
    final listId = widget.item?.listId ?? provider.activeListId;
    if (listId == null) {
      return;
    }
    final safeName = name.length > 64 ? name.substring(0, 64) : name;
    final quantity =
        (double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 1.0)
            .clamp(0, 9999)
            .toDouble();
    // When the price field is hidden (non-shopping styles) the controller keeps
    // the item's existing value, so saving preserves rather than clears it.
    final rawPrice =
        double.tryParse(_priceController.text.replaceAll(',', '.'));
    final price = rawPrice == null
        ? null
        : double.parse(rawPrice.clamp(0, 1000000000).toStringAsFixed(2));
    final note = _note.trim().isEmpty ? null : _note.trim();
    // Guard against persisting a category that was deleted while editing
    // (which would write a dangling foreign key).
    final categories = context.read<CategoryProvider>().categories;
    final categoryId =
        categories.any((c) => c.id == _categoryId) ? _categoryId : null;

    final existing = widget.item;
    final int itemId;
    if (existing == null) {
      itemId = await provider.addItem(
        Item(
          listId: listId,
          name: safeName,
          quantity: quantity,
          price: price,
          need: _need,
          note: note,
          categoryId: categoryId,
        ),
      );
    } else {
      existing
        ..name = safeName
        ..quantity = quantity
        ..price = price
        ..need = _need
        ..note = note
        ..categoryId = categoryId;
      await provider.updateItem(existing);
      itemId = existing.id!;
    }

    if (perStorePrices) {
      await _persistStorePrices(db, itemId, stores);
      // addItem/updateItem already fetched, but before the store prices were
      // written; refetch so the list's price map reflects them.
      await provider.fetchItems();
    }
    navigator.pop();
  }

  Future<void> _persistStorePrices(
    DatabaseService db,
    int itemId,
    List<Store> stores,
  ) async {
    for (final store in stores) {
      final storeId = store.id;
      if (storeId == null) {
        continue;
      }
      if (!_storePrice.containsKey(storeId) &&
          !_storeAisle.containsKey(storeId)) {
        continue; // untouched store
      }
      final raw =
          double.tryParse((_storePrice[storeId] ?? '').replaceAll(',', '.'));
      final price = raw == null
          ? null
          : double.parse(raw.clamp(0, 1000000000).toStringAsFixed(2));
      await db.setItemStorePrice(
        itemId,
        storeId,
        price: price,
        aisle: _storeAisle[storeId],
      );
    }
  }

  Future<void> _confirmDelete() async {
    final item = widget.item;
    if (item?.id == null) {
      return;
    }
    final provider = context.read<ItemProvider>();
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t('delete_product')),
        content: Text(_t('delete_confirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(_t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(_t('delete_product')),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await provider.deleteItem(item!.id!);
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;
    final currency = context.watch<SettingsProvider>().currencySymbol;
    final activeList = context.watch<ListProvider>().activeList;
    // Price is a shopping-list concept; other styles hide it.
    final showsPrice =
        (activeList?.style ?? ListStyle.shopping) == ListStyle.shopping;
    final perStorePrices = activeList?.perStorePrices ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? _t('edit_product') : _t('add_product'),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => unawaited(_confirmDelete()),
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => unawaited(_save()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            autofocus: !isEditing,
            decoration: InputDecoration(labelText: _t('name')),
            inputFormatters: [LengthLimitingTextInputFormatter(64)],
          ),
          TextField(
            controller: _quantityController,
            decoration: InputDecoration(labelText: _t('quantity')),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              _decimalFormatter,
              LengthLimitingTextInputFormatter(12),
            ],
          ),
          if (showsPrice)
            TextField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: _t('price'),
                prefixText: '$currency ',
                hintText: 'Optional',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                _decimalFormatter,
                LengthLimitingTextInputFormatter(12),
              ],
            ),
          const SizedBox(height: 12),
          _buildCategoryRow(),
          if (perStorePrices) _buildStoresSection(currency),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_t('need')),
            value: _need,
            onChanged: (value) => setState(() => _need = value ?? true),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              _note.isEmpty ? Icons.note_outlined : Icons.note,
            ),
            title: Text(_t('note')),
            subtitle: _note.isEmpty
                ? null
                : Text(
                    _note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
            onTap: () => unawaited(_editNote()),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow() {
    return Consumer<CategoryProvider>(
      builder: (context, provider, child) {
        final categories = provider.categories;
        final value =
            categories.any((c) => c.id == _categoryId) ? _categoryId : null;
        return Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int?>(
                initialValue: value,
                decoration: InputDecoration(labelText: _t('category')),
                items: [
                  DropdownMenuItem<int?>(
                    child: Text(_t('uncategorized')),
                  ),
                  ...categories.map(
                    (c) => DropdownMenuItem<int?>(
                      value: c.id,
                      child: Text(
                        c.icon == null ? c.name : '${c.icon}  ${c.name}',
                      ),
                    ),
                  ),
                ],
                onChanged: (id) => setState(() => _categoryId = id),
              ),
            ),
            IconButton(
              tooltip: _t('edit_categories'),
              icon: const Icon(Icons.edit),
              onPressed: () {
                unawaited(
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const CategoryScreen(),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildStoresSection(String currency) {
    return Consumer<StoreProvider>(
      builder: (context, provider, child) {
        final stores = provider.stores;
        // Lowest entered price across stores, for the "cheapest" highlight.
        double? cheapest;
        for (final store in stores) {
          final value = double.tryParse(
            (_storePrice[store.id] ?? '').replaceAll(',', '.'),
          );
          if (value != null && (cheapest == null || value < cheapest)) {
            cheapest = value;
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _t('stores'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 18),
                  label: Text(_t('edit_stores')),
                  onPressed: () {
                    unawaited(
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => const StoreScreen(),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            if (!_storePricesLoaded)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (stores.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(_t('no_stores')),
              )
            else
              ...stores
                  .map((store) => _buildStoreRow(store, currency, cheapest)),
          ],
        );
      },
    );
  }

  Widget _buildStoreRow(Store store, String currency, double? cheapest) {
    final priceText = _storePrice[store.id] ?? '';
    final value = double.tryParse(priceText.replaceAll(',', '.'));
    final isCheapest = value != null && value == cheapest;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              store.name,
              style: isCheapest
                  ? const TextStyle(fontWeight: FontWeight.bold)
                  : null,
            ),
          ),
          Expanded(
            flex: 3,
            child: TextFormField(
              key: ValueKey('price_${store.id}'),
              initialValue: priceText,
              decoration: InputDecoration(
                labelText: _t('price'),
                prefixText: '$currency ',
                suffixIcon: isCheapest
                    ? const Icon(Icons.check, color: Colors.green, size: 18)
                    : null,
                isDense: true,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                _decimalFormatter,
                LengthLimitingTextInputFormatter(12),
              ],
              onChanged: (text) =>
                  setState(() => _storePrice[store.id!] = text),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              key: ValueKey('aisle_${store.id}'),
              initialValue: _storeAisle[store.id] ?? '',
              decoration: InputDecoration(
                labelText: _t('aisle'),
                isDense: true,
              ),
              inputFormatters: [LengthLimitingTextInputFormatter(16)],
              // No setState: aisle isn't rendered reactively, only read on
              // save.
              onChanged: (text) => _storeAisle[store.id!] = text,
            ),
          ),
        ],
      ),
    );
  }
}
