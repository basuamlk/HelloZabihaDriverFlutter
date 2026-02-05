import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/delivery.dart';
import 'auth_service.dart';

/// Service for managing dev mode and mock data generation
class DevModeService {
  static final DevModeService instance = DevModeService._internal();
  DevModeService._internal();

  static const String _devModeKey = 'dev_mode_enabled';
  bool _isDevMode = false;

  bool get isDevMode => _isDevMode;

  SupabaseClient get _client => Supabase.instance.client;

  /// Initialize dev mode state from preferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isDevMode = prefs.getBool(_devModeKey) ?? false;
  }

  /// Toggle dev mode
  Future<void> setDevMode(bool enabled) async {
    _isDevMode = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_devModeKey, enabled);
  }

  /// Generate mock deliveries for testing
  Future<int> generateMockDeliveries({int count = 5}) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return 0;

    final random = Random();
    int created = 0;

    // San Francisco area coordinates
    const baseLat = 37.7749;
    const baseLng = -122.4194;

    final customers = [
      {'name': 'Sarah Johnson', 'phone': '415-555-0101'},
      {'name': 'Michael Chen', 'phone': '415-555-0102'},
      {'name': 'Emily Rodriguez', 'phone': '415-555-0103'},
      {'name': 'David Kim', 'phone': '415-555-0104'},
      {'name': 'Jessica Williams', 'phone': '415-555-0105'},
      {'name': 'Ahmed Hassan', 'phone': '415-555-0106'},
      {'name': 'Maria Garcia', 'phone': '415-555-0107'},
      {'name': 'James Brown', 'phone': '415-555-0108'},
    ];

    final addresses = [
      '123 Market St, San Francisco, CA 94102',
      '456 Mission St, San Francisco, CA 94105',
      '789 Valencia St, San Francisco, CA 94110',
      '321 Castro St, San Francisco, CA 94114',
      '654 Haight St, San Francisco, CA 94117',
      '987 Fillmore St, San Francisco, CA 94115',
      '147 Polk St, San Francisco, CA 94109',
      '258 Columbus Ave, San Francisco, CA 94133',
    ];

    final pickupAddresses = [
      'HelloZabiha Farm, 100 Farm Road, Petaluma, CA 94952',
      'Zabiha Meats Warehouse, 500 Industrial Blvd, South SF, CA 94080',
      'Halal Fresh Market, 200 Produce Ave, Oakland, CA 94607',
    ];

    final instructions = [
      null,
      'Please ring doorbell twice',
      'Leave at door if no answer',
      'Call when arriving',
      'Gate code: 1234',
      'Apartment on 3rd floor',
      null,
      'Dog in yard - use side gate',
    ];

    final statuses = [
      DeliveryStatus.assigned,
      DeliveryStatus.assigned,
      DeliveryStatus.pickedUpFromFarm,
      DeliveryStatus.enRoute,
      DeliveryStatus.nearbyFifteenMin,
    ];

    for (int i = 0; i < count; i++) {
      final customer = customers[random.nextInt(customers.length)];
      final address = addresses[random.nextInt(addresses.length)];
      final pickup = pickupAddresses[random.nextInt(pickupAddresses.length)];
      final instruction = instructions[random.nextInt(instructions.length)];
      final status = statuses[random.nextInt(statuses.length)];

      final deliveryLat = baseLat + (random.nextDouble() - 0.5) * 0.1;
      final deliveryLng = baseLng + (random.nextDouble() - 0.5) * 0.1;

      final itemCount = random.nextInt(5) + 1;
      final totalAmount = (random.nextDouble() * 150 + 30).roundToDouble();

      try {
        await _client.from('deliveries').insert({
          'order_id': _generateUuid(),
          'driver_id': userId,
          'customer_name': customer['name'],
          'customer_phone': customer['phone'],
          'pickup_address': pickup,
          'pickup_latitude': 37.8 + random.nextDouble() * 0.1,
          'pickup_longitude': -122.5 + random.nextDouble() * 0.1,
          'delivery_address': address,
          'delivery_latitude': deliveryLat,
          'delivery_longitude': deliveryLng,
          'delivery_notes': instruction,
          'item_count': itemCount,
          'total_amount': totalAmount,
          'status': status.value,
          'requires_signature': random.nextBool(),
          'requires_refrigeration': random.nextBool(),
          'estimated_minutes': random.nextInt(30) + 15,
          'scheduled_pickup_time': DateTime.now().add(Duration(hours: random.nextInt(3))).toIso8601String(),
        });
        created++;
      } catch (e) {
        debugPrint('Failed to create mock delivery: $e');
      }
    }

    return created;
  }

  /// Generate completed deliveries for earnings/history
  Future<int> generateCompletedDeliveries({int count = 10}) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return 0;

    final random = Random();
    int created = 0;

    final customers = [
      {'name': 'Sarah Johnson', 'phone': '415-555-0101'},
      {'name': 'Michael Chen', 'phone': '415-555-0102'},
      {'name': 'Emily Rodriguez', 'phone': '415-555-0103'},
      {'name': 'David Kim', 'phone': '415-555-0104'},
      {'name': 'Jessica Williams', 'phone': '415-555-0105'},
    ];

    final addresses = [
      '123 Market St, San Francisco, CA 94102',
      '456 Mission St, San Francisco, CA 94105',
      '789 Valencia St, San Francisco, CA 94110',
      '321 Castro St, San Francisco, CA 94114',
      '654 Haight St, San Francisco, CA 94117',
    ];

    for (int i = 0; i < count; i++) {
      final customer = customers[random.nextInt(customers.length)];
      final address = addresses[random.nextInt(addresses.length)];
      final daysAgo = random.nextInt(30);
      final completedAt = DateTime.now().subtract(Duration(days: daysAgo, hours: random.nextInt(12)));
      final pickedUpAt = completedAt.subtract(Duration(minutes: random.nextInt(45) + 15));

      final totalAmount = (random.nextDouble() * 150 + 30).roundToDouble();

      try {
        await _client.from('deliveries').insert({
          'order_id': _generateUuid(),
          'driver_id': userId,
          'customer_name': customer['name'],
          'customer_phone': customer['phone'],
          'delivery_address': address,
          'delivery_latitude': 37.7749 + (random.nextDouble() - 0.5) * 0.1,
          'delivery_longitude': -122.4194 + (random.nextDouble() - 0.5) * 0.1,
          'item_count': random.nextInt(5) + 1,
          'total_amount': totalAmount,
          'status': 'completed',
          'actual_pickup_time': pickedUpAt.toIso8601String(),
          'actual_delivery_time': completedAt.toIso8601String(),
          'created_at': pickedUpAt.subtract(const Duration(hours: 1)).toIso8601String(),
        });
        created++;
      } catch (e) {
        debugPrint('Failed to create completed delivery: $e');
      }
    }

    return created;
  }

  /// Clear all mock data for current user
  Future<int> clearMockData() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return 0;

    try {
      final result = await _client
          .from('deliveries')
          .delete()
          .eq('driver_id', userId)
          .select();

      return (result as List).length;
    } catch (e) {
      debugPrint('Failed to clear mock data: $e');
      return 0;
    }
  }

  String _generateUuid() {
    final random = Random();
    const hexChars = '0123456789abcdef';
    String uuid = '';
    for (int i = 0; i < 32; i++) {
      if (i == 8 || i == 12 || i == 16 || i == 20) {
        uuid += '-';
      }
      uuid += hexChars[random.nextInt(16)];
    }
    return uuid;
  }
}
