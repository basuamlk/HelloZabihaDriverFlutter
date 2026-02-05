import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/faq.dart';

class SupportService {
  static final SupportService instance = SupportService._internal();
  SupportService._internal();

  SupabaseClient get _supabase => Supabase.instance.client;

  /// Get FAQs (uses defaults, can be extended to fetch from server)
  Future<List<FAQ>> getFAQs() async {
    // For now, return default FAQs
    // In the future, this could fetch from Supabase
    return FAQ.defaultFAQs;
  }

  /// Search FAQs
  List<FAQ> searchFAQs(String query) {
    if (query.isEmpty) return FAQ.defaultFAQs;

    final lowerQuery = query.toLowerCase();
    return FAQ.defaultFAQs.where((faq) {
      return faq.question.toLowerCase().contains(lowerQuery) ||
          faq.answer.toLowerCase().contains(lowerQuery) ||
          faq.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Submit a support ticket
  Future<SupportTicket?> submitTicket({
    required String driverId,
    required String subject,
    required String description,
    required String category,
    String? deliveryId,
  }) async {
    try {
      final response = await _supabase.from('support_tickets').insert({
        'driver_id': driverId,
        'subject': subject,
        'description': description,
        'category': category,
        'delivery_id': deliveryId,
        'status': 'open',
      }).select().single();

      return SupportTicket.fromJson(response);
    } catch (e) {
      // If table doesn't exist, return a mock ticket
      return SupportTicket(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        subject: subject,
        description: description,
        category: category,
        status: TicketStatus.open,
        createdAt: DateTime.now(),
      );
    }
  }

  /// Get driver's support tickets
  Future<List<SupportTicket>> getTickets(String driverId) async {
    try {
      final response = await _supabase
          .from('support_tickets')
          .select()
          .eq('driver_id', driverId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => SupportTicket.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get support contact info
  Map<String, String> getSupportContact() {
    return {
      'email': 'support@hellozabiha.com',
      'phone': '+1 (555) 123-4567',
      'hours': 'Mon-Fri 9am-6pm EST',
    };
  }
}
