
import 'package:firebase_analytics/firebase_analytics.dart';

/// Stelluriini Analytics Service
///
/// Ei lähetä sähköpostiosoitteita, käyttäjänimiä,
/// lompakko-osoitteita tai transaction ID -tunnisteita.
class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics _analytics =
      FirebaseAnalytics.instance;

  static Future<void> logSignUp({
    String method = 'email',
  }) async {
    await _analytics.logSignUp(
      signUpMethod: method,
    );
  }

  static Future<void> logLogin({
    String method = 'email',
  }) async {
    await _analytics.logLogin(
      loginMethod: method,
    );
  }

  static Future<void> logMiningStarted() async {
    await _analytics.logEvent(
      name: 'mining_started',
    );
  }

  static Future<void> logMiningClaimed() async {
    await _analytics.logEvent(
      name: 'mining_claimed',
    );
  }

  static Future<void> logPowerBoostUsed() async {
    await _analytics.logEvent(
      name: 'power_boost_used',
    );
  }

  static Future<void> logPremiumPurchaseStarted({
    required String productId,
  }) async {
    await _analytics.logEvent(
      name: 'premium_purchase_started',
      parameters: <String, Object>{
        'product_id': productId,
      },
    );
  }

  static Future<void> logPremiumPurchaseCompleted({
    required String productId,
    required String tier,
  }) async {
    await _analytics.logEvent(
      name: 'premium_purchase_completed',
      parameters: <String, Object>{
        'product_id': productId,
        'tier': tier,
      },
    );
  }
}
