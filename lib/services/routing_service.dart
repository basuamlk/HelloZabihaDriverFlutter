import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Route information from OSRM
class RouteInfo {
  final List<LatLng> polylinePoints;
  final double distanceMeters;
  final double durationSeconds;
  final String? summary;

  RouteInfo({
    required this.polylinePoints,
    required this.distanceMeters,
    required this.durationSeconds,
    this.summary,
  });

  /// Distance in miles
  double get distanceMiles => distanceMeters / 1609.34;

  /// Duration in minutes
  double get durationMinutes => durationSeconds / 60;

  /// Formatted distance string
  String get formattedDistance {
    if (distanceMiles < 0.1) {
      return '${(distanceMeters * 3.28084).round()} ft';
    } else if (distanceMiles < 10) {
      return '${distanceMiles.toStringAsFixed(1)} mi';
    } else {
      return '${distanceMiles.round()} mi';
    }
  }

  /// Formatted duration string
  String get formattedDuration {
    final mins = durationMinutes.round();
    if (mins < 60) {
      return '$mins min';
    } else {
      final hours = mins ~/ 60;
      final remainingMins = mins % 60;
      return remainingMins > 0 ? '${hours}h ${remainingMins}m' : '${hours}h';
    }
  }
}

/// Waypoint for route optimization
class RouteWaypoint {
  final String id;
  final LatLng location;
  final String? label;
  final bool isPickup;

  RouteWaypoint({
    required this.id,
    required this.location,
    this.label,
    this.isPickup = false,
  });
}

/// Optimized route result
class OptimizedRoute {
  final List<RouteWaypoint> orderedWaypoints;
  final List<RouteInfo> legs;
  final double totalDistanceMeters;
  final double totalDurationSeconds;

  OptimizedRoute({
    required this.orderedWaypoints,
    required this.legs,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
  });

  String get formattedTotalDistance {
    final miles = totalDistanceMeters / 1609.34;
    return miles < 10
        ? '${miles.toStringAsFixed(1)} mi'
        : '${miles.round()} mi';
  }

  String get formattedTotalDuration {
    final mins = (totalDurationSeconds / 60).round();
    if (mins < 60) {
      return '$mins min';
    } else {
      final hours = mins ~/ 60;
      final remainingMins = mins % 60;
      return remainingMins > 0 ? '${hours}h ${remainingMins}m' : '${hours}h';
    }
  }
}

class RoutingService {
  static RoutingService? _instance;
  static RoutingService get instance => _instance ??= RoutingService._();

  RoutingService._();

  // OSRM Demo server (for development - consider self-hosting for production)
  static const String _osrmBaseUrl = 'https://router.project-osrm.org';

  /// Get route between two points
  Future<RouteInfo?> getRoute(LatLng origin, LatLng destination) async {
    try {
      final url = '$_osrmBaseUrl/route/v1/driving/'
          '${origin.longitude},${origin.latitude};'
          '${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=polyline';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 'Ok' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'] as String;
          final points = _decodePolyline(geometry);

          return RouteInfo(
            polylinePoints: points,
            distanceMeters: (route['distance'] as num).toDouble(),
            durationSeconds: (route['duration'] as num).toDouble(),
            summary: route['legs']?[0]?['summary'] as String?,
          );
        }
      }

