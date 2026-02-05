import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/delivery.dart';
import '../../models/order_item.dart';
import '../../providers/deliveries_provider.dart';
import '../../providers/delivery_detail_provider.dart';
import '../../widgets/delivery_progress.dart';
import '../../theme/app_theme.dart';
import 'photo_capture_screen.dart';
import 'delivery_completion_screen.dart';

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
    final detailProvider = context.read<DeliveryDetailProvider>();
    setState(() {
      _delivery = deliveriesProvider.getDeliveryById(widget.deliveryId);
    });
    // Load order items
    if (_delivery != null) {
      detailProvider.loadOrderItems(_delivery!.orderId);
    }
  }

  @override
  void dispose() {
    context.read<DeliveryDetailProvider>().clearOrderItems();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    if (_delivery == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Delivery Details'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Delivery Details'),
        actions: [
          _buildStatusChip(_delivery!.status),
          const SizedBox(width: AppTheme.spacingM),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            DeliveryProgress(currentStatus: _delivery!.status),
            const SizedBox(height: AppTheme.spacingL),

            // ETA Card (if active)
            if (_delivery!.status.isActive && _delivery!.estimatedMinutes != null)
              _buildETACard(),

            // Special Instructions Alert
            if (_delivery!.specialInstructions != null &&
                _delivery!.specialInstructions!.isNotEmpty)
              _buildSpecialInstructionsCard(),

            // Pickup Info (if assigned or has pickup address)
            if (_delivery!.status == DeliveryStatus.assigned ||
                _delivery!.pickupAddress != null)
              _buildPickupSection(),

            // Map placeholder
            _buildMapSection(),
            const SizedBox(height: AppTheme.spacingL),

            // Customer info
            _buildCustomerSection(),
            const SizedBox(height: AppTheme.spacingL),

            // Order summary
            _buildOrderSection(currencyFormat),
            const SizedBox(height: AppTheme.spacingL),

            // Requirements badges
            _buildRequirementsBadges(),
            const SizedBox(height: AppTheme.spacingL),

            // Action buttons
            _buildActionButtons(),
            const SizedBox(height: AppTheme.spacingM),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(DeliveryStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              color: status.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildETACard() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingL),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.primaryGreenDark],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingS),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: const Icon(
              Icons.timer,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estimated Arrival',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _delivery!.etaDisplay ?? '-- min',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _showUpdateETADialog,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialInstructionsCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingL),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Special Instructions',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _delivery!.specialInstructions!,
                  style: TextStyle(
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupSection() {
    final hasPickupAddress = _delivery!.pickupAddress != null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingL),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingS),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(
                    Icons.inventory_2,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                const Text(
                  'Pickup Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_delivery!.isPickupConfirmed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingS,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 14, color: AppTheme.success),
                        SizedBox(width: 4),
                        Text(
                          'Picked Up',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasPickupAddress) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Expanded(
                        child: Text(
                          _delivery!.pickupAddress!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    'Pickup location will be provided',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (_delivery!.pickupNotes != null) ...[
                  const SizedBox(height: AppTheme.spacingS),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note_outlined, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: AppTheme.spacingS),
                      Expanded(
                        child: Text(
                          _delivery!.pickupNotes!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_delivery!.scheduledPickupTime != null) ...[
                  const SizedBox(height: AppTheme.spacingS),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: AppTheme.spacingS),
                      Text(
                        'Scheduled: ${DateFormat.jm().format(_delivery!.scheduledPickupTime!)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 48, color: Colors.grey[500]),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    'Map View',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
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
              bottom: AppTheme.spacingM,
              right: AppTheme.spacingM,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: AppTheme.spacingS,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
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
                    Icon(Icons.navigation, size: 16, color: AppTheme.primaryGreen),
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
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingS),
                  decoration: AppTheme.iconContainerDecoration,
                  child: const Icon(
                    Icons.person,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                const Text(
                  'Delivery Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.person,
                  'Customer',
                  _delivery!.customerName,
                ),
                const SizedBox(height: AppTheme.spacingM),
                GestureDetector(
                  onTap: () => _callCustomer(),
                  child: _buildInfoRow(
                    Icons.phone,
                    'Phone',
                    _delivery!.customerPhone,
                    trailing: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingS),
                      decoration: BoxDecoration(
                        color: AppTheme.iconBackground,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: const Icon(
                        Icons.call,
                        color: AppTheme.primaryGreen,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                _buildInfoRow(
                  Icons.location_on,
                  'Address',
                  _delivery!.deliveryAddress,
                ),
                if (_delivery!.deliveryNotes != null &&
                    _delivery!.deliveryNotes!.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingM),
                  _buildInfoRow(
                    Icons.note,
                    'Notes',
                    _delivery!.deliveryNotes!,
                    valueColor: Colors.orange,
                  ),
                ],
              ],
            ),
          ),
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
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: AppTheme.spacingM),
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
    return Consumer<DeliveryDetailProvider>(
      builder: (context, provider, _) {
        final orderItems = provider.orderItems;

        return Container(
          decoration: AppTheme.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingS),
                      decoration: AppTheme.iconContainerDecoration,
                      child: const Icon(
                        Icons.receipt_long,
                        color: AppTheme.primaryGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    const Expanded(
                      child: Text(
                        'Order Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${_delivery!.itemCount} item${_delivery!.itemCount != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Order items list
              if (orderItems.isNotEmpty) ...[
                ...orderItems.map((item) => _buildOrderItemRow(item)),
                const Divider(height: 1),
              ],
              // Summary row
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Order Total',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      currencyFormat.format(_delivery!.totalAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderItemRow(OrderItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[100]!),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quantity badge
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${item.quantity}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                if (item.productDescription != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.productDescription!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (item.notes != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.notes!,
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.formattedPrice,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                item.formattedQuantity,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsBadges() {
    final requirements = <Widget>[];

    if (_delivery!.requiresRefrigeration) {
      requirements.add(_buildBadge(
        Icons.ac_unit,
        'Refrigerated',
        Colors.blue,
      ));
    }

    if (_delivery!.requiresSignature) {
      requirements.add(_buildBadge(
        Icons.draw,
        'Signature Required',
        Colors.purple,
      ));
    }

    if (_delivery!.requiresPhotoProof) {
      requirements.add(_buildBadge(
        Icons.camera_alt,
        'Photo Required',
        Colors.orange,
      ));
    }

    if (requirements.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppTheme.spacingS,
      runSpacing: AppTheme.spacingS,
      children: requirements,
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppTheme.spacingXS),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final status = _delivery!.status;

    return Column(
      children: [
        // Navigate button (always visible for active deliveries)
        if (status.isPending)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openMaps,
              icon: const Icon(Icons.navigation),
              label: const Text('Navigate with Maps'),
              style: AppTheme.outlinedButtonStyle,
            ),
          ),

        // Primary action button based on status
        if (status.buttonTitle != null) ...[
          const SizedBox(height: AppTheme.spacingM),
          Consumer<DeliveryDetailProvider>(
            builder: (context, provider, child) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: provider.isLoading ? null : () => _handlePrimaryAction(),
                  style: AppTheme.primaryButtonStyle,
                  child: provider.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(status.buttonTitle!),
                ),
              );
            },
          ),
        ],

        // Mark as failed button
        if (status.isPending && status != DeliveryStatus.assigned) ...[
          const SizedBox(height: AppTheme.spacingM),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showFailedDialog(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: const BorderSide(color: AppTheme.error),
              ),
              child: const Text('Mark as Failed'),
            ),
          ),
        ],
      ],
    );
  }

  void _handlePrimaryAction() async {
    switch (_delivery!.status) {
      case DeliveryStatus.assigned:
        // Confirm pickup with optional photo
        await _confirmPickup();
        break;
      case DeliveryStatus.pickedUpFromFarm:
        // Start delivery
        await _startDelivery();
        break;
      case DeliveryStatus.enRoute:
        // Mark as nearby
        await _markNearby();
        break;
      case DeliveryStatus.nearbyFifteenMin:
        // Complete delivery - go to completion screen
        await _navigateToCompletion();
        break;
      default:
        break;
    }
  }

  Future<void> _confirmPickup() async {
    // Ask if they want to take a photo
    final takePhoto = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: const Text('Confirm Pickup'),
        content: const Text(
          'Would you like to take a photo of the picked up items?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Take Photo'),
          ),
        ],
      ),
    );

    if (takePhoto == null) return;

    File? photo;
    if (takePhoto) {
      photo = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (context) => const PhotoCaptureScreen(
            title: 'Pickup Photo',
            instruction: 'Take a photo of the items\nyou are picking up',
          ),
        ),
      );

      // User cancelled photo capture
      if (photo == null) return;
    }

    final provider = context.read<DeliveryDetailProvider>();
    final updated = await provider.confirmPickup(_delivery!.id, photo: photo);

    if (updated != null && mounted) {
      setState(() => _delivery = updated);
      context.read<DeliveriesProvider>().updateDeliveryLocally(updated);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup confirmed'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  Future<void> _startDelivery() async {
    final confirmed = await _showConfirmDialog(
      'Start Delivery',
      'Mark as en route to customer?',
    );

    if (confirmed != true) return;

    final provider = context.read<DeliveryDetailProvider>();
    final updated = await provider.startDelivery(_delivery!.id);

    if (updated != null && mounted) {
      setState(() => _delivery = updated);
      context.read<DeliveriesProvider>().updateDeliveryLocally(updated);
    }
  }

  Future<void> _markNearby() async {
    final confirmed = await _showConfirmDialog(
      'Almost There',
      'Mark as 15 minutes away from customer?',
    );

    if (confirmed != true) return;

    final provider = context.read<DeliveryDetailProvider>();
    final updated = await provider.markNearby(_delivery!.id);

    if (updated != null && mounted) {
      setState(() => _delivery = updated);
      context.read<DeliveriesProvider>().updateDeliveryLocally(updated);
    }
  }

  Future<void> _navigateToCompletion() async {
    final updated = await Navigator.push<Delivery>(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryCompletionScreen(delivery: _delivery!),
      ),
    );

    if (updated != null && mounted) {
      setState(() => _delivery = updated);
    }
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _showFailedDialog() async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: const Text('Mark as Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please provide a reason for the failed delivery:',
            ),
            const SizedBox(height: AppTheme.spacingM),
            TextField(
              controller: reasonController,
              decoration: AppTheme.inputDecoration(
                label: 'Reason',
                hint: 'e.g., Customer not available',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text('Mark Failed'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final provider = context.read<DeliveryDetailProvider>();
    final updated = await provider.failDelivery(
      _delivery!.id,
      reason: reasonController.text.trim().isNotEmpty
          ? reasonController.text.trim()
          : null,
    );

    if (updated != null && mounted) {
      setState(() => _delivery = updated);
      context.read<DeliveriesProvider>().updateDeliveryLocally(updated);
    }
  }

  void _showUpdateETADialog() async {
    int? selectedMinutes;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: const Text('Update ETA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select estimated time of arrival:'),
            const SizedBox(height: AppTheme.spacingM),
            Wrap(
              spacing: AppTheme.spacingS,
              runSpacing: AppTheme.spacingS,
              children: [5, 10, 15, 20, 30, 45, 60].map((mins) {
                return ChoiceChip(
                  label: Text(mins < 60 ? '$mins min' : '1 hr'),
                  selected: selectedMinutes == mins,
                  onSelected: (selected) {
                    Navigator.pop(context, mins);
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ).then((mins) async {
      if (mins != null && mins is int) {
        final provider = context.read<DeliveryDetailProvider>();
        final updated = await provider.updateETA(_delivery!.id, mins);

        if (updated != null && mounted) {
          setState(() => _delivery = updated);
          context.read<DeliveriesProvider>().updateDeliveryLocally(updated);
        }
      }
    });
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
}
