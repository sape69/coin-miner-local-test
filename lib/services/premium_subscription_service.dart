
import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

// ============================================================
// 🐱 STELLURIINI - PREMIUM SUBSCRIPTION SERVICE
// ============================================================
//
// Google Play Billing + Firebase server-side verification.
//
// Products:
// - stelluriini_premium_monthly      €1.99 / month
// - stelluriini_premium_plus_monthly €4.99 / month
//
// ============================================================

class PremiumSubscriptionService extends ChangeNotifier {
  PremiumSubscriptionService({
    InAppPurchase? inAppPurchase,
    FirebaseFunctions? functions,
  })  : _inAppPurchase =
            inAppPurchase ?? InAppPurchase.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(
              region: 'us-central1',
            );

  // ==========================================================
  // CONFIGURATION
  // ==========================================================

  static const String premiumProductId =
      'stelluriini_premium_monthly';

  static const String premiumPlusProductId =
      'stelluriini_premium_plus_monthly';

  static const Set<String> productIds = {
    premiumProductId,
    premiumPlusProductId,
  };

  // ==========================================================
  // SERVICES
  // ==========================================================

  final InAppPurchase _inAppPurchase;

  final FirebaseFunctions _functions;

  StreamSubscription<List<PurchaseDetails>>?
      _purchaseSubscription;

  // ==========================================================
  // STATE
  // ==========================================================

  final List<ProductDetails> _products = [];

  List<ProductDetails> get products =>
      List.unmodifiable(_products);

  bool _storeAvailable = false;

  bool get storeAvailable => _storeAvailable;

  bool _loading = false;

  bool get loading => _loading;

  bool _purchasePending = false;

  bool get purchasePending => _purchasePending;

  bool _verifying = false;

  bool get verifying => _verifying;

  bool _initialized = false;

  bool get initialized => _initialized;

  String? _error;

  String? get error => _error;

  String? _message;

  String? get message => _message;

  String? _activeTier;

  String? get activeTier => _activeTier;

  DateTime? _expiryTime;

  DateTime? get expiryTime => _expiryTime;

  bool get isPremium =>
      _activeTier == 'premium' ||
      _activeTier == 'premium_plus';

  bool get isPremiumPlus =>
      _activeTier == 'premium_plus';

  // ==========================================================
  // INITIALIZE
  // ==========================================================

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _setLoading(true);
    _error = null;
    _message = null;

    try {
      _storeAvailable =
          await _inAppPurchase.isAvailable();

      if (!_storeAvailable) {
        _error =
            'Google Play -kauppa ei ole tällä hetkellä käytettävissä.';
        return;
      }

      _purchaseSubscription ??=
          _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onError: (Object error) {
          _setError(
            'Ostotapahtuman käsittely epäonnistui: $error',
          );
        },
      );

      await loadProducts();

