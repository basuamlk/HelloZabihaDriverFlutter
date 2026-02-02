import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/driver.dart';
import 'supabase_service.dart';
import 'auth_service.dart';

class DriverService {
  static DriverService? _instance;
  static DriverService get instance => _instance ??= DriverService._();

  DriverService._();

  SupabaseClient get _client => SupabaseService.client;

  /// Get current driver's profile
  Future<Driver?> getCurrentDriver() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _client
          .from('drivers')
          .select()
          .eq('id', userId)
          .single();

      return Driver.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Create driver profile (called after sign up if trigger doesn't exist)
  Future<Driver?> createDriverProfile({
    required String name,
    required String email,
    String? phone,
  }) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _client
          .from('drivers')
          .insert({
            'id': userId,
            'name': name,
            'email': email,
            'phone': phone ?? '',
            'is_available': false,
            'total_deliveries': 0,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return Driver.fromJson(response);
    } catch (e) {
      // Profile might already exist (from trigger)
      return getCurrentDriver();
    }
  }

  /// Update driver profile
  Future<Driver?> updateDriver({
    String? name,
    String? phone,
    String? vehicleType,
    String? licensePlate,
    bool? isAvailable,
  }) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return null;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (vehicleType != null) updates['vehicle_type'] = vehicleType;
    if (licensePlate != null) updates['license_plate'] = licensePlate;
    if (isAvailable != null) updates['is_available'] = isAvailable;

    try {
      final response = await _client
          .from('drivers')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return Driver.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Update driver availability
  Future<void> setAvailability(bool isAvailable) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('drivers')
        .update({
          'is_available': isAvailable,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  /// Increment total deliveries count
  Future<void> incrementDeliveryCount() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;

    final driver = await getCurrentDriver();
    if (driver == null) return;

    await _client
        .from('drivers')
        .update({
          'total_deliveries': driver.totalDeliveries + 1,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }
}
