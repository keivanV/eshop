import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final String categoryId;
  final int stock;
  final String? description;
  final List<String>? imageUrls;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    required this.stock,
    this.description,
    this.imageUrls,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'نامشخص',
      price: (json['price'] is num ? json['price'].toDouble() : 0.0),
      categoryId: json['category']?['_id']?.toString() ??
          json['category']?.toString() ??
          '',
      stock: json['stock'] is num ? json['stock'].toInt() : 0,
      description: json['description']?.toString(),
      imageUrls: json['imageUrls'] != null
          ? (json['imageUrls'] as List<dynamic>)
              .map((e) => e.toString())
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'price': price,
      'category': categoryId,
      'stock': stock,
      'description': description,
      'imageUrls': imageUrls,
    };
    // Only include '_id' if it's not empty (i.e., for updates)
    if (id.isNotEmpty) {
      data['_id'] = id;
    }
    return data;
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
          description == other.description &&
          imageUrls == other.imageUrls;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      price.hashCode ^
      categoryId.hashCode ^
      stock.hashCode ^
      description.hashCode ^
      imageUrls.hashCode;
}
