import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hello_zabiha_driver/services/cache_service.dart';
import 'package:hello_zabiha_driver/models/delivery.dart';
import 'package:hello_zabiha_driver/models/driver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CacheService', () {
    setUp(() async {
      // Reset SharedPreferences for each test
      SharedPreferences.setMockInitialValues({});
    });

    group('cacheDeliveries / getCachedDeliveries', () {
      test('caches and retrieves deliveries', () async {
        SharedPreferences.setMockInitialValues({});

        final deliveries = [
          Delivery(
            id: 'delivery-1',
            orderId: 'order-1',
            driverId: 'driver-1',
            status: DeliveryStatus.assigned,
            customerName: 'John Doe',
            customerPhone: '555-1234',
            deliveryAddress: '123 Main St',
            totalAmount: 50.0,
            itemCount: 2,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Delivery(
            id: 'delivery-2',
            orderId: 'order-2',
            driverId: 'driver-1',
            status: DeliveryStatus.completed,
            customerName: 'Jane Smith',
            customerPhone: '555-5678',
            deliveryAddress: '456 Oak Ave',
            totalAmount: 75.0,
            itemCount: 3,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        await CacheService.instance.cacheDeliveries(deliveries);
        final cached = await CacheService.instance.getCachedDeliveries();

        expect(cached.length, 2);
        expect(cached[0].id, 'delivery-1');
        expect(cached[0].customerName, 'John Doe');
        expect(cached[1].id, 'delivery-2');
        expect(cached[1].status, DeliveryStatus.completed);
      });
    });

    group('cacheDriver / getCachedDriver', () {
      test('caches and retrieves driver', () async {
        SharedPreferences.setMockInitialValues({});

        final driver = Driver(
          id: 'driver-123',
          name: 'Test Driver',
          email: 'test@example.com',
          phone: '555-9999',
          isAvailable: true,
          isOnDelivery: false,
          rating: 4.5,
          totalDeliveries: 100,
          completedToday: 5,
          vehicleType: VehicleType.suv,
          hasRefrigeration: true,
          hasCooler: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await CacheService.instance.cacheDriver(driver);
        final cached = await CacheService.instance.getCachedDriver();

        expect(cached, isNotNull);
        expect(cached!.id, 'driver-123');
        expect(cached.name, 'Test Driver');
        expect(cached.rating, 4.5);
        expect(cached.vehicleType, VehicleType.suv);
        expect(cached.hasRefrigeration, true);
      });
    });

    group('getLastSyncTime', () {
      test('returns DateTime after caching data', () async {
        SharedPreferences.setMockInitialValues({});

        final deliveries = [
          Delivery(
            id: 'delivery-1',
            orderId: 'order-1',
            driverId: 'driver-1',
            status: DeliveryStatus.assigned,
            customerName: 'John Doe',
            customerPhone: '555-1234',
            deliveryAddress: '123 Main St',
            totalAmount: 50.0,
            itemCount: 2,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        await CacheService.instance.cacheDeliveries(deliveries);
        final lastSync = await CacheService.instance.getLastSyncTime();

        expect(lastSync, isNotNull);
        expect(
            lastSync!.difference(DateTime.now()).inSeconds.abs(), lessThan(5));
      });
    });

    group('getLastSyncString', () {
      test('returns "Just now" after recent sync', () async {
        SharedPreferences.setMockInitialValues({});

        final driver = Driver(
          id: 'driver-123',
          name: 'Test',
          email: 'test@example.com',
          phone: '',
          isAvailable: true,
          isOnDelivery: false,
          totalDeliveries: 0,
          completedToday: 0,
          hasRefrigeration: false,
          hasCooler: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await CacheService.instance.cacheDriver(driver);
        final syncString = await CacheService.instance.getLastSyncString();

        expect(syncString, 'Just now');
      });
    });

    group('clearCache', () {
      test('clears all cached data', () async {
        SharedPreferences.setMockInitialValues({});

        final driver = Driver(
          id: 'driver-123',
          name: 'Test',
          email: 'test@example.com',
          phone: '',
          isAvailable: true,
          isOnDelivery: false,
          totalDeliveries: 0,
          completedToday: 0,
          hasRefrigeration: false,
          hasCooler: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await CacheService.instance.cacheDriver(driver);
        expect(await CacheService.instance.getCachedDriver(), isNotNull);

        await CacheService.instance.clearCache();

        // After clearing, next fetch should return null/empty
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('cached_driver'), isNull);
      });
    });
  });
}