      _initialized = true;
    } catch (error) {
      _error =
          'Premium-palvelun käynnistäminen epäonnistui: $error';
    } finally {
      _setLoading(false);
    }
  }

  // ==========================================================
  // LOAD GOOGLE PLAY PRODUCTS
  // ==========================================================

  Future<void> loadProducts() async {
    _error = null;

    try {
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(
        productIds,
      );

      if (response.error != null) {
        _error =
            'Premium-tuotteiden hakeminen epäonnistui: '
            '${response.error!.message}';
      }

      _products
        ..clear()
        ..addAll(response.productDetails);

      if (response.notFoundIDs.isNotEmpty) {
        _error ??=
            'Google Playsta puuttuvat tuotteet: '
            '${response.notFoundIDs.join(', ')}';
      }

      _notify();
    } catch (error) {
      _setError(
        'Tuotteiden hakeminen epäonnistui: $error',
      );
    }
  }

  // ==========================================================
  // GET PRODUCT
  // ==========================================================

  ProductDetails? getProduct(String productId) {
    for (final ProductDetails product in _products) {
      if (product.id == productId) {
        return product;
      }
    }

    return null;
  }

  // ==========================================================
  // BUY PREMIUM
  // ==========================================================

  Future<bool> buyPremium() {
    return _buyProduct(premiumProductId);
  }

  // ==========================================================
  // BUY PREMIUM PLUS
  // ==========================================================

  Future<bool> buyPremiumPlus() {
    return _buyProduct(premiumPlusProductId);
  }

  // ==========================================================
  // BUY PRODUCT
  // ==========================================================

  Future<bool> _buyProduct(String productId) async {
    if (!_storeAvailable) {
      _setError(
        'Google Play -kauppa ei ole käytettävissä.',
      );
      return false;
    }

    if (_purchasePending || _verifying) {
      _setError(
        'Ostoa käsitellään jo. Odota hetki.',
      );
      return false;
    }

    final ProductDetails? product =
        getProduct(productId);

    if (product == null) {
      _setError(
        'Tuotetta ei löytynyt Google Playsta. '
        'Päivitä tuoteluettelo ja yritä uudelleen.',
      );
      return false;
    }

    _error = null;
    _message = null;

    try {
      final PurchaseParam purchaseParam =
          PurchaseParam(
        productDetails: product,
      );

      _purchasePending = true;
      _notify();

      final bool started =
          await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!started) {
        _purchasePending = false;
        _setError(
          'Google Play ei käynnistänyt ostotapahtumaa.',
        );
        return false;
      }

      return true;
    } catch (error) {
      _purchasePending = false;

      _setError(
        'Premium-oston käynnistäminen epäonnistui: $error',
      );

      return false;
    }
  }

  // ==========================================================
  // RESTORE PURCHASES
  // ==========================================================

  Future<void> restorePurchases() async {
    if (!_storeAvailable) {
      _setError(
        'Google Play -kauppa ei ole käytettävissä.',
      );
      return;
    }

    if (_purchasePending || _verifying) {
      _setError(
        'Ostotapahtumaa käsitellään jo.',
      );
      return;
    }

    _error = null;
    _message = null;
    _setLoading(true);

    try {
      await _inAppPurchase.restorePurchases();

      _message =
          'Ostojen palautuspyyntö lähetettiin Google Playhin.';
    } catch (error) {
      _error =
          'Ostojen palauttaminen epäonnistui: $error';
    } finally {
      _setLoading(false);
    }
  }

  // ==========================================================
  // PURCHASE STREAM
  // ==========================================================

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
  ) async {
    for (final PurchaseDetails purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _purchasePending = true;
          _message = 'Ostoa käsitellään Google Playssa.';
          _notify();
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyPurchase(purchase);
          break;

        case PurchaseStatus.error:
          _purchasePending = false;

          _setError(
            purchase.error?.message ??
                'Google Play -osto epäonnistui.',
          );

          await _completePurchaseIfNeeded(purchase);
          break;

        case PurchaseStatus.canceled:
          _purchasePending = false;
          _message = 'Osto peruutettiin.';
          _notify();

          await _completePurchaseIfNeeded(purchase);
          break;
      }
    }
  }

  // ==========================================================
  // VERIFY PURCHASE WITH FIREBASE
  // ==========================================================

  Future<void> _verifyPurchase(
    PurchaseDetails purchase,
  ) async {
    if (!productIds.contains(purchase.productID)) {
      _purchasePending = false;

      _setError(
        'Tuntematon Premium-tuote: ${purchase.productID}',
      );

      await _completePurchaseIfNeeded(purchase);
      return;
    }

    final String purchaseToken =
        purchase.verificationData.serverVerificationData
            .trim();

    if (purchaseToken.isEmpty) {
      _purchasePending = false;

      _setError(
        'Google Play -ostotunniste puuttuu.',
      );

      await _completePurchaseIfNeeded(purchase);
      return;
    }

    _verifying = true;
    _purchasePending = true;
    _error = null;
    _message =
        'Varmennetaan Premium-tilausta...';

    _notify();

    try {
      final HttpsCallable callable =
          _functions.httpsCallable(
        'verifyPlaySubscription',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 30),
        ),
      );

      final HttpsCallableResult<dynamic> result =
          await callable.call({
        'productId': purchase.productID,
        'purchaseToken': purchaseToken,
      });

      final dynamic raw = result.data;

      if (raw is! Map) {
        throw Exception(
          'Palvelin palautti virheellisen vastauksen.',
        );
      }

      final Map<String, dynamic> data =
          Map<String, dynamic>.from(raw);

      if (data['success'] != true ||
          data['verified'] != true) {
        throw Exception(
          'Google Play -tilauksen varmennus epäonnistui.',
        );
      }

      final String tier =
          data['tier']?.toString() ?? '';

      if (tier != 'premium' &&
          tier != 'premium_plus') {
        throw Exception(
          'Palvelin palautti tuntemattoman tilaustason.',
        );
      }

      _activeTier = tier;

      final String? expiry =
          data['expiryTime']?.toString();

      _expiryTime = expiry == null
          ? null
          : DateTime.tryParse(expiry);

      _message = tier == 'premium_plus'
          ? 'Premium Plus on aktivoitu!'
          : 'Premium on aktivoitu!';

      _error = null;
    } catch (error) {
      _error =
          'Premium-tilauksen varmennus epäonnistui: $error';

      _message = null;
    } finally {
      _verifying = false;
      _purchasePending = false;

      await _completePurchaseIfNeeded(purchase);

      _notify();
    }
  }

  // ==========================================================
  // COMPLETE PURCHASE
  // ==========================================================

  Future<void> _completePurchaseIfNeeded(
    PurchaseDetails purchase,
  ) async {
    if (!purchase.pendingCompletePurchase) {
      return;
    }

    try {
      await _inAppPurchase.completePurchase(purchase);
    } catch (error) {
      _setError(
        'Oston viimeistely epäonnistui: $error',
      );
    }
  }

  // ==========================================================
  // CLEAR MESSAGES
  // ==========================================================

  void clearMessages() {
    _error = null;
    _message = null;
    _notify();
  }

  // ==========================================================
  // INTERNAL STATE HELPERS
  // ==========================================================

  void _setLoading(bool value) {
    _loading = value;
    _notify();
  }

  void _setError(String value) {
    _error = value;
    _message = null;
    _notify();
  }

  void _notify() {
    if (!isDisposed) {
      notifyListeners();
    }
  }

  bool get isDisposed => !_initialized && false;

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    _purchaseSubscription = null;

    super.dispose();
  }
}
