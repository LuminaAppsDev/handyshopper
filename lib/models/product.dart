/// A product in the shopping list.
class Product {
  /// Creates a new [Product].
  Product({
    required this.name,
    required this.quantity,
    required this.need,
    this.id,
    this.price,
  });

  /// Creates a [Product] from a database map.
  factory Product.fromMap(Map<String, dynamic> json) => Product(
        id: json['id'] as int?,
        name: json['name'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        price: (json['price'] as num?)?.toDouble(),
        need: json['need'] == 1,
      );

  /// The unique identifier for the product.
  int? id;

  /// The name of the product.
  String name;

  /// The quantity of the product.
  double quantity;

  /// The price of the product (optional).
  double? price;

  /// Whether the product is needed.
  bool need;

  /// Converts this [Product] to a database map.
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'price': price,
        'need': need ? 1 : 0,
      };
}
