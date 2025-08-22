import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product.dart';
import '../routes/app_routes.dart';
import '../constants.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  _InventoryManagementScreenState createState() =>
      _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  int _stock = 0;
  String _productId = '';
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final inventoryProvider =
        Provider.of<InventoryProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await Future.wait([
        productProvider.fetchProducts(),
        inventoryProvider.fetchInventory(authProvider.token!),
      ]);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError) {
      return Scaffold(
        body: Center(
            child: Text('خطا در بارگذاری موجودی: $_errorMessage',
                textDirection: TextDirection.rtl)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت انبار'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'خروج',
            onPressed: () async {
              await authProvider.logout();
              Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.login, (route) => false);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _productId.isEmpty ? null : _productId,
                    decoration: const InputDecoration(
                        labelText: 'محصول', hintText: 'یک محصول انتخاب کنید'),
                    items: productProvider.products
                        .map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.name,
                                  textDirection: TextDirection.rtl),
                            ))
                        .toList(),
                    validator: (value) => value == null ? 'الزامی' : null,
                    onChanged: (value) => setState(() => _productId = value!),
                  ),
                  TextFormField(
                    initialValue: _stock.toString(),
                    decoration: const InputDecoration(
                      labelText: 'موجودی',
                      hintText: 'تعداد موجودی را وارد کنید',
                    ),
                    textDirection: TextDirection.rtl,
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        int.tryParse(value!) == null ? 'مقدار نامعتبر' : null,
                    onSaved: (value) => _stock = int.parse(value!),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        try {
                          await inventoryProvider.updateInventory(
                              _productId, _stock, authProvider.token!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('موجودی با موفقیت به‌روزرسانی شد',
                                    textDirection: TextDirection.rtl)),
                          );
                          setState(() {
                            _productId = '';
                            _stock = 0;
                          });
                          // Fetch inventory again to update UI
                          await inventoryProvider
                              .fetchInventory(authProvider.token!);
                        } catch (e) {
                          String errorMessage =
                              e.toString().replaceFirst('Exception: ', '');
                          if (errorMessage.contains('403')) {
                            errorMessage =
                                'عدم دسترسی: لطفاً با حساب مدیر وارد شوید';
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'خطا در به‌روزرسانی موجودی: $errorMessage',
                                  textDirection: TextDirection.rtl),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('به‌روزرسانی موجودی'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Consumer<InventoryProvider>(
                builder: (ctx, inventoryProvider, _) => ListView.builder(
                  itemCount: inventoryProvider.inventory.length,
                  itemBuilder: (ctx, i) {
                    final item = inventoryProvider.inventory[i];
                    final product = productProvider.products.firstWhere(
                      (p) => p.id == item.productId,
                      orElse: () => Product(
                          id: '',
                          name: 'نامشخص',
                          price: 0,
                          categoryId: '',
                          stock: 0),
                    );
                    return Card(
                      child: ListTile(
                        title: Text(product.name,
                            textDirection: TextDirection.rtl),
                        subtitle: Text(
                            'موجودی: ${item.quantity} | به‌روزرسانی: ${item.lastUpdated.toString()}',
                            textDirection: TextDirection.rtl),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => setState(() {
                            _productId = item.productId;
                            _stock = item.quantity;
                          }),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
