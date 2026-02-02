class Driver {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? vehicleType;
  final String? licensePlate;
  final bool isAvailable;
  final double? rating;
  final int totalDeliveries;
  final DateTime createdAt;
  final DateTime updatedAt;

  Driver({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.vehicleType,
    this.licensePlate,
    this.isAvailable = false,
    this.rating,
    this.totalDeliveries = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      vehicleType: json['vehicle_type'] as String?,
      licensePlate: json['license_plate'] as String?,
      isAvailable: json['is_available'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble(),
      totalDeliveries: json['total_deliveries'] as int? ?? 0,
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
      'vehicle_type': vehicleType,
      'license_plate': licensePlate,
      'is_available': isAvailable,
      'rating': rating,
      'total_deliveries': totalDeliveries,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Driver copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? vehicleType,
    String? licensePlate,
    bool? isAvailable,
    double? rating,
    int? totalDeliveries,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Driver(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      vehicleType: vehicleType ?? this.vehicleType,
      licensePlate: licensePlate ?? this.licensePlate,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
