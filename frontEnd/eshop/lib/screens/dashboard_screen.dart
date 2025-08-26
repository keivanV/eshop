import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../routes/app_routes.dart';
import '../screens/home_tab.dart';
import '../screens/orders_tab.dart';
import '../screens/cart_screen.dart';
import '../screens/products_tab.dart';
import '../screens/admin_dashboard_screen.dart';
import '../services/api_service.dart';
import '../constants.dart';
import '../models/order.dart';

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
  bool _isSidebarExpanded = true;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController =
      TextEditingController(); // اضافه کردن کنترلر برای رمز عبور
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
    _passwordController.dispose();
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
        throw Exception('Token or UserId is null');
      }
      futures.add(orderProvider.fetchOrders(authProvider.token!,
          authProvider.role ?? 'user', authProvider.userId ?? ''));
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
          _usernameController.text = authProvider.username ?? '';
          _emailController.text = authProvider.email ?? '';
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
      return 'کاربر یافت نشد';
    } else if (error.contains('400')) {
      if (error.contains('Email already taken')) {
        return 'ایمیل قبلاً استفاده شده است';
      }
      return 'خطا در درخواست: اطلاعات نامعتبر است';
    } else {
      return error.replaceFirst('Exception: ', '');
    }
  }

  Future<void> _fetchUserData(AuthProvider authProvider) async {
    final userData = await ApiService.getUserById(
        authProvider.userId!, authProvider.token!); // استفاده از userId
    if (mounted) {
      setState(() {
        _usernameController.text =
            userData['username'] ?? authProvider.username ?? '';
        _emailController.text = userData['email'] ?? authProvider.email ?? '';
        _userDataError = false;
      });
    }
  }

  Future<void> _updateUserProfile(AuthProvider authProvider,
      {String? password}) async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await authProvider.updateUserProfile(
        _emailController.text,
        password: _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'اطلاعات با موفقیت به‌روزرسانی شد',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                  fontFamily: 'Vazir', fontSize: 16, color: Colors.white),
            ),
            backgroundColor: const Color(0xff11998e),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(12),
            elevation: 8,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در به‌روزرسانی اطلاعات: ${_formatErrorMessage(e.toString())}',
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                  fontFamily: 'Vazir', fontSize: 16, color: Colors.white),
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(12),
            elevation: 8,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      debugPrint('Error updating profile: $e');
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
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 50, 4, 105),
                Color.fromARGB(255, 39, 5, 81)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: ZoomIn(
              duration: const Duration(milliseconds: 600),
              child: _buildCustomLoader(),
            ),
          ),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 129, 129, 129), // خاکستری
                Color.fromARGB(255, 255, 255, 255), // سفید
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: FadeInUp(
              duration: const Duration(milliseconds: 600),
              child: _buildErrorCard(),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'پنل کاربر',
          style: TextStyle(
            fontFamily: 'Vazir',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 13, 35, 76),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1B263B),
              Color(0xFF1B263B),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(
                    top: 16, bottom: 16, right: 8, left: 16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _isSidebarExpanded ? 250 : 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Color(0xFF4682B4).withOpacity(0.5),
                      width: 1.2,
                    ),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color.fromARGB(210, 13, 52, 130),
                            Color.fromARGB(255, 58, 72, 99)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: _buildSidebar(authProvider),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(
                      top: 16, bottom: 16, right: 16, left: 8),
                  child: _buildTabContent(context, role),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(AuthProvider authProvider) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final orderStats = {
      'pending': orderProvider.orders
          .where((o) => o.status == OrderStatus.pending)
          .length,
      'processed': orderProvider.orders
          .where((o) => o.status == OrderStatus.processed)
          .length,
      'shipped': orderProvider.orders
          .where((o) => o.status == OrderStatus.shipped)
          .length,
      'delivered': orderProvider.orders
          .where((o) => o.status == OrderStatus.delivered)
          .length,
      'returned': orderProvider.orders
          .where((o) => o.status == OrderStatus.returned)
          .length,
      'cancelled': orderProvider.orders
          .where((o) => o.status == OrderStatus.cancelled)
          .length,
    };
    final sections = [
      PieChartSectionData(
        color: Colors.blue.shade600,
        value: orderStats['pending']!.toDouble(),
        title: '',
        radius: 60,
        badgeWidget: orderStats['pending']! > 0
            ? ZoomIn(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    '${orderStats['pending']}',
                    style: const TextStyle(
                      fontFamily: 'Vazir',
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.3,
      ),
      PieChartSectionData(
        color: Colors.green.shade600,
        value: orderStats['processed']!.toDouble(),
        title: '',
        radius: 60,
        badgeWidget: orderStats['processed']! > 0
            ? ZoomIn(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    '${orderStats['processed']}',
                    style: const TextStyle(
                      fontFamily: 'Vazir',
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.3,
      ),
      PieChartSectionData(
        color: Colors.orange.shade600,
        value: orderStats['shipped']!.toDouble(),
        title: '',
        radius: 60,
        badgeWidget: orderStats['shipped']! > 0
            ? ZoomIn(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    '${orderStats['shipped']}',
                    style: const TextStyle(
                      fontFamily: 'Vazir',
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.3,
      ),
      PieChartSectionData(
        color: Colors.teal.shade600,
        value: orderStats['delivered']!.toDouble(),
        title: '',
        radius: 60,
        badgeWidget: orderStats['delivered']! > 0
            ? ZoomIn(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade600.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    '${orderStats['delivered']}',
                    style: const TextStyle(
                      fontFamily: 'Vazir',
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.3,
      ),
      PieChartSectionData(
        color: Colors.red.shade600,
        value: orderStats['returned']!.toDouble(),
        title: '',
        radius: 60,
        badgeWidget: orderStats['returned']! > 0
            ? ZoomIn(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    '${orderStats['returned']}',
                    style: const TextStyle(
                      fontFamily: 'Vazir',
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.3,
      ),
      PieChartSectionData(
        color: Colors.grey.shade600,
        value: orderStats['cancelled']!.toDouble(),
        title: '',
        radius: 60,
        badgeWidget: orderStats['cancelled']! > 0
            ? ZoomIn(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    '${orderStats['cancelled']}',
                    style: const TextStyle(
                      fontFamily: 'Vazir',
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.3,
      ),
    ].where((section) => section.value > 0).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            mainAxisAlignment: _isSidebarExpanded
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.center,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    padding: const EdgeInsets.all(2),
                    icon: FaIcon(
                      _isSidebarExpanded
                          ? FontAwesomeIcons.angleRight
                          : FontAwesomeIcons.angleLeft,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isSidebarExpanded = !_isSidebarExpanded;
                        _animationController.reset();
                        _animationController.forward();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              _buildSidebarItem(
                  FontAwesomeIcons.userEdit, 'ویرایش اطلاعات', 'edit_profile'),
              if (authProvider.role == 'user')
                _buildSidebarItem(FontAwesomeIcons.listCheck, 'روند سفارشات',
                    'order_progress'),
              _buildSidebarItem(FontAwesomeIcons.store, 'محصولات', 'products'),
              _buildSidebarItem(FontAwesomeIcons.boxOpen, 'سفارشات', 'orders'),
              _buildSidebarItem(
                  FontAwesomeIcons.cartShopping, 'سبد خرید', 'cart'),
            ],
          ),
        ),
        if (_isSidebarExpanded)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: sections.isEmpty
                      ? const Center(
                          child: Text(
                            'هیچ داده‌ای برای نمایش وجود ندارد',
                            style: TextStyle(
                              fontFamily: 'Vazir',
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        )
                      : PieChart(
                          PieChartData(
                            sections: sections,
                            centerSpaceRadius: 20,
                            sectionsSpace: 2,
                            pieTouchData: PieTouchData(
                              enabled: true,
                              touchCallback:
                                  (FlTouchEvent event, pieTouchResponse) {
                                if (event is FlTapUpEvent &&
                                    pieTouchResponse != null) {
                                  // Optional: Add interaction feedback
                                }
                              },
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildLegendItem('در انتظار', Colors.blue.shade600),
                    _buildLegendItem('پردازش‌شده', Colors.green.shade600),
                    _buildLegendItem('خروج از انبار', Colors.orange.shade600),
                    _buildLegendItem('تحویل‌شده', Colors.teal.shade600),
                    _buildLegendItem('مرجوع‌شده', Colors.red.shade600),
                    _buildLegendItem('لغوشده', Colors.grey.shade600),
                  ],
                ),
              ],
            ),
          ),
        _buildSidebarItem(
          FontAwesomeIcons.rightFromBracket,
          'خروج',
          'logout',
          onTap: () async {
            await authProvider.logout();
            Navigator.pushNamedAndRemoveUntil(
                context, AppRoutes.login, (route) => false);
          },
        ),
      ],
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, String tab,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ??
          () {
            setState(() {
              _selectedTab = tab;
              _animationController.reset();
              _animationController.forward();
            });
          },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _selectedTab == tab
              ? Colors.white.withOpacity(0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: _selectedTab == tab
              ? Border.all(color: Colors.white.withOpacity(0.5), width: 1.5)
              : null,
          boxShadow: _selectedTab == tab
              ? [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: ClipRect(
          child: Row(
            mainAxisAlignment: _isSidebarExpanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              FaIcon(
                icon,
                size: _selectedTab == tab ? 26 : 22,
                color: Colors.white,
              ),
              if (_isSidebarExpanded) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Vazir',
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: _selectedTab == tab
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 2,
                spreadRadius: 0.5,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Vazir',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }

  Widget _buildCustomLoader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xff38ef7d)),
                  strokeWidth: 6,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'در حال بارگذاری...',
                style: TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ZoomIn(
                duration: const Duration(milliseconds: 600),
                child: const FaIcon(
                  FontAwesomeIcons.exclamationTriangle,
                  color: Colors.redAccent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'خطا در بارگذاری اطلاعات: $_errorMessage',
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'Vazir',
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Bounce(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xff11998e),
                        Color(0xff38ef7d),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text(
                      'تلاش مجدد',
                      style: TextStyle(
                        fontFamily: 'Vazir',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, String role) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.2,
            ),
          ),
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
      ),
    );
  }

  Widget _getTabWidget(String role) {
    switch (_selectedTab) {
      case 'edit_profile':
      case 'order_progress':
      case 'order_report':
        return HomeTab(
          key: const ValueKey('home'),
          role: role,
          selectedHomeTab: _selectedTab,
          userDataError: _userDataError,
          userDataErrorMessage: _userDataErrorMessage,
          formKey: _formKey,
          usernameController: _usernameController,
          emailController: _emailController,
          passwordController: _passwordController, // اضافه کردن کنترلر رمز عبور
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
              _selectedTab = tab;
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
              fontSize: 18,
              fontFamily: 'Vazir',
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textDirection: TextDirection.rtl,
          ),
        );
    }
  }
}
