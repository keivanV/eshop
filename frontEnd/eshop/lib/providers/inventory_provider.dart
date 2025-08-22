import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/inventory_item.dart';

class InventoryProvider with ChangeNotifier {
  List<InventoryItem> _inventory = [];

  List<InventoryItem> get inventory => _inventory;

  Future<void> fetchInventory(String token) async {
    try {
      debugPrint('Fetching inventory...');
      final response = await ApiService.getInventory(token);
      print('Inventory response: $response'); // لاگ برای دیباگ
      final newInventory = (response as List<dynamic>)
          .map((json) {
            if (json is Map<String, dynamic>) {
              return InventoryItem.fromJson(json);
            } else {
              debugPrint('Invalid inventory item: $json');
              return null;
            }
          })
          .where((item) => item != null)
          .cast<InventoryItem>()
          .toList();
      if (_inventory.length != newInventory.length ||
          _inventory.any((i) => !newInventory.contains(i))) {
        _inventory = newInventory;
        debugPrint('Inventory fetched: ${_inventory.length}');
        notifyListeners();
      } else {
        debugPrint('No changes in inventory, skipping notifyListeners');
      }
    } catch (e) {
      debugPrint('Error fetching inventory: $e');
      throw Exception('خطا در دریافت موجودی انبار: $e');
    }
  }

  Future<void> updateInventory(
      String productId, int stock, String token) async {
    try {
      debugPrint('Updating inventory for product $productId to stock $stock');
      await ApiService.updateInventory(productId, stock, token);
      debugPrint('Inventory updated successfully');
      await fetchInventory(token);
    } catch (e) {
      debugPrint('Error updating inventory: $e');
      throw Exception('خطا در به‌روزرسانی موجودی انبار: $e');
    }
  }
}
