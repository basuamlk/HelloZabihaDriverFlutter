import 'package:flutter/foundation.dart';
import '../models/delivery.dart';
import '../services/delivery_service.dart';

enum DeliveryFilter { all, pending, completed }

class DeliveriesProvider extends ChangeNotifier {
  final DeliveryService _deliveryService = DeliveryService.instance;

  List<Delivery> _allDeliveries = [];
  DeliveryFilter _currentFilter = DeliveryFilter.all;
  bool _isLoading = false;
  String? _errorMessage;

  List<Delivery> get deliveries {
    switch (_currentFilter) {
      case DeliveryFilter.all:
        return _allDeliveries;
      case DeliveryFilter.pending:
        return _allDeliveries.where((d) => d.status.isPending).toList();
      case DeliveryFilter.completed:
        return _allDeliveries
            .where((d) => d.status == DeliveryStatus.completed)
            .toList();
    }
  }

  DeliveryFilter get currentFilter => _currentFilter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadDeliveries() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allDeliveries = await _deliveryService.getDriverDeliveries();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load deliveries';
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(DeliveryFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadDeliveries();
  }

  Delivery? getDeliveryById(String id) {
    try {
      return _allDeliveries.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  void updateDeliveryLocally(Delivery updatedDelivery) {
    final index =
        _allDeliveries.indexWhere((d) => d.id == updatedDelivery.id);
    if (index != -1) {
      _allDeliveries[index] = updatedDelivery;
      notifyListeners();
    }
  }
}
