import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/connectivity_service.dart';

class ConnectivityProvider extends ChangeNotifier {
  final ConnectivityService _connectivityService = ConnectivityService.instance;
  StreamSubscription<bool>? _subscription;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    await _connectivityService.initialize();
    _isConnected = _connectivityService.isConnected;

    _subscription = _connectivityService.connectivityStream.listen((connected) {
      _isConnected = connected;
      notifyListeners();
    });
  }

  Future<bool> checkConnectivity() async {
    _isConnected = await _connectivityService.checkConnectivity();
    notifyListeners();
    return _isConnected;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
