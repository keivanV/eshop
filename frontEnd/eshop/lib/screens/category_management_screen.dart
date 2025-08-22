import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_app/routes/app_routes.dart';
import '../providers/category_provider.dart';
import '../providers/auth_provider.dart';
import '../models/category.dart';
import '../constants.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  _CategoryManagementScreenState createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String? _editingCategoryId;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);
    try {
      await categoryProvider.fetchCategories();
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

  void _editCategory(Category category) {
    setState(() {
      _editingCategoryId = category.id;
      _name = category.name;
    });
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('مدیریت دسته‌بندی‌ها'),
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
                        labelText: 'نام دسته‌بندی',
                        hintText: 'نام دسته‌بندی را وارد کنید'),
                    textDirection: TextDirection.rtl,
                    validator: (value) => value!.isEmpty ? 'الزامی' : null,
                    onSaved: (value) => _name = value!,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        try {
                          final category = Category(
                              id: _editingCategoryId ?? '', name: _name);
                          if (_editingCategoryId != null) {
                            await categoryProvider.updateCategory(
                                _editingCategoryId!,
                                category,
                                authProvider.token!);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('دسته‌بندی ویرایش شد')));
                          } else {
                            await categoryProvider.createCategory(
                                category, authProvider.token!);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('دسته‌بندی اضافه شد')));
                          }
                          setState(() {
                            _editingCategoryId = null;
                            _name = '';
                          });
                        } catch (e) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text('خطا: $e')));
                        }
                      }
                    },
                    child: Text(_editingCategoryId != null
                        ? 'ویرایش دسته‌بندی'
                        : 'اضافه کردن دسته‌بندی'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: categoryProvider.categories.length,
                itemBuilder: (ctx, i) {
                  final category = categoryProvider.categories[i];
                  return Card(
                    child: ListTile(
                      title:
                          Text(category.name, textDirection: TextDirection.rtl),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editCategory(category),
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
                                  await categoryProvider.deleteCategory(
                                      category.id, authProvider.token!);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('دسته‌بندی حذف شد')));
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
