import 'package:flutter/foundation.dart';
import '../models/delivery.dart';
import '../services/delivery_service.dart';
import '../services/cache_service.dart';
import '../utils/error_handler.dart';

enum DeliveryFilter { all, pending, completed }

class DeliveriesProvider extends ChangeNotifier {
  final DeliveryService _deliveryService = DeliveryService.instance;
  final CacheService _cacheService = CacheService.instance;

  List<Delivery> _allDeliveries = [];
  DeliveryFilter _currentFilter = DeliveryFilter.all;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isFromCache = false;
  String? _lastSyncTime;

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
  bool get isFromCache => _isFromCache;
  String? get lastSyncTime => _lastSyncTime;

  Future<void> loadDeliveries() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Try to fetch from network
      _allDeliveries = await _deliveryService.getDriverDeliveries();
      _isFromCache = false;

      // Cache the data for offline use
      await _cacheService.cacheDeliveries(_allDeliveries);
      _lastSyncTime = await _cacheService.getLastSyncString();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Try to load from cache on network error
      final cachedDeliveries = await _cacheService.getCachedDeliveries();
      if (cachedDeliveries.isNotEmpty) {
        _allDeliveries = cachedDeliveries;
        _isFromCache = true;
        _lastSyncTime = await _cacheService.getLastSyncString();
        _errorMessage = null; // Clear error since we have cached data
      } else {
        _errorMessage = ErrorHandler.getUserMessage(e);
      }
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
