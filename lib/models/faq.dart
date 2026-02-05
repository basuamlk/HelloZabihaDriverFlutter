/// FAQ model for help center
class FAQ {
  final String id;
  final String question;
  final String answer;
  final String category;
  final int orderIndex;

  const FAQ({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    this.orderIndex = 0,
  });

  factory FAQ.fromJson(Map<String, dynamic> json) {
    return FAQ(
      id: json['id'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      category: json['category'] as String,
      orderIndex: json['order_index'] as int? ?? 0,
    );
  }

  /// Default FAQs for the driver app
  static const List<FAQ> defaultFAQs = [
    // Getting Started
    FAQ(
      id: 'gs_1',
      question: 'How do I start receiving deliveries?',
      answer: 'Complete your profile with vehicle information and set yourself as "Online" on the home screen. You\'ll receive delivery assignments based on your location and vehicle capacity.',
      category: 'Getting Started',
      orderIndex: 1,
    ),
    FAQ(
      id: 'gs_2',
      question: 'What vehicle types are accepted?',
      answer: 'We accept cars, SUVs, vans, and trucks. Your vehicle must have adequate space for deliveries and, for meat products, proper cold storage capability (cooler or refrigeration unit).',
      category: 'Getting Started',
      orderIndex: 2,
    ),
    FAQ(
      id: 'gs_3',
      question: 'Do I need cold storage for deliveries?',
      answer: 'Yes, since HelloZabiha delivers halal meat products, you need either a cooler with ice packs or a refrigeration unit to maintain product freshness during transport.',
      category: 'Getting Started',
      orderIndex: 3,
    ),

    // Deliveries
    FAQ(
      id: 'del_1',
      question: 'How do I accept a delivery?',
      answer: 'When a delivery is assigned to you, you\'ll see it in your Deliveries tab. Tap on it to view details, then follow the status buttons to progress through pickup and delivery.',
      category: 'Deliveries',
      orderIndex: 1,
    ),
    FAQ(
      id: 'del_2',
      question: 'What if the customer is not available?',
      answer: 'Try calling or messaging the customer through the app. If you cannot reach them after multiple attempts, mark the delivery as "Failed" and select the appropriate reason.',
      category: 'Deliveries',
      orderIndex: 2,
    ),
    FAQ(
      id: 'del_3',
      question: 'How do I handle special instructions?',
      answer: 'Special instructions appear in an orange banner on the delivery detail screen. Make sure to read and follow them carefully. Contact the customer if clarification is needed.',
      category: 'Deliveries',
      orderIndex: 3,
    ),
    FAQ(
      id: 'del_4',
      question: 'What photos do I need to take?',
      answer: 'You may need to take a pickup photo (of items collected) and a delivery photo (proof of delivery). Some orders also require a customer signature.',
      category: 'Deliveries',
      orderIndex: 4,
    ),

    // Earnings
    FAQ(
      id: 'earn_1',
      question: 'How is my pay calculated?',
      answer: 'You earn 15% commission on each delivery\'s order total, plus any tips from customers. Bonuses may be offered during peak times or for completing delivery streaks.',
      category: 'Earnings',
      orderIndex: 1,
    ),
    FAQ(
      id: 'earn_2',
      question: 'When do I get paid?',
      answer: 'Earnings are calculated weekly and paid out every Monday for the previous week\'s completed deliveries. Payments are sent to your registered bank account.',
      category: 'Earnings',
      orderIndex: 2,
    ),
    FAQ(
      id: 'earn_3',
      question: 'How do I view my earnings?',
      answer: 'Go to Profile > Earnings to see your earnings breakdown by day, week, or month. You can view total commission, tips, and bonuses separately.',
      category: 'Earnings',
      orderIndex: 3,
    ),

    // Account
    FAQ(
      id: 'acc_1',
      question: 'How do I update my vehicle information?',
      answer: 'Go to Profile and tap on any vehicle-related field (Vehicle Type, Model, License Plate, or Capacity) to update your information.',
      category: 'Account',
      orderIndex: 1,
    ),
    FAQ(
      id: 'acc_2',
      question: 'How do I change my phone number?',
      answer: 'Go to Profile > Personal Info and update your phone number. This is the number customers will use to contact you.',
      category: 'Account',
      orderIndex: 2,
    ),
    FAQ(
      id: 'acc_3',
      question: 'Can I take time off?',
      answer: 'Yes! Simply set yourself as "Offline" on the home screen. You won\'t receive any delivery assignments while offline. Go online again when you\'re ready to deliver.',
      category: 'Account',
      orderIndex: 3,
    ),

    // Troubleshooting
    FAQ(
      id: 'trouble_1',
      question: 'The app is not showing my location correctly',
      answer: 'Make sure location services are enabled for the app in your phone settings. Try restarting the app or your phone if the issue persists.',
      category: 'Troubleshooting',
      orderIndex: 1,
    ),
    FAQ(
      id: 'trouble_2',
      question: 'I\'m not receiving delivery assignments',
      answer: 'Check that you\'re set to "Online", have a stable internet connection, and your profile is complete. Assignments are based on proximity and availability.',
      category: 'Troubleshooting',
      orderIndex: 2,
    ),
    FAQ(
      id: 'trouble_3',
      question: 'The customer\'s address is incorrect',
      answer: 'Contact the customer through the app to confirm the correct address. If you cannot reach them, contact support for assistance.',
      category: 'Troubleshooting',
      orderIndex: 3,
    ),
  ];

  static List<String> get categories {
    return defaultFAQs.map((f) => f.category).toSet().toList();
  }

  static List<FAQ> getFAQsByCategory(String category) {
    return defaultFAQs.where((f) => f.category == category).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }
}

/// Support ticket model
class SupportTicket {
  final String id;
  final String subject;
  final String description;
  final String category;
  final TicketStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  SupportTicket({
    required this.id,
    required this.subject,
    required this.description,
    required this.category,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as String,
      subject: json['subject'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      status: TicketStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'description': description,
      'category': category,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }
}

enum TicketStatus {
  open('open'),
  inProgress('in_progress'),
  resolved('resolved'),
  closed('closed');

  final String value;
  const TicketStatus(this.value);

  static TicketStatus fromString(String value) {
    return TicketStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TicketStatus.open,
    );
  }

  String get displayName {
    switch (this) {
      case TicketStatus.open:
        return 'Open';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.resolved:
        return 'Resolved';
      case TicketStatus.closed:
        return 'Closed';
    }
  }
}
