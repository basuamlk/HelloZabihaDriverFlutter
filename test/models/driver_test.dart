import 'package:flutter_test/flutter_test.dart';
import 'package:hello_zabiha_driver/models/driver.dart';

void main() {
  group('Driver', () {
    group('fromJson', () {
      test('parses valid driver JSON', () {
        final json = {
          'id': 'driver-123',
          'name': 'John Driver',
          'email': 'john@example.com',
          'phone': '555-1234',
          'is_available': true,
          'is_on_delivery': false,
          'rating': 4.8,
          'total_deliveries': 150,
          'completed_today': 5,
          'vehicle_type': 'suv',
          'vehicle_model': 'Honda CR-V',
          'license_plate': 'ABC-123',
          'has_refrigeration': true,
          'has_cooler': false,
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': '2024-01-15T10:30:00Z',
        };

        final driver = Driver.fromJson(json);

        expect(driver.id, 'driver-123');
        expect(driver.name, 'John Driver');
        expect(driver.email, 'john@example.com');
        expect(driver.phone, '555-1234');
        expect(driver.isAvailable, true);
        expect(driver.isOnDelivery, false);
        expect(driver.rating, 4.8);
        expect(driver.totalDeliveries, 150);
        expect(driver.completedToday, 5);
        expect(driver.vehicleType, VehicleType.suv);
        expect(driver.vehicleModel, 'Honda CR-V');
        expect(driver.licensePlate, 'ABC-123');
        expect(driver.hasRefrigeration, true);
        expect(driver.hasCooler, false);
      });

      test('handles null optional fields', () {
        final json = {
          'id': 'driver-123',
          'name': 'John Driver',
          'email': 'john@example.com',
          'phone': '',
          'is_available': false,
          'is_on_delivery': false,
          'total_deliveries': 0,
          'completed_today': 0,
          'has_refrigeration': false,
          'has_cooler': false,
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': '2024-01-15T10:30:00Z',
        };

        final driver = Driver.fromJson(json);

        expect(driver.rating, isNull);
        expect(driver.vehicleType, isNull);
        expect(driver.vehicleModel, isNull);
        expect(driver.licensePlate, isNull);
        expect(driver.profilePhotoUrl, isNull);
      });
    });

    group('toJson', () {
      test('serializes driver to JSON', () {
        final driver = Driver(
          id: 'driver-123',
          name: 'John Driver',
          email: 'john@example.com',
          phone: '555-1234',
          isAvailable: true,
          isOnDelivery: false,
          rating: 4.5,
          totalDeliveries: 100,
          completedToday: 3,
          vehicleType: VehicleType.car,
          hasRefrigeration: false,
          hasCooler: true,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 15),
        );

        final json = driver.toJson();

        expect(json['id'], 'driver-123');
        expect(json['name'], 'John Driver');
        expect(json['email'], 'john@example.com');
        expect(json['is_available'], true);
        expect(json['vehicle_type'], 'car');
        expect(json['has_cooler'], true);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final driver = Driver(
          id: 'driver-123',
          name: 'John Driver',
          email: 'john@example.com',
          phone: '555-1234',
          isAvailable: false,
          isOnDelivery: false,
          totalDeliveries: 100,
          completedToday: 0,
          hasRefrigeration: false,
          hasCooler: false,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 15),
        );

        final updated = driver.copyWith(
          isAvailable: true,
          totalDeliveries: 101,
          rating: 4.9,
        );

        expect(updated.id, driver.id); // unchanged
        expect(updated.name, driver.name); // unchanged
        expect(updated.isAvailable, true); // changed
        expect(updated.totalDeliveries, 101); // changed
        expect(updated.rating, 4.9); // changed
      });
    });

    group('VehicleType', () {
      test('all vehicle types have correct values', () {
        expect(VehicleType.car.value, 'car');
        expect(VehicleType.suv.value, 'suv');
        expect(VehicleType.truck.value, 'truck');
        expect(VehicleType.van.value, 'van');
        expect(VehicleType.motorcycle.value, 'motorcycle');
      });

      test('fromString parses valid types', () {
        expect(VehicleType.fromString('car'), VehicleType.car);
        expect(VehicleType.fromString('suv'), VehicleType.suv);
        expect(VehicleType.fromString('truck'), VehicleType.truck);
        expect(VehicleType.fromString('van'), VehicleType.van);
        expect(VehicleType.fromString('motorcycle'), VehicleType.motorcycle);
      });

      test('fromString returns default (car) for invalid type', () {
        // Invalid types default to car
        expect(VehicleType.fromString('airplane'), VehicleType.car);
        expect(VehicleType.fromString(''), VehicleType.car);
        expect(VehicleType.fromString('invalid'), VehicleType.car);
        expect(VehicleType.fromString(null), VehicleType.car);
      });
    });

    group('effectiveCapacity', () {
      test('returns capacity when set', () {
        final driver = Driver(
          id: 'driver-123',
          name: 'John',
          email: 'john@example.com',
          phone: '',
          isAvailable: true,
          isOnDelivery: false,
          totalDeliveries: 0,
          completedToday: 0,
          capacityCubicFeet: 50.0,
          hasRefrigeration: false,
          hasCooler: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(driver.effectiveCapacity, 50.0);
      });

      test('returns default based on vehicle type when not set', () {
        final suvDriver = Driver(
          id: 'driver-123',
          name: 'John',
          email: 'john@example.com',
          phone: '',
          isAvailable: true,
          isOnDelivery: false,
          totalDeliveries: 0,
          completedToday: 0,
          vehicleType: VehicleType.suv,
          hasRefrigeration: false,
          hasCooler: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(suvDriver.effectiveCapacity, greaterThan(0));
      });
    });
  });
}
