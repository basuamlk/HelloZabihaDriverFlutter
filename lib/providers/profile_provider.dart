import 'package:flutter/foundation.dart';
import '../models/driver.dart';
import '../models/delivery.dart';
import '../services/delivery_service.dart';
import '../services/auth_service.dart';

class ProfileProvider extends ChangeNotifier {
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
      final user = AuthService.instance.currentUser;
      if (user != null) {
        // Create driver from user data
        _driver = Driver(
          id: user.id,
          name: user.userMetadata?['name'] as String? ??
              user.email?.split('@').first ??
              'Driver',
          email: user.email ?? '',
          phone: user.userMetadata?['phone'] as String? ?? '',
          vehicleType: user.userMetadata?['vehicle_type'] as String?,
          licensePlate: user.userMetadata?['license_plate'] as String?,
          isAvailable: false,
          rating: (user.userMetadata?['rating'] as num?)?.toDouble(),
          totalDeliveries: 0,
          createdAt: DateTime.parse(user.createdAt),
          updatedAt: DateTime.now(),
        );

        // Get deliveries for statistics
        final deliveries = await _deliveryService.getDriverDeliveries();

        // Calculate statistics
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final monthStart = DateTime(now.year, now.month, 1);

        final completedDeliveries = deliveries
            .where((d) => d.status == DeliveryStatus.completed)
            .toList();

        _driver = _driver!.copyWith(totalDeliveries: completedDeliveries.length);

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
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load profile';
      _isLoading = false;
      _loadMockProfile();
      notifyListeners();
    }
  }

  void _loadMockProfile() {
    _driver = Driver(
      id: 'mock-id',
      name: 'Test Driver',
      email: 'test@example.com',
      phone: '555-1234',
      vehicleType: 'Van',
      licensePlate: 'ABC-1234',
      isAvailable: false,
      rating: 4.8,
      totalDeliveries: 150,
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      updatedAt: DateTime.now(),
    );
    _weeklyDeliveries = 12;
    _monthlyDeliveries = 45;
  }

  Future<void> refresh() async {
    await loadProfile();
  }
}
