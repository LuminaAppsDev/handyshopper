import 'package:handyshopper/models/item.dart';
import 'package:handyshopper/models/shopping_list.dart';

/// The result of a tax computation over a set of items.
class TaxBreakdown {
  /// Creates a [TaxBreakdown].
  const TaxBreakdown({
    required this.subtotal,
    required this.taxableSubtotal,
    required this.tax1,
    required this.tax2,
    required this.total,
    required this.inclusive,
  });

  /// Sum of all item prices × quantities.
  final double subtotal;

  /// Subtotal restricted to taxable items.
  final double taxableSubtotal;

  /// The primary tax amount.
  final double tax1;

  /// The secondary tax amount (0 when the second tax is disabled).
  final double tax2;

  /// The grand total. For inclusive lists this equals [subtotal]; for exclusive
  /// lists it is [subtotal] + [tax1] + [tax2].
  final double total;

  /// Whether the prices already included tax (VAT broken out) rather than tax
  /// being added on top.
  final bool inclusive;

  /// The combined tax amount.
  double get totalTax => tax1 + tax2;
}

/// Computes the tax breakdown for [items] under [list]'s tax settings, using
/// [priceOf] to resolve each item's effective unit price.
///
/// Pure (no Flutter / IO) so it is trivially unit-testable. Exclusive lists add
/// tax on top of the subtotal; inclusive lists break the embedded tax out of a
/// subtotal that already contains it.
TaxBreakdown computeTax(
  ShoppingList list,
  List<Item> items,
  double Function(Item) priceOf,
) {
  var subtotal = 0.0;
  var taxableSubtotal = 0.0;
  for (final item in items) {
    final line = priceOf(item) * item.quantity;
    subtotal += line;
    if (item.taxable) {
      taxableSubtotal += line;
    }
  }

  final rate1 = list.taxRate / 100;
  final rate2 = list.tax2Enabled ? list.tax2Rate / 100 : 0.0;

  double tax1;
  double tax2;
  double total;
  if (list.taxInclusive) {
    // Prices already include the combined tax; break it back out pro-rata.
    final combined = rate1 + rate2;
    final embedded =
        combined == 0 ? 0.0 : taxableSubtotal * combined / (1 + combined);
    tax1 = combined == 0 ? 0.0 : embedded * (rate1 / combined);
    tax2 = embedded - tax1;
    total = subtotal;
  } else {
    tax1 = taxableSubtotal * rate1;
    tax2 = taxableSubtotal * rate2;
    total = subtotal + tax1 + tax2;
  }

  return TaxBreakdown(
    subtotal: subtotal,
    taxableSubtotal: taxableSubtotal,
    tax1: tax1,
    tax2: tax2,
    total: total,
    inclusive: list.taxInclusive,
  );
}
