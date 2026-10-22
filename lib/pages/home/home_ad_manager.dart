import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class HomeAdManager extends ChangeNotifier {
  // ============================================================
  // 🐱 STELLURIINI - HOME AD MANAGER
  // ============================================================
  //
  // TEST MODE
  //
  // Käytetään Googlen virallista Rewarded Test Ad Unit ID:tä
  // sekä Mining Startiin että Power Boostiin.
  //
  // Test Ad Unit:
  //
  // ca-app-pub-3940256099942544/5224354917
  //
  // ============================================================

  // ============================================================
  // REAL ADMOB IDS
  // ============================================================
  //
  // Säilytetään myöhempää käyttöönottoa varten.
  // Näitä EI käytetä testitilassa.
  //

  static const String miningRewardedAdUnitId =
      'ca-app-pub-1131012057145658/6674097787';

  static const String powerBoostRewardedAdUnitId =
      'ca-app-pub-1131012057145658/7225738491';

  // ============================================================
  // GOOGLE TEST REWARDED AD
  // ============================================================

  static const String testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // ============================================================
  // PURPOSES
  // ============================================================

  static const String miningStartPurpose = 'mining_start';

  static const String powerBoostPurpose = 'power_boost';

  // ============================================================
  // CALLBACKS
  // ============================================================

  final void Function()? onMiningStartReward;

  final void Function()? onPowerBoostReward;

  final void Function(String message)? onAdLoadError;

  final void Function(String message)? onAdShowError;

  final void Function(String purpose)? onAdDismissed;

  // Säilytetään vanha yleinen callback-yhteensopivuus.
  void Function(String purpose)? onRewarded;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  HomeAdManager({
    this.onMiningStartReward,
    this.onPowerBoostReward,
    this.onAdLoadError,
    this.onAdShowError,
    this.onAdDismissed,
  });

  // ============================================================
  // INTERNAL STATE
  // ============================================================

  RewardedAd? _rewardedAd;

  String? _loadedPurpose;

  bool _isLoading = false;

  bool _isShowing = false;

  bool _disposed = false;

  String? _lastError;

  final Set<String> _loadingPurposes = <String>{};

  final Set<String> _showingPurposes = <String>{};

  // ============================================================
  // PRIVACY / UMP STATE
  // ============================================================

  bool _privacyOptionsRequired = false;

  bool get privacyOptionsRequired => _privacyOptionsRequired;

  // ============================================================
  // MINING AD FLOW
  // ============================================================

  bool get miningAdFlowActive =>
      _isShowing &&
      _showingPurposes.contains(miningStartPurpose);

  // ============================================================
  // PUBLIC GETTERS
  // ============================================================

  bool get isLoading => _isLoading;

  bool get isShowing => _isShowing;

  bool get isReady =>
      _rewardedAd != null &&
      _loadedPurpose != null;

  String? get loadedPurpose => _loadedPurpose;

  String? get lastError => _lastError;

  // ============================================================
  // CURRENT USER
  // ============================================================

  String? get _uid {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // ============================================================
  // INITIALIZATION
  // ============================================================

  Future<void> initialize() async {
    if (_disposed) {
      return;
    }

    try {
      await MobileAds.instance.initialize();

      if (_disposed) {
        return;
      }

      await _updatePrivacyOptionsStatus();

      debugPrint(
        '🐱 AdMob initialized.',
      );

      debugPrint(
        '🐱 Test Rewarded Ads enabled.',
      );
    } catch (error) {
      debugPrint(
        '🐱 AdMob initialization error: $error',
      );
    }
  }

  // ============================================================
  // PRIVACY OPTIONS
  // ============================================================

  Future<void> _updatePrivacyOptionsStatus() async {
    if (_disposed) {
      return;
    }

    try {
      final status =
          await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus();

      if (_disposed) {
        return;
      }

      _privacyOptionsRequired =
          status == PrivacyOptionsRequirementStatus.required;

      _safeNotify();
    } catch (error) {
      debugPrint(
        '🐱 Privacy options status error: $error',
      );

      _privacyOptionsRequired = false;
    }
  }

  Future<void> showPrivacyOptionsForm() async {
    if (_disposed) {
      return;
    }

    try {
      ConsentForm.showPrivacyOptionsForm(
        (
          FormError? error,
        ) async {
          if (error != null) {
            debugPrint(
              '🐱 Privacy options error: '
              '${error.errorCode}: ${error.message}',
            );
          }

          await _updatePrivacyOptionsStatus();
        },
      );
    } catch (error) {
      debugPrint(
        '🐱 Failed to show privacy options form: $error',
      );
    }
  }

  // ============================================================
  // AD UNIT
  // ============================================================

  String _rewardedAdUnitIdForPurpose(
    String purpose,
  ) {
    // Testitilassa molemmat käyttävät samaa Googlen
    // virallista Rewarded Test Ad Unit ID:tä.
    return testRewardedAdUnitId;
  }

  // ============================================================
  // LOAD REWARDED AD
  // ============================================================

  Future<void> loadRewardedAd(
    String purpose,
  ) async {
    if (_disposed) {
      return;
    }

    final uid = _uid;

    if (uid == null || uid.isEmpty) {
      _lastError =
          'User is not authenticated.';

      _safeNotify();

      debugPrint(
        '🐱 Cannot load Rewarded Ad: user not authenticated.',
      );

      return;
    }

    if (purpose != miningStartPurpose &&
        purpose != powerBoostPurpose) {
      _lastError =
          'Invalid Rewarded Ad purpose.';

      _safeNotify();

      debugPrint(
        '🐱 Invalid Rewarded Ad purpose: $purpose',
      );

      return;
    }

    if (_rewardedAd != null &&
        _loadedPurpose == purpose) {
      debugPrint(
        '🐱 Rewarded Ad already loaded: $purpose',
      );

      return;
    }

    if (_loadingPurposes.contains(purpose)) {
      debugPrint(
        '🐱 Rewarded Ad already loading: $purpose',
      );

      return;
    }

    _loadingPurposes.add(purpose);

    _isLoading = true;

    _lastError = null;

    _safeNotify();

    final adUnitId =
        _rewardedAdUnitIdForPurpose(
      purpose,
    );

    debugPrint(
      '🐱 Loading TEST Rewarded Ad.',
    );

    debugPrint(
      '🐱 Purpose: $purpose',
    );

    debugPrint(
      '🐱 Test Ad Unit ID: $adUnitId',
    );

    try {
      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback:
            RewardedAdLoadCallback(
          onAdLoaded:
              (
                RewardedAd ad,
              ) {
            if (_disposed) {
              ad.dispose();

              _loadingPurposes.remove(
                purpose,
              );

              return;
            }

            _rewardedAd?.dispose();

            _rewardedAd = ad;

            _loadedPurpose = purpose;

            _isLoading = false;

            _loadingPurposes.remove(
              purpose,
            );

            _lastError = null;

            debugPrint(
              '🐱 Rewarded Ad loaded successfully.',
            );

            debugPrint(
              '🐱 Purpose: $purpose',
            );

            _safeNotify();
          },
          onAdFailedToLoad:
              (
                LoadAdError error,
              ) {
            _rewardedAd?.dispose();

            _rewardedAd = null;

            _loadedPurpose = null;

            _isLoading = false;

            _loadingPurposes.remove(
              purpose,
            );

            _lastError =
                error.message;

            debugPrint(
              '🐱 Rewarded Ad failed to load.',
            );

            debugPrint(
              '🐱 Purpose: $purpose',
            );

            debugPrint(
              '🐱 Error: $error',
            );

            _notifyAdLoadError(
              error.message,
            );

            _safeNotify();
          },
        ),
      );
    } catch (error) {
      _rewardedAd?.dispose();

      _rewardedAd = null;

      _loadedPurpose = null;

      _isLoading = false;

      _loadingPurposes.remove(
        purpose,
      );

      _lastError =
          error.toString();

      debugPrint(
        '🐱 Rewarded Ad load exception: $error',
      );

      _notifyAdLoadError(
        error.toString(),
      );

      _safeNotify();
    }
  }

  // ============================================================
  // SHOW REWARDED AD
  // ============================================================

  Future<bool> showRewardedAd(
    String purpose,
  ) async {
    if (_disposed) {
      return false;
    }

    final uid = _uid;

    if (uid == null || uid.isEmpty) {
      debugPrint(
        '🐱 Cannot show Rewarded Ad: user not authenticated.',
      );

      return false;
    }

    if (purpose != miningStartPurpose &&
        purpose != powerBoostPurpose) {
      debugPrint(
        '🐱 Invalid Rewarded Ad purpose: $purpose',
      );

      return false;
    }

    if (_isShowing) {
      debugPrint(
        '🐱 Rewarded Ad is already showing.',
      );

      return false;
    }

    final ad = _rewardedAd;

    if (ad == null ||
        _loadedPurpose != purpose) {
      debugPrint(
        '🐱 Rewarded Ad is not ready for purpose: $purpose',
      );

      unawaited(
        loadRewardedAd(
          purpose,
        ),
      );

      return false;
    }

    _rewardedAd = null;

    _loadedPurpose = null;

    _isShowing = true;

    _showingPurposes.add(
      purpose,
    );

    _safeNotify();

    bool rewardEarned = false;

    final completer =
        Completer<bool>();

    // ==========================================================
    // SSV
    // ==========================================================
    //
    // Tämänhetkinen google_mobile_ads-riippuvuus ei tarjoa
    // analyysin mukaan RewardedAd-oliolle suoraan
    // setServerSideVerificationOptions()-metodia.
    //
    // Siksi emme kutsu sitä tässä.
    //
    // Testimainos toimii normaalina Rewarded Ad -mainoksena.
    //
    // ==========================================================

    debugPrint(
      '🐱 Rewarded Ad purpose: $purpose',
    );

    debugPrint(
      '🐱 Rewarded Ad UID: $uid',
    );

    // ==========================================================
    // FULLSCREEN CALLBACK
    // ==========================================================

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdShowedFullScreenContent:
          (
            RewardedAd ad,
          ) {
        debugPrint(
          '🐱 Rewarded Ad shown.',
        );

        debugPrint(
          '🐱 Purpose: $purpose',
        );
      },
      onAdDismissedFullScreenContent:
          (
            RewardedAd ad,
          ) {
        debugPrint(
          '🐱 Rewarded Ad dismissed.',
        );

        ad.dispose();

        _finishShowing(
          purpose,
          rewardEarned,
          completer,
        );

        _notifyAdDismissed(
          purpose,
        );
      },
      onAdFailedToShowFullScreenContent:
          (
            RewardedAd ad,
            AdError error,
          ) {
        debugPrint(
          '🐱 Rewarded Ad failed to show.',
        );

        debugPrint(
          '🐱 Error: $error',
        );

        ad.dispose();

        _notifyAdShowError(
          error.message,
        );

        _finishShowing(
          purpose,
          false,
          completer,
        );
      },
      onAdImpression:
          (
            RewardedAd ad,
          ) {
        debugPrint(
          '🐱 Rewarded Ad impression.',
        );
      },
      onAdClicked:
          (
            RewardedAd ad,
          ) {
        debugPrint(
          '🐱 Rewarded Ad clicked.',
        );
      },
      onAdWillDismissFullScreenContent:
          (
            RewardedAd ad,
          ) {
        debugPrint(
          '🐱 Rewarded Ad will dismiss.',
        );
      },
    );

    // ==========================================================
    // SHOW
    // ==========================================================

    try {
      ad.show(
        onUserEarnedReward:
            (
              AdWithoutView ad,
              RewardItem reward,
            ) {
          rewardEarned = true;

          debugPrint(
            '🐱 Reward earned.',
          );

          debugPrint(
            '🐱 Purpose: $purpose',
          );

          debugPrint(
            '🐱 Reward amount: ${reward.amount}',
          );

          debugPrint(
            '🐱 Reward type: ${reward.type}',
          );

          _notifyReward(
            purpose,
          );
        },
      );
    } catch (error) {
      debugPrint(
        '🐱 Rewarded Ad show exception: $error',
      );

      _notifyAdShowError(
        error.toString(),
      );

      try {
        ad.dispose();
      } catch (_) {}

      _finishShowing(
        purpose,
        false,
        completer,
      );
    }

    return completer.future;
  }

  // ============================================================
  // REWARD CALLBACK
  // ============================================================

  void _notifyReward(
    String purpose,
  ) {
    try {
      if (purpose == miningStartPurpose) {
        onMiningStartReward?.call();
      } else if (purpose == powerBoostPurpose) {
        onPowerBoostReward?.call();
      }

      onRewarded?.call(
        purpose,
      );
    } catch (error) {
      debugPrint(
        '🐱 Reward callback error: $error',
      );
    }
  }

  // ============================================================
  // ERROR CALLBACKS
  // ============================================================

  void _notifyAdLoadError(
    String message,
  ) {
    try {
      onAdLoadError?.call(
        message,
      );
    } catch (error) {
      debugPrint(
        '🐱 onAdLoadError callback error: $error',
      );
    }
  }

  void _notifyAdShowError(
    String message,
  ) {
    try {
      onAdShowError?.call(
        message,
      );
    } catch (error) {
      debugPrint(
        '🐱 onAdShowError callback error: $error',
      );
    }
  }

  void _notifyAdDismissed(
    String purpose,
  ) {
    try {
      onAdDismissed?.call(
        purpose,
      );
    } catch (error) {
      debugPrint(
        '🐱 onAdDismissed callback error: $error',
      );
    }
  }

  // ============================================================
  // FINISH SHOWING
  // ============================================================

  void _finishShowing(
    String purpose,
    bool rewardEarned,
    Completer<bool> completer,
  ) {
    if (completer.isCompleted) {
      return;
    }

    _isShowing = false;

    _showingPurposes.remove(
      purpose,
    );

    _safeNotify();

    // Ladataan seuraava testimainos.
    unawaited(
      loadRewardedAd(
        purpose,
      ),
    );

    completer.complete(
      rewardEarned,
    );
  }

  // ============================================================
  // PRELOAD
  // ============================================================

  Future<void> preload(
    String purpose,
  ) async {
    if (_disposed) {
      return;
    }

    if (_rewardedAd != null &&
        _loadedPurpose == purpose) {
      return;
    }

    await loadRewardedAd(
      purpose,
    );
  }

  // ============================================================
  // PRELOAD BOTH
  // ============================================================

  Future<void> preloadBoth() async {
    if (_disposed) {
      return;
    }

    await Future.wait(
      <Future<void>>[
        preload(
          miningStartPurpose,
        ),
        preload(
          powerBoostPurpose,
        ),
      ],
    );
  }

  // ============================================================
  // CONVENIENCE METHODS
  // ============================================================

  Future<bool> showMiningStartAd() {
    return showRewardedAd(
      miningStartPurpose,
    );
  }

  Future<bool> showPowerBoostAd() {
    return showRewardedAd(
      powerBoostPurpose,
    );
  }

  // ============================================================
  // DISPOSE CURRENT AD
  // ============================================================

  void disposeRewardedAd() {
    try {
      _rewardedAd?.dispose();
    } catch (_) {}

    _rewardedAd = null;

    _loadedPurpose = null;

    _isLoading = false;

    _safeNotify();
  }

  // ============================================================
  // SAFE NOTIFY
  // ============================================================

  void _safeNotify() {
    if (_disposed) {
      return;
    }

    try {
      notifyListeners();
    } catch (error) {
      debugPrint(
        '🐱 notifyListeners error: $error',
      );
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _disposed = true;

    _loadingPurposes.clear();

    _showingPurposes.clear();

    try {
      _rewardedAd?.dispose();
    } catch (_) {}

    _rewardedAd = null;

    _loadedPurpose = null;

    _isLoading = false;

    _isShowing = false;

    super.dispose();
  }
}