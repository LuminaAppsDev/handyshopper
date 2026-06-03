import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:handyshopper/localization/app_localizations.dart';
import 'package:handyshopper/models/store.dart';
import 'package:handyshopper/providers/store_provider.dart';
import 'package:provider/provider.dart';

/// Manages the stores of the active list: add, rename, and delete.
class StoreScreen extends StatelessWidget {
  /// Creates a [StoreScreen].
  const StoreScreen({super.key});

  String _t(BuildContext context, String key) =>
      AppLocalizations.of(context).translate(key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_t(context, 'edit_stores'))),
      body: Consumer<StoreProvider>(
        builder: (context, provider, child) {
          if (provider.stores.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _t(context, 'no_stores'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            );
          }
          return ListView(
            children: provider.stores.map((store) {
              return ListTile(
                leading: const Icon(Icons.store),
                title: Text(store.name),
                trailing: _buildMenu(context, provider, store),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => unawaited(_showStoreDialog(context)),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMenu(
    BuildContext context,
    StoreProvider provider,
    Store store,
  ) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'rename':
            unawaited(_showStoreDialog(context, store: store));
          case 'delete':
            unawaited(_confirmDelete(context, provider, store));
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'rename', child: Text(_t(context, 'rename'))),
        PopupMenuItem(
          value: 'delete',
          child: Text(_t(context, 'delete_store')),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    StoreProvider provider,
    Store store,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t(dialogContext, 'delete_store')),
        content: Text(_t(dialogContext, 'delete_store_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(_t(dialogContext, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(_t(dialogContext, 'delete_store')),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await provider.deleteStore(store.id!);
    }
  }

  /// Shows the add/rename dialog. Creates a store when [store] is null,
  /// otherwise renames it.
  Future<void> _showStoreDialog(
    BuildContext context, {
    Store? store,
  }) async {
    final provider = context.read<StoreProvider>();
    final controller = TextEditingController(text: store?.name ?? '');
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(
              _t(dialogContext, store == null ? 'new_store' : 'rename'),
            ),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: _t(dialogContext, 'store_name'),
              ),
              inputFormatters: [LengthLimitingTextInputFormatter(40)],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(_t(dialogContext, 'cancel')),
              ),
              TextButton(
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isEmpty) {
                    return;
                  }
                  if (store == null) {
                    unawaited(provider.addStore(name));
                  } else {
                    unawaited(provider.renameStore(store.id!, name));
                  }
                  Navigator.of(dialogContext).pop();
                },
                child: Text(
                  _t(dialogContext, store == null ? 'create' : 'update'),
                ),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }
}
