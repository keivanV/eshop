import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/product_provider.dart';
import '../widgets/product_card.dart';
import '../constants.dart';

class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  _ProductsTabState createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab>
    with SingleTickerProviderStateMixin {
  Future<void>? _fetchProductsFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    debugPrint('ProductsTab initState');
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _fetchProductsFuture =
        Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    // Calculate maxCrossAxisExtent dynamically (140 card width + 20 spacing)
    const cardWidth = 140.0;
    const spacing = 20.0;
    final crossAxisCount =
        (screenWidth / (cardWidth + spacing)).floor().clamp(2, 4);
    final maxCrossAxisExtent = screenWidth / crossAxisCount;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.15), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
            child: FadeInDown(
              duration: const Duration(milliseconds: 800),
              child: Text(
                'محصولات',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontFamily: 'Vazir',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: Colors.white,
              onRefresh: () async {
                debugPrint('Manual refresh triggered for products');
                setState(() {
                  _fetchProductsFuture =
                      Provider.of<ProductProvider>(context, listen: false)
                          .fetchProducts();
                  _animationController.reset();
                  _animationController.forward();
                });
              },
              child: FutureBuilder(
                future: _fetchProductsFuture,
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: _buildCustomLoader());
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: _buildErrorCard(snapshot.error
                            .toString()
                            .replaceFirst('Exception: ', '')));
                  }
                  if (productProvider.products.isEmpty) {
                    return Center(child: _buildNoProductsCard());
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: maxCrossAxisExtent,
                      childAspectRatio: 2 / 3,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                    ),
                    itemCount: productProvider.products.length,
                    itemBuilder: (_, i) {
                      final product = productProvider.products[i];
                      debugPrint('Building ProductCard for ${product.id}');
                      return FadeInUp(
                        duration: const Duration(milliseconds: 600),
                        delay: Duration(milliseconds: 200 * i),
                        child: ProductCard(product: product),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomLoader() {
    return FadeIn(
      duration: const Duration(milliseconds: 1000),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ZoomIn(
            duration: const Duration(milliseconds: 800),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 28,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                strokeWidth: 10,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'در حال بارگذاری محصولات...',
            style: TextStyle(
              fontFamily: 'Vazir',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String errorMessage) {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 14,
              spreadRadius: 4,
            ),
          ],
          border: Border.all(color: Colors.black87, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ZoomIn(
              duration: const Duration(milliseconds: 600),
              child: const FaIcon(
                FontAwesomeIcons.exclamationTriangle,
                color: Colors.redAccent,
                size: 56,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'خطا در بارگذاری محصولات: $errorMessage',
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Vazir',
                fontWeight: FontWeight.w600,
                color: Colors.redAccent,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Bounce(
              duration: const Duration(milliseconds: 800),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.accent, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black87, width: 1),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _fetchProductsFuture =
                          Provider.of<ProductProvider>(context, listen: false)
                              .fetchProducts();
                      _animationController.reset();
                      _animationController.forward();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    elevation: 8,
                    shadowColor: AppColors.accent.withOpacity(0.5),
                  ),
                  child: const Text(
                    'تلاش مجدد',
                    style: TextStyle(
                      fontFamily: 'Vazir',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoProductsCard() {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 14,
              spreadRadius: 4,
            ),
          ],
          border: Border.all(color: Colors.black87, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ZoomIn(
              duration: const Duration(milliseconds: 600),
              child: const FaIcon(
                FontAwesomeIcons.boxOpen,
                color: AppColors.primary,
                size: 56,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'هیچ محصولی یافت نشد',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Vazir',
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Bounce(
              duration: const Duration(milliseconds: 800),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.accent, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black87, width: 1),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _fetchProductsFuture =
                          Provider.of<ProductProvider>(context, listen: false)
                              .fetchProducts();
                      _animationController.reset();
                      _animationController.forward();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    elevation: 8,
                    shadowColor: AppColors.accent.withOpacity(0.5),
                  ),
                  child: const Text(
                    'تلاش مجدد',
                    style: TextStyle(
                      fontFamily: 'Vazir',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
