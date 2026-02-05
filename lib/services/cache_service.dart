import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/delivery.dart';
import '../models/driver.dart';

/// Service for caching data locally for offline access
class CacheService {
  static final CacheService instance = CacheService._internal();
  CacheService._internal();

  static const String _deliveriesKey = 'cached_deliveries';
  static const String _driverKey = 'cached_driver';
  static const String _lastSyncKey = 'last_sync_time';
  static const Duration _cacheExpiry = Duration(hours: 24);

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Cache deliveries list
  Future<void> cacheDeliveries(List<Delivery> deliveries) async {
    final p = await prefs;
    final jsonList = deliveries.map((d) => d.toJson()).toList();
    await p.setString(_deliveriesKey, jsonEncode(jsonList));
    await _updateLastSyncTime();
  }

  /// Get cached deliveries
  Future<List<Delivery>> getCachedDeliveries() async {
    final p = await prefs;
    final jsonString = p.getString(_deliveriesKey);
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => Delivery.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Cache driver profile
  Future<void> cacheDriver(Driver driver) async {
    final p = await prefs;
    await p.setString(_driverKey, jsonEncode(driver.toJson()));
    await _updateLastSyncTime();
  }

  /// Get cached driver profile
  Future<Driver?> getCachedDriver() async {
    final p = await prefs;
    final jsonString = p.getString(_driverKey);
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return Driver.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Update last sync timestamp
  Future<void> _updateLastSyncTime() async {
    final p = await prefs;
    await p.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    final p = await prefs;
    final timestamp = p.getInt(_lastSyncKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Check if cache is expired
  Future<bool> isCacheExpired() async {
    final lastSync = await getLastSyncTime();
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync) > _cacheExpiry;
  }

  /// Get formatted last sync string
  Future<String> getLastSyncString() async {
    final lastSync = await getLastSyncTime();
    if (lastSync == null) return 'Never synced';

    final now = DateTime.now();
    final diff = now.difference(lastSync);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    final p = await prefs;
    await p.remove(_deliveriesKey);
    await p.remove(_driverKey);
    await p.remove(_lastSyncKey);
  }

  /// Clear cache for a specific user (call on logout)
  Future<void> clearUserCache() async {
    await clearCache();
  }
}
