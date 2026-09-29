import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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

  // Kuinka monta latausyritystä tehdään yhden käyttäjän
  // painalluksen aikana ennen kuin ilmoitetaan ettei mainosta
  // ole saatavilla.
  static const int maxAdLoadAttempts = 3;

  // Pieni tauko epäonnistuneen latauksen jälkeen.
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
  }

  // ============================================================
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
        _rewardedAdUserUid ==
            uid;
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
  //
  // TÄRKEÄ MUUTOS:
  //
  // Jos ensimmäinen AdMob-lataus epäonnistuu,
  // emme heti ilmoita käyttäjälle "No available".
  //
  // Yritämme automaattisesti uudelleen.
  //
  // Näin käyttäjän ei tarvitse painaa
  // ALOITA LOUHINTA -nappia useita kertoja.
  //
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

    // ----------------------------------------------------------
    // Jos oikea mainos on jo valmis
    // ----------------------------------------------------------

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

    // ----------------------------------------------------------
    // Yritetään automaattisesti useamman kerran
    // ----------------------------------------------------------

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

      // --------------------------------------------------------
      // Jos toinen purpose latautuu, perutaan vanha lataus
      // --------------------------------------------------------

      if (_adLoading &&
          _loadingPurpose !=
              purpose) {
        _loadRequestId++;

        _adLoading = false;

        _loadingPurpose = '';
      }

      // --------------------------------------------------------
      // Vanha väärän purpose-mainos pois
      // --------------------------------------------------------

      if (_rewardedAd != null &&
          !_isReadyFor(
            purpose,
            activeUser.uid,
          )) {
        _disposeCurrentAd();
      }

      // --------------------------------------------------------
      // Käynnistä lataus
      // --------------------------------------------------------

      if (!_adLoading) {
        await loadRewardedAd(
          purpose: purpose,
          notifyOnLoadError: true,
        );
      }

      // --------------------------------------------------------
      // Odota tämän latausyrityksen valmistumista
      // --------------------------------------------------------

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

        // ------------------------------------------------------
        // Lataus epäonnistui
        // ------------------------------------------------------

        if (!_adLoading ||
            _loadingPurpose !=
                purpose) {
          break;
        }

        await Future<void>.delayed(
          adCheckInterval,
        );
      }

      // --------------------------------------------------------
      // Tarkista vielä kerran ennen retryä
      // --------------------------------------------------------

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

      // --------------------------------------------------------
      // Ei ollut valmis → uusi yritys
      // --------------------------------------------------------

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
  }

  // ============================================================
  // 📺 LOAD REWARDED AD
  // ============================================================

  Future<void> loadRewardedAd({
    required String purpose,
    bool notifyOnLoadError = true,
  }) async {
    if (_disposed) {
      return;
    }

    final bool allowed =
        _consentCheckCompleted
            ? _canRequestAds
            : await _checkAdConsent();

    if (!allowed) {
      _adLoading = false;

      _loadingPurpose = '';

      _clearAdState();

      _adLoadError =
          'CONSENT_NOT_GRANTED | '
          'Purpose: $purpose';

      _notify();

      return;
    }

    try {
      await _initializeAdMob();
    } catch (error) {
      _adLoading = false;

      _loadingPurpose = '';

      _clearAdState();

      _adLoadError =
          'ADMOB_INITIALIZATION_FAILED | '
          '$error';

      _notify();

      return;
    }

    final User? user =
        _auth.currentUser;

    if (user == null) {
      _adLoading = false;

      _loadingPurpose = '';

      _clearAdState();

      _adLoadError =
          'NO_AUTH_USER';

      _notify();

      return;
    }

    if (_isReadyFor(
      purpose,
      user.uid,
    )) {
      return;
    }

    if (_adLoading) {
      if (_loadingPurpose ==
          purpose) {
        return;
      }

      _loadRequestId++;

      _adLoading = false;

      _loadingPurpose = '';
    }

    if (_rewardedAd != null) {
      _disposeCurrentAd();
    }

    final int requestId =
        ++_loadRequestId;

    final String loadingUid =
        user.uid;

    final String adUnitId =
        _getAdUnitId(
      purpose,
    );

    _adLoading = true;

    _loadingPurpose =
        purpose;

    _adReady = false;

    _rewardedAdPurpose = '';

    _rewardedAdUserUid = '';

    _adLoadError = '';

    _notify();

    bool callbackReceived =
        false;

    debugPrint(
      '🐱 [ADMOB] Loading rewarded ad: '
      '$purpose',
    );

    RewardedAd.load(
      adUnitId: adUnitId,
      request:
          const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (
          RewardedAd ad,
        ) {
          callbackReceived = true;

          unawaited(
            _finishAdLoad(
              ad: ad,
              purpose: purpose,
              loadingUid:
                  loadingUid,
              requestId:
                  requestId,
            ),
          );
        },
        onAdFailedToLoad: (
          LoadAdError error,
        ) {
          callbackReceived = true;

          if (_disposed ||
              requestId !=
                  _loadRequestId) {
            return;
          }

          _adLoading = false;

          _loadingPurpose = '';

          _clearAdState();

          _adLoadError =
              'LOAD_FAILED | '
              'Purpose: $purpose | '
              'Code: ${error.code} | '
              'Domain: ${error.domain} | '
              'Message: ${error.message}';

          debugPrint(
            '❌ [ADMOB] $_adLoadError',
          );

          _notify();

          if (notifyOnLoadError) {
            onAdLoadError?.call(
              purpose,
              error,
            );
          }
        },
      ),
    );

    // ----------------------------------------------------------
    // ⏱️ LOAD TIMEOUT
    // ----------------------------------------------------------

    unawaited(
      Future<void>.delayed(
        adLoadTimeout,
      ).then(
        (_) {
          if (_disposed ||
              requestId !=
                  _loadRequestId) {
            return;
          }

          if (callbackReceived) {
            return;
          }

          if (!_adLoading ||
              _loadingPurpose !=
                  purpose) {
            return;
          }

          _loadRequestId++;

          _adLoading = false;

          _loadingPurpose = '';

          _clearAdState();

          _adLoadError =
              'LOAD_TIMEOUT | '
              'Purpose: $purpose';

          debugPrint(
            '⚠️ [ADMOB] $_adLoadError',
          );

          _notify();
        },
      ),
    );
  }

  // ============================================================
  // 🔐 FINISH AD LOAD + SSV
  // ============================================================

  Future<void> _finishAdLoad({
    required RewardedAd ad,
    required String purpose,
    required String loadingUid,
    required int requestId,
  }) async {
    if (_disposed ||
        requestId !=
            _loadRequestId) {
      ad.dispose();
      return;
    }

    final User? activeUser =
        _auth.currentUser;

    if (activeUser == null ||
        activeUser.uid !=
            loadingUid) {
      ad.dispose();

      _adLoading = false;

      _loadingPurpose = '';

      _clearAdState();

      _adLoadError =
          'AUTH_USER_CHANGED';

      _notify();

      return;
    }

    // ==========================================================
    // 🔐 ADMOB SERVER-SIDE VERIFICATION
    // ==========================================================
    //
    // UID + PURPOSE lähetetään AdMob SSV customData-kenttään.
    //
    // Esimerkiksi:
    //
    // abc123:mining_start
    //
    // tai:
    //
    // abc123:power_boost
    //
    // ==========================================================

    try {
      await ad.setServerSideOptions(
        ServerSideVerificationOptions(
          customData:
              '$loadingUid:$purpose',
        ),
      );
    } catch (error) {
      ad.dispose();

      if (_disposed ||
          requestId !=
              _loadRequestId) {
        return;
      }

      _adLoading = false;

      _loadingPurpose = '';

      _clearAdState();

      _adLoadError =
          'SSV_SETUP_FAILED | '
          '$error';

      _notify();

      return;
    }

    if (_disposed ||
        requestId !=
            _loadRequestId) {
      ad.dispose();
      return;
    }

    final User? verifiedUser =
        _auth.currentUser;

    if (verifiedUser == null ||
        verifiedUser.uid !=
            loadingUid) {
      ad.dispose();

      _adLoading = false;

      _loadingPurpose = '';

      _clearAdState();

      return;
    }

    // ==========================================================
    // 📺 FULLSCREEN CALLBACKS
    // ==========================================================

    ad.fullScreenContentCallback =
        FullScreenContentCallback<RewardedAd>(
      onAdShowedFullScreenContent:
          (
        RewardedAd ad,
      ) {
        debugPrint(
          '✅ [ADMOB] Ad shown: '
          '$purpose',
        );
      },
      onAdImpression:
          (
        RewardedAd ad,
      ) {
        debugPrint(
          '🐱 [ADMOB] Impression: '
          '$purpose',
        );
      },
      onAdClicked:
          (
        RewardedAd ad,
      ) {
        debugPrint(
          '🐱 [ADMOB] Clicked: '
          '$purpose',
        );
      },
      onAdDismissedFullScreenContent:
          (
        RewardedAd ad,
      ) {
        debugPrint(
          '🐱 [ADMOB] Ad dismissed: '
          '$purpose',
        );

        try {
          ad.dispose();
        } catch (_) {}

        _clearAdState();

        _setFlowActive(
          purpose,
          false,
        );

        _notify();

        onAdDismissed?.call(
          purpose,
        );

        if (!_disposed) {
          unawaited(
            _reloadAfterDismiss(
              purpose,
            ),
          );
        }
      },
      onAdFailedToShowFullScreenContent:
          (
        RewardedAd ad,
        AdError error,
      ) {
        debugPrint(
          '❌ [ADMOB] Failed to show: '
          '$purpose | '
          '${error.message}',
        );

        try {
          ad.dispose();
        } catch (_) {}

        _clearAdState();

        _setFlowActive(
          purpose,
          false,
        );

        _resetRewardCallbackState(
          purpose,
        );

        _adLoadError =
            'SHOW_FAILED | '
            'Purpose: $purpose | '
            'Code: ${error.code} | '
            'Message: ${error.message}';

        _notify();

        onAdShowError?.call(
          purpose,
          error,
        );

        if (!_disposed) {
          unawaited(
            _reloadAfterDismiss(
              purpose,
            ),
          );
        }
      },
    );

    // ==========================================================
    // ✅ STORE READY AD
    // ==========================================================

    _rewardedAd = ad;

    _rewardedAdPurpose =
        purpose;

    _rewardedAdUserUid =
        loadingUid;

    _adReady = true;

    _adLoading = false;

    _loadingPurpose = '';

    _adLoadError = '';

    _notify();

    debugPrint(
      '✅ [ADMOB] REWARDED AD READY: '
      '$purpose',
    );
  }

  // ============================================================
  // 🔄 RELOAD AFTER DISMISS
  // ============================================================

  Future<void> _reloadAfterDismiss(
    String purpose,
  ) async {
    await Future<void>.delayed(
      reloadDelay,
    );

    if (_disposed) {
      return;
    }

    final User? user =
        _auth.currentUser;

    if (user == null) {
      return;
    }

    if (_adLoading) {
      return;
    }

    if (_isReadyFor(
      purpose,
      user.uid,
    )) {
      return;
    }

    await loadRewardedAd(
      purpose: purpose,
      notifyOnLoadError: false,
    );
  }

  // ============================================================
  // 🎁 REWARD EARNED
  // ============================================================

  void _handleRewardEarned(
    String purpose,
  ) {
    if (_disposed) {
      return;
    }

    if (purpose ==
        miningStartPurpose) {
      if (_miningRewardCallbackStarted) {
        return;
      }

      _miningRewardCallbackStarted =
          true;
    }

    if (purpose ==
        powerBoostPurpose) {
      if (_powerBoostRewardCallbackStarted) {
        return;
      }

      _powerBoostRewardCallbackStarted =
          true;
    }

    debugPrint(
      '🎁 [ADMOB] Reward earned: '
      '$purpose',
    );

    unawaited(
      _executeRewardCallback(
        purpose,
      ),
    );
  }

  // ============================================================
  // 🔥 BACKEND CALLBACK
  // ============================================================

  Future<void> _executeRewardCallback(
    String purpose,
  ) async {
    try {
      if (_disposed) {
        return;
      }

      if (purpose ==
          miningStartPurpose) {
        final callback =
            onMiningStartReward;

        if (callback == null) {
          throw Exception(
            'Mining reward callback is null.',
          );
        }

        await callback();
      } else if (purpose ==
          powerBoostPurpose) {
        final callback =
            onPowerBoostReward;

        if (callback == null) {
          throw Exception(
            'Power Boost callback is null.',
          );
        }

        await callback();
      } else {
        throw Exception(
          'Unknown reward purpose: '
          '$purpose',
        );
      }

      debugPrint(
        '✅ [ADMOB] Backend callback completed: '
        '$purpose',
      );
    } catch (error) {
      debugPrint(
        '❌ [ADMOB] Backend callback failed: '
        '$purpose | $error',
      );
    } finally {
      _resetRewardCallbackState(
        purpose,
      );
    }
  }

  // ============================================================
  // ⛏️ SHOW MINING START AD
  // ============================================================

  Future<bool> showMiningStartAd() async {
    return _showRewardedAd(
      purpose:
          miningStartPurpose,
    );
  }

  // ============================================================
  // ⚡ SHOW POWER BOOST AD
  // ============================================================

  Future<bool> showPowerBoostAd() async {
    return _showRewardedAd(
      purpose:
          powerBoostPurpose,
    );
  }

  // ============================================================
  // 📺 SHOW REWARDED AD
  // ============================================================

  Future<bool> _showRewardedAd({
    required String purpose,
  }) async {
    if (_disposed) {
      return false;
    }

    final User? user =
        _auth.currentUser;

    if (user == null) {
      debugPrint(
        '❌ [ADMOB] No authenticated user.',
      );

      return false;
    }

    final bool allowed =
        _consentCheckCompleted
            ? _canRequestAds
            : await _checkAdConsent();

    if (!allowed) {
      debugPrint(
        '⚠️ [ADMOB] Ad request not allowed.',
      );

      return false;
    }

    // ==========================================================
    // 🔒 PREVENT DUPLICATE FLOWS
    // ==========================================================

    if (purpose ==
            miningStartPurpose &&
        _miningAdFlowActive) {
      return false;
    }

    if (purpose ==
            powerBoostPurpose &&
        _powerBoostAdFlowActive) {
      return false;
    }

    if (purpose ==
            miningStartPurpose &&
        _powerBoostAdFlowActive) {
      return false;
    }

    if (purpose ==
            powerBoostPurpose &&
        _miningAdFlowActive) {
      return false;
    }

    if (purpose ==
            miningStartPurpose &&
        _miningRewardCallbackStarted) {
      return false;
    }

    if (purpose ==
            powerBoostPurpose &&
        _powerBoostRewardCallbackStarted) {
      return false;
    }

    _setFlowActive(
      purpose,
      true,
    );

    _adLoadError = '';

    _notify();

    RewardedAd? ad;

    try {
      // --------------------------------------------------------
      // STEP 1
      // --------------------------------------------------------

      final bool ready =
          await waitForRewardedAd(
        purpose:
            purpose,
      );

      if (_disposed) {
        return false;
      }

      final User? activeUser =
          _auth.currentUser;

      if (!ready ||
          activeUser == null ||
          !_isReadyFor(
            purpose,
            activeUser.uid,
          )) {
        debugPrint(
          '❌ [ADMOB] Ad not ready after '
          '$maxAdLoadAttempts attempts.',
        );

        _setFlowActive(
          purpose,
          false,
        );

        _notify();

        return false;
      }

      // --------------------------------------------------------
      // STEP 2
      // --------------------------------------------------------

      ad = _rewardedAd;

      if (ad == null) {
        _setFlowActive(
          purpose,
          false,
        );

        return false;
      }

      // --------------------------------------------------------
      // MOVE AD OWNERSHIP
      // --------------------------------------------------------

      _clearAdState();

      _notify();

      bool rewardEarned = false;

      // --------------------------------------------------------
      // STEP 3
      // SHOW
      // --------------------------------------------------------

      ad.show(
        onUserEarnedReward:
            (
          AdWithoutView adWithoutView,
          RewardItem reward,
        ) {
          if (rewardEarned) {
            return;
          }

          rewardEarned = true;

          debugPrint(
            '🎁 [ADMOB] Reward received.'
            ' Purpose=$purpose '
            'Amount=${reward.amount} '
            'Type=${reward.type}',
          );

          _handleRewardEarned(
            purpose,
          );
        },
      );

      debugPrint(
        '✅ [ADMOB] Ad.show() called: '
        '$purpose',
      );

      return true;
    } catch (error) {
      debugPrint(
        '❌ [ADMOB] Show exception: '
        '$purpose | $error',
      );

      try {
        ad?.dispose();
      } catch (_) {}

      _clearAdState();

      _setFlowActive(
        purpose,
        false,
      );

      _resetRewardCallbackState(
        purpose,
      );

      _adLoadError =
          'SHOW_EXCEPTION | '
          'Purpose: $purpose | '
          'Error: $error';

      _notify();

      return false;
    }
  }

  // ============================================================
  // 🔒 FLOW STATE
  // ============================================================

  void _setFlowActive(
    String purpose,
    bool active,
  ) {
    if (purpose ==
        miningStartPurpose) {
      _miningAdFlowActive =
          active;
    }

    if (purpose ==
        powerBoostPurpose) {
      _powerBoostAdFlowActive =
          active;
    }
  }

  // ============================================================
  // 🔄 RESET CALLBACK STATE
  // ============================================================

  void _resetRewardCallbackState(
    String purpose,
  ) {
    if (purpose ==
        miningStartPurpose) {
      _miningRewardCallbackStarted =
          false;
    }

    if (purpose ==
        powerBoostPurpose) {
      _powerBoostRewardCallbackStarted =
          false;
    }
  }

  // ============================================================
  // 🧹 DISPOSE
  // ============================================================

  @override
  void dispose() {
    debugPrint(
      '🐱 [ADMOB] HomeAdManager disposed.',
    );

    _disposed = true;

    _loadRequestId++;

    final RewardedAd? ad =
        _rewardedAd;

    _rewardedAd = null;

    _adReady = false;

    _adLoading = false;

    _loadingPurpose = '';

    _rewardedAdPurpose = '';

    _rewardedAdUserUid = '';

    try {
      ad?.dispose();
    } catch (_) {}

    super.dispose();
  }
}