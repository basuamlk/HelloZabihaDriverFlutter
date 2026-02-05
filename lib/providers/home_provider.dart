import 'package:flutter/foundation.dart';
import '../models/delivery.dart';
import '../services/delivery_service.dart';
import '../services/driver_service.dart';
import '../services/location_service.dart';
import '../services/cache_service.dart';
import '../utils/error_handler.dart';

class HomeProvider extends ChangeNotifier {
  final DeliveryService _deliveryService = DeliveryService.instance;
  final DriverService _driverService = DriverService.instance;
  final LocationService _locationService = LocationService.instance;
  final CacheService _cacheService = CacheService.instance;

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
  bool _isFromCache = false;

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
  bool get isFromCache => _isFromCache;

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

        // Cache driver for offline use
        await _cacheService.cacheDriver(driver);

        // Sync location tracking with availability
        if (_isAvailable && !_locationService.isTracking) {
          _locationService.startTracking();
        }
      }

      // Get all deliveries
      final deliveries = await _deliveryService.getDriverDeliveries();

      // Process deliveries for statistics
      _processDeliveries(deliveries);

      _isFromCache = false;

      // Cache deliveries for offline use
      await _cacheService.cacheDeliveries(deliveries);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Try to load from cache on network error
      final cachedDeliveries = await _cacheService.getCachedDeliveries();
      final cachedDriver = await _cacheService.getCachedDriver();

      if (cachedDeliveries.isNotEmpty || cachedDriver != null) {
        _isFromCache = true;

        if (cachedDriver != null) {
          _driverName = cachedDriver.name;
          _isAvailable = cachedDriver.isAvailable;
          _rating = cachedDriver.rating ?? 0.0;
        }

        if (cachedDeliveries.isNotEmpty) {
          _processDeliveries(cachedDeliveries);
        }

        _errorMessage = null; // Clear error since we have cached data
      } else {
        _errorMessage = ErrorHandler.getUserMessage(e);
      }

      _isLoading = false;
      notifyListeners();
    }
  }

  void _processDeliveries(List<Delivery> deliveries) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final todayDeliveriesList = deliveries.where((d) =>
        d.status == DeliveryStatus.completed &&
        d.actualDeliveryTime != null &&
        d.actualDeliveryTime!.isAfter(todayStart));

    _todayDeliveries = todayDeliveriesList.length;
    _todayEarnings = todayDeliveriesList.fold(
        0.0, (sum, d) => sum + (d.totalAmount * 0.15));

    _activeDelivery = deliveries.cast<Delivery?>().firstWhere(
          (d) => d!.status.isActive,
          orElse: () => null,
        );

    _assignedDeliveries = deliveries
        .where((d) => d.status == DeliveryStatus.assigned)
        .toList();

    _pendingDeliveries = deliveries.where((d) => d.status.isPending).length;
    _recentDeliveries = deliveries.take(5).toList();
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
