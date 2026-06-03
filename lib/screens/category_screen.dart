import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:handyshopper/localization/app_localizations.dart';
import 'package:handyshopper/models/category.dart';
import 'package:handyshopper/providers/category_provider.dart';
import 'package:handyshopper/widgets/emoji_picker.dart';
import 'package:provider/provider.dart';

/// Manages the categories of the active list: add, rename, set an emoji icon,
/// and delete.
class CategoryScreen extends StatelessWidget {
  /// Creates a [CategoryScreen].
  const CategoryScreen({super.key});

  String _t(BuildContext context, String key) =>
      AppLocalizations.of(context).translate(key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_t(context, 'edit_categories'))),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, child) {
          if (provider.categories.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _t(context, 'no_categories'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            );
          }
          return ListView(
            children: provider.categories.map((category) {
              return ListTile(
                leading: Text(
                  category.icon ?? '🏷️',
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(category.name),
                trailing: _buildMenu(context, provider, category),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => unawaited(_showCategoryDialog(context)),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMenu(
    BuildContext context,
    CategoryProvider provider,
    Category category,
  ) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'rename':
            unawaited(_showCategoryDialog(context, category: category));
          case 'icon':
            unawaited(_pickIcon(context, provider, category));
          case 'delete':
            unawaited(_confirmDelete(context, provider, category));
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: 'rename', child: Text(_t(context, 'rename'))),
        PopupMenuItem(value: 'icon', child: Text(_t(context, 'choose_icon'))),
        PopupMenuItem(
          value: 'delete',
          child: Text(_t(context, 'delete_category')),
        ),
      ],
    );
  }

  Future<void> _pickIcon(
    BuildContext context,
    CategoryProvider provider,
    Category category,
  ) async {
    final emoji = await showEmojiPicker(context);
    if (emoji == null) {
      return; // dismissed
    }
    await provider.setIcon(category.id!, emoji.isEmpty ? null : emoji);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CategoryProvider provider,
    Category category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t(dialogContext, 'delete_category')),
        content: Text(_t(dialogContext, 'delete_category_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(_t(dialogContext, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(_t(dialogContext, 'delete_category')),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await provider.deleteCategory(category.id!);
    }
  }

  /// Shows the add/rename dialog. When [category] is null it creates a new one
  /// (with an optional emoji); otherwise it renames the existing one.
  Future<void> _showCategoryDialog(
    BuildContext context, {
    Category? category,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _CategoryDialog(
        provider: context.read<CategoryProvider>(),
        category: category,
      ),
    );
  }
}

/// Add/rename category dialog. A [StatefulWidget] so its controller is disposed
/// only when the dialog is fully gone (avoids use-after-dispose during the
/// dismiss animation).
class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({required this.provider, this.category});

  final CategoryProvider provider;
  final Category? category;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _controller;
  late String? _icon;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.category?.name ?? '');
    _icon = widget.category?.icon;
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
    final category = widget.category;
    if (category == null) {
      unawaited(widget.provider.addCategory(name, icon: _icon));
    } else {
      unawaited(widget.provider.renameCategory(category.id!, name));
      if (_icon != category.icon) {
        unawaited(widget.provider.setIcon(category.id!, _icon));
      }
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_t(widget.category == null ? 'new_category' : 'rename')),
      content: Row(
        children: [
          TextButton(
            onPressed: () async {
              final picked = await showEmojiPicker(context);
              if (picked != null && mounted) {
                setState(() => _icon = picked.isEmpty ? null : picked);
              }
            },
            child: Text(_icon ?? '🏷️', style: const TextStyle(fontSize: 28)),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(labelText: _t('category_name')),
              inputFormatters: [LengthLimitingTextInputFormatter(40)],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_t('cancel')),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(_t(widget.category == null ? 'create' : 'update')),
        ),
      ],
    );
  }
}
