class OrderRecord {
  final String id;
  final String userId;
  final double totalAmount;
  final String paymentStatus;
  final DateTime createdAt;
  final List<OrderItemRecord> items;

  const OrderRecord({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.paymentStatus,
    required this.createdAt,
    required this.items,
  });

  factory OrderRecord.fromMap(Map<String, dynamic> map) {
    final itemRows = map['items'];
    if (itemRows is! List) {
      throw const FormatException('Order items are missing from the response.');
    }

    return OrderRecord(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      totalAmount: _numberFrom(map['total_amount']),
      paymentStatus: map['payment_status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      items: itemRows
          .map(
            (row) => OrderItemRecord.fromMap(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList(),
    );
  }
}

class OrderItemRecord {
  final String? productId;
  final String productName;
  final String? productCategory;
  final double unitPrice;
  final int quantity;
  final double subtotal;

  const OrderItemRecord({
    required this.productId,
    required this.productName,
    required this.productCategory,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItemRecord.fromMap(Map<String, dynamic> map) {
    return OrderItemRecord(
      productId: map['product_id'] as String?,
      productName: map['product_name'] as String,
      productCategory: map['product_category'] as String?,
      unitPrice: _numberFrom(map['unit_price']),
      quantity: (map['quantity'] as num).toInt(),
      subtotal: _numberFrom(map['subtotal']),
    );
  }
}

double _numberFrom(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.parse(value);
  throw const FormatException('An order amount is invalid.');
}
