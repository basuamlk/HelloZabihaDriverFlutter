import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';

class MessagingService {
  static final MessagingService instance = MessagingService._internal();
  MessagingService._internal();

  SupabaseClient get _supabase => Supabase.instance.client;

  /// Get all messages for a delivery
  Future<List<Message>> getMessages(String deliveryId) async {
    try {
      final response = await _supabase
          .from('delivery_messages')
          .select()
          .eq('delivery_id', deliveryId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => Message.fromJson(json))
          .toList();
    } catch (e) {
      // Table might not exist yet, return empty list
      return [];
    }
  }

  /// Send a message from the driver
  Future<Message?> sendMessage({
    required String deliveryId,
    required String driverId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    try {
      final response = await _supabase.from('delivery_messages').insert({
        'delivery_id': deliveryId,
        'sender_id': driverId,
        'sender_type': 'driver',
        'content': content,
        'type': type.value,
      }).select().single();

      return Message.fromJson(response);
    } catch (e) {
      // If table doesn't exist, create a local-only message
      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        deliveryId: deliveryId,
        senderId: driverId,
        senderType: 'driver',
        content: content,
        type: type,
        createdAt: DateTime.now(),
      );
    }
  }

  /// Send a quick reply message
  Future<Message?> sendQuickReply({
    required String deliveryId,
    required String driverId,
    required QuickReply quickReply,
  }) async {
    return sendMessage(
      deliveryId: deliveryId,
      driverId: driverId,
      content: quickReply.message,
      type: MessageType.quickReply,
    );
  }

  /// Send ETA update message
  Future<Message?> sendETAUpdate({
    required String deliveryId,
    required String driverId,
    required int minutes,
  }) async {
    final content = minutes == 1
        ? "I'll arrive in about 1 minute."
        : "I'll arrive in about $minutes minutes.";

    return sendMessage(
      deliveryId: deliveryId,
      driverId: driverId,
      content: content,
      type: MessageType.etaUpdate,
    );
  }

  /// Send location/status update message
  Future<Message?> sendStatusUpdate({
    required String deliveryId,
    required String driverId,
    required String status,
  }) async {
    String content;
    switch (status) {
      case 'picked_up':
        content = "I've picked up your order and am heading your way!";
        break;
      case 'en_route':
        content = "I'm on my way to deliver your order.";
        break;
      case 'nearby':
        content = "I'm nearby and will arrive shortly.";
        break;
      case 'arrived':
        content = "I've arrived at your location.";
        break;
      default:
        content = "Order status updated: $status";
    }

    return sendMessage(
      deliveryId: deliveryId,
      driverId: driverId,
      content: content,
      type: MessageType.statusUpdate,
    );
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String deliveryId, String readerId) async {
    try {
      await _supabase
          .from('delivery_messages')
          .update({'is_read': true})
          .eq('delivery_id', deliveryId)
          .neq('sender_id', readerId);
    } catch (e) {
      // Ignore errors if table doesn't exist
    }
  }

  /// Subscribe to new messages for a delivery
  Stream<Message> subscribeToMessages(String deliveryId) {
    return _supabase
        .from('delivery_messages')
        .stream(primaryKey: ['id'])
        .eq('delivery_id', deliveryId)
        .order('created_at')
        .map((data) => data.map((json) => Message.fromJson(json)))
        .expand((messages) => messages);
  }

  /// Get unread message count for a delivery
  Future<int> getUnreadCount(String deliveryId, String readerId) async {
    try {
      final response = await _supabase
          .from('delivery_messages')
          .select('id')
          .eq('delivery_id', deliveryId)
          .eq('is_read', false)
          .neq('sender_id', readerId);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }
}
