import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/category_provider.dart';
import '../routes/app_routes.dart';
import '../constants.dart';
import '../screens/category_management_screen.dart';
import '../screens/product_management_screen.dart';
import '../screens/inventory_management_screen.dart';
import '../screens/order_management_screen.dart';
import '../screens/user_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  Future<void> _fetchData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final inventoryProvider =
        Provider.of<InventoryProvider>(context, listen: false);
    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);

    try {
      await Future.wait([
        productProvider.fetchProducts(),
        orderProvider.fetchOrders(
            authProvider.token!, 'admin', authProvider.userId!),
        inventoryProvider.fetchInventory(authProvider.token!),
        categoryProvider.fetchCategories(),
      ]);
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = _formatErrorMessage(e.toString());
        });
      }
    }
  }

  String _formatErrorMessage(String error) {
    if (error.contains('403'))
      return 'عدم دسترسی: لطفاً با حساب مدیر وارد شوید';
    if (error.contains('404')) return 'داده‌ای یافت نشد';
    return error.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'پنل مدیریت، ${authProvider.userId ?? 'ادمین'}',
          style: const TextStyle(
              fontFamily: 'Vazir', fontSize: 22, fontWeight: FontWeight.bold),
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.accent.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
        actions: [
          IconButton(
            icon:
                const FaIcon(FontAwesomeIcons.signOutAlt, color: Colors.white),
            onPressed: () async {
              await authProvider.logout();
              Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.login, (route) => false);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppColors.accent)))
          : _hasError
              ? _buildErrorWidget()
              : _buildTabContent(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() => _selectedIndex = index);
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(
              fontFamily: 'Vazir', fontSize: 12, fontWeight: FontWeight.bold),
          unselectedLabelStyle:
              const TextStyle(fontFamily: 'Vazir', fontSize: 12),
          items: [
            _buildNavItem(FontAwesomeIcons.thList, 'دسته‌بندی‌ها'),
            _buildNavItem(FontAwesomeIcons.box, 'محصولات'),
            _buildNavItem(FontAwesomeIcons.warehouse, 'انبار'),
            _buildNavItem(FontAwesomeIcons.boxOpen, 'سفارشات'),
            _buildNavItem(FontAwesomeIcons.users, 'کاربران'),
            _buildNavItem(FontAwesomeIcons.chartPie, 'آمار'),
          ],
        ),
      ),
      backgroundColor: Colors.grey.shade100,
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _selectedIndex == _getIndexForLabel(label)
              ? AppColors.accent.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: FaIcon(icon, size: 24),
      ),
      label: label,
    );
  }

  int _getIndexForLabel(String label) {
    const labels = [
      'دسته‌بندی‌ها',
      'محصولات',
      'انبار',
      'سفارشات',
      'کاربران',
      'آمار'
    ];
    return labels.indexOf(label);
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Card(
            elevation: 8,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'خطا: $_errorMessage',
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                    fontFamily: 'Vazir', fontSize: 16, color: Colors.redAccent),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
              _fetchData();
            },
            child: const Text('تلاش مجدد',
                style: TextStyle(fontFamily: 'Vazir', fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: Container(
        key: ValueKey(_selectedIndex),
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height -
              kToolbarHeight -
              kBottomNavigationBarHeight -
              MediaQuery.of(context).padding.top,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _getTabContent(),
        ),
      ),
    );
  }

  Widget _getTabContent() {
    switch (_selectedIndex) {
      case 0:
        return const CategoryManagementScreen();
      case 1:
        return const ProductManagementScreen();
      case 2:
        return const InventoryManagementScreen();
      case 3:
        return const OrderManagementScreen();
      case 4:
        return const UserManagementScreen();
      case 5:
        return _buildStatsTab();
      default:
        return const Center(
          child: Text(
            'تب نامعتبر',
            style: TextStyle(fontFamily: 'Vazir', fontSize: 16),
            textDirection: TextDirection.rtl,
          ),
        );
    }
  }

  Widget _buildStatsTab() {
    final productProvider = Provider.of<ProductProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'آمار کلی',
          style: TextStyle(
              fontFamily: 'Vazir',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.blue.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow(FontAwesomeIcons.boxes, 'محصولات',
                    productProvider.products.length.toString()),
                _buildStatRow(FontAwesomeIcons.boxOpen, 'سفارشات',
                    orderProvider.orders.length.toString()),
                _buildStatRow(
                    FontAwesomeIcons.warehouse,
                    'موجودی',
                    inventoryProvider.inventory
                        .fold(0, (sum, item) => sum + item.quantity)
                        .toString()),
                _buildStatRow(FontAwesomeIcons.thList, 'دسته‌بندی‌ها',
                    categoryProvider.categories.length.toString()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          FaIcon(icon, color: AppColors.accent, size: 24),
          const SizedBox(width: 12),
          Text(
            '$label: $value',
            style: const TextStyle(
                fontFamily: 'Vazir', fontSize: 16, fontWeight: FontWeight.w600),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}
