import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../constants.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../models/product.dart';
import '../models/category.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  _ProductManagementScreenState createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isSubmitting = false;
  String? _editingProductId;
  String? _selectedCategoryId;
  List<XFile> _selectedImages = [];
  List<String> _existingImageUrls = [];
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  String _searchQuery = '';
  String _searchType = 'id'; // 'id' or 'category'
  final String _baseUrl = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/api$'), '');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
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
    if (error.contains('404')) return 'محصول یافت نشد';
    return error.replaceFirst('Exception: ', '');
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
      _currentPage = 1; // Reset to first page on search
    });
  }

  Future<void> _pickImages() async {
    if (Platform.isAndroid) {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('دسترسی به گالری لازم است',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontFamily: 'Vazir')),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }
    final picker = ImagePicker();
    final pickedFiles =
        await picker.pickMultiImage(limit: 5 - _existingImageUrls.length);
    if (pickedFiles != null) {
      setState(() {
        _selectedImages = pickedFiles;
        debugPrint(
            'Selected images: ${_selectedImages.map((file) => file.path).toList()}');
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    try {
      final product = Product(
        id: _editingProductId ?? '',
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        categoryId: _selectedCategoryId ?? '',
        stock: int.parse(_stockController.text.trim()),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        imageUrls: _editingProductId != null ? _existingImageUrls : [],
      );

      if (_editingProductId != null) {
        await productProvider.updateProduct(
            _editingProductId!, product, authProvider.token!);
        if (_selectedImages.isNotEmpty) {
          await productProvider.uploadProductImages(
              _editingProductId!, _selectedImages, authProvider.token!);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('محصول ویرایش شد',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontFamily: 'Vazir')),
              backgroundColor: AppColors.accent,
            ),
          );
        }
      } else {
        await productProvider.createProduct(product, authProvider.token!);
        final newProductId = productProvider.products.last.id;
        debugPrint('New product ID: $newProductId');
        if (_selectedImages.isNotEmpty) {
          await productProvider.uploadProductImages(
              newProductId, _selectedImages, authProvider.token!);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('محصول اضافه شد',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontFamily: 'Vazir')),
              backgroundColor: AppColors.accent,
            ),
          );
        }
      }
      _clearForm();
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

  Future<void> _deleteProduct(String productId) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await Provider.of<ProductProvider>(context, listen: false)
          .deleteProduct(productId, authProvider.token!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('محصول حذف شد',
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

  void _editProduct(Product product) {
    setState(() {
      _editingProductId = product.id;
      _nameController.text = product.name;
      _priceController.text = product.price.toString();
      _stockController.text = product.stock.toString();
      _descriptionController.text = product.description ?? '';
      _selectedCategoryId = product.categoryId;
      _existingImageUrls = product.imageUrls ?? [];
      _selectedImages = [];
    });
  }

  void _clearForm() {
    setState(() {
      _editingProductId = null;
      _nameController.clear();
      _priceController.clear();
      _stockController.clear();
      _descriptionController.clear();
      _selectedCategoryId = null;
      _selectedImages = [];
      _existingImageUrls = [];
    });
  }

  List<Product> _getFilteredProducts(
      List<Product> products, List<Category> categories) {
    if (_searchQuery.isEmpty) return products;
    if (_searchType == 'id') {
      return products
          .where((p) => p.id.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    } else {
      return products.where((p) {
        final category = categories.firstWhere((c) => c.id == p.categoryId,
            orElse: () => Category(id: '', name: ''));
        return category.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final filteredProducts = _getFilteredProducts(
        productProvider.products, categoryProvider.categories);
    final totalPages = (filteredProducts.length / _itemsPerPage).ceil();
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex =
        (startIndex + _itemsPerPage).clamp(0, filteredProducts.length);
    final paginatedProducts = filteredProducts.sublist(startIndex, endIndex);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت محصولات',
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
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(20)),
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
                                      _editingProductId != null
                                          ? 'ویرایش محصول'
                                          : 'افزودن محصول',
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
                                        labelText: 'نام محصول',
                                        labelStyle: const TextStyle(
                                            fontFamily: 'Vazir'),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        filled: true,
                                        fillColor: Colors.grey.shade100,
                                        prefixIcon: const FaIcon(
                                            FontAwesomeIcons.box,
                                            color: AppColors.primary),
                                      ),
                                      textDirection: TextDirection.rtl,
                                      validator: (value) =>
                                          value!.trim().isEmpty
                                              ? 'نام محصول را وارد کنید'
                                              : null,
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _priceController,
                                      decoration: InputDecoration(
                                        labelText: 'قیمت (تومان)',
                                        labelStyle: const TextStyle(
                                            fontFamily: 'Vazir'),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        filled: true,
                                        fillColor: Colors.grey.shade100,
                                        prefixIcon: const FaIcon(
                                            FontAwesomeIcons.moneyBill,
                                            color: AppColors.primary),
                                      ),
                                      textDirection: TextDirection.rtl,
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value!.trim().isEmpty)
                                          return 'قیمت را وارد کنید';
                                        if (double.tryParse(value.trim()) ==
                                                null ||
                                            double.parse(value.trim()) <= 0) {
                                          return 'قیمت باید عدد معتبر باشد';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _stockController,
                                      decoration: InputDecoration(
                                        labelText: 'موجودی',
                                        labelStyle: const TextStyle(
                                            fontFamily: 'Vazir'),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        filled: true,
                                        fillColor: Colors.grey.shade100,
                                        prefixIcon: const FaIcon(
                                            FontAwesomeIcons.warehouse,
                                            color: AppColors.primary),
                                      ),
                                      textDirection: TextDirection.rtl,
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value!.trim().isEmpty)
                                          return 'موجودی را وارد کنید';
                                        if (int.tryParse(value.trim()) ==
                                                null ||
                                            int.parse(value.trim()) < 0) {
                                          return 'موجودی باید عدد معتبر باشد';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _descriptionController,
                                      decoration: InputDecoration(
                                        labelText: 'توضیحات (اختیاری)',
                                        labelStyle: const TextStyle(
                                            fontFamily: 'Vazir'),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        filled: true,
                                        fillColor: Colors.grey.shade100,
                                        prefixIcon: const FaIcon(
                                            FontAwesomeIcons.fileAlt,
                                            color: AppColors.primary),
                                      ),
                                      textDirection: TextDirection.rtl,
                                      maxLines: 3,
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      value: _selectedCategoryId,
                                      decoration: InputDecoration(
                                        labelText: 'دسته‌بندی',
                                        labelStyle: const TextStyle(
                                            fontFamily: 'Vazir'),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        filled: true,
                                        fillColor: Colors.grey.shade100,
                                      ),
                                      items: categoryProvider.categories
                                          .map((category) {
                                        return DropdownMenuItem<String>(
                                          value: category.id,
                                          child: Text(category.name,
                                              style: const TextStyle(
                                                  fontFamily: 'Vazir'),
                                              textDirection: TextDirection.rtl),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(
                                            () => _selectedCategoryId = value);
                                      },
                                      validator: (value) => value == null
                                          ? 'دسته‌بندی را انتخاب کنید'
                                          : null,
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      onPressed:
                                          _isSubmitting ? null : _pickImages,
                                      icon: const FaIcon(FontAwesomeIcons.image,
                                          size: 20),
                                      label: Text(
                                        _selectedImages.isEmpty
                                            ? 'انتخاب تصاویر (${_existingImageUrls.length}/5)'
                                            : '${_selectedImages.length} تصویر انتخاب شده',
                                        style: const TextStyle(
                                            fontFamily: 'Vazir', fontSize: 16),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 12),
                                        elevation: 4,
                                      ),
                                    ),
                                    if (_existingImageUrls.isNotEmpty ||
                                        _selectedImages.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            ..._existingImageUrls.map((url) {
                                              return Stack(
                                                children: [
                                                  Container(
                                                    width: 80,
                                                    height: 80,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      image: DecorationImage(
                                                        image: NetworkImage(
                                                            '$_baseUrl$url'),
                                                        fit: BoxFit.cover,
                                                        onError: (exception,
                                                                stackTrace) =>
                                                            const Icon(
                                                                Icons.error),
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 0,
                                                    right: 0,
                                                    child: IconButton(
                                                      icon: const FaIcon(
                                                          FontAwesomeIcons
                                                              .times,
                                                          color: Colors.red,
                                                          size: 16),
                                                      onPressed: () {
                                                        setState(() {
                                                          _existingImageUrls
                                                              .remove(url);
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }),
                                            ..._selectedImages.map((file) {
                                              return Stack(
                                                children: [
                                                  Container(
                                                    width: 80,
                                                    height: 80,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      image: DecorationImage(
                                                        image: FileImage(
                                                            File(file.path)),
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 0,
                                                    right: 0,
                                                    child: IconButton(
                                                      icon: const FaIcon(
                                                          FontAwesomeIcons
                                                              .times,
                                                          color: Colors.red,
                                                          size: 16),
                                                      onPressed: () {
                                                        setState(() {
                                                          _selectedImages
                                                              .remove(file);
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed:
                                          _isSubmitting ? null : _saveProduct,
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
                                              _editingProductId != null
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
                                    if (_editingProductId != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: TextButton(
                                          onPressed: _clearForm,
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'جستجوی محصولات',
                                    style: TextStyle(
                                        fontFamily: 'Vazir',
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary),
                                    textDirection: TextDirection.rtl,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _searchController,
                                          decoration: InputDecoration(
                                            labelText: 'جستجو',
                                            labelStyle: const TextStyle(
                                                fontFamily: 'Vazir'),
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            filled: true,
                                            fillColor: Colors.grey.shade100,
                                            prefixIcon: const FaIcon(
                                                FontAwesomeIcons.search,
                                                color: AppColors.primary),
                                          ),
                                          textDirection: TextDirection.rtl,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      DropdownButton<String>(
                                        value: _searchType,
                                        items: [
                                          DropdownMenuItem(
                                              value: 'id',
                                              child: Text('شناسه',
                                                  style: const TextStyle(
                                                      fontFamily: 'Vazir'),
                                                  textDirection:
                                                      TextDirection.rtl)),
                                          DropdownMenuItem(
                                              value: 'category',
                                              child: Text('دسته‌بندی',
                                                  style: const TextStyle(
                                                      fontFamily: 'Vazir'),
                                                  textDirection:
                                                      TextDirection.rtl)),
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            _searchType = value!;
                                            _searchQuery =
                                                _searchController.text.trim();
                                            _currentPage = 1;
                                          });
                                        },
                                        style: const TextStyle(
                                            fontFamily: 'Vazir',
                                            color: Colors.black),
                                        dropdownColor: Colors.white,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'لیست محصولات',
                            style: TextStyle(
                                fontFamily: 'Vazir',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 12),
                          filteredProducts.isEmpty
                              ? Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  child: const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(
                                      child: Text(
                                        'هیچ محصولی یافت نشد',
                                        style: TextStyle(
                                            fontFamily: 'Vazir',
                                            fontSize: 16,
                                            color: Colors.grey),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: [
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: paginatedProducts.length,
                                      itemBuilder: (context, index) {
                                        final product =
                                            paginatedProducts[index];
                                        final category = categoryProvider
                                            .categories
                                            .firstWhere(
                                          (c) => c.id == product.categoryId,
                                          orElse: () => Category(
                                              id: '', name: 'بدون دسته‌بندی'),
                                        );
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
                                                    horizontal: 16,
                                                    vertical: 8),
                                            leading: product.imageUrls !=
                                                        null &&
                                                    product
                                                        .imageUrls!.isNotEmpty
                                                ? Container(
                                                    width: 50,
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      image: DecorationImage(
                                                        image: NetworkImage(
                                                            '$_baseUrl${product.imageUrls!.first}'),
                                                        fit: BoxFit.cover,
                                                        onError: (exception,
                                                                stackTrace) =>
                                                            const Icon(
                                                                Icons.error),
                                                      ),
                                                    ),
                                                  )
                                                : const FaIcon(
                                                    FontAwesomeIcons.box,
                                                    color: AppColors.primary),
                                            title: Text(
                                              product.name,
                                              style: const TextStyle(
                                                  fontFamily: 'Vazir',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600),
                                              textDirection: TextDirection.rtl,
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'شناسه: ${product.id}',
                                                  style: const TextStyle(
                                                      fontFamily: 'Vazir',
                                                      fontSize: 14,
                                                      color: Colors.grey),
                                                  textDirection:
                                                      TextDirection.rtl,
                                                ),
                                                Text(
                                                  'دسته‌بندی: ${category.name}',
                                                  style: const TextStyle(
                                                      fontFamily: 'Vazir',
                                                      fontSize: 14,
                                                      color: Colors.grey),
                                                  textDirection:
                                                      TextDirection.rtl,
                                                ),
                                                Text(
                                                  'قیمت: ${product.price.toStringAsFixed(0)} تومان',
                                                  style: const TextStyle(
                                                      fontFamily: 'Vazir',
                                                      fontSize: 14,
                                                      color: Colors.grey),
                                                  textDirection:
                                                      TextDirection.rtl,
                                                ),
                                                Text(
                                                  'موجودی: ${product.stock}',
                                                  style: const TextStyle(
                                                      fontFamily: 'Vazir',
                                                      fontSize: 14,
                                                      color: Colors.grey),
                                                  textDirection:
                                                      TextDirection.rtl,
                                                ),
                                                if (product.description !=
                                                        null &&
                                                    product.description!
                                                        .isNotEmpty)
                                                  Text(
                                                    'توضیحات: ${product.description!.length > 50 ? product.description!.substring(0, 50) + '...' : product.description}',
                                                    style: const TextStyle(
                                                        fontFamily: 'Vazir',
                                                        fontSize: 14,
                                                        color: Colors.grey),
                                                    textDirection:
                                                        TextDirection.rtl,
                                                  ),
                                              ],
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
                                                          _editProduct(product),
                                                ),
                                                IconButton(
                                                  icon: const FaIcon(
                                                      FontAwesomeIcons.trash,
                                                      color: Colors.redAccent),
                                                  onPressed: _isSubmitting
                                                      ? null
                                                      : () =>
                                                          _showDeleteConfirmationDialog(
                                                              context,
                                                              product.id),
                                                ),
                                              ],
                                            ),
                                            onTap: () => _showProductDetails(
                                                context, product, category),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const FaIcon(
                                              FontAwesomeIcons.chevronRight),
                                          onPressed: _currentPage == 1
                                              ? null
                                              : () => setState(
                                                  () => _currentPage--),
                                        ),
                                        Text(
                                          'صفحه $_currentPage از $totalPages',
                                          style: const TextStyle(
                                              fontFamily: 'Vazir',
                                              fontSize: 16),
                                          textDirection: TextDirection.rtl,
                                        ),
                                        IconButton(
                                          icon: const FaIcon(
                                              FontAwesomeIcons.chevronLeft),
                                          onPressed: _currentPage == totalPages
                                              ? null
                                              : () => setState(
                                                  () => _currentPage++),
                                        ),
                                      ],
                                    ),
                                  ],
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

  void _showDeleteConfirmationDialog(BuildContext context, String productId) {
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
            'آیا مطمئن هستید که می‌خواهید این محصول را حذف کنید؟',
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
              _deleteProduct(productId);
              Navigator.pop(context);
            },
            child: const Text('حذف',
                style: TextStyle(fontFamily: 'Vazir', color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showProductDetails(
      BuildContext context, Product product, Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(product.name,
            style: const TextStyle(
                fontFamily: 'Vazir', fontSize: 20, fontWeight: FontWeight.bold),
            textDirection: TextDirection.rtl),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.imageUrls != null && product.imageUrls!.isNotEmpty)
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: product.imageUrls!.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(
                                  '$_baseUrl${product.imageUrls![index]}'),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) =>
                                  const Icon(Icons.error),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              Text('شناسه: ${product.id}',
                  style: const TextStyle(fontFamily: 'Vazir', fontSize: 16),
                  textDirection: TextDirection.rtl),
              Text('دسته‌بندی: ${category.name}',
                  style: const TextStyle(fontFamily: 'Vazir', fontSize: 16),
                  textDirection: TextDirection.rtl),
              Text('قیمت: ${product.price.toStringAsFixed(0)} تومان',
                  style: const TextStyle(fontFamily: 'Vazir', fontSize: 16),
                  textDirection: TextDirection.rtl),
              Text('موجودی: ${product.stock}',
                  style: const TextStyle(fontFamily: 'Vazir', fontSize: 16),
                  textDirection: TextDirection.rtl),
              if (product.description != null &&
                  product.description!.isNotEmpty)
                Text('توضیحات: ${product.description}',
                    style: const TextStyle(fontFamily: 'Vazir', fontSize: 16),
                    textDirection: TextDirection.rtl),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بستن',
                style:
                    TextStyle(fontFamily: 'Vazir', color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
