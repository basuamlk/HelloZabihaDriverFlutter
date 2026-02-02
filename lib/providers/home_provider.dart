import 'package:flutter/foundation.dart';
import '../models/delivery.dart';
import '../services/delivery_service.dart';
import '../services/driver_service.dart';
import '../services/location_service.dart';

class HomeProvider extends ChangeNotifier {
  final DeliveryService _deliveryService = DeliveryService.instance;
  final DriverService _driverService = DriverService.instance;
  final LocationService _locationService = LocationService.instance;

  String _driverName = 'Driver';
  bool _isAvailable = false;
  int _todayDeliveries = 0;
  int _pendingDeliveries = 0;
  double _todayEarnings = 0.0;
  double _rating = 0.0;
  Delivery? _activeDelivery;
  List<Delivery> _recentDeliveries = [];
  List<Delivery> _assignedDeliveries = [];
  bool _isLoading = false;
  String? _errorMessage;

  String get driverName => _driverName;
  bool get isAvailable => _isAvailable;
  int get todayDeliveries => _todayDeliveries;
  int get pendingDeliveries => _pendingDeliveries;
  double get todayEarnings => _todayEarnings;
  double get rating => _rating;
  Delivery? get activeDelivery => _activeDelivery;
  List<Delivery> get recentDeliveries => _recentDeliveries;
  List<Delivery> get assignedDeliveries => _assignedDeliveries;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isTracking => _locationService.isTracking;

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get driver profile from database
      final driver = await _driverService.getCurrentDriver();
      if (driver != null) {
        _driverName = driver.name;
        _isAvailable = driver.isAvailable;
        _rating = driver.rating ?? 0.0;

        // Sync location tracking with availability
        if (_isAvailable && !_locationService.isTracking) {
          _locationService.startTracking();
        }
      }

      // Get all deliveries
      final deliveries = await _deliveryService.getDriverDeliveries();

      // Calculate statistics
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      final todayDeliveriesList = deliveries.where((d) =>
          d.status == DeliveryStatus.completed &&
          d.actualDeliveryTime != null &&
          d.actualDeliveryTime!.isAfter(todayStart));

      _todayDeliveries = todayDeliveriesList.length;
      _todayEarnings = todayDeliveriesList.fold(
          0.0, (sum, d) => sum + (d.totalAmount * 0.15));

      // Find active delivery (in progress)
      _activeDelivery = deliveries.cast<Delivery?>().firstWhere(
            (d) => d!.status.isActive,
            orElse: () => null,
          );

      // Get assigned deliveries (not started yet)
      _assignedDeliveries = deliveries
          .where((d) => d.status == DeliveryStatus.assigned)
          .toList();

      _pendingDeliveries = deliveries.where((d) => d.status.isPending).length;

      // Get recent deliveries (last 5)
      _recentDeliveries = deliveries.take(5).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load data';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadData();
  }

  Future<void> toggleAvailability() async {
    _isAvailable = !_isAvailable;
    notifyListeners();

    // Update in database
    await _driverService.setAvailability(_isAvailable);

    // Control location tracking
    if (_isAvailable) {
      _locationService.startTracking();
    } else {
      _locationService.stopTracking();
    }

    notifyListeners();
  }

  Future<void> requestLocationPermission() async {
    await _locationService.requestPermission();
    notifyListeners();
  }
}
