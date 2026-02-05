/// Message model for driver-customer communication
class Message {
  final String id;
  final String deliveryId;
  final String senderId;
  final String senderType; // 'driver' or 'customer'
  final String content;
  final MessageType type;
  final DateTime createdAt;
  final bool isRead;

  Message({
    required this.id,
    required this.deliveryId,
    required this.senderId,
    required this.senderType,
    required this.content,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  bool get isFromDriver => senderType == 'driver';
  bool get isFromCustomer => senderType == 'customer';

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      deliveryId: json['delivery_id'] as String,
      senderId: json['sender_id'] as String,
      senderType: json['sender_type'] as String,
      content: json['content'] as String,
      type: MessageType.fromString(json['type'] as String? ?? 'text'),
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'delivery_id': deliveryId,
      'sender_id': senderId,
      'sender_type': senderType,
      'content': content,
      'type': type.value,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }
}

enum MessageType {
  text('text'),
  quickReply('quick_reply'),
  locationUpdate('location_update'),
  etaUpdate('eta_update'),
  statusUpdate('status_update');

  final String value;
  const MessageType(this.value);

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MessageType.text,
    );
  }
}

/// Pre-defined quick reply messages for drivers
class QuickReply {
  final String id;
  final String message;
  final IconType icon;

  const QuickReply({
    required this.id,
    required this.message,
    required this.icon,
  });

  static const List<QuickReply> driverQuickReplies = [
    QuickReply(
      id: 'on_my_way',
      message: "I'm on my way to your location!",
      icon: IconType.directions,
    ),
    QuickReply(
      id: 'arriving_soon',
      message: "I'll be arriving in about 5 minutes.",
      icon: IconType.timer,
    ),
    QuickReply(
      id: 'at_location',
      message: "I've arrived at your location.",
      icon: IconType.location,
    ),
    QuickReply(
      id: 'need_directions',
      message: "I'm having trouble finding your address. Could you provide more directions?",
      icon: IconType.help,
    ),
    QuickReply(
      id: 'running_late',
      message: "Running a bit late due to traffic. I'll be there as soon as possible.",
      icon: IconType.warning,
    ),
    QuickReply(
      id: 'call_me',
      message: "Please give me a call when you have a moment.",
      icon: IconType.phone,
    ),
  ];
}

enum IconType {
  directions,
  timer,
  location,
  help,
  warning,
  phone,
}
