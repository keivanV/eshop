import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/models/product.dart';
import '../models/order.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../providers/order_provider.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../constants.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

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
        body: Center(
          child: Text(
            'خطا: $_errorMessage',
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('سبد خرید')),
      body: cartProvider.items.isEmpty
          ? const Center(
              child: Text(
                'سبد خرید شما خالی است',
                textDirection: TextDirection.rtl,
                style: TextStyle(fontSize: 16),
              ),
            )
          : Consumer<CartProvider>(
              builder: (ctx, cartProvider, _) {
                debugPrint('Rendering cart items');
                return ListView.builder(
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
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        child: ListTile(
                          leading: const Icon(Icons.inventory),
                          title: Text(
                            product.name,
                            textDirection: TextDirection.rtl,
                          ),
                          subtitle: Text(
                            'تعداد: ${entry.value} | قیمت: ${(product.price * entry.value).toStringAsFixed(0)} تومان',
                            textDirection: TextDirection.rtl,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle),
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
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'جمع کل: ${cartProvider.getTotalAmount(productProvider.products).toStringAsFixed(0)} تومان',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textDirection: TextDirection.rtl,
              ),
              ElevatedButton(
                onPressed: cartProvider.items.isEmpty
                    ? null
                    : () async {
                        setState(() {
                          _isLoading = true;
                        });
                        try {
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'سفارش با موفقیت ثبت شد',
                                textDirection: TextDirection.rtl,
                              ),
                            ),
                          );
                          Navigator.pushNamed(
                              context, AppRoutes.orderManagement);
                        } catch (e) {
                          setState(() {
                            _hasError = true;
                            _errorMessage =
                                e.toString().replaceFirst('Exception: ', '');
                          });
                        } finally {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
                child: const Text('ثبت سفارش'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
