import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class HomeAdManager extends ChangeNotifier {
  // ============================================================
  // 🐱 STELLURIINI - ADMOB MANAGER
  // ============================================================
  //
  // AdMob Rewarded Ad ei anna STL-tokenia.
  //
  // AdMob toimii vain hyväksyntänä:
  //
  // 1. Mining Start
  // 2. Power Boost
  //
  // Lopullinen oikeutus tarkistetaan Firebase Functionsissa
  // AdMob Server-Side Verificationin kautta.
  //
  // ============================================================

  // ============================================================
  // 📺 ADMOB AD UNITS
  // ============================================================

  static const String miningRewardedAdUnitId =
      'ca-app-pub-1131012057145658/6674097787';

  static const String powerBoostRewardedAdUnitId =
      'ca-app-pub-1131012057145658/7225738491';

  static const String miningStartPurpose =
      'mining_start';

  static const String powerBoostPurpose =
      'power_boost';

  // ============================================================
  // ⏱️ TIMING
  // ============================================================

  static const Duration adLoadTimeout =
      Duration(seconds: 20);

  static const Duration adReadyTimeout =
      Duration(seconds: 20);

  static const Duration adCheckInterval =
      Duration(milliseconds: 200);

  static const Duration reloadDelay =
      Duration(seconds: 3);

  // ============================================================
  // 🔁 AUTOMATIC RETRY
  // ============================================================

  static const int maxAdLoadAttempts = 3;

  static const Duration adRetryDelay =
      Duration(milliseconds: 700);

  // ============================================================
  // 🔥 FIREBASE AUTH
  // ============================================================

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // 🔔 CALLBACKS
  // ============================================================

  final Future<void> Function()?
      onMiningStartReward;

  final Future<void> Function()?
      onPowerBoostReward;

  final void Function(
    String purpose,
    LoadAdError error,
  )? onAdLoadError;

  final void Function(
    String purpose,
    AdError error,
  )? onAdShowError;

  final void Function(
    String purpose,
  )? onAdDismissed;

  // ============================================================
  // 📺 AD STATE
  // ============================================================

  RewardedAd? _rewardedAd;

  bool _adReady = false;

  bool _adLoading = false;

  String _rewardedAdPurpose = '';

  String _loadingPurpose = '';

  String _adLoadError = '';

  String _rewardedAdUserUid = '';

  // ============================================================
  // 🔐 UMP CONSENT
  // ============================================================

  bool _canRequestAds = false;

  bool _consentCheckCompleted = false;

  Future<bool>? _consentCheckFuture;

  // ============================================================
  // 🔒 UMP PRIVACY OPTIONS
  // ============================================================

  bool _privacyOptionsRequired = false;

  // ============================================================
  // 🔒 FLOW PROTECTION
  // ============================================================

  bool _miningAdFlowActive = false;

  bool _powerBoostAdFlowActive = false;

  bool _miningRewardCallbackStarted = false;

  bool _powerBoostRewardCallbackStarted = false;

  bool _disposed = false;

  int _loadRequestId = 0;

  // ============================================================
  // 📺 ADMOB INITIALIZATION
  // ============================================================

  static Future<InitializationStatus>?
      _mobileAdsInitialization;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  HomeAdManager({
    this.onMiningStartReward,
    this.onPowerBoostReward,
    this.onAdLoadError,
    this.onAdShowError,
    this.onAdDismissed,
  }) {
    debugPrint(
      '🐱 [ADMOB] HomeAdManager created.',
    );

    unawaited(
      _initializeAndPreload(),
    );
  }

  // ============================================================
  // GETTERS
  // ============================================================

  RewardedAd? get rewardedAd =>
      _rewardedAd;

  bool get adReady =>
      _adReady;

  bool get adLoading =>
      _adLoading;

  String get rewardedAdPurpose =>
      _rewardedAdPurpose;

  String get adLoadError =>
      _adLoadError;

  bool get miningAdFlowActive =>
      _miningAdFlowActive;

  bool get powerBoostAdFlowActive =>
      _powerBoostAdFlowActive;

  bool get canRequestAds =>
      _canRequestAds;

  bool get consentCheckCompleted =>
      _consentCheckCompleted;

  bool get privacyOptionsRequired =>
      _privacyOptionsRequired;

  // ============================================================
  // 🔔 NOTIFY
  // ============================================================

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  // ============================================================
  // 🔐 UMP CONSENT
  // ============================================================

  Future<bool> _checkAdConsent() async {
    if (_disposed) {
      return false;
    }

    final Future<bool>? existing =
        _consentCheckFuture;

    if (existing != null) {
      return existing;
    }

    final Future<bool> future =
        _performConsentCheck();

    _consentCheckFuture =
        future;

    try {
      return await future;
    } finally {
      if (identical(
        _consentCheckFuture,
        future,
      )) {
        _consentCheckFuture = null;
      }
    }
  }

  Future<bool> _performConsentCheck() async {
    if (_disposed) {
      return false;
    }

    try {
      debugPrint(
        '🐱 [ADMOB] UMP consent check started.',
      );

      final ConsentRequestParameters params =
          ConsentRequestParameters();

      final Completer<void> updateCompleter =
          Completer<void>();

      ConsentInformation.instance
          .requestConsentInfoUpdate(
        params,
        () {
          if (!updateCompleter.isCompleted) {
            updateCompleter.complete();
          }
        },
        (FormError error) {
          if (!updateCompleter.isCompleted) {
            updateCompleter.completeError(
              error,
            );
          }
        },
      );

      await updateCompleter.future;

      if (_disposed) {
        return false;
      }

      // ========================================================
      // 🔒 PRIVACY OPTIONS REQUIREMENT
      // ========================================================

      final PrivacyOptionsRequirementStatus
          privacyOptionsStatus =
          await ConsentInformation
              .instance
              .getPrivacyOptionsRequirementStatus();

      _privacyOptionsRequired =
          privacyOptionsStatus ==
              PrivacyOptionsRequirementStatus.required;

      debugPrint(
        '🐱 [ADMOB] Privacy options required: '
        '$_privacyOptionsRequired',
      );

      // ========================================================
      // 📋 SHOW REQUIRED CONSENT FORM
      // ========================================================

      final Completer<FormError?>
          formCompleter =
          Completer<FormError?>();

      ConsentForm
          .loadAndShowConsentFormIfRequired(
        (
          FormError? error,
        ) {
          if (!formCompleter.isCompleted) {
            formCompleter.complete(error);
          }
        },
      );

      final FormError? formError =
          await formCompleter.future;

      if (formError != null) {
        debugPrint(
          '⚠️ [ADMOB] UMP form error: '
          '${formError.errorCode} '
          '${formError.message}',
        );
      }

      if (_disposed) {
        return false;
      }

      final bool canRequest =
          await ConsentInformation
              .instance
              .canRequestAds();

      if (_disposed) {
        return false;
      }

      _canRequestAds =
          canRequest;

      _consentCheckCompleted =
          true;

      debugPrint(
        canRequest
            ? '✅ [ADMOB] Ad requests allowed.'
            : '⚠️ [ADMOB] Ad requests not allowed.',
      );

      _notify();

      return canRequest;
    } catch (error) {
      debugPrint(
        '❌ [ADMOB] Consent check failed: '
        '$error',
      );

      if (_disposed) {
        return false;
      }

      _privacyOptionsRequired =
          false;

      try {
        final bool canRequest =
            await ConsentInformation
                .instance
                .canRequestAds();

        _canRequestAds =
            canRequest;

        _consentCheckCompleted =
            true;

        if (canRequest) {
          _notify();

          return true;
        }
      } catch (fallbackError) {
        debugPrint(
          '❌ [ADMOB] Consent fallback failed: '
          '$fallbackError',
        );
      }

      _canRequestAds = false;

      _consentCheckCompleted = true;

      _adLoadError =
          'CONSENT_CHECK_FAILED | $error';

      _notify();

      return false;
    }
  }

  // ============================================================
  // 🔒 SHOW PRIVACY OPTIONS
  // ============================================================

  void showPrivacyOptionsForm() {
    if (_disposed) {
      return;
    }

    if (!_privacyOptionsRequired) {
      debugPrint(
        '🐱 [ADMOB] Privacy options form is not required.',
      );

      return;
    }

    debugPrint(
      '🐱 [ADMOB] Opening privacy options form.',
    );

    unawaited(
      ConsentForm.showPrivacyOptionsForm(
        (
          FormError? formError,
        ) {
          if (formError != null) {
            debugPrint(
              '❌ [ADMOB] Privacy options form error: '
              '${formError.errorCode} '
              '${formError.message}',
            );
          } else {
            debugPrint(
              '✅ [ADMOB] Privacy options form dismissed.',
            );
          }

          if (!_disposed) {
            unawaited(
              _refreshConsentAfterPrivacyOptions(),
            );
          }
        },
      ),
    );
  }

  // ============================================================
  // 🔄 REFRESH CONSENT AFTER PRIVACY OPTIONS
  // ============================================================

  Future<void> _refreshConsentAfterPrivacyOptions() async {
    if (_disposed) {
      return;
    }

    try {
      final bool canRequest =
          await ConsentInformation
              .instance
              .canRequestAds();

      if (_disposed) {
        return;
      }

      final PrivacyOptionsRequirementStatus
          privacyOptionsStatus =
          await ConsentInformation
              .instance
              .getPrivacyOptionsRequirementStatus();

      _canRequestAds =
          canRequest;

      _privacyOptionsRequired =
          privacyOptionsStatus ==
              PrivacyOptionsRequirementStatus.required;

      _consentCheckCompleted =
          true;

      // Vanha mainos ei saa jäädä käyttöön,
      // jos käyttäjän consent-asetus muuttui.
      _disposeCurrentAd();

      _notify();

      if (canRequest) {
        final User? user =
            _auth.currentUser;

        if (user != null &&
            !_disposed) {
          await loadRewardedAd(
            purpose:
                miningStartPurpose,
            notifyOnLoadError: false,
          );
        }
      }
    } catch (error) {
      debugPrint(
        '❌ [ADMOB] Consent refresh after privacy options failed: '
        '$error',
      );
    }
  }

  // ============================================================
  // 📺 INITIALIZE ADMOB
  // ============================================================

  Future<void> _initializeAdMob() async {
    if (_mobileAdsInitialization != null) {
      await _mobileAdsInitialization;

      return;
    }

    debugPrint(
      '🐱 [ADMOB] Initializing Mobile Ads...',
    );

    _mobileAdsInitialization =
        MobileAds.instance.initialize();

    try {
      final InitializationStatus status =
          await _mobileAdsInitialization!;

      debugPrint(
        '✅ [ADMOB] Mobile Ads initialized.',
      );

      debugPrint(
        '🐱 [ADMOB] Adapter statuses: '
        '${status.adapterStatuses}',
      );
    } catch (error) {
      _mobileAdsInitialization = null;

      debugPrint(
        '❌ [ADMOB] Mobile Ads initialization failed: '
        '$error',
      );

      rethrow;
    }
  }  // ============================================================
  // 🚀 INITIALIZE + PRELOAD
  // ============================================================

  Future<void> _initializeAndPreload() async {
    if (_disposed) {
      return;
    }

    try {
      final bool allowed =
          await _checkAdConsent();

      if (!allowed) {
        debugPrint(
          '⚠️ [ADMOB] Preload skipped: consent not available.',
        );

        return;
      }

      await _initializeAdMob();

      if (_disposed) {
        return;
      }

      await _preloadMiningAd();
    } catch (error) {
      debugPrint(
        '❌ [ADMOB] Initialization failed: '
        '$error',
      );

      if (!_disposed) {
        _adLoadError =
            'ADMOB_INITIALIZATION_FAILED | $error';

        _notify();
      }
    }
  }

  // ============================================================
  // 📺 GET AD UNIT
  // ============================================================

  String _getAdUnitId(
    String purpose,
  ) {
    if (purpose ==
        powerBoostPurpose) {
      return powerBoostRewardedAdUnitId;
    }

    return miningRewardedAdUnitId;
  }

  // ============================================================
  // 🧹 CLEAR AD STATE
  // ============================================================

  void _clearAdState() {
    _rewardedAd = null;

    _adReady = false;

    _rewardedAdPurpose = '';

    _rewardedAdUserUid = '';
  }

  // ============================================================
  // 🗑️ DISPOSE CURRENT AD
  // ============================================================

  void _disposeCurrentAd() {
    final RewardedAd? ad =
        _rewardedAd;

    _clearAdState();

    try {
      ad?.dispose();
    } catch (error) {
      debugPrint(
        '⚠️ [ADMOB] Dispose failed: '
        '$error',
      );
    }
  }

  // ============================================================
  // 🔎 CHECK READY
  // ============================================================

  bool _isReadyFor(
    String purpose,
    String uid,
  ) {
    return _rewardedAd != null &&
        _adReady &&
        _rewardedAdPurpose ==
            purpose &&
        _rewardedAdUserUid == uid;
  }

  // ============================================================
  // 🚀 PRELOAD MINING AD
  // ============================================================

  Future<void> _preloadMiningAd() async {
    if (_disposed) {
      return;
    }

    final User? user =
        _auth.currentUser;

    if (user == null) {
      debugPrint(
        '⚠️ [ADMOB] Mining preload skipped: '
        'no authenticated user.',
      );

      return;
    }

    await loadRewardedAd(
      purpose:
          miningStartPurpose,
      notifyOnLoadError: false,
    );
  }

  // ============================================================
  // ⏳ WAIT FOR AD
  // ============================================================

  Future<bool> waitForRewardedAd({
    required String purpose,
  }) async {
    if (_disposed) {
      return false;
    }

    final User? user =
        _auth.currentUser;

    if (user == null) {
      return false;
    }

    if (!_consentCheckCompleted) {
      final bool allowed =
          await _checkAdConsent();

      if (!allowed) {
        return false;
      }
    }

    if (!_canRequestAds) {
      return false;
    }

    if (_isReadyFor(
      purpose,
      user.uid,
    )) {
      debugPrint(
        '✅ [ADMOB] Ad already ready: '
        '$purpose',
      );

      return true;
    }

    for (
      int attempt = 1;
      attempt <= maxAdLoadAttempts;
      attempt++
    ) {
      if (_disposed) {
        return false;
      }

      final User? activeUser =
          _auth.currentUser;

      if (activeUser == null) {
        return false;
      }

      if (_isReadyFor(
        purpose,
        activeUser.uid,
      )) {
        debugPrint(
          '✅ [ADMOB] Ad became ready: '
          '$purpose',
        );

        return true;
      }

      debugPrint(
        '🐱 [ADMOB] Ad load attempt '
        '$attempt/$maxAdLoadAttempts: '
        '$purpose',
      );

      if (_adLoading &&
          _loadingPurpose !=
              purpose) {
        _loadRequestId++;

        _adLoading = false;

        _loadingPurpose = '';
      }

      if (_rewardedAd != null &&
          !_isReadyFor(
            purpose,
            activeUser.uid,
          )) {
        _disposeCurrentAd();
      }

      if (!_adLoading) {
        await loadRewardedAd(
          purpose: purpose,
          notifyOnLoadError: true,
        );
      }

      final Stopwatch stopwatch =
          Stopwatch()..start();

      while (
          stopwatch.elapsed <
              adReadyTimeout) {
        if (_disposed) {
          return false;
        }

        final User? currentUser =
            _auth.currentUser;

        if (currentUser == null) {
          return false;
        }

        if (_isReadyFor(
          purpose,
          currentUser.uid,
        )) {
          debugPrint(
            '✅ [ADMOB] Ad ready after '
            'attempt $attempt: '
            '$purpose',
          );

          return true;
        }

        if (!_adLoading ||
            _loadingPurpose !=
                purpose) {
          break;
        }

        await Future<void>.delayed(
          adCheckInterval,
        );
      }

      final User? retryUser =
          _auth.currentUser;

      if (retryUser != null &&
          _isReadyFor(
            purpose,
            retryUser.uid,
          )) {
        return true;
      }

      if (_disposed) {
        return false;
      }

      if (attempt <
          maxAdLoadAttempts) {
        debugPrint(
          '⚠️ [ADMOB] Ad not ready. '
          'Retrying in '
          '${adRetryDelay.inMilliseconds} ms...',
        );

        await Future<void>.delayed(
          adRetryDelay,
        );
      }
    }

    debugPrint(
      '❌ [ADMOB] All ad load attempts failed: '
      '$purpose',
    );

    return false;
  }  // ============================================================
  // 📥 LOAD REWARDED AD
  // ============================================================

  Future<void> loadRewardedAd({
    required String purpose,
    bool notifyOnLoadError = true,
  }) async {
    if (_disposed) {
      return;
    }

    final User? user =
        _auth.currentUser;

    if (user == null) {
      debugPrint(
        '⚠️ [ADMOB] Load skipped: '
        'no authenticated user.',
      );

      return;
    }

    if (!_consentCheckCompleted) {
      final bool allowed =
          await _checkAdConsent();

      if (!allowed) {
        debugPrint(
          '⚠️ [ADMOB] Load skipped: '
          'consent not available.',
        );

        return;
      }
    }

    if (!_canRequestAds) {
      debugPrint(
        '⚠️ [ADMOB] Load skipped: '
        'ad requests are not allowed.',
      );

      return;
    }

    if (_adLoading &&
        _loadingPurpose ==
            purpose) {
      debugPrint(
        'ℹ️ [ADMOB] Load already in progress: '
        '$purpose',
      );

      return;
    }

    if (_isReadyFor(
      purpose,
      user.uid,
    )) {
      debugPrint(
        '✅ [ADMOB] Existing ad is ready: '
        '$purpose',
      );

      return;
    }

    if (_rewardedAd != null) {
      _disposeCurrentAd();
    }

    final String adUnitId =
        _getAdUnitId(purpose);

    final int requestId =
        ++_loadRequestId;

    _adLoading = true;
    _loadingPurpose = purpose;
    _adLoadError = null;

    _notify();

    debugPrint(
      '📺 [ADMOB] Loading rewarded ad: '
      'purpose=$purpose, '
      'unit=$adUnitId, '
      'request=$requestId',
    );

    try {
      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback:
            RewardedAdLoadCallback(
          onAdLoaded:
              (RewardedAd ad) {
            _finishAdLoad(
              requestId: requestId,
              purpose: purpose,
              uid: user.uid,
              ad: ad,
            );
          },
          onAdFailedToLoad:
              (LoadAdError error) {
            debugPrint(
              '❌ [ADMOB] Rewarded ad failed '
              'to load: '
              '$error',
            );

            if (_disposed ||
                requestId !=
                    _loadRequestId) {
              try {
                // No state belongs to this
                // obsolete request anymore.
                //
                // The ad object is not available
                // in onAdFailedToLoad.
              } catch (_) {}
              return;
            }

            _adLoading = false;
            _loadingPurpose = '';

            _adLoadError =
                'REWARDED_AD_LOAD_FAILED | '
                '${error.code} | '
                '${error.message}';

            if (notifyOnLoadError) {
              _notify();
            }
          },
        ),
      );
    } catch (error) {
      debugPrint(
        '❌ [ADMOB] RewardedAd.load exception: '
        '$error',
      );

      if (_disposed ||
          requestId !=
              _loadRequestId) {
        return;
      }

      _adLoading = false;
      _loadingPurpose = '';

      _adLoadError =
          'REWARDED_AD_LOAD_EXCEPTION | '
          '$error';

      if (notifyOnLoadError) {
        _notify();
      }
    }
  }

  // ============================================================
  // ✅ FINISH AD LOAD
  // ============================================================

  void _finishAdLoad({
    required int requestId,
    required String purpose,
    required String uid,
    required RewardedAd ad,
  }) {
    if (_disposed ||
        requestId !=
            _loadRequestId) {
      debugPrint(
        '⚠️ [ADMOB] Ignoring obsolete '
        'rewarded ad load.',
      );

      try {
        ad.dispose();
      } catch (_) {}

      return;
    }

    final User? currentUser =
        _auth.currentUser;

    if (currentUser == null ||
        currentUser.uid != uid) {
      debugPrint(
        '⚠️ [ADMOB] Ignoring rewarded ad '
        'for inactive user.',
      );

      try {
        ad.dispose();
      } catch (_) {}

      _adLoading = false;
      _loadingPurpose = '';

      return;
    }

    _rewardedAd = ad;

    _adReady = true;

    _rewardedAdPurpose =
        purpose;

    _rewardedAdUserUid =
        uid;

    _adLoading = false;

    _loadingPurpose = '';

    _adLoadError = null;

    debugPrint(
      '✅ [ADMOB] Rewarded ad loaded: '
      '$purpose',
    );

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdShowedFullScreenContent:
          (RewardedAd ad) {
        debugPrint(
          '📺 [ADMOB] Rewarded ad '
          'shown: $purpose',
        );
      },

      onAdImpression:
          (RewardedAd ad) {
        debugPrint(
          '👀 [ADMOB] Rewarded ad '
          'impression: $purpose',
        );
      },

      onAdClicked:
          (RewardedAd ad) {
        debugPrint(
          '👆 [ADMOB] Rewarded ad '
          'clicked: $purpose',
        );
      },

      onAdDismissedFullScreenContent:
          (RewardedAd ad) async {
        debugPrint(
          '❎ [ADMOB] Rewarded ad '
          'dismissed: $purpose',
        );

        await SystemChrome
            .setEnabledSystemUIMode(
          SystemUiMode.edgeToEdge,
        );

        try {
          ad.dispose();
        } catch (error) {
          debugPrint(
            '⚠️ [ADMOB] Dispose after '
            'dismiss failed: '
            '$error',
          );
        }

        if (_rewardedAd == ad) {
          _clearAdState();
        }

        _adShowing = false;

        _activeAdPurpose = '';

        _notify();

        await _reloadAfterDismiss(
          purpose,
        );
      },

      onAdFailedToShowFullScreenContent:
          (
        RewardedAd ad,
        AdError error,
      ) async {
        debugPrint(
          '❌ [ADMOB] Rewarded ad '
          'failed to show: '
          '$error',
        );

        await SystemChrome
            .setEnabledSystemUIMode(
          SystemUiMode.edgeToEdge,
        );

        try {
          ad.dispose();
        } catch (disposeError) {
          debugPrint(
            '⚠️ [ADMOB] Dispose after '
            'show failure failed: '
            '$disposeError',
          );
        }

        if (_rewardedAd == ad) {
          _clearAdState();
        }

        _adShowing = false;

        _activeAdPurpose = '';

        _rewardedAdRewardEarned = false;

        _adLoadError =
            'REWARDED_AD_SHOW_FAILED | '
            '${error.code} | '
            '${error.message}';

        _notify();

        await _reloadAfterDismiss(
          purpose,
        );
      },
    );

    _notify();
  }  // ============================================================
  // 🔄 RELOAD AFTER DISMISS
  // ============================================================

  Future<void> _reloadAfterDismiss(
    String purpose,
  ) async {
    if (_disposed) {
      return;
    }

    await Future<void>.delayed(
      const Duration(milliseconds: 500),
    );

    if (_disposed) {
      return;
    }

    final User? user =
        _auth.currentUser;

    if (user == null) {
      return;
    }

    await loadRewardedAd(
      purpose: purpose,
      notifyOnLoadError: false,
    );
  }

  // ============================================================
  // 🎁 REWARD HANDLER
  // ============================================================

  void _handleReward(
    String purpose,
    RewardItem reward,
  ) {
    if (_disposed) {
      return;
    }

    _rewardedAdRewardEarned = true;

    debugPrint(
      '🎁 [ADMOB] Reward received: '
      'purpose=$purpose, '
      'amount=${reward.amount}, '
      'type=${reward.type}',
    );

    final RewardCallback?
        callback =
        _rewardCallback;

    if (callback != null) {
      callback(
        purpose,
        reward,
      );
    }

    _notify();
  }

  // ============================================================
  // 📺 SHOW REWARDED AD
  // ============================================================

  Future<bool> showRewardedAd({
    required String purpose,
    RewardCallback? onReward,
  }) async {
    if (_disposed) {
      return false;
    }

    final User? user =
        _auth.currentUser;

    if (user == null) {
      debugPrint(
        '⚠️ [ADMOB] Show skipped: '
        'no authenticated user.',
      );

      return false;
    }

    if (_adShowing) {
      debugPrint(
        '⚠️ [ADMOB] Show skipped: '
        'another ad is already showing.',
      );

      return false;
    }

    final bool ready =
        await waitForRewardedAd(
      purpose: purpose,
    );

    if (!ready) {
      debugPrint(
        '❌ [ADMOB] Rewarded ad not ready: '
        '$purpose',
      );

      return false;
    }

    if (_disposed) {
      return false;
    }

    final RewardedAd? ad =
        _rewardedAd;

    if (ad == null) {
      debugPrint(
        '❌ [ADMOB] Rewarded ad became null '
        'before show.',
      );

      return false;
    }

    if (!_isReadyFor(
      purpose,
      user.uid,
    )) {
      debugPrint(
        '❌ [ADMOB] Rewarded ad state '
        'changed before show.',
      );

      return false;
    }

    return _showRewardedAd(
      ad: ad,
      purpose: purpose,
      onReward: onReward,
    );
  }

  // ============================================================
  // 📺 SHOW CURRENT REWARDED AD
  // ============================================================

  Future<bool> _showRewardedAd({
    required RewardedAd ad,
    required String purpose,
    RewardCallback? onReward,
  }) async {
    if (_disposed) {
      return false;
    }

    _adShowing = true;

    _activeAdPurpose =
        purpose;

    _rewardedAdRewardEarned =
        false;

    _rewardCallback =
        onReward;

    _adReady = false;

    _notify();

    try {
      // Android 15 / targetSdk 35+ uses
      // edge-to-edge by default.
      //
      // Force immersive mode before showing
      // the rewarded ad so the ad can occupy
      // the complete screen area.
      await SystemChrome
          .setEnabledSystemUIMode(
        SystemUiMode.immersive,
      );

      await ad.setImmersiveMode(
        true,
      );

      ad.show(
        onUserEarnedReward:
            (
          AdWithoutView ad,
          RewardItem reward,
        ) {
          _handleReward(
            purpose,
            reward,
          );
        },
      );

      debugPrint(
        '📺 [ADMOB] Rewarded ad '
        'show requested: $purpose',
      );

      return true;
    } catch (error) {
      debugPrint(
        '❌ [ADMOB] Failed to show '
        'rewarded ad: '
        '$error',
      );

      await SystemChrome
          .setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
      );

      try {
        ad.dispose();
      } catch (disposeError) {
        debugPrint(
          '⚠️ [ADMOB] Dispose after '
          'show exception failed: '
          '$disposeError',
        );
      }

      if (_rewardedAd == ad) {
        _clearAdState();
      }

      _adShowing = false;

      _activeAdPurpose = '';

      _rewardedAdRewardEarned =
          false;

      _rewardCallback = null;

      _adLoadError =
          'REWARDED_AD_SHOW_EXCEPTION | '
          '$error';

      _notify();

      await _reloadAfterDismiss(
        purpose,
      );

      return false;
    }
  }

  // ============================================================
  // 🐱 MINING AD
  // ============================================================

  Future<bool> showMiningAd({
    RewardCallback? onReward,
  }) async {
    return showRewardedAd(
      purpose:
          miningStartPurpose,
      onReward: onReward,
    );
  }

  // ============================================================
  // ⚡ POWER BOOST AD
  // ============================================================

  Future<bool> showPowerBoostAd({
    RewardCallback? onReward,
  }) async {
    return showRewardedAd(
      purpose:
          powerBoostPurpose,
      onReward: onReward,
    );
  }

  // ============================================================
  // 🔄 RESET AD STATE
  // ============================================================

  void resetAdState() {
    if (_disposed) {
      return;
    }

    _adShowing = false;

    _activeAdPurpose = '';

    _rewardedAdRewardEarned =
        false;

    _rewardCallback = null;

    _notify();
  }

  // ============================================================
  // 🧹 DISPOSE
  // ============================================================

  @override
  void dispose() {
    _disposed = true;

    _loadRequestId++;

    _adLoading = false;

    _loadingPurpose = '';

    _adShowing = false;

    _activeAdPurpose = '';

    _rewardCallback = null;

    _disposeCurrentAd();

    super.dispose();
  }
}