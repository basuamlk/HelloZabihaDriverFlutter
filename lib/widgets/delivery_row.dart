import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/delivery.dart';
import '../theme/app_theme.dart';
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingXS),
      decoration: AppTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: delivery.status.color.withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Icon(
                    Icons.local_shipping,
                    color: delivery.status.color,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              delivery.customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          StatusBadge(status: delivery.status, compact: true),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        delivery.deliveryAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      Row(
                        children: [
                          Text(
                            '${delivery.itemCount} item${delivery.itemCount != 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: AppTheme.textHint,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          const Text(
                            '•',
                            style: TextStyle(color: AppTheme.textHint),
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          Text(
                            currencyFormat.format(delivery.totalAmount),
                            style: const TextStyle(
                              color: AppTheme.textHint,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppTheme.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
