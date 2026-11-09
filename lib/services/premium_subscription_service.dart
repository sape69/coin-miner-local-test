import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Stelluriini Premium -tilausten hallinta.
///
/// Google Play hoitaa maksun ja Firebase Functions varmentaa ostot.
/// Ostoa ei kuitata valmiiksi ennen onnistunutta palvelinvarmennusta.
class PremiumSubscriptionService extends ChangeNotifier {
  PremiumSubscriptionService({
    InAppPurchase? inAppPurchase,
    FirebaseFunctions? functions,
  })  : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1');

  static const String premiumProductId =
      'stelluriini_premium_monthly';

  static const String premiumPlusProductId =
      'stelluriini_premium_plus_monthly';

  static const Set<String> productIds = {
    premiumProductId,
    premiumPlusProductId,
  };

  final InAppPurchase _inAppPurchase;
  final FirebaseFunctions _functions;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  final List<ProductDetails> _products = [];

  bool _initialized = false;
  bool _disposed = false;
  bool _storeAvailable = false;
  bool _loading = false;
  bool _purchasePending = false;
  bool _verifying = false;

  String? _error;
  String? _message;

  String _activeTier = 'free';
  DateTime? _premiumExpiresAt;

  // ------------------------------------------------------------
  // GETTERS
  // ------------------------------------------------------------

  bool get isInitialized => _initialized;

  bool get isStoreAvailable => _storeAvailable;

  bool get isLoading => _loading;

  bool get isPurchasePending => _purchasePending;

  bool get isVerifying => _verifying;

  bool get isPremium => _activeTier == 'premium' ||
      _activeTier == 'premium_plus';

  bool get isPremiumPlus => _activeTier == 'premium_plus';

  bool get isDisposed => _disposed;

  String get activeTier => _activeTier;

  String? get error => _error;

  String? get message => _message;

  DateTime? get premiumExpiresAt => _premiumExpiresAt;

  List<ProductDetails> get products =>
      List.unmodifiable(_products);

  ProductDetails? get premiumProduct {
    for (final product in _products) {
      if (product.id == premiumProductId) {
        return product;
      }
    }

    return null;
  }

  ProductDetails? get premiumPlusProduct {
    for (final product in _products) {
      if (product.id == premiumPlusProductId) {
        return product;
      }
    }

    return null;
  }

  String get premiumPrice =>
      premiumProduct?.price ?? 'Ei saatavilla';

  String get premiumPlusPrice =>
      premiumPlusProduct?.price ?? 'Ei saatavilla';

  // ------------------------------------------------------------
  // INITIALIZATION
  // ------------------------------------------------------------

