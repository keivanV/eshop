// lib/screens/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

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
      debugPrint('Error checking inventory: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'خطا در بررسی موجودی: $e';
      });
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    debugPrint('CartScreen initState');
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    debugPrint('Building CartScreen');
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('سبد خرید', style: TextStyle(fontFamily: 'Vazir')),
          backgroundColor: AppColors.primary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'خطا: $_errorMessage',
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontSize: 16, fontFamily: 'Vazir'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _errorMessage = '';
                  });
                },
                child: const Text(
                  'تلاش مجدد',
                  style: TextStyle(fontFamily: 'Vazir'),
                ),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('سبد خرید', style: TextStyle(fontFamily: 'Vazir')),
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
      body: cartProvider.items.isEmpty
          ? const Center(
              child: Text(
                'سبد خرید شما خالی است',
                textDirection: TextDirection.rtl,
                style: TextStyle(fontSize: 16, fontFamily: 'Vazir'),
              ),
            )
          : Consumer<CartProvider>(
              builder: (ctx, cartProvider, _) {
                debugPrint('Rendering cart items');
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
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
                    return Dismissible(
                      key: Key(entry.key),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        debugPrint('Removing ${entry.key} from cart');
                        cartProvider.removeItem(entry.key);
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const FaIcon(FontAwesomeIcons.trash,
                            color: Colors.white),
                      ),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image),
                            ),
                          ),
                          title: Text(
                            product.name,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                                fontFamily: 'Vazir',
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'تعداد: ${entry.value} | قیمت: ${(product.price * entry.value).toStringAsFixed(0)} تومان | موجودی: ${product.stock}',
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(fontFamily: 'Vazir'),
                          ),
                          trailing: IconButton(
                            icon: const FaIcon(FontAwesomeIcons.minusCircle,
                                color: Colors.red),
                            onPressed: () {
                              debugPrint(
                                  'Updating quantity for ${entry.key} to ${entry.value - 1}');
                              cartProvider.updateQuantity(
                                  entry.key, entry.value - 1);
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: BottomAppBar(
        color: AppColors.primary,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'جمع کل: ${cartProvider.getTotalAmount(productProvider.products).toStringAsFixed(0)} تومان',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Vazir',
                  color: Colors.white,
                ),
                textDirection: TextDirection.rtl,
              ),
              ElevatedButton.icon(
                onPressed: cartProvider.items.isEmpty
                    ? null
                    : () async {
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
                            return; // Error message set in _checkInventory
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
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'سفارش با موفقیت ثبت شد',
                                textDirection: TextDirection.rtl,
                                style: TextStyle(fontFamily: 'Vazir'),
                              ),
                              backgroundColor: AppColors.accent,
                            ),
                          );
                          Navigator.pushNamed(
                              context, AppRoutes.orderManagement);
                        } catch (e) {
                          setState(() {
                            _hasError = true;
                            _errorMessage = e
                                .toString()
                                .replaceFirst('Exception: ', '')
                                .replaceFirst(
                                    RegExp(r'400 - {"msg":"[^"]+"}'), '');
                          });
                        } finally {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
                icon: const FaIcon(FontAwesomeIcons.checkCircle,
                    color: Colors.white),
                label: const Text(
                  'ثبت سفارش',
                  style: TextStyle(fontFamily: 'Vazir', color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
