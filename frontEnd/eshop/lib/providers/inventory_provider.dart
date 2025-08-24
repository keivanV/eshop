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
      debugPrint('Inventory response: $response');
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

  Future<InventoryItem> fetchInventoryByProduct(
      String productId, String token) async {
    try {
      debugPrint('Fetching inventory for product: $productId');
      final response = await ApiService.getInventoryByProduct(productId, token);
      if (response == null) {
        debugPrint('No inventory found for product: $productId');
        throw Exception('موجودی برای محصول $productId یافت نشد');
      }
      final inventoryItem = InventoryItem.fromJson(response);
      debugPrint(
          'Inventory fetched for product $productId: ${inventoryItem.quantity}');
      return inventoryItem;
    } catch (e) {
      debugPrint('Error fetching inventory for product $productId: $e');
      throw Exception('خطا در دریافت موجودی محصول: $e');
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
