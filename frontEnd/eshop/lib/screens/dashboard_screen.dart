import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../routes/app_routes.dart';
import '../constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    try {
      await Future.wait([
        productProvider.fetchProducts(),
        orderProvider.fetchOrders(
            authProvider.token!, authProvider.role!, authProvider.userId!),
      ]);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final role = authProvider.role;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError) {
      return Scaffold(
        body: Center(child: Text('خطا در بارگذاری اطلاعات: $_errorMessage')),
      );
    }

    final totalProducts = productProvider.products.length;
    final processedOrders = orderProvider.orders
        .where((o) => o.status == OrderStatus.processed)
        .length;
    final returnedOrders = orderProvider.orders
        .where((o) => o.status == OrderStatus.returned)
        .length;
    final deliveredOrders = orderProvider.orders
        .where((o) => o.status == OrderStatus.delivered)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('داشبورد'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'خروج',
            onPressed: () async {
              await authProvider.logout();
              Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.login, (route) => false);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('خوش آمدید، ${authProvider.userId}',
                  style: Theme.of(context).textTheme.headlineSmall),
              Text('نقش: $role',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 20),
              if (role == 'user') ...[
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.productList),
                  child: const Text('مشاهده محصولات'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
                  child: const Text('مشاهده سبد خرید'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.profile),
                  child: const Text('سفارشات من'),
                ),
              ],
              if (role == 'admin' || role == 'warehouse_manager') ...[
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(
                      context, AppRoutes.categoryManagement),
                  child: const Text('مدیریت دسته‌بندی‌ها'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.productManagement),
                  child: const Text('مدیریت محصولات'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(
                      context, AppRoutes.inventoryManagement),
                  child: const Text('مدیریت انبار'),
                ),
              ],
              if (role == 'admin' ||
                  role == 'warehouse_manager' ||
                  role == 'delivery_agent')
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.orderManagement),
                  child: const Text('مدیریت سفارشات'),
                ),
              const SizedBox(height: 30),
              if (role == 'admin') ...[
                const Text('آمار',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تعداد کل محصولات: $totalProducts'),
                        Text('سفارشات پردازش‌شده: $processedOrders'),
                        Text('سفارشات مرجوعی: $returnedOrders'),
                        Text('سفارشات تحویل‌شده: $deliveredOrders'),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
