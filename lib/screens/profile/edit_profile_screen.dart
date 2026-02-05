import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/driver.dart';
import '../../providers/profile_provider.dart';
import '../../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  final Driver driver;

  const EditProfileScreen({super.key, required this.driver});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _vehicleModelController;
  late TextEditingController _licensePlateController;
  late TextEditingController _vehicleYearController;
  late TextEditingController _capacityController;
  late TextEditingController _maxWeightController;
  late TextEditingController _maxDeliveriesController;

  VehicleType? _selectedVehicleType;
  bool _hasRefrigeration = false;
  bool _hasCooler = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.driver.name);
    _phoneController = TextEditingController(text: widget.driver.phone);
    _vehicleModelController = TextEditingController(text: widget.driver.vehicleModel ?? '');
    _licensePlateController = TextEditingController(text: widget.driver.licensePlate ?? '');
    _vehicleYearController = TextEditingController(
      text: widget.driver.vehicleYear?.toString() ?? '',
    );
    _capacityController = TextEditingController(
      text: widget.driver.capacityCubicFeet?.toString() ?? '',
    );
    _maxWeightController = TextEditingController(
      text: widget.driver.maxWeightLbs?.toString() ?? '',
    );
    _maxDeliveriesController = TextEditingController(
      text: widget.driver.maxDeliveriesPerRun?.toString() ?? '',
    );
    _selectedVehicleType = widget.driver.vehicleType;
    _hasRefrigeration = widget.driver.hasRefrigeration;
    _hasCooler = widget.driver.hasCooler;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleModelController.dispose();
    _licensePlateController.dispose();
    _vehicleYearController.dispose();
    _capacityController.dispose();
    _maxWeightController.dispose();
    _maxDeliveriesController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<ProfileProvider>();
    final success = await provider.updateFullProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      vehicleType: _selectedVehicleType,
      vehicleModel: _vehicleModelController.text.trim().isNotEmpty
          ? _vehicleModelController.text.trim()
          : null,
      licensePlate: _licensePlateController.text.trim().isNotEmpty
          ? _licensePlateController.text.trim()
          : null,
      vehicleYear: _vehicleYearController.text.isNotEmpty
          ? int.tryParse(_vehicleYearController.text)
          : null,
      capacityCubicFeet: _capacityController.text.isNotEmpty
          ? double.tryParse(_capacityController.text)
          : null,
      maxWeightLbs: _maxWeightController.text.isNotEmpty
          ? double.tryParse(_maxWeightController.text)
          : null,
      maxDeliveriesPerRun: _maxDeliveriesController.text.isNotEmpty
          ? int.tryParse(_maxDeliveriesController.text)
          : null,
      hasRefrigeration: _hasRefrigeration,
      hasCooler: _hasCooler,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to update profile'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          children: [
            // Personal Information Section
            _buildSectionHeader('Personal Information'),
            const SizedBox(height: AppTheme.spacingM),
            _buildCard([
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const Divider(height: 1),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
            ]),

            const SizedBox(height: AppTheme.spacingL),

            // Vehicle Information Section
            _buildSectionHeader('Vehicle Information'),
            const SizedBox(height: AppTheme.spacingM),
            _buildCard([
              _buildDropdownField(
                label: 'Vehicle Type',
                icon: Icons.directions_car_outlined,
                value: _selectedVehicleType,
                items: VehicleType.values,
                onChanged: (value) {
                  setState(() {
                    _selectedVehicleType = value;
                    // Auto-fill capacity if empty
                    if (value != null && _capacityController.text.isEmpty) {
                      _capacityController.text = value.defaultCapacityCubicFeet.toString();
                    }
                    if (value != null && _maxWeightController.text.isEmpty) {
                      _maxWeightController.text = value.defaultMaxWeightLbs.toString();
                    }
                  });
                },
              ),
              const Divider(height: 1),
              _buildTextField(
                controller: _vehicleModelController,
                label: 'Vehicle Model',
                icon: Icons.directions_car,
                hint: 'e.g., Toyota Camry',
              ),
              const Divider(height: 1),
              _buildTextField(
                controller: _licensePlateController,
                label: 'License Plate',
                icon: Icons.badge_outlined,
                textCapitalization: TextCapitalization.characters,
              ),
              const Divider(height: 1),
              _buildTextField(
                controller: _vehicleYearController,
                label: 'Vehicle Year',
                icon: Icons.calendar_today_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                hint: 'e.g., 2022',
              ),
            ]),

            const SizedBox(height: AppTheme.spacingL),

            // Capacity Settings Section
            _buildSectionHeader('Capacity Settings'),
            const SizedBox(height: AppTheme.spacingM),
            _buildCard([
              _buildTextField(
                controller: _capacityController,
                label: 'Cargo Capacity (cubic ft)',
                icon: Icons.inventory_2_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                hint: _selectedVehicleType?.defaultCapacityCubicFeet.toString() ?? '15',
              ),
              const Divider(height: 1),
              _buildTextField(
                controller: _maxWeightController,
                label: 'Max Weight (lbs)',
                icon: Icons.fitness_center_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                hint: _selectedVehicleType?.defaultMaxWeightLbs.toString() ?? '200',
              ),
              const Divider(height: 1),
              _buildTextField(
                controller: _maxDeliveriesController,
                label: 'Max Deliveries Per Run',
                icon: Icons.local_shipping_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                hint: '10',
              ),
            ]),

            const SizedBox(height: AppTheme.spacingL),

            // Cold Storage Section
            _buildSectionHeader('Cold Storage Capability'),
            const SizedBox(height: AppTheme.spacingM),
            _buildCard([
              _buildSwitchTile(
                title: 'Has Refrigeration Unit',
                subtitle: 'Vehicle has built-in refrigeration',
                icon: Icons.ac_unit,
                value: _hasRefrigeration,
                onChanged: (value) => setState(() => _hasRefrigeration = value),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                title: 'Has Cooler/Ice Chest',
                subtitle: 'Using portable cooler for cold items',
                icon: Icons.kitchen_outlined,
                value: _hasCooler,
                onChanged: (value) => setState(() => _hasCooler = value),
              ),
            ]),

            const SizedBox(height: AppTheme.spacingXL),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXS),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: AppTheme.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: AppTheme.iconContainerDecoration,
            child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              textCapitalization: textCapitalization,
              inputFormatters: inputFormatters,
              validator: validator,
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required VehicleType? value,
    required List<VehicleType> items,
    required void Function(VehicleType?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: AppTheme.iconContainerDecoration,
            child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: DropdownButtonFormField<VehicleType>(
              value: value,
              decoration: InputDecoration(
                labelText: label,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              items: items.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: AppTheme.iconContainerDecoration,
            child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppTheme.primaryGreenLight,
            activeThumbColor: AppTheme.primaryGreen,
          ),
        ],
      ),
    );
  }
}
