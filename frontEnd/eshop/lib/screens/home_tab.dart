import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../constants.dart';

class HomeTab extends StatelessWidget {
  final String role;
  final String selectedHomeTab;
  final bool userDataError;
  final String userDataErrorMessage;
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final Future<void> Function(AuthProvider) onUpdateProfile;
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
    required this.onUpdateProfile,
    required this.onFetchUserData,
    required this.onRefreshData,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'مدیریت حساب',
            style: TextStyle(
              fontFamily: 'Vazir',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 20),
          _buildHomeMenuSection(context),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: _buildHomeTabContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeMenuSection(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildMenuCard(
            context: context,
            icon: FontAwesomeIcons.userEdit,
            label: 'ویرایش اطلاعات',
            tab: 'edit_profile',
            isSelected: selectedHomeTab == 'edit_profile',
          ),
          _buildMenuCard(
            context: context,
            icon: FontAwesomeIcons.listCheck,
            label: 'روند سفارشات',
            tab: 'order_progress',
            isSelected: selectedHomeTab == 'order_progress',
          ),
          _buildMenuCard(
            context: context,
            icon: FontAwesomeIcons.chartPie,
            label: 'گزارش سفارشات',
            tab: 'order_report',
            isSelected: selectedHomeTab == 'order_report',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTabContent(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);

    switch (selectedHomeTab) {
      case 'edit_profile':
        return Column(
          children: [
            if (userDataError)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'خطا در بارگذاری اطلاعات کاربر: $userDataErrorMessage',
                  style: TextStyle(
                    fontFamily: 'Vazir',
                    fontSize: 14,
                    color: Colors.red.shade700,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: 'نام کاربری',
                      labelStyle: const TextStyle(fontFamily: 'Vazir'),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const FaIcon(FontAwesomeIcons.user),
                    ),
                    textDirection: TextDirection.rtl,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'لطفاً نام کاربری را وارد کنید';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'ایمیل',
                      labelStyle: const TextStyle(fontFamily: 'Vazir'),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const FaIcon(FontAwesomeIcons.envelope),
                    ),
                    textDirection: TextDirection.rtl,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'لطفاً ایمیل را وارد کنید';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'ایمیل نامعتبر است';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => onUpdateProfile(authProvider),
                    child: const Text('ذخیره تغییرات',
                        style: TextStyle(fontFamily: 'Vazir')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                  if (userDataError)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ElevatedButton(
                        onPressed: () async {
                          await onFetchUserData(authProvider);
                        },
                        child: const Text('تلاش مجدد برای بارگذاری اطلاعات',
                            style: TextStyle(fontFamily: 'Vazir')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'هیچ سفارش جاری یافت نشد',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontSize: 16, fontFamily: 'Vazir'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRefreshData,
                  child: const Text('تلاش مجدد',
                      style: TextStyle(fontFamily: 'Vazir')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: currentOrders.length,
          itemBuilder: (ctx, i) {
            debugPrint('Building timeline for order: ${currentOrders[i].id}');
            return _buildOrderTimeline(currentOrders[i]);
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
            color: Colors.blue,
            value: orderStats['pending']!.toDouble(),
            title: '',
            radius: 100,
            badgeWidget: orderStats['pending']! > 0
                ? AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${orderStats['pending']}',
                        style: const TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : null,
            badgePositionPercentageOffset: 1.2,
          ),
          PieChartSectionData(
            color: Colors.green,
            value: orderStats['processed']!.toDouble(),
            title: '',
            radius: 100,
            badgeWidget: orderStats['processed']! > 0
                ? AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${orderStats['processed']}',
                        style: const TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : null,
            badgePositionPercentageOffset: 1.2,
          ),
          PieChartSectionData(
            color: Colors.orange,
            value: orderStats['shipped']!.toDouble(),
            title: '',
            radius: 100,
            badgeWidget: orderStats['shipped']! > 0
                ? AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${orderStats['shipped']}',
                        style: const TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : null,
            badgePositionPercentageOffset: 1.2,
          ),
          PieChartSectionData(
            color: Colors.teal,
            value: orderStats['delivered']!.toDouble(),
            title: '',
            radius: 100,
            badgeWidget: orderStats['delivered']! > 0
                ? AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${orderStats['delivered']}',
                        style: const TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : null,
            badgePositionPercentageOffset: 1.2,
          ),
          PieChartSectionData(
            color: Colors.red,
            value: orderStats['returned']!.toDouble(),
            title: '',
            radius: 100,
            badgeWidget: orderStats['returned']! > 0
                ? AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${orderStats['returned']}',
                        style: const TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : null,
            badgePositionPercentageOffset: 1.2,
          ),
          PieChartSectionData(
            color: Colors.grey,
            value: orderStats['cancelled']!.toDouble(),
            title: '',
            radius: 100,
            badgeWidget: orderStats['cancelled']! > 0
                ? AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${orderStats['cancelled']}',
                        style: const TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : null,
            badgePositionPercentageOffset: 1.2,
          ),
        ].where((section) => section.value > 0).toList();
        if (sections.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'هیچ داده‌ای برای نمایش گزارش سفارشات یافت نشد',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontSize: 16, fontFamily: 'Vazir'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRefreshData,
                  child: const Text('تلاش مجدد',
                      style: TextStyle(fontFamily: 'Vazir')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                  pieTouchData: PieTouchData(enabled: false),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'خلاصه آمار سفارشات',
                      style: TextStyle(
                        fontFamily: 'Vazir',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 8),
                    ...[
                      {
                        'label': 'در انتظار',
                        'count': orderStats['pending']!,
                        'color': Colors.blue
                      },
                      {
                        'label': 'پردازش‌شده',
                        'count': orderStats['processed']!,
                        'color': Colors.green
                      },
                      {
                        'label': 'خروج از انبار',
                        'count': orderStats['shipped']!,
                        'color': Colors.orange
                      },
                      {
                        'label': 'تحویل‌شده',
                        'count': orderStats['delivered']!,
                        'color': Colors.teal
                      },
                      {
                        'label': 'مرجوع‌شده',
                        'count': orderStats['returned']!,
                        'color': Colors.red
                      },
                      {
                        'label': 'لغوشده',
                        'count': orderStats['cancelled']!,
                        'color': Colors.grey
                      },
                    ].map((stat) => AnimatedOpacity(
                          opacity: (stat['count'] as int) > 0 ? 1.0 : 0.5,
                          duration: const Duration(milliseconds: 500),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: stat['color'] as Color,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${stat['label']}: ${stat['count']} سفارش',
                                    style: const TextStyle(
                                      fontFamily: 'Vazir',
                                      fontSize: 14,
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
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildLegendItem('در انتظار', Colors.blue),
                _buildLegendItem('پردازش‌شده', Colors.green),
                _buildLegendItem('خروج از انبار', Colors.orange),
                _buildLegendItem('تحویل‌شده', Colors.teal),
                _buildLegendItem('مرجوع‌شده', Colors.red),
                _buildLegendItem('لغوشده', Colors.grey),
              ],
            ),
          ],
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontFamily: 'Vazir', fontSize: 12),
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
        'color': Colors.blue
      },
      OrderStatus.processed: {
        'label': 'پردازش‌شده',
        'icon': FontAwesomeIcons.cogs,
        'color': Colors.green
      },
      OrderStatus.shipped: {
        'label': 'خروج از انبار',
        'icon': FontAwesomeIcons.truck,
        'color': Colors.orange
      },
      OrderStatus.delivered: {
        'label': 'تحویل‌شده',
        'icon': FontAwesomeIcons.checkCircle,
        'color': Colors.teal
      },
      OrderStatus.returned: {
        'label': 'مرجوع‌شده',
        'icon': FontAwesomeIcons.undo,
        'color': Colors.red
      },
      OrderStatus.cancelled: {
        'label': 'لغوشده',
        'icon': FontAwesomeIcons.ban,
        'color': Colors.grey
      },
    };

    final currentStatusIndex = OrderStatus.values.indexOf(order.status);
    final statusesToShow =
        OrderStatus.values.take(currentStatusIndex + 1).toList();

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'سفارش #${order.id}',
              style: const TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 12),
            ...statusesToShow.asMap().entries.map((entry) {
              final index = entry.key;
              final status = entry.value;
              final isLast = index == statusesToShow.length - 1;
              return Row(
                children: [
                  Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusMap[status]!['color'] as Color,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: FaIcon(
                          statusMap[status]!['icon'] as IconData,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 40,
                          color: Colors.grey.shade300,
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusMap[status]!['label'] as String,
                          style: const TextStyle(
                              fontFamily: 'Vazir',
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                          textDirection: TextDirection.rtl,
                        ),
                        Text(
                          'تاریخ: ${order.createdAt.toString().substring(0, 10)}',
                          style: TextStyle(
                              fontFamily: 'Vazir',
                              fontSize: 14,
                              color: Colors.grey.shade600),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String tab,
    required bool isSelected,
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
}
