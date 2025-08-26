import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
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

class _OrderManagementScreenState extends State<OrderManagementScreen>
    with SingleTickerProviderStateMixin {
  // Added SingleTickerProviderStateMixin
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isInitialized = false;
  late AnimationController _controller; // AnimationController for FAB

  @override
  void initState() {
    super.initState();
    debugPrint('OrderManagementScreen initState');
    // Initialize AnimationController
    _controller = AnimationController(
      vsync: this, // Use this as the TickerProvider
      duration: const Duration(milliseconds: 800),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose of AnimationController
    super.dispose();
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
      await orderProvider.fetchOrders(authProvider.token ?? '',
          authProvider.role ?? 'user', authProvider.userId ?? '');
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

  Future<void> _cancelOrder(String orderId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    try {
      debugPrint(
          'Attempting to cancel order $orderId with token: ${authProvider.token}');
      await orderProvider.cancelOrder(orderId, authProvider.token!);
      debugPrint('Order $orderId cancelled successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'سفارش با موفقیت لغو شد',
            textDirection: TextDirection.rtl,
            style: TextStyle(fontFamily: 'Vazir', color: Colors.white),
          ),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() {
        _isInitialized = false;
        _isLoading = true;
      });
      await _fetchData();
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (errorMessage.contains('403')) {
        errorMessage = 'عدم دسترسی: فقط سفارش‌های در انتظار قابل لغو هستند';
      } else if (errorMessage.contains('404')) {
        errorMessage = 'سفارش یافت نشد';
      } else if (errorMessage.contains('401')) {
        errorMessage = 'توکن نامعتبر است. لطفاً دوباره وارد شوید';
        await authProvider.logout();
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.login, (route) => false);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطا در لغو سفارش: $errorMessage',
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontFamily: 'Vazir', color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
      debugPrint('Error cancelling order $orderId: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final role = authProvider.role ?? 'user';

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: FadeIn(
            duration: const Duration(milliseconds: 800),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppColors.accent),
                ),
                const SizedBox(height: 16),
                Text(
                  'در حال بارگذاری سفارشات...',
                  style: TextStyle(
                    fontFamily: 'Vazir',
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        appBar: _buildAppBar(authProvider),
        body: Center(
          child: FadeIn(
            duration: const Duration(milliseconds: 800),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FontAwesomeIcons.exclamationTriangle,
                  color: Colors.red[400],
                  size: 50,
                ),
                const SizedBox(height: 16),
                Text(
                  'خطا در بارگذاری سفارشات: $_errorMessage',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Vazir',
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 24),
                _buildRetryButton(),
              ],
            ),
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
      appBar: _buildAppBar(authProvider),
      body: RefreshIndicator(
        color: AppColors.accent,
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
              gradient: const LinearGradient(
                colors: [Colors.orange, Colors.amber],
              ),
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
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.blueAccent],
              ),
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
              gradient: const LinearGradient(
                colors: [Colors.purple, Colors.purpleAccent],
              ),
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
              gradient: const LinearGradient(
                colors: [Colors.green, Colors.greenAccent],
              ),
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
              gradient: const LinearGradient(
                colors: [Colors.red, Colors.redAccent],
              ),
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
              gradient: const LinearGradient(
                colors: [Colors.grey, Colors.grey],
              ),
              orderProvider: orderProvider,
              authProvider: authProvider,
              productProvider: productProvider,
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller, // Use the initialized AnimationController
            curve: Curves.easeInOut,
          ),
        ),
        child: FloatingActionButton(
          backgroundColor: AppColors.accent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child:
              const FaIcon(FontAwesomeIcons.shoppingCart, color: Colors.white),
          onPressed: () {
            debugPrint('Navigating to cart');
            Navigator.pushNamed(context, AppRoutes.cart);
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar(AuthProvider authProvider) {
    return AppBar(
      title: const Text(
        'مدیریت سفارشات',
        style: TextStyle(
          fontFamily: 'Vazir',
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      backgroundColor: AppColors.primary,
      elevation: 4,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.signOutAlt, color: Colors.white),
          tooltip: 'خروج',
          onPressed: () async {
            await authProvider.logout();
            Navigator.pushNamedAndRemoveUntil(
                context, AppRoutes.login, (route) => false);
          },
        ),
      ],
    );
  }

  Widget _buildRetryButton() {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _isLoading = true;
          _hasError = false;
          _isInitialized = false;
        });
        _fetchData();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: Colors.black26,
        elevation: 8,
      ),
      child: const Text(
        'تلاش مجدد',
        style: TextStyle(
          fontFamily: 'Vazir',
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOrderGroup({
    required BuildContext context,
    required String title,
    required List<Order> orders,
    required IconData icon,
    required Color color,
    required LinearGradient gradient,
    required OrderProvider orderProvider,
    required AuthProvider authProvider,
    required ProductProvider productProvider,
  }) {
    return FadeIn(
      duration: const Duration(milliseconds: 600),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ExpansionTile(
            leading: FaIcon(icon, color: Colors.white, size: 28),
            title: Text(
              '$title (${orders.length})',
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontFamily: 'Vazir',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            children: orders.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'هیچ سفارشی در این دسته وجود ندارد',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ]
                : orders.map((order) {
                    final currentStatus = OrderStatus.values.firstWhere(
                      (status) =>
                          status.toString().split('.').last ==
                          order.status.toString().split('.').last,
                      orElse: () => OrderStatus.pending,
                    );

                    if (order.products.any((item) => item.productId == null)) {
                      debugPrint(
                          'Skipping order ${order.id} due to null product');
                      return const SizedBox.shrink();
                    }

                    List<OrderStatus> allowedStatuses = [];
                    if (authProvider.role == 'admin') {
                      allowedStatuses = OrderStatus.values;
                    } else if (authProvider.role == 'warehouse_manager' &&
                        currentStatus == OrderStatus.pending) {
                      allowedStatuses = [
                        OrderStatus.processed,
                        OrderStatus.cancelled,
                      ];
                    } else if (authProvider.role == 'delivery_agent' &&
                        (currentStatus == OrderStatus.processed ||
                            currentStatus == OrderStatus.shipped)) {
                      allowedStatuses = [
                        OrderStatus.delivered,
                        if (order.returnRequest) OrderStatus.returned,
                      ];
                    }

                    bool canCancel = (authProvider.role == 'user' &&
                            currentStatus == OrderStatus.pending &&
                            order.userId == authProvider.userId) ||
                        (authProvider.role == 'warehouse_manager' &&
                            currentStatus == OrderStatus.pending);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (order.status == OrderStatus.pending &&
                                DateTime.now()
                                        .difference(order.createdAt)
                                        .inHours <=
                                    24)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'جدید',
                                  style: TextStyle(
                                    fontFamily: 'Vazir',
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'سفارش #${order.id}',
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(
                                  fontFamily: 'Vazir',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'کاربر: ${order.userId}',
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontFamily: 'Vazir',
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              'مبلغ: ${order.totalAmount.toStringAsFixed(0)} تومان',
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontFamily: 'Vazir',
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              'تاریخ: ${order.createdAt.toString()}',
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontFamily: 'Vazir',
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              'درخواست مرجوعی: ${order.returnRequest ? 'بله' : 'خیر'}',
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontFamily: 'Vazir',
                                color: Colors.grey[700],
                              ),
                            ),
                            ExpansionTile(
                              title: const Text(
                                'محصولات',
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontFamily: 'Vazir',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              children: order.products.map((item) {
                                final product =
                                    productProvider.products.isNotEmpty
                                        ? productProvider.products.firstWhere(
                                            (p) => p.id == item.productId,
                                            orElse: () => Product(
                                              id: item.productId,
                                              name: 'محصول حذف شده',
                                              price: 0.0,
                                              categoryId: '',
                                              stock: 0,
                                            ),
                                          )
                                        : Product(
                                            id: item.productId,
                                            name: 'محصول حذف شده',
                                            price: 0.0,
                                            categoryId: '',
                                            stock: 0,
                                          );
                                return ListTile(
                                  leading: product.imageUrls != null &&
                                          product.imageUrls!.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: CachedNetworkImage(
                                            imageUrl:
                                                '${AppConfig.apiBaseUrl.replaceAll('/api', '')}${product.imageUrls!.first}',
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation(
                                                          AppColors.accent),
                                                ),
                                              ),
                                            ),
                                            errorWidget: (context, url, error) {
                                              debugPrint(
                                                  'Image load error for ${AppConfig.apiBaseUrl.replaceAll('/api', '')}${product.imageUrls!.first}: $error');
                                              return const Icon(
                                                  Icons.broken_image,
                                                  size: 50);
                                            },
                                          ),
                                        )
                                      : const Icon(Icons.image_not_supported,
                                          size: 50),
                                  title: Text(
                                    product.name,
                                    textDirection: TextDirection.rtl,
                                    style: const TextStyle(
                                      fontFamily: 'Vazir',
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'تعداد: ${item.quantity} | قیمت واحد: ${product.price.toStringAsFixed(0)} تومان',
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(
                                      fontFamily: 'Vazir',
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (canCancel)
                              IconButton(
                                icon: const FaIcon(
                                  FontAwesomeIcons.ban,
                                  color: Colors.red,
                                ),
                                tooltip: 'لغو سفارش',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16)),
                                      title: const Text(
                                        'تأیید لغو سفارش',
                                        style: TextStyle(
                                          fontFamily: 'Vazir',
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        textDirection: TextDirection.rtl,
                                      ),
                                      content: Text(
                                        'آیا مطمئن هستید که می‌خواهید سفارش #${order.id} را لغو کنید؟',
                                        style: const TextStyle(
                                            fontFamily: 'Vazir'),
                                        textDirection: TextDirection.rtl,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text(
                                            'خیر',
                                            style: TextStyle(
                                                fontFamily: 'Vazir',
                                                color: Colors.grey),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _cancelOrder(order.id);
                                          },
                                          child: const Text(
                                            'بله',
                                            style: TextStyle(
                                              fontFamily: 'Vazir',
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            if (allowedStatuses.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: DropdownButton<OrderStatus>(
                                  value: allowedStatuses.contains(currentStatus)
                                      ? currentStatus
                                      : allowedStatuses.firstOrNull,
                                  items: allowedStatuses.map((status) {
                                    return DropdownMenuItem<OrderStatus>(
                                      value: status,
                                      child: Text(
                                        status.toString().split('.').last,
                                        textDirection: TextDirection.rtl,
                                        style: const TextStyle(
                                          fontFamily: 'Vazir',
                                          color: Colors.black87,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (newStatus) async {
                                    if (newStatus != null &&
                                        newStatus != currentStatus) {
                                      try {
                                        debugPrint(
                                            'Updating order ${order.id} status to $newStatus');
                                        await orderProvider.updateOrderStatus(
                                            order.id,
                                            newStatus,
                                            authProvider.token!);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                              'وضعیت سفارش با موفقیت به‌روزرسانی شد',
                                              textDirection: TextDirection.rtl,
                                              style: TextStyle(
                                                  fontFamily: 'Vazir',
                                                  color: Colors.white),
                                            ),
                                            backgroundColor: AppColors.accent,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            duration:
                                                const Duration(seconds: 2),
                                          ),
                                        );
                                        setState(() {
                                          _isInitialized = false;
                                          _isLoading = true;
                                        });
                                        await _fetchData();
                                      } catch (e) {
                                        String errorMessage = e
                                            .toString()
                                            .replaceFirst('Exception: ', '');
                                        if (errorMessage.contains('403')) {
                                          errorMessage =
                                              'عدم دسترسی: لطفاً با حساب مناسب وارد شوید';
                                        } else if (errorMessage
                                            .contains('401')) {
                                          errorMessage =
                                              'توکن نامعتبر است. لطفاً دوباره وارد شوید';
                                          await authProvider.logout();
                                          Navigator.pushNamedAndRemoveUntil(
                                              context,
                                              AppRoutes.login,
                                              (route) => false);
                                        }
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'خطا در به‌روزرسانی وضعیت سفارش: $errorMessage',
                                              textDirection: TextDirection.rtl,
                                              style: const TextStyle(
                                                  fontFamily: 'Vazir',
                                                  color: Colors.white),
                                            ),
                                            backgroundColor: Colors.red,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            duration:
                                                const Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  underline: const SizedBox(),
                                  icon: const Icon(Icons.arrow_drop_down,
                                      color: AppColors.accent),
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          debugPrint(
                              'Navigating to order details: ${order.id}');
                          // TODO: Implement order details page if needed
                        },
                      ),
                    );
                  }).toList(),
          ),
        ),
      ),
    );
  }
}
