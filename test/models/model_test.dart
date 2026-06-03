import 'package:flutter_test/flutter_test.dart';
import 'package:handyshopper/models/item.dart';
import 'package:handyshopper/models/shopping_list.dart';

void main() {
  group('Item', () {
    test('fromMap/toMap round-trips all fields', () {
      final item = Item(
        id: 7,
        listId: 2,
        categoryId: 3,
        name: 'Cereal',
        quantity: 1.5,
        unit: 'lbs',
        price: 2.25,
        need: false,
        completed: true,
        note: 'crunchy',
        taxable: true,
        coupon: true,
        priority: 2,
        aisle: '5',
        sortOrder: 4,
      );

      final restored = Item.fromMap(item.toMap());

      expect(restored.id, 7);
      expect(restored.listId, 2);
      expect(restored.categoryId, 3);
      expect(restored.name, 'Cereal');
      expect(restored.quantity, 1.5);
      expect(restored.unit, 'lbs');
      expect(restored.price, 2.25);
      expect(restored.need, isFalse);
      expect(restored.completed, isTrue);
      expect(restored.note, 'crunchy');
      expect(restored.taxable, isTrue);
      expect(restored.coupon, isTrue);
      expect(restored.priority, 2);
      expect(restored.aisle, '5');
      expect(restored.sortOrder, 4);
    });

    test('clamps an out-of-range priority into [1, 5]', () {
      expect(
        Item.fromMap({'list_id': 1, 'name': 'x', 'priority': 0}).priority,
        1,
      );
      expect(
        Item.fromMap({'list_id': 1, 'name': 'x', 'priority': 99}).priority,
        5,
      );
    });
  });

  group('ShoppingList', () {
    test('fromMap/toMap round-trips tax fields', () {
      final list = ShoppingList(
        id: 3,
        name: 'Groceries',
        taxRate: 19,
        tax2Rate: 7,
        tax2Enabled: true,
        taxInclusive: true,
      );
      final restored = ShoppingList.fromMap(list.toMap());
      expect(restored.name, 'Groceries');
      expect(restored.taxRate, 19);
      expect(restored.tax2Rate, 7);
      expect(restored.tax2Enabled, isTrue);
      expect(restored.taxInclusive, isTrue);
    });
  });

  group('ListStyle', () {
    test('maps valid indices', () {
      expect(listStyleFromIndex(0), ListStyle.shopping);
      expect(listStyleFromIndex(3), ListStyle.checklist);
    });

    test('falls back to shopping for out-of-range indices', () {
      expect(listStyleFromIndex(-1), ListStyle.shopping);
      expect(listStyleFromIndex(99), ListStyle.shopping);
    });
  });
}
