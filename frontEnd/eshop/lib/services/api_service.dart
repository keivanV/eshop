import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/inventory_item.dart';
import '../models/user.dart';

class ApiService {
  static String _padBase64(String base64Str) {
    while (base64Str.length % 4 != 0) {
      base64Str += '=';
    }
    return base64Str;
  }

  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final payload = _padBase64(data['token'].split('.')[1]);
      try {
        final decoded = json.decode(utf8.decode(base64Url.decode(payload)));

        return {
          'token': data['token'],
          'role': data['role'],
          'userId': decoded['id'],
        };
      } catch (e) {
        throw Exception('خطا در رمزگشایی توکن: $e');
      }
    }
    throw Exception('خطا در ورود: ${response.statusCode} - ${response.body}');
  }

  static Future<Map<String, dynamic>> register(
      String username, String password, String email, String role) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
        'email': email,
        'roleName': role
      }),
    );
    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      final payload = _padBase64(data['token'].split('.')[1]);
      try {
        final decoded = json.decode(utf8.decode(base64Url.decode(payload)));

        return {
          'token': data['token'],
          'userId': decoded['id'],
          'role': role,
        };
      } catch (e) {
        throw Exception('خطا در رمزگشایی توکن: $e');
      }
    }
    throw Exception(
        'خطا در ثبت‌نام: ${response.statusCode} - ${response.body}');
  }

  static Future<List<Category>> getCategories() async {
    final response =
        await http.get(Uri.parse('${AppConfig.apiBaseUrl}/categories'));
    if (response.statusCode == 200) {
      return (json.decode(response.body) as List)
          .map((e) => Category.fromJson(e))
          .toList();
    }
    throw Exception(
        'خطا در دریافت دسته‌بندی‌ها: ${response.statusCode} - ${response.body}');
  }

  static Future<void> createCategory(Category category, String token) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/categories'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: json.encode(category.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception(
          'خطا در ایجاد دسته‌بندی: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> updateCategory(
      String id, Category category, String token) async {
    final response = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/categories/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: json.encode(category.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception(
          'خطا در به‌روزرسانی دسته‌بندی: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> deleteCategory(String id, String token) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.apiBaseUrl}/categories/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception(
          'خطا در حذف دسته‌بندی: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<List<Product>> getProducts() async {
    final response =
        await http.get(Uri.parse('${AppConfig.apiBaseUrl}/products'));
    if (response.statusCode == 200) {
      return (json.decode(response.body) as List)
          .map((e) => Product.fromJson(e))
          .toList();
    }
    throw Exception(
        'خطا در دریافت محصولات: ${response.statusCode} - ${response.body}');
  }

  static Future<void> createProduct(Product product, String token) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/products'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: json.encode(product.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception(
          'خطا در ایجاد محصول: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> updateProduct(
      String id, Product product, String token) async {
    final response = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/products/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: json.encode(product.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception(
          'خطا در به‌روزرسانی محصول: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> deleteProduct(String id, String token) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.apiBaseUrl}/products/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception(
          'خطا در حذف محصول: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<List<InventoryItem>> getInventory(String token) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/inventory'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return (json.decode(response.body) as List)
          .map((e) => InventoryItem.fromJson(e))
          .toList();
    }
    throw Exception(
        'خطا در دریافت موجودی انبار: ${response.statusCode} - ${response.body}');
  }

  static Future<void> updateInventory(
      String productId, int quantity, String token) async {
    final response = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/inventory'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: json.encode({'productId': productId, 'quantity': quantity}),
    );
    if (response.statusCode != 200) {
      throw Exception(
          'خطا در به‌روزرسانی موجودی انبار: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<List<Order>> getOrders(String token) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/orders'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return (json.decode(response.body) as List)
          .map((e) => Order.fromJson(e))
          .toList();
    }
    throw Exception(
        'خطا در دریافت سفارشات: ${response.statusCode} - ${response.body}');
  }

  static Future<void> createOrder(
      List<OrderItem> products, double totalAmount, String token) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: json.encode({
        'products': products.map((e) => e.toJson()).toList(),
        'totalAmount': totalAmount
      }),
    );
    if (response.statusCode != 201) {
      throw Exception(
          'خطا در ثبت سفارش: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> cancelOrder(String id, String token) async {
    final response = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/orders/$id/cancel'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception(
          'خطا در لغو سفارش: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> requestReturn(String id, String token) async {
    final response = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/orders/$id/return'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception(
          'خطا در درخواست مرجوعی: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> updateOrderStatus(
      String id, OrderStatus status, String token) async {
    final response = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/orders/$id/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: json.encode({'status': status.toString().split('.').last}),
    );
    if (response.statusCode != 200) {
      throw Exception(
          'خطا در به‌روزرسانی وضعیت سفارش: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<List<User>> getUsers(String token) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/users'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return (json.decode(response.body) as List)
          .map((e) => User.fromJson(e))
          .toList();
    }
    throw Exception(
        'خطا در دریافت کاربران: ${response.statusCode} - ${response.body}');
  }

  static Future<Map<String, dynamic>> updateUser(
      String userId, String token, String username, String email) async {
    try {
      print('Updating user $userId with username: $username, email: $email');
      final response = await http.put(
        Uri.parse('${AppConfig.apiBaseUrl}/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'email': email,
        }),
      );
      print(
          'Update response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception(
          'Failed to update user: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('Update user error: $e');
      rethrow;
    }
  }

  static Future<void> deleteUser(String id, String token) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.apiBaseUrl}/users/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception(
          'خطا در حذف کاربر: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> changeUserRole(
      String id, String role, String token) async {
    final response = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/users/$id/role'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: json.encode({'roleName': role}),
    );
    if (response.statusCode != 200) {
      throw Exception(
          'خطا در تغییر نقش کاربر: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getUserById(
      String userId, String token) async {
    try {
      print('Fetching user data for userId: $userId with token: $token');
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/users/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      print('Response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception(
          'Failed to fetch user: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('Get user error: $e');
      rethrow;
    }
  }
}
