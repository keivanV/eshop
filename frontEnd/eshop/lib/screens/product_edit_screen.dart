import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../providers/auth_provider.dart';
import '../models/product.dart';
import '../constants.dart';

class ProductEditScreen extends StatefulWidget {
  final String? productId;

  const ProductEditScreen({super.key, this.productId});

  @override
  _ProductEditScreenState createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  String? _selectedCategoryId;
  bool _isLoading = false;
  String? _errorMessage;
  List<String> _existingImageUrls = [];
  List<XFile> _newImages = [];
  List<int> _imagesToDelete = [];

  static const String _baseUrl =
      'http://localhost:5000'; // Adjust for production

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _stockController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      final categoryProvider =
          Provider.of<CategoryProvider>(context, listen: false);

      if (categoryProvider.categories.isNotEmpty) {
        _selectedCategoryId = categoryProvider.categories.first.id;
      }

      if (widget.productId != null) {
        final product = productProvider.products.firstWhere(
          (p) => p.id == widget.productId,
          orElse: () =>
              Product(id: '', name: '', price: 0.0, categoryId: '', stock: 0),
        );
        if (product.id.isNotEmpty) {
          _nameController.text = product.name;
          _descriptionController.text = product.description ?? '';
          _priceController.text = product.price.toString();
          _stockController.text = product.stock.toString();
          _selectedCategoryId = product.categoryId.isNotEmpty
              ? product.categoryId
              : categoryProvider.categories.isNotEmpty
                  ? categoryProvider.categories.first.id
                  : null;
          _existingImageUrls = List.from(product.imageUrls ?? []);
          print('Existing image URLs: $_existingImageUrls'); // Debug log
        }
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images != null) {
      setState(() {
        _newImages.addAll(images);
      });
    }
  }

  Future<void> _deleteImage(int index, bool isExisting) async {
    if (isExisting) {
      setState(() {
        _imagesToDelete.add(index);
      });
    } else {
      setState(() {
        _newImages.removeAt(index - _existingImageUrls.length);
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final product = Product(
        id: widget.productId ?? '',
        name: _nameController.text,
        price: double.parse(_priceController.text),
        categoryId: _selectedCategoryId ?? '',
        stock: int.parse(_stockController.text),
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        imageUrls: _existingImageUrls
            .asMap()
            .entries
            .where((entry) => !_imagesToDelete.contains(entry.key))
            .map((entry) => entry.value)
            .toList(),
      );

      String? newProductId = widget.productId;
      if (widget.productId != null) {
        await productProvider.updateProduct(
          widget.productId!,
          product,
          authProvider.token!,
        );
      } else {
        newProductId = await productProvider.createProduct(
          product,
          authProvider.token!,
        );
      }

      if (_newImages.isNotEmpty && newProductId != null) {
        await productProvider.uploadProductImages(
            newProductId, _newImages, authProvider.token!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.productId != null
                  ? 'محصول با موفقیت به‌روزرسانی شد'
                  : 'محصول با موفقیت ایجاد شد',
              style: const TextStyle(fontFamily: 'Vazir'),
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: AppColors.accent,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.productId != null ? 'ویرایش محصول' : 'ایجاد محصول جدید',
          style: const TextStyle(
              fontFamily: 'Vazir', fontSize: 20, fontWeight: FontWeight.bold),
          textDirection: TextDirection.rtl,
        ),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(AppColors.accent)))
            : SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'خطا: $_errorMessage',
                            style: const TextStyle(
                                fontFamily: 'Vazir',
                                fontSize: 14,
                                color: Colors.redAccent),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'نام محصول',
                          labelStyle: const TextStyle(fontFamily: 'Vazir'),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        textDirection: TextDirection.rtl,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'لطفاً نام محصول را وارد کنید';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'توضیحات',
                          labelStyle: const TextStyle(fontFamily: 'Vazir'),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        textDirection: TextDirection.rtl,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: 'قیمت (تومان)',
                          labelStyle: const TextStyle(fontFamily: 'Vazir'),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        textDirection: TextDirection.rtl,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'لطفاً قیمت را وارد کنید';
                          }
                          if (double.tryParse(value) == null ||
                              double.parse(value) < 0) {
                            return 'قیمت نامعتبر است';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _stockController,
                        decoration: InputDecoration(
                          labelText: 'موجودی',
                          labelStyle: const TextStyle(fontFamily: 'Vazir'),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        textDirection: TextDirection.rtl,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'لطفاً موجودی را وارد کنید';
                          }
                          if (int.tryParse(value) == null ||
                              int.parse(value) < 0) {
                            return 'موجودی نامعتبر است';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategoryId,
                        decoration: InputDecoration(
                          labelText: 'دسته‌بندی',
                          labelStyle: const TextStyle(fontFamily: 'Vazir'),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        items: categoryProvider.categories.isEmpty
                            ? [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text(
                                    'بدون دسته‌بندی',
                                    style: TextStyle(fontFamily: 'Vazir'),
                                    textDirection: TextDirection.rtl,
                                  ),
                                )
                              ]
                            : categoryProvider.categories
                                .map((category) => DropdownMenuItem(
                                      value: category.id,
                                      child: Text(
                                        category.name,
                                        style: const TextStyle(
                                            fontFamily: 'Vazir'),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ))
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null &&
                              categoryProvider.categories.isNotEmpty) {
                            return 'لطفاً یک دسته‌بندی انتخاب کنید';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'تصاویر محصول',
                        style: TextStyle(
                            fontFamily: 'Vazir',
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._existingImageUrls
                              .asMap()
                              .entries
                              .where((entry) =>
                                  !_imagesToDelete.contains(entry.key))
                              .map((entry) {
                            final index = entry.key;
                            final url = entry.value;
                            final fullUrl = '$_baseUrl$url';
                            print('Loading image: $fullUrl'); // Debug log
                            return Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      fullUrl,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    (loadingProgress
                                                            .expectedTotalBytes ??
                                                        1)
                                                : null,
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        print(
                                            'Image load error for $fullUrl: $error');
                                        return const Icon(
                                          Icons.broken_image,
                                          size: 50,
                                          color: Colors.redAccent,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.redAccent, size: 20),
                                    onPressed: () => _deleteImage(index, true),
                                  ),
                                ),
                              ],
                            );
                          }),
                          ..._newImages.asMap().entries.map((entry) {
                            final index = entry.key;
                            final image = entry.value;
                            return Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(image.path),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        print(
                                            'Local image load error for ${image.path}: $error');
                                        return const Icon(
                                          Icons.broken_image,
                                          size: 50,
                                          color: Colors.redAccent,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.redAccent, size: 20),
                                    onPressed: () => _deleteImage(index, false),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.add_photo_alternate,
                              color: Colors.white),
                          label: const Text(
                            'افزودن تصویر',
                            style: TextStyle(fontFamily: 'Vazir'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: ElevatedButton(
                          onPressed: _saveProduct,
                          child: Text(
                            widget.productId != null
                                ? 'ذخیره تغییرات'
                                : 'ایجاد محصول',
                            style: const TextStyle(
                                fontFamily: 'Vazir', fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
