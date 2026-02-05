import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import '../../theme/app_theme.dart';

class SignatureCaptureScreen extends StatefulWidget {
  final String? recipientName;

  const SignatureCaptureScreen({
    super.key,
    this.recipientName,
  });

  @override
  State<SignatureCaptureScreen> createState() => _SignatureCaptureScreenState();
}

class SignatureResult {
  final File signatureImage;
  final String recipientName;

  SignatureResult({
    required this.signatureImage,
    required this.recipientName,
  });
}

class _SignatureCaptureScreenState extends State<SignatureCaptureScreen> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
    exportPenColor: Colors.black,
  );

  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.recipientName != null) {
      _nameController.text = widget.recipientName!;
    }
  }

  @override
  void dispose() {
    _signatureController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _clearSignature() {
    _signatureController.clear();
  }

  Future<void> _saveSignature() async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a signature'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter recipient name'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final Uint8List? signatureBytes = await _signatureController.toPngBytes();
      if (signatureBytes == null) {
        throw Exception('Failed to export signature');
      }

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/signature_$timestamp.png');
      await file.writeAsBytes(signatureBytes);

      if (mounted) {
        Navigator.pop(
          context,
          SignatureResult(
            signatureImage: file,
            recipientName: _nameController.text.trim(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save signature'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Capture Signature'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _clearSignature,
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: AppTheme.spacingM),

          // Recipient Name Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
            child: TextField(
              controller: _nameController,
              decoration: AppTheme.inputDecoration(
                label: 'Recipient Name',
                hint: 'Enter name of person receiving delivery',
                prefixIcon: const Icon(Icons.person_outline),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ),

          const SizedBox(height: AppTheme.spacingM),

          // Instructions
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
            child: Row(
              children: [
                Icon(Icons.gesture, color: AppTheme.textSecondary, size: 20),
                SizedBox(width: AppTheme.spacingS),
                Text(
                  'Sign below to confirm delivery receipt',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacingM),

          // Signature Pad
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(color: AppTheme.inputBorder, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge - 2),
                child: Signature(
                  controller: _signatureController,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacingS),

          // Hint text
          const Text(
            'Draw signature with your finger',
            style: TextStyle(
              color: AppTheme.textHint,
              fontSize: 12,
            ),
          ),

          // Bottom Actions
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: AppTheme.outlinedButtonStyle,
                child: const Text('Skip'),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveSignature,
                style: AppTheme.primaryButtonStyle,
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Confirm'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
