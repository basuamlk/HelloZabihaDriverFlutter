import 'package:flutter/material.dart';

enum DeliveryStatus {
  pending,
  offered,
  assigned,
  pickedUpFromFarm,
  enRoute,
  nearbyFifteenMin,
  completed,
  failed;

  String get value {
    switch (this) {
      case DeliveryStatus.pending:
        return 'pending';
      case DeliveryStatus.offered:
        return 'offered';
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
      case 'pending':
        return DeliveryStatus.pending;
      case 'offered':
        return DeliveryStatus.offered;
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
      case DeliveryStatus.pending:
        return 'Pending';
      case DeliveryStatus.offered:
        return 'Offer Pending';
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
      case DeliveryStatus.pending:
        return Colors.grey;
      case DeliveryStatus.offered:
        return Colors.amber;
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

  IconData get icon {
    switch (this) {
      case DeliveryStatus.pending:
        return Icons.hourglass_empty;
      case DeliveryStatus.offered:
        return Icons.notifications_active;
      case DeliveryStatus.assigned:
        return Icons.assignment;
      case DeliveryStatus.pickedUpFromFarm:
        return Icons.inventory;
      case DeliveryStatus.enRoute:
        return Icons.local_shipping;
      case DeliveryStatus.nearbyFifteenMin:
        return Icons.near_me;
      case DeliveryStatus.completed:
        return Icons.check_circle;
      case DeliveryStatus.failed:
        return Icons.cancel;
    }
  }

  String? get buttonTitle {
    switch (this) {
      case DeliveryStatus.pending:
      case DeliveryStatus.offered:
        return null;
      case DeliveryStatus.assigned:
        return 'Confirm Pickup';
      case DeliveryStatus.pickedUpFromFarm:
        return 'Start Delivery';
      case DeliveryStatus.enRoute:
        return 'Nearby (15 min)';
      case DeliveryStatus.nearbyFifteenMin:
        return 'Complete Delivery';
      case DeliveryStatus.completed:
      case DeliveryStatus.failed:
        return null;
    }
  }

  DeliveryStatus? get nextStatus {
    switch (this) {
      case DeliveryStatus.pending:
        return DeliveryStatus.offered;
      case DeliveryStatus.offered:
        return DeliveryStatus.assigned;
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

  /// Progress percentage for tracking UI (0.0 to 1.0)
  double get progressPercentage {
    switch (this) {
      case DeliveryStatus.pending:
        return 0.0;
      case DeliveryStatus.offered:
        return 0.05;
      case DeliveryStatus.assigned:
        return 0.1;
      case DeliveryStatus.pickedUpFromFarm:
        return 0.35;
      case DeliveryStatus.enRoute:
        return 0.6;
      case DeliveryStatus.nearbyFifteenMin:
        return 0.85;
      case DeliveryStatus.completed:
        return 1.0;
      case DeliveryStatus.failed:
        return 0.0;
    }
  }

  /// Step index for progress indicator (0-based)
  int get stepIndex {
    switch (this) {
      case DeliveryStatus.pending:
      case DeliveryStatus.offered:
      case DeliveryStatus.assigned:
        return 0;
      case DeliveryStatus.pickedUpFromFarm:
        return 1;
      case DeliveryStatus.enRoute:
      case DeliveryStatus.nearbyFifteenMin:
        return 2;
      case DeliveryStatus.completed:
        return 3;
      case DeliveryStatus.failed:
        return -1;
    }
  }
}

class Delivery {
  final String id;
  final String orderId;
  final String? driverId;
  final DeliveryStatus status;

  // Customer info
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String? deliveryNotes;

  // Pickup location (farm/warehouse)
  final String? pickupAddress;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String? pickupNotes;

  // Timing
  final DateTime? scheduledPickupTime;
  final DateTime? estimatedDeliveryTime;
  final DateTime? actualPickupTime;
  final DateTime? actualDeliveryTime;
  final int? estimatedMinutes; // ETA in minutes

  // Confirmation data
  final String? pickupPhotoUrl;
  final String? deliveryPhotoUrl;
  final String? signatureUrl;
  final String? deliveryRecipientName;

  // Order details
  final double totalAmount;
  final int itemCount;
  final bool requiresRefrigeration;
  final bool requiresSignature;
  final String? specialInstructions;

  // Offer tracking
  final String? offeredDriverId;
  final DateTime? offerExpiresAt;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  Delivery({
    required this.id,
    required this.orderId,
    this.driverId,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.deliveryNotes,
    this.pickupAddress,
    this.pickupLatitude,
    this.pickupLongitude,
    this.pickupNotes,
    this.scheduledPickupTime,
    this.estimatedDeliveryTime,
    this.actualPickupTime,
    this.actualDeliveryTime,
    this.estimatedMinutes,
    this.pickupPhotoUrl,
    this.deliveryPhotoUrl,
    this.signatureUrl,
    this.deliveryRecipientName,
    required this.totalAmount,
    required this.itemCount,
    this.requiresRefrigeration = false,
    this.requiresSignature = false,
    this.specialInstructions,
    this.offeredDriverId,
    this.offerExpiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if pickup has been confirmed
  bool get isPickupConfirmed => actualPickupTime != null;

  /// Check if delivery has been confirmed
  bool get isDeliveryConfirmed => actualDeliveryTime != null;

  /// Get formatted ETA string
  String? get etaDisplay {
    if (estimatedMinutes == null) return null;
    if (estimatedMinutes! < 60) {
      return '${estimatedMinutes} min';
    } else {
      final hours = estimatedMinutes! ~/ 60;
      final mins = estimatedMinutes! % 60;
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
  }

  /// Check if delivery requires photo proof
  bool get requiresPhotoProof => true; // Always require for meat delivery

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      driverId: json['driver_id'] as String?,
      status: DeliveryStatus.fromString(json['status'] as String),
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String,
      deliveryAddress: json['delivery_address'] as String,
      deliveryLatitude: (json['delivery_latitude'] as num?)?.toDouble(),
      deliveryLongitude: (json['delivery_longitude'] as num?)?.toDouble(),
      deliveryNotes: json['delivery_notes'] as String?,
      pickupAddress: json['pickup_address'] as String?,
      pickupLatitude: (json['pickup_latitude'] as num?)?.toDouble(),
      pickupLongitude: (json['pickup_longitude'] as num?)?.toDouble(),
      pickupNotes: json['pickup_notes'] as String?,
      scheduledPickupTime: json['scheduled_pickup_time'] != null
          ? DateTime.parse(json['scheduled_pickup_time'] as String)
          : null,
      estimatedDeliveryTime: json['estimated_delivery_time'] != null
          ? DateTime.parse(json['estimated_delivery_time'] as String)
          : null,
      actualPickupTime: json['actual_pickup_time'] != null
          ? DateTime.parse(json['actual_pickup_time'] as String)
          : null,
      actualDeliveryTime: json['actual_delivery_time'] != null
          ? DateTime.parse(json['actual_delivery_time'] as String)
          : null,
      estimatedMinutes: json['estimated_minutes'] as int?,
      pickupPhotoUrl: json['pickup_photo_url'] as String?,
      deliveryPhotoUrl: json['delivery_photo_url'] as String?,
      signatureUrl: json['signature_url'] as String?,
      deliveryRecipientName: json['delivery_recipient_name'] as String?,
      totalAmount: (json['total_amount'] as num).toDouble(),
      itemCount: json['item_count'] as int,
      requiresRefrigeration: json['requires_refrigeration'] as bool? ?? false,
      requiresSignature: json['requires_signature'] as bool? ?? false,
      specialInstructions: json['special_instructions'] as String?,
      offeredDriverId: json['offered_driver_id'] as String?,
      offerExpiresAt: json['offer_expires_at'] != null
          ? DateTime.parse(json['offer_expires_at'] as String)
          : null,
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
      'pickup_address': pickupAddress,
      'pickup_latitude': pickupLatitude,
      'pickup_longitude': pickupLongitude,
      'pickup_notes': pickupNotes,
      'scheduled_pickup_time': scheduledPickupTime?.toIso8601String(),
      'estimated_delivery_time': estimatedDeliveryTime?.toIso8601String(),
      'actual_pickup_time': actualPickupTime?.toIso8601String(),
      'actual_delivery_time': actualDeliveryTime?.toIso8601String(),
      'estimated_minutes': estimatedMinutes,
      'pickup_photo_url': pickupPhotoUrl,
      'delivery_photo_url': deliveryPhotoUrl,
      'signature_url': signatureUrl,
      'delivery_recipient_name': deliveryRecipientName,
      'total_amount': totalAmount,
      'item_count': itemCount,
      'requires_refrigeration': requiresRefrigeration,
      'requires_signature': requiresSignature,
      'special_instructions': specialInstructions,
      'offered_driver_id': offeredDriverId,
      'offer_expires_at': offerExpiresAt?.toIso8601String(),
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
    String? pickupAddress,
    double? pickupLatitude,
    double? pickupLongitude,
    String? pickupNotes,
    DateTime? scheduledPickupTime,
    DateTime? estimatedDeliveryTime,
    DateTime? actualPickupTime,
    DateTime? actualDeliveryTime,
    int? estimatedMinutes,
    String? pickupPhotoUrl,
    String? deliveryPhotoUrl,
    String? signatureUrl,
    String? deliveryRecipientName,
    double? totalAmount,
    int? itemCount,
    bool? requiresRefrigeration,
    bool? requiresSignature,
    String? specialInstructions,
    String? offeredDriverId,
    DateTime? offerExpiresAt,
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
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      pickupNotes: pickupNotes ?? this.pickupNotes,
      scheduledPickupTime: scheduledPickupTime ?? this.scheduledPickupTime,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      actualPickupTime: actualPickupTime ?? this.actualPickupTime,
      actualDeliveryTime: actualDeliveryTime ?? this.actualDeliveryTime,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      pickupPhotoUrl: pickupPhotoUrl ?? this.pickupPhotoUrl,
      deliveryPhotoUrl: deliveryPhotoUrl ?? this.deliveryPhotoUrl,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      deliveryRecipientName: deliveryRecipientName ?? this.deliveryRecipientName,
      totalAmount: totalAmount ?? this.totalAmount,
      itemCount: itemCount ?? this.itemCount,
      requiresRefrigeration: requiresRefrigeration ?? this.requiresRefrigeration,
      requiresSignature: requiresSignature ?? this.requiresSignature,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      offeredDriverId: offeredDriverId ?? this.offeredDriverId,
      offerExpiresAt: offerExpiresAt ?? this.offerExpiresAt,
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
