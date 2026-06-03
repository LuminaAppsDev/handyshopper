import 'package:flutter/material.dart';
import 'package:handyshopper/localization/app_localizations.dart';

/// A curated set of grocery / household emojis offered as category and list
/// icons. Deliberately a fixed, dependency-free set rather than the full
/// Unicode catalog — predictable across devices and easy to extend.
const List<String> kPickerEmojis = [
  '🛒',
  '🧺',
  '🛍️',
  '🥦',
  '🥕',
  '🍎',
  '🍌',
  '🍓',
  '🍇',
  '🍅',
  '🥬',
  '🥔',
  '🧅',
  '🌽',
  '🍞',
  '🥐',
  '🥖',
  '🧀',
  '🥚',
  '🥛',
  '🧈',
  '🍗',
  '🥩',
  '🐟',
  '🍤',
  '🍚',
  '🍝',
  '🥫',
  '🧂',
  '🌶️',
  '☕',
  '🍵',
  '🧃',
  '🍷',
  '🍺',
  '💧',
  '🍫',
  '🍪',
  '🍰',
  '🍦',
  '🧁',
  '🍿',
  '🧊',
  '🧹',
  '🧼',
  '🧽',
  '🧻',
  '🪥',
  '🧴',
  '🧷',
  '💊',
  '🩹',
  '🐾',
  '🌷',
  '🔋',
  '💡',
  '📦',
  '🎁',
  '🏠',
  '🚗',
];

/// Shows a modal grid of [kPickerEmojis] plus a "none" option. Resolves to the
/// chosen emoji, an empty string for "none", or `null` if dismissed.
Future<String?> showEmojiPicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(''),
                  child: Text(
                    AppLocalizations.of(sheetContext).translate('none'),
                  ),
                ),
              ),
              Flexible(
                child: GridView.count(
                  crossAxisCount: 6,
                  shrinkWrap: true,
                  children: kPickerEmojis.map((emoji) {
                    return InkWell(
                      onTap: () => Navigator.of(sheetContext).pop(emoji),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
