import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Introduction',
              'HelloZabiha ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our Driver application.',
            ),
            _buildSection(
              'Information We Collect',
              '''We collect the following types of information:

Personal Information:
• Name and contact information
• Email address and phone number
• Driver's license information
• Vehicle information
• Profile photo

Location Data:
• Real-time GPS location during active deliveries
• Location history for completed deliveries
• Route information

Usage Data:
• App usage patterns
• Delivery performance metrics
• Device information''',
            ),
            _buildSection(
              'How We Use Your Information',
              '''We use the information we collect to:

• Facilitate delivery services
• Track and display your location to customers during deliveries
• Process payments and calculate earnings
• Communicate important updates and notifications
• Improve our services and app functionality
• Ensure safety and security
• Comply with legal obligations''',
            ),
            _buildSection(
              'Location Tracking',
              'We collect your location data only when you are actively on a delivery or have marked yourself as available. You can control location permissions through your device settings. Note that location tracking is required for the core functionality of the delivery service.',
            ),
            _buildSection(
              'Data Sharing',
              '''We may share your information with:

• Customers (limited info such as name, photo, and real-time location during active deliveries)
• Payment processors for earnings disbursement
• Service providers who assist our operations
• Law enforcement when required by law
• Other parties with your consent''',
            ),
            _buildSection(
              'Data Security',
              'We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.',
            ),
            _buildSection(
              'Data Retention',
              'We retain your personal information for as long as your account is active or as needed to provide services. We may retain certain information for legal compliance, dispute resolution, and enforcement of agreements.',
            ),
            _buildSection(
              'Your Rights',
              '''You have the right to:

• Access your personal data
• Correct inaccurate data
• Request deletion of your data
• Opt-out of marketing communications
• Export your data

To exercise these rights, contact us at privacy@hellozabiha.com''',
            ),
            _buildSection(
              'Children\'s Privacy',
              'Our service is not intended for individuals under 18 years of age. We do not knowingly collect personal information from children.',
            ),
            _buildSection(
              'Changes to This Policy',
              'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy in the app and updating the "Last updated" date.',
            ),
            _buildSection(
              'Contact Us',
              '''If you have questions about this Privacy Policy, please contact us:

Email: privacy@hellozabiha.com
Address: HelloZabiha Inc.''',
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