      return null;
    } catch (e) {
      // Return straight line as fallback
      return _straightLineRoute(origin, destination);
    }
  }

  /// Get route through multiple waypoints
  Future<List<RouteInfo>?> getMultiStopRoute(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return null;

    try {
      final coordString = waypoints
          .map((p) => '${p.longitude},${p.latitude}')
          .join(';');

      final url = '$_osrmBaseUrl/route/v1/driving/$coordString'
          '?overview=full&geometries=polyline&steps=false';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 'Ok' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final legs = route['legs'] as List;

          return legs.map<RouteInfo>((leg) {
            // For multi-stop, we need to get geometry from the full route
            // OSRM returns legs without individual geometry, so we calculate segments
            return RouteInfo(
              polylinePoints: [], // Will be populated by full route geometry
              distanceMeters: (leg['distance'] as num).toDouble(),
              durationSeconds: (leg['duration'] as num).toDouble(),
              summary: leg['summary'] as String?,
            );
          }).toList();
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get optimized route (reorders waypoints for shortest path)
  Future<OptimizedRoute?> getOptimizedRoute(
    LatLng origin,
    List<RouteWaypoint> waypoints,
  ) async {
    if (waypoints.isEmpty) return null;

    try {
      // Build coordinate string: origin + all waypoints
      final allPoints = [origin, ...waypoints.map((w) => w.location)];
      final coordString = allPoints
          .map((p) => '${p.longitude},${p.latitude}')
          .join(';');

      // Use OSRM trip service for optimization
      // source=first means start from origin, roundtrip=false for one-way
      final url = '$_osrmBaseUrl/trip/v1/driving/$coordString'
          '?source=first&roundtrip=false&geometries=polyline&overview=full';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 'Ok' && data['trips'].isNotEmpty) {
          final trip = data['trips'][0];
          final waypointOrder = (data['waypoints'] as List)
              .map((w) => w['waypoint_index'] as int)
              .toList();

          // Reorder waypoints according to optimization
          // Skip index 0 (origin) and map to original waypoints
          final orderedWaypoints = <RouteWaypoint>[];
          for (int i = 1; i < waypointOrder.length; i++) {
            final originalIndex = waypointOrder[i] - 1; // -1 because origin is at 0
            if (originalIndex >= 0 && originalIndex < waypoints.length) {
              orderedWaypoints.add(waypoints[originalIndex]);
            }
          }

          // Get legs info
          final legs = (trip['legs'] as List).map<RouteInfo>((leg) {
            return RouteInfo(
              polylinePoints: [],
              distanceMeters: (leg['distance'] as num).toDouble(),
              durationSeconds: (leg['duration'] as num).toDouble(),
            );
          }).toList();

          // Decode full route geometry
          final geometry = trip['geometry'] as String;
          final fullRoute = _decodePolyline(geometry);

          // Update first leg with full geometry for display
          if (legs.isNotEmpty) {
            legs[0] = RouteInfo(
              polylinePoints: fullRoute,
              distanceMeters: legs[0].distanceMeters,
              durationSeconds: legs[0].durationSeconds,
            );
          }

          return OptimizedRoute(
            orderedWaypoints: orderedWaypoints,
            legs: legs,
            totalDistanceMeters: (trip['distance'] as num).toDouble(),
            totalDurationSeconds: (trip['duration'] as num).toDouble(),
          );
        }
      }

      // Fallback: return waypoints in original order with straight-line routes
      return _fallbackOptimization(origin, waypoints);
    } catch (e) {
      return _fallbackOptimization(origin, waypoints);
    }
  }

  /// Fallback when OSRM is unavailable - uses nearest neighbor heuristic
  Future<OptimizedRoute?> _fallbackOptimization(
    LatLng origin,
    List<RouteWaypoint> waypoints,
  ) async {
    if (waypoints.isEmpty) return null;

    // Simple nearest neighbor algorithm
    final remaining = List<RouteWaypoint>.from(waypoints);
    final ordered = <RouteWaypoint>[];
    final legs = <RouteInfo>[];
    var currentPos = origin;
    var totalDistance = 0.0;
    var totalDuration = 0.0;

    while (remaining.isNotEmpty) {
      // Find nearest waypoint
      var nearestIndex = 0;
      var nearestDistance = _haversineDistance(currentPos, remaining[0].location);

      for (int i = 1; i < remaining.length; i++) {
        final dist = _haversineDistance(currentPos, remaining[i].location);
        if (dist < nearestDistance) {
          nearestDistance = dist;
          nearestIndex = i;
        }
      }

      final nearest = remaining.removeAt(nearestIndex);
      ordered.add(nearest);

      // Create leg info
      final route = _straightLineRoute(currentPos, nearest.location);
      legs.add(route);
      totalDistance += route.distanceMeters;
      totalDuration += route.durationSeconds;

      currentPos = nearest.location;
    }

    return OptimizedRoute(
      orderedWaypoints: ordered,
      legs: legs,
      totalDistanceMeters: totalDistance,
      totalDurationSeconds: totalDuration,
    );
  }

  /// Calculate haversine distance between two points in meters
  double _haversineDistance(LatLng p1, LatLng p2) {
    const earthRadius = 6371000.0; // meters

    final dLat = _toRadians(p2.latitude - p1.latitude);
    final dLon = _toRadians(p2.longitude - p1.longitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(p1.latitude)) *
            cos(_toRadians(p2.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  /// Create a straight-line route as fallback
  RouteInfo _straightLineRoute(LatLng origin, LatLng destination) {
    final distance = _haversineDistance(origin, destination);
    // Estimate duration at 30 mph average
    final duration = distance / 13.4; // 30 mph = 13.4 m/s

    return RouteInfo(
      polylinePoints: [origin, destination],
      distanceMeters: distance,
      durationSeconds: duration,
    );
  }

  /// Decode Google polyline format (used by OSRM)
  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      // Decode latitude
      int shift = 0;
      int result = 0;
      int byte;

      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);

      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      // Decode longitude
      shift = 0;
      result = 0;

      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);

      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }
}
