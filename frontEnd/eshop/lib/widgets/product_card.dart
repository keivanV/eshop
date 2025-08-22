import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../routes/app_routes.dart';
import '../constants.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    debugPrint('Building ProductCard for ${product.id}');
    return GestureDetector(
      onTap: () {
        debugPrint('Navigating to product detail: ${product.id}');
        Navigator.pushNamed(context, AppRoutes.productDetail,
            arguments: product.id);
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(
                'https://placehold.co/200x150',
                fit: BoxFit.cover,
                width: double.infinity,
                height: 150,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  height: 150,
                  child: const Center(
                    child: Icon(Icons.error, color: Colors.red),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                product.name,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.rtl,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'قیمت: ${product.price.toStringAsFixed(0)} تومان',
                style: const TextStyle(fontSize: 14),
                textDirection: TextDirection.rtl,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'موجودی: ${product.stock}',
                style: const TextStyle(fontSize: 14),
                textDirection: TextDirection.rtl,
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: ElevatedButton(
                  onPressed: product.stock > 0
                      ? () {
                          debugPrint('Adding product ${product.id} to cart');
                          cartProvider.addItem(product, 1);
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'به سبد خرید اضافه شد',
                                textDirection: TextDirection.rtl,
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      : null,
                  child: const Text('افزودن به سبد خرید'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
