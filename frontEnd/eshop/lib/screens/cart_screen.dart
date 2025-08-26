import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animate_do/animate_do.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../providers/order_provider.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../constants.dart';
import '../services/api_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    debugPrint('CartScreen initState');
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _checkInventory(
      List<MapEntry<String, int>> items, String token) async {
    try {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      for (var entry in items) {
        debugPrint('Checking product: ${entry.key}, quantity: ${entry.value}');
        final product = await ApiService.getProductById(entry.key, token);
        if (product == null) {
          debugPrint('Product not found: ${entry.key}');
          setState(() {
            _hasError = true;
            _errorMessage = 'محصول ${entry.key} یافت نشد';
          });
          return false;
        }
        final cachedProduct = productProvider.products.firstWhere(
          (p) => p.id == entry.key,
          orElse: () => Product(
            id: entry.key,
            name: product['name'] ?? 'نامشخص',
            price: product['price']?.toDouble() ?? 0.0,
            categoryId: product['category']?['_id'] ?? '',
            stock: product['stock']?.toInt() ?? 0,
          ),
        );
        debugPrint(
            'Product found: ${product['name']}, cached stock: ${cachedProduct.stock}');
        final inventory =
            await ApiService.getInventoryByProduct(entry.key, token);
        final inventoryQuantity =
            inventory['quantity']?.toInt() ?? cachedProduct.stock;
        debugPrint(
            'Inventory response: $inventory, using quantity: $inventoryQuantity');
        if (inventoryQuantity < entry.value) {
          debugPrint(
              'Insufficient inventory for product: ${entry.key}, required: ${entry.value}, available: $inventoryQuantity');
          setState(() {
            _hasError = true;
            _errorMessage =
                'موجودی کافی برای محصول ${product['name']} وجود ندارد (موجود: $inventoryQuantity)';
          });
          return false;
        }
      }
      return true;
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Error checking inventory: $e');
      if (errorMessage.contains('Unauthorized: Invalid or expired token')) {
        _handleTokenExpiration();
        return false;
      }
      setState(() {
        _hasError = true;
        _errorMessage = 'خطا در بررسی موجودی: $errorMessage';
      });
      return false;
    }
  }

  void _handleTokenExpiration() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'توکن شما منقضی شده، لطفاً مجدد وارد شوید',
          textDirection: TextDirection.rtl,
          style:
              TextStyle(fontFamily: 'Vazir', fontSize: 13, color: Colors.white),
        ),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    await authProvider.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_isLoading) {
      return Scaffold(
        body: Center(child: _buildCustomLoader()),
      );
    }

    if (_hasError) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: Center(child: _buildErrorCard()),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: cartProvider.items.isEmpty
          ? Center(child: _buildEmptyCartCard())
          : Consumer<CartProvider>(
              builder: (ctx, cartProvider, _) {
                debugPrint('Rendering cart items');
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: cartProvider.items.length,
                  itemBuilder: (ctx, i) {
                    final entry = cartProvider.items.entries.elementAt(i);
                    final product = productProvider.products.firstWhere(
                      (p) => p.id == entry.key,
                      orElse: () => Product(
                        id: entry.key,
                        name: 'نامشخص',
                        price: 0,
                        categoryId: '',
                        stock: 0,
                      ),
                    );
                    final imageUrl = product.imageUrls != null &&
                            product.imageUrls!.isNotEmpty
                        ? product.imageUrls!.first
                        : 'https://placehold.co/50x50';
                    return FadeInUp(
                      duration: const Duration(milliseconds: 400),
                      delay: Duration(milliseconds: 100 * i),
                      child: Dismissible(
                        key: Key(entry.key),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          debugPrint('Removing ${entry.key} from cart');
                          cartProvider.removeItem(entry.key);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'محصول ${product.name} از سبد خرید حذف شد',
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(
                                    fontFamily: 'Vazir',
                                    fontSize: 11,
                                    color: Colors.white),
                              ),
                              backgroundColor: Colors.red.shade600,
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          );
                        },
                        background: Container(
                          color: Colors.red.shade600,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 12),
                          child: const FaIcon(FontAwesomeIcons.trash,
                              color: Colors.white, size: 18),
                        ),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  imageUrl,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const FaIcon(
                                    FontAwesomeIcons.image,
                                    color: Colors.grey,
                                    size: 24,
                                  ),
                                ),
                              ),
                              title: Text(
                                product.name,
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(
                                  fontFamily: 'Vazir',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'تعداد: ${entry.value} | ${(product.price * entry.value).toStringAsFixed(0)} تومان',
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(
                                      fontFamily: 'Vazir',
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    'موجودی: ${product.stock}',
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(
                                      fontFamily: 'Vazir',
                                      fontSize: 10,
                                      color: product.stock >= entry.value
                                          ? Colors.green.shade600
                                          : Colors.red.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: FaIcon(
                                  FontAwesomeIcons.minusCircle,
                                  color: Colors.red.shade600,
                                  size: 16,
                                ),
                                onPressed: () {
                                  debugPrint(
                                      'Updating quantity for ${entry.key} to ${entry.value - 1}');
                                  cartProvider.updateQuantity(
                                      entry.key, entry.value - 1);
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: cartProvider.items.isEmpty
          ? null
          : BottomAppBar(
              color: Colors.white,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(color: Colors.grey.shade300, width: 1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FadeInUp(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        'جمع: ${cartProvider.getTotalAmount(productProvider.products).toStringAsFixed(0)} تومان',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Vazir',
                          color: AppColors.primary,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    ZoomIn(
                      duration: const Duration(milliseconds: 400),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accent,
                              AppColors.primary.withOpacity(0.9)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            setState(() {
                              _isLoading = true;
                            });
                            try {
                              debugPrint(
                                  'Checking inventory before creating order');
                              final inventoryValid = await _checkInventory(
                                  cartProvider.items.entries.toList(),
                                  authProvider.token!);
                              if (!inventoryValid) {
                                return;
                              }
                              debugPrint('Creating order from cart');
                              final total = cartProvider
                                  .getTotalAmount(productProvider.products);
                              final orderItems = cartProvider.items.entries
                                  .map((e) => OrderItem(
                                      productId: e.key, quantity: e.value))
                                  .toList();
                              await orderProvider.createOrder(
                                  orderItems, total, authProvider.token!);
                              cartProvider.clear();
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'سفارش با موفقیت ثبت شد',
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(
                                        fontFamily: 'Vazir',
                                        fontSize: 11,
                                        color: Colors.white),
                                  ),
                                  backgroundColor: AppColors.accent,
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              );
                              Navigator.pushNamed(
                                  context, AppRoutes.orderManagement);
                            } catch (e) {
                              String errorMessage = e
                                  .toString()
                                  .replaceFirst('Exception: ', '')
                                  .replaceFirst(
                                      RegExp(r'400 - {"msg":"[^"]+"}'), '');
                              if (errorMessage.contains(
                                  'Unauthorized: Invalid or expired token')) {
                                _handleTokenExpiration();
                                return;
                              }
                              setState(() {
                                _hasError = true;
                                _errorMessage = errorMessage;
                              });
                            } finally {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          },
                          icon: const FaIcon(FontAwesomeIcons.check,
                              color: Colors.white, size: 14),
                          label: const Text(
                            'ثبت سفارش',
                            style: TextStyle(
                              fontFamily: 'Vazir',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return AppBar(
      title: const Text(
        'سبد خرید',
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

  Widget _buildCustomLoader() {
    return FadeIn(
      duration: const Duration(milliseconds: 800),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ZoomIn(
            duration: const Duration(milliseconds: 600),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                strokeWidth: 4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'در حال بارگذاری...',
            style: TextStyle(
              fontFamily: 'Vazir',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ZoomIn(
              duration: const Duration(milliseconds: 400),
              child: const FaIcon(
                FontAwesomeIcons.exclamationTriangle,
                color: Colors.redAccent,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'خطا: $_errorMessage',
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Vazir',
                fontWeight: FontWeight.w600,
                color: Colors.redAccent,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ZoomIn(
              duration: const Duration(milliseconds: 400),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.accent, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _errorMessage = '';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: const Text(
                    'تلاش مجدد',
                    style: TextStyle(
                      fontFamily: 'Vazir',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCartCard() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ZoomIn(
              duration: const Duration(milliseconds: 400),
              child: const FaIcon(
                FontAwesomeIcons.cartShopping,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'سبد خرید شما خالی است',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Vazir',
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
