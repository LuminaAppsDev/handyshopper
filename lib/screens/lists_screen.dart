import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:handyshopper/data/database_service.dart';
import 'package:handyshopper/data/share_format.dart';
import 'package:handyshopper/localization/app_localizations.dart';
import 'package:handyshopper/models/shopping_list.dart';
import 'package:handyshopper/providers/list_provider.dart';
import 'package:handyshopper/providers/settings_provider.dart';
import 'package:handyshopper/screens/item_list_screen.dart';
import 'package:handyshopper/screens/list_settings_screen.dart';
import 'package:handyshopper/services/share_service.dart';
import 'package:handyshopper/settings_screen.dart';
import 'package:handyshopper/widgets/emoji_picker.dart';
import 'package:provider/provider.dart';

/// The home screen: the collection of lists ("databases").
///
/// Tapping a list opens its items; per-list and app-wide actions (rename, copy,
/// delete, share, export, back up, restore) are exposed here.
class ListsScreen extends StatefulWidget {
  /// Creates a [ListsScreen].
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  String _t(String key) => AppLocalizations.of(context).translate(key);

  IconData _iconFor(ListStyle style) {
    switch (style) {
      case ListStyle.shopping:
        return Icons.shopping_cart;
      case ListStyle.todo:
        return Icons.checklist;
      case ListStyle.dated:
        return Icons.event;
      case ListStyle.checklist:
        return Icons.check_box;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          AppLocalizations.of(context).translate('title'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'backup') {
                unawaited(_backupAll());
              } else if (value == 'restore') {
                unawaited(_restore());
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'backup', child: Text(_t('backup_all'))),
              PopupMenuItem(value: 'restore', child: Text(_t('restore'))),
            ],
          ),
        ],
      ),
      body: Consumer<ListProvider>(
        builder: (context, provider, child) {
          if (provider.lists.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _t('no_databases'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            );
          }
          return ListView(
            children: provider.lists.map((list) {
              return ListTile(
                leading: list.icon == null
                    ? Icon(_iconFor(list.style))
                    : Text(
                        list.icon!,
                        style: const TextStyle(fontSize: 24),
                      ),
                title: Text(list.name),
                trailing: _buildListMenu(list),
                onTap: () => unawaited(_openList(list)),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => unawaited(_showNewListDialog()),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListMenu(ShoppingList list) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'edit':
            unawaited(
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => ListSettingsScreen(list: list),
                ),
              ),
            );
          case 'icon':
            unawaited(_pickListIcon(list));
          case 'copy':
            unawaited(context.read<ListProvider>().copyList(list.id!));
          case 'delete':
            unawaited(_confirmDelete(list));
          case 'share':
            unawaited(_shareListText(list));
          case 'export':
            unawaited(_exportList(list));
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'edit', child: Text(_t('edit_list'))),
        PopupMenuItem(value: 'icon', child: Text(_t('choose_icon'))),
        PopupMenuItem(value: 'copy', child: Text(_t('copy'))),
        PopupMenuItem(value: 'delete', child: Text(_t('delete_list'))),
        PopupMenuItem(value: 'share', child: Text(_t('share_as_text'))),
        PopupMenuItem(value: 'export', child: Text(_t('export_file'))),
      ],
    );
  }

  Future<void> _openList(ShoppingList list) async {
    await context.read<ListProvider>().setActive(list.id!);
    if (!mounted) {
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => const ItemListScreen()),
    );
  }

  Future<void> _showNewListDialog() async {
    final controller = TextEditingController();
    var style = ListStyle.shopping;
    var perStorePrices = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setLocalState) {
              return AlertDialog(
                title: Text(_t('new_list')),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: InputDecoration(labelText: _t('list_name')),
                      inputFormatters: [LengthLimitingTextInputFormatter(64)],
                    ),
                    const SizedBox(height: 12),
                    DropdownButton<ListStyle>(
                      isExpanded: true,
                      value: style,
                      onChanged: (value) =>
                          setLocalState(() => style = value ?? style),
                      items: [
                        DropdownMenuItem(
                          value: ListStyle.shopping,
                          child: Text(_t('style_shopping')),
                        ),
                        DropdownMenuItem(
                          value: ListStyle.todo,
                          child: Text(_t('style_todo')),
                        ),
                        DropdownMenuItem(
                          value: ListStyle.dated,
                          child: Text(_t('style_dated')),
                        ),
                        DropdownMenuItem(
                          value: ListStyle.checklist,
                          child: Text(_t('style_checklist')),
                        ),
                      ],
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_t('per_store_prices')),
                      value: perStorePrices,
                      onChanged: (value) =>
                          setLocalState(() => perStorePrices = value ?? false),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(_t('cancel')),
                  ),
                  TextButton(
                    onPressed: () {
                      final name = controller.text.trim();
                      if (name.isEmpty) {
                        return;
                      }
                      unawaited(
                        context.read<ListProvider>().createList(
                              name,
                              style: style,
                              perStorePrices: perStorePrices,
                            ),
                      );
                      Navigator.of(dialogContext).pop();
                    },
                    child: Text(_t('create')),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _pickListIcon(ShoppingList list) async {
    final provider = context.read<ListProvider>();
    final emoji = await showEmojiPicker(context);
    if (emoji == null) {
      return; // dismissed
    }
    await provider.setIcon(list.id!, emoji.isEmpty ? null : emoji);
  }

  Future<void> _confirmDelete(ShoppingList list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(_t('delete_list')),
          content: Text(_t('delete_list_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(_t('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(_t('delete_list')),
            ),
          ],
        );
      },
    );
    if (confirmed ?? false) {
      if (!mounted) {
        return;
      }
      await context.read<ListProvider>().deleteList(list.id!);
    }
  }

  Future<void> _shareListText(ShoppingList list) async {
    final db = context.read<DatabaseService>();
    final share = context.read<ShareService>();
    final currency = context.read<SettingsProvider>().currencySymbol;
    final items = await db.getItems(list.id!);
    await share.shareText(listToShareText(list, items, currency));
  }

  Future<void> _exportList(ShoppingList list) async {
    final db = context.read<DatabaseService>();
    final share = context.read<ShareService>();
    final data = await db.exportData(listIds: [list.id!]);
    await share.shareJsonFile(
      'handyshopper_${_safeFileName(list.name)}.json',
      const JsonEncoder.withIndent('  ').convert(data),
    );
  }

  Future<void> _backupAll() async {
    final db = context.read<DatabaseService>();
    final share = context.read<ShareService>();
    final data = await db.exportData();
    await share.shareJsonFile(
      'handyshopper_backup.json',
      const JsonEncoder.withIndent('  ').convert(data),
    );
  }

  Future<void> _restore() async {
    final db = context.read<DatabaseService>();
    final share = context.read<ShareService>();
    final listProvider = context.read<ListProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final importedLabel = _t('imported_lists');
    final failedLabel = _t('import_failed');

    final data = await share.pickJsonData();
    if (data == null) {
      return;
    }
    try {
      final count = await db.importData(data);
      await listProvider.load();
      messenger.showSnackBar(
        SnackBar(content: Text('$importedLabel: $count')),
      );
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(failedLabel)));
    }
  }

  String _safeFileName(String name) {
    final sanitized = name.replaceAll(RegExp('[^A-Za-z0-9_-]'), '_');
    // Cap the length so an over-long (e.g. imported) list name can't produce a
    // path beyond filesystem limits.
    return sanitized.length <= 64 ? sanitized : sanitized.substring(0, 64);
  }
}
