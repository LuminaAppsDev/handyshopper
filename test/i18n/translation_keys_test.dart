import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards against translation drift: every language file must expose exactly
/// the same set of keys as the canonical `en.json`. As keys grow in later
/// phases this catches a file that was forgotten or mistyped.
void main() {
  const dir = 'assets/translations';

  Set<String> keysOf(String path) {
    final json = jsonDecode(File(path).readAsStringSync()) as Map;
    return json.keys.cast<String>().toSet();
  }

  test('every locale has exactly the canonical en.json key set', () {
    // All locales are fully translated, so each must match en.json's keys
    // exactly — no missing keys (untranslated) and no orphans (typos/stale).
    final enKeys = keysOf('$dir/en.json');
    expect(enKeys, isNotEmpty);

    final files = Directory(dir)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'));

    for (final file in files) {
      final keys = keysOf(file.path);
      expect(
        keys,
        enKeys,
        reason: '${file.path}: missing ${enKeys.difference(keys)}, '
            'orphan ${keys.difference(enKeys)}',
      );
    }
  });
}
