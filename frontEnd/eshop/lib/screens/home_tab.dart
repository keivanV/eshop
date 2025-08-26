import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../constants.dart';

class HomeTab extends StatefulWidget {
  final String role;
  final String selectedHomeTab;
  final bool userDataError;
  final String userDataErrorMessage;
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController; // اضافه شده
  final Future<void> Function(AuthProvider, {String? password}) onUpdateProfile;
  final Future<void> Function(AuthProvider) onFetchUserData;
  final Future<void> Function() onRefreshData;
  final void Function(String) onTabChanged;

  const HomeTab({
    super.key,
    required this.role,
    required this.selectedHomeTab,
    required this.userDataError,
    required this.userDataErrorMessage,
    required this.formKey,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.onUpdateProfile,
    required this.onFetchUserData,
    required this.onRefreshData,
    required this.onTabChanged,
  });

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current user data
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    widget.usernameController.text = authProvider.username ?? '';
    widget.emailController.text = authProvider.email ?? '';
  }

  @override
  void dispose() {
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'لطفاً ایمیل را وارد کنید';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'ایمیل نامعتبر است';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value != null && value.trim().isNotEmpty && value.trim().length < 6) {
      return 'رمز عبور باید حداقل ۶ کاراکتر باشد';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: _buildHomeTabContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTabContent(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);

    switch (widget.selectedHomeTab) {
      case 'edit_profile':
        return FadeInUp(
          duration: const Duration(milliseconds: 800),
          child: Column(
            children: [
              if (widget.userDataError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ZoomIn(
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.2),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        'خطا در بارگذاری اطلاعات کاربر: ${widget.userDataErrorMessage}',
                        style: const TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 16,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              Form(
                key: widget.formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: widget.usernameController,
                      enabled: false, // Disable username field
                      decoration: InputDecoration(
                        labelText: 'نام کاربری',
                        labelStyle: const TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 15,
                          color: AppColors.primary,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                              color: AppColors.primary.withOpacity(0.2)),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                              color: AppColors.primary.withOpacity(0.2)),
                        ),
                        prefixIcon: const FaIcon(FontAwesomeIcons.user,
                            color: AppColors.primary),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontFamily: 'Vazir', fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: widget.emailController,
                      decoration: InputDecoration(
                        labelText: 'ایمیل',
                        labelStyle: const TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 15,
                          color: AppColors.primary,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                              color: AppColors.primary.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: Color.fromARGB(255, 18, 51, 219),
                              width: 2),
                        ),
                        prefixIcon: const FaIcon(FontAwesomeIcons.envelope,
                            color: AppColors.primary),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontFamily: 'Vazir', fontSize: 16),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: widget.passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'رمز عبور جدید (اختیاری)',
                        labelStyle: const TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 15,
                          color: AppColors.primary,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                              color: AppColors.primary.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                              color: Color.fromARGB(255, 18, 51, 219),
                              width: 2),
                        ),
                        prefixIcon: const FaIcon(FontAwesomeIcons.lock,
                            color: AppColors.primary),
                        suffixIcon: IconButton(
                          icon: FaIcon(
                            _isPasswordVisible
                                ? FontAwesomeIcons.eye
                                : FontAwesomeIcons.eyeSlash,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontFamily: 'Vazir', fontSize: 16),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 24),
                    Bounce(
                      duration: const Duration(milliseconds: 800),
                      child: ElevatedButton(
                        onPressed: () async {
                          if (widget.formKey.currentState!.validate()) {
                            await widget.onUpdateProfile(
                              authProvider,
                              password:
                                  widget.passwordController.text.isNotEmpty
                                      ? widget.passwordController.text
                                      : null,
                            );
                            widget.passwordController.clear();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 6, 35, 181),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          elevation: 6,
                          shadowColor: AppColors.accent.withOpacity(0.4),
                        ),
                        child: const Text(
                          'ذخیره تغییرات',
                          style: TextStyle(
                            fontFamily: 'Vazir',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (widget.userDataError)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Bounce(
                          duration: const Duration(milliseconds: 800),
                          child: ElevatedButton(
                            onPressed: () async {
                              await widget.onFetchUserData(authProvider);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                              elevation: 6,
                              shadowColor: Colors.blueGrey.withOpacity(0.4),
                            ),
                            child: const Text(
                              'تلاش مجدد برای بارگذاری اطلاعات',
                              style: TextStyle(
                                fontFamily: 'Vazir',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      case 'order_progress':
        final currentOrders = orderProvider.orders
            .where((order) => ![
                  OrderStatus.delivered,
                  OrderStatus.returned,
                  OrderStatus.cancelled
                ].contains(order.status))
            .toList();
        debugPrint('Current orders count: ${currentOrders.length}');
        debugPrint(
            'Current orders statuses: ${currentOrders.map((o) => o.status.toString()).toList()}');
        if (currentOrders.isEmpty) {
          return Center(
            child: FadeInUp(
              duration: const Duration(milliseconds: 800),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ZoomIn(
                    duration: const Duration(milliseconds: 600),
                    child: const FaIcon(
                      FontAwesomeIcons.boxOpen,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'هیچ سفارش جاری یافت نشد',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'Vazir',
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Bounce(
                    duration: const Duration(milliseconds: 800),
                    child: ElevatedButton(
                      onPressed: widget.onRefreshData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        elevation: 6,
                        shadowColor: AppColors.accent.withOpacity(0.4),
                      ),
                      child: const Text(
                        'تلاش مجدد',
                        style: TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: currentOrders.length,
          itemBuilder: (ctx, i) {
            debugPrint('Building timeline for order: ${currentOrders[i].id}');
            return FadeInUp(
              duration: const Duration(milliseconds: 600),
              delay: Duration(milliseconds: 200 * i),
              child: _buildOrderTimeline(currentOrders[i]),
            );
          },
        );
      case 'order_report':
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
        debugPrint('Order stats: $orderStats');
        final sections = [
          PieChartSectionData(
            color: Colors.blue.shade600,
            value: orderStats['pending']!.toDouble(),
            title: '',
            radius: 120,
            badgeWidget: orderStats['pending']! > 0
                ? ZoomIn(
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        '${orderStats['pending']}',
                        style: const TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 14,
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
            radius: 120,
            badgeWidget: orderStats['processed']! > 0
                ? ZoomIn(
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        '${orderStats['processed']}',
                        style: const TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 14,
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
            radius: 120,
            badgeWidget: orderStats['shipped']! > 0
                ? ZoomIn(
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade600.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        '${orderStats['shipped']}',
                        style: const TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 14,
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
            radius: 120,
            badgeWidget: orderStats['delivered']! > 0
                ? ZoomIn(
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade600.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        '${orderStats['delivered']}',
                        style: const TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 14,
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
            radius: 120,
            badgeWidget: orderStats['returned']! > 0
                ? ZoomIn(
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        '${orderStats['returned']}',
                        style: const TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 14,
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
            radius: 120,
            badgeWidget: orderStats['cancelled']! > 0
                ? ZoomIn(
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade600.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        '${orderStats['cancelled']}',
                        style: const TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 14,
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
        if (sections.isEmpty) {
          return Center(
            child: FadeInUp(
              duration: const Duration(milliseconds: 800),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ZoomIn(
                    duration: const Duration(milliseconds: 600),
                    child: const FaIcon(
                      FontAwesomeIcons.chartPie,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'هیچ داده‌ای برای نمایش گزارش سفارشات یافت نشد',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'Vazir',
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Bounce(
                    duration: const Duration(milliseconds: 800),
                    child: ElevatedButton(
                      onPressed: widget.onRefreshData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        elevation: 6,
                        shadowColor: AppColors.accent.withOpacity(0.4),
                      ),
                      child: const Text(
                        'تلاش مجدد',
                        style: TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return FadeInUp(
          duration: const Duration(milliseconds: 800),
          child: Column(
            children: [
              Container(
                height: 320,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 50,
                    sectionsSpace: 4,
                    pieTouchData: PieTouchData(
                      enabled: true,
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        if (event is FlTapUpEvent && pieTouchResponse != null) {
                          // Optional: Add interaction feedback
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        AppColors.primary.withOpacity(0.1)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeIn(
                        duration: const Duration(milliseconds: 600),
                        child: const Text(
                          'خلاصه آمار سفارشات',
                          style: TextStyle(
                            fontFamily: 'Vazir',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...[
                        {
                          'label': 'در انتظار',
                          'count': orderStats['pending']!,
                          'color': Colors.blue.shade600
                        },
                        {
                          'label': 'پردازش‌شده',
                          'count': orderStats['processed']!,
                          'color': Colors.green.shade600
                        },
                        {
                          'label': 'خروج از انبار',
                          'count': orderStats['shipped']!,
                          'color': Colors.orange.shade600
                        },
                        {
                          'label': 'تحویل‌شده',
                          'count': orderStats['delivered']!,
                          'color': Colors.teal.shade600
                        },
                        {
                          'label': 'مرجوع‌شده',
                          'count': orderStats['returned']!,
                          'color': Colors.red.shade600
                        },
                        {
                          'label': 'لغوشده',
                          'count': orderStats['cancelled']!,
                          'color': Colors.grey.shade600
                        },
                      ].map((stat) => FadeIn(
                            duration: const Duration(milliseconds: 600),
                            delay: Duration(
                                milliseconds: 100 * (stat['count'] as int)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: stat['color'] as Color,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (stat['color'] as Color)
                                              .withOpacity(0.3),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '${stat['label']}: ${stat['count']} سفارش',
                                      style: const TextStyle(
                                        fontFamily: 'Vazir',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                      textDirection: TextDirection.rtl,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 12,
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
        );
      default:
        return Center(
          child: FadeIn(
            duration: const Duration(milliseconds: 600),
            child: const Text(
              'تب نامعتبر',
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
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Vazir',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }

  Widget _buildOrderTimeline(Order order) {
    final statusMap = {
      OrderStatus.pending: {
        'label': 'در صف پردازش',
        'icon': FontAwesomeIcons.hourglassStart,
        'color': Colors.blue.shade600
      },
      OrderStatus.processed: {
        'label': 'پردازش‌شده',
        'icon': FontAwesomeIcons.cogs,
        'color': Colors.green.shade600
      },
      OrderStatus.shipped: {
        'label': 'خروج از انبار',
        'icon': FontAwesomeIcons.truck,
        'color': Colors.orange.shade600
      },
      OrderStatus.delivered: {
        'label': 'تحویل‌شده',
        'icon': FontAwesomeIcons.checkCircle,
        'color': Colors.teal.shade600
      },
      OrderStatus.returned: {
        'label': 'مرجوع‌شده',
        'icon': FontAwesomeIcons.undo,
        'color': Colors.red.shade600
      },
      OrderStatus.cancelled: {
        'label': 'لغوشده',
        'icon': FontAwesomeIcons.ban,
        'color': Colors.grey.shade600
      },
    };

    final currentStatusIndex = OrderStatus.values.indexOf(order.status);
    final statusesToShow =
        OrderStatus.values.take(currentStatusIndex + 1).toList();

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.white, AppColors.primary.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 4,
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeIn(
              duration: const Duration(milliseconds: 600),
              child: Text(
                'سفارش #${order.id}',
                style: const TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
            const SizedBox(height: 16),
            ...statusesToShow.asMap().entries.map((entry) {
              final index = entry.key;
              final status = entry.value;
              final isLast = index == statusesToShow.length - 1;
              return FadeInUp(
                duration: const Duration(milliseconds: 600),
                delay: Duration(milliseconds: 200 * index),
                child: Row(
                  children: [
                    Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusMap[status]!['color'] as Color,
                            boxShadow: [
                              BoxShadow(
                                color: (statusMap[status]!['color'] as Color)
                                    .withOpacity(0.4),
                                spreadRadius: 3,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: FaIcon(
                            statusMap[status]!['icon'] as IconData,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 4,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusMap[status]!['label'] as String,
                            style: const TextStyle(
                              fontFamily: 'Vazir',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          Text(
                            'تاریخ: ${order.createdAt.toString().substring(0, 10)}',
                            style: TextStyle(
                              fontFamily: 'Vazir',
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
