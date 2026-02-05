import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/app_notification.dart';
import '../models/delivery.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();

  NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  final _notificationController = StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get notificationStream => _notificationController.stream;

  bool _initialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions on iOS
    if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    // Request permissions on Android 13+
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - will be handled by the app
    final payload = response.payload;
    if (payload != null) {
      // Parse payload and navigate
      debugPrint('Notification tapped: $payload');
    }
  }

  /// Show local notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    bool playSound = true,
    bool vibrate = true,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'hellozabiha_driver',
      'HelloZabiha Driver',
      channelDescription: 'Delivery notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _localNotifications.show(id, title, body, details, payload: payload);

    // Play custom sound for urgent notifications
    if (playSound) {
      await _playNotificationSound();
    }

    // Vibrate
    if (vibrate) {
      await _vibrate();
    }
  }

  /// Show notification for new delivery assignment
  Future<void> showNewDeliveryNotification(Delivery delivery) async {
    final notification = AppNotification(
      id: 'delivery_${delivery.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.newDelivery,
      title: 'New Delivery Assigned',
      message: 'Pickup from ${delivery.pickupAddress ?? "warehouse"} to ${delivery.customerName}',
      createdAt: DateTime.now(),
      deliveryId: delivery.id,
    );

    _notificationController.add(notification);

    await showNotification(
      title: notification.title,
      body: notification.message,
      payload: 'delivery:${delivery.id}',
    );
  }

  /// Show notification for delivery status update
  Future<void> showStatusUpdateNotification(
    Delivery delivery,
    DeliveryStatus oldStatus,
    DeliveryStatus newStatus,
  ) async {
    String message;
    switch (newStatus) {
      case DeliveryStatus.pickedUpFromFarm:
        message = 'Pickup confirmed for ${delivery.customerName}';
        break;
      case DeliveryStatus.enRoute:
        message = 'En route to ${delivery.customerName}';
        break;
      case DeliveryStatus.nearbyFifteenMin:
        message = '15 minutes away from ${delivery.customerName}';
        break;
      case DeliveryStatus.completed:
        message = 'Delivery to ${delivery.customerName} completed!';
        break;
      case DeliveryStatus.failed:
        message = 'Delivery to ${delivery.customerName} marked as failed';
        break;
      default:
        message = 'Status updated to ${newStatus.displayName}';
    }

    final notification = AppNotification(
      id: 'status_${delivery.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.statusUpdate,
      title: 'Delivery Update',
      message: message,
      createdAt: DateTime.now(),
      deliveryId: delivery.id,
    );

    _notificationController.add(notification);

    // Only show push notification for certain status changes
    if (newStatus == DeliveryStatus.completed || newStatus == DeliveryStatus.failed) {
      await showNotification(
        title: notification.title,
        body: notification.message,
        payload: 'delivery:${delivery.id}',
        vibrate: false,
      );
    }
  }

  /// Show delivery reminder
  Future<void> showDeliveryReminder(Delivery delivery, String message) async {
    final notification = AppNotification(
      id: 'reminder_${delivery.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.deliveryReminder,
      title: 'Delivery Reminder',
      message: message,
      createdAt: DateTime.now(),
      deliveryId: delivery.id,
    );

    _notificationController.add(notification);

    await showNotification(
      title: notification.title,
      body: notification.message,
      payload: 'delivery:${delivery.id}',
    );
  }

  /// Show system alert
  Future<void> showSystemAlert(String title, String message) async {
    final notification = AppNotification(
      id: 'system_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.systemAlert,
      title: title,
      message: message,
      createdAt: DateTime.now(),
    );

    _notificationController.add(notification);

    await showNotification(
      title: title,
      body: message,
      vibrate: false,
    );
  }

  /// Play notification sound
  Future<void> _playNotificationSound() async {
    try {
      // Use system notification sound
      await _audioPlayer.play(
        AssetSource('sounds/notification.mp3'),
        volume: 0.5,
      );
    } catch (e) {
      // Fallback: system will play default notification sound
      debugPrint('Could not play custom sound: $e');
    }
  }

  /// Vibrate device
  Future<void> _vibrate() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        // Short vibration pattern
        await Vibration.vibrate(duration: 300);
      }
    } catch (e) {
      debugPrint('Could not vibrate: $e');
    }
  }

  /// Vibrate for urgent notification
  Future<void> vibrateUrgent() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        // Longer pattern for urgent
        await Vibration.vibrate(
          pattern: [0, 200, 100, 200, 100, 200],
        );
      }
    } catch (e) {
      debugPrint('Could not vibrate: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _localNotifications.cancelAll();
  }

  /// Cancel specific notification
  Future<void> cancel(int id) async {
    await _localNotifications.cancel(id);
  }

  void dispose() {
    _notificationController.close();
    _audioPlayer.dispose();
  }
}
