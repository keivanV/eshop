import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shop_app/models/order.dart';
import 'package:shop_app/screens/inventory_management_screen.dart';
import 'package:shop_app/widgets/product_card.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../constants.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'product_management_screen.dart';
import 'order_management_screen.dart';
import 'category_management_screen.dart';

class DashboardTab extends StatelessWidget {
  final String role;
  final String selectedMenuTab;
  final void Function(String) onTabChanged;

  const DashboardTab({
    super.key,
    required this.role,
    required this.selectedMenuTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final totalProducts = productProvider.products.length;

    // Calculate statistics based on role
    final pendingOrders = orderProvider.orders
        .where((o) => o.status == OrderStatus.pending)
        .length;
    final processedOrders = orderProvider.orders
        .where((o) => o.status == OrderStatus.processed)
        .length;
    final shippedOrders = orderProvider.orders
        .where((o) => o.status == OrderStatus.shipped)
        .length;
    final deliveredOrders = orderProvider.orders
        .where((o) => o.status == OrderStatus.delivered)
        .length;
    final returnedOrders = orderProvider.orders
        .where((o) => o.status == OrderStatus.returned)
        .length;
    final cancelledOrders = orderProvider.orders
        .where((o) => o.status == OrderStatus.cancelled)
        .length;

    // Select relevant statistics based on role
    final stats = role == 'warehouse_manager'
        ? [
            _buildStatRow(
              icon: FontAwesomeIcons.hourglassHalf,
              label: 'سفارشات در انتظار',
              value: pendingOrders.toString(),
            ),
            _buildStatRow(
              icon: FontAwesomeIcons.cogs,
              label: 'سفارشات پردازش‌شده',
              value: processedOrders.toString(),
            ),
            _buildStatRow(
              icon: FontAwesomeIcons.ban,
              label: 'سفارشات لغوشده',
              value: cancelledOrders.toString(),
            ),
          ]
        : role == 'delivery_agent'
            ? [
                _buildStatRow(
                  icon: FontAwesomeIcons.cogs,
                  label: 'سفارشات پردازش‌شده',
                  value: processedOrders.toString(),
                ),
                _buildStatRow(
                  icon: FontAwesomeIcons.truckLoading,
                  label: 'سفارشات ارسال‌شده',
                  value: shippedOrders.toString(),
                ),
                _buildStatRow(
                  icon: FontAwesomeIcons.truck,
                  label: 'سفارشات تحویل‌شده',
                  value: deliveredOrders.toString(),
                ),
                _buildStatRow(
                  icon: FontAwesomeIcons.undo,
                  label: 'سفارشات مرجوعی',
                  value: returnedOrders.toString(),
                ),
              ]
            : [
                _buildStatRow(
                  icon: FontAwesomeIcons.boxes,
                  label: 'تعداد کل محصولات',
                  value: totalProducts.toString(),
                ),
                _buildStatRow(
                  icon: FontAwesomeIcons.cogs,
                  label: 'سفارشات پردازش‌شده',
                  value: processedOrders.toString(),
                ),
                _buildStatRow(
                  icon: FontAwesomeIcons.undo,
                  label: 'سفارشات مرجوعی',
                  value: returnedOrders.toString(),
                ),
                _buildStatRow(
                  icon: FontAwesomeIcons.truck,
                  label: 'سفارشات تحویل‌شده',
                  value: deliveredOrders.toString(),
                ),
              ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'خوش آمدید، ${Provider.of<AuthProvider>(context).userId ?? 'کاربر'}',
            style: const TextStyle(
              fontFamily: 'Vazir',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 4),
          Text(
            'نقش: $role',
            style: TextStyle(
              fontFamily: 'Vazir',
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 20),
          if (role != 'user') _buildMenuSection(context, role),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: role == 'user'
                ? _buildProductsContent(context)
                : _buildMenuTabContent(context, role),
          ),
          if (role != 'user') ...[
            const SizedBox(height: 30),
            const Text(
              'آمار',
              style: TextStyle(
                fontFamily: 'Vazir',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.blue.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 3,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: stats,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, String role) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (role == 'admin' || role == 'warehouse_manager') ...[
            _buildMenuCard(
              context: context,
              icon: FontAwesomeIcons.thList,
              label: 'دسته‌بندی‌ها',
              tab: 'category',
              isSelected: selectedMenuTab == 'category',
            ),
            _buildMenuCard(
              context: context,
              icon: FontAwesomeIcons.box,
              label: 'محصولات',
              tab: 'product_management',
              isSelected: selectedMenuTab == 'product_management',
            ),
            _buildMenuCard(
              context: context,
              icon: FontAwesomeIcons.warehouse,
              label: 'انبار',
              tab: 'inventory',
              isSelected: selectedMenuTab == 'inventory',
            ),
          ],
          _buildMenuCard(
            context: context,
            icon: FontAwesomeIcons.boxOpen,
            label: 'سفارشات',
            tab: 'orders',
            isSelected: selectedMenuTab == 'orders',
          ),
        ],
      ),
    );
  }

  Widget _buildProductsContent(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    return productProvider.products.isEmpty
        ? const Center(
            key: ValueKey('empty_products'),
            child: Text(
              'هیچ محصولی یافت نشد',
              style: TextStyle(fontFamily: 'Vazir', fontSize: 16),
              textDirection: TextDirection.rtl,
            ),
          )
        : GridView.builder(
            key: const ValueKey('products_grid'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: productProvider.products.length,
            itemBuilder: (ctx, i) =>
                ProductCard(product: productProvider.products[i]),
          );
  }

  Widget _buildMenuTabContent(BuildContext context, String role) {
    switch (selectedMenuTab) {
      case 'products':
        return _buildProductsContent(context);
      case 'cart':
        return const CartScreen(key: ValueKey('cart'));
      case 'profile':
        return const ProfileScreen(key: ValueKey('profile'));
      case 'category':
        return const CategoryManagementScreen(key: ValueKey('category'));
      case 'product_management':
        return const ProductManagementScreen(
            key: ValueKey('product_management'));
      case 'inventory':
        return const InventoryManagementScreen(key: ValueKey('inventory'));
      case 'orders':
        return const OrderManagementScreen(key: ValueKey('orders'));
      default:
        return const Center(
          key: ValueKey('invalid_tab'),
          child: Text(
            'تب نامعتبر',
            style: TextStyle(fontFamily: 'Vazir', fontSize: 16),
            textDirection: TextDirection.rtl,
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
          border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent, width: 2),
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
