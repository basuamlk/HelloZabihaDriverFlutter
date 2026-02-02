import 'package:flutter/material.dart';
import '../models/delivery.dart';

class StatusBadge extends StatelessWidget {
  final DeliveryStatus status;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(compact ? 4 : 8),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: status.color,
          fontSize: compact ? 11 : 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
