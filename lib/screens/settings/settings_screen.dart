import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/home_provider.dart';
import '../../providers/deliveries_provider.dart';
import '../../services/dev_mode_service.dart';
import '../../theme/app_theme.dart';
import '../legal/terms_of_service_screen.dart';
import '../legal/privacy_policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDevMode = false;
  bool _isGenerating = false;
  String? _devModeMessage;

  @override
  void initState() {
    super.initState();
    _isDevMode = DevModeService.instance.isDevMode;
  }

  Future<void> _toggleDevMode(bool value) async {
    await DevModeService.instance.setDevMode(value);
    setState(() {
      _isDevMode = value;
      _devModeMessage = value ? 'Dev mode enabled' : 'Dev mode disabled';
    });
    _showSnackBar(_devModeMessage!);
  }

  Future<void> _generateMockDeliveries() async {
    setState(() => _isGenerating = true);
    final count = await DevModeService.instance.generateMockDeliveries(count: 5);
    setState(() => _isGenerating = false);

    // Refresh providers to show new data
    if (mounted) {
      context.read<HomeProvider>().refresh();
      context.read<DeliveriesProvider>().loadDeliveries();
    }

    _showSnackBar('Created $count mock deliveries');
  }

  Future<void> _generateCompletedDeliveries() async {
    setState(() => _isGenerating = true);
    final count = await DevModeService.instance.generateCompletedDeliveries(count: 10);
    setState(() => _isGenerating = false);

    // Refresh providers to show new data
    if (mounted) {
      context.read<HomeProvider>().refresh();
      context.read<DeliveriesProvider>().loadDeliveries();
    }

    _showSnackBar('Created $count completed deliveries for earnings history');
  }

  Future<void> _clearMockData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will delete all deliveries assigned to you. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isGenerating = true);
      final count = await DevModeService.instance.clearMockData();
      setState(() => _isGenerating = false);

      // Refresh the providers to update UI
      if (mounted) {
        context.read<HomeProvider>().refresh();
        context.read<DeliveriesProvider>().loadDeliveries();
      }

      _showSnackBar('Deleted $count deliveries');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        children: [
          // Appearance section
          _buildSectionHeader(context, 'Appearance'),
          _buildAppearanceCard(context),

          const SizedBox(height: AppTheme.spacingL),

          // Developer section
          _buildSectionHeader(context, 'Developer'),
          _buildDevModeCard(context),

          const SizedBox(height: AppTheme.spacingL),

          // About section
          _buildSectionHeader(context, 'About'),
          _buildAboutCard(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppTheme.spacingS,
        bottom: AppTheme.spacingS,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.darkTextSecondary
              : AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildAppearanceCard(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildThemeOption(
                context,
                'Light',
                Icons.light_mode,
                ThemeMode.light,
                themeProvider,
              ),
              const Divider(height: 1),
              _buildThemeOption(
                context,
                'Dark',
                Icons.dark_mode,
                ThemeMode.dark,
                themeProvider,
              ),
              const Divider(height: 1),
              _buildThemeOption(
                context,
                'System',
                Icons.settings_brightness,
                ThemeMode.system,
                themeProvider,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String label,
    IconData icon,
    ThemeMode mode,
    ThemeProvider themeProvider,
  ) {
    final isSelected = themeProvider.themeMode == mode;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryGreen : null,
      ),
      title: Text(label),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppTheme.primaryGreen)
          : null,
      onTap: () => themeProvider.setThemeMode(mode),
    );
  }

  Widget _buildDevModeCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Dev mode toggle
          SwitchListTile(
            secondary: Icon(
              Icons.developer_mode,
              color: _isDevMode ? Colors.orange : null,
            ),
            title: const Text('Developer Mode'),
            subtitle: const Text('Enable mock data generation'),
            value: _isDevMode,
            activeTrackColor: Colors.orange.withValues(alpha: 0.5),
            activeThumbColor: Colors.orange,
            onChanged: _toggleDevMode,
          ),

          // Show dev options only when enabled
          if (_isDevMode) ...[
            const Divider(height: 1),
            // Generate active deliveries
            ListTile(
              leading: _isGenerating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_circle_outline, color: Colors.blue),
              title: const Text('Generate Active Deliveries'),
              subtitle: const Text('Create 5 mock deliveries for testing'),
              enabled: !_isGenerating,
              onTap: _generateMockDeliveries,
            ),
            const Divider(height: 1),
            // Generate completed deliveries
            ListTile(
              leading: _isGenerating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.history, color: Colors.green),
              title: const Text('Generate Completed Deliveries'),
              subtitle: const Text('Create 10 past deliveries for earnings'),
              enabled: !_isGenerating,
              onTap: _generateCompletedDeliveries,
            ),
            const Divider(height: 1),
            // Clear all data
            ListTile(
              leading: _isGenerating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Clear All Deliveries'),
              subtitle: const Text('Delete all your delivery data'),
              enabled: !_isGenerating,
              onTap: _clearMockData,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            trailing: Text(
              '1.0.0',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.textSecondary,
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TermsOfServiceScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
