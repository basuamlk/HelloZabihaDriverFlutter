import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/home_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/delivery_row.dart';
import '../../widgets/status_badge.dart';
import '../deliveries/delivery_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().loadData();
      context.read<HomeProvider>().requestLocationPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('HelloZabiha Driver'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.recentDeliveries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  _buildStatusCard(provider),
                  const SizedBox(height: 20),

                  // Statistics Grid
                  _buildStatsGrid(provider, currencyFormat),
                  const SizedBox(height: 20),

                  // Active Delivery
                  if (provider.activeDelivery != null) ...[
                    _buildSectionTitle('Active Delivery'),
                    const SizedBox(height: 12),
                    _buildActiveDeliveryCard(provider, currencyFormat),
                    const SizedBox(height: 20),
                  ],

                  // Assigned Deliveries
                  if (provider.assignedDeliveries.isNotEmpty) ...[
                    _buildSectionTitle(
                      'Assigned Deliveries (${provider.assignedDeliveries.length})',
                    ),
                    const SizedBox(height: 12),
                    ...provider.assignedDeliveries.map(
                      (delivery) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DeliveryRow(
                          delivery: delivery,
                          onTap: () => _navigateToDetail(delivery.id),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Recent Deliveries
                  if (provider.recentDeliveries.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle('Recent Deliveries'),
                        TextButton(
                          onPressed: () {
                            // Navigate to deliveries tab
                            DefaultTabController.of(context).animateTo(1);
                          },
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...provider.recentDeliveries.take(5).map(
                          (delivery) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: DeliveryRow(
                              delivery: delivery,
                              onTap: () => _navigateToDetail(delivery.id),
                            ),
                          ),
                        ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(HomeProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade600,
            Colors.green.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${provider.driverName}!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        provider.isAvailable
                            ? Icons.check_circle
                            : Icons.pause_circle_filled,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        provider.isAvailable ? 'Available' : 'Offline',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: provider.isAvailable,
                onChanged: (_) => provider.toggleAvailability(),
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.white30,
              ),
            ],
          ),
          if (provider.isTracking) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.lightGreenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Location tracking active',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsGrid(HomeProvider provider, NumberFormat currencyFormat) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        StatCard(
          title: "Today's Deliveries",
          value: provider.todayDeliveries.toString(),
          icon: Icons.inventory_2,
          color: Colors.blue,
        ),
        StatCard(
          title: 'Pending',
          value: provider.pendingDeliveries.toString(),
          icon: Icons.access_time,
          color: Colors.orange,
        ),
        StatCard(
          title: "Today's Earnings",
          value: currencyFormat.format(provider.todayEarnings),
          icon: Icons.attach_money,
          color: Colors.green,
        ),
        StatCard(
          title: 'Rating',
          value: provider.rating.toStringAsFixed(1),
          icon: Icons.star,
          color: Colors.amber,
        ),
      ],
    );
  }

  Widget _buildActiveDeliveryCard(
    HomeProvider provider,
    NumberFormat currencyFormat,
  ) {
    final delivery = provider.activeDelivery!;

    return GestureDetector(
      onTap: () => _navigateToDetail(delivery.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'In Progress',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                const Spacer(),
                StatusBadge(status: delivery.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              delivery.customerName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              delivery.deliveryAddress,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${delivery.itemCount} items',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                const SizedBox(width: 12),
                Text(
                  currencyFormat.format(delivery.totalAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  void _navigateToDetail(String deliveryId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryDetailScreen(deliveryId: deliveryId),
      ),
    );
  }
}
