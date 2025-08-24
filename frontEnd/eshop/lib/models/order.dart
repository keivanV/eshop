enum OrderStatus { pending, processed, shipped, delivered, returned, cancelled }

class OrderItem {
  final String productId;
  final int quantity;

  OrderItem({required this.productId, required this.quantity});

  factory OrderItem.fromJson(Map<String, dynamic> json) {

    String productId;
    if (json['product'] is Map<String, dynamic>) {
      productId = json['product']['_id']?.toString() ?? '';
    } else {
      productId = json['product']?.toString() ?? '';
    }
    if (productId.isEmpty) {

    }
    return OrderItem(
      productId: productId,
      quantity: (json['quantity'] is num ? json['quantity'].toInt() : 0),
    );
  }

  Map<String, dynamic> toJson() => {'product': productId, 'quantity': quantity};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderItem &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          quantity == other.quantity;

  @override
  int get hashCode => productId.hashCode ^ quantity.hashCode;
}

class Order {
  final String id;
  final String userId;
  final List<OrderItem> products;
  final double totalAmount;
  final OrderStatus status;
  final bool returnRequest;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.userId,
    required this.products,
    required this.totalAmount,
    required this.status,
    required this.returnRequest,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
   
    if (json['_id'] == null) {

      throw Exception('داده سفارش نامعتبر است: ID یافت نشد');
    }
    return Order(
      id: json['_id'].toString(),
      userId: json['user'] is Map<String, dynamic>
          ? json['user']['_id']?.toString() ?? 'unknown'
          : json['user']?.toString() ?? 'unknown',
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount:
          (json['totalAmount'] is num ? json['totalAmount'].toDouble() : 0.0),
      status: OrderStatus.values.firstWhere(
          (e) => e.toString().split('.').last == json['status'],
          orElse: () => OrderStatus.pending),
      returnRequest: json['returnRequest'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Order &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          products.length == other.products.length &&
          products
              .asMap()
              .entries
              .every((entry) => entry.value == other.products[entry.key]) &&
          totalAmount == other.totalAmount &&
          status == other.status &&
          returnRequest == other.returnRequest &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      products.hashCode ^
      totalAmount.hashCode ^
      status.hashCode ^
      returnRequest.hashCode ^
      createdAt.hashCode;
}
