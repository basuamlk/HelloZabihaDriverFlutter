import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/delivery.dart';
import '../../providers/delivery_detail_provider.dart';
import '../../providers/deliveries_provider.dart';
import '../../theme/app_theme.dart';
import 'photo_capture_screen.dart';
import 'signature_capture_screen.dart';

class DeliveryCompletionScreen extends StatefulWidget {
  final Delivery delivery;

  const DeliveryCompletionScreen({
    super.key,
    required this.delivery,
  });

  @override
  State<DeliveryCompletionScreen> createState() => _DeliveryCompletionScreenState();
}

class _DeliveryCompletionScreenState extends State<DeliveryCompletionScreen> {
  File? _deliveryPhoto;
  File? _signatureImage;
  String? _recipientName;
  bool _isSubmitting = false;

  Future<void> _captureDeliveryPhoto() async {
    final photo = await Navigator.push<File>(
      context,
      MaterialPageRoute(
        builder: (context) => const PhotoCaptureScreen(
          title: 'Delivery Photo',
          instruction: 'Take a photo of the delivered items\nat the customer\'s location',
        ),
      ),
    );

    if (photo != null) {
      setState(() {
        _deliveryPhoto = photo;
      });
    }
  }

  Future<void> _captureSignature() async {
    final result = await Navigator.push<SignatureResult>(
      context,
      MaterialPageRoute(
        builder: (context) => SignatureCaptureScreen(
          recipientName: _recipientName ?? widget.delivery.customerName,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _signatureImage = result.signatureImage;
        _recipientName = result.recipientName;
      });
    }
  }

  Future<void> _submitCompletion() async {
    if (_deliveryPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take a delivery photo'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = context.read<DeliveryDetailProvider>();
    final updated = await provider.completeDelivery(
      widget.delivery.id,
      deliveryPhoto: _deliveryPhoto!,
      signatureImage: _signatureImage,
      recipientName: _recipientName,
    );

    setState(() => _isSubmitting = false);

    if (updated != null && mounted) {
      context.read<DeliveriesProvider>().updateDeliveryLocally(updated);

      // Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppTheme.success,
                  size: 48,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              const Text(
                'Delivery Completed!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                'Order delivered to ${widget.delivery.customerName}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, updated); // Return to detail screen
                },
                style: AppTheme.primaryButtonStyle,
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to complete delivery'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Complete Delivery'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Summary
            _buildCustomerSummary(),
            const SizedBox(height: AppTheme.spacingL),

            // Delivery Photo Section
            _buildSectionHeader(
              'Delivery Photo',
              subtitle: 'Required',
              isComplete: _deliveryPhoto != null,
            ),
            const SizedBox(height: AppTheme.spacingM),
            _buildPhotoSection(),
            const SizedBox(height: AppTheme.spacingL),

            // Signature Section
            _buildSectionHeader(
              'Recipient Signature',
              subtitle: widget.delivery.requiresSignature ? 'Required' : 'Optional',
              isComplete: _signatureImage != null,
            ),
            const SizedBox(height: AppTheme.spacingM),
            _buildSignatureSection(),
            const SizedBox(height: AppTheme.spacingXL),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitCompletion,
                style: AppTheme.primaryButtonStyle,
                child: _isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: AppTheme.spacingM),
                          Text('Completing...'),
                        ],
                      )
                    : const Text('Complete Delivery'),
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSummary() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: AppTheme.iconContainerDecoration,
            child: const Icon(
              Icons.person,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.delivery.customerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.delivery.deliveryAddress,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? subtitle, bool isComplete = false}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: AppTheme.spacingS),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingS,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: isComplete
                  ? AppTheme.success.withValues(alpha: 0.15)
                  : AppTheme.inputFill,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Text(
              isComplete ? 'Done' : subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isComplete ? AppTheme.success : AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoSection() {
    if (_deliveryPhoto != null) {
      return Container(
        decoration: AppTheme.cardDecoration,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.file(
                _deliveryPhoto!,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.success,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  const Expanded(
                    child: Text(
                      'Photo captured',
                      style: TextStyle(
                        color: AppTheme.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _captureDeliveryPhoto,
                    child: const Text('Retake'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: _captureDeliveryPhoto,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: AppTheme.inputBorder,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: AppTheme.iconBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_a_photo,
                  color: AppTheme.primaryGreen,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              const Text(
                'Tap to take delivery photo',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignatureSection() {
    if (_signatureImage != null) {
      return Container(
        decoration: AppTheme.cardDecoration,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusLarge),
                ),
              ),
              child: Image.file(
                _signatureImage!,
                height: 100,
                fit: BoxFit.contain,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.success,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Signature captured',
                          style: TextStyle(
                            color: AppTheme.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_recipientName != null)
                          Text(
                            'By: $_recipientName',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _captureSignature,
                    child: const Text('Redo'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: _captureSignature,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: AppTheme.inputBorder,
            width: 2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: AppTheme.iconBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.draw,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              const Text(
                'Tap to capture signature',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
