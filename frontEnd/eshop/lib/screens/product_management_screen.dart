import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/routes/app_routes.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product.dart';
import '../constants.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  _ProductManagementScreenState createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _description = '';
  double _price = 0;
  String _categoryId = '';
  String? _editingProductId;
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
    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);
    try {
      await Future.wait([
        productProvider.fetchProducts(),
        categoryProvider.fetchCategories(),
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
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _editProduct(Product product) {
    setState(() {
      _editingProductId = product.id;
      _name = product.name;
      _description = product.description ?? '';
      _price = product.price;
      _categoryId = product.categoryId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError) {
      return Scaffold(
        body: Center(child: Text('خطا در بارگذاری اطلاعات: $_errorMessage')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت محصولات'),
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
                  TextFormField(
                    initialValue: _name,
                    decoration: const InputDecoration(
                        labelText: 'نام محصول',
                        hintText: 'نام محصول را وارد کنید'),
                    textDirection: TextDirection.rtl,
                    validator: (value) => value!.isEmpty ? 'الزامی' : null,
                    onSaved: (value) => _name = value!,
                  ),
                  TextFormField(
                    initialValue: _description,
                    decoration: const InputDecoration(
                        labelText: 'توضیحات',
                        hintText: 'توضیحات محصول را وارد کنید'),
                    textDirection: TextDirection.rtl,
                    onSaved: (value) => _description = value!,
                  ),
                  TextFormField(
                    initialValue: _price.toString(),
                    decoration: const InputDecoration(
                        labelText: 'قیمت', hintText: 'قیمت به تومان'),
                    textDirection: TextDirection.rtl,
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        double.tryParse(value!) == null ? 'قیمت نامعتبر' : null,
                    onSaved: (value) => _price = double.parse(value!),
                  ),
                  DropdownButtonFormField<String>(
                    value: _categoryId.isEmpty ? null : _categoryId,
                    decoration: const InputDecoration(labelText: 'دسته‌بندی'),
                    items: categoryProvider.categories
                        .map((c) => DropdownMenuItem(
                            value: c.id,
                            child:
                                Text(c.name, textDirection: TextDirection.rtl)))
                        .toList(),
                    validator: (value) => value == null ? 'الزامی' : null,
                    onChanged: (value) => setState(() => _categoryId = value!),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        try {
                          final product = Product(
                            id: _editingProductId ?? '',
                            name: _name,
                            description: _description,
                            price: _price,
                            categoryId: _categoryId,
                            stock: 0,
                          );
                          if (_editingProductId != null) {
                            await productProvider.updateProduct(
                                _editingProductId!,
                                product,
                                authProvider.token!);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('محصول ویرایش شد')));
                          } else {
                            await productProvider.createProduct(
                                product, authProvider.token!);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('محصول اضافه شد')));
                          }
                          setState(() {
                            _editingProductId = null;
                            _name = '';
                            _description = '';
                            _price = 0;
                            _categoryId = '';
                          });
                        } catch (e) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text('خطا: $e')));
                        }
                      }
                    },
                    child: Text(_editingProductId != null
                        ? 'ویرایش محصول'
                        : 'اضافه کردن محصول'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: productProvider.products.length,
                itemBuilder: (ctx, i) {
                  final product = productProvider.products[i];
                  return Card(
                    child: ListTile(
                      title:
                          Text(product.name, textDirection: TextDirection.rtl),
                      subtitle: Text(
                          'قیمت: ${product.price.toStringAsFixed(0)} تومان | موجودی: ${product.stock}',
                          textDirection: TextDirection.rtl),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editProduct(product),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('تأیید حذف',
                                      textDirection: TextDirection.rtl),
                                  content: const Text('آیا مطمئن هستید؟',
                                      textDirection: TextDirection.rtl),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('خیر'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('بله'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm) {
                                try {
                                  await productProvider.deleteProduct(
                                      product.id, authProvider.token!);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('محصول حذف شد')));
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('خطا: $e')));
                                }
                              }
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
  }
}
