import 'dart:io';
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
            'is_on_delivery': false,
            'has_refrigeration': false,
            'has_cooler': false,
            'total_deliveries': 0,
            'completed_today': 0,
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

  /// Update driver personal info
  Future<Driver?> updatePersonalInfo({
    String? name,
    String? phone,
    String? email,
  }) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return null;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (email != null) updates['email'] = email;

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

  /// Update vehicle information
  Future<Driver?> updateVehicleInfo({
    VehicleType? vehicleType,
    String? vehicleModel,
    String? licensePlate,
    int? vehicleYear,
  }) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return null;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (vehicleType != null) updates['vehicle_type'] = vehicleType.value;
    if (vehicleModel != null) updates['vehicle_model'] = vehicleModel;
    if (licensePlate != null) updates['license_plate'] = licensePlate;
    if (vehicleYear != null) updates['vehicle_year'] = vehicleYear;

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

  /// Update capacity settings
  Future<Driver?> updateCapacitySettings({
    double? capacityCubicFeet,
    double? maxWeightLbs,
    int? maxDeliveriesPerRun,
    bool? hasRefrigeration,
    bool? hasCooler,
  }) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return null;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (capacityCubicFeet != null) updates['capacity_cubic_feet'] = capacityCubicFeet;
    if (maxWeightLbs != null) updates['max_weight_lbs'] = maxWeightLbs;
    if (maxDeliveriesPerRun != null) updates['max_deliveries_per_run'] = maxDeliveriesPerRun;
    if (hasRefrigeration != null) updates['has_refrigeration'] = hasRefrigeration;
    if (hasCooler != null) updates['has_cooler'] = hasCooler;

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

  /// Update full driver profile (combines all updates)
  Future<Driver?> updateDriver({
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
    bool? isAvailable,
  }) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return null;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (vehicleType != null) updates['vehicle_type'] = vehicleType.value;
    if (vehicleModel != null) updates['vehicle_model'] = vehicleModel;
    if (licensePlate != null) updates['license_plate'] = licensePlate;
    if (vehicleYear != null) updates['vehicle_year'] = vehicleYear;
    if (capacityCubicFeet != null) updates['capacity_cubic_feet'] = capacityCubicFeet;
    if (maxWeightLbs != null) updates['max_weight_lbs'] = maxWeightLbs;
    if (maxDeliveriesPerRun != null) updates['max_deliveries_per_run'] = maxDeliveriesPerRun;
    if (hasRefrigeration != null) updates['has_refrigeration'] = hasRefrigeration;
    if (hasCooler != null) updates['has_cooler'] = hasCooler;
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

  /// Update driver location
  Future<void> updateLocation(double latitude, double longitude) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('drivers')
        .update({
          'current_latitude': latitude,
          'current_longitude': longitude,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  /// Set driver on delivery status
  Future<void> setOnDelivery(bool isOnDelivery) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('drivers')
        .update({
          'is_on_delivery': isOnDelivery,
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
          'completed_today': driver.completedToday + 1,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  /// Reset daily delivery count (call at start of day)
  Future<void> resetDailyCount() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('drivers')
        .update({
          'completed_today': 0,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  /// Get available drivers for assignment (admin use)
  Future<List<Driver>> getAvailableDrivers() async {
    try {
      final response = await _client
          .from('drivers')
          .select()
          .eq('is_available', true)
          .eq('is_on_delivery', false)
          .order('rating', ascending: false);

      return (response as List)
          .map((json) => Driver.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get drivers matching capacity requirements
  Future<List<Driver>> getDriversForCapacity({
    required double requiredCapacityCubicFeet,
    required double requiredWeightLbs,
    bool requiresRefrigeration = false,
  }) async {
    try {
      var query = _client
          .from('drivers')
          .select()
          .eq('is_available', true)
          .eq('is_on_delivery', false);

      if (requiresRefrigeration) {
        query = query.or('has_refrigeration.eq.true,has_cooler.eq.true');
      }

      final response = await query.order('rating', ascending: false);

      // Filter by capacity client-side (Supabase doesn't support complex comparisons easily)
      return (response as List)
          .map((json) => Driver.fromJson(json))
          .where((driver) =>
              driver.effectiveCapacity >= requiredCapacityCubicFeet &&
              driver.effectiveMaxWeight >= requiredWeightLbs)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Upload profile photo and update driver record
  Future<String?> uploadProfilePhoto(File photo) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return null;

    try {
      final fileName = 'profile_$userId\_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'drivers/$userId/$fileName';

      // Upload to Supabase Storage
      await _client.storage
          .from('profile-photos')
          .upload(filePath, photo);

      // Get public URL
      final photoUrl = _client.storage
          .from('profile-photos')
          .getPublicUrl(filePath);

      // Update driver record with photo URL
      await _client
          .from('drivers')
          .update({
            'profile_photo_url': photoUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      return photoUrl;
    } catch (e) {
      return null;
    }
  }

  /// Delete profile photo
  Future<bool> deleteProfilePhoto() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return false;

    try {
      // Get current driver to find photo path
      final driver = await getCurrentDriver();
      if (driver?.profilePhotoUrl != null) {
        // Extract file path from URL and delete from storage
        final uri = Uri.parse(driver!.profilePhotoUrl!);
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 2) {
          final filePath = pathSegments.sublist(pathSegments.length - 3).join('/');
          await _client.storage.from('profile-photos').remove([filePath]);
        }
      }

      // Clear photo URL in driver record
      await _client
          .from('drivers')
          .update({
            'profile_photo_url': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      return true;
    } catch (e) {
      return false;
    }
  }
}
