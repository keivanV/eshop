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
        constraints: const BoxConstraints(maxWidth: 140),
        child: FadeIn(
          duration: const Duration(milliseconds: 600),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isHovered ? 0.25 : 0.15),
                  spreadRadius: _isHovered ? 3 : 2,
                  blurRadius: _isHovered ? 10 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: _isHovered ? Colors.black : Colors.black87,
                width: _isHovered ? 2 : 1.5,
              ),
            ),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              color: Colors.transparent,
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                        child: AnimatedOpacity(
                          opacity: widget.product.stock > 0 ? 1.0 : 0.7,
                          duration: const Duration(milliseconds: 300),
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: CarouselSlider(
                                  options: CarouselOptions(
                                    height: 100,
                                    autoPlay: imageUrls.length > 1,
                                    autoPlayInterval:
                                        const Duration(seconds: 3),
                                    autoPlayAnimationDuration:
                                        const Duration(milliseconds: 800),
                                    autoPlayCurve: Curves.easeInOutCubic,
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
                                        height: 100,
                                        memCacheHeight: 200,
                                        memCacheWidth: 280,
                                        placeholder: (context, url) =>
                                            Container(
                                          color: Colors.grey[100],
                                          height: 100,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                      AppColors.accent),
                                              strokeWidth: 5,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) {
                                          debugPrint(
                                              'Image load error for $url: $error');
                                          return Container(
                                            color: Colors.grey[100],
                                            height: 100,
                                            child: const Center(
                                              child: FaIcon(
                                                FontAwesomeIcons.image,
                                                color: Colors.grey,
                                                size: 32,
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
                                      const EdgeInsets.symmetric(vertical: 6.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children:
                                        imageUrls.asMap().entries.map((entry) {
                                      return Container(
                                        width: 6.0,
                                        height: 6.0,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 3.0),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.accent.withOpacity(
                                              _currentImageIndex == entry.key
                                                  ? 0.9
                                                  : 0.4),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.accent
                                                  .withOpacity(0.3),
                                              blurRadius: 3,
                                              spreadRadius: 1,
                                            ),
                                          ],
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
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'Vazir',
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.rtl,
                            ),
                            const SizedBox(height: 6),
                            if (widget.product.description != null &&
                                widget.product.description!.isNotEmpty)
                              ExpansionTile(
                                title: Text(
                                  'توضیحات',
                                  style: TextStyle(
                                    fontFamily: 'Vazir',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: widget.product.stock > 0
                                        ? AppColors.primary
                                        : Colors.grey.shade500,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    child: Text(
                                      widget.product.description!,
                                      style: TextStyle(
                                        fontSize: 11,
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
                            const SizedBox(height: 6),
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
                                    fontSize: 12,
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
                                    fontSize: 12,
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
                            const SizedBox(height: 10),
                            if (widget.product.stock > 0)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: FaIcon(
                                          FontAwesomeIcons.minus,
                                          size: 16,
                                          color: AppColors.accent,
                                        ),
                                        onPressed: () {
                                          if (_quantity > 1) {
                                            setState(() {
                                              _quantity--;
                                            });
                                          }
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.black87, width: 1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          color: Colors.white,
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
                                      IconButton(
                                        icon: FaIcon(
                                          FontAwesomeIcons.plus,
                                          size: 16,
                                          color: AppColors.accent,
                                        ),
                                        onPressed: () {
                                          if (_quantity <
                                              widget.product.stock) {
                                            setState(() {
                                              _quantity++;
                                            });
                                          }
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                  Bounce(
                                    duration: const Duration(milliseconds: 600),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.accent,
                                            AppColors.primary,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: Colors.black87, width: 1),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.accent.withOpacity(
                                                _isHovered ? 0.5 : 0.3),
                                            blurRadius: _isHovered ? 10 : 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: () {
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
                                                  fontFamily: 'Vazir',
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              backgroundColor: AppColors.accent,
                                              duration:
                                                  const Duration(seconds: 2),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          );
                                        },
                                        icon: AnimatedSwitcher(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          child: FaIcon(
                                            FontAwesomeIcons.cartPlus,
                                            key: ValueKey(
                                                widget.product.stock > 0),
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                        label: const Text(
                                          'ثبت',
                                          style: TextStyle(
                                            fontFamily: 'Vazir',
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 8),
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
                      top: 10,
                      right: 10,
                      child: ZoomIn(
                        duration: const Duration(milliseconds: 600),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.black87, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 5,
                                spreadRadius: 1,
                              ),
                            ],
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
