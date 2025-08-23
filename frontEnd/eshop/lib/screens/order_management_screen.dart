import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../providers/order_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
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
    final orderProvider = Provider.of<OrderProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('مدیریت سفارشات',
              style: TextStyle(fontFamily: 'Vazir')),
          backgroundColor: AppColors.primary,
          actions: [
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.signOutAlt),
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
                style: const TextStyle(fontSize: 16, fontFamily: 'Vazir'),
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
                child: const Text('تلاش مجدد',
                    style: TextStyle(fontFamily: 'Vazir')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final groupedOrders = {
      OrderStatus.pending: orderProvider.orders
          .where((o) => o.status == OrderStatus.pending)
          .toList(),
      OrderStatus.processed: orderProvider.orders
          .where((o) => o.status == OrderStatus.processed)
          .toList(),
      OrderStatus.shipped: orderProvider.orders
          .where((o) => o.status == OrderStatus.shipped)
          .toList(),
      OrderStatus.delivered: orderProvider.orders
          .where((o) => o.status == OrderStatus.delivered)
          .toList(),
      OrderStatus.returned: orderProvider.orders
          .where((o) => o.status == OrderStatus.returned)
          .toList(),
      OrderStatus.cancelled: orderProvider.orders
          .where((o) => o.status == OrderStatus.cancelled)
          .toList(),
    };

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('مدیریت سفارشات', style: TextStyle(fontFamily: 'Vazir')),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.signOutAlt),
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
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildOrderGroup(
              context: context,
              title: 'در انتظار',
              orders: groupedOrders[OrderStatus.pending]!,
              icon: FontAwesomeIcons.hourglassHalf,
              color: Colors.orange,
              orderProvider: orderProvider,
              authProvider: authProvider,
              productProvider: productProvider,
            ),
            _buildOrderGroup(
              context: context,
              title: 'پردازش‌شده',
              orders: groupedOrders[OrderStatus.processed]!,
              icon: FontAwesomeIcons.cogs,
              color: Colors.blue,
              orderProvider: orderProvider,
              authProvider: authProvider,
              productProvider: productProvider,
            ),
            _buildOrderGroup(
              context: context,
              title: 'ارسال‌شده',
              orders: groupedOrders[OrderStatus.shipped]!,
              icon: FontAwesomeIcons.truckLoading,
              color: Colors.purple,
              orderProvider: orderProvider,
              authProvider: authProvider,
              productProvider: productProvider,
            ),
            _buildOrderGroup(
              context: context,
              title: 'تحویل‌شده',
              orders: groupedOrders[OrderStatus.delivered]!,
              icon: FontAwesomeIcons.truck,
              color: Colors.green,
              orderProvider: orderProvider,
              authProvider: authProvider,
              productProvider: productProvider,
            ),
            _buildOrderGroup(
              context: context,
              title: 'مرجوعی',
              orders: groupedOrders[OrderStatus.returned]!,
              icon: FontAwesomeIcons.undo,
              color: Colors.red,
              orderProvider: orderProvider,
              authProvider: authProvider,
              productProvider: productProvider,
            ),
            _buildOrderGroup(
              context: context,
              title: 'لغوشده',
              orders: groupedOrders[OrderStatus.cancelled]!,
              icon: FontAwesomeIcons.ban,
              color: Colors.grey,
              orderProvider: orderProvider,
              authProvider: authProvider,
              productProvider: productProvider,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        child: const FaIcon(FontAwesomeIcons.shoppingCart),
        onPressed: () {
          debugPrint('Navigating to cart');
          Navigator.pushNamed(context, AppRoutes.cart);
        },
      ),
    );
  }

  Widget _buildOrderGroup({
    required BuildContext context,
    required String title,
    required List<Order> orders,
    required IconData icon,
    required Color color,
    required OrderProvider orderProvider,
    required AuthProvider authProvider,
    required ProductProvider productProvider,
  }) {
    return ExpansionTile(
      leading: FaIcon(icon, color: color),
      title: Text(
        '$title (${orders.length})',
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: 'Vazir',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      children: orders.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'هیچ سفارشی در این دسته وجود ندارد',
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontFamily: 'Vazir', fontSize: 14),
                ),
              ),
            ]
          : orders.map((order) {
              return ListTile(
                title: Text(
                  'سفارش #${order.id}',
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                      fontFamily: 'Vazir', fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'کاربر: ${order.userId}',
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontFamily: 'Vazir'),
                    ),
                    Text(
                      'مبلغ: ${order.totalAmount.toStringAsFixed(0)} تومان',
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontFamily: 'Vazir'),
                    ),
                    Text(
                      'تاریخ: ${order.createdAt.toString()}',
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontFamily: 'Vazir'),
                    ),
                    Text(
                      'درخواست مرجوعی: ${order.returnRequest ? 'بله' : 'خیر'}',
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontFamily: 'Vazir'),
                    ),
                    ExpansionTile(
                      title: const Text(
                        'محصولات',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(fontFamily: 'Vazir', fontSize: 14),
                      ),
                      children: order.products.map((item) {
                        final product = productProvider.products.firstWhere(
                          (p) => p.id == item.productId,
                          orElse: () => Product(
                            id: item.productId,
                            name: 'نامشخص',
                            price: 0.0,
                            categoryId: '',
                            stock: 0,
                          ),
                        );
                        return ListTile(
                          leading: product.imageUrls != null &&
                                  product.imageUrls!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    product.imageUrls!.first,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.broken_image),
                                  ),
                                )
                              : const Icon(Icons.image_not_supported),
                          title: Text(
                            product.name,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(fontFamily: 'Vazir'),
                          ),
                          subtitle: Text(
                            'تعداد: ${item.quantity} | قیمت واحد: ${product.price.toStringAsFixed(0)} تومان',
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(fontFamily: 'Vazir'),
                          ),
                        );
                      }).toList(),
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
                                    style: const TextStyle(fontFamily: 'Vazir'),
                                  ),
                                ))
                            .toList(),
                        onChanged: (newStatus) async {
                          if (newStatus != null && newStatus != order.status) {
                            try {
                              debugPrint(
                                  'Updating order ${order.id} status to $newStatus');
                              await orderProvider.updateOrderStatus(
                                  order.id, newStatus, authProvider.token!);
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'وضعیت سفارش با موفقیت به‌روزرسانی شد',
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(fontFamily: 'Vazir'),
                                  ),
                                  backgroundColor: AppColors.accent,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            } catch (e) {
                              String errorMessage =
                                  e.toString().replaceFirst('Exception: ', '');
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
                                    style: const TextStyle(fontFamily: 'Vazir'),
                                  ),
                                  backgroundColor: Colors.red,
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
                  // TODO: Implement order details page if needed
                },
              );
            }).toList(),
    );
  }
}
