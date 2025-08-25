import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../routes/app_routes.dart';
import '../constants.dart';
import '../screens/home_tab.dart';
import '../screens/orders_tab.dart';
import '../screens/cart_screen.dart';
import '../screens/products_tab.dart';
import '../screens/admin_dashboard_screen.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isInitialized = false;
  String _selectedTab = 'orders';
  String _selectedHomeTab = 'edit_profile';
  bool _userDataError = false;
  String _userDataErrorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (_isInitialized) {
      debugPrint('Fetch data skipped: already initialized');
      return;
    }
    _isInitialized = true;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    try {
      final List<Future<dynamic>> futures = [];
      if (authProvider.token == null || authProvider.userId == null) {
        throw Exception('Token or User ID is null');
      }
      futures.add(orderProvider.fetchOrders(authProvider.token!,
          authProvider.role ?? 'user', authProvider.userId!));
      if (authProvider.role == 'user') {
        futures.add(productProvider.fetchProducts());
      }
      await Future.wait(futures);

      try {
        await _fetchUserData(authProvider);
      } catch (e) {
        setState(() {
          _userDataError = true;
          _userDataErrorMessage = _formatErrorMessage(e.toString());
          _usernameController.text = authProvider.userId ?? '';
          _emailController.text = '';
        });
      }

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
          _errorMessage = _formatErrorMessage(e.toString());
        });
      }
      debugPrint('Error in fetchData: $e');
    }
  }

  String _formatErrorMessage(String error) {
    if (error.contains('403')) {
      return 'عدم دسترسی: لطفاً دوباره وارد شوید';
    } else if (error.contains('404')) {
      return 'داده‌ای یافت نشد';
    } else {
      return error.replaceFirst('Exception: ', '');
    }
  }

  Future<void> _fetchUserData(AuthProvider authProvider) async {
    final userData =
        await ApiService.getUserById(authProvider.userId!, authProvider.token!);
    if (mounted) {
      setState(() {
        _usernameController.text =
            userData['username'] ?? authProvider.userId ?? '';
        _emailController.text = userData['email'] ?? '';
        _userDataError = false;
      });
    }
  }

  Future<void> _updateUserProfile(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final userData = await ApiService.updateUser(
        authProvider.userId ?? '',
        authProvider.token ?? '',
        _usernameController.text,
        _emailController.text,
      );
      authProvider.updateUserInfo(_usernameController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'اطلاعات با موفقیت به‌روزرسانی شد',
            textDirection: TextDirection.rtl,
            style: TextStyle(
                fontFamily: 'Vazir', fontSize: 14, color: Colors.white),
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
          elevation: 6,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطا در به‌روزرسانی اطلاعات: ${_formatErrorMessage(e.toString())}',
            textDirection: TextDirection.rtl,
            style: const TextStyle(
                fontFamily: 'Vazir', fontSize: 14, color: Colors.white),
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
          elevation: 6,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final role = authProvider.role ?? 'user';

    if (['admin', 'warehouse_manager', 'delivery_agent'].contains(role)) {
      return const AdminDashboardScreen();
    }

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: ZoomIn(
            duration: const Duration(milliseconds: 600),
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
            duration: const Duration(milliseconds: 600),
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
            colors: [AppColors.primary.withOpacity(0.2), Colors.grey.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: FadeIn(
            duration: const Duration(milliseconds: 400),
            child: _buildTabContent(context, role),
          ),
        ),
      ),
      bottomNavigationBar: _buildCustomNavigationBar(),
    );
  }

  AppBar _buildAppBar(AuthProvider authProvider) {
    return AppBar(
      title: SlideInDown(
        duration: const Duration(milliseconds: 600),
        child: const Text(
          'فروشگاه',
          style: TextStyle(
            fontFamily: 'Vazir',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      backgroundColor: AppColors.primary,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.accent.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border(bottom: BorderSide(color: Colors.black87, width: 1.5)),
        ),
      ),
      actions: [
        FadeInRight(
          duration: const Duration(milliseconds: 600),
          child: IconButton(
            icon: const FaIcon(FontAwesomeIcons.rightFromBracket,
                size: 22, color: Colors.white),
            tooltip: 'خروج',
            onPressed: () async {
              await authProvider.logout();
              Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.login, (route) => false);
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
          colors: [
            AppColors.primary.withOpacity(0.9),
            AppColors.accent.withOpacity(0.9)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(top: BorderSide(color: Colors.black87, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: BottomNavigationBar(
        currentIndex:
            ['home', 'products', 'orders', 'cart'].indexOf(_selectedTab),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey.shade300,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Vazir',
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Vazir',
          fontSize: 10,
        ),
        type: BottomNavigationBarType.fixed,
        items: [
          _buildNavItem(FontAwesomeIcons.house, 'خانه', 'home'),
          _buildNavItem(FontAwesomeIcons.store, 'محصولات', 'products'),
          _buildNavItem(FontAwesomeIcons.boxOpen, 'سفارشات', 'orders'),
          _buildNavItem(FontAwesomeIcons.cartShopping, 'سبد خرید', 'cart'),
        ],
        onTap: (index) {
          setState(() {
            _selectedTab = ['home', 'products', 'orders', 'cart'][index];
            _animationController.reset();
            _animationController.forward();
          });
        },
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
      IconData icon, String label, String tab) {
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _selectedTab == tab
              ? AppColors.accent.withOpacity(0.2)
              : Colors.transparent,
          border: _selectedTab == tab
              ? Border.all(color: Colors.black87, width: 1)
              : null,
          boxShadow: _selectedTab == tab
              ? [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: FaIcon(
          icon,
          size: _selectedTab == tab ? 26 : 20,
          color: _selectedTab == tab ? Colors.white : Colors.grey.shade300,
        ),
      ),
      label: label,
    );
  }

  Widget _buildCustomLoader() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black87, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 3,
              ),
            ],
          ),
          child: const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            strokeWidth: 5,
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
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black87, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ZoomIn(
            duration: const Duration(milliseconds: 600),
            child: const FaIcon(
              FontAwesomeIcons.exclamationTriangle,
              color: Colors.redAccent,
              size: 36,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'خطا در بارگذاری اطلاعات: $_errorMessage',
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Vazir',
              fontWeight: FontWeight.w600,
              color: Colors.redAccent,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Bounce(
            duration: const Duration(milliseconds: 600),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accent, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black87, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                    _isInitialized = false;
                  });
                  _fetchData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  elevation: 0,
                ),
                child: const Text(
                  'تلاش مجدد',
                  style: TextStyle(
                    fontFamily: 'Vazir',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, String role) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black87, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: _getTabWidget(role),
        ),
      ),
    );
  }

  Widget _getTabWidget(String role) {
    switch (_selectedTab) {
      case 'home':
        return HomeTab(
          key: const ValueKey('home'),
          role: role,
          selectedHomeTab: _selectedHomeTab,
          userDataError: _userDataError,
          userDataErrorMessage: _userDataErrorMessage,
          formKey: _formKey,
          usernameController: _usernameController,
          emailController: _emailController,
          onUpdateProfile: _updateUserProfile,
          onFetchUserData: _fetchUserData,
          onRefreshData: () async {
            setState(() {
              _isLoading = true;
              _isInitialized = false;
            });
            await _fetchData();
          },
          onTabChanged: (tab) {
            setState(() {
              _selectedHomeTab = tab;
              _animationController.reset();
              _animationController.forward();
            });
          },
        );
      case 'products':
        return const ProductsTab(key: ValueKey('products'));
      case 'orders':
        return const OrdersTab(key: ValueKey('orders'));
      case 'cart':
        return const CartScreen(key: ValueKey('cart'));
      default:
        return Center(
          child: Text(
            'تب نامعتبر',
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Vazir',
              color: AppColors.primary,
            ),
            textDirection: TextDirection.rtl,
          ),
        );
    }
  }
}
