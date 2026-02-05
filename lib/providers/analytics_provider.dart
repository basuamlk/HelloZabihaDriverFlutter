import 'package:flutter/foundation.dart';
import '../models/analytics.dart';
import '../services/analytics_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsService _service = AnalyticsService.instance;

  DriverAnalytics? _analytics;
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.month;
  bool _isLoading = false;
  String? _errorMessage;

  DriverAnalytics? get analytics => _analytics;
  AnalyticsPeriod get selectedPeriod => _selectedPeriod;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  PerformanceMetrics get performance =>
      _analytics?.performance ?? PerformanceMetrics.empty();
  List<DailyStats> get dailyStats => _analytics?.dailyStats ?? [];
  List<WeeklyTrend> get weeklyTrends => _analytics?.weeklyTrends ?? [];
  DeliveryBreakdown get deliveryBreakdown =>
      _analytics?.deliveryBreakdown ?? DeliveryBreakdown.empty();

  Future<void> loadAnalytics(String driverId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _analytics = await _service.getDriverAnalytics(driverId, _selectedPeriod);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load analytics';
    }

    _isLoading = false;
    notifyListeners();
  }

  void setPeriod(AnalyticsPeriod period, String driverId) {
    if (_selectedPeriod == period) return;

    _selectedPeriod = period;
    loadAnalytics(driverId);
  }

  Future<void> refresh(String driverId) async {
    await loadAnalytics(driverId);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
