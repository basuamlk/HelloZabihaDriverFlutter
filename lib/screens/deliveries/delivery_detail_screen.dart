import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/delivery.dart';
import '../../providers/deliveries_provider.dart';
import '../../providers/delivery_detail_provider.dart';
import '../../widgets/delivery_progress.dart';
import '../../widgets/status_badge.dart';

class DeliveryDetailScreen extends StatefulWidget {
  final String deliveryId;

  const DeliveryDetailScreen({
    super.key,
    required this.deliveryId,
  });

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  Delivery? _delivery;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDelivery();
    });
  }

  void _loadDelivery() {
    final deliveriesProvider = context.read<DeliveriesProvider>();
    setState(() {
      _delivery = deliveriesProvider.getDeliveryById(widget.deliveryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    if (_delivery == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Delivery Details'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Delivery Details'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          StatusBadge(status: _delivery!.status),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            DeliveryProgress(currentStatus: _delivery!.status),
            const SizedBox(height: 20),

            // Map placeholder
            _buildMapSection(),
            const SizedBox(height: 20),

            // Customer info
            _buildCustomerSection(),
            const SizedBox(height: 20),

            // Order summary
            _buildOrderSection(currencyFormat),
            const SizedBox(height: 24),

            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Placeholder for map
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 48, color: Colors.grey[500]),
                  const SizedBox(height: 8),
                  Text(
                    'Map View',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            // Tap to open maps overlay
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openMaps(),
                  child: Container(),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.navigation, size: 16, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'Open Maps',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.person,
            'Name',
            _delivery!.customerName,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _callCustomer(),
            child: _buildInfoRow(
              Icons.phone,
              'Phone',
              _delivery!.customerPhone,
              trailing: const Icon(Icons.call, color: Colors.green, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.location_on,
            'Address',
            _delivery!.deliveryAddress,
          ),
          if (_delivery!.deliveryNotes != null &&
              _delivery!.deliveryNotes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.note,
              'Notes',
              _delivery!.deliveryNotes!,
              valueColor: Colors.orange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Widget? trailing,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildOrderSection(NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Items',
                style: TextStyle(color: Colors.grey[600]),
              ),
              Text(
                '${_delivery!.itemCount} item${_delivery!.itemCount != 1 ? 's' : ''}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(color: Colors.grey[600]),
              ),
              Text(
                currencyFormat.format(_delivery!.totalAmount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final status = _delivery!.status;
    final hasNextStatus = status.nextStatus != null;

    return Column(
      children: [
        // Navigate button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _openMaps,
            icon: const Icon(Icons.navigation),
            label: const Text('Navigate with Maps'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        if (hasNextStatus) ...[
          const SizedBox(height: 12),
          Consumer<DeliveryDetailProvider>(
            builder: (context, provider, child) {
              return SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      provider.isLoading ? null : () => _updateStatus(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          status.buttonTitle ?? 'Update Status',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              );
            },
          ),
        ],

        if (status.isPending && status != DeliveryStatus.assigned) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => _markAsFailed(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Mark as Failed',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _openMaps() {
    final provider = context.read<DeliveryDetailProvider>();
    provider.openGoogleMaps(
      _delivery!.deliveryLatitude,
      _delivery!.deliveryLongitude,
      _delivery!.deliveryAddress,
    );
  }

  void _callCustomer() {
    final provider = context.read<DeliveryDetailProvider>();
    provider.callCustomer(_delivery!.customerPhone);
  }

  Future<void> _updateStatus() async {
    final nextStatus = _delivery!.status.nextStatus;
    if (nextStatus == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Status Update'),
        content: Text(
          'Are you sure you want to mark this delivery as "${nextStatus.displayName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final provider = context.read<DeliveryDetailProvider>();
    final updated = await provider.updateStatus(_delivery!, nextStatus);

    if (updated != null && mounted) {
      setState(() {
        _delivery = updated;
      });
      context.read<DeliveriesProvider>().updateDeliveryLocally(updated);
    }
  }

  Future<void> _markAsFailed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Failed'),
        content: const Text(
          'Are you sure you want to mark this delivery as failed? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mark Failed'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final provider = context.read<DeliveryDetailProvider>();
    final updated =
        await provider.updateStatus(_delivery!, DeliveryStatus.failed);

    if (updated != null && mounted) {
      setState(() {
        _delivery = updated;
      });
      context.read<DeliveriesProvider>().updateDeliveryLocally(updated);
    }
  }
}
