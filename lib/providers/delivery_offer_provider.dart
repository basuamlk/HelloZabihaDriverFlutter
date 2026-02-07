import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/delivery.dart';
import '../models/delivery_offer.dart';
import '../services/offer_service.dart';
import '../services/delivery_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';

/// Info about a declined offer + whether the delivery is still available
class DeclinedOfferInfo {
  final DeliveryOffer offer;
  final Delivery? delivery;
  final bool isAvailable;

  DeclinedOfferInfo({
    required this.offer,
    this.delivery,
    this.isAvailable = false,
  });
}

class DeliveryOfferProvider extends ChangeNotifier {
  final OfferService _offerService = OfferService.instance;
  final DeliveryService _deliveryService = DeliveryService.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final AuthService _authService = AuthService.instance;

  DeliveryOffer? _currentOffer;
  Delivery? _currentOfferDelivery;
  List<DeclinedOfferInfo> _declinedOffers = [];
  int _remainingSeconds = 0;
  bool _isResponding = false;
  String? _errorMessage;
  Timer? _countdownTimer;
  StreamSubscription? _offerSubscription;
  bool _offerScreenShowing = false;

  DeliveryOffer? get currentOffer => _currentOffer;
  Delivery? get currentOfferDelivery => _currentOfferDelivery;
  List<DeclinedOfferInfo> get declinedOffers => _declinedOffers;
  int get remainingSeconds => _remainingSeconds;
  bool get isResponding => _isResponding;
  String? get errorMessage => _errorMessage;
  bool get hasActiveOffer => _currentOffer != null && _remainingSeconds > 0;
  bool get offerScreenShowing => _offerScreenShowing;

  String get countdownDisplay {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get countdownProgress {
    if (_currentOffer == null) return 0.0;
    final totalSeconds = _currentOffer!.expiresAt.difference(_currentOffer!.offeredAt).inSeconds;
    if (totalSeconds <= 0) return 0.0;
    return _remainingSeconds / totalSeconds;
  }

  void setOfferScreenShowing(bool showing) {
    _offerScreenShowing = showing;
  }

  Future<void> initialize() async {
    _startOfferSubscription();
    // Check for any existing active offer on startup
    await _checkForActiveOffer();
  }

  void _startOfferSubscription() {
    final userId = _authService.currentUser?.id;
    if (userId == null) {
      Future.delayed(const Duration(seconds: 5), () {
        if (_authService.currentUser != null) {
          _startOfferSubscription();
        }
      });
      return;
    }

    _offerSubscription?.cancel();

    try {
      _offerSubscription = _offerService.subscribeToOffers().listen(
        (List<Map<String, dynamic>> data) {
          _handleOfferUpdates(data);
        },
        onError: (error) {
          debugPrint('Offer subscription error: $error');
          Future.delayed(const Duration(seconds: 30), () {
            if (_authService.currentUser != null) {
              _startOfferSubscription();
            }
          });
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('Failed to start offer subscription: $e');
    }
  }

  void _handleOfferUpdates(List<Map<String, dynamic>> data) {
    for (final item in data) {
      try {
        final offer = DeliveryOffer.fromJson(item);

        // Detect new pending offer
        if (offer.status == OfferStatus.pending && !offer.isExpired) {
          if (_currentOffer == null || _currentOffer!.id != offer.id) {
            _onOfferReceived(offer);
          }
        }
      } catch (e) {
        debugPrint('Error processing offer update: $e');
      }
    }
  }

  Future<void> _checkForActiveOffer() async {
    try {
      final activeOffer = await _offerService.getActiveOffer();
      if (activeOffer != null && !activeOffer.isExpired) {
        await _onOfferReceived(activeOffer);
      }
    } catch (e) {
      debugPrint('Error checking for active offer: $e');
    }
  }

  Future<void> _onOfferReceived(DeliveryOffer offer) async {
    // Fetch delivery details for this offer
    try {
      final delivery = await _deliveryService.getDelivery(offer.deliveryId);
      if (delivery == null) return;

      _currentOffer = offer;
      _currentOfferDelivery = delivery;
      _errorMessage = null;

      // Start countdown
      _startCountdown();

      // Play notification sound + vibration
      _notificationService.vibrateUrgent();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading offer delivery: $e');
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();

    if (_currentOffer == null) return;

    _updateRemainingTime();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemainingTime();

      if (_remainingSeconds <= 0) {
        _onCountdownExpired();
      }
    });
  }

  void _updateRemainingTime() {
    if (_currentOffer == null) {
      _remainingSeconds = 0;
      return;
    }
    final remaining = _currentOffer!.expiresAt.difference(DateTime.now());
    _remainingSeconds = remaining.inSeconds.clamp(0, 300);
    notifyListeners();
  }

  Future<void> _onCountdownExpired() async {
    _countdownTimer?.cancel();
    if (_currentOffer == null) return;

    // Auto-decline via Edge Function (marks as expired server-side)
    try {
      await _offerService.checkExpiredOffers();
    } catch (e) {
      debugPrint('Error auto-expiring offer: $e');
    }

    final expiredOffer = _currentOffer;
    _currentOffer = null;
    _currentOfferDelivery = null;
    _remainingSeconds = 0;
    notifyListeners();

    // Refresh declined offers
    if (expiredOffer != null) {
      await loadDeclinedOffers();
    }
  }

  Future<bool> acceptOffer() async {
    if (_currentOffer == null) return false;

    _isResponding = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _offerService.respondToOffer(_currentOffer!.id, 'accept');

      _countdownTimer?.cancel();
      _currentOffer = null;
      _currentOfferDelivery = null;
      _remainingSeconds = 0;
      _isResponding = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isResponding = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> declineOffer() async {
    if (_currentOffer == null) return false;

    _isResponding = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _offerService.respondToOffer(_currentOffer!.id, 'decline');

      _countdownTimer?.cancel();
      _currentOffer = null;
      _currentOfferDelivery = null;
      _remainingSeconds = 0;
      _isResponding = false;
      notifyListeners();

      // Refresh declined offers list
      await loadDeclinedOffers();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isResponding = false;
      notifyListeners();
      return false;
    }
  }

  /// Reclaim a previously declined delivery
  Future<bool> reclaimDelivery(String deliveryId) async {
    _isResponding = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _offerService.reclaimDelivery(deliveryId);

      // Remove from declined list
      _declinedOffers.removeWhere((d) => d.offer.deliveryId == deliveryId);

      _isResponding = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isResponding = false;
      notifyListeners();
      return false;
    }
  }

  /// Load recently declined offers with availability status
  Future<void> loadDeclinedOffers() async {
    try {
      final offers = await _offerService.getDeclinedOffers();
      final List<DeclinedOfferInfo> infos = [];

      for (final offer in offers) {
        // Check if delivery is still available
        final status = await _offerService.getDeliveryStatus(offer.deliveryId);
        final isAvailable = status == 'pending';

        // Fetch delivery details
        Delivery? delivery;
        try {
          delivery = await _deliveryService.getDelivery(offer.deliveryId);
        } catch (_) {}

        infos.add(DeclinedOfferInfo(
          offer: offer,
          delivery: delivery,
          isAvailable: isAvailable,
        ));
      }

      _declinedOffers = infos;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading declined offers: $e');
    }
  }

  /// Refresh subscription (call after login)
  void refreshSubscription() {
    _startOfferSubscription();
    _checkForActiveOffer();
    loadDeclinedOffers();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _offerSubscription?.cancel();
    super.dispose();
  }
}
