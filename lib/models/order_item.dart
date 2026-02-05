/// Represents a single item in a delivery order
class OrderItem {
  final String id;
  final String orderId;
  final String productName;
  final String? productDescription;
  final String? category; // e.g., "Chicken", "Beef", "Lamb"
  final int quantity;
  final String unit; // e.g., "lb", "kg", "piece"
  final double unitPrice;
  final double totalPrice;
  final String? notes; // Special prep instructions
  final bool requiresRefrigeration;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productName,
    this.productDescription,
    this.category,
    required this.quantity,
    this.unit = 'piece',
    required this.unitPrice,
    required this.totalPrice,
    this.notes,
    this.requiresRefrigeration = true,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productName: json['product_name'] as String,
      productDescription: json['product_description'] as String?,
      category: json['category'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      unit: json['unit'] as String? ?? 'piece',
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      requiresRefrigeration: json['requires_refrigeration'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_name': productName,
      'product_description': productDescription,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'notes': notes,
      'requires_refrigeration': requiresRefrigeration,
    };
  }

  /// Formatted quantity string (e.g., "2 lbs", "3 pieces")
  String get formattedQuantity {
    if (unit == 'piece') {
      return quantity == 1 ? '1 piece' : '$quantity pieces';
    }
    return '$quantity $unit';
  }

  /// Formatted price string
  String get formattedPrice => '\$${totalPrice.toStringAsFixed(2)}';
  String get formattedUnitPrice => '\$${unitPrice.toStringAsFixed(2)}/$unit';
}
