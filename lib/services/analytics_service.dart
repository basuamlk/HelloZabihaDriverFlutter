import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/analytics.dart';
import '../models/delivery.dart';

class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._internal();
  AnalyticsService._internal();

  SupabaseClient get _supabase => Supabase.instance.client;

  /// Get comprehensive analytics for a driver
  Future<DriverAnalytics> getDriverAnalytics(
    String driverId,
    AnalyticsPeriod period,
  ) async {
    final deliveries = await _getDeliveriesForPeriod(driverId, period);

    return DriverAnalytics(
      performance: _calculatePerformanceMetrics(deliveries),
      dailyStats: _calculateDailyStats(deliveries),
      weeklyTrends: _calculateWeeklyTrends(deliveries),
      deliveryBreakdown: _calculateDeliveryBreakdown(deliveries),
    );
  }

  Future<List<Delivery>> _getDeliveriesForPeriod(
    String driverId,
    AnalyticsPeriod period,
  ) async {
    try {
      final response = await _supabase
          .from('deliveries')
          .select()
          .eq('driver_id', driverId)
          .gte('created_at', period.startDate.toIso8601String())
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Delivery.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  PerformanceMetrics _calculatePerformanceMetrics(List<Delivery> deliveries) {
    if (deliveries.isEmpty) {
      return PerformanceMetrics.empty();
    }

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    final completed = deliveries.where((d) => d.status == DeliveryStatus.completed).toList();
    final failed = deliveries.where((d) => d.status == DeliveryStatus.failed).toList();

    // Calculate on-time rate (deliveries completed within estimated time)
    int onTimeCount = 0;
    double totalDeliveryTime = 0;

    for (final delivery in completed) {
      if (delivery.actualDeliveryTime != null && delivery.actualPickupTime != null) {
        final deliveryTime = delivery.actualDeliveryTime!.difference(delivery.actualPickupTime!).inMinutes;
        totalDeliveryTime += deliveryTime;

        // Consider on-time if delivered within estimated minutes + 15 min buffer
        final estimatedMinutes = delivery.estimatedMinutes ?? 60;
        if (deliveryTime <= estimatedMinutes + 15) {
          onTimeCount++;
        }
      }
    }

    // Calculate weekly/monthly counts
    final thisWeek = deliveries.where((d) =>
      d.createdAt.isAfter(weekStart) && d.status == DeliveryStatus.completed
    ).length;

    final thisMonth = deliveries.where((d) =>
      d.createdAt.isAfter(monthStart) && d.status == DeliveryStatus.completed
    ).length;

    return PerformanceMetrics(
      onTimeRate: completed.isNotEmpty ? onTimeCount / completed.length : 0,
      completionRate: deliveries.isNotEmpty
          ? completed.length / (completed.length + failed.length)
          : 0,
      averageRating: 4.8, // TODO: Calculate from actual ratings
      totalDeliveries: completed.length,
      thisWeekDeliveries: thisWeek,
      thisMonthDeliveries: thisMonth,
      averageDeliveryTime: completed.isNotEmpty
          ? totalDeliveryTime / completed.length
          : 0,
      totalDistanceMiles: _estimateTotalDistance(completed),
    );
  }

  int _estimateTotalDistance(List<Delivery> deliveries) {
    // Rough estimate: 5 miles per delivery on average
    return deliveries.length * 5;
  }

  List<DailyStats> _calculateDailyStats(List<Delivery> deliveries) {
    final Map<String, DailyStats> statsMap = {};

    for (final delivery in deliveries) {
      final dateKey = _dateKey(delivery.createdAt);

      if (!statsMap.containsKey(dateKey)) {
        statsMap[dateKey] = DailyStats(
          date: DateTime(delivery.createdAt.year, delivery.createdAt.month, delivery.createdAt.day),
          deliveries: 0,
          earnings: 0,
          onTimeCount: 0,
          totalCount: 0,
        );
      }

      final current = statsMap[dateKey]!;
      final isCompleted = delivery.status == DeliveryStatus.completed;
      final isOnTime = _isOnTime(delivery);

      statsMap[dateKey] = DailyStats(
        date: current.date,
        deliveries: current.deliveries + (isCompleted ? 1 : 0),
        earnings: current.earnings + (isCompleted ? delivery.totalAmount * 0.15 : 0),
        onTimeCount: current.onTimeCount + (isOnTime ? 1 : 0),
        totalCount: current.totalCount + (isCompleted ? 1 : 0),
      );
    }

    final stats = statsMap.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Return last 14 days
    return stats.length > 14 ? stats.sublist(stats.length - 14) : stats;
  }

  List<WeeklyTrend> _calculateWeeklyTrends(List<Delivery> deliveries) {
    final Map<int, List<Delivery>> weekMap = {};

    for (final delivery in deliveries) {
      final weekNum = _weekNumber(delivery.createdAt);
      weekMap.putIfAbsent(weekNum, () => []).add(delivery);
    }

    final trends = <WeeklyTrend>[];

    for (final entry in weekMap.entries) {
      final weekDeliveries = entry.value;
      final completed = weekDeliveries.where((d) => d.status == DeliveryStatus.completed).toList();
      final onTimeCount = completed.where(_isOnTime).length;

      if (weekDeliveries.isNotEmpty) {
        final firstDate = weekDeliveries.map((d) => d.createdAt).reduce((a, b) => a.isBefore(b) ? a : b);

        trends.add(WeeklyTrend(
          weekNumber: entry.key,
          startDate: firstDate,
          endDate: firstDate.add(const Duration(days: 6)),
          deliveries: completed.length,
          earnings: completed.fold(0.0, (sum, d) => sum + d.totalAmount * 0.15),
          onTimeRate: completed.isNotEmpty ? onTimeCount / completed.length : 0,
          rating: 4.8, // TODO: Calculate from actual ratings
        ));
      }
    }

    trends.sort((a, b) => a.weekNumber.compareTo(b.weekNumber));
    return trends.length > 8 ? trends.sublist(trends.length - 8) : trends;
  }

  DeliveryBreakdown _calculateDeliveryBreakdown(List<Delivery> deliveries) {
    return DeliveryBreakdown(
      completed: deliveries.where((d) => d.status == DeliveryStatus.completed).length,
      failed: deliveries.where((d) => d.status == DeliveryStatus.failed).length,
      cancelled: 0, // No cancelled status in current model
    );
  }

  bool _isOnTime(Delivery delivery) {
    if (delivery.actualDeliveryTime == null || delivery.actualPickupTime == null) return true;
    final deliveryTime = delivery.actualDeliveryTime!.difference(delivery.actualPickupTime!).inMinutes;
    final estimatedMinutes = delivery.estimatedMinutes ?? 60;
    return deliveryTime <= estimatedMinutes + 15;
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  int _weekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final diff = date.difference(startOfYear);
    return (diff.inDays / 7).ceil();
  }
}
