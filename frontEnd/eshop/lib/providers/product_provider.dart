import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/product.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  bool _isFetching = false;

  List<Product> get products => _products;

  Future<void> fetchProducts() async {
    if (_isFetching) {
      debugPrint('Fetch products skipped: already fetching');
      return;
    }
    _isFetching = true;
    try {
      debugPrint('Fetching products...');
      final newProducts = await ApiService.getProducts();
      if (_products.length != newProducts.length ||
          _products.any((p) => !newProducts.contains(p))) {
        _products = newProducts;
        debugPrint('Products fetched: ${_products.length}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      } else {
        debugPrint('No changes in products, skipping notifyListeners');
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
      throw Exception('خطا در دریافت محصولات: $e');
    } finally {
      _isFetching = false;
    }
  }

  Future<void> createProduct(Product product, String token) async {
    try {
      debugPrint('Creating product: ${product.name}');
      await ApiService.createProduct(product, token);
      await fetchProducts();
    } catch (e) {
      debugPrint('Error creating product: $e');
      throw Exception('خطا در ایجاد محصول: $e');
    }
  }

  Future<void> updateProduct(String id, Product product, String token) async {
    try {
      debugPrint('Updating product: $id');
      await ApiService.updateProduct(id, product, token);
      await fetchProducts();
    } catch (e) {
      debugPrint('Error updating product: $e');
      throw Exception('خطا در به‌روزرسانی محصول: $e');
    }
  }

  Future<void> deleteProduct(String id, String token) async {
    try {
      debugPrint('Deleting product: $id');
      await ApiService.deleteProduct(id, token);
      await fetchProducts();
    } catch (e) {
      debugPrint('Error deleting product: $e');
      throw Exception('خطا در حذف محصول: $e');
    }
  }

  Future<void> uploadProductImages(
      String productId, List<XFile> images, String token) async {
    try {
      debugPrint('Uploading images for product: $productId');
      await ApiService.uploadProductImages(productId, images, token);
      await fetchProducts();
    } catch (e) {
      debugPrint('Error uploading product images: $e');
      throw Exception('خطا در آپلود تصاویر: $e');
    }
  }
}
