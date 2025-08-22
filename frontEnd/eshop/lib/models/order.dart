enum OrderStatus { pending, processed, shipped, delivered, returned, cancelled }

class OrderItem {
  final String productId;
  final int quantity;

  OrderItem({required this.productId, required this.quantity});

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product']['_id'] ?? json['product'] ?? '',
      quantity: json['quantity'] ?? 0,
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
    return Order(
      id: json['_id'] ?? '',
      userId: json['user']['_id'] ?? json['user'] ?? '',
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: OrderStatus.values.firstWhere(
          (e) => e.toString().split('.').last == json['status'],
          orElse: () => OrderStatus.pending),
      returnRequest: json['returnRequest'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
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
