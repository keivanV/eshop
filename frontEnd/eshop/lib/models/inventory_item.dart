class InventoryItem {
  final String id;
  final String productId; // فقط ID محصول
  final int quantity;
  final DateTime lastUpdated;

  InventoryItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.lastUpdated,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    print('InventoryItem.fromJson input: $json'); // لاگ برای دیباگ
    return InventoryItem(
      id: json['_id']?.toString() ?? '',
      productId: json['product'] is Map
          ? json['product']['_id']?.toString() ?? ''
          : json['product']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'product': productId,
        'quantity': quantity,
        'lastUpdated': lastUpdated.toIso8601String(),
      };
}
