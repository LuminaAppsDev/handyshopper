/// The style of a list, mirroring the Palm "database style" options.
enum ListStyle {
  /// A shopping list (prices, stores, checkout).
  shopping,

  /// A to-do list.
  todo,

  /// A dated list.
  dated,

  /// A simple check list.
  checklist,
}

/// Returns the [ListStyle] for [index], falling back to [ListStyle.shopping]
/// when the stored value is out of range (e.g. written by a newer schema).
ListStyle listStyleFromIndex(int index) =>
    (index >= 0 && index < ListStyle.values.length)
        ? ListStyle.values[index]
        : ListStyle.shopping;

/// A list (a "database" in Palm terminology) that owns items, categories,
/// and stores.
///
/// Named [ShoppingList] to avoid clashing with the core Dart `List` type.
class ShoppingList {
  /// Creates a new [ShoppingList].
  ShoppingList({
    required this.name,
    this.id,
    this.icon,
    this.style = ListStyle.shopping,
    this.perStorePrices = false,
    this.currencySymbol,
    this.taxRate = 0,
    this.tax2Rate = 0,
    this.tax2Enabled = false,
    this.defaultPriority = 3,
    this.sortPrimary = 'manual',
    this.sortSecondary,
    this.sortDescending = false,
    this.learnOrder = false,
    this.columnFlags = 0,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates a [ShoppingList] from a database row.
  factory ShoppingList.fromMap(Map<String, dynamic> map) => ShoppingList(
        id: map['id'] as int?,
        name: map['name'] as String,
        icon: map['icon'] as String?,
        style: listStyleFromIndex(map['style'] as int? ?? 0),
        perStorePrices: (map['per_store_prices'] as int? ?? 0) == 1,
        currencySymbol: map['currency_symbol'] as String?,
        taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0,
        tax2Rate: (map['tax2_rate'] as num?)?.toDouble() ?? 0,
        tax2Enabled: (map['tax2_enabled'] as int? ?? 0) == 1,
        defaultPriority: map['default_priority'] as int? ?? 3,
        sortPrimary: map['sort_primary'] as String? ?? 'manual',
        sortSecondary: map['sort_secondary'] as String?,
        sortDescending: (map['sort_descending'] as int? ?? 0) == 1,
        learnOrder: (map['learn_order'] as int? ?? 0) == 1,
        columnFlags: map['column_flags'] as int? ?? 0,
        sortOrder: map['sort_order'] as int? ?? 0,
        createdAt: map['created_at'] as int?,
        updatedAt: map['updated_at'] as int?,
      );

  /// The unique identifier, or `null` before the list is persisted.
  int? id;

  /// The list name.
  String name;

  /// The icon identifier, or `null` for the default.
  String? icon;

  /// The list style.
  ListStyle style;

  /// Whether per-store prices and aisles are enabled.
  bool perStorePrices;

  /// A per-list currency symbol override, or `null` to use the app default.
  String? currencySymbol;

  /// The primary tax rate as a percentage.
  double taxRate;

  /// The secondary tax rate as a percentage.
  double tax2Rate;

  /// Whether the secondary tax is enabled.
  bool tax2Enabled;

  /// The default priority assigned to new items.
  int defaultPriority;

  /// The primary sort field key (e.g. `manual`, `alphabetical`).
  String sortPrimary;

  /// The secondary sort field key, or `null` for none.
  String? sortSecondary;

  /// Whether the sort is descending.
  bool sortDescending;

  /// Whether "learn shopping order" is enabled.
  bool learnOrder;

  /// A bitfield controlling which columns are visible.
  int columnFlags;

  /// The manual sort position of this list among other lists.
  int sortOrder;

  /// Creation time as epoch milliseconds, or `null` if not recorded.
  int? createdAt;

  /// Last-update time as epoch milliseconds, or `null` if not recorded.
  int? updatedAt;

  /// Converts this list to a database row.
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'style': style.index,
        'per_store_prices': perStorePrices ? 1 : 0,
        'currency_symbol': currencySymbol,
        'tax_rate': taxRate,
        'tax2_rate': tax2Rate,
        'tax2_enabled': tax2Enabled ? 1 : 0,
        'default_priority': defaultPriority,
        'sort_primary': sortPrimary,
        'sort_secondary': sortSecondary,
        'sort_descending': sortDescending ? 1 : 0,
        'learn_order': learnOrder ? 1 : 0,
        'column_flags': columnFlags,
        'sort_order': sortOrder,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}
