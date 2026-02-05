import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';
import '../models/delivery.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';

class NotificationsProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService.instance;
  final AuthService _authService = AuthService.instance;

  List<AppNotification> _notifications = [];
  StreamSubscription? _deliverySubscription;
  StreamSubscription? _notificationStreamSubscription;
  final bool _isLoading = false;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;

  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  /// Initialize and start listening
  Future<void> initialize() async {
    await _notificationService.initialize();

    // Listen to notification stream from service
    _notificationStreamSubscription =
        _notificationService.notificationStream.listen(_onNewNotification);

    // Start listening for real-time delivery updates
    _startDeliverySubscription();
  }

  void _onNewNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    // Keep only last 50 notifications
    if (_notifications.length > 50) {
      _notifications = _notifications.sublist(0, 50);
    }
    notifyListeners();
  }

  /// Start real-time subscription for delivery updates
  void _startDeliverySubscription() {
    final userId = _authService.currentUser?.id;
    if (userId == null) return;

    _deliverySubscription?.cancel();

    // Subscribe to changes in deliveries table for this driver
    _deliverySubscription = SupabaseService.client
        .from('deliveries')
        .stream(primaryKey: ['id'])
        .eq('driver_id', userId)
        .listen((List<Map<String, dynamic>> data) {
          _handleDeliveryUpdates(data);
        });
  }

  void _handleDeliveryUpdates(List<Map<String, dynamic>> data) {
    // This is called whenever there's a change to deliveries
    // We'll detect new deliveries by checking if they're newly assigned
    for (final item in data) {
      try {
        final delivery = Delivery.fromJson(item);

        // Check if this is a newly assigned delivery (status is assigned and recent)
        if (delivery.status == DeliveryStatus.assigned) {
          final timeSinceCreated = DateTime.now().difference(delivery.createdAt);
          if (timeSinceCreated.inSeconds < 30) {
            // This is likely a new assignment
            _notificationService.showNewDeliveryNotification(delivery);
          }
        }
      } catch (e) {
        debugPrint('Error processing delivery update: $e');
      }
    }
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  /// Delete notification
  void deleteNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  /// Clear all notifications
  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  /// Add a test notification (for development)
  void addTestNotification() {
    final notification = AppNotification(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.newDelivery,
      title: 'New Delivery Assigned',
      message: 'Pickup from HelloZabiha Farm to John Smith at 123 Main St',
      createdAt: DateTime.now(),
      deliveryId: 'test-delivery-id',
    );
    _onNewNotification(notification);
  }

  /// Refresh subscription (call after login)
  void refreshSubscription() {
    _startDeliverySubscription();
  }

  @override
  void dispose() {
    _deliverySubscription?.cancel();
    _notificationStreamSubscription?.cancel();
    super.dispose();
  }
}
