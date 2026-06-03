import 'package:handyshopper/models/item.dart';
import 'package:handyshopper/models/shopping_list.dart';

/// Builds a human-readable, shareable text rendering of [list] and its [items].
///
/// Pure (no Flutter / IO dependencies) so it is trivially unit-testable. The
/// [currencySymbol] is prefixed to any item that has a price, and a total of
/// the needed items is appended.
String listToShareText(
  ShoppingList list,
  List<Item> items,
  String currencySymbol,
) {
  final buffer = StringBuffer()..writeln(list.name);

  if (items.isEmpty) {
    buffer
      ..writeln()
      ..write('(empty)');
    return buffer.toString();
  }

  buffer.writeln();
  for (final item in items) {
    final box = item.completed ? '[x]' : '[ ]';
    final quantity = _formatQuantity(item.quantity);
    final parts = <String>[item.name];
    if (quantity != '1') {
      parts.add('x$quantity');
    }
    if (item.price != null) {
      parts.add('$currencySymbol${item.price!.toStringAsFixed(2)}');
    }
    buffer.writeln('$box ${parts.join(' — ')}');
  }

  final total = items
      .where((i) => i.need)
      .fold<double>(0, (sum, i) => sum + (i.price ?? 0) * i.quantity);
  buffer
    ..writeln()
    ..write('Total: $currencySymbol${total.toStringAsFixed(2)}');

  return buffer.toString();
}

String _formatQuantity(double quantity) {
  return quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString();
}