  Future<void> initialize() async {
    if (_disposed || _initialized || _loading) {
      return;
    }

    _loading = true;
    _error = null;
    _message = null;
    _notify();

    try {
      _storeAvailable = await _inAppPurchase.isAvailable();

      if (_disposed) return;

      if (!_storeAvailable) {
        _error = 'Google Play -kauppa ei ole käytettävissä.';
        return;
      }

      await _purchaseSubscription?.cancel();

      if (_disposed) return;

      _purchaseSubscription =
          _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onError: (Object error) {
          if (_disposed) return;

          _error = 'Ostotapahtuman käsittely epäonnistui.';
          _purchasePending = false;
          _verifying = false;
          _notify();
        },
      );

      await loadProducts();

      if (_disposed) return;

      _initialized = true;
    } catch (e) {
      if (!_disposed) {
        _error = 'Premium-palvelun käynnistys epäonnistui.';
      }
    } finally {
      _loading = false;
      _notify();
    }
  }

  // ------------------------------------------------------------
  // LOAD PRODUCTS
  // ------------------------------------------------------------

  Future<void> loadProducts() async {
    if (_disposed) return;

    try {
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(productIds);

      if (_disposed) return;

      _products
        ..clear()
        ..addAll(response.productDetails);

      if (response.error != null) {
        _error = 'Tuotteiden lataaminen epäonnistui.';
      } else if (response.notFoundIDs.isNotEmpty) {
        _error =
            'Kaikkia Premium-tuotteita ei löytynyt Google Playsta.';
      } else {
        _error = null;
      }

      _notify();
    } catch (e) {
      if (!_disposed) {
        _error = 'Premium-tuotteiden lataaminen epäonnistui.';
        _notify();
      }
    }
  }

  // ------------------------------------------------------------
  // BUY PREMIUM
  // ------------------------------------------------------------

  Future<bool> buyPremium() async {
    return _buyProduct(premiumProductId);
  }

  Future<bool> buyPremiumPlus() async {
    return _buyProduct(premiumPlusProductId);
  }

  Future<bool> _buyProduct(String productId) async {
    if (_disposed) return false;

    if (!_storeAvailable) {
      _error = 'Google Play -kauppa ei ole käytettävissä.';
      _notify();
      return false;
    }

    if (_purchasePending || _verifying) {
      _error = 'Aiempi ostotapahtuma on vielä kesken.';
      _notify();
      return false;
    }

    ProductDetails? product;

    for (final item in _products) {
      if (item.id == productId) {
        product = item;
        break;
      }
    }

    if (product == null) {
      _error = 'Valittua Premium-tuotetta ei löytynyt.';
      _notify();
      return false;
    }

    try {
      _error = null;
      _message = null;
      _purchasePending = true;
      _notify();

      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: product);

      return await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
    } catch (e) {
      if (!_disposed) {
        _purchasePending = false;
        _error = 'Oston käynnistäminen epäonnistui.';
        _notify();
      }

      return false;
    }
  }

  // ------------------------------------------------------------
  // RESTORE PURCHASES
  // ------------------------------------------------------------

  Future<void> restorePurchases() async {
    if (_disposed) return;

    if (!_storeAvailable) {
      _error = 'Google Play -kauppa ei ole käytettävissä.';
      _notify();
      return;
    }

    try {
      _loading = true;
      _error = null;
      _message = null;
      _notify();

      await _inAppPurchase.restorePurchases();

      if (_disposed) return;

      _message = 'Ostojen palautus käynnistetty.';
    } catch (e) {
      if (!_disposed) {
        _error = 'Ostojen palauttaminen epäonnistui.';
      }
    } finally {
      _loading = false;
      _notify();
    }
  }

  // ------------------------------------------------------------
  // PURCHASE STREAM
  // ------------------------------------------------------------

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
  ) async {
    if (_disposed) return;

    for (final purchase in purchases) {
      if (_disposed) return;

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
          _verifying = false;
          _error = purchase.error?.message ??
              'Ostotapahtuma epäonnistui.';

          await _completePurchaseIfNeeded(purchase);

          _notify();
          break;

        case PurchaseStatus.canceled:
          _purchasePending = false;
          _verifying = false;
          _message = 'Osto peruutettiin.';

          await _completePurchaseIfNeeded(purchase);

          _notify();
          break;
      }
    }
  }

  // ------------------------------------------------------------
  // VERIFY PURCHASE WITH FIREBASE
  // ------------------------------------------------------------

  Future<void> _verifyPurchase(
    PurchaseDetails purchase,
  ) async {
    if (_disposed) return;

    bool verified = false;

    try {
      _verifying = true;
      _purchasePending = true;
      _error = null;
      _message = 'Varmistetaan Premium-tilausta...';
      _notify();

      final String productId = purchase.productID;

      if (!productIds.contains(productId)) {
        throw Exception('Tuntematon Premium-tuote.');
      }

      final String purchaseToken =
          purchase.verificationData.serverVerificationData;

      if (purchaseToken.trim().isEmpty) {
        throw Exception('Google Play -ostotunniste puuttuu.');
      }

      final HttpsCallable callable =
          _functions.httpsCallable('verifyPlaySubscription');

      final HttpsCallableResult<dynamic> result =
          await callable.call({
        'productId': productId,
        'purchaseToken': purchaseToken,
      });

      if (_disposed) return;

      final dynamic data = result.data;

      if (data is! Map) {
        throw Exception('Palvelimen vastaus oli virheellinen.');
      }

      final bool success = data['success'] == true;

      if (!success) {
        throw Exception(
          data['message']?.toString() ??
              'Google Play -tilausta ei voitu varmentaa.',
        );
      }

      final String tier =
          data['tier']?.toString() ?? '';

      if (tier != 'premium' && tier != 'premium_plus') {
        throw Exception('Palvelin palautti virheellisen tilaustason.');
      }

      _activeTier = tier;

      final dynamic expiryValue = data['expiresAt'];

      if (expiryValue is String) {
        _premiumExpiresAt = DateTime.tryParse(expiryValue);
      } else if (expiryValue is int) {
        _premiumExpiresAt =
            DateTime.fromMillisecondsSinceEpoch(expiryValue);
      }

      _message = tier == 'premium_plus'
          ? 'Premium Plus on aktivoitu!'
          : 'Premium on aktivoitu!';

      _error = null;

      // Ostoa voidaan kuitata vasta onnistuneen
      // palvelinvarmennuksen jälkeen.
      verified = true;
    } catch (e) {
      if (!_disposed) {
        _error = e.toString().replaceFirst('Exception: ', '');
        _message = null;
      }
    } finally {
      if (!_disposed) {
        _verifying = false;
        _purchasePending = false;

        if (verified) {
          await _completePurchaseIfNeeded(purchase);
        }

        _notify();
      }
    }
  }

  // ------------------------------------------------------------
  // COMPLETE PURCHASE
  // ------------------------------------------------------------

  Future<void> _completePurchaseIfNeeded(
    PurchaseDetails purchase,
  ) async {
    if (_disposed) return;

    if (!purchase.pendingCompletePurchase) {
      return;
    }

    try {
      await _inAppPurchase.completePurchase(purchase);
    } catch (e) {
      if (!_disposed) {
        _error =
            'Oston kuittaus epäonnistui. Voit yrittää palauttaa ostot myöhemmin.';
        _notify();
      }
    }
  }

  // ------------------------------------------------------------
  // CLEAR MESSAGE
  // ------------------------------------------------------------

  void clearMessage() {
    if (_disposed) return;

    _message = null;
    _error = null;
    _notify();
  }

  // ------------------------------------------------------------
  // NOTIFY
  // ------------------------------------------------------------

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  @override
  void dispose() {
    if (_disposed) return;

    _disposed = true;

    _purchaseSubscription?.cancel();
    _purchaseSubscription = null;

    super.dispose();
  }
}