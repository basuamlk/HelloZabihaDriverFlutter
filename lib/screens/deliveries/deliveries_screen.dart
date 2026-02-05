import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/delivery.dart';
import '../../providers/deliveries_provider.dart';
import '../../services/location_service.dart';
import '../../services/routing_service.dart';
import '../../services/navigation_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';
import 'delivery_detail_screen.dart';

class DeliveriesScreen extends StatefulWidget {
  const DeliveriesScreen({super.key});

  @override
  State<DeliveriesScreen> createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends State<DeliveriesScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService.instance;
  final RoutingService _routingService = RoutingService.instance;
  final NavigationService _navigationService = NavigationService.instance;
  StreamSubscription<Position>? _positionSubscription;

  LatLng? _currentPosition;
  bool _mapReady = false;
  RouteInfo? _activeRoute;
  bool _isLoadingRoute = false;
  String? _lastRouteKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveriesProvider>().loadDeliveries();
      _initializeLocation();
    });
  }

  Future<void> _initializeLocation() async {
    final position = await _locationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      _centerOnCurrentPosition();
    }

    _locationService.startTracking();
    _positionSubscription = _locationService.positionStream.listen((position) {
      if (mounted) {
        final newPos = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentPosition = newPos;
        });
        // Refresh route if position changed significantly
        _checkAndRefreshRoute();
      }
    });
  }

  void _checkAndRefreshRoute() {
    final deliveries = context.read<DeliveriesProvider>().deliveries;
    final activeDelivery = _getActiveDelivery(deliveries);
    if (activeDelivery != null && _currentPosition != null) {
      _loadRouteForDelivery(activeDelivery);
    }
  }

  Future<void> _loadRouteForDelivery(Delivery delivery) async {
    if (_currentPosition == null ||
        delivery.deliveryLatitude == null ||
        delivery.deliveryLongitude == null) {
      return;
    }

    // Create a key to avoid redundant route fetches
    final routeKey = '${_currentPosition!.latitude.toStringAsFixed(3)},'
        '${_currentPosition!.longitude.toStringAsFixed(3)}-'
        '${delivery.deliveryLatitude!.toStringAsFixed(3)},'
        '${delivery.deliveryLongitude!.toStringAsFixed(3)}';

    if (routeKey == _lastRouteKey) return;
    _lastRouteKey = routeKey;

    setState(() => _isLoadingRoute = true);

    final destination = LatLng(
      delivery.deliveryLatitude!,
      delivery.deliveryLongitude!,
    );

    // Check if there's a pickup location to include
    LatLng? pickup;
    if (delivery.status == DeliveryStatus.assigned &&
        delivery.pickupLatitude != null &&
        delivery.pickupLongitude != null) {
      pickup = LatLng(delivery.pickupLatitude!, delivery.pickupLongitude!);
    }

    RouteInfo? route;
    if (pickup != null) {
      // Route to pickup location first
      route = await _routingService.getRoute(_currentPosition!, pickup);
    } else {
      // Route directly to delivery destination
      route = await _routingService.getRoute(_currentPosition!, destination);
    }

    if (mounted) {
      setState(() {
        _activeRoute = route;
        _isLoadingRoute = false;
      });
    }
  }

  void _centerOnCurrentPosition() {
    if (_currentPosition != null && _mapReady) {
      _mapController.move(_currentPosition!, 14);
    }
  }

  void _fitBoundsToRoute() {
    if (_activeRoute == null || _activeRoute!.polylinePoints.isEmpty) return;

    final points = _activeRoute!.polylinePoints;
    if (_currentPosition != null) {
      points.insert(0, _currentPosition!);
    }

    if (points.length < 2) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  Delivery? _getActiveDelivery(List<Delivery> deliveries) {
    try {
      return deliveries.firstWhere((d) => d.status.isActive);
    } catch (_) {
      try {
        return deliveries.firstWhere((d) => d.status == DeliveryStatus.assigned);
      } catch (_) {
        return null;
      }
    }
  }

  List<Delivery> _getUpcomingDeliveries(List<Delivery> deliveries) {
    final active = _getActiveDelivery(deliveries);
    return deliveries
        .where((d) => d.status.isPending && d.id != active?.id)
        .toList();
  }

  List<Delivery> _getCompletedDeliveries(List<Delivery> deliveries) {
    return deliveries
        .where((d) =>
            d.status == DeliveryStatus.completed ||
            d.status == DeliveryStatus.failed)
        .toList();
  }

  List<Marker> _buildMarkers(List<Delivery> deliveries) {
    final markers = <Marker>[];
    final activeDelivery = _getActiveDelivery(deliveries);
    final upcomingDeliveries = _getUpcomingDeliveries(deliveries);

    // Driver marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: _currentPosition!,
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const Icon(
              Icons.navigation,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      );
    }

    // Pickup marker (if assigned and has pickup location)
    if (activeDelivery != null &&
        activeDelivery.status == DeliveryStatus.assigned &&
        activeDelivery.pickupLatitude != null &&
        activeDelivery.pickupLongitude != null) {
      markers.add(
        Marker(
          point: LatLng(
            activeDelivery.pickupLatitude!,
            activeDelivery.pickupLongitude!,
          ),
          width: 40,
          height: 50,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              Container(
                width: 3,
                height: 10,
                color: Colors.blue,
              ),
            ],
          ),
        ),
      );
    }

    // Active delivery marker
    if (activeDelivery != null &&
        activeDelivery.deliveryLatitude != null &&
        activeDelivery.deliveryLongitude != null) {
      markers.add(
        Marker(
          point: LatLng(
            activeDelivery.deliveryLatitude!,
            activeDelivery.deliveryLongitude!,
          ),
          width: 40,
          height: 50,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              Container(
                width: 3,
                height: 10,
                color: AppTheme.primaryGreen,
              ),
            ],
          ),
        ),
      );
    }

    // Upcoming delivery markers
    for (int i = 0; i < upcomingDeliveries.length; i++) {
      final delivery = upcomingDeliveries[i];
      if (delivery.deliveryLatitude != null &&
          delivery.deliveryLongitude != null) {
        markers.add(
          Marker(
            point: LatLng(
              delivery.deliveryLatitude!,
              delivery.deliveryLongitude!,
            ),
            width: 36,
            height: 36,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  List<Polyline> _buildPolylines(List<Delivery> deliveries) {
    final polylines = <Polyline>[];
    final activeDelivery = _getActiveDelivery(deliveries);

    // Show actual route if available
    if (_activeRoute != null && _activeRoute!.polylinePoints.isNotEmpty) {
      polylines.add(
        Polyline(
          points: _activeRoute!.polylinePoints,
          color: AppTheme.primaryGreen,
          strokeWidth: 5,
        ),
      );
    } else if (_currentPosition != null &&
        activeDelivery != null &&
        activeDelivery.deliveryLatitude != null &&
        activeDelivery.deliveryLongitude != null) {
      // Fallback to straight line while loading
      polylines.add(
        Polyline(
          points: [
            _currentPosition!,
            LatLng(
              activeDelivery.deliveryLatitude!,
              activeDelivery.deliveryLongitude!,
            ),
          ],
          color: Colors.blue.withValues(alpha: 0.5),
          strokeWidth: 4,
          pattern: const StrokePattern.dotted(),
        ),
      );
    }

    return polylines;
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Deliveries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _centerOnCurrentPosition,
            tooltip: 'Center on my location',
          ),
          IconButton(
            icon: const Icon(Icons.fit_screen),
            onPressed: _fitBoundsToRoute,
            tooltip: 'Fit route',
          ),
        ],
      ),
      body: Consumer<DeliveriesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.deliveries.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            );
          }

          final activeDelivery = _getActiveDelivery(provider.deliveries);
          final upcomingDeliveries = _getUpcomingDeliveries(provider.deliveries);
          final completedDeliveries = _getCompletedDeliveries(provider.deliveries);

          // Load route when deliveries change
          if (activeDelivery != null && _currentPosition != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadRouteForDelivery(activeDelivery);
            });
          }

          return RefreshIndicator(
            color: AppTheme.primaryGreen,
            onRefresh: () async {
              await provider.refresh();
              _lastRouteKey = null; // Force route refresh
            },
            child: CustomScrollView(
              slivers: [
                // Map Section
                SliverToBoxAdapter(
                  child: _buildMapSection(provider.deliveries, activeDelivery),
                ),

                // Route Info Card
                if (_activeRoute != null && activeDelivery != null)
                  SliverToBoxAdapter(
                    child: _buildRouteInfoCard(activeDelivery),
                  ),

                // Active Delivery Section
                if (activeDelivery != null) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      'Active Delivery',
                      icon: Icons.local_shipping,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildActiveDeliveryCard(activeDelivery),
                  ),
                ],

                // Upcoming Deliveries Section
                if (upcomingDeliveries.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      'Upcoming (${upcomingDeliveries.length})',
                      icon: Icons.schedule,
                      color: Colors.orange,
                      trailing: TextButton.icon(
                        onPressed: () => _showOptimizeRouteDialog(upcomingDeliveries),
                        icon: const Icon(Icons.route, size: 16),
                        label: const Text('Optimize'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final delivery = upcomingDeliveries[index];
                        return _buildDeliveryItem(delivery, index + 1);
                      },
                      childCount: upcomingDeliveries.length,
                    ),
                  ),
                ],

                // Completed Deliveries Section
                if (completedDeliveries.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      'Completed (${completedDeliveries.length})',
                      icon: Icons.check_circle,
                      color: Colors.grey,
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final delivery = completedDeliveries[index];
                        return _buildDeliveryItem(delivery, null,
                            isCompleted: true);
                      },
                      childCount: completedDeliveries.length,
                    ),
                  ),
                ],

                // Empty state
                if (provider.deliveries.isEmpty)
                  SliverFillRemaining(
                    child: _buildEmptyState(),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapSection(List<Delivery> deliveries, Delivery? activeDelivery) {
    return Container(
      height: 280,
      margin: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition ?? const LatLng(37.7749, -122.4194),
                initialZoom: 14,
                onMapReady: () {
                  setState(() => _mapReady = true);
                  _centerOnCurrentPosition();
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.hellozabiha.driver',
                ),
                PolylineLayer(
                  polylines: _buildPolylines(deliveries),
                ),
                MarkerLayer(
                  markers: _buildMarkers(deliveries),
                ),
              ],
            ),

            // Route loading indicator
            if (_isLoadingRoute)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Loading route...',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

            // Navigate button
            if (activeDelivery != null)
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  child: InkWell(
                    onTap: () => _startNavigation(activeDelivery),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.navigation, color: Colors.white, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'Navigate',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Loading overlay
            if (_currentPosition == null)
              Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppTheme.primaryGreen),
                      SizedBox(height: 12),
                      Text('Getting your location...'),
                    ],
                  ),
                ),
              ),

            // OSM attribution
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '© OpenStreetMap',
                  style: TextStyle(fontSize: 9, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfoCard(Delivery activeDelivery) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          // ETA
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.timer,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ETA',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      _activeRoute?.formattedDuration ?? '--',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            width: 1,
            height: 40,
            color: AppTheme.inputBorder,
          ),

          // Distance
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.straighten,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distance',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      _activeRoute?.formattedDistance ?? '--',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            width: 1,
            height: 40,
            color: AppTheme.inputBorder,
          ),

          // Status
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                StatusBadge(status: activeDelivery.status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    required IconData icon,
    required Color color,
    String? subtitle,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingM,
        AppTheme.spacingM,
        AppTheme.spacingM,
        AppTheme.spacingS,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildActiveDeliveryCard(Delivery delivery) {
    return GestureDetector(
      onTap: () => _navigateToDetail(delivery.id),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingXS,
        ),
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryGreen.withValues(alpha: 0.1),
              AppTheme.primaryGreen.withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    delivery.customerName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                StatusBadge(status: delivery.status),
              ],
            ),
            const SizedBox(height: AppTheme.spacingS),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    delivery.deliveryAddress,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingS),
            Row(
              children: [
                Icon(Icons.inventory_2, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${delivery.itemCount} items',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                Text(
                  '\$${delivery.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, color: AppTheme.primaryGreen),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryItem(Delivery delivery, int? orderNumber,
      {bool isCompleted = false}) {
    return GestureDetector(
      onTap: () => _navigateToDetail(delivery.id),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingXS,
        ),
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: AppTheme.cardDecoration,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.grey.withValues(alpha: 0.15)
                    : Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Center(
                child: isCompleted
                    ? Icon(
                        delivery.status == DeliveryStatus.completed
                            ? Icons.check
                            : Icons.close,
                        color: delivery.status == DeliveryStatus.completed
                            ? AppTheme.success
                            : AppTheme.error,
                        size: 18,
                      )
                    : Text(
                        '$orderNumber',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    delivery.customerName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? Colors.grey : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    delivery.deliveryAddress,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${delivery.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isCompleted ? Colors.grey : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${delivery.itemCount} items',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppTheme.spacingS),
            Icon(
              Icons.chevron_right,
              color: AppTheme.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 64,
            color: AppTheme.textHint,
          ),
          const SizedBox(height: AppTheme.spacingM),
          const Text(
            'No Deliveries',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          const Text(
            'Your deliveries will appear here',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startNavigation(Delivery delivery) async {
    final lat = delivery.status == DeliveryStatus.assigned
        ? delivery.pickupLatitude ?? delivery.deliveryLatitude
        : delivery.deliveryLatitude;
    final lng = delivery.status == DeliveryStatus.assigned
        ? delivery.pickupLongitude ?? delivery.deliveryLongitude
        : delivery.deliveryLongitude;

    if (lat == null || lng == null) return;

    await _navigationService.navigateWithPicker(
      context: context,
      latitude: lat,
      longitude: lng,
      address: delivery.status == DeliveryStatus.assigned
          ? delivery.pickupAddress ?? delivery.deliveryAddress
          : delivery.deliveryAddress,
    );
  }

  void _showOptimizeRouteDialog(List<Delivery> deliveries) async {
    if (_currentPosition == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: AppTheme.primaryGreen),
            SizedBox(width: 20),
            Text('Optimizing route...'),
          ],
        ),
      ),
    );

    // Build waypoints
    final waypoints = deliveries
        .where((d) => d.deliveryLatitude != null && d.deliveryLongitude != null)
        .map((d) => RouteWaypoint(
              id: d.id,
              location: LatLng(d.deliveryLatitude!, d.deliveryLongitude!),
              label: d.customerName,
            ))
        .toList();

    final optimized = await _routingService.getOptimizedRoute(
      _currentPosition!,
      waypoints,
    );

    if (mounted) Navigator.pop(context);

    if (optimized != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          title: const Row(
            children: [
              Icon(Icons.route, color: AppTheme.primaryGreen),
              SizedBox(width: 8),
              Text('Optimized Route'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total: ${optimized.formattedTotalDistance} • ${optimized.formattedTotalDuration}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Suggested order:',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              ...optimized.orderedWaypoints.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value.label ?? 'Stop ${entry.key + 1}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _launchMultiStopNavigation(optimized);
              },
              icon: const Icon(Icons.navigation, size: 18),
              label: const Text('Navigate'),
            ),
          ],
        ),
      );
    }
  }

  void _launchMultiStopNavigation(OptimizedRoute route) async {
    if (_currentPosition == null || route.orderedWaypoints.isEmpty) return;

    final waypoints = route.orderedWaypoints.map((w) => w.location).toList();
    final destination = waypoints.removeLast();

    await _navigationService.navigateWithStops(
      origin: _currentPosition!,
      waypoints: waypoints,
      destination: destination,
    );
  }

  void _navigateToDetail(String deliveryId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryDetailScreen(deliveryId: deliveryId),
      ),
    ).then((_) {
      context.read<DeliveriesProvider>().refresh();
      _lastRouteKey = null; // Force route refresh
    });
  }
}
