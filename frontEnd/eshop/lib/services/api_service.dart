import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/inventory_item.dart';
import '../models/user.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ApiService {
  static String _padBase64(String base64Str) {
    while (base64Str.length % 4 != 0) {
      base64Str += '=';
    }
    return base64Str;
  }

  static String _cleanBaseUrl() {
    return AppConfig.apiBaseUrl.replaceAll(RegExp(r'/api$'), '');
  }

  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    final baseUrl = _cleanBaseUrl();
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
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
    final baseUrl = _cleanBaseUrl();
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
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
    final baseUrl = _cleanBaseUrl();
    final response = await http.get(Uri.parse('$baseUrl/api/categories'));
    if (response.statusCode == 200) {
      return (json.decode(response.body) as List)
          .map((e) => Category.fromJson(e))
          .toList();
    }
    throw Exception(
        'خطا در دریافت دسته‌بندی‌ها: ${response.statusCode} - ${response.body}');
  }

  static Future<void> createCategory(Category category, String token) async {
    final baseUrl = _cleanBaseUrl();
    final response = await http.post(
      Uri.parse('$baseUrl/api/categories'),
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
    final baseUrl = _cleanBaseUrl();
    final response = await http.put(
      Uri.parse('$baseUrl/api/categories/$id'),
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
    final baseUrl = _cleanBaseUrl();
    final response = await http.delete(
      Uri.parse('$baseUrl/api/categories/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception(
          'خطا در حذف دسته‌بندی: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<List<Product>> getProducts() async {
    final baseUrl = _cleanBaseUrl();
    final response = await http.get(Uri.parse('$baseUrl/api/products'));
    if (response.statusCode == 200) {
      return (json.decode(response.body) as List)
          .map((e) => Product.fromJson(e))
          .toList();
    }
    throw Exception(
        'خطا در دریافت محصولات: ${response.statusCode} - ${response.body}');
  }

  static Future<String> createProduct(Product product, String token) async {
    final baseUrl = _cleanBaseUrl();
    final response = await http.post(
      Uri.parse('$baseUrl/api/products'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: json.encode(product.toJson()),
    );
    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      final productId = data['_id'].toString();
      await updateInventory(productId, product.stock, token);
      return productId;
    }
    throw Exception(
        'خطا در ایجاد محصول: ${response.statusCode} - ${response.body}');
  }

  static Future<void> updateProduct(
      String id, Product product, String token) async {
    final baseUrl = _cleanBaseUrl();
    final response = await http.put(
      Uri.parse('$baseUrl/api/products/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: json.encode(product.toJson()),
    );
    if (response.statusCode == 200) {
      await updateInventory(id, product.stock, token);
      return;
    }
    throw Exception(
        'خطا در به‌روزرسانی محصول: ${response.statusCode} - ${response.body}');
  }

  static Future<void> deleteProduct(String id, String token) async {
    final baseUrl = _cleanBaseUrl();
    final response = await http.delete(
      Uri.parse('$baseUrl/api/products/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception(
          'خطا در حذف محصول: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> uploadProductImages(
      String productId, List<XFile> images, String token) async {
    final baseUrl = _cleanBaseUrl();
    final uploadUrl = '$baseUrl/api/products/$productId/images';
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(uploadUrl),
    )..headers['Authorization'] = 'Bearer $token';

    for (var file in images) {
      final filePath = file.path;
      final ext = filePath.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
      request.files.add(
        await http.MultipartFile.fromPath(
          'images',
          filePath,
          contentType: MediaType('image', ext == 'png' ? 'png' : 'jpeg'),
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode != 200) {
      throw Exception('خطا در آپلود تصاویر: ${response.body}');
    }
  }

  static Future<List<InventoryItem>> getInventory(String token) async {
    final baseUrl = _cleanBaseUrl();
    final response = await http.get(
      Uri.parse('$baseUrl/api/inventory'),
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

  static Future<Map<String, dynamic>> getInventoryByProduct(
      String productId, String token) async {
    final baseUrl = _cleanBaseUrl();

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/api/inventory/$productId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else if (response.statusCode == 401) {
          throw Exception('Unauthorized: Invalid or expired token');
        } else if (response.statusCode == 403) {
          throw Exception('Forbidden: User role not authorized');
        } else if (response.statusCode == 404) {
          if (attempt < 3) {
            await Future.delayed(const Duration(milliseconds: 500));
            continue;
          }
          return {
            'product': productId,
            'quantity': 0,
            'lastUpdated': DateTime.now().toIso8601String()
          };
        } else {
          throw Exception(
              'Failed to fetch inventory: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        if (attempt < 3) {
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        }
        throw Exception('Error fetching inventory after retries: $e');
      }
    }
    throw Exception('Failed to fetch inventory after all retries');
  }

  static Future<void> updateInventory(
      String productId, int quantity, String token) async {
    final baseUrl = _cleanBaseUrl();
    final response = await http.put(
      Uri.parse('$baseUrl/api/inventory'),
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

  static Future<List<dynamic>> getOrders(String token,
      [String role = '', String userId = '']) async {
    final baseUrl = _cleanBaseUrl();
    final url =
        '$baseUrl/api/orders'; // Always use /api/orders, backend filters by role
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data == null) {
        return [];
      }
      if (data is! List) {
        throw Exception('فرمت پاسخ سرور نامعتبر است');
      }
      return data;
    } else if (response.statusCode == 403) {
      throw Exception('عدم دسترسی: توکن نامعتبر است');
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception(
          'خطا در دریافت سفارشات: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> createOrder(
      List<OrderItem> products, double totalAmount, String token) async {
    final baseUrl = _cleanBaseUrl();
    final response = await http.post(
      Uri.parse('$baseUrl/api/orders'),
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
    final baseUrl = _cleanBaseUrl();
    final response = await http.put(
      Uri.parse('$baseUrl/api/orders/$id/cancel'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception(
          'خطا در لغو سفارش: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> requestReturn(String id, String token) async {
    final baseUrl = _cleanBaseUrl();
    final response = await http.put(
      Uri.parse('$baseUrl/api/orders/$id/return'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception(
          'خطا در درخواست مرجوعی: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> updateOrderStatus(
      String id, OrderStatus status, String token) async {
    final baseUrl = _cleanBaseUrl();
    final response = await http.put(
      Uri.parse('$baseUrl/api/orders/$id/status'),
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
    final baseUrl = _cleanBaseUrl();
    final response = await http.get(
      Uri.parse('$baseUrl/api/users'),
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
    final baseUrl = _cleanBaseUrl();
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'email': email,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception(
          'Failed to update user: ${response.statusCode} - ${response.body}');
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> deleteUser(String id, String token) async {
    final baseUrl = _cleanBaseUrl();
    final response = await http.delete(
      Uri.parse('$baseUrl/api/users/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception(
          'خطا در حذف کاربر: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> changeUserRole(
      String id, String role, String token) async {
    final baseUrl = _cleanBaseUrl();
    final response = await http.put(
      Uri.parse('$baseUrl/api/users/$id/role'),
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
    final baseUrl = _cleanBaseUrl();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception(
          'Failed to fetch user: ${response.statusCode} - ${response.body}');
    } catch (e) {
      rethrow;
    }
  }

  static Future<dynamic> getProductById(String productId, String token) async {
    final baseUrl = _cleanBaseUrl();
    final response = await http.get(
      Uri.parse('$baseUrl/api/products/$productId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null; // Handle 404 gracefully
  }
}
