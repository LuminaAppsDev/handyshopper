/// A category within a list, used to group and filter items.
class Category {
  /// Creates a new [Category].
  Category({
    required this.listId,
    required this.name,
    this.id,
    this.icon,
    this.sortOrder = 0,
  });

  /// Creates a [Category] from a database row.
  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as int?,
        listId: map['list_id'] as int,
        name: map['name'] as String,
        icon: map['icon'] as String?,
        sortOrder: map['sort_order'] as int? ?? 0,
      );

  /// The unique identifier, or `null` before the category is persisted.
  int? id;

  /// The id of the owning list.
  int listId;

  /// The category name.
  String name;

  /// The icon identifier, or `null` for none.
  String? icon;

  /// The manual sort position within the owning list.
  int sortOrder;

  /// Converts this category to a database row.
  Map<String, dynamic> toMap() => {
        'id': id,
        'list_id': listId,
        'name': name,
        'icon': icon,
        'sort_order': sortOrder,
      };
}
