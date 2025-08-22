import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../routes/app_routes.dart';
import '../constants.dart';
import '../services/api_service.dart';
import 'home_tab.dart';
import 'orders_tab.dart';
import 'dashboard_tab.dart';

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
  String _selectedTab = 'home';
  String _selectedMenuTab = 'products';
  String _selectedHomeTab = 'edit_profile';
  bool _userDataError = false;
  String _userDataErrorMessage = '';

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    debugPrint('DashboardScreen initState');
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
      debugPrint('Fetching products, orders, and user data...');
      await Future.wait([
        productProvider.fetchProducts().then((_) {
          debugPrint('Products fetched: ${productProvider.products.length}');
        }),
        orderProvider
            .fetchOrders(
          authProvider.token ?? '',
          authProvider.role ?? 'user',
          authProvider.userId ?? '',
        )
            .then((_) {
          debugPrint('Orders fetched: ${orderProvider.orders.length}');
          debugPrint(
              'Order statuses: ${orderProvider.orders.map((o) => o.status.toString()).toList()}');
        }),
      ]);

      try {
        if (authProvider.userId == null || authProvider.token == null) {
          throw Exception('User ID or token is null');
        }
        await _fetchUserData(authProvider);
      } catch (e) {
        debugPrint('Error fetching user data: $e');
        setState(() {
          _userDataError = true;
          _userDataErrorMessage = e.toString().replaceFirst('Exception: ', '');
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
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
      debugPrint('Error in fetchData: $e');
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
              'خطا در به‌روزرسانی اطلاعات: ${e.toString().replaceFirst('Exception: ', '')}',
              textDirection: TextDirection.rtl),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final role = authProvider.role ?? 'user';

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
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
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
            scale: _selectedTab == 'orders' ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: const FaIcon(FontAwesomeIcons.boxOpen,
                color: Colors.white, size: 28),
          ),
          AnimatedScale(
            scale: _selectedTab == 'dashboard' ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: const FaIcon(FontAwesomeIcons.chartBar,
                color: Colors.white, size: 28),
          ),
        ],
        onTap: (index) {
          setState(() {
            if (index == 0) {
              _selectedTab = 'home';
              debugPrint('Switched to home tab');
            } else if (index == 1) {
              _selectedTab = 'orders';
              debugPrint('Switched to orders tab');
            } else {
              _selectedTab = 'dashboard';
              debugPrint('Switched to dashboard tab');
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
      case 'orders':
        return const OrdersTab();
      case 'dashboard':
        return DashboardTab(
          role: role,
          selectedMenuTab: _selectedMenuTab,
          onTabChanged: (tab) {
            setState(() {
              _selectedMenuTab = tab;
            });
          },
        );
      default:
        return const Center(
          child: Text(
            'تب نامعتبر',
            textDirection: TextDirection.rtl,
            style: TextStyle(fontSize: 16, fontFamily: 'Vazir'),
          ),
        );
    }
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String tab,
    required bool isSelected,
    required void Function(String) onTabChanged,
  }) {
    return GestureDetector(
      onTap: () {
        debugPrint('Switching to menu tab: $tab');
        onTabChanged(tab);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 120,
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: isSelected
                ? [AppColors.accent, AppColors.primary.withOpacity(0.9)]
                : [Colors.grey.shade200, Colors.grey.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(isSelected ? 0.5 : 0.3),
              spreadRadius: isSelected ? 3 : 2,
              blurRadius: isSelected ? 8 : 5,
              offset: const Offset(0, 3),
            ),
          ],
          border: isSelected
              ? Border.all(color: Colors.white, width: 2)
              : Border.all(color: Colors.transparent),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade700,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Vazir',
                fontSize: 14,
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          FaIcon(icon, color: AppColors.accent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$label: $value',
              style: const TextStyle(
                fontFamily: 'Vazir',
                fontSize: 18,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }
}
