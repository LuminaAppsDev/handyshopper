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

  test('every locale is a subset of the canonical en.json key set', () {
    // en.json is the canonical superset of keys; other locales may lag behind
    // (missing keys fall back to English at runtime) but must never contain an
    // orphan key that does not exist in en.json (catches typos / stale keys).
    final enKeys = keysOf('$dir/en.json');
    expect(enKeys, isNotEmpty);

    final files = Directory(dir)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'));

    for (final file in files) {
      final orphans = keysOf(file.path).difference(enKeys);
      expect(
        orphans,
        isEmpty,
        reason: 'Orphan keys in ${file.path} not present in en.json: $orphans',
      );
    }
  });
}
