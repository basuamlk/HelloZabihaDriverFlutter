import 'package:flutter/material.dart';

enum DeliveryStatus {
  assigned,
  pickedUpFromFarm,
  enRoute,
  nearbyFifteenMin,
  completed,
  failed;

  String get value {
    switch (this) {
      case DeliveryStatus.assigned:
        return 'assigned';
      case DeliveryStatus.pickedUpFromFarm:
        return 'picked_up_from_farm';
      case DeliveryStatus.enRoute:
        return 'en_route';
      case DeliveryStatus.nearbyFifteenMin:
        return 'nearby_15_min';
      case DeliveryStatus.completed:
        return 'completed';
      case DeliveryStatus.failed:
        return 'failed';
    }
  }

  static DeliveryStatus fromString(String value) {
    switch (value) {
      case 'assigned':
        return DeliveryStatus.assigned;
      case 'picked_up_from_farm':
        return DeliveryStatus.pickedUpFromFarm;
      case 'en_route':
        return DeliveryStatus.enRoute;
      case 'nearby_15_min':
        return DeliveryStatus.nearbyFifteenMin;
      case 'completed':
        return DeliveryStatus.completed;
      case 'failed':
        return DeliveryStatus.failed;
      default:
        return DeliveryStatus.assigned;
    }
  }

  String get displayName {
    switch (this) {
      case DeliveryStatus.assigned:
        return 'Assigned';
      case DeliveryStatus.pickedUpFromFarm:
        return 'Picked Up';
      case DeliveryStatus.enRoute:
        return 'En Route';
      case DeliveryStatus.nearbyFifteenMin:
        return '15 Min Away';
      case DeliveryStatus.completed:
        return 'Completed';
      case DeliveryStatus.failed:
        return 'Failed';
    }
  }

  Color get color {
    switch (this) {
      case DeliveryStatus.assigned:
        return Colors.orange;
      case DeliveryStatus.pickedUpFromFarm:
        return Colors.blue;
      case DeliveryStatus.enRoute:
        return Colors.purple;
      case DeliveryStatus.nearbyFifteenMin:
        return Colors.indigo;
      case DeliveryStatus.completed:
        return Colors.green;
      case DeliveryStatus.failed:
        return Colors.red;
    }
  }

  String? get buttonTitle {
    switch (this) {
      case DeliveryStatus.assigned:
        return 'Picked Up from Farm';
      case DeliveryStatus.pickedUpFromFarm:
        return 'Start Delivery';
      case DeliveryStatus.enRoute:
        return '15 Minutes Away';
      case DeliveryStatus.nearbyFifteenMin:
        return 'Order Completed';
      case DeliveryStatus.completed:
      case DeliveryStatus.failed:
        return null;
    }
  }

  DeliveryStatus? get nextStatus {
    switch (this) {
      case DeliveryStatus.assigned:
        return DeliveryStatus.pickedUpFromFarm;
      case DeliveryStatus.pickedUpFromFarm:
        return DeliveryStatus.enRoute;
      case DeliveryStatus.enRoute:
        return DeliveryStatus.nearbyFifteenMin;
      case DeliveryStatus.nearbyFifteenMin:
        return DeliveryStatus.completed;
      case DeliveryStatus.completed:
      case DeliveryStatus.failed:
        return null;
    }
  }

  bool get isPending {
    return this != DeliveryStatus.completed && this != DeliveryStatus.failed;
  }

  bool get isActive {
    return this == DeliveryStatus.pickedUpFromFarm ||
        this == DeliveryStatus.enRoute ||
        this == DeliveryStatus.nearbyFifteenMin;
  }
}

class Delivery {
  final String id;
  final String orderId;
  final String driverId;
  final DeliveryStatus status;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String? deliveryNotes;
  final DateTime? estimatedDeliveryTime;
  final DateTime? actualDeliveryTime;
  final double totalAmount;
  final int itemCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Delivery({
    required this.id,
    required this.orderId,
    required this.driverId,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.deliveryNotes,
    this.estimatedDeliveryTime,
    this.actualDeliveryTime,
    required this.totalAmount,
    required this.itemCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      driverId: json['driver_id'] as String,
      status: DeliveryStatus.fromString(json['status'] as String),
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String,
      deliveryAddress: json['delivery_address'] as String,
      deliveryLatitude: (json['delivery_latitude'] as num?)?.toDouble(),
      deliveryLongitude: (json['delivery_longitude'] as num?)?.toDouble(),
      deliveryNotes: json['delivery_notes'] as String?,
      estimatedDeliveryTime: json['estimated_delivery_time'] != null
          ? DateTime.parse(json['estimated_delivery_time'] as String)
          : null,
      actualDeliveryTime: json['actual_delivery_time'] != null
          ? DateTime.parse(json['actual_delivery_time'] as String)
          : null,
      totalAmount: (json['total_amount'] as num).toDouble(),
      itemCount: json['item_count'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'driver_id': driverId,
      'status': status.value,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'delivery_address': deliveryAddress,
      'delivery_latitude': deliveryLatitude,
      'delivery_longitude': deliveryLongitude,
      'delivery_notes': deliveryNotes,
      'estimated_delivery_time': estimatedDeliveryTime?.toIso8601String(),
      'actual_delivery_time': actualDeliveryTime?.toIso8601String(),
      'total_amount': totalAmount,
      'item_count': itemCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Delivery copyWith({
    String? id,
    String? orderId,
    String? driverId,
    DeliveryStatus? status,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? deliveryNotes,
    DateTime? estimatedDeliveryTime,
    DateTime? actualDeliveryTime,
    double? totalAmount,
    int? itemCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Delivery(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      driverId: driverId ?? this.driverId,
      status: status ?? this.status,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      estimatedDeliveryTime:
          estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      actualDeliveryTime: actualDeliveryTime ?? this.actualDeliveryTime,
      totalAmount: totalAmount ?? this.totalAmount,
      itemCount: itemCount ?? this.itemCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Delivery && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
