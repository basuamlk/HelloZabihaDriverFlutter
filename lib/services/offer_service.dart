import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/delivery_offer.dart';
import 'supabase_service.dart';
import 'auth_service.dart';

class OfferService {
  static OfferService? _instance;
  static OfferService get instance => _instance ??= OfferService._();

  OfferService._();

  SupabaseClient get _client => SupabaseService.client;

  /// Respond to an offer (accept or decline) via database RPC
  Future<Map<String, dynamic>> respondToOffer(String offerId, String action) async {
    try {
      final response = await _client.rpc(
        'respond_to_delivery_offer',
        params: {'p_offer_id': offerId, 'p_action': action},
      );

      if (response is Map<String, dynamic>) {
        return response;
      }
      return {'success': true, 'action': action};
    } catch (e) {
      debugPrint('respondToOffer error: $e');
      rethrow;
    }
  }

  /// Reclaim a previously declined delivery via database RPC
  Future<Map<String, dynamic>> reclaimDelivery(String deliveryId) async {
    try {
      final response = await _client.rpc(
        'respond_to_delivery_offer',
        params: {
          'p_offer_id': deliveryId,
          'p_action': 'accept',
        },
      );

      if (response is Map<String, dynamic>) {
        return response;
      }
      return {'success': true, 'action': 'reclaimed'};
    } catch (e) {
      debugPrint('reclaimDelivery error: $e');
      rethrow;
    }
  }

  /// Get the current active offer for this driver (pending + not expired)
  Future<DeliveryOffer?> getActiveOffer() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _client
          .from('delivery_offers')
          .select()
          .eq('driver_id', userId)
          .eq('status', 'pending')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) return null;
      return DeliveryOffer.fromJson(response.first);
    } catch (e) {
      debugPrint('getActiveOffer error: $e');
      return null;
    }
  }

  /// Get recently declined offers (within last hour) for reconsider
  Future<List<DeliveryOffer>> getDeclinedOffers() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return [];

    try {
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      final response = await _client
          .from('delivery_offers')
          .select()
          .eq('driver_id', userId)
          .eq('status', 'declined')
          .gt('offered_at', oneHourAgo.toIso8601String())
          .order('responded_at', ascending: false);

      return (response as List)
          .map((json) => DeliveryOffer.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('getDeclinedOffers error: $e');
      return [];
    }
  }

  /// Subscribe to offer changes for this driver via realtime
  Stream<List<Map<String, dynamic>>> subscribeToOffers() {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return _client
        .from('delivery_offers')
        .stream(primaryKey: ['id'])
        .eq('driver_id', userId);
  }

  /// Check if a delivery is still available (for reconsider)
  Future<String?> getDeliveryStatus(String deliveryId) async {
    try {
      final response = await _client
          .from('deliveries')
          .select('status')
          .eq('id', deliveryId)
          .single();

      return response['status'] as String?;
    } catch (e) {
      debugPrint('getDeliveryStatus error: $e');
      return null;
    }
  }
}
