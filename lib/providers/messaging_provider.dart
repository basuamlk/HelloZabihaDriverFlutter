import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../services/messaging_service.dart';

class MessagingProvider extends ChangeNotifier {
  final MessagingService _service = MessagingService.instance;

  List<Message> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSending = false;
  String? _currentDeliveryId;
  String? _currentDriverId;
  StreamSubscription? _messageSubscription;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSending => _isSending;
  int get unreadCount => _messages.where((m) => !m.isRead && m.isFromCustomer).length;

  /// Initialize messaging for a delivery
  Future<void> initializeForDelivery(String deliveryId, String driverId) async {
    // Don't reinitialize if already set up for this delivery
    if (_currentDeliveryId == deliveryId) return;

    _currentDeliveryId = deliveryId;
    _currentDriverId = driverId;
    _messages = [];
    _errorMessage = null;

    await loadMessages();
    _subscribeToMessages();
  }

  /// Load existing messages
  Future<void> loadMessages() async {
    if (_currentDeliveryId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _messages = await _service.getMessages(_currentDeliveryId!);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load messages';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Subscribe to real-time message updates
  void _subscribeToMessages() {
    _messageSubscription?.cancel();

    if (_currentDeliveryId == null) return;

    _messageSubscription = _service
        .subscribeToMessages(_currentDeliveryId!)
        .listen((message) {
      // Add new message if not already in list
      if (!_messages.any((m) => m.id == message.id)) {
        _messages.add(message);
        notifyListeners();
      }
    });
  }

  /// Send a text message
  Future<bool> sendMessage(String content) async {
    if (_currentDeliveryId == null || _currentDriverId == null) return false;
    if (content.trim().isEmpty) return false;

    _isSending = true;
    notifyListeners();

    try {
      final message = await _service.sendMessage(
        deliveryId: _currentDeliveryId!,
        driverId: _currentDriverId!,
        content: content.trim(),
      );

      if (message != null) {
        // Add to local list if not already present (real-time might have added it)
        if (!_messages.any((m) => m.id == message.id)) {
          _messages.add(message);
        }
        _isSending = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to send message';
    }

    _isSending = false;
    notifyListeners();
    return false;
  }

  /// Send a quick reply
  Future<bool> sendQuickReply(QuickReply quickReply) async {
    if (_currentDeliveryId == null || _currentDriverId == null) return false;

    _isSending = true;
    notifyListeners();

    try {
      final message = await _service.sendQuickReply(
        deliveryId: _currentDeliveryId!,
        driverId: _currentDriverId!,
        quickReply: quickReply,
      );

      if (message != null) {
        if (!_messages.any((m) => m.id == message.id)) {
          _messages.add(message);
        }
        _isSending = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to send message';
    }

    _isSending = false;
    notifyListeners();
    return false;
  }

  /// Send ETA update
  Future<bool> sendETAUpdate(int minutes) async {
    if (_currentDeliveryId == null || _currentDriverId == null) return false;

    _isSending = true;
    notifyListeners();

    try {
      final message = await _service.sendETAUpdate(
        deliveryId: _currentDeliveryId!,
        driverId: _currentDriverId!,
        minutes: minutes,
      );

      if (message != null) {
        if (!_messages.any((m) => m.id == message.id)) {
          _messages.add(message);
        }
        _isSending = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to send ETA update';
    }

    _isSending = false;
    notifyListeners();
    return false;
  }

  /// Send status update message
  Future<bool> sendStatusUpdate(String status) async {
    if (_currentDeliveryId == null || _currentDriverId == null) return false;

    try {
      final message = await _service.sendStatusUpdate(
        deliveryId: _currentDeliveryId!,
        driverId: _currentDriverId!,
        status: status,
      );

      if (message != null) {
        if (!_messages.any((m) => m.id == message.id)) {
          _messages.add(message);
        }
        notifyListeners();
        return true;
      }
    } catch (e) {
      // Silent fail for status updates
    }

    return false;
  }

  /// Mark all customer messages as read
  Future<void> markAsRead() async {
    if (_currentDeliveryId == null || _currentDriverId == null) return;

    await _service.markMessagesAsRead(_currentDeliveryId!, _currentDriverId!);
  }

  /// Clean up when leaving the chat
  @override
  void dispose() {
    _messageSubscription?.cancel();
    _currentDeliveryId = null;
    _currentDriverId = null;
    _messages = [];
    super.dispose();
  }

  /// Clear state for a delivery
  void clearForDelivery() {
    _messageSubscription?.cancel();
    _currentDeliveryId = null;
    _currentDriverId = null;
    _messages = [];
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
