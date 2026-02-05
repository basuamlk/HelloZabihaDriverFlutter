import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';

class PhotoCaptureScreen extends StatefulWidget {
  final String title;
  final String instruction;
  final bool allowGallery;

  const PhotoCaptureScreen({
    super.key,
    required this.title,
    required this.instruction,
    this.allowGallery = false,
  });

  @override
  State<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends State<PhotoCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _capturedPhoto;
  bool _isCapturing = false;

  Future<void> _takePhoto() async {
    setState(() => _isCapturing = true);

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (photo != null) {
        setState(() {
          _capturedPhoto = File(photo.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to access camera'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (photo != null) {
        setState(() {
          _capturedPhoto = File(photo.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to access gallery'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedPhoto = null;
    });
  }

  void _confirmPhoto() {
    if (_capturedPhoto != null) {
      Navigator.pop(context, _capturedPhoto);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _capturedPhoto == null
                ? _buildCaptureView()
                : _buildPreviewView(),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildCaptureView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: AppTheme.iconBackground,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Icon(
            Icons.camera_alt_outlined,
            size: 80,
            color: AppTheme.primaryGreen.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
        Text(
          widget.instruction,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXL),
        if (_isCapturing)
          const CircularProgressIndicator(color: AppTheme.primaryGreen)
        else
          Column(
            children: [
              ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
                style: AppTheme.primaryButtonStyle.copyWith(
                  minimumSize: WidgetStatePropertyAll(
                    Size(MediaQuery.of(context).size.width * 0.7, 56),
                  ),
                ),
              ),
              if (widget.allowGallery) ...[
                const SizedBox(height: AppTheme.spacingM),
                TextButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose from Gallery'),
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildPreviewView() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              child: Image.file(
                _capturedPhoto!,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppTheme.success,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingS),
              const Expanded(
                child: Text(
                  'Photo captured successfully',
                  style: TextStyle(
                    color: AppTheme.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: _retakePhoto,
                child: const Text('Retake'),
              ),
            ],
          ),
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
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: ElevatedButton(
                onPressed: _capturedPhoto != null ? _confirmPhoto : null,
                style: AppTheme.primaryButtonStyle,
                child: const Text('Confirm'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
