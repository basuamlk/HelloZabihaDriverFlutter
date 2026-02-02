import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/delivery.dart';
import 'supabase_service.dart';
import 'auth_service.dart';

class DeliveryService {
  static DeliveryService? _instance;
  static DeliveryService get instance => _instance ??= DeliveryService._();

  DeliveryService._();

  SupabaseClient get _client => SupabaseService.client;

  Future<List<Delivery>> getDriverDeliveries() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('deliveries')
        .select()
        .eq('driver_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Delivery.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Delivery?> getDelivery(String id) async {
    final response =
        await _client.from('deliveries').select().eq('id', id).single();

    return Delivery.fromJson(response);
  }

  Future<Delivery> updateDeliveryStatus(
    String deliveryId,
    DeliveryStatus status,
  ) async {
    final updates = {
      'status': status.value,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (status == DeliveryStatus.completed) {
      updates['actual_delivery_time'] = DateTime.now().toIso8601String();
    }

    final response = await _client
        .from('deliveries')
        .update(updates)
        .eq('id', deliveryId)
        .select()
        .single();

    return Delivery.fromJson(response);
  }

  Future<List<Delivery>> getDeliveriesByStatus(DeliveryStatus status) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('deliveries')
        .select()
        .eq('driver_id', userId)
        .eq('status', status.value)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Delivery.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Delivery>> getPendingDeliveries() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('deliveries')
        .select()
        .eq('driver_id', userId)
        .inFilter('status', [
          DeliveryStatus.assigned.value,
          DeliveryStatus.pickedUpFromFarm.value,
          DeliveryStatus.enRoute.value,
          DeliveryStatus.nearbyFifteenMin.value,
        ])
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Delivery.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Delivery>> getCompletedDeliveries() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('deliveries')
        .select()
        .eq('driver_id', userId)
        .eq('status', DeliveryStatus.completed.value)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Delivery.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
