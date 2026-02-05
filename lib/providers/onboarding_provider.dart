import 'package:flutter/foundation.dart';
import '../models/driver.dart';
import '../services/driver_service.dart';

class OnboardingProvider extends ChangeNotifier {
  final DriverService _driverService = DriverService.instance;

  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;
  Driver? _driver;

  // Form data
  String _name = '';
  String _phone = '';
  VehicleType _vehicleType = VehicleType.car;
  String _vehicleModel = '';
  String _licensePlate = '';
  int? _vehicleYear;
  bool _hasRefrigeration = false;
  bool _hasCooler = false;
  int _maxDeliveriesPerRun = 10;

  // Getters
  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Driver? get driver => _driver;

  String get name => _name;
  String get phone => _phone;
  VehicleType get vehicleType => _vehicleType;
  String get vehicleModel => _vehicleModel;
  String get licensePlate => _licensePlate;
  int? get vehicleYear => _vehicleYear;
  bool get hasRefrigeration => _hasRefrigeration;
  bool get hasCooler => _hasCooler;
  int get maxDeliveriesPerRun => _maxDeliveriesPerRun;

  static const int totalSteps = 5;

  bool get isFirstStep => _currentStep == 0;
  bool get isLastStep => _currentStep == totalSteps - 1;
  double get progress => (_currentStep + 1) / totalSteps;

  /// Load existing driver data if available
  Future<void> loadDriverData() async {
    _driver = await _driverService.getCurrentDriver();
    if (_driver != null) {
      _name = _driver!.name;
      _phone = _driver!.phone;
      if (_driver!.vehicleType != null) {
        _vehicleType = _driver!.vehicleType!;
      }
      _vehicleModel = _driver!.vehicleModel ?? '';
      _licensePlate = _driver!.licensePlate ?? '';
      _vehicleYear = _driver!.vehicleYear;
      _hasRefrigeration = _driver!.hasRefrigeration;
      _hasCooler = _driver!.hasCooler;
      _maxDeliveriesPerRun = _driver!.maxDeliveriesPerRun ?? 10;
      notifyListeners();
    }
  }

  /// Check if onboarding is needed
  Future<bool> needsOnboarding() async {
    _driver = await _driverService.getCurrentDriver();
    if (_driver == null) return true;
    return !_driver!.isProfileComplete;
  }

  // Setters with notification
  void setName(String value) {
    _name = value;
    notifyListeners();
  }

  void setPhone(String value) {
    _phone = value;
    notifyListeners();
  }

  void setVehicleType(VehicleType value) {
    _vehicleType = value;
    notifyListeners();
  }

  void setVehicleModel(String value) {
    _vehicleModel = value;
    notifyListeners();
  }

  void setLicensePlate(String value) {
    _licensePlate = value;
    notifyListeners();
  }

  void setVehicleYear(int? value) {
    _vehicleYear = value;
    notifyListeners();
  }

  void setHasRefrigeration(bool value) {
    _hasRefrigeration = value;
    notifyListeners();
  }

  void setHasCooler(bool value) {
    _hasCooler = value;
    notifyListeners();
  }

  void setMaxDeliveriesPerRun(int value) {
    _maxDeliveriesPerRun = value;
    notifyListeners();
  }

  /// Navigate to next step
  void nextStep() {
    if (_currentStep < totalSteps - 1) {
      _currentStep++;
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Navigate to previous step
  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Go to specific step
  void goToStep(int step) {
    if (step >= 0 && step < totalSteps) {
      _currentStep = step;
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Validate current step
  bool validateCurrentStep() {
    _errorMessage = null;

    switch (_currentStep) {
      case 0: // Welcome
        return true;
      case 1: // Personal info
        if (_name.trim().isEmpty) {
          _errorMessage = 'Please enter your full name';
          notifyListeners();
          return false;
        }
        if (_phone.trim().isEmpty) {
          _errorMessage = 'Please enter your phone number';
          notifyListeners();
          return false;
        }
        if (_phone.trim().length < 10) {
          _errorMessage = 'Please enter a valid phone number';
          notifyListeners();
          return false;
        }
        return true;
      case 2: // Vehicle info
        if (_licensePlate.trim().isEmpty) {
          _errorMessage = 'Please enter your license plate number';
          notifyListeners();
          return false;
        }
        return true;
      case 3: // Capabilities
        return true;
      case 4: // Complete
        return true;
      default:
        return true;
    }
  }

  /// Save all onboarding data
  Future<bool> saveOnboardingData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _driverService.updateDriver(
        name: _name,
        phone: _phone,
        vehicleType: _vehicleType,
        vehicleModel: _vehicleModel.isNotEmpty ? _vehicleModel : null,
        licensePlate: _licensePlate,
        vehicleYear: _vehicleYear,
        hasRefrigeration: _hasRefrigeration,
        hasCooler: _hasCooler,
        maxDeliveriesPerRun: _maxDeliveriesPerRun,
      );

      if (result != null) {
        _driver = result;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to save profile. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reset onboarding state
  void reset() {
    _currentStep = 0;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
