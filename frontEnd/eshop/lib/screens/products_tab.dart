
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../widgets/product_card.dart';
import '../constants.dart';

class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  _ProductsTabState createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  Future<void>? _fetchProductsFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the future in initState to prevent repeated fetching
    _fetchProductsFuture =
        Provider.of<ProductProvider>(context, listen: false).fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Text(
            'محصولات',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontFamily: 'Vazir', fontWeight: FontWeight.bold),
            textDirection: TextDirection.rtl,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              // Create a new future for refresh
              setState(() {
                _fetchProductsFuture =
                    Provider.of<ProductProvider>(context, listen: false)
                        .fetchProducts();
              });
            },
            child: FutureBuilder(
              future: _fetchProductsFuture,
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'خطا در بارگذاری محصولات: ${snapshot.error.toString().replaceFirst('Exception: ', '')}',
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                              fontFamily: 'Vazir', fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _fetchProductsFuture =
                                  Provider.of<ProductProvider>(context,
                                          listen: false)
                                      .fetchProducts();
                            });
                          },
                          child: const Text('تلاش مجدد',
                              style: TextStyle(fontFamily: 'Vazir')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (productProvider.products.isEmpty) {
                  return const Center(
                    child: Text(
                      'هیچ محصولی یافت نشد',
                      style: TextStyle(fontFamily: 'Vazir', fontSize: 16),
                      textDirection: TextDirection.rtl,
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2 / 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: productProvider.products.length,
                  itemBuilder: (_, i) {
                    final product = productProvider.products[i];
                    return ProductCard(product: product);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
