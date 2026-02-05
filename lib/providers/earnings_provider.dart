import 'package:flutter/foundation.dart';
import '../models/earning.dart';
import '../services/earnings_service.dart';

enum EarningsPeriod { today, week, month, all }

class EarningsProvider extends ChangeNotifier {
  final EarningsService _earningsService = EarningsService.instance;

  bool _isLoading = false;
  String? _errorMessage;

  EarningsPeriod _selectedPeriod = EarningsPeriod.week;
  EarningsSummary? _currentSummary;
  List<DeliveryEarning> _earnings = [];
  Map<DateTime, EarningsSummary>? _dailyBreakdown;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  EarningsPeriod get selectedPeriod => _selectedPeriod;
  EarningsSummary? get currentSummary => _currentSummary;
  List<DeliveryEarning> get earnings => _earnings;
  Map<DateTime, EarningsSummary>? get dailyBreakdown => _dailyBreakdown;

  /// Load earnings for the selected period
  Future<void> loadEarnings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      switch (_selectedPeriod) {
        case EarningsPeriod.today:
          await _loadTodayEarnings();
          break;
        case EarningsPeriod.week:
          await _loadWeekEarnings();
          break;
        case EarningsPeriod.month:
          await _loadMonthEarnings();
          break;
        case EarningsPeriod.all:
          await _loadAllEarnings();
          break;
      }
    } catch (e) {
      _errorMessage = 'Failed to load earnings';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadTodayEarnings() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    _earnings = await _earningsService.getEarningsFromDeliveries(
      startDate: startOfDay,
      endDate: endOfDay,
    );
    _currentSummary = EarningsSummary.fromDeliveries(_earnings);
    _dailyBreakdown = null;
  }

  Future<void> _loadWeekEarnings() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endDate = now.add(const Duration(days: 1));

    _earnings = await _earningsService.getEarningsFromDeliveries(
      startDate: startDate,
      endDate: endDate,
    );
    _currentSummary = EarningsSummary.fromDeliveries(_earnings);
    _dailyBreakdown = await _earningsService.getDailyBreakdown(
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<void> _loadMonthEarnings() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endDate = now.add(const Duration(days: 1));

    _earnings = await _earningsService.getEarningsFromDeliveries(
      startDate: startOfMonth,
      endDate: endDate,
    );
    _currentSummary = EarningsSummary.fromDeliveries(_earnings);
    _dailyBreakdown = await _earningsService.getDailyBreakdown(
      startDate: startOfMonth,
      endDate: endDate,
    );
  }

  Future<void> _loadAllEarnings() async {
    _earnings = await _earningsService.getEarningsFromDeliveries();
    _currentSummary = EarningsSummary.fromDeliveries(_earnings);
    _dailyBreakdown = null;
  }

  /// Change the selected period and reload
  void selectPeriod(EarningsPeriod period) {
    if (_selectedPeriod != period) {
      _selectedPeriod = period;
      loadEarnings();
    }
  }

  /// Refresh earnings
  Future<void> refresh() async {
    await loadEarnings();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
