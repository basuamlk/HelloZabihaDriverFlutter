import 'package:flutter/material.dart';

enum NotificationType {
  newDelivery,
  statusUpdate,
  deliveryReminder,
  systemAlert,
}

extension NotificationTypeExtension on NotificationType {
  String get title {
    switch (this) {
      case NotificationType.newDelivery:
        return 'New Delivery';
      case NotificationType.statusUpdate:
        return 'Status Update';
      case NotificationType.deliveryReminder:
        return 'Delivery Reminder';
      case NotificationType.systemAlert:
        return 'System Alert';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.newDelivery:
        return Icons.local_shipping;
      case NotificationType.statusUpdate:
        return Icons.update;
      case NotificationType.deliveryReminder:
        return Icons.alarm;
      case NotificationType.systemAlert:
        return Icons.info_outline;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.newDelivery:
        return Colors.green;
      case NotificationType.statusUpdate:
        return Colors.blue;
      case NotificationType.deliveryReminder:
        return Colors.orange;
      case NotificationType.systemAlert:
        return Colors.purple;
    }
  }
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? deliveryId;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.deliveryId,
    this.data,
  });

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    String? deliveryId,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      deliveryId: deliveryId ?? this.deliveryId,
      data: data ?? this.data,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: NotificationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => NotificationType.systemAlert,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      deliveryId: json['delivery_id'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'delivery_id': deliveryId,
      'data': data,
    };
  }

  /// Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.month}/${createdAt.day}';
    }
  }
}
