import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/delivery.dart';
import 'status_badge.dart';

class DeliveryRow extends StatelessWidget {
  final Delivery delivery;
  final VoidCallback? onTap;

  const DeliveryRow({
    super.key,
    required this.delivery,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: delivery.status.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(
            Icons.local_shipping,
            color: delivery.status.color,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                delivery.customerName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            StatusBadge(status: delivery.status, compact: true),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              delivery.deliveryAddress,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${delivery.itemCount} item${delivery.itemCount != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '•',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                const SizedBox(width: 8),
                Text(
                  currencyFormat.format(delivery.totalAmount),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
