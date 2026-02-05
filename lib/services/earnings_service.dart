import '../models/delivery.dart';
import '../models/earning.dart';
import 'supabase_service.dart';
import 'auth_service.dart';

class EarningsService {
  static EarningsService? _instance;
  static EarningsService get instance => _instance ??= EarningsService._();

  EarningsService._();

  static const double defaultCommissionRate = 0.15; // 15%

  /// Calculate earnings from completed deliveries
  /// Since we don't have a separate earnings table yet, we calculate from deliveries
  Future<List<DeliveryEarning>> getEarningsFromDeliveries({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return [];

    try {
      var query = SupabaseService.client
          .from('deliveries')
          .select()
          .eq('driver_id', userId)
          .eq('status', 'completed');

      if (startDate != null) {
        query = query.gte('actual_delivery_time', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('actual_delivery_time', endDate.toIso8601String());
      }

      final response = await query.order('actual_delivery_time', ascending: false);

      return (response as List).map((json) {
        final delivery = Delivery.fromJson(json);
        return _calculateEarningFromDelivery(delivery, userId);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Calculate earning from a single delivery
  DeliveryEarning _calculateEarningFromDelivery(Delivery delivery, String driverId) {
    final commission = delivery.totalAmount * defaultCommissionRate;

    return DeliveryEarning(
      id: 'earning_${delivery.id}',
      deliveryId: delivery.id,
      driverId: driverId,
      orderAmount: delivery.totalAmount,
      commissionRate: defaultCommissionRate,
      commissionEarned: commission,
      tipAmount: null, // Tips would come from a separate field if implemented
      bonusAmount: null,
      bonusReason: null,
      totalEarned: commission,
      earnedAt: delivery.actualDeliveryTime ?? delivery.updatedAt,
      status: EarningStatus.pending,
    );
  }

  /// Get today's earnings
  Future<EarningsSummary> getTodayEarnings() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final earnings = await getEarningsFromDeliveries(
      startDate: startOfDay,
      endDate: endOfDay,
    );

    return EarningsSummary.fromDeliveries(earnings);
  }

  /// Get this week's earnings
  Future<EarningsSummary> getWeekEarnings() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    final earnings = await getEarningsFromDeliveries(startDate: startDate);

    return EarningsSummary.fromDeliveries(earnings);
  }

  /// Get this month's earnings
  Future<EarningsSummary> getMonthEarnings() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final earnings = await getEarningsFromDeliveries(startDate: startOfMonth);

    return EarningsSummary.fromDeliveries(earnings);
  }

  /// Get earnings for a custom date range
  Future<EarningsSummary> getEarningsForRange(DateTime start, DateTime end) async {
    final earnings = await getEarningsFromDeliveries(
      startDate: start,
      endDate: end,
    );

    return EarningsSummary.fromDeliveries(earnings);
  }

  /// Get daily earnings breakdown for a period
  Future<Map<DateTime, EarningsSummary>> getDailyBreakdown({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final earnings = await getEarningsFromDeliveries(
      startDate: startDate,
      endDate: endDate,
    );

    final Map<DateTime, List<DeliveryEarning>> dailyEarnings = {};

    for (final earning in earnings) {
      final date = DateTime(
        earning.earnedAt.year,
        earning.earnedAt.month,
        earning.earnedAt.day,
      );
      dailyEarnings.putIfAbsent(date, () => []).add(earning);
    }

    return dailyEarnings.map(
      (date, earningsList) => MapEntry(date, EarningsSummary.fromDeliveries(earningsList)),
    );
  }

  /// Get lifetime earnings summary
  Future<EarningsSummary> getLifetimeEarnings() async {
    final earnings = await getEarningsFromDeliveries();
    return EarningsSummary.fromDeliveries(earnings);
  }
}
