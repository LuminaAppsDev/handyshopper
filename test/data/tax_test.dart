import 'package:flutter_test/flutter_test.dart';
import 'package:handyshopper/data/tax.dart';
import 'package:handyshopper/models/item.dart';
import 'package:handyshopper/models/shopping_list.dart';

void main() {
  double priceOf(Item item) => item.price ?? 0;

  List<Item> items() => [
        Item(listId: 1, name: 'Taxed', price: 10, taxable: true),
        Item(listId: 1, name: 'Untaxed', price: 5),
      ];

  test('exclusive: tax is added on top of the subtotal', () {
    final list = ShoppingList(name: 'L', taxRate: 10);
    final b = computeTax(list, items(), priceOf);

    expect(b.subtotal, 15.0);
    expect(b.taxableSubtotal, 10.0);
    expect(b.tax1, 1.0); // 10% of the taxable 10
    expect(b.tax2, 0.0);
    expect(b.total, 16.0); // 15 + 1
    expect(b.inclusive, isFalse);
  });

  test('exclusive: second tax adds on top too', () {
    final list = ShoppingList(name: 'L', taxRate: 10, tax2Rate: 5)
      ..tax2Enabled = true;
    final b = computeTax(list, items(), priceOf);
    expect(b.tax1, 1.0);
    expect(b.tax2, closeTo(0.5, 1e-9)); // 5% of 10
    expect(b.total, closeTo(16.5, 1e-9));
  });

  test('inclusive: tax is broken out, total unchanged', () {
    final list = ShoppingList(name: 'L', taxRate: 20, taxInclusive: true);
    final b = computeTax(list, items(), priceOf);

    expect(b.subtotal, 15.0);
    expect(b.total, 15.0); // tax already included
    // Embedded tax in the taxable 10 at 20%: 10 - 10/1.2 = 1.6667.
    expect(b.totalTax, closeTo(10 - 10 / 1.2, 1e-9));
    expect(b.inclusive, isTrue);
  });

  test('zero rate yields no tax', () {
    final list = ShoppingList(name: 'L');
    final b = computeTax(list, items(), priceOf);
    expect(b.tax1, 0.0);
    expect(b.tax2, 0.0);
    expect(b.total, 15.0);
  });
}
