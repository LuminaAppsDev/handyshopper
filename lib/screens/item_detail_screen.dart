import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:handyshopper/localization/app_localizations.dart';
import 'package:handyshopper/models/item.dart';
import 'package:handyshopper/providers/category_provider.dart';
import 'package:handyshopper/providers/item_provider.dart';
import 'package:handyshopper/providers/settings_provider.dart';
import 'package:handyshopper/screens/category_screen.dart';
import 'package:handyshopper/screens/note_editor_screen.dart';
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

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    final provider = context.read<ItemProvider>();
    final listId = widget.item?.listId ?? provider.activeListId;
    if (listId == null) {
      return;
    }
    final safeName = name.length > 64 ? name.substring(0, 64) : name;
    final quantity =
        (double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 1.0)
            .clamp(0, 9999)
            .toDouble();
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
    if (existing == null) {
      unawaited(
        provider.addItem(
          Item(
            listId: listId,
            name: safeName,
            quantity: quantity,
            price: price,
            need: _need,
            note: note,
            categoryId: categoryId,
          ),
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
      unawaited(provider.updateItem(existing));
    }
    Navigator.of(context).pop();
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
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
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
          TextField(
            controller: _priceController,
            decoration: InputDecoration(
              labelText: _t('price'),
              prefixText: '$currency ',
              hintText: 'Optional',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              _decimalFormatter,
              LengthLimitingTextInputFormatter(12),
            ],
          ),
          const SizedBox(height: 12),
          _buildCategoryRow(),
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
}
