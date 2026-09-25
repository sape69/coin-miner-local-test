import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class HomeAdManager extends ChangeNotifier {
  // ============================================================
  // 📺 ADMOB
  // ============================================================

  static const String miningRewardedAdUnitId =
      'ca-app-pub-1131012057145658/6674097787';

  static const String powerBoostRewardedAdUnitId =
      'ca-app-pub-1131012057145658/7225738491';

  static const String powerBoostPurpose = 'power_boost';

  static const String miningStartPurpose = 'mining_start';

  // ============================================================
  // ⏱️ TIMEOUTS
  // ============================================================

  static const Duration adLoadTimeout =
      Duration(seconds: 20);

  static const Duration adReadyWaitTimeout =
      Duration(seconds: 20);

  static const Duration adReadyCheckInterval =
      Duration(milliseconds: 200);

  static const Duration reloadDelay =
      Duration(seconds: 3);

  // ============================================================
  // 🔥 FIREBASE / CALLBACKS
  // ============================================================

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final Future<void> Function()? onMiningStartReward;

  final Future<void> Function()? onPowerBoostReward;

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
  // 🔒 FLOW STATE
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

  // ============================================================
  // 🔔 NOTIFY
  // ============================================================

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  // ============================================================
  // 📺 ADMOB SDK INITIALIZATION
  // ============================================================

  Future<void> _initializeAdMob() async {
    if (_mobileAdsInitialization != null) {
      debugPrint(
        '🐱 [ADMOB] Initialization already started.',
      );

      await _mobileAdsInitialization;

      return;
    }

    debugPrint(
      '🐱 [ADMOB] Starting Mobile Ads initialization...',
    );

    _mobileAdsInitialization =
        MobileAds.instance.initialize();

    try {
      final InitializationStatus status =
          await _mobileAdsInitialization!;

      debugPrint(
        '🐱 [ADMOB] Mobile Ads initialized successfully.',
      );

      debugPrint(
        '🐱 [ADMOB] Adapter statuses: '
        '${status.adapterStatuses}',
      );
    } catch (error) {
      debugPrint(
        '❌ [ADMOB] Mobile Ads initialization failed: '
        '$error',
      );

      _mobileAdsInitialization = null;

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
      await _initializeAdMob();

      if (_disposed) {
        return;
      }

      await _preloadMiningAd();
    } catch (error) {
      debugPrint(
        '❌ [ADMOB] Initialization/preload failed: '
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
  // 📺 AD UNIT
  // ============================================================

  String _getAdUnitId(
    String purpose,
  ) {
    if (purpose == powerBoostPurpose) {
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
        '⚠️ [ADMOB] Error disposing ad: $error',
      );
    }
  }

  // ============================================================
  // 🔎 READY CHECK
  // ============================================================

  bool _isReadyFor(
    String purpose,
    String uid,
  ) {
    return _rewardedAd != null &&
        _adReady &&
        _rewardedAdPurpose == purpose &&
        _rewardedAdUserUid == uid;
  }

  // ============================================================
  // 🚀 INITIAL PRELOAD
  // ============================================================

  Future<void> _preloadMiningAd() async {
    if (_disposed) {
      return;
    }

    final User? user =
        _auth.currentUser;

    if (user == null) {
      debugPrint(
        '⚠️ [ADMOB] Preload skipped: '
        'no authenticated user.',
      );

      return;
    }

    debugPrint(
      '🐱 [ADMOB] Starting initial mining ad preload.',
    );

    await loadRewardedAd(
      purpose: miningStartPurpose,
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
      debugPrint(
        '❌ [ADMOB] Cannot wait for ad: '
        'no authenticated user.',
      );

      return false;
    }

    debugPrint(
      '🐱 [ADMOB] Waiting for rewarded ad: $purpose',
    );

    // ----------------------------------------------------------
    // Already ready
    // ----------------------------------------------------------

    if (_isReadyFor(
      purpose,
      user.uid,
    )) {
      debugPrint(
        '🐱 [ADMOB] Ad already ready: $purpose',
      );

      return true;
    }

    // ----------------------------------------------------------
    // Wrong-purpose ad
    // ----------------------------------------------------------

    if (_rewardedAd != null &&
        !_isReadyFor(
          purpose,
          user.uid,
        )) {
      debugPrint(
        '🐱 [ADMOB] Existing ad belongs to another purpose. '
        'Disposing it.',
      );

      _disposeCurrentAd();
    }

    // ----------------------------------------------------------
    // Another purpose is loading
    // ----------------------------------------------------------

    if (_adLoading &&
        _loadingPurpose != purpose) {
      debugPrint(
        '🐱 [ADMOB] Cancelling previous load: '
        '$_loadingPurpose',
      );

      _loadRequestId++;

      _adLoading = false;

      _loadingPurpose = '';

      _notify();
    }

    // ----------------------------------------------------------
    // Start loading
    // ----------------------------------------------------------

    if (!_adLoading) {
      await loadRewardedAd(
        purpose: purpose,
        notifyOnLoadError: true,
      );
    }

    // ----------------------------------------------------------
    // WAIT
    // ----------------------------------------------------------

    final Stopwatch stopwatch =
        Stopwatch()..start();

    while (
        stopwatch.elapsed <
            adReadyWaitTimeout) {
      if (_disposed) {
        return false;
      }

      final User? activeUser =
          _auth.currentUser;

      if (activeUser == null) {
        debugPrint(
          '❌ [ADMOB] User disappeared while waiting.',
        );

        return false;
      }

      if (_isReadyFor(
        purpose,
        activeUser.uid,
      )) {
        debugPrint(
          '✅ [ADMOB] Ad became ready: $purpose',
        );

        return true;
      }

      if (!_adLoading ||
          _loadingPurpose != purpose) {
        debugPrint(
          '⚠️ [ADMOB] Ad loading stopped before '
          'ad became ready: $purpose',
        );

        break;
      }

      await Future<void>.delayed(
        adReadyCheckInterval,
      );
    }

    debugPrint(
      '❌ [ADMOB] Ad was not ready within '
      '${adReadyWaitTimeout.inSeconds} seconds: '
      '$purpose',
    );

    if (_adLoadError.isNotEmpty) {
      debugPrint(
        '❌ [ADMOB] Last AdMob error: '
        '$_adLoadError',
      );
    }

    // ----------------------------------------------------------
    // FORCE RESET IF LOAD IS STUCK
    // ----------------------------------------------------------

    if (_adLoading &&
        _loadingPurpose == purpose) {
      debugPrint(
        '⚠️ [ADMOB] Load appears stuck. '
        'Forcing loading state reset.',
      );

      _loadRequestId++;

      _adLoading = false;

      _loadingPurpose = '';

      _notify();
    }

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

    debugPrint(
      '🐱 [ADMOB] loadRewardedAd() called: $purpose',
    );

    // ----------------------------------------------------------
    // ENSURE ADMOB INITIALIZED
    // ----------------------------------------------------------

    try {
      await _initializeAdMob();
    } catch (error) {
      if (!_disposed) {
        _adLoading = false;

        _loadingPurpose = '';

        _clearAdState();

        _adLoadError =
            'ADMOB_INITIALIZATION_FAILED | '
            'Purpose: $purpose | '
            'Error: $error';

        debugPrint(
          '❌ [ADMOB] $_adLoadError',
        );

        _notify();
      }

      return;
    }

    if (_disposed) {
      return;
    }

    // ----------------------------------------------------------
    // AUTH
    // ----------------------------------------------------------

    final User? user =
        _auth.currentUser;

    if (user == null) {
      _adLoading = false;

      _loadingPurpose = '';

      _clearAdState();

      _adLoadError =
          'NO_AUTH_USER | Purpose: $purpose';

      debugPrint(
        '❌ [ADMOB] $_adLoadError',
      );

      _notify();

      return;
    }

    // ----------------------------------------------------------
    // ALREADY READY
    // ----------------------------------------------------------

    if (_isReadyFor(
      purpose,
      user.uid,
    )) {
      debugPrint(
        '🐱 [ADMOB] Existing ready ad used: $purpose',
      );

      return;
    }

    // ----------------------------------------------------------
    // EXISTING LOAD
    // ----------------------------------------------------------

    if (_adLoading) {
      if (_loadingPurpose == purpose) {
        debugPrint(
          '🐱 [ADMOB] Load already running: $purpose',
        );

        return;
      }

      debugPrint(
        '🐱 [ADMOB] Cancelling different load: '
        '$_loadingPurpose',
      );

      _loadRequestId++;

      _adLoading = false;

      _loadingPurpose = '';
    }

    // ----------------------------------------------------------
    // DISPOSE OLD AD
    // ----------------------------------------------------------

    if (_rewardedAd != null) {
      debugPrint(
        '🐱 [ADMOB] Disposing previous rewarded ad.',
      );

      _disposeCurrentAd();
    }

    // ----------------------------------------------------------
    // REQUEST
    // ----------------------------------------------------------

    final int requestId =
        ++_loadRequestId;

    final String loadingUid =
        user.uid;

    final String adUnitId =
        _getAdUnitId(
      purpose,
    );

    _adLoading = true;

    _loadingPurpose = purpose;

    _adReady = false;

    _adLoadError = '';

    _rewardedAdPurpose = '';

    _rewardedAdUserUid = '';

    _notify();

    debugPrint(
      '================================================',
    );

    debugPrint(
      '🐱 [ADMOB] START REWARDED AD LOAD',
    );

    debugPrint(
      '🐱 [ADMOB] Purpose: $purpose',
    );

    debugPrint(
      '🐱 [ADMOB] Ad Unit: $adUnitId',
    );

    debugPrint(
      '🐱 [ADMOB] UID: $loadingUid',
    );

    debugPrint(
      '🐱 [ADMOB] Request ID: $requestId',
    );

    debugPrint(
      '================================================',
    );

    bool callbackReceived =
        false;

    // ----------------------------------------------------------
    // LOAD
    // ----------------------------------------------------------

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (
          RewardedAd ad,
        ) {
          callbackReceived = true;

          debugPrint(
            '✅ [ADMOB] onAdLoaded received: '
            '$purpose',
          );

          unawaited(
            _finishAdLoad(
              ad: ad,
              purpose: purpose,
              loadingUid: loadingUid,
              requestId: requestId,
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
            debugPrint(
              '⚠️ [ADMOB] Ignoring old load failure: '
              '$purpose',
            );

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
    // LOAD TIMEOUT
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

          debugPrint(
            '❌ [ADMOB] LOAD TIMEOUT: '
            '$purpose',
          );

          _loadRequestId++;

          _adLoading = false;

          _loadingPurpose = '';

          _clearAdState();

          _adLoadError =
              'LOAD_TIMEOUT | '
              'Purpose: $purpose | '
              'Timeout: '
              '${adLoadTimeout.inSeconds}s';

          _notify();

          if (notifyOnLoadError) {
            debugPrint(
              '❌ [ADMOB] Ad load timed out. '
              'Check AdMob configuration and '
              'Android logcat.',
            );
          }
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
        requestId != _loadRequestId) {
      debugPrint(
        '⚠️ [ADMOB] Ignoring stale loaded ad: '
        '$purpose',
      );

      ad.dispose();

      return;
    }

    final User? activeUser =
        _auth.currentUser;

    if (activeUser == null ||
        activeUser.uid !=
            loadingUid) {
      debugPrint(
        '❌ [ADMOB] Auth user changed during ad load.',
      );

      ad.dispose();

      _adLoading = false;

      _loadingPurpose = '';

      _clearAdState();

      _adLoadError =
          'AUTH_USER_CHANGED | '
          'Purpose: $purpose';

      _notify();

      return;
    }

    debugPrint(
      '✅ [ADMOB] Ad loaded successfully: '
      '$purpose',
    );

    // ==========================================================
    // 🔐 SERVER-SIDE VERIFICATION
    // ==========================================================

    try {
      debugPrint(
        '🐱 [ADMOB] Setting SSV customData: '
        '$loadingUid:$purpose',
      );

      await ad.setServerSideOptions(
        ServerSideVerificationOptions(
          customData:
              '$loadingUid:$purpose',
        ),
      );

      debugPrint(
        '✅ [ADMOB] SSV customData configured: '
        '$purpose',
      );
    } catch (error) {
      debugPrint(
        '❌ [ADMOB] SSV setup failed: '
        '$purpose | $error',
      );

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
          'Purpose: $purpose | '
          'Error: $error';

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

      _adLoadError =
          'AUTH_USER_CHANGED | '
          'Purpose: $purpose';

      _notify();

      return;
    }

    // ==========================================================
    // 📺 STORE READY AD
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

    // ==========================================================
    // 📺 FULL SCREEN CALLBACK
    // ==========================================================

    ad.fullScreenContentCallback =
        FullScreenContentCallback<
            RewardedAd>(
      onAdShowedFullScreenContent:
          (
        RewardedAd ad,
      ) {
        debugPrint(
          '✅ [ADMOB] SHOWED FULLSCREEN: '
          '$purpose',
        );
      },
      onAdImpression:
          (
        RewardedAd ad,
      ) {
        debugPrint(
          '🐱 [ADMOB] IMPRESSION: '
          '$purpose',
        );
      },
      onAdClicked:
          (
        RewardedAd ad,
      ) {
        debugPrint(
          '🐱 [ADMOB] CLICKED: '
          '$purpose',
        );
      },
      onAdDismissedFullScreenContent:
          (
        RewardedAd ad,
      ) {
        debugPrint(
          '🐱 [ADMOB] DISMISSED: '
          '$purpose',
        );

        ad.dispose();

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
          '❌ [ADMOB] FAILED TO SHOW: '
          '$purpose | '
          'Code: ${error.code} | '
          'Domain: ${error.domain} | '
          'Message: ${error.message}',
        );

        ad.dispose();

        _clearAdState();

        _setFlowActive(
          purpose,
          false,
        );

        _adLoadError =
            'SHOW_FAILED | '
            'Purpose: $purpose | '
            'Code: ${error.code} | '
            'Domain: ${error.domain} | '
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

    _notify();

    debugPrint(
      '================================================',
    );

    debugPrint(
      '✅ [ADMOB] REWARDED AD READY',
    );

    debugPrint(
      '🐱 [ADMOB] Purpose: $purpose',
    );

    debugPrint(
      '🐱 [ADMOB] UID: $loadingUid',
    );

    debugPrint(
      '🐱 [ADMOB] Ready: $_adReady',
    );

    debugPrint(
      '================================================',
    );
  }

  // ============================================================
  // 🔄 RELOAD AFTER DISMISS
  // ============================================================

  Future<void> _reloadAfterDismiss(
    String purpose,
  ) async {
    debugPrint(
      '🐱 [ADMOB] Reload scheduled: '
      '$purpose',
    );

    await Future<void>.delayed(
      reloadDelay,
    );

    if (_disposed) {
      return;
    }

    final User? user =
        _auth.currentUser;

    if (user == null) {
      debugPrint(
        '⚠️ [ADMOB] Reload skipped: '
        'no authenticated user.',
      );

      return;
    }

    if (_adLoading) {
      debugPrint(
        '⚠️ [ADMOB] Reload skipped: '
        'another ad is loading.',
      );

      return;
    }

    if (_isReadyFor(
      purpose,
      user.uid,
    )) {
      return;
    }

    debugPrint(
      '🐱 [ADMOB] Reloading rewarded ad: '
      '$purpose',
    );

    await loadRewardedAd(
      purpose: purpose,
      notifyOnLoadError: false,
    );
  }

  // ============================================================
  // 🎁 REWARD CALLBACK
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
        debugPrint(
          '⚠️ [ADMOB] Mining reward callback '
          'already running.',
        );

        return;
      }

      _miningRewardCallbackStarted =
          true;
    }

    if (purpose ==
        powerBoostPurpose) {
      if (_powerBoostRewardCallbackStarted) {
        debugPrint(
          '⚠️ [ADMOB] Power boost reward callback '
          'already running.',
        );

        return;
      }

      _powerBoostRewardCallbackStarted =
          true;
    }

    debugPrint(
      '🎁 [ADMOB] REWARD EARNED: '
      '$purpose',
    );

    unawaited(
      _executeRewardCallback(
        purpose,
      ),
    );
  }

  // ============================================================
  // 🔐 BACKEND REWARD CALLBACK
  // ============================================================

  Future<void> _executeRewardCallback(
    String purpose,
  ) async {
    try {
      if (_disposed) {
        return;
      }

      debugPrint(
        '🐱 [ADMOB] Starting backend reward callback: '
        '$purpose',
      );

      if (purpose ==
          miningStartPurpose) {
        await onMiningStartReward
            ?.call();
      } else if (purpose ==
          powerBoostPurpose) {
        await onPowerBoostReward
            ?.call();
      }

      debugPrint(
        '✅ [ADMOB] Backend reward callback completed: '
        '$purpose',
      );
    } catch (error) {
      debugPrint(
        '❌ [ADMOB] Backend reward callback failed: '
        '$purpose | $error',
      );
    } finally {
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
  }

  // ============================================================
  // ⛏️ SHOW MINING START AD
  // ============================================================

  Future<bool> showMiningStartAd() async {
    debugPrint(
      '🐱 [ADMOB] showMiningStartAd()',
    );

    return _showRewardedAd(
      purpose:
          miningStartPurpose,
    );
  }

  // ============================================================
  // ⚡ SHOW POWER BOOST AD
  // ============================================================

  Future<bool> showPowerBoostAd() async {
    debugPrint(
      '🐱 [ADMOB] showPowerBoostAd()',
    );

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
        '❌ [ADMOB] Cannot show ad: '
        'no authenticated user.',
      );

      return false;
    }

    debugPrint(
      '================================================',
    );

    debugPrint(
      '🐱 [ADMOB] PREPARING REWARDED AD',
    );

    debugPrint(
      '🐱 [ADMOB] Purpose: $purpose',
    );

    debugPrint(
      '🐱 [ADMOB] UID: ${user.uid}',
    );

    debugPrint(
      '================================================',
    );

    // ----------------------------------------------------------
    // DUPLICATE FLOWS
    // ----------------------------------------------------------

    if (purpose ==
            miningStartPurpose &&
        _miningAdFlowActive) {
      debugPrint(
        '⚠️ [ADMOB] Mining ad flow already active.',
      );

      return false;
    }

    if (purpose ==
            powerBoostPurpose &&
        _powerBoostAdFlowActive) {
      debugPrint(
        '⚠️ [ADMOB] Power boost ad flow already active.',
      );

      return false;
    }

    if (purpose ==
            miningStartPurpose &&
        _powerBoostAdFlowActive) {
      debugPrint(
        '⚠️ [ADMOB] Power boost flow is active.',
      );

      return false;
    }

    if (purpose ==
            powerBoostPurpose &&
        _miningAdFlowActive) {
      debugPrint(
        '⚠️ [ADMOB] Mining flow is active.',
      );

      return false;
    }

    // ----------------------------------------------------------
    // DUPLICATE CALLBACK
    // ----------------------------------------------------------

    if (purpose ==
            miningStartPurpose &&
        _miningRewardCallbackStarted) {
      debugPrint(
        '⚠️ [ADMOB] Mining reward callback already running.',
      );

      return false;
    }

    if (purpose ==
            powerBoostPurpose &&
        _powerBoostRewardCallbackStarted) {
      debugPrint(
        '⚠️ [ADMOB] Power boost reward callback already running.',
      );

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
      debugPrint(
        '🐱 [ADMOB] Step 1/4: waiting for ad...',
      );

      final bool ready =
          await waitForRewardedAd(
        purpose:
            purpose,
      );

      if (_disposed) {
        _setFlowActive(
          purpose,
          false,
        );

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
          '❌ [ADMOB] Step 1 failed: '
          'ad is not ready.',
        );

        debugPrint(
          '❌ [ADMOB] adReady=$_adReady',
        );

        debugPrint(
          '❌ [ADMOB] adLoading=$_adLoading',
        );

        debugPrint(
          '❌ [ADMOB] loadingPurpose=$_loadingPurpose',
        );

        debugPrint(
          '❌ [ADMOB] rewardedAdPurpose=$_rewardedAdPurpose',
        );

        debugPrint(
          '❌ [ADMOB] error=$_adLoadError',
        );

        _setFlowActive(
          purpose,
          false,
        );

        _notify();

        return false;
      }

      debugPrint(
        '✅ [ADMOB] Step 1/4 complete: ad READY.',
      );

      // --------------------------------------------------------
      // GET AD
      // --------------------------------------------------------

      ad = _rewardedAd;

      if (ad == null) {
        debugPrint(
          '❌ [ADMOB] Step 2/4 failed: '
          'RewardedAd is null.',
        );

        _setFlowActive(
          purpose,
          false,
        );

        _notify();

        return false;
      }

      debugPrint(
        '✅ [ADMOB] Step 2/4 complete: '
        'RewardedAd object acquired.',
      );

      // --------------------------------------------------------
      // MOVE OWNERSHIP TO LOCAL VARIABLE
      // --------------------------------------------------------

      _clearAdState();

      _notify();

      bool rewardEarned =
          false;

      // --------------------------------------------------------
      // SHOW
      // --------------------------------------------------------

      debugPrint(
        '🐱 [ADMOB] Step 3/4: calling ad.show()...',
      );

      ad.show(
        onUserEarnedReward: (
          AdWithoutView adWithoutView,
          RewardItem reward,
        ) {
          if (rewardEarned) {
            debugPrint(
              '⚠️ [ADMOB] Duplicate reward callback ignored.',
            );

            return;
          }

          rewardEarned = true;

          debugPrint(
            '================================================',
          );

          debugPrint(
            '🎁 [ADMOB] USER EARNED REWARD',
          );

          debugPrint(
            '🐱 [ADMOB] Purpose: $purpose',
          );

          debugPrint(
            '🐱 [ADMOB] Amount: ${reward.amount}',
          );

          debugPrint(
            '🐱 [ADMOB] Type: ${reward.type}',
          );

          debugPrint(
            '================================================',
          );

          _handleRewardEarned(
            purpose,
          );
        },
      );

      debugPrint(
        '✅ [ADMOB] Step 3/4 complete: '
        'ad.show() called.',
      );

      return true;
    } catch (error) {
      debugPrint(
        '================================================',
      );

      debugPrint(
        '❌ [ADMOB] SHOW EXCEPTION',
      );

      debugPrint(
        '❌ [ADMOB] Purpose: $purpose',
      );

      debugPrint(
        '❌ [ADMOB] Error: $error',
      );

      debugPrint(
        '================================================',
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

    try {
      ad?.dispose();
    } catch (_) {}

    super.dispose();
  }
}