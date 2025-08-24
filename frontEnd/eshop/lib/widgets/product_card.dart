import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  int _quantity = 1;

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
      onTap: () {
        debugPrint('Navigating to product details: ${widget.product.id}');
        Navigator.pushNamed(context, AppRoutes.productDetail,
            arguments: widget.product.id);
      },
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          transform: Matrix4.identity()..scale(_isHovered ? 1.03 : 1.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade100,
                Colors.purple.shade100,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(_isHovered ? 0.6 : 0.4),
                spreadRadius: _isHovered ? 5 : 3,
                blurRadius: _isHovered ? 15 : 10,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: _isHovered ? AppColors.accent : Colors.grey.shade200,
              width: 2,
            ),
          ),
          child: Card(
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            color: Colors.transparent,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      child: AnimatedOpacity(
                        opacity: widget.product.stock > 0 ? 1.0 : 0.7,
                        duration: const Duration(milliseconds: 300),
                        child: Column(
                          children: [
                            CarouselSlider(
                              options: CarouselOptions(
                                height: 140,
                                autoPlay: imageUrls.length > 1,
                                autoPlayInterval: const Duration(seconds: 3),
                                autoPlayAnimationDuration:
                                    const Duration(milliseconds: 800),
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
                                    height: 140,
                                    memCacheHeight: 280,
                                    memCacheWidth: 400,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[200],
                                      height: 140,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation(
                                              AppColors.accent),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) {
                                      debugPrint(
                                          'Image load error for $url: $error');
                                      return Container(
                                        color: Colors.grey[200],
                                        height: 140,
                                        child: const Center(
                                          child: Icon(Icons.broken_image,
                                              color: Colors.grey, size: 40),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                            if (imageUrls.length > 1)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children:
                                      imageUrls.asMap().entries.map((entry) {
                                    return GestureDetector(
                                      onTap: () {
                                        // Empty onTap to absorb tap events, making dots non-interactive
                                        debugPrint(
                                            'Dot tapped for index ${entry.key}, no action taken');
                                      },
                                      child: Container(
                                        width: 8.0,
                                        height: 8.0,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 4.0),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.accent.withOpacity(
                                              _currentImageIndex == entry.key
                                                  ? 0.9
                                                  : 0.4),
                                        ),
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
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              fontFamily: 'Vazir',
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 8),
                          if (widget.product.description != null &&
                              widget.product.description!.isNotEmpty)
                            ExpansionTile(
                              title: const Text(
                                'توضیحات',
                                style: TextStyle(
                                  fontFamily: 'Vazir',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: Text(
                                    widget.product.description!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: widget.product.stock > 0
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade400,
                                      fontFamily: 'Vazir',
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              FaIcon(
                                FontAwesomeIcons.box,
                                size: 14,
                                color: widget.product.stock > 0
                                    ? Colors.green.shade600
                                    : Colors.red.shade600,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.product.stock > 0
                                    ? 'موجودی: ${widget.product.stock}'
                                    : 'ناموجود',
                                style: TextStyle(
                                  fontSize: 13,
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
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              FaIcon(
                                FontAwesomeIcons.tag,
                                size: 14,
                                color: widget.product.stock > 0
                                    ? AppColors.accent
                                    : Colors.grey.shade400,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'قیمت: ${widget.product.price.toStringAsFixed(0)} تومان',
                                style: TextStyle(
                                  fontSize: 13,
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
                          const SizedBox(height: 12),
                          if (widget.product.stock > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove,
                                          size: 20, color: AppColors.accent),
                                      onPressed: () {
                                        if (_quantity > 1) {
                                          setState(() {
                                            _quantity--;
                                          });
                                        }
                                      },
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: AppColors.accent, width: 1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$_quantity',
                                        style: const TextStyle(
                                          fontFamily: 'Vazir',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add,
                                          size: 20, color: AppColors.accent),
                                      onPressed: () {
                                        if (_quantity < widget.product.stock) {
                                          setState(() {
                                            _quantity++;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                AnimatedScale(
                                  scale: _isHovered && widget.product.stock > 0
                                      ? 1.1
                                      : 1.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: widget.product.stock > 0
                                          ? LinearGradient(
                                              colors: [
                                                AppColors.accent,
                                                AppColors.primary,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: widget.product.stock > 0
                                              ? AppColors.accent.withOpacity(
                                                  _isHovered ? 0.6 : 0.4)
                                              : Colors.grey.withOpacity(0.3),
                                          blurRadius: _isHovered ? 10 : 5,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: widget.product.stock > 0
                                          ? () {
                                              cartProvider.addItem(
                                                  widget.product, _quantity);
                                              ScaffoldMessenger.of(context)
                                                  .hideCurrentSnackBar();
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'محصول ${widget.product.name} به سبد خرید اضافه شد',
                                                    textDirection:
                                                        TextDirection.rtl,
                                                    style: const TextStyle(
                                                        fontFamily: 'Vazir'),
                                                  ),
                                                  backgroundColor:
                                                      AppColors.accent,
                                                  duration: const Duration(
                                                      seconds: 2),
                                                ),
                                              );
                                            }
                                          : null,
                                      icon: AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        child: FaIcon(
                                          widget.product.stock > 0
                                              ? FontAwesomeIcons.cartPlus
                                              : FontAwesomeIcons.ban,
                                          key: ValueKey(
                                              widget.product.stock > 0),
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      label: Text(
                                        widget.product.stock > 0
                                            ? 'ثبت سفارش'
                                            : 'ناموجود',
                                        style: const TextStyle(
                                          fontFamily: 'Vazir',
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 10),
                                        elevation: 0,
                                        shadowColor: Colors.transparent,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ناموجود',
                        style: TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textDirection: TextDirection.rtl,
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
