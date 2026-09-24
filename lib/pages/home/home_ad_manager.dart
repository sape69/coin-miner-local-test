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
  // 🔥 FIREBASE / CALLBACKS
  // ============================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

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
  // CONSTRUCTOR
  // ============================================================

  HomeAdManager({
    this.onMiningStartReward,
    this.onPowerBoostReward,
    this.onAdLoadError,
    this.onAdShowError,
    this.onAdDismissed,
  }) {
    unawaited(
      _preloadMiningAd(),
    );
  }

  // ============================================================
  // GETTERS
  // ============================================================

  RewardedAd? get rewardedAd => _rewardedAd;

  bool get adReady => _adReady;

  bool get adLoading => _adLoading;

  String get rewardedAdPurpose => _rewardedAdPurpose;

  String get adLoadError => _adLoadError;

  bool get miningAdFlowActive => _miningAdFlowActive;

  bool get powerBoostAdFlowActive => _powerBoostAdFlowActive;

  // ============================================================
  // 🔔 NOTIFY
  // ============================================================

  void _notify() {
    if (!_disposed) {
      notifyListeners();
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
    final RewardedAd? ad = _rewardedAd;

    _clearAdState();

    ad?.dispose();
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

    final User? user = _auth.currentUser;

    if (user == null) {
      debugPrint(
        '🐱 [ADMOB] Preload skipped: no authenticated user.',
      );

      return;
    }

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

    final User? user = _auth.currentUser;

    if (user == null) {
      debugPrint(
        '❌ [ADMOB] Cannot wait for ad: no authenticated user.',
      );

      return false;
    }

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
        '🐱 [ADMOB] Disposing ad for another purpose.',
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
    // Start loading if necessary
    // ----------------------------------------------------------

    if (!_adLoading) {
      await loadRewardedAd(
        purpose: purpose,
        notifyOnLoadError: true,
      );
    }

    // ----------------------------------------------------------
    // Wait up to 20 seconds
    // ----------------------------------------------------------

    const Duration interval =
        Duration(milliseconds: 200);

    const int maxChecks = 100;

    for (int i = 0; i < maxChecks; i++) {
      if (_disposed) {
        return false;
      }

      final User? activeUser = _auth.currentUser;

      if (activeUser == null) {
        return false;
      }

      if (_isReadyFor(
        purpose,
        activeUser.uid,
      )) {
        debugPrint(
          '🐱 [ADMOB] Ad became ready: $purpose',
        );

        return true;
      }

      if (!_adLoading ||
          _loadingPurpose != purpose) {
        break;
      }

      await Future<void>.delayed(
        interval,
      );
    }

    final User? finalUser = _auth.currentUser;

    final bool ready =
        !_disposed &&
        finalUser != null &&
        _isReadyFor(
          purpose,
          finalUser.uid,
        );

    if (!ready) {
      debugPrint(
        '❌ [ADMOB] Ad was not ready after 20 seconds: '
        '$purpose',
      );

      if (_adLoadError.isNotEmpty) {
        debugPrint(
          '❌ [ADMOB] Last load error: $_adLoadError',
        );
      } else if (_adLoading) {
        debugPrint(
          '⚠️ [ADMOB] Ad is still loading after 20 seconds: '
          '$purpose',
        );
      }
    }

    return ready;
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

    final User? user = _auth.currentUser;

    if (user == null) {
      _adLoading = false;

      _loadingPurpose = '';

      _clearAdState();

      _adLoadError =
          'NO_AUTH_USER | Purpose: $purpose';

      _notify();

      return;
    }

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
    // Existing load
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
    // Dispose old ad
    // ----------------------------------------------------------

    if (_rewardedAd != null) {
      _disposeCurrentAd();
    }

    // ----------------------------------------------------------
    // Request information
    // ----------------------------------------------------------

    final int requestId = ++_loadRequestId;

    final String loadingUid = user.uid;

    final String adUnitId = _getAdUnitId(
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
      '🐱 [ADMOB] Loading rewarded ad',
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
          if (_disposed ||
              requestId != _loadRequestId) {
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
      ad.dispose();

      return;
    }

    final User? activeUser = _auth.currentUser;

    if (activeUser == null ||
        activeUser.uid != loadingUid) {
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
      '🐱 [ADMOB] Ad loaded successfully: $purpose',
    );

    // ==========================================================
    // 🔐 SERVER-SIDE VERIFICATION
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
          requestId != _loadRequestId) {
        return;
      }

      _adLoading = false;

      _loadingPurpose = '';

      _clearAdState();

      _adLoadError =
          'SSV_SETUP_FAILED | '
          'Purpose: $purpose | '
          'Error: $error';

      debugPrint(
        '❌ [ADMOB] $_adLoadError',
      );

      _notify();

      return;
    }

    if (_disposed ||
        requestId != _loadRequestId) {
      ad.dispose();

      return;
    }

    final User? verifiedUser = _auth.currentUser;

    if (verifiedUser == null ||
        verifiedUser.uid != loadingUid) {
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

    _rewardedAdPurpose = purpose;

    _rewardedAdUserUid = loadingUid;

    _adReady = true;

    _adLoading = false;

    _loadingPurpose = '';

    _adLoadError = '';

    // ==========================================================
    // 📺 FULL SCREEN CALLBACK
    // ==========================================================

    ad.fullScreenContentCallback =
        FullScreenContentCallback<RewardedAd>(
      onAdShowedFullScreenContent: (
        RewardedAd ad,
      ) {
        debugPrint(
          '🐱 [ADMOB] Shown: $purpose',
        );
      },
      onAdImpression: (
        RewardedAd ad,
      ) {
        debugPrint(
          '🐱 [ADMOB] Impression: $purpose',
        );
      },
      onAdClicked: (
        RewardedAd ad,
      ) {
        debugPrint(
          '🐱 [ADMOB] Clicked: $purpose',
        );
      },
      onAdDismissedFullScreenContent: (
        RewardedAd ad,
      ) {
        debugPrint(
          '🐱 [ADMOB] Dismissed: $purpose',
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
      onAdFailedToShowFullScreenContent: (
        RewardedAd ad,
        AdError error,
      ) {
        debugPrint(
          '❌ [ADMOB] Failed to show: '
          '$purpose | '
          'Code: ${error.code} | '
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
      '🐱 [ADMOB] Rewarded ad READY: $purpose',
    );
  }

  // ============================================================
  // 🔄 RELOAD AFTER DISMISS
  // ============================================================

  Future<void> _reloadAfterDismiss(
    String purpose,
  ) async {
    await Future<void>.delayed(
      const Duration(
        seconds: 3,
      ),
    );

    if (_disposed) {
      return;
    }

    final User? user = _auth.currentUser;

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
  // 🎁 REWARD CALLBACK
  // ============================================================

  void _handleRewardEarned(
    String purpose,
  ) {
    if (_disposed) {
      return;
    }

    if (purpose == miningStartPurpose) {
      if (_miningRewardCallbackStarted) {
        debugPrint(
          '⚠️ [ADMOB] Mining reward callback already running.',
        );

        return;
      }

      _miningRewardCallbackStarted = true;
    }

    if (purpose == powerBoostPurpose) {
      if (_powerBoostRewardCallbackStarted) {
        debugPrint(
          '⚠️ [ADMOB] Power boost reward callback already running.',
        );

        return;
      }

      _powerBoostRewardCallbackStarted = true;
    }

    debugPrint(
      '🐱 [ADMOB] Reward earned: $purpose',
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

      if (purpose == miningStartPurpose) {
        await onMiningStartReward?.call();
      } else if (purpose == powerBoostPurpose) {
        await onPowerBoostReward?.call();
      }
    } catch (error) {
      debugPrint(
        '❌ [ADMOB] Backend reward callback failed: '
        '$purpose | $error',
      );
    } finally {
      if (purpose == miningStartPurpose) {
        _miningRewardCallbackStarted = false;
      }

      if (purpose == powerBoostPurpose) {
        _powerBoostRewardCallbackStarted = false;
      }
    }
  }

  // ============================================================
  // ⛏️ SHOW MINING START AD
  // ============================================================

  Future<bool> showMiningStartAd() async {
    return _showRewardedAd(
      purpose: miningStartPurpose,
    );
  }

  // ============================================================
  // ⚡ SHOW POWER BOOST AD
  // ============================================================

  Future<bool> showPowerBoostAd() async {
    return _showRewardedAd(
      purpose: powerBoostPurpose,
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

    final User? user = _auth.currentUser;

    if (user == null) {
      debugPrint(
        '❌ [ADMOB] Cannot show ad: no authenticated user.',
      );

      return false;
    }

    // ----------------------------------------------------------
    // Prevent duplicate flows
    // ----------------------------------------------------------

    if (purpose == miningStartPurpose &&
        _miningAdFlowActive) {
      return false;
    }

    if (purpose == powerBoostPurpose &&
        _powerBoostAdFlowActive) {
      return false;
    }

    if (purpose == miningStartPurpose &&
        _powerBoostAdFlowActive) {
      return false;
    }

    if (purpose == powerBoostPurpose &&
        _miningAdFlowActive) {
      return false;
    }

    // ----------------------------------------------------------
    // Prevent duplicate backend callback
    // ----------------------------------------------------------

    if (purpose == miningStartPurpose &&
        _miningRewardCallbackStarted) {
      return false;
    }

    if (purpose == powerBoostPurpose &&
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
      debugPrint(
        '🐱 [ADMOB] Preparing rewarded ad: $purpose',
      );

      final bool ready =
          await waitForRewardedAd(
        purpose: purpose,
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
          '❌ [ADMOB] Cannot show ad because it is not ready: '
          '$purpose',
        );

        _setFlowActive(
          purpose,
          false,
        );

        _notify();

        return false;
      }

      ad = _rewardedAd;

      if (ad == null) {
        debugPrint(
          '❌ [ADMOB] RewardedAd became null before show: '
          '$purpose',
        );

        _setFlowActive(
          purpose,
          false,
        );

        _notify();

        return false;
      }

      // --------------------------------------------------------
      // Local variable now owns the ad until dismissal.
      // --------------------------------------------------------

      _clearAdState();

      _notify();

      bool rewardEarned = false;

      debugPrint(
        '🐱 [ADMOB] Showing rewarded ad: $purpose',
      );

      ad.show(
        onUserEarnedReward: (
          AdWithoutView adWithoutView,
          RewardItem reward,
        ) {
          if (rewardEarned) {
            return;
          }

          rewardEarned = true;

          debugPrint(
            '🐱 [ADMOB] User earned reward: '
            '$purpose | '
            '${reward.amount} '
            '${reward.type}',
          );

          _handleRewardEarned(
            purpose,
          );
        },
      );

      return true;
    } catch (error) {
      debugPrint(
        '❌ [ADMOB] Show exception: '
        '$purpose | $error',
      );

      ad?.dispose();

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
    if (purpose == miningStartPurpose) {
      _miningAdFlowActive = active;
    }

    if (purpose == powerBoostPurpose) {
      _powerBoostAdFlowActive = active;
    }
  }

  void _resetRewardCallbackState(
    String purpose,
  ) {
    if (purpose == miningStartPurpose) {
      _miningRewardCallbackStarted = false;
    }

    if (purpose == powerBoostPurpose) {
      _powerBoostRewardCallbackStarted = false;
    }
  }

  // ============================================================
  // 🧹 DISPOSE
  // ============================================================

  @override
  void dispose() {
    _disposed = true;

    _loadRequestId++;

    final RewardedAd? ad = _rewardedAd;

    _rewardedAd = null;

    ad?.dispose();

    super.dispose();
  }
}