/// Vehicle types supported by the delivery system
enum VehicleType {
  car,
  suv,
  van,
  truck,
  motorcycle,
  bicycle;

  String get displayName {
    switch (this) {
      case VehicleType.car:
        return 'Car';
      case VehicleType.suv:
        return 'SUV';
      case VehicleType.van:
        return 'Van';
      case VehicleType.truck:
        return 'Truck';
      case VehicleType.motorcycle:
        return 'Motorcycle';
      case VehicleType.bicycle:
        return 'Bicycle';
    }
  }

  String get value {
    switch (this) {
      case VehicleType.car:
        return 'car';
      case VehicleType.suv:
        return 'suv';
      case VehicleType.van:
        return 'van';
      case VehicleType.truck:
        return 'truck';
      case VehicleType.motorcycle:
        return 'motorcycle';
      case VehicleType.bicycle:
        return 'bicycle';
    }
  }

  static VehicleType fromString(String? value) {
    switch (value) {
      case 'car':
        return VehicleType.car;
      case 'suv':
        return VehicleType.suv;
      case 'van':
        return VehicleType.van;
      case 'truck':
        return VehicleType.truck;
      case 'motorcycle':
        return VehicleType.motorcycle;
      case 'bicycle':
        return VehicleType.bicycle;
      default:
        return VehicleType.car;
    }
  }

  /// Default capacity in cubic feet for each vehicle type
  double get defaultCapacityCubicFeet {
    switch (this) {
      case VehicleType.car:
        return 15.0;
      case VehicleType.suv:
        return 35.0;
      case VehicleType.van:
        return 100.0;
      case VehicleType.truck:
        return 200.0;
      case VehicleType.motorcycle:
        return 3.0;
      case VehicleType.bicycle:
        return 2.0;
    }
  }

  /// Default max weight capacity in lbs
  double get defaultMaxWeightLbs {
    switch (this) {
      case VehicleType.car:
        return 200.0;
      case VehicleType.suv:
        return 400.0;
      case VehicleType.van:
        return 1000.0;
      case VehicleType.truck:
        return 2000.0;
      case VehicleType.motorcycle:
        return 50.0;
      case VehicleType.bicycle:
        return 30.0;
    }
  }

  /// Whether the vehicle has refrigeration capability
  bool get supportsRefrigeration {
    switch (this) {
      case VehicleType.van:
      case VehicleType.truck:
        return true;
      default:
        return false;
    }
  }
}

class Driver {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profilePhotoUrl;

  // Vehicle Information
  final VehicleType? vehicleType;
  final String? vehicleModel;
  final String? licensePlate;
  final int? vehicleYear;

  // Capacity Information
  final double? capacityCubicFeet;
  final double? maxWeightLbs;
  final int? maxDeliveriesPerRun;
  final bool hasRefrigeration;
  final bool hasCooler;

  // Availability & Status
  final bool isAvailable;
  final bool isOnDelivery;
  final double? currentLatitude;
  final double? currentLongitude;

  // Performance
  final double? rating;
  final int totalDeliveries;
  final int completedToday;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  Driver({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profilePhotoUrl,
    this.vehicleType,
    this.vehicleModel,
    this.licensePlate,
    this.vehicleYear,
    this.capacityCubicFeet,
    this.maxWeightLbs,
    this.maxDeliveriesPerRun,
    this.hasRefrigeration = false,
    this.hasCooler = false,
    this.isAvailable = false,
    this.isOnDelivery = false,
    this.currentLatitude,
    this.currentLongitude,
    this.rating,
    this.totalDeliveries = 0,
    this.completedToday = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get effective capacity (use vehicle type default if not specified)
  double get effectiveCapacity {
    return capacityCubicFeet ?? vehicleType?.defaultCapacityCubicFeet ?? 15.0;
  }

  /// Get effective max weight (use vehicle type default if not specified)
  double get effectiveMaxWeight {
    return maxWeightLbs ?? vehicleType?.defaultMaxWeightLbs ?? 200.0;
  }

  /// Get effective max deliveries per run
  int get effectiveMaxDeliveries {
    return maxDeliveriesPerRun ?? 10;
  }

  /// Check if driver can handle refrigerated deliveries
  bool get canHandleRefrigerated {
    return hasRefrigeration || hasCooler;
  }

  /// Check if profile is complete enough for assignments
  bool get isProfileComplete {
    return vehicleType != null &&
           licensePlate != null &&
           licensePlate!.isNotEmpty &&
           phone.isNotEmpty;
  }

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String? ?? '',
      profilePhotoUrl: json['profile_photo_url'] as String?,
      vehicleType: json['vehicle_type'] != null
          ? VehicleType.fromString(json['vehicle_type'] as String?)
          : null,
      vehicleModel: json['vehicle_model'] as String?,
      licensePlate: json['license_plate'] as String?,
      vehicleYear: json['vehicle_year'] as int?,
      capacityCubicFeet: (json['capacity_cubic_feet'] as num?)?.toDouble(),
      maxWeightLbs: (json['max_weight_lbs'] as num?)?.toDouble(),
      maxDeliveriesPerRun: json['max_deliveries_per_run'] as int?,
      hasRefrigeration: json['has_refrigeration'] as bool? ?? false,
      hasCooler: json['has_cooler'] as bool? ?? false,
      isAvailable: json['is_available'] as bool? ?? false,
      isOnDelivery: json['is_on_delivery'] as bool? ?? false,
      currentLatitude: (json['current_latitude'] as num?)?.toDouble(),
      currentLongitude: (json['current_longitude'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      totalDeliveries: json['total_deliveries'] as int? ?? 0,
      completedToday: json['completed_today'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profile_photo_url': profilePhotoUrl,
      'vehicle_type': vehicleType?.value,
      'vehicle_model': vehicleModel,
      'license_plate': licensePlate,
      'vehicle_year': vehicleYear,
      'capacity_cubic_feet': capacityCubicFeet,
      'max_weight_lbs': maxWeightLbs,
      'max_deliveries_per_run': maxDeliveriesPerRun,
      'has_refrigeration': hasRefrigeration,
      'has_cooler': hasCooler,
      'is_available': isAvailable,
      'is_on_delivery': isOnDelivery,
      'current_latitude': currentLatitude,
      'current_longitude': currentLongitude,
      'rating': rating,
      'total_deliveries': totalDeliveries,
      'completed_today': completedToday,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Driver copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profilePhotoUrl,
    VehicleType? vehicleType,
    String? vehicleModel,
    String? licensePlate,
    int? vehicleYear,
    double? capacityCubicFeet,
    double? maxWeightLbs,
    int? maxDeliveriesPerRun,
    bool? hasRefrigeration,
    bool? hasCooler,
    bool? isAvailable,
    bool? isOnDelivery,
    double? currentLatitude,
    double? currentLongitude,
    double? rating,
    int? totalDeliveries,
    int? completedToday,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      licensePlate: licensePlate ?? this.licensePlate,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      capacityCubicFeet: capacityCubicFeet ?? this.capacityCubicFeet,
      maxWeightLbs: maxWeightLbs ?? this.maxWeightLbs,
      maxDeliveriesPerRun: maxDeliveriesPerRun ?? this.maxDeliveriesPerRun,
      hasRefrigeration: hasRefrigeration ?? this.hasRefrigeration,
      hasCooler: hasCooler ?? this.hasCooler,
      isAvailable: isAvailable ?? this.isAvailable,
      isOnDelivery: isOnDelivery ?? this.isOnDelivery,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      completedToday: completedToday ?? this.completedToday,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
