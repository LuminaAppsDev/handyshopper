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
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _StoreDialog(
        provider: context.read<StoreProvider>(),
        store: store,
      ),
    );
  }
}

/// Add/rename store dialog. A [StatefulWidget] so its controller is disposed
/// only when the dialog is fully gone (avoids use-after-dispose during the
/// dismiss animation).
class _StoreDialog extends StatefulWidget {
  const _StoreDialog({required this.provider, this.store});

  final StoreProvider provider;
  final Store? store;

  @override
  State<_StoreDialog> createState() => _StoreDialogState();
}

class _StoreDialogState extends State<_StoreDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.store?.name ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _t(String key) => AppLocalizations.of(context).translate(key);

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      return;
    }
    final store = widget.store;
    if (store == null) {
      unawaited(widget.provider.addStore(name));
    } else {
      unawaited(widget.provider.renameStore(store.id!, name));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_t(widget.store == null ? 'new_store' : 'rename')),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: _t('store_name')),
        inputFormatters: [LengthLimitingTextInputFormatter(40)],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_t('cancel')),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(_t(widget.store == null ? 'create' : 'update')),
        ),
      ],
    );
  }
}
