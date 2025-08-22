import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/api_service.dart';

class CategoryProvider with ChangeNotifier {
  List<Category> _categories = [];
  bool _isLoading = false;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> fetchCategories() async {
    _isLoading = true;
    notifyListeners();
    try {
      _categories = await ApiService.getCategories();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createCategory(Category category, String token) async {
    await ApiService.createCategory(category, token);
    await fetchCategories();
  }

  Future<void> updateCategory(
      String id, Category category, String token) async {
    await ApiService.updateCategory(id, category, token);
    await fetchCategories();
  }

  Future<void> deleteCategory(String id, String token) async {
    await ApiService.deleteCategory(id, token);
    await fetchCategories();
  }
}
