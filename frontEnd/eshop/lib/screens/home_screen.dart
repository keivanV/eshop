import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/product_card.dart';
import '../routes/app_routes.dart';
import '../constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isInitialized = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    debugPrint('HomeScreen initState');
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (_isInitialized) {
      debugPrint('Fetch products skipped: already initialized');
      return;
    }
    _isInitialized = true;
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      debugPrint('Starting fetchProducts and fetchOrders...');
      final List<Future<dynamic>> futures = [];
      futures.add(productProvider.fetchProducts());
      futures.add(orderProvider.fetchOrders(
        authProvider.token ?? '',
        authProvider.role ?? 'user',
        authProvider.userId ?? '',
      ));
      await Future.wait(futures);
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
      return Scaffold(
        body: Center(
          child: ZoomIn(
            duration: const Duration(milliseconds: 1000),
            child: _buildCustomLoader(),
          ),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        appBar: _buildAppBar(authProvider),
        body: Center(
          child: FadeInUp(
            duration: const Duration(milliseconds: 1000),
            child: _buildErrorCard(),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(authProvider),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary.withOpacity(0.2), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: Colors.white,
          onRefresh: () async {
            debugPrint('Manual refresh triggered for products');
            _isInitialized = false;
            await _fetchData();
            _animationController.reset();
            _animationController.forward();
          },
          child: Consumer<ProductProvider>(
            builder: (ctx, productProvider, _) {
              debugPrint(
                  'Rendering product grid with ${productProvider.products.length} products');
              if (productProvider.products.isEmpty) {
                return Center(
                  child: FadeIn(
                    duration: const Duration(milliseconds: 800),
                    child: const Text(
                      'هیچ محصولی یافت نشد',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'Vazir',
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2 / 3,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                ),
                itemCount: productProvider.products.length,
                itemBuilder: (_, i) {
                  debugPrint(
                      'Creating ProductCard for ${productProvider.products[i].id}');
                  return FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: Duration(milliseconds: 200 * i),
                    child: GestureDetector(
                      onTapDown: (_) => setState(() {}),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        transform: Matrix4.identity()..scale(1.0),
                        transformAlignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child:
                            ProductCard(product: productProvider.products[i]),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: Bounce(
        duration: const Duration(milliseconds: 1000),
        child: FloatingActionButton(
          backgroundColor: AppColors.accent,
          elevation: 12,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: const FaIcon(FontAwesomeIcons.shoppingCart,
              color: Colors.white, size: 28),
          onPressed: () {
            debugPrint('Navigating to cart');
            Navigator.pushNamed(context, AppRoutes.cart);
          },
        ),
      ),
      bottomNavigationBar: _buildCustomNavigationBar(),
    );
  }

  AppBar _buildAppBar(AuthProvider authProvider) {
    return AppBar(
      title: SlideInDown(
        duration: const Duration(milliseconds: 1000),
        child: const Text(
          'محصولات',
          style: TextStyle(
            fontFamily: 'Vazir',
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.accent.withOpacity(0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
      elevation: 0,
      actions: [
        ElasticIn(
          duration: const Duration(milliseconds: 1000),
          child: IconButton(
            icon: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(6),
              child: const FaIcon(FontAwesomeIcons.signOutAlt,
                  size: 26, color: Colors.white),
            ),
            tooltip: 'خروج',
            onPressed: () async {
              await authProvider.logout();
              Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.login, (route) => false);
            },
          ),
        ),
        if (authProvider.role == 'admin')
          ElasticIn(
            duration: const Duration(milliseconds: 1000),
            child: IconButton(
              icon: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(6),
                child: const FaIcon(FontAwesomeIcons.plusCircle,
                    size: 26, color: Colors.white),
              ),
              tooltip: 'مدیریت محصولات',
              onPressed: () {
                debugPrint('Navigating to product management');
                Navigator.pushNamed(context, AppRoutes.productManagement);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCustomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.accent.withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: BottomNavigationBar(
        currentIndex: 0, // Home is always selected in HomeScreen
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.7),
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Vazir',
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Vazir',
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        items: [
          _buildNavItem(FontAwesomeIcons.home, 'خانه', true),
          _buildNavItem(FontAwesomeIcons.boxOpen, 'سفارشات', false),
          _buildNavItem(FontAwesomeIcons.chartBar, 'داشبورد', false),
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

  BottomNavigationBarItem _buildNavItem(
      IconData icon, String label, bool isSelected) {
    return BottomNavigationBarItem(
      icon: Bounce(
        duration: const Duration(milliseconds: 400),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.all(12),
          transform: Matrix4.identity()..scale(isSelected ? 1.15 : 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.7),
                      blurRadius: 14,
                      spreadRadius: 4,
                    ),
                  ]
                : [],
          ),
          child: FaIcon(
            icon,
            size: isSelected ? 32 : 26,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
          ),
        ),
      ),
      label: label,
    );
  }

  Widget _buildCustomLoader() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ZoomIn(
          duration: const Duration(milliseconds: 1000),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 28,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              strokeWidth: 10,
            ),
          ),
        ),
        const SizedBox(height: 24),
        FadeIn(
          duration: const Duration(milliseconds: 800),
          child: const Text(
            'در حال بارگذاری...',
            style: TextStyle(
              fontFamily: 'Vazir',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 14,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ZoomIn(
            duration: const Duration(milliseconds: 800),
            child: const FaIcon(
              FontAwesomeIcons.exclamationTriangle,
              color: Colors.redAccent,
              size: 56,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'خطا در بارگذاری محصولات: $_errorMessage',
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontSize: 20,
              fontFamily: 'Vazir',
              fontWeight: FontWeight.w600,
              color: Colors.redAccent,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Bounce(
            duration: const Duration(milliseconds: 1000),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                  _isInitialized = false;
                });
                _fetchData();
                _animationController.reset();
                _animationController.forward();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                elevation: 8,
                shadowColor: AppColors.accent.withOpacity(0.5),
              ),
              child: const Text(
                'تلاش مجدد',
                style: TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
