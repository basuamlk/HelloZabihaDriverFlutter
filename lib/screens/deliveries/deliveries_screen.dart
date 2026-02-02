import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/delivery.dart';
import '../../providers/deliveries_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/delivery_row.dart';
import '../../widgets/status_badge.dart';
import 'delivery_detail_screen.dart';

class DeliveriesScreen extends StatefulWidget {
  const DeliveriesScreen({super.key});

  @override
  State<DeliveriesScreen> createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends State<DeliveriesScreen> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService.instance;
  StreamSubscription<Position>? _positionSubscription;

  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveriesProvider>().loadDeliveries();
      _initializeLocation();
    });
  }

  Future<void> _initializeLocation() async {
    // Get current position
    final position = await _locationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      _updateMapView();
    }

    // Listen to position updates
    _locationService.startTracking();
    _positionSubscription = _locationService.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        _updateMarkers();
        _animateToCurrentPosition();
      }
    });
  }

  void _updateMapView() {
    _updateMarkers();
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 14),
      );
    }
  }

  void _animateToCurrentPosition() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(_currentPosition!),
      );
    }
  }

  void _updateMarkers() {
    final deliveries = context.read<DeliveriesProvider>().deliveries;
    final activeDelivery = _getActiveDelivery(deliveries);
    final upcomingDeliveries = _getUpcomingDeliveries(deliveries);

    final markers = <Marker>{};

    // Driver marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'You'),
        ),
      );
    }

    // Active delivery marker (green)
    if (activeDelivery != null &&
        activeDelivery.deliveryLatitude != null &&
        activeDelivery.deliveryLongitude != null) {
      markers.add(
        Marker(
          markerId: MarkerId('active_${activeDelivery.id}'),
          position: LatLng(
            activeDelivery.deliveryLatitude!,
            activeDelivery.deliveryLongitude!,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Active: ${activeDelivery.customerName}',
            snippet: activeDelivery.deliveryAddress,
          ),
        ),
      );

      // Draw route to active delivery
      _drawRouteToDestination(activeDelivery);
    }

    // Upcoming delivery markers (orange)
    for (int i = 0; i < upcomingDeliveries.length; i++) {
      final delivery = upcomingDeliveries[i];
      if (delivery.deliveryLatitude != null && delivery.deliveryLongitude != null) {
        markers.add(
          Marker(
            markerId: MarkerId('upcoming_${delivery.id}'),
            position: LatLng(
              delivery.deliveryLatitude!,
              delivery.deliveryLongitude!,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(
              title: '${i + 1}. ${delivery.customerName}',
              snippet: delivery.deliveryAddress,
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  void _drawRouteToDestination(Delivery delivery) {
    if (_currentPosition == null ||
        delivery.deliveryLatitude == null ||
        delivery.deliveryLongitude == null) {
      return;
    }

    // Simple straight line for now - can be replaced with actual routing API
    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      points: [
        _currentPosition!,
        LatLng(delivery.deliveryLatitude!, delivery.deliveryLongitude!),
      ],
      color: Colors.blue,
      width: 4,
      patterns: [PatternItem.dash(20), PatternItem.gap(10)],
    );

    setState(() {
      _polylines = {polyline};
    });
  }

  Delivery? _getActiveDelivery(List<Delivery> deliveries) {
    try {
      return deliveries.firstWhere((d) => d.status.isActive);
    } catch (_) {
      // No active delivery, check for assigned
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
        .where((d) =>
            d.status.isPending &&
            d.id != active?.id)
        .toList();
  }

  List<Delivery> _getCompletedDeliveries(List<Delivery> deliveries) {
    return deliveries
        .where((d) => d.status == DeliveryStatus.completed || d.status == DeliveryStatus.failed)
        .toList();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Deliveries'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _animateToCurrentPosition,
            tooltip: 'Center on my location',
          ),
        ],
      ),
      body: Consumer<DeliveriesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.deliveries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final activeDelivery = _getActiveDelivery(provider.deliveries);
          final upcomingDeliveries = _getUpcomingDeliveries(provider.deliveries);
          final completedDeliveries = _getCompletedDeliveries(provider.deliveries);

          // Update markers when deliveries change
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _updateMarkers();
          });

          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: CustomScrollView(
              slivers: [
                // Map Section
                SliverToBoxAdapter(
                  child: _buildMapSection(activeDelivery),
                ),

                // Active Delivery Section
                if (activeDelivery != null) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      'Active Delivery',
                      icon: Icons.local_shipping,
                      color: Colors.green,
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
                      subtitle: 'Route order will be optimized',
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
                        return _buildDeliveryItem(delivery, null, isCompleted: true);
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

                // Bottom padding
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

  Widget _buildMapSection(Delivery? activeDelivery) {
    return Container(
      height: 280,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition ?? const LatLng(37.7749, -122.4194),
                zoom: 14,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                _updateMapView();
              },
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: false, // Using custom marker instead
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
            // Destination info overlay
            if (activeDelivery != null)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.navigation,
                          color: Colors.green,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              activeDelivery.customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              activeDelivery.deliveryAddress,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(status: activeDelivery.status, compact: true),
                    ],
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
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Getting your location...'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
        ],
      ),
    );
  }

  Widget _buildActiveDeliveryCard(Delivery delivery) {
    return GestureDetector(
      onTap: () => _navigateToDetail(delivery.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade100],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
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
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.inventory_2, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${delivery.itemCount} items',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(width: 16),
                Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                Text(
                  '\$${delivery.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, color: Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryItem(Delivery delivery, int? orderNumber, {bool isCompleted = false}) {
    return GestureDetector(
      onTap: () => _navigateToDetail(delivery.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            // Order number or status icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.grey.withValues(alpha: 0.15)
                    : Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: isCompleted
                    ? Icon(
                        delivery.status == DeliveryStatus.completed
                            ? Icons.check
                            : Icons.close,
                        color: delivery.status == DeliveryStatus.completed
                            ? Colors.green
                            : Colors.red,
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    delivery.customerName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? Colors.grey : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    delivery.deliveryAddress,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
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
                    color: isCompleted ? Colors.grey : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${delivery.itemCount} items',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
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
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Deliveries',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your deliveries will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(String deliveryId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryDetailScreen(deliveryId: deliveryId),
      ),
    ).then((_) {
      // Refresh when returning from detail
      context.read<DeliveriesProvider>().refresh();
    });
  }
}
