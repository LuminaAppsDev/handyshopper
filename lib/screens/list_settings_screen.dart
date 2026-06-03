import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:handyshopper/data/item_columns.dart';
import 'package:handyshopper/localization/app_localizations.dart';
import 'package:handyshopper/models/shopping_list.dart';
import 'package:handyshopper/providers/list_provider.dart';
import 'package:provider/provider.dart';

/// Per-list settings: name, per-store prices, and tax configuration.
class ListSettingsScreen extends StatefulWidget {
  /// Creates a [ListSettingsScreen] editing [list].
  const ListSettingsScreen({required this.list, super.key});

  /// The list being edited.
  final ShoppingList list;

  @override
  State<ListSettingsScreen> createState() => _ListSettingsScreenState();
}

class _ListSettingsScreenState extends State<ListSettingsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _taxController;
  late final TextEditingController _tax2Controller;
  late bool _perStorePrices;
  late bool _tax2Enabled;
  late bool _taxInclusive;
  late int _columnFlags;

  /// Columns offered in the Columns section, with their labels.
  static const Map<ItemColumn, String> _columnKeys = {
    ItemColumn.quantity: 'quantity',
    ItemColumn.price: 'price',
    ItemColumn.priority: 'priority',
    ItemColumn.aisle: 'aisle',
    ItemColumn.date: 'date',
  };

  static final _rateFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'^\d*[.,]?\d{0,2}'),
  );

  @override
  void initState() {
    super.initState();
    final list = widget.list;
    _nameController = TextEditingController(text: list.name);
    _taxController = TextEditingController(
      text: list.taxRate == 0 ? '' : list.taxRate.toString(),
    );
    _tax2Controller = TextEditingController(
      text: list.tax2Rate == 0 ? '' : list.tax2Rate.toString(),
    );
    _perStorePrices = list.perStorePrices;
    _tax2Enabled = list.tax2Enabled;
    _taxInclusive = list.taxInclusive;
    _columnFlags = effectiveColumns(list.columnFlags);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taxController.dispose();
    _tax2Controller.dispose();
    super.dispose();
  }

  String _t(String key) => AppLocalizations.of(context).translate(key);

  double _parseRate(TextEditingController controller) {
    return double.tryParse(controller.text.replaceAll(',', '.'))
            ?.clamp(0, 100)
            .toDouble() ??
        0;
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    final provider = context.read<ListProvider>();
    final navigator = Navigator.of(context);
    widget.list
      ..name = name
      ..perStorePrices = _perStorePrices
      ..taxRate = _parseRate(_taxController)
      ..tax2Enabled = _tax2Enabled
      ..tax2Rate = _tax2Enabled ? _parseRate(_tax2Controller) : 0
      ..taxInclusive = _taxInclusive
      ..columnFlags = _columnFlags;
    await provider.saveList(widget.list);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('list_settings')),
        actions: [
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
            decoration: InputDecoration(labelText: _t('list_name')),
            inputFormatters: [LengthLimitingTextInputFormatter(64)],
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_t('per_store_prices')),
            value: _perStorePrices,
            onChanged: (value) =>
                setState(() => _perStorePrices = value ?? false),
          ),
          const Divider(),
          TextField(
            controller: _taxController,
            decoration: InputDecoration(labelText: _t('tax_rate')),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              _rateFormatter,
              LengthLimitingTextInputFormatter(6),
            ],
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_t('second_tax')),
            value: _tax2Enabled,
            onChanged: (value) => setState(() => _tax2Enabled = value ?? false),
          ),
          if (_tax2Enabled)
            TextField(
              controller: _tax2Controller,
              decoration: InputDecoration(labelText: _t('second_tax')),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                _rateFormatter,
                LengthLimitingTextInputFormatter(6),
              ],
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_t('tax_mode')),
            subtitle: Text(_taxInclusive ? _t('tax_included') : _t('tax_add')),
            value: _taxInclusive,
            onChanged: (value) => setState(() => _taxInclusive = value),
          ),
          const Divider(),
          Text(_t('columns')),
          for (final entry in _columnKeys.entries)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_t(entry.value)),
              value: hasColumn(_columnFlags, entry.key),
              onChanged: (value) => setState(
                () => _columnFlags = toggleColumn(
                  _columnFlags,
                  entry.key,
                  on: value ?? false,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
