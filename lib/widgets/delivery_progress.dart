import 'package:flutter/material.dart';
import '../models/delivery.dart';

class DeliveryProgress extends StatelessWidget {
  final DeliveryStatus currentStatus;

  const DeliveryProgress({
    super.key,
    required this.currentStatus,
  });

  static const List<DeliveryStatus> _progressSteps = [
    DeliveryStatus.assigned,
    DeliveryStatus.pickedUpFromFarm,
    DeliveryStatus.enRoute,
    DeliveryStatus.nearbyFifteenMin,
    DeliveryStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = _progressSteps.indexOf(currentStatus);
    final isFailed = currentStatus == DeliveryStatus.failed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          if (isFailed)
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.red,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Delivery Failed',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: List.generate(_progressSteps.length * 2 - 1, (index) {
                if (index.isOdd) {
                  // Connector line
                  final stepIndex = index ~/ 2;
                  final isCompleted = stepIndex < currentIndex;
                  return Expanded(
                    child: Container(
                      height: 3,
                      color: isCompleted ? Colors.green : Colors.grey[300],
                    ),
                  );
                } else {
                  // Step circle
                  final stepIndex = index ~/ 2;
                  final isCompleted = stepIndex < currentIndex;
                  final isCurrent = stepIndex == currentIndex;

                  return Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompleted || isCurrent
                              ? Colors.green
                              : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : Text(
                                  '${stepIndex + 1}',
                                  style: TextStyle(
                                    color: isCurrent
                                        ? Colors.white
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  );
                }
              }),
            ),
          const SizedBox(height: 8),
          if (!isFailed)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _progressSteps.map((status) {
                return SizedBox(
                  width: 50,
                  child: Text(
                    _getShortLabel(status),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[600],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  String _getShortLabel(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.assigned:
        return 'Assigned';
      case DeliveryStatus.pickedUpFromFarm:
        return 'Picked Up';
      case DeliveryStatus.enRoute:
        return 'En Route';
      case DeliveryStatus.nearbyFifteenMin:
        return '15 Min';
      case DeliveryStatus.completed:
        return 'Done';
      case DeliveryStatus.failed:
        return 'Failed';
    }
  }
}
