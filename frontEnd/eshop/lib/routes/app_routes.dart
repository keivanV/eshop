import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/product_list_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/product_management_screen.dart';
import '../screens/category_management_screen.dart';
import '../screens/inventory_management_screen.dart';
import '../screens/order_management_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/dashboard_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String cart = '/cart';
  static const String productList = '/products';
  static const String productDetail = '/product_detail';
  static const String productManagement = '/product_management';
  static const String categoryManagement = '/category_management';
  static const String inventoryManagement = '/inventory_management';
  static const String orderManagement = '/order_management';
  static const String profile = '/profile';
  static const String dashboard = '/dashboard';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());
      case productList:
        return MaterialPageRoute(builder: (_) => const ProductListScreen());
      case productDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: args['productId']));
      case productManagement:
        return MaterialPageRoute(
            builder: (_) => const ProductManagementScreen());
      case categoryManagement:
        return MaterialPageRoute(
            builder: (_) => const CategoryManagementScreen());
      case inventoryManagement:
        return MaterialPageRoute(
            builder: (_) => const InventoryManagementScreen());
      case orderManagement:
        return MaterialPageRoute(builder: (_) => const OrderManagementScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      default:
        return MaterialPageRoute(
            builder: (_) =>
                const Scaffold(body: Center(child: Text('Page not found'))));
    }
  }
}
