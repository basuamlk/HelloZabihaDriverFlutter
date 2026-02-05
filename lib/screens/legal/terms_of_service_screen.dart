import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Agreement to Terms',
              'By accessing or using the HelloZabiha Driver application, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the application.',
            ),
            _buildSection(
              'Driver Requirements',
              '''To use the HelloZabiha Driver app, you must:

• Be at least 18 years of age
• Possess a valid driver's license
• Have access to a reliable vehicle
• Maintain valid auto insurance
• Pass any required background checks
• Comply with all local, state, and federal laws''',
            ),
            _buildSection(
              'Service Description',
              'HelloZabiha Driver is a platform that connects delivery drivers with customers ordering halal meat products. As a driver, you are responsible for picking up orders from designated locations and delivering them to customers in a timely and professional manner.',
            ),
            _buildSection(
              'Your Responsibilities',
              '''As a HelloZabiha driver, you agree to:

• Maintain the cold chain for all refrigerated products
• Handle all products with care and professionalism
• Deliver orders within the estimated timeframes
• Communicate professionally with customers
• Follow all food safety guidelines
• Keep your vehicle clean and suitable for food delivery
• Accurately report delivery status updates''',
            ),
            _buildSection(
              'Payment Terms',
              'Payment for completed deliveries will be processed according to the payment schedule and rates communicated to you through the app. HelloZabiha reserves the right to adjust payment rates with prior notice.',
            ),
            _buildSection(
              'Termination',
              'HelloZabiha reserves the right to suspend or terminate your access to the Driver app at any time for violation of these terms, poor performance, or any other reason at our sole discretion.',
            ),
            _buildSection(
              'Limitation of Liability',
              'HelloZabiha shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of or inability to use the service.',
            ),
            _buildSection(
              'Changes to Terms',
              'We may modify these Terms of Service at any time. Continued use of the app after changes constitutes acceptance of the new terms.',
            ),
            _buildSection(
              'Contact Us',
              'If you have questions about these Terms of Service, please contact us at support@hellozabiha.com',
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'Last updated: February 2026',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXL),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
