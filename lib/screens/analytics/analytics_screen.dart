import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/analytics.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalytics();
    });
  }

  void _loadAnalytics() {
    final auth = context.read<AuthProvider>();
    final driverId = auth.currentUser?.id ?? '';
    context.read<AnalyticsProvider>().loadAnalytics(driverId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Performance Analytics'),
      ),
      body: Consumer<AnalyticsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.analytics == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            );
          }

          return RefreshIndicator(
            color: AppTheme.primaryGreen,
            onRefresh: () async {
              final auth = context.read<AuthProvider>();
              await provider.refresh(auth.currentUser?.id ?? '');
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period selector
                  _buildPeriodSelector(provider),
                  const SizedBox(height: AppTheme.spacingL),

                  // Key metrics
                  _buildKeyMetrics(provider.performance),
                  const SizedBox(height: AppTheme.spacingL),

                  // Performance scores
                  _buildPerformanceScores(provider.performance),
                  const SizedBox(height: AppTheme.spacingL),

                  // Delivery breakdown
                  _buildDeliveryBreakdown(provider.deliveryBreakdown),
                  const SizedBox(height: AppTheme.spacingL),

                  // Daily chart
                  if (provider.dailyStats.isNotEmpty) ...[
                    _buildDailyChart(provider.dailyStats),
                    const SizedBox(height: AppTheme.spacingL),
                  ],

                  // Weekly trends
                  if (provider.weeklyTrends.isNotEmpty) ...[
                    _buildWeeklyTrends(provider.weeklyTrends),
                  ],

                  const SizedBox(height: AppTheme.spacingXL),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector(AnalyticsProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AnalyticsPeriod.values.map((period) {
          final isSelected = provider.selectedPeriod == period;
          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacingS),
            child: ChoiceChip(
              label: Text(period.label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  final auth = context.read<AuthProvider>();
                  provider.setPeriod(period, auth.currentUser?.id ?? '');
                }
              },
              selectedColor: AppTheme.primaryGreen,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKeyMetrics(PerformanceMetrics metrics) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.local_shipping,
            label: 'Total Deliveries',
            value: metrics.totalDeliveries.toString(),
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.timer,
            label: 'Avg. Time',
            value: metrics.avgDeliveryTimeFormatted,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingS),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceScores(PerformanceMetrics metrics) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Scores',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildScoreRow(
            icon: Icons.access_time,
            label: 'On-Time Rate',
            value: metrics.onTimeRateFormatted,
            progress: metrics.onTimeRate,
            color: _getScoreColor(metrics.onTimeRate),
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildScoreRow(
            icon: Icons.check_circle_outline,
            label: 'Completion Rate',
            value: metrics.completionRateFormatted,
            progress: metrics.completionRate,
            color: _getScoreColor(metrics.completionRate),
          ),
          const SizedBox(height: AppTheme.spacingM),
          _buildScoreRow(
            icon: Icons.star_outline,
            label: 'Average Rating',
            value: metrics.ratingFormatted,
            progress: metrics.averageRating / 5,
            color: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow({
    required IconData icon,
    required String label,
    required String value,
    required double progress,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.9) return AppTheme.success;
    if (score >= 0.75) return Colors.amber;
    return AppTheme.error;
  }

  Widget _buildDeliveryBreakdown(DeliveryBreakdown breakdown) {
    if (breakdown.total == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          // Visual bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                if (breakdown.completedPercent > 0)
                  Expanded(
                    flex: (breakdown.completedPercent * 100).round(),
                    child: Container(
                      height: 24,
                      color: AppTheme.success,
                    ),
                  ),
                if (breakdown.failedPercent > 0)
                  Expanded(
                    flex: (breakdown.failedPercent * 100).round(),
                    child: Container(
                      height: 24,
                      color: AppTheme.error,
                    ),
                  ),
                if (breakdown.cancelledPercent > 0)
                  Expanded(
                    flex: (breakdown.cancelledPercent * 100).round(),
                    child: Container(
                      height: 24,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBreakdownItem(
                'Completed',
                breakdown.completed,
                AppTheme.success,
              ),
              _buildBreakdownItem(
                'Failed',
                breakdown.failed,
                AppTheme.error,
              ),
              _buildBreakdownItem(
                'Cancelled',
                breakdown.cancelled,
                Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: AppTheme.spacingXS),
        Text(
          '$label ($count)',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDailyChart(List<DailyStats> stats) {
    final maxDeliveries = stats.map((s) => s.deliveries).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Deliveries',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: stats.map((stat) {
                final height = maxDeliveries > 0
                    ? (stat.deliveries / maxDeliveries) * 120
                    : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          stat.deliveries.toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: height.clamp(4.0, 120.0),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('E').format(stat.date).substring(0, 1),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrends(List<WeeklyTrend> trends) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Trends',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          ...trends.map((trend) => Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    trend.weekLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_shipping,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${trend.deliveries}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Icon(
                        Icons.attach_money,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      Text(
                        currencyFormat.format(trend.earnings),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingS,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getScoreColor(trend.onTimeRate).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${(trend.onTimeRate * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getScoreColor(trend.onTimeRate),
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
