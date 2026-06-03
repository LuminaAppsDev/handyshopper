/// An item belonging to a shopping list.
///
/// This supersedes the former `Product` model. It carries the full set of
/// fields required for Palm-parity features (notes, tax, priority, aisle,
/// units, alarms, etc.); Phase 0 only populates a subset and lets the rest
/// fall back to their defaults.
class Item {
  /// Creates a new [Item].
  Item({
    required this.listId,
    required this.name,
    this.id,
    this.categoryId,
    this.quantity = 1,
    this.unit,
    this.price,
    this.need = true,
    this.completed = false,
    this.note,
    this.taxable = false,
    this.coupon = false,
    this.priority = 3,
    this.aisle,
    this.itemDate,
    this.autoDelete = false,
    this.private = false,
    this.customText,
    this.alarmAt,
    this.alarmSound,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates an [Item] from a database row.
  factory Item.fromMap(Map<String, dynamic> map) => Item(
        id: map['id'] as int?,
        listId: map['list_id'] as int,
        categoryId: map['category_id'] as int?,
        name: map['name'] as String,
        quantity: (map['quantity'] as num?)?.toDouble() ?? 1,
        unit: map['unit'] as String?,
        price: (map['price'] as num?)?.toDouble(),
        need: (map['need'] as int? ?? 1) == 1,
        completed: (map['completed'] as int? ?? 0) == 1,
        note: map['note'] as String?,
        taxable: (map['taxable'] as int? ?? 0) == 1,
        coupon: (map['coupon'] as int? ?? 0) == 1,
        priority: (map['priority'] as int? ?? 3).clamp(1, 5),
        aisle: map['aisle'] as String?,
        itemDate: map['item_date'] as int?,
        autoDelete: (map['auto_delete'] as int? ?? 0) == 1,
        private: (map['private'] as int? ?? 0) == 1,
        customText: map['custom_text'] as String?,
        alarmAt: map['alarm_at'] as int?,
        alarmSound: map['alarm_sound'] as String?,
        sortOrder: map['sort_order'] as int? ?? 0,
        createdAt: map['created_at'] as int?,
        updatedAt: map['updated_at'] as int?,
      );

  /// The unique identifier, or `null` before the item is persisted.
  int? id;

  /// The id of the owning list.
  int listId;

  /// The id of the assigned category, or `null` if uncategorized.
  int? categoryId;

  /// The item name.
  String name;

  /// The quantity of the item.
  double quantity;

  /// The unit of measure (e.g. `lbs`, `ozs`), or `null` for none.
  String? unit;

  /// The base price, or `null` if unpriced.
  double? price;

  /// Whether the item is on the need list.
  bool need;

  /// Whether the item has been purchased / checked off.
  bool completed;

  /// A free-text note attached to the item.
  String? note;

  /// Whether the item is subject to tax.
  bool taxable;

  /// Whether a coupon applies to the item.
  bool coupon;

  /// The priority from 1 (highest) to 5 (lowest).
  int priority;

  /// The default aisle, or `null` if unset.
  String? aisle;

  /// An associated date as epoch milliseconds, or `null`.
  int? itemDate;

  /// Whether the item is removed automatically after purchase.
  bool autoDelete;

  /// Whether the item is marked private.
  bool private;

  /// Optional user-defined custom text.
  String? customText;

  /// The alarm time as epoch milliseconds, or `null` for no alarm.
  int? alarmAt;

  /// The alarm sound identifier, or `null` for the default.
  String? alarmSound;

  /// The manual sort position within the owning list.
  int sortOrder;

  /// Creation time as epoch milliseconds, or `null` if not recorded.
  int? createdAt;

  /// Last-update time as epoch milliseconds, or `null` if not recorded.
  int? updatedAt;

  /// Converts this item to a database row.
  Map<String, dynamic> toMap() => {
        'id': id,
        'list_id': listId,
        'category_id': categoryId,
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'price': price,
        'need': need ? 1 : 0,
        'completed': completed ? 1 : 0,
        'note': note,
        'taxable': taxable ? 1 : 0,
        'coupon': coupon ? 1 : 0,
        'priority': priority,
        'aisle': aisle,
        'item_date': itemDate,
        'auto_delete': autoDelete ? 1 : 0,
        'private': private ? 1 : 0,
        'custom_text': customText,
        'alarm_at': alarmAt,
        'alarm_sound': alarmSound,
        'sort_order': sortOrder,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}
