import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/delivery.dart';
import '../../providers/delivery_offer_provider.dart';
import '../../theme/app_theme.dart';

class DeliveryOfferScreen extends StatefulWidget {
  const DeliveryOfferScreen({super.key});

  @override
  State<DeliveryOfferScreen> createState() => _DeliveryOfferScreenState();
}

class _DeliveryOfferScreenState extends State<DeliveryOfferScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryOfferProvider>().setOfferScreenShowing(true);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: Consumer<DeliveryOfferProvider>(
          builder: (context, provider, child) {
            // Auto-dismiss if offer is gone
            if (!provider.hasActiveOffer && !provider.isResponding) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  provider.setOfferScreenShowing(false);
                  Navigator.of(context).pop();
                }
              });
              return const Center(
                child: Text(
                  'Offer expired',
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              );
            }

            final delivery = provider.currentOfferDelivery;
            if (delivery == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Header
                  const Text(
                    'NEW DELIVERY OFFER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Countdown timer
                  _buildCountdownTimer(provider),
                  const SizedBox(height: 24),

                  // Delivery details
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildDeliveryDetails(delivery),
                    ),
                  ),

                  // Action buttons
                  _buildActionButtons(context, provider),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCountdownTimer(DeliveryOfferProvider provider) {
    final isUrgent = provider.remainingSeconds < 60;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = isUrgent ? 1.0 + (_pulseController.value * 0.05) : 1.0;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: CircularProgressIndicator(
                    value: provider.countdownProgress,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isUrgent ? Colors.red : AppTheme.primaryGreen,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer,
                      color: isUrgent ? Colors.red : Colors.white70,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.countdownDisplay,
                      style: TextStyle(
                        color: isUrgent ? Colors.red : Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeliveryDetails(Delivery delivery) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pickup
          _buildDetailRow(
            icon: Icons.store,
            iconColor: AppTheme.primaryGreen,
            label: 'PICKUP',
            value: delivery.pickupAddress ?? 'HelloZabiha Farm',
          ),
          const Divider(color: Colors.white12, height: 24),

          // Delivery address
          _buildDetailRow(
            icon: Icons.location_on,
            iconColor: Colors.redAccent,
            label: 'DELIVER TO',
            value: delivery.deliveryAddress,
          ),
          const Divider(color: Colors.white12, height: 24),

          // Customer
          _buildDetailRow(
            icon: Icons.person,
            iconColor: Colors.blueAccent,
            label: 'CUSTOMER',
            value: delivery.customerName,
          ),
          const Divider(color: Colors.white12, height: 24),

          // Order summary
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.inventory_2,
                label: '${delivery.itemCount} items',
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                icon: Icons.attach_money,
                label: currencyFormat.format(delivery.totalAmount),
              ),
              if (delivery.requiresRefrigeration) ...[
                const SizedBox(width: 12),
                _buildInfoChip(
                  icon: Icons.ac_unit,
                  label: 'Cold',
                  color: Colors.lightBlueAccent,
                ),
              ],
            ],
          ),

          // Special instructions
          if (delivery.specialInstructions != null &&
              delivery.specialInstructions!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      delivery.specialInstructions!,
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Signature requirement
          if (delivery.requiresSignature) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.draw, color: Colors.orange.shade300, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Signature required',
                  style: TextStyle(color: Colors.orange.shade300, fontSize: 13),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color color = Colors.white70,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, DeliveryOfferProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Error message
          if (provider.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                provider.errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),

          // Accept button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: provider.isResponding
                  ? null
                  : () async {
                      final success = await provider.acceptOffer();
                      if (success && mounted) {
                        provider.setOfferScreenShowing(false);
                        Navigator.of(context).pop(true);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                elevation: 4,
              ),
              child: provider.isResponding
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'ACCEPT ORDER',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Decline button
          TextButton(
            onPressed: provider.isResponding
                ? null
                : () async {
                    final success = await provider.declineOffer();
                    if (success && mounted) {
                      provider.setOfferScreenShowing(false);
                      Navigator.of(context).pop(false);
                    }
                  },
            child: Text(
              'Decline',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
