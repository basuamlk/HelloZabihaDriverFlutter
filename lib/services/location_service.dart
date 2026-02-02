import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();

  LocationService._();

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  StreamSubscription<Position>? _positionSubscription;
  final List<Position> _locationHistory = [];
  List<Position> get locationHistory => List.unmodifiable(_locationHistory);

  final _positionController = StreamController<Position>.broadcast();
  Stream<Position> get positionStream => _positionController.stream;

  Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<LocationPermission> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermission.denied;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        final permission = await requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return null;
        }
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return _currentPosition;
    } catch (e) {
      return null;
    }
  }

  void startTracking() {
    if (_isTracking) return;
    _isTracking = true;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _currentPosition = position;
      _locationHistory.add(position);

      // Keep last 100 locations
      if (_locationHistory.length > 100) {
        _locationHistory.removeAt(0);
      }

      _positionController.add(position);
    });
  }

  void stopTracking() {
    _isTracking = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  double? distanceTo(double latitude, double longitude) {
    if (_currentPosition == null) return null;

    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      latitude,
      longitude,
    );
  }

  Duration? estimatedTimeTo(double latitude, double longitude) {
    final distance = distanceTo(latitude, longitude);
    if (distance == null) return null;

    // Assuming average speed of 30 mph (13.4 m/s)
    const averageSpeedMps = 13.4;
    final seconds = distance / averageSpeedMps;
    return Duration(seconds: seconds.round());
  }

  void dispose() {
    stopTracking();
    _positionController.close();
  }
}
