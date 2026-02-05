import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/driver.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'edit_profile_screen.dart';
import '../earnings/earnings_screen.dart';
import '../history/delivery_history_screen.dart';
import '../support/help_center_screen.dart';
import '../analytics/analytics_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfile();
    });
  }

  void _navigateToEditProfile(Driver driver) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(driver: driver),
      ),
    );

    if (result == true && mounted) {
      context.read<ProfileProvider>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.driver == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            );
          }

          final driver = provider.driver;
          if (driver == null) {
            return const Center(child: Text('Failed to load profile'));
          }

          return RefreshIndicator(
            color: AppTheme.primaryGreen,
            onRefresh: provider.refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Profile Header
                  _buildProfileHeader(driver),

                  const SizedBox(height: AppTheme.spacingM),

                  // Profile Completion Banner (if incomplete)
                  if (!driver.isProfileComplete)
                    _buildCompletionBanner(driver),

                  // Statistics Card
                  _buildStatisticsCard(
                    driver.totalDeliveries,
                    provider.weeklyDeliveries,
                    provider.monthlyDeliveries,
                  ),

                  const SizedBox(height: AppTheme.spacingM),

                  // Menu Items
                  _buildMenuSection([
                    _MenuItem(
                      icon: Icons.person_outline,
                      title: 'Personal Info',
                      subtitle: driver.name,
                      onTap: () => _navigateToEditProfile(driver),
                    ),
                    _MenuItem(
                      icon: Icons.phone_outlined,
                      title: 'Phone',
                      subtitle: driver.phone.isNotEmpty ? driver.phone : 'Add phone number',
                      onTap: () => _navigateToEditProfile(driver),
                    ),
                  ]),

                  const SizedBox(height: AppTheme.spacingM),

                  // Vehicle Info
                  _buildMenuSection([
                    _MenuItem(
                      icon: Icons.directions_car_outlined,
                      title: 'Vehicle Type',
                      subtitle: driver.vehicleType?.displayName ?? 'Not configured',
                      onTap: () => _navigateToEditProfile(driver),
                    ),
                    _MenuItem(
                      icon: Icons.directions_car,
                      title: 'Vehicle Model',
                      subtitle: driver.vehicleModel ?? 'Not set',
                      onTap: () => _navigateToEditProfile(driver),
                    ),
                    _MenuItem(
                      icon: Icons.badge_outlined,
                      title: 'License Plate',
                      subtitle: driver.licensePlate ?? 'Not set',
                      onTap: () => _navigateToEditProfile(driver),
                    ),
                  ]),

                  const SizedBox(height: AppTheme.spacingM),

                  // Capacity Info
                  _buildMenuSection([
                    _MenuItem(
                      icon: Icons.inventory_2_outlined,
                      title: 'Cargo Capacity',
                      subtitle: '${driver.effectiveCapacity.toStringAsFixed(0)} cu ft',
                      onTap: () => _navigateToEditProfile(driver),
                    ),
                    _MenuItem(
                      icon: Icons.fitness_center_outlined,
                      title: 'Max Weight',
                      subtitle: '${driver.effectiveMaxWeight.toStringAsFixed(0)} lbs',
                      onTap: () => _navigateToEditProfile(driver),
                    ),
                    _MenuItem(
                      icon: Icons.local_shipping_outlined,
                      title: 'Max Deliveries/Run',
                      subtitle: '${driver.effectiveMaxDeliveries} deliveries',
                      onTap: () => _navigateToEditProfile(driver),
                    ),
                    _MenuItem(
                      icon: Icons.ac_unit,
                      title: 'Cold Storage',
                      subtitle: driver.canHandleRefrigerated
                          ? (driver.hasRefrigeration ? 'Refrigeration unit' : 'Cooler/Ice chest')
                          : 'Not available',
                      onTap: () => _navigateToEditProfile(driver),
                    ),
                  ]),

                  const SizedBox(height: AppTheme.spacingM),

                  _buildMenuSection([
                    _MenuItem(
                      icon: Icons.attach_money,
                      title: 'Earnings',
                      subtitle: 'View your earnings and payouts',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EarningsScreen()),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.history,
                      title: 'Delivery History',
                      subtitle: 'View past deliveries',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DeliveryHistoryScreen()),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.analytics_outlined,
                      title: 'Analytics',
                      subtitle: 'Performance metrics and trends',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.help_outline,
                      title: 'Help Center',
                      subtitle: 'FAQs, Contact Support',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      subtitle: 'Theme, preferences',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      },
                    ),
                  ]),

                  const SizedBox(height: AppTheme.spacingL),

                  // Sign Out Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
                    child: _buildSignOutButton(),
                  ),

                  const SizedBox(height: AppTheme.spacingS),

                  // App Version
                  const Text(
                    'App Version 1.0.0',
                    style: TextStyle(
                      color: AppTheme.textHint,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacingXL),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final provider = context.read<ProfileProvider>();
    final hasExistingPhoto = provider.driver?.profilePhotoUrl != null;

    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppTheme.primaryGreen),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppTheme.primaryGreen),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              if (hasExistingPhoto)
                ListTile(
                  leading: const Icon(Icons.delete, color: AppTheme.error),
                  title: const Text('Remove Photo'),
                  onTap: () => Navigator.pop(context, 'remove'),
                ),
            ],
          ),
        ),
      ),
    );

    if (result == null || !mounted) return;

    if (result == 'remove') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove Photo'),
          content: const Text('Are you sure you want to remove your profile photo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              child: const Text('Remove'),
            ),
          ],
        ),
      );

      if (confirm == true && mounted) {
        await provider.deleteProfilePhoto();
      }
      return;
    }

    final source = result == 'camera' ? ImageSource.camera : ImageSource.gallery;
    final image = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image != null && mounted) {
      await provider.uploadProfilePhoto(File(image.path));
    }
  }

  Widget _buildProfileHeader(Driver driver) {
    final initial = driver.name.isNotEmpty ? driver.name[0].toUpperCase() : 'D';
    final hasPhoto = driver.profilePhotoUrl != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingL),
      color: AppTheme.primaryGreen,
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickAndUploadPhoto,
            child: Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 3,
                    ),
                    image: hasPhoto
                        ? DecorationImage(
                            image: NetworkImage(driver.profilePhotoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: hasPhoto
                      ? null
                      : Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            driver.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            driver.email,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (driver.rating != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingM,
                    vertical: AppTheme.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        driver.rating!.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
              ],
              if (driver.vehicleType != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingM,
                    vertical: AppTheme.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_car, color: Colors.white, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        driver.vehicleType!.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionBanner(Driver driver) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete Your Profile',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Add vehicle info to receive delivery assignments',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _navigateToEditProfile(driver),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(int total, int weekly, int monthly) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem('Total', total.toString(), AppTheme.primaryGreen),
          ),
          Container(width: 1, height: 40, color: AppTheme.inputBorder),
          Expanded(
            child: _buildStatItem('This Week', weekly.toString(), Colors.blue),
          ),
          Container(width: 1, height: 40, color: AppTheme.inputBorder),
          Expanded(
            child: _buildStatItem('This Month', monthly.toString(), Colors.purple),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(List<_MenuItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return Column(
            children: [
              _buildMenuItem(item),
              if (!isLast)
                const Divider(height: 1, indent: 72),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItem(_MenuItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: AppTheme.iconContainerDecoration,
              child: Icon(
                item.icon,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        return InkWell(
          onTap: auth.isLoading
              ? null
              : () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      ),
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
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
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await auth.signOut();
                  }
                },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
                SizedBox(width: AppTheme.spacingS),
                Text(
                  'Sign Out',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
