
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Product> get products => _products;

  Future<void> fetchProducts() async {
    try {
      _products = await ApiService.getProducts();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  Future<String> createProduct(Product product, String token) async {
    try {
      final productId = await ApiService.createProduct(product, token);
      await fetchProducts(); // Refresh product list
      return productId;
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  Future<void> updateProduct(String id, Product product, String token) async {
    try {
      await ApiService.updateProduct(id, product, token);
      await fetchProducts(); // Refresh product list
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(String id, String token) async {
    try {
      await ApiService.deleteProduct(id, token);
      await fetchProducts(); // Refresh product list
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  Future<void> uploadProductImages(
      String productId, List<XFile> images, String token) async {
    try {
      await ApiService.uploadProductImages(productId, images, token);
      await fetchProducts(); // Refresh product list
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }
}
