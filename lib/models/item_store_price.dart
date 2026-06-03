/// A per-store price and aisle for a specific item.
///
/// This is the join that powers price comparison: one row per
/// (item, store) pair.
class ItemStorePrice {
  /// Creates a new [ItemStorePrice].
  ItemStorePrice({
    required this.itemId,
    required this.storeId,
    this.id,
    this.price,
    this.aisle,
  });

  /// Creates an [ItemStorePrice] from a database row.
  factory ItemStorePrice.fromMap(Map<String, dynamic> map) => ItemStorePrice(
        id: map['id'] as int?,
        itemId: map['item_id'] as int,
        storeId: map['store_id'] as int,
        price: (map['price'] as num?)?.toDouble(),
        aisle: map['aisle'] as String?,
      );

  /// The unique identifier, or `null` before the row is persisted.
  int? id;

  /// The id of the item this price belongs to.
  int itemId;

  /// The id of the store this price applies to.
  int storeId;

  /// The price at this store, or `null` if unset.
  double? price;

  /// The aisle at this store, or `null` if unset.
  String? aisle;

  /// Converts this row to a database map.
  Map<String, dynamic> toMap() => {
        'id': id,
        'item_id': itemId,
        'store_id': storeId,
        'price': price,
        'aisle': aisle,
      };
}
