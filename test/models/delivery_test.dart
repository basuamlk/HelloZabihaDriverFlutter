import 'package:flutter_test/flutter_test.dart';
import 'package:hello_zabiha_driver/models/delivery.dart';

void main() {
  group('Delivery', () {
    group('fromJson', () {
      test('parses valid delivery JSON', () {
        final json = {
          'id': 'test-id-123',
          'order_id': 'order-456',
          'driver_id': 'driver-789',
          'customer_name': 'John Doe',
          'customer_phone': '555-1234',
          'delivery_address': '123 Main St',
          'delivery_latitude': 40.7128,
          'delivery_longitude': -74.0060,
          'status': 'assigned',
          'total_amount': 99.99,
          'item_count': 3,
          'created_at': '2024-01-15T10:30:00Z',
          'updated_at': '2024-01-15T10:30:00Z',
        };

        final delivery = Delivery.fromJson(json);

        expect(delivery.id, 'test-id-123');
        expect(delivery.orderId, 'order-456');
        expect(delivery.driverId, 'driver-789');
        expect(delivery.customerName, 'John Doe');
        expect(delivery.customerPhone, '555-1234');
        expect(delivery.deliveryAddress, '123 Main St');
        expect(delivery.deliveryLatitude, 40.7128);
        expect(delivery.deliveryLongitude, -74.0060);
        expect(delivery.status, DeliveryStatus.assigned);
        expect(delivery.totalAmount, 99.99);
        expect(delivery.itemCount, 3);
      });

      test('handles null optional fields', () {
        final json = {
          'id': 'test-id-123',
          'order_id': 'order-456',
          'driver_id': 'driver-789',
          'customer_name': 'John Doe',
          'customer_phone': '555-1234',
          'delivery_address': '123 Main St',
          'status': 'assigned',
          'total_amount': 50.0,
          'item_count': 1,
          'created_at': '2024-01-15T10:30:00Z',
          'updated_at': '2024-01-15T10:30:00Z',
        };

        final delivery = Delivery.fromJson(json);

        expect(delivery.pickupAddress, isNull);
        expect(delivery.deliveryLatitude, isNull);
        expect(delivery.specialInstructions, isNull);
      });

      test('handles all delivery statuses', () {
        final statuses = [
          'pending',
          'assigned',
          'picked_up_from_farm',
          'en_route',
          'nearby_fifteen_min',
          'completed',
          'failed',
        ];

        for (final statusStr in statuses) {
          final json = {
            'id': 'test-id',
            'order_id': 'order-id',
            'driver_id': 'driver-id',
            'customer_name': 'Test',
            'customer_phone': '555-0000',
            'delivery_address': 'Test Address',
            'status': statusStr,
            'total_amount': 25.0,
            'item_count': 2,
            'created_at': '2024-01-15T10:30:00Z',
            'updated_at': '2024-01-15T10:30:00Z',
          };

          final delivery = Delivery.fromJson(json);
          expect(delivery.status, isNotNull);
        }
      });
    });

    group('DeliveryStatus', () {
      test('displayName returns human readable string', () {
        expect(DeliveryStatus.pending.displayName, 'Pending');
        expect(DeliveryStatus.assigned.displayName, 'Assigned');
        expect(DeliveryStatus.pickedUpFromFarm.displayName, 'Picked Up');
        expect(DeliveryStatus.enRoute.displayName, 'En Route');
        expect(DeliveryStatus.nearbyFifteenMin.displayName, '15 Min Away');
        expect(DeliveryStatus.completed.displayName, 'Completed');
        expect(DeliveryStatus.failed.displayName, 'Failed');
      });

      test('isActive returns true only for active statuses', () {
        // Active statuses (driver is actively working on delivery)
        expect(DeliveryStatus.pickedUpFromFarm.isActive, isTrue);
        expect(DeliveryStatus.enRoute.isActive, isTrue);
        expect(DeliveryStatus.nearbyFifteenMin.isActive, isTrue);

        // Not active statuses
        expect(DeliveryStatus.pending.isActive, isFalse);
        expect(DeliveryStatus.assigned.isActive, isFalse);
        expect(DeliveryStatus.completed.isActive, isFalse);
        expect(DeliveryStatus.failed.isActive, isFalse);
      });

      test('isPending returns true for non-terminal statuses', () {
        expect(DeliveryStatus.pending.isPending, isTrue);
        expect(DeliveryStatus.assigned.isPending, isTrue);
        expect(DeliveryStatus.pickedUpFromFarm.isPending, isTrue);
        expect(DeliveryStatus.enRoute.isPending, isTrue);
        expect(DeliveryStatus.nearbyFifteenMin.isPending, isTrue);

        // Terminal statuses
        expect(DeliveryStatus.completed.isPending, isFalse);
        expect(DeliveryStatus.failed.isPending, isFalse);
      });
    });
  });
}
