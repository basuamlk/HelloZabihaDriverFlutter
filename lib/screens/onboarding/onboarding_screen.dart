import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/driver.dart';
import '../../providers/onboarding_provider.dart';
import '../../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OnboardingProvider>().loadDriverData();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    final provider = context.read<OnboardingProvider>();

    if (!provider.validateCurrentStep()) {
      return;
    }

    if (provider.isLastStep) {
      _completeOnboarding();
    } else {
      provider.nextStep();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onBackPressed() {
    final provider = context.read<OnboardingProvider>();
    if (!provider.isFirstStep) {
      provider.previousStep();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    final provider = context.read<OnboardingProvider>();
    final success = await provider.saveOnboardingData();

    if (success && mounted) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<OnboardingProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                // Progress indicator
                _buildProgressIndicator(provider),

                // Page content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      _WelcomeStep(),
                      _PersonalInfoStep(),
                      _VehicleInfoStep(),
                      _CapabilitiesStep(),
                      _CompleteStep(),
                    ],
                  ),
                ),

                // Error message
                if (provider.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text(
                      provider.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Navigation buttons
                _buildNavigationButtons(provider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(OnboardingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              if (!provider.isFirstStep)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _onBackPressed,
                )
              else
                const SizedBox(width: 48),
              Expanded(
                child: Text(
                  'Step ${provider.currentStep + 1} of ${OnboardingProvider.totalSteps}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: provider.progress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(OnboardingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: provider.isLoading ? null : _onNextPressed,
          child: provider.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  provider.isLastStep ? 'Get Started' : 'Continue',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }
}

// Step 1: Welcome
class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.local_shipping,
              size: 60,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Welcome to HelloZabiha Driver',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Let\'s set up your driver profile so you can start accepting deliveries.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _buildInfoCard(
            icon: Icons.person_outline,
            title: 'Personal Information',
            description: 'Your name and contact details',
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            icon: Icons.directions_car_outlined,
            title: 'Vehicle Details',
            description: 'Information about your delivery vehicle',
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            icon: Icons.ac_unit,
            title: 'Delivery Capabilities',
            description: 'Cold storage and capacity settings',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Step 2: Personal Information
class _PersonalInfoStep extends StatelessWidget {
  const _PersonalInfoStep();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Consumer<OnboardingProvider>(
        builder: (context, provider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tell us a bit about yourself',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                initialValue: provider.name,
                decoration: AppTheme.inputDecoration(
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: provider.setName,
              ),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: provider.phone,
                decoration: AppTheme.inputDecoration(
                  label: 'Phone Number',
                  hint: '(555) 123-4567',
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                onChanged: provider.setPhone,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your phone number will be used to contact you about deliveries.',
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Step 3: Vehicle Information
class _VehicleInfoStep extends StatelessWidget {
  const _VehicleInfoStep();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Consumer<OnboardingProvider>(
        builder: (context, provider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vehicle Information',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Details about your delivery vehicle',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // Vehicle Type Selection
              const Text(
                'Vehicle Type',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: VehicleType.values.map((type) {
                  final isSelected = provider.vehicleType == type;
                  return GestureDetector(
                    onTap: () => provider.setVehicleType(type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryGreen
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getVehicleIcon(type),
                            size: 20,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            type.displayName,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[700],
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              TextFormField(
                initialValue: provider.vehicleModel,
                decoration: AppTheme.inputDecoration(
                  label: 'Vehicle Make & Model',
                  hint: 'e.g., Toyota Camry',
                  prefixIcon: const Icon(Icons.directions_car_outlined),
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: provider.setVehicleModel,
              ),
              const SizedBox(height: 20),

              TextFormField(
                initialValue: provider.vehicleYear?.toString() ?? '',
                decoration: AppTheme.inputDecoration(
                  label: 'Vehicle Year',
                  hint: 'e.g., 2020',
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                onChanged: (value) {
                  provider.setVehicleYear(
                    value.isNotEmpty ? int.tryParse(value) : null,
                  );
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                initialValue: provider.licensePlate,
                decoration: AppTheme.inputDecoration(
                  label: 'License Plate *',
                  hint: 'Enter license plate number',
                  prefixIcon: const Icon(Icons.credit_card_outlined),
                ),
                textCapitalization: TextCapitalization.characters,
                onChanged: provider.setLicensePlate,
              ),
              const SizedBox(height: 8),
              Text(
                '* Required for verification',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getVehicleIcon(VehicleType type) {
    switch (type) {
      case VehicleType.car:
        return Icons.directions_car;
      case VehicleType.suv:
        return Icons.directions_car;
      case VehicleType.van:
        return Icons.airport_shuttle;
      case VehicleType.truck:
        return Icons.local_shipping;
      case VehicleType.motorcycle:
        return Icons.two_wheeler;
      case VehicleType.bicycle:
        return Icons.pedal_bike;
    }
  }
}

// Step 4: Capabilities
class _CapabilitiesStep extends StatelessWidget {
  const _CapabilitiesStep();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Consumer<OnboardingProvider>(
        builder: (context, provider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Delivery Capabilities',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Help us match you with the right deliveries',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // Cold Storage Section
              const Text(
                'Cold Storage',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Can you transport refrigerated or frozen items?',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),

              _buildToggleOption(
                title: 'Refrigerated Vehicle',
                description: 'Vehicle has built-in refrigeration',
                icon: Icons.ac_unit,
                value: provider.hasRefrigeration,
                onChanged: provider.setHasRefrigeration,
              ),
              const SizedBox(height: 12),

              _buildToggleOption(
                title: 'Cooler / Ice Chest',
                description: 'I can use a cooler for cold items',
                icon: Icons.kitchen,
                value: provider.hasCooler,
                onChanged: provider.setHasCooler,
              ),

              const SizedBox(height: 32),

              // Capacity Section
              const Text(
                'Delivery Capacity',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Maximum deliveries you can handle per run',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppTheme.primaryGreen,
                        thumbColor: AppTheme.primaryGreen,
                        overlayColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: provider.maxDeliveriesPerRun.toDouble(),
                        min: 1,
                        max: 20,
                        divisions: 19,
                        onChanged: (value) {
                          provider.setMaxDeliveriesPerRun(value.toInt());
                        },
                      ),
                    ),
                  ),
                  Container(
                    width: 48,
                    alignment: Alignment.center,
                    child: Text(
                      '${provider.maxDeliveriesPerRun}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.amber[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Having cold storage options helps you receive more delivery opportunities!',
                        style: TextStyle(
                          color: Colors.amber[900],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToggleOption({
    required String title,
    required String description,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: value ? AppTheme.primaryGreen.withValues(alpha: 0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? AppTheme.primaryGreen : Colors.grey[300]!,
            width: value ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: value ? AppTheme.primaryGreen : Colors.grey[600],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: value ? AppTheme.primaryGreen : Colors.grey[800],
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppTheme.primaryGreen,
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return Colors.grey[400];
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// Step 5: Complete
class _CompleteStep extends StatelessWidget {
  const _CompleteStep();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Consumer<OnboardingProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 60,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'You\'re All Set!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your driver profile is complete. You\'re ready to start accepting deliveries!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryRow(
                      icon: Icons.person_outline,
                      label: 'Name',
                      value: provider.name,
                    ),
                    _buildSummaryRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: provider.phone,
                    ),
                    _buildSummaryRow(
                      icon: Icons.directions_car_outlined,
                      label: 'Vehicle',
                      value: provider.vehicleModel.isNotEmpty
                          ? '${provider.vehicleType.displayName} - ${provider.vehicleModel}'
                          : provider.vehicleType.displayName,
                    ),
                    _buildSummaryRow(
                      icon: Icons.credit_card_outlined,
                      label: 'License Plate',
                      value: provider.licensePlate,
                    ),
                    _buildSummaryRow(
                      icon: Icons.ac_unit,
                      label: 'Cold Storage',
                      value: provider.hasRefrigeration
                          ? 'Refrigerated'
                          : provider.hasCooler
                              ? 'Cooler'
                              : 'None',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
