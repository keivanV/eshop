import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../constants.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final product =
        productProvider.products.firstWhere((p) => p.id == productId);

    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network('https://placehold.co/300x200', fit: BoxFit.cover),
            const SizedBox(height: 16),
            Text(product.name,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Price: \$${product.price}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Stock: ${product.stock}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(product.description ?? 'No description',
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                cartProvider.addItem(product, 1);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to cart')));
              },
              child: const Text('Add to Cart'),
            ),
          ],
        ),
      ),
    );
  }
}
