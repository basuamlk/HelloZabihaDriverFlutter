enum OfferStatus {
  pending,
  accepted,
  declined,
  expired;

  String get value {
    switch (this) {
      case OfferStatus.pending:
        return 'pending';
      case OfferStatus.accepted:
        return 'accepted';
      case OfferStatus.declined:
        return 'declined';
      case OfferStatus.expired:
        return 'expired';
    }
  }

  static OfferStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return OfferStatus.pending;
      case 'accepted':
        return OfferStatus.accepted;
      case 'declined':
        return OfferStatus.declined;
      case 'expired':
        return OfferStatus.expired;
      default:
        return OfferStatus.pending;
    }
  }
}

class DeliveryOffer {
  final String id;
  final String deliveryId;
  final String driverId;
  final OfferStatus status;
  final DateTime offeredAt;
  final DateTime expiresAt;
  final DateTime? respondedAt;
  final DateTime createdAt;

  DeliveryOffer({
    required this.id,
    required this.deliveryId,
    required this.driverId,
    required this.status,
    required this.offeredAt,
    required this.expiresAt,
    this.respondedAt,
    required this.createdAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get remainingTime {
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  factory DeliveryOffer.fromJson(Map<String, dynamic> json) {
    return DeliveryOffer(
      id: json['id'] as String,
      deliveryId: json['delivery_id'] as String,
      driverId: json['driver_id'] as String,
      status: OfferStatus.fromString(json['status'] as String),
      offeredAt: DateTime.parse(json['offered_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'delivery_id': deliveryId,
      'driver_id': driverId,
      'status': status.value,
      'offered_at': offeredAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  DeliveryOffer copyWith({
    String? id,
    String? deliveryId,
    String? driverId,
    OfferStatus? status,
    DateTime? offeredAt,
    DateTime? expiresAt,
    DateTime? respondedAt,
    DateTime? createdAt,
  }) {
    return DeliveryOffer(
      id: id ?? this.id,
      deliveryId: deliveryId ?? this.deliveryId,
      driverId: driverId ?? this.driverId,
      status: status ?? this.status,
      offeredAt: offeredAt ?? this.offeredAt,
      expiresAt: expiresAt ?? this.expiresAt,
      respondedAt: respondedAt ?? this.respondedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
