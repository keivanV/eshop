import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../constants.dart';
import '../providers/auth_provider.dart';
import '../providers/category_provider.dart';
import '../services/api_service.dart';
import '../models/category.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  _CategoryManagementScreenState createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isSubmitting = false;
  String? _editingCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);
    try {
      await categoryProvider.fetchCategories();
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
    if (error.contains('403')) return 'عدم دسترسی';
    if (error.contains('404')) return 'دسته‌بندی یافت نشد';
    return error.replaceFirst('Exception: ', '');
  }

  Future<void> _saveCategory() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);
    try {
      final category = Category(
          id: _editingCategoryId ?? '', name: _nameController.text.trim());
      if (_editingCategoryId != null) {
        await categoryProvider.updateCategory(
            _editingCategoryId!, category, authProvider.token!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('دسته‌بندی ویرایش شد',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontFamily: 'Vazir')),
              backgroundColor: AppColors.accent,
            ),
          );
        }
      } else {
        await categoryProvider.createCategory(category, authProvider.token!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('دسته‌بندی اضافه شد',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontFamily: 'Vazir')),
              backgroundColor: AppColors.accent,
            ),
          );
        }
      }
      _nameController.clear();
      setState(() => _editingCategoryId = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا: ${_formatErrorMessage(e.toString())}',
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontFamily: 'Vazir')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteCategory(String categoryId) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await Provider.of<CategoryProvider>(context, listen: false)
          .deleteCategory(categoryId, authProvider.token!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('دسته‌بندی حذف شد',
                textDirection: TextDirection.rtl,
                style: TextStyle(fontFamily: 'Vazir')),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا: ${_formatErrorMessage(e.toString())}',
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontFamily: 'Vazir')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _editCategory(Category category) {
    setState(() {
      _editingCategoryId = category.id;
      _nameController.text = category.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت دسته‌بندی‌ها',
            style: TextStyle(
                fontFamily: 'Vazir',
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.accent.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(AppColors.accent)))
          : _hasError
              ? _buildErrorWidget()
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  color: AppColors.accent,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.white, Colors.blue.shade50],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(16.0),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _editingCategoryId != null
                                          ? 'ویرایش دسته‌بندی'
                                          : 'افزودن دسته‌بندی',
                                      style: const TextStyle(
                                          fontFamily: 'Vazir',
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary),
                                      textDirection: TextDirection.rtl,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _nameController,
                                      decoration: InputDecoration(
                                        labelText: 'نام دسته‌بندی',
                                        labelStyle: const TextStyle(
                                            fontFamily: 'Vazir'),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        filled: true,
                                        fillColor: Colors.grey.shade100,
                                        prefixIcon: const FaIcon(
                                            FontAwesomeIcons.thList,
                                            color: AppColors.primary),
                                      ),
                                      textDirection: TextDirection.rtl,
                                      validator: (value) =>
                                          value!.trim().isEmpty
                                              ? 'نام دسته‌بندی را وارد کنید'
                                              : null,
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed:
                                          _isSubmitting ? null : _saveCategory,
                                      child: _isSubmitting
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation(
                                                          Colors.white)))
                                          : Text(
                                              _editingCategoryId != null
                                                  ? 'ذخیره تغییرات'
                                                  : 'افزودن',
                                              style: const TextStyle(
                                                  fontFamily: 'Vazir',
                                                  fontSize: 16)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.accent,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 12),
                                        elevation: 4,
                                      ),
                                    ),
                                    if (_editingCategoryId != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _editingCategoryId = null;
                                              _nameController.clear();
                                            });
                                          },
                                          child: const Text('لغو ویرایش',
                                              style: TextStyle(
                                                  fontFamily: 'Vazir',
                                                  color: Colors.grey)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'لیست دسته‌بندی‌ها',
                            style: TextStyle(
                                fontFamily: 'Vazir',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 12),
                          categoryProvider.categories.isEmpty
                              ? Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  child: const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(
                                      child: Text(
                                        'هیچ دسته‌بندی یافت نشد',
                                        style: TextStyle(
                                            fontFamily: 'Vazir',
                                            fontSize: 16,
                                            color: Colors.grey),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: categoryProvider.categories.length,
                                  itemBuilder: (context, index) {
                                    final category =
                                        categoryProvider.categories[index];
                                    return Card(
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                        title: Text(
                                          category.name,
                                          style: const TextStyle(
                                              fontFamily: 'Vazir',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600),
                                          textDirection: TextDirection.rtl,
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const FaIcon(
                                                  FontAwesomeIcons.edit,
                                                  color: AppColors.primary),
                                              onPressed: _isSubmitting
                                                  ? null
                                                  : () =>
                                                      _editCategory(category),
                                            ),
                                            IconButton(
                                              icon: const FaIcon(
                                                  FontAwesomeIcons.trash,
                                                  color: Colors.redAccent),
                                              onPressed: _isSubmitting
                                                  ? null
                                                  : () =>
                                                      _showDeleteConfirmationDialog(
                                                          context, category.id),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
      backgroundColor: Colors.grey.shade100,
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Card(
            elevation: 8,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'خطا: $_errorMessage',
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                    fontFamily: 'Vazir', fontSize: 16, color: Colors.redAccent),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _fetchData,
            child: const Text('تلاش مجدد',
                style: TextStyle(fontFamily: 'Vazir', fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String categoryId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تأیید حذف',
            style: TextStyle(
                fontFamily: 'Vazir',
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        content: const Text(
            'آیا مطمئن هستید که می‌خواهید این دسته‌بندی را حذف کنید؟',
            style: TextStyle(fontFamily: 'Vazir'),
            textDirection: TextDirection.rtl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو',
                style: TextStyle(fontFamily: 'Vazir', color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              _deleteCategory(categoryId);
              Navigator.pop(context);
            },
            child: const Text('حذف',
                style: TextStyle(fontFamily: 'Vazir', color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
