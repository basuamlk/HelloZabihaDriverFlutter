import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/delivery.dart';
import '../services/delivery_service.dart';

class DeliveryDetailProvider extends ChangeNotifier {
  final DeliveryService _deliveryService = DeliveryService.instance;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
