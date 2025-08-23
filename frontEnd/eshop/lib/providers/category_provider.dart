import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/category.dart';

class CategoryProvider with ChangeNotifier {
  List<Category> _categories = [];
  bool _isFetching = false;
  bool _isLoading = false;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> fetchCategories() async {
    if (_isFetching) {
      debugPrint('Fetch categories skipped: already fetching');
      return;
    }
    _isFetching = true;
    _isLoading = true;
    try {
      debugPrint('Fetching categories...');
      final newCategories = await ApiService.getCategories();
      if (_categories.length != newCategories.length ||
          !_categories.every((c) =>
              newCategories.any((n) => n.id == c.id && n.name == c.name))) {
        _categories = newCategories;
        debugPrint('Categories fetched: ${_categories.length}');
      } else {
        debugPrint('No changes in categories, skipping notifyListeners');
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error fetching categories: $e');
      throw Exception('خطا در دریافت دسته‌بندی‌ها: $e');
    } finally {
      _isFetching = false;
    }
  }

  Future<void> createCategory(Category category, String token) async {
    try {
      await ApiService.createCategory(category, token);
      await fetchCategories();
    } catch (e) {
      debugPrint('Error creating category: $e');
      throw Exception('خطا در ایجاد دسته‌بندی: $e');
    }
  }

  Future<void> updateCategory(
      String id, Category category, String token) async {
    try {
      await ApiService.updateCategory(id, category, token);
      await fetchCategories();
    } catch (e) {
      debugPrint('Error updating category: $e');
      throw Exception('خطا در به‌روزرسانی دسته‌بندی: $e');
    }
  }

  Future<void> deleteCategory(String id, String token) async {
    try {
      await ApiService.deleteCategory(id, token);
      await fetchCategories();
    } catch (e) {
      debugPrint('Error deleting category: $e');
      throw Exception('خطا در حذف دسته‌بندی: $e');
    }
  }
}
