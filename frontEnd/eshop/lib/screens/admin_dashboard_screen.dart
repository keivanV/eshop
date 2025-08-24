// lib/screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../routes/app_routes.dart';
import '../constants.dart';
import '../screens/category_management_screen.dart';
import '../screens/order_management_screen.dart';
import '../screens/user_management_screen.dart';
import '../screens/product_edit_screen.dart';

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
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategoryId;
  static const String _baseUrl =
      'http://localhost:5000'; // Adjust for production

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
    _searchController.addListener(() {
      setState(() {}); // Update UI on search input change
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);

    try {
      final futures = [
        productProvider.fetchProducts(),
        categoryProvider.fetchCategories(),
      ];
      // Only fetch orders if the user is an admin
      if (authProvider.role == 'admin') {
        futures.add(orderProvider.fetchOrders(
            authProvider.token!, 'admin', authProvider.userId!));
      }
      await Future.wait(futures);
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

  Future<void> _deleteProduct(String productId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);

    try {
      await productProvider.deleteProduct(productId, authProvider.token!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'محصول با موفقیت حذف شد',
              style: TextStyle(fontFamily: 'Vazir'),
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: AppColors.accent,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در حذف محصول: ${e.toString().replaceFirst('Exception: ', '')}',
              style: const TextStyle(fontFamily: 'Vazir'),
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.role == 'admin';

    // Define navigation items, excluding Orders for non-admins
    final navItems = [
      _buildNavItem(FontAwesomeIcons.thList, 'دسته‌بندی‌ها'),
      _buildNavItem(FontAwesomeIcons.box, 'محصولات'),
      if (isAdmin) _buildNavItem(FontAwesomeIcons.boxOpen, 'سفارشات'),
      _buildNavItem(FontAwesomeIcons.users, 'کاربران'),
      _buildNavItem(FontAwesomeIcons.chartPie, 'آمار'),
    ];

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
            setState(() {
              _selectedIndex = index;
              // Clear filters when switching tabs
              if (_selectedIndex != (isAdmin ? 1 : 1)) {
                _searchController.clear();
                _selectedCategoryId = null;
              }
            });
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
          items: navItems,
        ),
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.productEdit);
              },
              backgroundColor: AppColors.accent,
              child: const FaIcon(FontAwesomeIcons.plus, color: Colors.white),
            )
          : null,
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = authProvider.role == 'admin';
    final labels = [
      'دسته‌بندی‌ها',
      'محصولات',
      if (isAdmin) 'سفارشات',
      'کاربران',
      'آمار',
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
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.role == 'admin';
    final productProvider = Provider.of<ProductProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);

    // Adjust index mapping for non-admins
    int adjustedIndex = _selectedIndex;
    if (!isAdmin && _selectedIndex >= 2) {
      adjustedIndex += 1; // Skip Orders tab for non-admins
    }

    switch (adjustedIndex) {
      case 0:
        return const CategoryManagementScreen();
      case 1:
        final filteredProducts = productProvider.products.where((product) {
          final matchesSearch = _searchController.text.isEmpty ||
              product.name
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase());
          final matchesCategory = _selectedCategoryId == null ||
              product.categoryId == _selectedCategoryId;
          return matchesSearch && matchesCategory;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'جستجو بر اساس نام محصول',
                labelStyle: const TextStyle(fontFamily: 'Vazir'),
                prefixIcon: const Icon(Icons.search, color: AppColors.accent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: InputDecoration(
                labelText: 'فیلتر بر اساس دسته‌بندی',
                labelStyle: const TextStyle(fontFamily: 'Vazir'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text(
                    'همه دسته‌بندی‌ها',
                    style: TextStyle(fontFamily: 'Vazir'),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                ...categoryProvider.categories
                    .map((category) => DropdownMenuItem(
                          value: category.id,
                          child: Text(
                            category.name,
                            style: const TextStyle(fontFamily: 'Vazir'),
                            textDirection: TextDirection.rtl,
                          ),
                        )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredProducts.isEmpty
                  ? const Center(
                      child: Text(
                        'محصولی یافت نشد',
                        style: TextStyle(
                            fontFamily: 'Vazir',
                            fontSize: 16,
                            color: Colors.grey),
                        textDirection: TextDirection.rtl,
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: product.imageUrls != null &&
                                    product.imageUrls!.isNotEmpty
                                ? Image.network(
                                    '$_baseUrl${product.imageUrls![0]}',
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      print(
                                          'Image load error for $_baseUrl${product.imageUrls![0]}: $error');
                                      return const Icon(Icons.broken_image,
                                          size: 50);
                                    },
                                  )
                                : const Icon(Icons.image, size: 50),
                            title: Text(
                              product.name,
                              style: const TextStyle(
                                  fontFamily: 'Vazir',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                              textDirection: TextDirection.rtl,
                            ),
                            subtitle: Text(
                              'قیمت: ${product.price.toStringAsFixed(0)} تومان',
                              style: const TextStyle(
                                  fontFamily: 'Vazir',
                                  fontSize: 14,
                                  color: Colors.grey),
                              textDirection: TextDirection.rtl,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const FaIcon(FontAwesomeIcons.edit,
                                      color: AppColors.accent),
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.productEdit,
                                      arguments: product.id,
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const FaIcon(FontAwesomeIcons.trash,
                                      color: Colors.redAccent),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text(
                                          'تأیید حذف',
                                          style: TextStyle(
                                              fontFamily: 'Vazir',
                                              fontWeight: FontWeight.bold),
                                          textDirection: TextDirection.rtl,
                                        ),
                                        content: Text(
                                          'آیا مطمئن هستید که می‌خواهید "${product.name}" را حذف کنید؟',
                                          style: const TextStyle(
                                              fontFamily: 'Vazir'),
                                          textDirection: TextDirection.rtl,
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text(
                                              'لغو',
                                              style: TextStyle(
                                                  fontFamily: 'Vazir'),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _deleteProduct(product.id);
                                            },
                                            child: const Text(
                                              'حذف',
                                              style: TextStyle(
                                                  fontFamily: 'Vazir',
                                                  color: Colors.redAccent),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      case 2:
        if (!isAdmin) {
          return const Center(
            child: Text(
              'عدم دسترسی: این بخش فقط برای مدیران قابل مشاهده است',
              style: TextStyle(fontFamily: 'Vazir', fontSize: 16),
              textDirection: TextDirection.rtl,
            ),
          );
        }
        return const OrderManagementScreen();
      case 3:
        return const UserManagementScreen();
      case 4:
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
