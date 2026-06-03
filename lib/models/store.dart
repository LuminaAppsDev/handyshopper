/// A store within a list, used for per-store price comparison.
class Store {
  /// Creates a new [Store].
  Store({
    required this.listId,
    required this.name,
    this.id,
    this.sortOrder = 0,
  });

  /// Creates a [Store] from a database row.
  factory Store.fromMap(Map<String, dynamic> map) => Store(
        id: map['id'] as int?,
        listId: map['list_id'] as int,
        name: map['name'] as String,
        sortOrder: map['sort_order'] as int? ?? 0,
      );

  /// The unique identifier, or `null` before the store is persisted.
  int? id;

  /// The id of the owning list.
  int listId;

  /// The store name.
  String name;

  /// The manual sort position within the owning list.
  int sortOrder;

  /// Converts this store to a database row.
  Map<String, dynamic> toMap() => {
        'id': id,
        'list_id': listId,
        'name': name,
        'sort_order': sortOrder,
      };
}
