class Product {
  final String id;
  final String name;
  final double price;
  final String categoryId;
  final int stock;
  final String? description;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    required this.stock,
    this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'نامشخص',
      price: (json['price'] ?? 0).toDouble(),
      categoryId: json['category']?['_id'] ?? '',
      stock: json['stock'] ?? 0,
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'price': price,
      'category': categoryId,
      'stock': stock,
      'description': description,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          price == other.price &&
          categoryId == other.categoryId &&
          stock == other.stock &&
          description == other.description;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      price.hashCode ^
      categoryId.hashCode ^
      stock.hashCode ^
      description.hashCode;
}
