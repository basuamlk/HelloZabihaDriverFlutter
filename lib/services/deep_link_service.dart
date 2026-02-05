import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import '../screens/deliveries/delivery_detail_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/earnings/earnings_screen.dart';

/// Service for handling deep links in the app.
/// Supports the following URL schemes:
/// - io.hellozabiha.driver://delivery/{id} -> DeliveryDetailScreen
/// - io.hellozabiha.driver://notifications -> NotificationsScreen
/// - io.hellozabiha.driver://profile -> ProfileScreen
/// - io.hellozabiha.driver://earnings -> EarningsScreen
class DeepLinkService {
  static DeepLinkService? _instance;
  static DeepLinkService get instance {
    _instance ??= DeepLinkService._();
    return _instance!;
  }

  DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  GlobalKey<NavigatorState>? _navigatorKey;
  Uri? _pendingDeepLink;
  bool _isInitialized = false;

  /// Initialize the deep link service with a navigator key.
  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    if (_isInitialized) return;

    _navigatorKey = navigatorKey;
    _isInitialized = true;

    // Handle initial link (cold start)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _pendingDeepLink = initialUri;
      }
    } catch (e) {
      debugPrint('DeepLinkService: Error getting initial link: $e');
    }

    // Listen for links while app is running (foreground/background)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleIncomingLink,
      onError: (err) {
        debugPrint('DeepLinkService: Error in link stream: $err');
      },
    );
  }

  /// Check if there's a pending deep link to process.
  bool get hasPendingDeepLink => _pendingDeepLink != null;

  /// Process any pending deep link after authentication.
  /// Call this after the user has successfully authenticated.
  void processPendingDeepLink() {
    if (_pendingDeepLink != null) {
      _handleDeepLink(_pendingDeepLink!);
      _pendingDeepLink = null;
    }
  }

  /// Store a deep link to be processed later (when not authenticated).
  void storePendingDeepLink(Uri uri) {
    _pendingDeepLink = uri;
  }

  void _handleIncomingLink(Uri uri) {
    debugPrint('DeepLinkService: Received link: $uri');
    _handleDeepLink(uri);
  }

  void _handleDeepLink(Uri uri) {
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      debugPrint('DeepLinkService: Navigator not available, storing pending link');
      _pendingDeepLink = uri;
      return;
    }

    final route = _parseDeepLink(uri);
    if (route != null) {
      navigator.push(route);
    }
  }

  MaterialPageRoute<dynamic>? _parseDeepLink(Uri uri) {
    // Validate scheme
    if (uri.scheme != 'io.hellozabiha.driver') {
      debugPrint('DeepLinkService: Unknown scheme: ${uri.scheme}');
      return null;
    }

    final path = uri.host.isEmpty ? uri.pathSegments : [uri.host, ...uri.pathSegments];

    if (path.isEmpty) {
      debugPrint('DeepLinkService: Empty path');
      return null;
    }

    final routeName = path.first;

    switch (routeName) {
      case 'delivery':
        if (path.length > 1) {
          final deliveryId = path[1];
          return MaterialPageRoute(
            builder: (_) => DeliveryDetailScreen(deliveryId: deliveryId),
          );
        }
        debugPrint('DeepLinkService: Missing delivery ID');
        return null;

      case 'notifications':
        return MaterialPageRoute(
          builder: (_) => const NotificationsScreen(),
        );

      case 'profile':
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        );

      case 'earnings':
        return MaterialPageRoute(
          builder: (_) => const EarningsScreen(),
        );

      default:
        debugPrint('DeepLinkService: Unknown route: $routeName');
        return null;
    }
  }

  /// Clean up resources.
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _isInitialized = false;
    _navigatorKey = null;
    _pendingDeepLink = null;
  }
}
