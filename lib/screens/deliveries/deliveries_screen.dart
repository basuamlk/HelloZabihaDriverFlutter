import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/deliveries_provider.dart';
import '../../widgets/delivery_row.dart';
import 'delivery_detail_screen.dart';

class DeliveriesScreen extends StatefulWidget {
  const DeliveriesScreen({super.key});

  @override
  State<DeliveriesScreen> createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends State<DeliveriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveriesProvider>().loadDeliveries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Deliveries'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<DeliveriesProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Filter tabs
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: DeliveryFilter.values.map((filter) {
                    final isSelected = provider.currentFilter == filter;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(_getFilterLabel(filter)),
                          selected: isSelected,
                          onSelected: (_) => provider.setFilter(filter),
                          selectedColor: Colors.green,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Deliveries list
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.deliveries.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: provider.refresh,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: provider.deliveries.length,
                              itemBuilder: (context, index) {
                                final delivery = provider.deliveries[index];
                                return DeliveryRow(
                                  delivery: delivery,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DeliveryDetailScreen(
                                          deliveryId: delivery.id,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getFilterLabel(DeliveryFilter filter) {
    switch (filter) {
      case DeliveryFilter.all:
        return 'All';
      case DeliveryFilter.pending:
        return 'Pending';
      case DeliveryFilter.completed:
        return 'Completed';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Deliveries',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new deliveries',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
