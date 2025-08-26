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
  static const String _baseUrl = 'http://localhost:5000';
  bool _isSidebarOpen = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    try {
      final List<Future<dynamic>> futures = [];
      if (authProvider.token == null || authProvider.userId == null) {
        throw Exception('Token or User ID is null');
      }
      futures.add(orderProvider.fetchOrders(authProvider.token!,
          authProvider.role ?? 'user', authProvider.userId!));
      if (authProvider.role == 'admin') {
        final productProvider =
            Provider.of<ProductProvider>(context, listen: false);
        final categoryProvider =
            Provider.of<CategoryProvider>(context, listen: false);
        futures.add(productProvider.fetchProducts());
        futures.add(categoryProvider.fetchCategories());
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
      return 'عدم دسترسی: لطفاً با حساب مناسب وارد شوید';
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
            backgroundColor: Colors.green,
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
    final role = authProvider.role ?? 'user';

    List<Map<String, dynamic>> navItems;
    String appBarTitle;
    if (role == 'warehouse_manager') {
      navItems = [
        {'icon': FontAwesomeIcons.boxOpen, 'label': 'مدیریت پردازش'},
      ];
      appBarTitle = 'پنل مدیریت پردازش، ${authProvider.userId ?? 'کاربر'}';
      _selectedIndex = 0;
    } else if (role == 'delivery_agent') {
      navItems = [
        {'icon': FontAwesomeIcons.boxOpen, 'label': 'مدیریت تحویل'},
      ];
      appBarTitle = 'پنل مدیریت تحویل';
      _selectedIndex = 0;
    } else {
      navItems = [
        {'icon': FontAwesomeIcons.thList, 'label': 'دسته‌بندی‌ها'},
        {'icon': FontAwesomeIcons.box, 'label': 'محصولات'},
        {'icon': FontAwesomeIcons.boxOpen, 'label': 'سفارشات'},
        {'icon': FontAwesomeIcons.users, 'label': 'کاربران'},
        {'icon': FontAwesomeIcons.chartPie, 'label': 'آمار'},
      ];
      appBarTitle = 'پنل مدیریت، ${authProvider.userId ?? 'کاربر'}';
    }

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isSidebarOpen ? 250 : 70,
            decoration: const BoxDecoration(
              color: Color(0xFF2A3F54), // AdminLTE dark sidebar
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Sidebar Header
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 8), // Reduced horizontal padding
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1F2A44), Color(0xFF2A3F54)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: TextDirection.rtl,
                    children: [
                      if (_isSidebarOpen)
                        Flexible(
                          child: Text(
                            'پنل مدیریت',
                            style: TextStyle(
                              fontFamily: 'Vazir',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textDirection: TextDirection.rtl,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      SizedBox(
                        width:
                            32, // Fixed width for icon to fit in collapsed mode
                        height: 32,
                        child: IconButton(
                          icon: Icon(
                            _isSidebarOpen
                                ? Icons.arrow_back_ios
                                : Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 16, // Smaller icon size
                          ),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints.tight(Size(32, 32)),
                          onPressed: () {
                            setState(() {
                              _isSidebarOpen = !_isSidebarOpen;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Sidebar Menu
                Expanded(
                  child: ListView.builder(
                    itemCount: navItems.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                            if (_selectedIndex != 1) {
                              _searchController.clear();
                              _selectedCategoryId = null;
                            }
                          });
                        },
                        child: Container(
                          height: 48,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: _selectedIndex == index
                              ? Colors.blue.withOpacity(0.1)
                              : null,
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              SizedBox(
                                width: 50,
                                child: Center(
                                  child: FaIcon(
                                    navItems[index]['icon'],
                                    color: _selectedIndex == index
                                        ? Colors.blue
                                        : Colors.white70,
                                    size: 24,
                                  ),
                                ),
                              ),
                              if (_isSidebarOpen)
                                Expanded(
                                  child: Text(
                                    navItems[index]['label'],
                                    style: TextStyle(
                                      fontFamily: 'Vazir',
                                      color: _selectedIndex == index
                                          ? Colors.blue
                                          : Colors.white70,
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Navbar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade700, Colors.green.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        appBarTitle,
                        style: const TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const FaIcon(
                              FontAwesomeIcons.signOutAlt,
                              color: Colors.white,
                            ),
                            onPressed: () async {
                              await authProvider.logout();
                              Navigator.pushNamedAndRemoveUntil(
                                  context, AppRoutes.login, (route) => false);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Content Area
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.green),
                          ),
                        )
                      : _hasError
                          ? _buildErrorWidget()
                          : _buildTabContent(role),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: (role == 'admin' && _selectedIndex == 1)
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.productEdit);
              },
              backgroundColor: Colors.green,
              child: const FaIcon(FontAwesomeIcons.plus, color: Colors.white),
            )
          : null,
      backgroundColor: Colors.grey.shade100,
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'خطا: $_errorMessage',
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 16,
                  color: Colors.redAccent,
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'تلاش مجدد',
                  style: TextStyle(
                      fontFamily: 'Vazir', fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(String role) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: Container(
        key: ValueKey(_selectedIndex),
        padding: const EdgeInsets.all(16),
        child: _getTabContent(role),
      ),
    );
  }

  Widget _getTabContent(String role) {
    final productProvider = Provider.of<ProductProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);

    if (role == 'warehouse_manager' || role == 'delivery_agent') {
      return const OrderManagementScreen();
    }

    switch (_selectedIndex) {
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

        return Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'جستجو بر اساس نام محصول',
                    labelStyle: const TextStyle(fontFamily: 'Vazir'),
                    prefixIcon: const Icon(Icons.search, color: Colors.green),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
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
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
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
                              color: Colors.grey,
                            ),
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
                                borderRadius: BorderRadius.circular(8),
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: product.imageUrls != null &&
                                        product.imageUrls!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          '$_baseUrl${product.imageUrls![0]}',
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            print('Image load error: $error');
                                            return const Icon(
                                                Icons.broken_image,
                                                size: 50);
                                          },
                                        ),
                                      )
                                    : const Icon(Icons.image, size: 50),
                                title: Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontFamily: 'Vazir',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                                subtitle: Text(
                                  'قیمت: ${product.price.toStringAsFixed(0)} تومان',
                                  style: const TextStyle(
                                    fontFamily: 'Vazir',
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const FaIcon(
                                        FontAwesomeIcons.edit,
                                        color: Colors.green,
                                      ),
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.productEdit,
                                          arguments: product.id,
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const FaIcon(
                                        FontAwesomeIcons.trash,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text(
                                              'تأیید حذف',
                                              style: TextStyle(
                                                fontFamily: 'Vazir',
                                                fontWeight: FontWeight.bold,
                                              ),
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
                                                    color: Colors.redAccent,
                                                  ),
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
            ),
          ),
        );
      case 2:
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

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'آمار کلی',
              style: TextStyle(
                fontFamily: 'Vazir',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard(FontAwesomeIcons.boxes, 'محصولات',
                    productProvider.products.length.toString()),
                _buildStatCard(FontAwesomeIcons.boxOpen, 'سفارشات',
                    orderProvider.orders.length.toString()),
                _buildStatCard(FontAwesomeIcons.thList, 'دسته‌بندی‌ها',
                    categoryProvider.categories.length.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              FaIcon(icon, color: Colors.green, size: 30),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
