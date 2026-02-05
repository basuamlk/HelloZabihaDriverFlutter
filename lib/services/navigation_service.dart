import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';

enum NavigationApp {
  googleMaps,
  appleMaps,
  waze,
}

extension NavigationAppExtension on NavigationApp {
  String get displayName {
    switch (this) {
      case NavigationApp.googleMaps:
        return 'Google Maps';
      case NavigationApp.appleMaps:
        return 'Apple Maps';
      case NavigationApp.waze:
        return 'Waze';
    }
  }

  IconData get icon {
    switch (this) {
      case NavigationApp.googleMaps:
        return Icons.map;
      case NavigationApp.appleMaps:
        return Icons.explore;
      case NavigationApp.waze:
        return Icons.navigation;
    }
  }

  Color get color {
    switch (this) {
      case NavigationApp.googleMaps:
        return const Color(0xFF4285F4);
      case NavigationApp.appleMaps:
        return const Color(0xFF007AFF);
      case NavigationApp.waze:
        return const Color(0xFF33CCFF);
    }
  }
}

class NavigationService {
  static NavigationService? _instance;
  static NavigationService get instance => _instance ??= NavigationService._();

  NavigationService._();

  /// Get list of available navigation apps on this device
  List<NavigationApp> get availableApps {
    final apps = <NavigationApp>[NavigationApp.googleMaps];

    if (Platform.isIOS) {
      apps.add(NavigationApp.appleMaps);
    }

    apps.add(NavigationApp.waze);

    return apps;
  }

  /// Launch navigation to a single destination
  Future<bool> navigateTo({
    required double latitude,
    required double longitude,
    String? address,
    NavigationApp? preferredApp,
  }) async {
    final app = preferredApp ?? NavigationApp.googleMaps;

    final uri = _buildNavigationUri(
      app: app,
      destinationLat: latitude,
      destinationLng: longitude,
      address: address,
    );

    if (uri != null && await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    // Fallback to Google Maps web
    final webUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
    );
    return await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  /// Launch navigation with multiple stops
  Future<bool> navigateWithStops({
    required LatLng origin,
    required List<LatLng> waypoints,
    required LatLng destination,
    NavigationApp? preferredApp,
  }) async {
    final app = preferredApp ?? NavigationApp.googleMaps;

    switch (app) {
      case NavigationApp.googleMaps:
        return _launchGoogleMapsWithStops(origin, waypoints, destination);
      case NavigationApp.appleMaps:
        // Apple Maps doesn't support waypoints via URL, navigate to first stop
        return navigateTo(
          latitude: waypoints.isNotEmpty ? waypoints.first.latitude : destination.latitude,
          longitude: waypoints.isNotEmpty ? waypoints.first.longitude : destination.longitude,
          preferredApp: NavigationApp.appleMaps,
        );
      case NavigationApp.waze:
        // Waze doesn't support multiple waypoints, navigate to first stop
        return navigateTo(
          latitude: waypoints.isNotEmpty ? waypoints.first.latitude : destination.latitude,
          longitude: waypoints.isNotEmpty ? waypoints.first.longitude : destination.longitude,
          preferredApp: NavigationApp.waze,
        );
    }
  }

  /// Show a picker dialog for navigation app selection
  Future<NavigationApp?> showNavigationAppPicker(BuildContext context) async {
    return showModalBottomSheet<NavigationApp>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Open with...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Divider(height: 1),
            ...availableApps.map((app) => ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: app.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(app.icon, color: app.color),
              ),
              title: Text(app.displayName),
              onTap: () => Navigator.pop(context, app),
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Navigate with app picker
  Future<bool> navigateWithPicker({
    required BuildContext context,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    final app = await showNavigationAppPicker(context);
    if (app == null) return false;

    return navigateTo(
      latitude: latitude,
      longitude: longitude,
      address: address,
      preferredApp: app,
    );
  }

  Uri? _buildNavigationUri({
    required NavigationApp app,
    required double destinationLat,
    required double destinationLng,
    String? address,
  }) {
    switch (app) {
      case NavigationApp.googleMaps:
        return Uri.parse(
          'https://www.google.com/maps/dir/?api=1'
          '&destination=$destinationLat,$destinationLng'
          '&travelmode=driving',
        );

      case NavigationApp.appleMaps:
        return Uri.parse(
          'https://maps.apple.com/?daddr=$destinationLat,$destinationLng'
          '&dirflg=d',
        );

      case NavigationApp.waze:
        return Uri.parse(
          'https://waze.com/ul?ll=$destinationLat,$destinationLng&navigate=yes',
        );
    }
  }

  Future<bool> _launchGoogleMapsWithStops(
    LatLng origin,
    List<LatLng> waypoints,
    LatLng destination,
  ) async {
    // Google Maps supports waypoints via URL
    var url = 'https://www.google.com/maps/dir/?api=1'
        '&origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&travelmode=driving';

    if (waypoints.isNotEmpty) {
      final waypointsStr = waypoints
          .map((w) => '${w.latitude},${w.longitude}')
          .join('|');
      url += '&waypoints=$waypointsStr';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Open location in maps (view only, no navigation)
  Future<bool> openInMaps({
    required double latitude,
    required double longitude,
    String? label,
    NavigationApp? preferredApp,
  }) async {
    final app = preferredApp ?? NavigationApp.googleMaps;

    Uri? uri;
    switch (app) {
      case NavigationApp.googleMaps:
        final labelParam = label != null ? '($label)' : '';
        uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude$labelParam',
        );
        break;
      case NavigationApp.appleMaps:
        final labelParam = label != null ? '&q=${Uri.encodeComponent(label)}' : '';
        uri = Uri.parse(
          'https://maps.apple.com/?ll=$latitude,$longitude$labelParam',
        );
        break;
      case NavigationApp.waze:
        uri = Uri.parse(
          'https://waze.com/ul?ll=$latitude,$longitude',
        );
        break;
    }

    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Call a phone number
  Future<bool> callPhone(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }

  /// Send SMS
  Future<bool> sendSms(String phoneNumber, {String? message}) async {
    final body = message != null ? '?body=${Uri.encodeComponent(message)}' : '';
    final uri = Uri.parse('sms:$phoneNumber$body');
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }
}
