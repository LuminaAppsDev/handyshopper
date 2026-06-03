import 'package:flutter_test/flutter_test.dart';
import 'package:handyshopper/widgets/emoji_picker.dart';

void main() {
  test('curated emoji set is non-empty and has no duplicates', () {
    expect(kPickerEmojis, isNotEmpty);
    expect(kPickerEmojis.toSet().length, kPickerEmojis.length);
  });
}
