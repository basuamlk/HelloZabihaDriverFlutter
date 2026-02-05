import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/driver.dart';
import '../models/delivery.dart';
import '../services/driver_service.dart';
import '../services/delivery_service.dart';
import '../services/auth_service.dart';
import '../services/cache_service.dart';
import '../utils/error_handler.dart';

class ProfileProvider extends ChangeNotifier {
  final DriverService _driverService = DriverService.instance;
  final DeliveryService _deliveryService = DeliveryService.instance;
  final AuthService _authService = AuthService.instance;
  final CacheService _cacheService = CacheService.instance;

  Driver? _driver;
  int _weeklyDeliveries = 0;
  int _monthlyDeliveries = 0;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isFromCache = false;

  Driver? get driver => _driver;
  int get weeklyDeliveries => _weeklyDeliveries;
  int get monthlyDeliveries => _monthlyDeliveries;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isFromCache => _isFromCache;

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get driver profile from drivers table
      _driver = await _driverService.getCurrentDriver();

      // Create profile if it doesn't exist
      if (_driver == null) {
        final user = _authService.currentUser;
        if (user != null) {
          _driver = await _driverService.createDriverProfile(
            name: user.userMetadata?['name'] as String? ??
                user.email?.split('@').first ??
                'Driver',
            email: user.email ?? '',
          );
        }
      }

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

        // Cache driver for offline use
        await _cacheService.cacheDriver(_driver!);
      }

      _isFromCache = false;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Try to load from cache on network error
      final cachedDriver = await _cacheService.getCachedDriver();
      if (cachedDriver != null) {
        _driver = cachedDriver;
        _isFromCache = true;
        _errorMessage = null; // Clear error since we have cached data
      } else {
        _errorMessage = ErrorHandler.getUserMessage(e);
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update full driver profile with all fields
  Future<bool> updateFullProfile({
    String? name,
    String? phone,
    VehicleType? vehicleType,
    String? vehicleModel,
    String? licensePlate,
    int? vehicleYear,
    double? capacityCubicFeet,
    double? maxWeightLbs,
    int? maxDeliveriesPerRun,
    bool? hasRefrigeration,
    bool? hasCooler,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _driverService.updateDriver(
        name: name,
        phone: phone,
        vehicleType: vehicleType,
        vehicleModel: vehicleModel,
        licensePlate: licensePlate,
        vehicleYear: vehicleYear,
        capacityCubicFeet: capacityCubicFeet,
        maxWeightLbs: maxWeightLbs,
        maxDeliveriesPerRun: maxDeliveriesPerRun,
        hasRefrigeration: hasRefrigeration,
        hasCooler: hasCooler,
      );

      if (updated != null) {
        _driver = updated;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to update profile';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = ErrorHandler.getUserMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update personal info only
  Future<bool> updatePersonalInfo({
    String? name,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _driverService.updatePersonalInfo(
        name: name,
        phone: phone,
      );

      if (updated != null) {
        _driver = updated;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to update personal info';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = ErrorHandler.getUserMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update vehicle info only
  Future<bool> updateVehicleInfo({
    VehicleType? vehicleType,
    String? vehicleModel,
    String? licensePlate,
    int? vehicleYear,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _driverService.updateVehicleInfo(
        vehicleType: vehicleType,
        vehicleModel: vehicleModel,
        licensePlate: licensePlate,
        vehicleYear: vehicleYear,
      );

      if (updated != null) {
        _driver = updated;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to update vehicle info';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = ErrorHandler.getUserMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update capacity settings only
  Future<bool> updateCapacitySettings({
    double? capacityCubicFeet,
    double? maxWeightLbs,
    int? maxDeliveriesPerRun,
    bool? hasRefrigeration,
    bool? hasCooler,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _driverService.updateCapacitySettings(
        capacityCubicFeet: capacityCubicFeet,
        maxWeightLbs: maxWeightLbs,
        maxDeliveriesPerRun: maxDeliveriesPerRun,
        hasRefrigeration: hasRefrigeration,
        hasCooler: hasCooler,
      );

      if (updated != null) {
        _driver = updated;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to update capacity settings';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = ErrorHandler.getUserMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refresh() async {
    await loadProfile();
  }

  /// Upload profile photo
  Future<bool> uploadProfilePhoto(File photo) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final photoUrl = await _driverService.uploadProfilePhoto(photo);

      if (photoUrl != null && _driver != null) {
        _driver = _driver!.copyWith(profilePhotoUrl: photoUrl);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to upload photo. Make sure storage bucket exists.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = ErrorHandler.getUserMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete profile photo
  Future<bool> deleteProfilePhoto() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _driverService.deleteProfilePhoto();

      if (success && _driver != null) {
        _driver = _driver!.copyWith(profilePhotoUrl: null);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to delete photo';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = ErrorHandler.getUserMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
