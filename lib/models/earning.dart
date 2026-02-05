/// Represents earnings from a single delivery
class DeliveryEarning {
  final String id;
  final String deliveryId;
  final String driverId;
  final double orderAmount;
  final double commissionRate; // e.g., 0.15 for 15%
  final double commissionEarned;
  final double? tipAmount;
  final double? bonusAmount;
  final String? bonusReason;
  final double totalEarned;
  final DateTime earnedAt;
  final EarningStatus status;

  DeliveryEarning({
    required this.id,
    required this.deliveryId,
    required this.driverId,
    required this.orderAmount,
    required this.commissionRate,
    required this.commissionEarned,
    this.tipAmount,
    this.bonusAmount,
    this.bonusReason,
    required this.totalEarned,
    required this.earnedAt,
    this.status = EarningStatus.pending,
  });

  factory DeliveryEarning.fromJson(Map<String, dynamic> json) {
    return DeliveryEarning(
      id: json['id'] as String,
      deliveryId: json['delivery_id'] as String,
      driverId: json['driver_id'] as String,
      orderAmount: (json['order_amount'] as num).toDouble(),
      commissionRate: (json['commission_rate'] as num?)?.toDouble() ?? 0.15,
      commissionEarned: (json['commission_earned'] as num).toDouble(),
      tipAmount: (json['tip_amount'] as num?)?.toDouble(),
      bonusAmount: (json['bonus_amount'] as num?)?.toDouble(),
      bonusReason: json['bonus_reason'] as String?,
      totalEarned: (json['total_earned'] as num).toDouble(),
      earnedAt: DateTime.parse(json['earned_at'] as String),
      status: EarningStatus.fromString(json['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'delivery_id': deliveryId,
      'driver_id': driverId,
      'order_amount': orderAmount,
      'commission_rate': commissionRate,
      'commission_earned': commissionEarned,
      'tip_amount': tipAmount,
      'bonus_amount': bonusAmount,
      'bonus_reason': bonusReason,
      'total_earned': totalEarned,
      'earned_at': earnedAt.toIso8601String(),
      'status': status.value,
    };
  }

  /// Calculate earnings from a delivery (utility method)
  static DeliveryEarning calculate({
    required String deliveryId,
    required String driverId,
    required double orderAmount,
    double commissionRate = 0.15,
    double? tipAmount,
    double? bonusAmount,
    String? bonusReason,
  }) {
    final commission = orderAmount * commissionRate;
    final total = commission + (tipAmount ?? 0) + (bonusAmount ?? 0);

    return DeliveryEarning(
      id: '', // Will be assigned by database
      deliveryId: deliveryId,
      driverId: driverId,
      orderAmount: orderAmount,
      commissionRate: commissionRate,
      commissionEarned: commission,
      tipAmount: tipAmount,
      bonusAmount: bonusAmount,
      bonusReason: bonusReason,
      totalEarned: total,
      earnedAt: DateTime.now(),
      status: EarningStatus.pending,
    );
  }
}

enum EarningStatus {
  pending,
  processed,
  paid;

  String get value {
    switch (this) {
      case EarningStatus.pending:
        return 'pending';
      case EarningStatus.processed:
        return 'processed';
      case EarningStatus.paid:
        return 'paid';
    }
  }

  String get displayName {
    switch (this) {
      case EarningStatus.pending:
        return 'Pending';
      case EarningStatus.processed:
        return 'Processed';
      case EarningStatus.paid:
        return 'Paid';
    }
  }

  static EarningStatus fromString(String? value) {
    switch (value) {
      case 'processed':
        return EarningStatus.processed;
      case 'paid':
        return EarningStatus.paid;
      default:
        return EarningStatus.pending;
    }
  }
}

/// Summary of earnings for a time period
class EarningsSummary {
  final double totalEarnings;
  final double totalCommission;
  final double totalTips;
  final double totalBonuses;
  final int deliveryCount;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  EarningsSummary({
    required this.totalEarnings,
    required this.totalCommission,
    required this.totalTips,
    required this.totalBonuses,
    required this.deliveryCount,
    this.periodStart,
    this.periodEnd,
  });

  factory EarningsSummary.fromDeliveries(List<DeliveryEarning> earnings) {
    double totalEarnings = 0;
    double totalCommission = 0;
    double totalTips = 0;
    double totalBonuses = 0;

    for (final earning in earnings) {
      totalEarnings += earning.totalEarned;
      totalCommission += earning.commissionEarned;
      totalTips += earning.tipAmount ?? 0;
      totalBonuses += earning.bonusAmount ?? 0;
    }

    return EarningsSummary(
      totalEarnings: totalEarnings,
      totalCommission: totalCommission,
      totalTips: totalTips,
      totalBonuses: totalBonuses,
      deliveryCount: earnings.length,
    );
  }

  /// Average earnings per delivery
  double get averagePerDelivery =>
      deliveryCount > 0 ? totalEarnings / deliveryCount : 0;

  /// Formatted total
  String get formattedTotal => '\$${totalEarnings.toStringAsFixed(2)}';
}
