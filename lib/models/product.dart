class Product {
  // Define the fields of the Product class
  int? id; // The unique identifier for the product
  String name; // The name of the product
  int quantity; // The quantity of the product
  double? price; // The price of the product (optional)
  bool need; // Indicates whether the product is needed

  // Constructor for the Product class
  Product({
    this.id,
    required this.name,
    required this.quantity,
    this.price,
    required this.need,
  });

  // Create a Product object from a map (used when retrieving data from the database)
  factory Product.fromMap(Map<String, dynamic> json) => Product(
        id: json['id'],
        name: json['name'],
        quantity: json['quantity'],
        price: json['price'],
        need: json['need'] == 1, // Convert integer to boolean
      );

  // Convert a Product object to a map (used when inserting or updating data in the database)
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'price': price,
        'need': need ? 1 : 0, // Convert boolean to integer
      };
}
