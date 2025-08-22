import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../providers/auth_provider.dart';
import '../models/order.dart';
import '../routes/app_routes.dart';
import '../constants.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  _OrderManagementScreenState createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    debugPrint('OrderManagementScreen initState');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    if (_isInitialized) {
      debugPrint('Fetch orders skipped: already initialized');
      return;
    }
    _isInitialized = true;
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      debugPrint('Starting fetchOrders...');
      await orderProvider.fetchOrders(authProvider.token!, '', '');
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
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
      debugPrint('Error in fetchOrders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    debugPrint('Building OrderManagementScreen');
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('مدیریت سفارشات'),
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'خطا در بارگذاری سفارشات: $_errorMessage',
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                    _isInitialized = false;
                  });
                  _fetchData();
                },
                child: const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت سفارشات'),
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
      body: RefreshIndicator(
        onRefresh: () async {
          debugPrint('Manual refresh triggered for orders');
          _isInitialized = false;
          await _fetchData();
        },
        child: Consumer<OrderProvider>(
          builder: (ctx, orderProvider, _) {
            debugPrint(
                'Rendering order list with ${orderProvider.orders.length} orders');
            if (orderProvider.orders.isEmpty) {
              return const Center(
                child: Text(
                  'هیچ سفارشی یافت نشد',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontSize: 16),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: orderProvider.orders.length,
              itemBuilder: (ctx, i) {
                final order = orderProvider.orders[i];
                return Card(
                  child: ListTile(
                    title: Text('سفارش #${order.id}',
                        textDirection: TextDirection.rtl),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'وضعیت: ${order.status.toString().split('.').last}',
                          textDirection: TextDirection.rtl,
                        ),
                        Text(
                          'کاربر: ${order.userId}',
                          textDirection: TextDirection.rtl,
                        ),
                        Text(
                          'مبلغ کل: ${order.totalAmount.toStringAsFixed(0)} تومان',
                          textDirection: TextDirection.rtl,
                        ),
                        Text(
                          'درخواست مرجوعی: ${order.returnRequest ? 'بله' : 'خیر'}',
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                    trailing: authProvider.role == 'admin'
                        ? DropdownButton<OrderStatus>(
                            value: order.status,
                            items: OrderStatus.values
                                .map((status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(
                                        status.toString().split('.').last,
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (newStatus) async {
                              if (newStatus != null &&
                                  newStatus != order.status) {
                                try {
                                  debugPrint(
                                      'Updating order ${order.id} status to $newStatus');
                                  await orderProvider.updateOrderStatus(
                                      order.id, newStatus, authProvider.token!);
                                  ScaffoldMessenger.of(context)
                                      .hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'وضعیت سفارش با موفقیت به‌روزرسانی شد',
                                        textDirection: TextDirection.rtl,
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                } catch (e) {
                                  String errorMessage = e
                                      .toString()
                                      .replaceFirst('Exception: ', '');
                                  if (errorMessage.contains('403')) {
                                    errorMessage =
                                        'عدم دسترسی: لطفاً با حساب مدیر وارد شوید';
                                  }
                                  ScaffoldMessenger.of(context)
                                      .hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'خطا در به‌روزرسانی وضعیت سفارش: $errorMessage',
                                        textDirection: TextDirection.rtl,
                                      ),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              }
                            },
                          )
                        : null,
                    onTap: () {
                      debugPrint('Navigating to order details: ${order.id}');
                      // اگر صفحه جزئیات سفارش دارید، اینجا نویگیت کنید
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.shopping_cart),
        onPressed: () {
          debugPrint('Navigating to cart');
          Navigator.pushNamed(context, AppRoutes.cart);
        },
      ),
    );
  }
}
