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
    final provider = context.read<CategoryProvider>();
    final controller = TextEditingController(text: category?.name ?? '');
    var icon = category?.icon;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setLocalState) {
              return AlertDialog(
                title: Text(
                  _t(
                    dialogContext,
                    category == null ? 'new_category' : 'rename',
                  ),
                ),
                content: Row(
                  children: [
                    TextButton(
                      onPressed: () async {
                        final picked = await showEmojiPicker(dialogContext);
                        if (picked != null) {
                          setLocalState(
                            () => icon = picked.isEmpty ? null : picked,
                          );
                        }
                      },
                      child: Text(
                        icon ?? '🏷️',
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: _t(dialogContext, 'category_name'),
                        ),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(40),
                        ],
                      ),
                    ),
                  ],
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
                      if (category == null) {
                        unawaited(provider.addCategory(name, icon: icon));
                      } else {
                        unawaited(provider.renameCategory(category.id!, name));
                        if (icon != category.icon) {
                          unawaited(provider.setIcon(category.id!, icon));
                        }
                      }
                      Navigator.of(dialogContext).pop();
                    },
                    child: Text(
                      _t(
                        dialogContext,
                        category == null ? 'create' : 'update',
                      ),
                    ),
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
}
