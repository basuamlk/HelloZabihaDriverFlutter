import '../models/order_item.dart';
import 'supabase_service.dart';

class OrderService {
  static OrderService? _instance;
  static OrderService get instance => _instance ??= OrderService._();

  OrderService._();

  /// Get order items for a specific order
  Future<List<OrderItem>> getOrderItems(String orderId) async {
    try {
      final response = await SupabaseService.client
          .from('order_items')
          .select()
          .eq('order_id', orderId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => OrderItem.fromJson(json))
          .toList();
    } catch (e) {
      // Table might not exist yet, return empty list
      return [];
    }
  }

  /// Get order items for a delivery (via order_id in delivery)
  Future<List<OrderItem>> getItemsForDelivery(String deliveryOrderId) async {
    return getOrderItems(deliveryOrderId);
  }
}
