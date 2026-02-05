import 'dart:io';
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
    final updates = <String, dynamic>{
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

  /// Confirm pickup with optional photo
  Future<Delivery> confirmPickup(
    String deliveryId, {
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{
      'status': DeliveryStatus.pickedUpFromFarm.value,
      'actual_pickup_time': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (photoUrl != null) {
      updates['pickup_photo_url'] = photoUrl;
    }

    final response = await _client
        .from('deliveries')
        .update(updates)
        .eq('id', deliveryId)
        .select()
        .single();

    return Delivery.fromJson(response);
  }

  /// Start delivery (en route)
  Future<Delivery> startDelivery(String deliveryId) async {
    final updates = <String, dynamic>{
      'status': DeliveryStatus.enRoute.value,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _client
        .from('deliveries')
        .update(updates)
        .eq('id', deliveryId)
        .select()
        .single();

    return Delivery.fromJson(response);
  }

  /// Mark as nearby (15 min away)
  Future<Delivery> markNearby(String deliveryId) async {
    final updates = <String, dynamic>{
      'status': DeliveryStatus.nearbyFifteenMin.value,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _client
        .from('deliveries')
        .update(updates)
        .eq('id', deliveryId)
        .select()
        .single();

    return Delivery.fromJson(response);
  }

  /// Complete delivery with photo and optional signature
  Future<Delivery> completeDelivery(
    String deliveryId, {
    required String deliveryPhotoUrl,
    String? signatureUrl,
    String? recipientName,
  }) async {
    final updates = <String, dynamic>{
      'status': DeliveryStatus.completed.value,
      'actual_delivery_time': DateTime.now().toIso8601String(),
      'delivery_photo_url': deliveryPhotoUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (signatureUrl != null) {
      updates['signature_url'] = signatureUrl;
    }

    if (recipientName != null) {
      updates['delivery_recipient_name'] = recipientName;
    }

    final response = await _client
        .from('deliveries')
        .update(updates)
        .eq('id', deliveryId)
        .select()
        .single();

    return Delivery.fromJson(response);
  }

  /// Mark delivery as failed
  Future<Delivery> failDelivery(
    String deliveryId, {
    String? reason,
  }) async {
    final updates = <String, dynamic>{
      'status': DeliveryStatus.failed.value,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (reason != null) {
      updates['delivery_notes'] = reason;
    }

    final response = await _client
        .from('deliveries')
        .update(updates)
        .eq('id', deliveryId)
        .select()
        .single();

    return Delivery.fromJson(response);
  }

  /// Update ETA
  Future<Delivery> updateETA(String deliveryId, int estimatedMinutes) async {
    final response = await _client
        .from('deliveries')
        .update({
          'estimated_minutes': estimatedMinutes,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', deliveryId)
        .select()
        .single();

    return Delivery.fromJson(response);
  }

  /// Upload photo to Supabase storage
  Future<String?> uploadDeliveryPhoto(
    String deliveryId,
    File photo, {
    required String type, // 'pickup' or 'delivery'
  }) async {
    try {
      final userId = AuthService.instance.currentUser?.id;
      if (userId == null) return null;

      final fileName = '${type}_${deliveryId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '$userId/$deliveryId/$fileName';

      await _client.storage
          .from('delivery-photos')
          .upload(path, photo);

      final publicUrl = _client.storage
          .from('delivery-photos')
          .getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      return null;
    }
  }

  /// Upload signature image
  Future<String?> uploadSignature(
    String deliveryId,
    File signatureImage,
  ) async {
    try {
      final userId = AuthService.instance.currentUser?.id;
      if (userId == null) return null;

      final fileName = 'signature_${deliveryId}_${DateTime.now().millisecondsSinceEpoch}.png';
      final path = '$userId/$deliveryId/$fileName';

      await _client.storage
          .from('delivery-photos')
          .upload(path, signatureImage);

      final publicUrl = _client.storage
          .from('delivery-photos')
          .getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      return null;
    }
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

  /// Get active delivery (currently being delivered)
  Future<Delivery?> getActiveDelivery() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _client
          .from('deliveries')
          .select()
          .eq('driver_id', userId)
          .inFilter('status', [
            DeliveryStatus.pickedUpFromFarm.value,
            DeliveryStatus.enRoute.value,
            DeliveryStatus.nearbyFifteenMin.value,
          ])
          .order('updated_at', ascending: false)
          .limit(1)
          .single();

      return Delivery.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Subscribe to delivery updates (real-time)
  Stream<Delivery> subscribeToDelivery(String deliveryId) {
    return _client
        .from('deliveries')
        .stream(primaryKey: ['id'])
        .eq('id', deliveryId)
        .map((data) => Delivery.fromJson(data.first));
  }
}
