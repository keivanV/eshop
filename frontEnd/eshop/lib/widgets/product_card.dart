import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animate_do/animate_do.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../routes/app_routes.dart';
import '../constants.dart';

class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isHovered = false;
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    const baseUrl = 'http://localhost:5000'; // Adjust for production
    final imageUrls =
        widget.product.imageUrls != null && widget.product.imageUrls!.isNotEmpty
            ? widget.product.imageUrls!.map((url) {
                final fullUrl = url.startsWith('http') ? url : '$baseUrl$url';
                debugPrint(
                    'Loading image for product ${widget.product.id}: $fullUrl');
                return fullUrl;
              }).toList()
            : ['https://placehold.co/200x120'];

    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 140, maxHeight: 240),
        child: FadeIn(
          duration: const Duration(milliseconds: 400),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            transform: Matrix4.identity()..scale(_isHovered ? 1.03 : 1.0),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isHovered ? 0.2 : 0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: _isHovered ? AppColors.accent : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: Colors.transparent,
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        child: AnimatedOpacity(
                          opacity: widget.product.stock > 0 ? 1.0 : 0.6,
                          duration: const Duration(milliseconds: 200),
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: CarouselSlider(
                                  options: CarouselOptions(
                                    height: 80,
                                    autoPlay: imageUrls.length > 1,
                                    autoPlayInterval:
                                        const Duration(seconds: 3),
                                    autoPlayAnimationDuration:
                                        const Duration(milliseconds: 600),
                                    autoPlayCurve: Curves.easeInOut,
                                    enlargeCenterPage: true,
                                    viewportFraction: 1.0,
                                    onPageChanged: (index, reason) {
                                      setState(() {
                                        _currentImageIndex = index;
                                      });
                                      debugPrint(
                                          'Carousel changed to image index: $index for product ${widget.product.id}');
                                    },
                                  ),
                                  items: imageUrls.map((url) {
                                    return Hero(
                                      tag:
                                          'product-image-${widget.product.id}-${url.hashCode}',
                                      child: CachedNetworkImage(
                                        imageUrl: url,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: 80,
                                        memCacheHeight: 160,
                                        memCacheWidth: 240,
                                        placeholder: (context, url) =>
                                            Container(
                                          color: Colors.grey[100],
                                          height: 80,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                      AppColors.accent),
                                              strokeWidth: 4,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) {
                                          debugPrint(
                                              'Image load error for $url: $error');
                                          return Container(
                                            color: Colors.grey[100],
                                            height: 80,
                                            child: const Center(
                                              child: FaIcon(
                                                FontAwesomeIcons.image,
                                                color: Colors.grey,
                                                size: 28,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              if (imageUrls.length > 1)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children:
                                        imageUrls.asMap().entries.map((entry) {
                                      return Container(
                                        width: 5.0,
                                        height: 5.0,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 2.0),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.accent.withOpacity(
                                              _currentImageIndex == entry.key
                                                  ? 1.0
                                                  : 0.3),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                fontFamily: 'Vazir',
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.rtl,
                            ),
                            const SizedBox(height: 4),
                            if (widget.product.description != null &&
                                widget.product.description!.isNotEmpty)
                              Text(
                                widget.product.description!.length > 50
                                    ? '${widget.product.description!.substring(0, 50)}...'
                                    : widget.product.description!,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: widget.product.stock > 0
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade400,
                                  fontFamily: 'Vazir',
                                ),
                                textDirection: TextDirection.rtl,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.box,
                                  size: 15,
                                  color: widget.product.stock > 0
                                      ? Colors.green.shade600
                                      : Colors.red.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.product.stock > 0
                                      ? 'موجودی: ${widget.product.stock}'
                                      : 'ناموجود',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: widget.product.stock > 0
                                        ? Colors.green.shade600
                                        : Colors.red.shade600,
                                    fontFamily: 'Vazir',
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.tag,
                                  size: 15,
                                  color: widget.product.stock > 0
                                      ? AppColors.accent
                                      : Colors.grey.shade400,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'قیمت: ${widget.product.price.toStringAsFixed(0)} تومان',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: widget.product.stock > 0
                                        ? AppColors.accent
                                        : Colors.grey.shade400,
                                    fontFamily: 'Vazir',
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (widget.product.stock > 0)
                              QuantitySelector(
                                product: widget.product,
                                cartProvider: cartProvider,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (widget.product.stock == 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: ZoomIn(
                        duration: const Duration(milliseconds: 400),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Text(
                            'ناموجود',
                            style: TextStyle(
                              fontFamily: 'Vazir',
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class QuantitySelector extends StatefulWidget {
  final Product product;
  final CartProvider cartProvider;

  const QuantitySelector({
    super.key,
    required this.product,
    required this.cartProvider,
  });

  @override
  _QuantitySelectorState createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<QuantitySelector> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // دکمه کاهش تعداد
            GestureDetector(
              onTap: () {
                if (_quantity > 1) {
                  setState(() {
                    _quantity--;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent,
                      AppColors.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.minus,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accent, width: 1),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                '$_quantity',
                style: const TextStyle(
                  fontFamily: 'Vazir',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // دکمه افزایش تعداد
            GestureDetector(
              onTap: () {
                if (_quantity < widget.product.stock) {
                  setState(() {
                    _quantity++;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent,
                      AppColors.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.plus,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        // دکمه ثبت
        ZoomIn(
          duration: const Duration(milliseconds: 400),
          child: GestureDetector(
            onTap: () {
              widget.cartProvider.addItem(widget.product, _quantity);
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'محصول ${widget.product.name} به سبد خرید اضافه شد',
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontFamily: 'Vazir',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: AppColors.accent,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: Matrix4.identity()..scale(1.0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent,
                    AppColors.primary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Pulse(
                    duration: const Duration(seconds: 2),
                    child: FaIcon(
                      FontAwesomeIcons.cartPlus,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'افزودن به سبد',
                    style: TextStyle(
                      fontFamily: 'Vazir',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
