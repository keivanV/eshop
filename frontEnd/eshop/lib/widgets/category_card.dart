import 'package:flutter/material.dart';
import '../models/category.dart';
import '../constants.dart';

class CategoryCard extends StatelessWidget {
  final Category category;

  const CategoryCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: const Icon(Icons.category, color: AppColors.primary),
        title: Text(category.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(category.description ?? 'No description'),
      ),
    );
  }
}
