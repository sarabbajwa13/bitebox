/// Order lifecycle status (agent app se match).
enum OrderStatus {
  pending,
  accepted,
  preparing,
  outForDelivery,
  delivered,
  rejected,
}

extension OrderStatusInfo on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.outForDelivery:
        return 'Out for delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.rejected:
        return 'Rejected';
    }
  }

  String get description {
    switch (this) {
      case OrderStatus.pending:
        return 'Waiting for the store to accept your order';
      case OrderStatus.accepted:
        return 'The store has accepted your order';
      case OrderStatus.preparing:
        return 'Your food is being prepared';
      case OrderStatus.outForDelivery:
        return 'Your order is on the way';
      case OrderStatus.delivered:
        return 'Order delivered — enjoy your meal!';
      case OrderStatus.rejected:
        return 'Sorry, the store could not accept this order';
    }
  }

  bool get isTerminal =>
      this == OrderStatus.delivered || this == OrderStatus.rejected;
  bool get isRejected => this == OrderStatus.rejected;
}

/// The linear pipeline for the progress tracker (rejected is a separate branch).
const List<OrderStatus> kOrderPipeline = [
  OrderStatus.pending,
  OrderStatus.accepted,
  OrderStatus.preparing,
  OrderStatus.outForDelivery,
  OrderStatus.delivered,
];

/// One line of an order (variant name + price + quantity).
class OrderLine {
  final String name;
  final double price;
  final int quantity;

  const OrderLine({
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get lineTotal => price * quantity;

  Map<String, dynamic> toMap() => {
    'name': name,
    'price': price,
    'quantity': quantity,
  };

  factory OrderLine.fromMap(Map<String, dynamic> map) => OrderLine(
    name: (map['name'] ?? map['variantName'] ?? '') as String,
    price: (map['price'] as num?)?.toDouble() ?? 0,
    quantity: (map['quantity'] as num?)?.toInt() ?? 1,
  );
}

/// A placed order (Firestore-backed).
class CustomerOrder {
  final String id;
  final String storeId;
  final String storeName;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final List<OrderLine> items;
  final double total;
  final DateTime createdAt;
  final OrderStatus status;
  final DateTime statusUpdatedAt;

  const CustomerOrder({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.total,
    required this.createdAt,
    this.status = OrderStatus.pending,
    required this.statusUpdatedAt,
  });

  int get totalQuantity => items.fold(0, (sum, e) => sum + e.quantity);

  Map<String, dynamic> toMap() => {
    'storeId': storeId,
    'storeName': storeName,
    'customerId': customerId,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'items': items.map((e) => e.toMap()).toList(),
    'total': total,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'statusUpdatedAt': statusUpdatedAt.toIso8601String(),
  };

  factory CustomerOrder.fromMap(String id, Map<String, dynamic> map) {
    return CustomerOrder(
      id: id,
      storeId: (map['storeId'] ?? '') as String,
      storeName: (map['storeName'] ?? '') as String,
      customerId: (map['customerId'] ?? '') as String,
      customerName: (map['customerName'] ?? '') as String,
      customerPhone: (map['customerPhone'] ?? '') as String,
      items: ((map['items'] as List<dynamic>?) ?? [])
          .map((e) => OrderLine.fromMap(e as Map<String, dynamic>))
          .toList(),
      total: (map['total'] as num?)?.toDouble() ?? 0,
      status: OrderStatus.values.firstWhere(
        (s) => s.name == (map['status'] ?? 'pending'),
        orElse: () => OrderStatus.pending,
      ),
      createdAt: _time(map['createdAt']) ?? DateTime.now(),
      statusUpdatedAt: _time(map['statusUpdatedAt']) ??
          _time(map['createdAt']) ??
          DateTime.now(),
    );
  }

  static DateTime? _time(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }
}
