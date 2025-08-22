import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/order.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  bool _isFetching = false;

  List<Order> get orders => _orders;

  Future<void> fetchOrders(String token, String role, String userId) async {
    if (_isFetching) {
      debugPrint('Fetch orders skipped: already fetching');
      return;
    }
    _isFetching = true;
    try {
      debugPrint('Fetching orders...');
      final newOrders = await ApiService.getOrders(token);
      if (_orders.length != newOrders.length ||
          _orders.any((o) => !newOrders.contains(o))) {
        _orders = newOrders;
        debugPrint('Orders fetched: ${_orders.length}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      } else {
        debugPrint('No changes in orders, skipping notifyListeners');
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      throw Exception('خطا در دریافت سفارشات: $e');
    } finally {
      _isFetching = false;
    }
  }

  Future<void> createOrder(
      List<OrderItem> products, double totalAmount, String token) async {
    try {
      debugPrint(
          'Creating order with ${products.length} items, total: $totalAmount');
      await ApiService.createOrder(products, totalAmount, token);
      debugPrint('Order created successfully');
      // fetchOrders غیرفعال شده تا از حلقه جلوگیری بشه
    } catch (e) {
      debugPrint('Error creating order: $e');
      throw Exception('خطا در ثبت سفارش: $e');
    }
  }

  Future<void> updateOrderStatus(
      String id, OrderStatus status, String token) async {
    try {
      debugPrint('Updating order status for order $id to $status');
      await ApiService.updateOrderStatus(id, status, token);
      debugPrint('Order status updated successfully');
      // آپدیت محلی به‌جای فراخوانی fetchOrders
      final index = _orders.indexWhere((order) => order.id == id);
      if (index != -1) {
        _orders[index] = Order(
          id: _orders[index].id,
          userId: _orders[index].userId,
          products: _orders[index].products,
          totalAmount: _orders[index].totalAmount,
          status: status,
          returnRequest: _orders[index].returnRequest,
          createdAt: _orders[index].createdAt,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
    } catch (e) {
      debugPrint('Error updating order status: $e');
      throw Exception('خطا در به‌روزرسانی وضعیت سفارش: $e');
    }
  }

  Future<void> cancelOrder(String id, String token) async {
    try {
      debugPrint('Cancelling order $id');
      await ApiService.cancelOrder(id, token);
      debugPrint('Order cancelled successfully');
      // آپدیت محلی
      final index = _orders.indexWhere((order) => order.id == id);
      if (index != -1) {
        _orders[index] = Order(
          id: _orders[index].id,
          userId: _orders[index].userId,
          products: _orders[index].products,
          totalAmount: _orders[index].totalAmount,
          status: OrderStatus.cancelled,
          returnRequest: _orders[index].returnRequest,
          createdAt: _orders[index].createdAt,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      throw Exception('خطا در لغو سفارش: $e');
    }
  }

  Future<void> requestReturn(String id, String token) async {
    try {
      debugPrint('Requesting return for order $id');
      await ApiService.requestReturn(id, token);
      debugPrint('Return requested successfully');
      // آپدیت محلی
      final index = _orders.indexWhere((order) => order.id == id);
      if (index != -1) {
        _orders[index] = Order(
          id: _orders[index].id,
          userId: _orders[index].userId,
          products: _orders[index].products,
          totalAmount: _orders[index].totalAmount,
          status: _orders[index].status,
          returnRequest: true,
          createdAt: _orders[index].createdAt,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
    } catch (e) {
      debugPrint('Error requesting return: $e');
      throw Exception('خطا در درخواست مرجوعی: $e');
    }
  }
}
