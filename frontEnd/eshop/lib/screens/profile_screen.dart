import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../routes/app_routes.dart';
import '../constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('پروفایل')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('نام کاربری: ${authProvider.userId}',
                style: Theme.of(context).textTheme.titleLarge,
                textDirection: TextDirection.rtl),
            Text('نقش: ${authProvider.role}',
                style: Theme.of(context).textTheme.titleMedium,
                textDirection: TextDirection.rtl),
            const SizedBox(height: 20),
            const Text('سفارشات من',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textDirection: TextDirection.rtl),
            Expanded(
              child: FutureBuilder(
                future: orderProvider.fetchOrders(authProvider.token!, '', ''),
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text(
                            'خطا در بارگذاری سفارشات: ${snapshot.error.toString().replaceFirst('Exception: ', '')}',
                            textDirection: TextDirection.rtl));
                  }
                  return ListView.builder(
                    itemCount: orderProvider.orders.length,
                    itemBuilder: (ctx, i) {
                      final order = orderProvider.orders[i];
                      return Card(
                        elevation: 3,
                        child: ListTile(
                          title: Text('سفارش #${order.id}',
                              textDirection: TextDirection.rtl),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'وضعیت: ${order.status.toString().split('.').last}',
                                  textDirection: TextDirection.rtl),
                              Text(
                                  'جمع کل: ${order.totalAmount.toStringAsFixed(2)} تومان',
                                  textDirection: TextDirection.rtl),
                              if (order.returnRequest)
                                const Text('درخواست مرجوعی ثبت شده',
                                    style: TextStyle(color: Colors.red),
                                    textDirection: TextDirection.rtl),
                            ],
                          ),
                          trailing: order.status == OrderStatus.pending
                              ? IconButton(
                                  icon: const Icon(Icons.cancel,
                                      color: Colors.red),
                                  onPressed: () async {
                                    try {
                                      await orderProvider.cancelOrder(
                                          order.id, authProvider.token!);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('سفارش لغو شد',
                                              textDirection: TextDirection.rtl),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'خطا در لغو سفارش: ${e.toString().replaceFirst('Exception: ', '')}',
                                              textDirection: TextDirection.rtl),
                                        ),
                                      );
                                    }
                                  },
                                )
                              : order.status == OrderStatus.delivered &&
                                      !order.returnRequest
                                  ? IconButton(
                                      icon: const Icon(Icons.reply,
                                          color: Colors.orange),
                                      onPressed: () async {
                                        try {
                                          await orderProvider.requestReturn(
                                              order.id, authProvider.token!);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'درخواست مرجوعی ثبت شد',
                                                  textDirection:
                                                      TextDirection.rtl),
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'خطا در درخواست مرجوعی: ${e.toString().replaceFirst('Exception: ', '')}',
                                                  textDirection:
                                                      TextDirection.rtl),
                                            ),
                                          );
                                        }
                                      },
                                    )
                                  : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
