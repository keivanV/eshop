import 'package:flutter/material.dart';
import '../models/product.dart';

class CartProvider with ChangeNotifier {
  Map<String, int> _items = {};

  Map<String, int> get items => _items;

  void addItem(Product product, int quantity) {
    debugPrint('Adding ${product.id} with quantity $quantity to cart');
    _items.update(product.id, (value) => value + quantity,
        ifAbsent: () => quantity);
    notifyListeners();
  }

  void removeItem(String productId) {
    debugPrint('Removing $productId from cart');
    _items.remove(productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    debugPrint('Updating $productId quantity to $quantity');
    if (quantity <= 0) {
      _items.remove(productId);
    } else {
      _items[productId] = quantity;
    }
    notifyListeners();
  }

  double getTotalAmount(List<Product> products) {
    debugPrint('Calculating total amount for ${_items.length} items');
    double total = 0;
    for (var entry in _items.entries) {
      final product = products.firstWhere(
        (p) => p.id == entry.key,
        orElse: () => Product(
            id: entry.key, name: 'نامشخص', price: 0, categoryId: '', stock: 0),
      );
      total += product.price * entry.value;
    }
    return total;
  }

  void clear() {
    debugPrint('Clearing cart');
    _items = {};
    notifyListeners();
  }
}
