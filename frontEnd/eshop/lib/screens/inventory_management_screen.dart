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
    debugPrint('InventoryManagementScreen initState');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final inventoryProvider =
        Provider.of<InventoryProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      debugPrint('Fetching products and inventory...');
      await Future.wait([
        productProvider.fetchProducts(),
        inventoryProvider.fetchInventory(authProvider.token!),
      ]);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false;
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
      return 'عدم دسترسی: لطفاً با حساب مدیر وارد شوید';
    } else if (error.contains('404')) {
      return 'داده‌ای یافت نشد';
    } else if (error.contains('Inventory not found')) {
      return 'موجودی برای محصول یافت نشد. لطفاً موجودی را به‌روزرسانی کنید.';
    } else {
      return error.replaceFirst('Exception: ', '');
    }
  }

  Future<void> _updateInventory() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    final inventoryProvider =
        Provider.of<InventoryProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      debugPrint('Updating inventory for product $_productId to stock $_stock');
      await inventoryProvider.updateInventory(
          _productId, _stock, authProvider.token!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'موجودی با موفقیت به‌روزرسانی شد',
              textDirection: TextDirection.rtl,
              style: TextStyle(fontFamily: 'Vazir'),
            ),
            backgroundColor: AppColors.accent,
          ),
        );
        setState(() {
          _productId = '';
          _stock = 0;
        });
        await inventoryProvider.fetchInventory(authProvider.token!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطا در به‌روزرسانی موجودی: ${_formatErrorMessage(e.toString())}',
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontFamily: 'Vazir'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Error updating inventory: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('مدیریت انبار', style: TextStyle(fontFamily: 'Vazir')),
        backgroundColor: AppColors.primary,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorWidget()
              : _buildInventoryList(
                  context, productProvider, inventoryProvider),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'خطا در بارگذاری موجودی: $_errorMessage',
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontSize: 16, fontFamily: 'Vazir'),
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
            child:
                const Text('تلاش مجدد', style: TextStyle(fontFamily: 'Vazir')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryList(BuildContext context,
      ProductProvider productProvider, InventoryProvider inventoryProvider) {
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'به‌روزرسانی موجودی',
                style: TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 12),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _productId.isEmpty ? null : _productId,
                      decoration: const InputDecoration(
                        labelText: 'محصول',
                        hintText: 'یک محصول انتخاب کنید',
                        labelStyle: TextStyle(fontFamily: 'Vazir'),
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: productProvider.products
                          .map((p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(
                                  p.name,
                                  textDirection: TextDirection.rtl,
                                  style: const TextStyle(fontFamily: 'Vazir'),
                                ),
                              ))
                          .toList(),
                      validator: (value) =>
                          value == null ? 'لطفاً یک محصول انتخاب کنید' : null,
                      onChanged: (value) async {
                        if (value == null) return;
                        setState(() {
                          _productId = value;
                          _stock = 0; // Reset stock until fetched
                        });
                        final inventoryProvider =
                            Provider.of<InventoryProvider>(context,
                                listen: false);
                        final authProvider =
                            Provider.of<AuthProvider>(context, listen: false);
                        try {
                          final inventory =
                              await inventoryProvider.fetchInventoryByProduct(
                                  value, authProvider.token!);
                          setState(() {
                            _stock = inventory.quantity;
                          });
                        } catch (e) {
                          // If inventory not found, use product stock
                          final product = productProvider.products
                              .firstWhere((p) => p.id == value);
                          setState(() {
                            _stock = product.stock;
                          });
                          debugPrint(
                              'Inventory not found for product $value, using product stock: ${product.stock}');
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: _stock.toString(),
                      decoration: const InputDecoration(
                        labelText: 'موجودی',
                        hintText: 'تعداد موجودی را وارد کنید',
                        labelStyle: TextStyle(fontFamily: 'Vazir'),
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      textDirection: TextDirection.rtl,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'لطفاً مقدار موجودی را وارد کنید';
                        }
                        final parsed = int.tryParse(value);
                        if (parsed == null || parsed < 0) {
                          return 'لطفاً یک عدد معتبر و غیرمنفی وارد کنید';
                        }
                        return null;
                      },
                      onSaved: (value) => _stock = int.parse(value!),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _updateInventory,
                      child: const Text('به‌روزرسانی موجودی',
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
              ),
              const SizedBox(height: 20),
              const Text(
                'لیست موجودی',
                style: TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textDirection: TextDirection.rtl,
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
                      stock: 0,
                    ),
                  );
                  return Card(
                    elevation: 4,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        product.name,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontFamily: 'Vazir',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        'موجودی: ${item.quantity} | به‌روزرسانی: ${item.lastUpdated.toString()}',
                        textDirection: TextDirection.rtl,
                        style:
                            const TextStyle(fontFamily: 'Vazir', fontSize: 14),
                      ),
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
            ],
          ),
        ),
      ),
    );
  }
}
