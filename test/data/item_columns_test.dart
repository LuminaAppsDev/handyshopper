import 'package:flutter_test/flutter_test.dart';
import 'package:handyshopper/data/item_columns.dart';

void main() {
  test('flags == 0 resolves to the default (quantity + price)', () {
    expect(effectiveColumns(0), kDefaultColumns);
    expect(hasColumn(0, ItemColumn.quantity), isTrue);
    expect(hasColumn(0, ItemColumn.price), isTrue);
    expect(hasColumn(0, ItemColumn.priority), isFalse);
  });

  test('toggleColumn turns columns on and off', () {
    var flags = kDefaultColumns;
    flags = toggleColumn(flags, ItemColumn.priority, on: true);
    expect(hasColumn(flags, ItemColumn.priority), isTrue);
    expect(hasColumn(flags, ItemColumn.quantity), isTrue); // unchanged

    flags = toggleColumn(flags, ItemColumn.price, on: false);
    expect(hasColumn(flags, ItemColumn.price), isFalse);
    expect(hasColumn(flags, ItemColumn.priority), isTrue);
  });

  test('turning everything off keeps a non-zero marker (not the default)', () {
    var flags = kDefaultColumns;
    for (final column in ItemColumn.values) {
      flags = toggleColumn(flags, column, on: false);
    }
    // Must not collapse to 0 (which would re-expand to the default set).
    expect(flags, isNot(0));
    expect(effectiveColumns(flags), isNot(kDefaultColumns));
  });
}
