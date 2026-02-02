import 'package:flutter/foundation.dart';
import '../models/driver.dart';
import '../models/delivery.dart';
import '../services/driver_service.dart';
import '../services/delivery_service.dart';

class ProfileProvider extends ChangeNotifier {
  final DriverService _driverService = DriverService.instance;
  final DeliveryService _deliveryService = DeliveryService.instance;

  Driver? _driver;
  int _weeklyDeliveries = 0;
  int _monthlyDeliveries = 0;
  bool _isLoading = false;
  String? _errorMessage;

  Driver? get driver => _driver;
  int get weeklyDeliveries => _weeklyDeliveries;
  int get monthlyDeliveries => _monthlyDeliveries;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get driver profile from drivers table
      _driver = await _driverService.getCurrentDriver();

      if (_driver != null) {
        // Get deliveries for statistics
        final deliveries = await _deliveryService.getDriverDeliveries();

        // Calculate statistics
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final monthStart = DateTime(now.year, now.month, 1);

        final completedDeliveries = deliveries
            .where((d) => d.status == DeliveryStatus.completed)
            .toList();

        _weeklyDeliveries = completedDeliveries
            .where((d) =>
                d.actualDeliveryTime != null &&
                d.actualDeliveryTime!.isAfter(weekStart))
            .length;

        _monthlyDeliveries = completedDeliveries
            .where((d) =>
                d.actualDeliveryTime != null &&
                d.actualDeliveryTime!.isAfter(monthStart))
            .length;

        // Update total deliveries if different
        if (_driver!.totalDeliveries != completedDeliveries.length) {
          _driver = _driver!.copyWith(totalDeliveries: completedDeliveries.length);
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load profile';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? vehicleType,
    String? licensePlate,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updated = await _driverService.updateDriver(
        name: name,
        phone: phone,
        vehicleType: vehicleType,
        licensePlate: licensePlate,
      );

      if (updated != null) {
        _driver = updated;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update profile';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadProfile();
  }
}
