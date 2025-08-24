
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
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

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isInitialized = false;
  String _selectedTab = 'orders';
  String _selectedHomeTab = 'edit_profile';
  bool _userDataError = false;
  String _userDataErrorMessage = '';

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
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
      // Define futures as List<Future<dynamic>> to explicitly type it
      final List<Future<dynamic>> futures = [];
      // For non-admin roles, only fetch orders
      if (authProvider.token == null || authProvider.userId == null) {
        throw Exception('Token or User ID is null');
      }
      futures.add(orderProvider.fetchOrders(
          authProvider.token!, authProvider.role ?? 'user', authProvider.userId!));
      // For user role, also fetch products
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
        const SnackBar(
          content: Text('اطلاعات با موفقیت به‌روزرسانی شد',
              textDirection: TextDirection.rtl),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطا در به‌روزرسانی اطلاعات: ${_formatErrorMessage(e.toString())}',
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final role = authProvider.role ?? 'user';

    // Redirect to AdminDashboardScreen for admin, warehouse_manager, delivery_agent
    if (['admin', 'warehouse_manager', 'delivery_agent'].contains(role)) {
      return const AdminDashboardScreen();
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError) {
      return Scaffold(
        appBar: _buildAppBar(authProvider),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'خطا در بارگذاری اطلاعات: $_errorMessage',
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(authProvider),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: _buildTabContent(context, role),
        ),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        buttonBackgroundColor: AppColors.accent,
        color: AppColors.primary,
        animationDuration: const Duration(milliseconds: 400),
        items: [
          AnimatedScale(
            scale: _selectedTab == 'home' ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: const FaIcon(FontAwesomeIcons.home,
                color: Colors.white, size: 28),
          ),
          AnimatedScale(
            scale: _selectedTab == 'products' ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: const FaIcon(FontAwesomeIcons.store,
                color: Colors.white, size: 28),
          ),
          AnimatedScale(
            scale: _selectedTab == 'orders' ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: const FaIcon(FontAwesomeIcons.boxOpen,
                color: Colors.white, size: 28),
          ),
          AnimatedScale(
            scale: _selectedTab == 'cart' ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: const FaIcon(FontAwesomeIcons.shoppingCart,
                color: Colors.white, size: 28),
          ),
        ],
        onTap: (index) {
          setState(() {
            if (index == 0) {
              _selectedTab = 'home';
            } else if (index == 1) {
              _selectedTab = 'products';
            } else if (index == 2) {
              _selectedTab = 'orders';
            } else {
              _selectedTab = 'cart';
            }
          });
        },
      ),
    );
  }

  AppBar _buildAppBar(AuthProvider authProvider) {
    return AppBar(
      title: const Text('فروشگاه',
          style: TextStyle(fontFamily: 'Vazir', fontSize: 20)),
      backgroundColor: AppColors.primary,
      elevation: 4,
      actions: [
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.signOutAlt, size: 24),
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

  Widget _buildTabContent(BuildContext context, String role) {
    switch (_selectedTab) {
      case 'home':
        return HomeTab(
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
            });
          },
        );
      case 'products':
        return const ProductsTab();
      case 'orders':
        return const OrdersTab();
      case 'cart':
        return const CartScreen();
      default:
        return const Center(
          child: Text(
            'تب نامعتبر',
            style: TextStyle(fontSize: 16, fontFamily: 'Vazir'),
            textDirection: TextDirection.rtl,
          ),
        );
    }
  }
}
