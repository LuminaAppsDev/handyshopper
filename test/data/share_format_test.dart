import 'package:flutter_test/flutter_test.dart';
import 'package:handyshopper/data/share_format.dart';
import 'package:handyshopper/models/item.dart';
import 'package:handyshopper/models/shopping_list.dart';

void main() {
  final list = ShoppingList(id: 1, name: 'Groceries');

  test('renders title, items, quantities, prices and a total', () {
    final text = listToShareText(
      list,
      [
        Item(listId: 1, name: 'Milk', price: 0.95, quantity: 2),
        Item(listId: 1, name: 'Cereal', price: 2.25, completed: true),
      ],
      r'$',
    );

    expect(text, contains('Groceries'));
    expect(text, contains(r'[ ] Milk — x2 — $0.95'));
    expect(text, contains(r'[x] Cereal — $2.25')); // completed marker
    // Total = 0.95*2 + 2.25 = 4.15 (both are needed by default).
    expect(text, contains(r'Total: $4.15'));
  });

  test('renders an empty marker for a list with no items', () {
    final text = listToShareText(list, [], r'$');
    expect(text, contains('Groceries'));
    expect(text, contains('(empty)'));
  });

  test('excludes not-needed items from the total', () {
    final text = listToShareText(
      list,
      [
        Item(listId: 1, name: 'Milk', price: 1),
        Item(listId: 1, name: 'Soap', price: 5, need: false),
      ],
      r'$',
    );
    expect(text, contains(r'Total: $1.00'));
  });
}
