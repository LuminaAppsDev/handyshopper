import 'package:flutter/material.dart';
import 'package:handyshopper/data/tax.dart';
import 'package:handyshopper/localization/app_localizations.dart';
import 'package:handyshopper/models/shopping_list.dart';
import 'package:handyshopper/providers/item_provider.dart';
import 'package:handyshopper/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// Tallies the needed items (subtotal, tax, total) and lets the user check out,
/// which marks those items purchased.
class CheckoutScreen extends StatelessWidget {
  /// Creates a [CheckoutScreen] for [list], pricing at [storeId] when set.
  const CheckoutScreen({required this.list, this.storeId, super.key});

  /// The list being checked out.
  final ShoppingList list;

  /// The selected store for per-store pricing, or `null` for the base price.
  final int? storeId;

  String _t(BuildContext context, String key) =>
      AppLocalizations.of(context).translate(key);

  String _money(String currency, double amount) =>
      '$currency${amount.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().currencySymbol;
    return Scaffold(
      appBar: AppBar(title: Text(_t(context, 'checkout'))),
      body: Consumer<ItemProvider>(
        builder: (context, provider, child) {
          final needed = provider.items.where((i) => i.need).toList();
          final breakdown = computeTax(
            list,
            needed,
            (item) => provider.priceFor(item, storeId) ?? 0,
          );
          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    for (final item in needed)
                      ListTile(
                        title: Text(item.name),
                        trailing: Text(
                          _money(
                            currency,
                            (provider.priceFor(item, storeId) ?? 0) *
                                item.quantity,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              _buildSummary(context, currency, breakdown),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: needed.isEmpty
                        ? null
                        : () async {
                            final navigator = Navigator.of(context);
                            await provider.markNeededPurchased();
                            navigator.pop();
                          },
                    child: Text(_t(context, 'mark_purchased')),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummary(
    BuildContext context,
    String currency,
    TaxBreakdown breakdown,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _row(_t(context, 'subtotal'), _money(currency, breakdown.subtotal)),
          if (breakdown.inclusive)
            _row(
              _t(context, 'includes_tax'),
              _money(currency, breakdown.totalTax),
            )
          else ...[
            _row(_t(context, 'tax'), _money(currency, breakdown.totalTax)),
          ],
          const SizedBox(height: 4),
          _row(
            _t(context, 'total'),
            _money(currency, breakdown.total),
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.bold) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
