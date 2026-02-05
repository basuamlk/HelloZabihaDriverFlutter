import 'package:flutter/material.dart';
import '../models/delivery.dart';
import '../theme/app_theme.dart';

class DeliveryProgress extends StatelessWidget {
  final DeliveryStatus currentStatus;
  final bool showLabels;
  final bool compact;

  const DeliveryProgress({
    super.key,
    required this.currentStatus,
    this.showLabels = true,
    this.compact = false,
  });

  static const List<_ProgressStep> _steps = [
    _ProgressStep(
      status: DeliveryStatus.assigned,
      icon: Icons.assignment,
      label: 'Assigned',
    ),
    _ProgressStep(
      status: DeliveryStatus.pickedUpFromFarm,
      icon: Icons.inventory_2,
      label: 'Picked Up',
    ),
    _ProgressStep(
      status: DeliveryStatus.enRoute,
      icon: Icons.local_shipping,
      label: 'En Route',
    ),
    _ProgressStep(
      status: DeliveryStatus.completed,
      icon: Icons.check_circle,
      label: 'Delivered',
    ),
  ];

  int get _currentStepIndex {
    if (currentStatus == DeliveryStatus.failed) return -1;
    if (currentStatus == DeliveryStatus.nearbyFifteenMin) return 2; // Same as en route

    for (int i = 0; i < _steps.length; i++) {
      if (_steps[i].status == currentStatus) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isFailed = currentStatus == DeliveryStatus.failed;

    return Container(
      padding: EdgeInsets.all(compact ? AppTheme.spacingM : AppTheme.spacingM),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingS),
                    decoration: AppTheme.iconContainerDecoration,
                    child: Icon(
                      Icons.timeline,
                      color: AppTheme.primaryGreen,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  const Text(
                    'Delivery Progress',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (currentStatus.isActive)
                    _buildStatusPill(),
                ],
              ),
            ),

          if (isFailed)
            _buildFailedState()
          else
            _buildProgressSteps(),
        ],
      ),
    );
  }

  Widget _buildStatusPill() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 8,
            height: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingXS),
          const Text(
            'Active',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cancel,
                color: AppTheme.error,
                size: 32,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            const Text(
              'Delivery Failed',
              style: TextStyle(
                color: AppTheme.error,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSteps() {
    final currentIndex = _currentStepIndex;

    return Column(
      children: [
        // Progress bar with steps
        Row(
          children: List.generate(_steps.length * 2 - 1, (index) {
            if (index.isOdd) {
              // Connector line
              final stepIndex = index ~/ 2;
              final isCompleted = stepIndex < currentIndex;

              return Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppTheme.primaryGreen
                        : AppTheme.inputBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            } else {
              // Step circle
              final stepIndex = index ~/ 2;
              final step = _steps[stepIndex];
              final isCompleted = stepIndex < currentIndex;
              final isCurrent = stepIndex == currentIndex;

              return _buildStepCircle(
                step: step,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
              );
            }
          }),
        ),

        // Labels
        if (showLabels) ...[
          const SizedBox(height: AppTheme.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _steps.map((step) {
              final stepIndex = _steps.indexOf(step);
              final isCompleted = stepIndex < currentIndex;
              final isCurrent = stepIndex == currentIndex;

              return SizedBox(
                width: compact ? 50 : 60,
                child: Column(
                  children: [
                    Text(
                      step.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: compact ? 9 : 10,
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                        color: isCompleted || isCurrent
                            ? AppTheme.primaryGreen
                            : AppTheme.textSecondary,
                      ),
                    ),
                    if (isCurrent && currentStatus == DeliveryStatus.nearbyFifteenMin) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '15 min',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildStepCircle({
    required _ProgressStep step,
    required bool isCompleted,
    required bool isCurrent,
  }) {
    final size = compact ? 28.0 : 36.0;
    final iconSize = compact ? 14.0 : 18.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isCompleted || isCurrent
            ? AppTheme.primaryGreen
            : AppTheme.inputFill,
        shape: BoxShape.circle,
        border: Border.all(
          color: isCompleted || isCurrent
              ? AppTheme.primaryGreen
              : AppTheme.inputBorder,
          width: 2,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: isCompleted
            ? Icon(
                Icons.check,
                color: Colors.white,
                size: iconSize,
              )
            : Icon(
                step.icon,
                color: isCurrent ? Colors.white : AppTheme.textSecondary,
                size: iconSize,
              ),
      ),
    );
  }
}

class _ProgressStep {
  final DeliveryStatus status;
  final IconData icon;
  final String label;

  const _ProgressStep({
    required this.status,
    required this.icon,
    required this.label,
  });
}
