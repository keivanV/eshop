import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/product_card.dart';
import '../routes/app_routes.dart';
import '../constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    debugPrint('HomeScreen initState');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    if (_isInitialized) {
      debugPrint('Fetch products skipped: already initialized');
      return;
    }
    _isInitialized = true;
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    try {
      debugPrint('Starting fetchProducts...');
      await productProvider.fetchProducts();
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
      debugPrint('Error in fetchData: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('محصولات', style: TextStyle(fontFamily: 'Vazir')),
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
                'خطا در بارگذاری محصولات: $_errorMessage',
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('محصولات', style: TextStyle(fontFamily: 'Vazir')),
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
          if (authProvider.role == 'admin')
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.plusCircle),
              tooltip: 'مدیریت محصولات',
              onPressed: () {
                debugPrint('Navigating to product management');
                Navigator.pushNamed(context, AppRoutes.productManagement);
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          debugPrint('Manual refresh triggered for products');
          _isInitialized = false;
          await _fetchData();
        },
        child: Consumer<ProductProvider>(
          builder: (ctx, productProvider, _) {
            debugPrint(
                'Rendering product grid with ${productProvider.products.length} products');
            if (productProvider.products.isEmpty) {
              return const Center(
                child: Text(
                  'هیچ محصولی یافت نشد',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontSize: 16, fontFamily: 'Vazir'),
                ),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2 / 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: productProvider.products.length,
              itemBuilder: (_, i) {
                debugPrint(
                    'Creating ProductCard for ${productProvider.products[i].id}');
                return ProductCard(product: productProvider.products[i]);
              },
            );
          },
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
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        buttonBackgroundColor: AppColors.accent,
        color: AppColors.primary,
        animationDuration: const Duration(milliseconds: 300),
        items: const [
          FaIcon(FontAwesomeIcons.home, color: Colors.white),
          FaIcon(FontAwesomeIcons.boxOpen, color: Colors.white),
          FaIcon(FontAwesomeIcons.chartBar, color: Colors.white),
        ],
        onTap: (index) {
          if (index == 1) {
            debugPrint('Navigating to orders');
            Navigator.pushNamed(context, AppRoutes.orderManagement);
          } else if (index == 2) {
            debugPrint('Navigating to dashboard');
            Navigator.pushNamed(context, AppRoutes.dashboard);
          }
        },
      ),
    );
  }
}
