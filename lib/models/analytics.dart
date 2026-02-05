/// Analytics data models for driver performance tracking

class DriverAnalytics {
  final PerformanceMetrics performance;
  final List<DailyStats> dailyStats;
  final List<WeeklyTrend> weeklyTrends;
  final DeliveryBreakdown deliveryBreakdown;

  DriverAnalytics({
    required this.performance,
    required this.dailyStats,
    required this.weeklyTrends,
    required this.deliveryBreakdown,
  });
}

class PerformanceMetrics {
  final double onTimeRate;
  final double completionRate;
  final double averageRating;
  final int totalDeliveries;
  final int thisWeekDeliveries;
  final int thisMonthDeliveries;
  final double averageDeliveryTime; // in minutes
  final int totalDistanceMiles;

  PerformanceMetrics({
    required this.onTimeRate,
    required this.completionRate,
    required this.averageRating,
    required this.totalDeliveries,
    required this.thisWeekDeliveries,
    required this.thisMonthDeliveries,
    required this.averageDeliveryTime,
    required this.totalDistanceMiles,
  });

  String get onTimeRateFormatted => '${(onTimeRate * 100).toStringAsFixed(1)}%';
  String get completionRateFormatted => '${(completionRate * 100).toStringAsFixed(1)}%';
  String get ratingFormatted => averageRating.toStringAsFixed(1);
  String get avgDeliveryTimeFormatted => '${averageDeliveryTime.toStringAsFixed(0)} min';

  factory PerformanceMetrics.empty() {
    return PerformanceMetrics(
      onTimeRate: 0,
      completionRate: 0,
      averageRating: 0,
      totalDeliveries: 0,
      thisWeekDeliveries: 0,
      thisMonthDeliveries: 0,
      averageDeliveryTime: 0,
      totalDistanceMiles: 0,
    );
  }
}

class DailyStats {
  final DateTime date;
  final int deliveries;
  final double earnings;
  final int onTimeCount;
  final int totalCount;

  DailyStats({
    required this.date,
    required this.deliveries,
    required this.earnings,
    required this.onTimeCount,
    required this.totalCount,
  });

  double get onTimeRate => totalCount > 0 ? onTimeCount / totalCount : 0;
}

class WeeklyTrend {
  final int weekNumber;
  final DateTime startDate;
  final DateTime endDate;
  final int deliveries;
  final double earnings;
  final double onTimeRate;
  final double rating;

  WeeklyTrend({
    required this.weekNumber,
    required this.startDate,
    required this.endDate,
    required this.deliveries,
    required this.earnings,
    required this.onTimeRate,
    required this.rating,
  });

  String get weekLabel => 'Week $weekNumber';
}

class DeliveryBreakdown {
  final int completed;
  final int failed;
  final int cancelled;

  DeliveryBreakdown({
    required this.completed,
    required this.failed,
    required this.cancelled,
  });

  int get total => completed + failed + cancelled;

  double get completedPercent => total > 0 ? completed / total : 0;
  double get failedPercent => total > 0 ? failed / total : 0;
  double get cancelledPercent => total > 0 ? cancelled / total : 0;

  factory DeliveryBreakdown.empty() {
    return DeliveryBreakdown(completed: 0, failed: 0, cancelled: 0);
  }
}

/// Time period for analytics
enum AnalyticsPeriod {
  week('This Week'),
  month('This Month'),
  quarter('Last 3 Months'),
  year('This Year'),
  all('All Time');

  final String label;
  const AnalyticsPeriod(this.label);

  DateTime get startDate {
    final now = DateTime.now();
    switch (this) {
      case AnalyticsPeriod.week:
        return now.subtract(Duration(days: now.weekday - 1));
      case AnalyticsPeriod.month:
        return DateTime(now.year, now.month, 1);
      case AnalyticsPeriod.quarter:
        return now.subtract(const Duration(days: 90));
      case AnalyticsPeriod.year:
        return DateTime(now.year, 1, 1);
      case AnalyticsPeriod.all:
        return DateTime(2020, 1, 1);
    }
  }
}
