import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
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
    final imageUrls =
        widget.product.imageUrls != null && widget.product.imageUrls!.isNotEmpty
            ? widget.product.imageUrls!
            : ['https://placehold.co/200x120'];

    debugPrint('Building ProductCard for ${widget.product.id}');
    return GestureDetector(
      onTap: () {
        debugPrint('Navigating to product detail: ${widget.product.id}');
        Navigator.pushNamed(context, AppRoutes.productDetail,
            arguments: widget.product.id);
      },
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 180), // عرض کوچکتر
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade50,
                Colors.purple.shade50,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(_isHovered ? 0.5 : 0.3),
                spreadRadius: _isHovered ? 4 : 2,
                blurRadius: _isHovered ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: _isHovered ? AppColors.accent : Colors.transparent,
              width: 2,
            ),
          ),
          child: Card(
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: AnimatedOpacity(
                    opacity: widget.product.stock > 0 ? 1.0 : 0.6,
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      children: [
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 120,
                            autoPlay: imageUrls.length > 1,
                            autoPlayInterval: const Duration(seconds: 3),
                            enlargeCenterPage: true,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                          ),
                          items: imageUrls.map((url) {
                            return Hero(
                              tag:
                                  'product-image-${widget.product.id}-${url.hashCode}',
                              child: Image.network(
                                url,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 120,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: Colors.grey[200],
                                  height: 120,
                                  child: const Center(
                                    child: Icon(Icons.broken_image,
                                        color: Colors.grey),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        if (imageUrls.length > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: imageUrls.asMap().entries.map((entry) {
                              return Container(
                                width: 8.0,
                                height: 8.0,
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 4.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : AppColors.accent)
                                      .withOpacity(
                                          _currentImageIndex == entry.key
                                              ? 0.9
                                              : 0.4),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          fontFamily: 'Vazir',
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
                                : Colors.red.shade400,
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
                                  : Colors.red.shade400,
                              fontFamily: 'Vazir',
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
                    ],
                  ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10, bottom: 10),
                    child: AnimatedScale(
                      scale: _isHovered && widget.product.stock > 0 ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: ElevatedButton.icon(
                        onPressed: widget.product.stock > 0
                            ? () {
                                debugPrint(
                                    'Adding product ${widget.product.id} to cart');
                                cartProvider.addItem(widget.product, 1);
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'به سبد خرید اضافه شد',
                                      textDirection: TextDirection.rtl,
                                      style: TextStyle(fontFamily: 'Vazir'),
                                    ),
                                    backgroundColor: AppColors.accent,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            : null,
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: FaIcon(
                            widget.product.stock > 0
                                ? FontAwesomeIcons.cartPlus
                                : FontAwesomeIcons.ban,
                            key: ValueKey(widget.product.stock > 0),
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        label: Text(
                          widget.product.stock > 0 ? 'ثبت سفارش' : 'ناموجود',
                          style: const TextStyle(
                            fontFamily: 'Vazir',
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.product.stock > 0
                              ? AppColors.accent
                              : Colors.grey.withOpacity(0.7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          elevation:
                              _isHovered && widget.product.stock > 0 ? 8 : 4,
                        ),
                      ),
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
