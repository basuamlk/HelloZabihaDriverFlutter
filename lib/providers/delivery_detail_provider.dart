import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/delivery.dart';
import '../models/order_item.dart';
import '../services/delivery_service.dart';
import '../services/order_service.dart';

class DeliveryDetailProvider extends ChangeNotifier {
  final DeliveryService _deliveryService = DeliveryService.instance;
  final OrderService _orderService = OrderService.instance;

  bool _isLoading = false;
  String? _errorMessage;
  List<OrderItem> _orderItems = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<OrderItem> get orderItems => _orderItems;

  /// Load order items for a delivery
  Future<void> loadOrderItems(String orderId) async {
    _orderItems = await _orderService.getOrderItems(orderId);
    notifyListeners();
  }

  /// Clear order items when leaving detail screen
  void clearOrderItems() {
    _orderItems = [];
  }

  Future<Delivery?> updateStatus(Delivery delivery, DeliveryStatus newStatus) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _deliveryService.updateDeliveryStatus(
        delivery.id,
        newStatus,
      );
      _isLoading = false;
      notifyListeners();
      return updated;
    } catch (e) {
      _errorMessage = 'Failed to update status';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Confirm pickup with optional photo
  Future<Delivery?> confirmPickup(String deliveryId, {File? photo}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? photoUrl;
      if (photo != null) {
        photoUrl = await _deliveryService.uploadDeliveryPhoto(
          deliveryId,
          photo,
          type: 'pickup',
        );
      }

      final updated = await _deliveryService.confirmPickup(
        deliveryId,
        photoUrl: photoUrl,
      );
      _isLoading = false;
      notifyListeners();
      return updated;
    } catch (e) {
      _errorMessage = 'Failed to confirm pickup';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Start delivery (en route)
  Future<Delivery?> startDelivery(String deliveryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _deliveryService.startDelivery(deliveryId);
      _isLoading = false;
      notifyListeners();
      return updated;
    } catch (e) {
      _errorMessage = 'Failed to start delivery';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Mark as nearby (15 min away)
  Future<Delivery?> markNearby(String deliveryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _deliveryService.markNearby(deliveryId);
      _isLoading = false;
      notifyListeners();
      return updated;
    } catch (e) {
      _errorMessage = 'Failed to update status';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Complete delivery with photo and optional signature
  Future<Delivery?> completeDelivery(
    String deliveryId, {
    required File deliveryPhoto,
    File? signatureImage,
    String? recipientName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Upload delivery photo
      final photoUrl = await _deliveryService.uploadDeliveryPhoto(
        deliveryId,
        deliveryPhoto,
        type: 'delivery',
      );

      if (photoUrl == null) {
        _errorMessage = 'Failed to upload delivery photo';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // Upload signature if provided
      String? signatureUrl;
      if (signatureImage != null) {
        signatureUrl = await _deliveryService.uploadSignature(
          deliveryId,
          signatureImage,
        );
      }

      final updated = await _deliveryService.completeDelivery(
        deliveryId,
        deliveryPhotoUrl: photoUrl,
        signatureUrl: signatureUrl,
        recipientName: recipientName,
      );
      _isLoading = false;
      notifyListeners();
      return updated;
    } catch (e) {
      _errorMessage = 'Failed to complete delivery';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Mark delivery as failed
  Future<Delivery?> failDelivery(String deliveryId, {String? reason}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _deliveryService.failDelivery(
        deliveryId,
        reason: reason,
      );
      _isLoading = false;
      notifyListeners();
      return updated;
    } catch (e) {
      _errorMessage = 'Failed to update status';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Update ETA
  Future<Delivery?> updateETA(String deliveryId, int estimatedMinutes) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _deliveryService.updateETA(deliveryId, estimatedMinutes);
      _isLoading = false;
      notifyListeners();
      return updated;
    } catch (e) {
      _errorMessage = 'Failed to update ETA';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> callCustomer(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> openGoogleMaps(double? lat, double? lon, String address) async {
    Uri uri;
    if (lat != null && lon != null) {
      uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon');
    } else {
      final encodedAddress = Uri.encodeComponent(address);
      uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$encodedAddress');
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> openAppleMaps(double? lat, double? lon, String address) async {
    Uri uri;
    if (lat != null && lon != null) {
      uri = Uri.parse('https://maps.apple.com/?daddr=$lat,$lon');
    } else {
      final encodedAddress = Uri.encodeComponent(address);
      uri = Uri.parse('https://maps.apple.com/?daddr=$encodedAddress');
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
