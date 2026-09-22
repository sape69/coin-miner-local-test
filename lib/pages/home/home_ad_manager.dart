import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// ============================================================
// 🐱 STELLURIINI HOME AD MANAGER
// ============================================================
//
// STELLURIINI REWARDED ADS
//
// Flutter
//    ↓
// Google Mobile Ads SDK
//    ↓
// Rewarded Ad
//    ↓
// käyttäjä katsoo mainoksen
//    ↓
// Google AdMob SSV
//    ↓
// Stelluriinin Cloud Function
//    ↓
// Firestore admobRewards
//    ↓
// powerBoost / claimMining
//
// IMPORTANT:
//
// AdMob reward itself is NOT an STL token reward.
//
// AdMob authorizes:
// - Mining Start
// - Power Boost
//
// Backend SSV verification remains authoritative.
//
// ============================================================
//
// 📺 ADMOB-MAINOSYKSIKÖT
//
// Mining Start:
//
//   ca-app-pub-1131012057145658/6674097787
//
// Power Boost:
//
//   ca-app-pub-1131012057145658/7225738491
//
// ============================================================
//
// 🔐 SSV CUSTOM DATA
//
//   UID:mining_start
//   UID:power_boost
//
// ============================================================

class HomeAdManager extends ChangeNotifier {
  // ============================================================
  // 📺 MINING START REWARDED AD
  // ============================================================

  static const String miningRewardedAdUnitId =
      'ca-app-pub-1131012057145658/6674097787';

  // ============================================================
  // ⚡ POWER BOOST REWARDED AD
  // ============================================================

  static const String powerBoostRewardedAdUnitId =
      'ca-app-pub-1131012057145658/7225738491';

  // ============================================================
  // 🔐 SSV PURPOSES
  // ============================================================

  static const String powerBoostPurpose = 'power_boost';

  static const String miningStartPurpose = 'mining_start';

  // ============================================================
  // ⏳ SSV BACKEND PROPAGATION WAIT
  // ============================================================
  //
  // IMPORTANT:
  //
  // This is NOT SSV verification itself.
  //
  // The client cannot cryptographically verify Google's SSV
  // callback here.
  //
  // The delay simply gives the backend some time to receive
  // and process the verified AdMob SSV callback before the
  // HomePage callback calls claimMining/powerBoost.
  //
  // Backend verification remains authoritative.
  //
  // ============================================================

  static const Duration ssvGracePeriod = Duration(seconds: 8);

  // ============================================================
  // 👤 FIREBASE AUTH
  // ============================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================
  // 🔄 CALLBACKS
  // ============================================================

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
  // 📺 CURRENT AD
  // ============================================================

  RewardedAd? _rewardedAd;

  bool _adReady = false;

  bool _adLoading = false;

  String _rewardedAdPurpose = '';

  String _loadingPurpose = '';

  String _adLoadError = '';

  // ============================================================
  // 👤 USER WHO OWNS THE LOADED AD
  // ============================================================
  //
  // This prevents a loaded ad belonging to User A from being
  // used after Firebase Auth has switched to User B.
  //
  // ============================================================

  String _rewardedAdUid = '';

  String _loadingUid = '';

  // ============================================================
  // 🔒 FLOW STATE
  // ============================================================

  bool _miningAdFlowActive = false;

  bool _powerBoostAdFlowActive = false;

  // ============================================================
  // INTERNAL STATE
  // ============================================================

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
  });

  // ============================================================
  // PUBLIC GETTERS
  // ============================================================

  RewardedAd? get rewardedAd => _rewardedAd;

  bool get adReady => _adReady;

  bool get adLoading => _adLoading;

  String get rewardedAdPurpose => _rewardedAdPurpose;

  String get adLoadError => _adLoadError;

  bool get miningAdFlowActive => _miningAdFlowActive;

  bool get powerBoostAdFlowActive => _powerBoostAdFlowActive;

  // ============================================================
  // SAFE NOTIFY
  // ============================================================

  void _notify() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  // ============================================================
  // PURPOSE VALIDATION
  // ============================================================

  bool _isSupportedPurpose(String purpose) {
    return purpose == miningStartPurpose ||
        purpose == powerBoostPurpose;
  }

  // ============================================================
  // GET AD UNIT ID
  // ============================================================

  String _getAdUnitId(String purpose) {
    if (purpose == powerBoostPurpose) {
      return powerBoostRewardedAdUnitId;
    }

    return miningRewardedAdUnitId;
  }

  // ============================================================
  // GET CURRENT UID
  // ============================================================

  String? _currentUid() {
    return _auth.currentUser?.uid;
  }

  // ============================================================
  // WAIT FOR REWARDED AD
  // ============================================================

  Future<bool> waitForRewardedAd({
    required String purpose,
  }) async {
    if (_disposed) {
      return false;
    }

    if (!_isSupportedPurpose(purpose)) {
      debugPrint(
        '🐱 Unsupported Rewarded Ad purpose: $purpose',
      );

      return false;
    }

    final String? currentUid = _currentUid();

    if (currentUid == null) {
      debugPrint(
        '🐱 Cannot wait for Rewarded Ad: '
        'no authenticated Firebase user.',
      );

      return false;
    }

    // ----------------------------------------------------------
    // Already ready
    // ----------------------------------------------------------

    if (_rewardedAd != null &&
        _adReady &&
        _rewardedAdPurpose == purpose &&
        _rewardedAdUid == currentUid) {
      debugPrint(
        '🐱 Stelluriini Rewarded ad already ready: $purpose',
      );

      return true;
    }

    // ----------------------------------------------------------
    // Loaded ad belongs to another user
    // ----------------------------------------------------------

    if (_rewardedAd != null &&
        _rewardedAdUid.isNotEmpty &&
        _rewardedAdUid != currentUid) {
      debugPrint(
        '🐱 Loaded Rewarded ad belongs to another Firebase user. '
        'Discarding it.',
      );

      _disposeCurrentAd();
    }

    // ----------------------------------------------------------
    // Different purpose already loaded
    // ----------------------------------------------------------

    if (_rewardedAd != null &&
        _rewardedAdPurpose != purpose) {
      debugPrint(
        '🐱 Different Rewarded ad is loaded. '
        'Replacing it with: $purpose',
      );

      _disposeCurrentAd();
    }

    // ----------------------------------------------------------
    // Different purpose currently loading
    // ----------------------------------------------------------

    if (_adLoading && _loadingPurpose != purpose) {
      debugPrint(
        '🐱 Different Rewarded ad is currently loading. '
        'Switching to: $purpose',
      );

      _loadRequestId++;

      _adLoading = false;
      _loadingPurpose = '';
      _loadingUid = '';

      _rewardedAd = null;
      _adReady = false;
      _rewardedAdPurpose = '';
      _rewardedAdUid = '';

      _notify();
    }

    // ----------------------------------------------------------
    // Load if necessary
    // ----------------------------------------------------------

    if (!_adLoading) {
      await loadRewardedAd(
        purpose: purpose,
        notifyOnLoadError: true,
      );
    }

    // ----------------------------------------------------------
    // Wait for load/configuration
    // ----------------------------------------------------------

    const int maxWaitChecks = 150;

    const Duration checkInterval = Duration(
      milliseconds: 200,
    );

    for (
      int check = 0;
      check < maxWaitChecks;
      check++
    ) {
      if (_disposed) {
        return false;
      }

      final String? latestUid = _currentUid();

      if (latestUid == null ||
          latestUid != currentUid) {
        debugPrint(
          '🐱 Firebase user changed while waiting for Rewarded Ad.',
        );

        _disposeCurrentAd();

        return false;
      }

      if (_rewardedAd != null &&
          _adReady &&
          _rewardedAdPurpose == purpose &&
          _rewardedAdUid == currentUid) {
        debugPrint(
          '🐱 Stelluriini Rewarded ad became ready: $purpose',
        );

        return true;
      }

      if (_adLoading && _loadingPurpose != purpose) {
        debugPrint(
          '🐱 Rewarded ad loading purpose changed. '
          'Expected: $purpose '
          'Current: $_loadingPurpose',
        );

        return false;
      }

      if (!_adLoading) {
        break;
      }

      await Future<void>.delayed(
        checkInterval,
      );
    }

    final bool ready =
        !_disposed &&
        _rewardedAd != null &&
        _adReady &&
        _rewardedAdPurpose == purpose &&
        _rewardedAdUid == currentUid;

    debugPrint(
      '🐱 Stelluriini Rewarded ad wait finished. '
      'Purpose: $purpose '
      'Ready: $ready '
      'Last error: $_adLoadError',
    );

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

    if (!_isSupportedPurpose(purpose)) {
      _adLoadError =
          'INVALID_PURPOSE | '
          'Purpose: $purpose';

      debugPrint(
        '🐱 Cannot load Rewarded Ad: unsupported purpose $purpose',
      );

      _notify();

      return;
    }

    final User? user = _auth.currentUser;

    if (user == null) {
      debugPrint(
        '🐱 Cannot load Rewarded Ad: '
        'no authenticated Firebase user.',
      );

      _adLoading = false;
      _loadingPurpose = '';
      _loadingUid = '';

      _adReady = false;
      _adLoadError =
          'NO_AUTH_USER | '
          'Purpose: $purpose';

      _notify();

      return;
    }

    // ----------------------------------------------------------
    // Already ready for same user and purpose
    // ----------------------------------------------------------

    if (_rewardedAd != null &&
        _adReady &&
        _rewardedAdPurpose == purpose &&
        _rewardedAdUid == user.uid) {
      debugPrint(
        '🐱 Stelluriini Rewarded ad already ready: $purpose',
      );

      return;
    }

    // ----------------------------------------------------------
    // Existing ad belongs to another user
    // ----------------------------------------------------------

    if (_rewardedAd != null &&
        _rewardedAdUid.isNotEmpty &&
        _rewardedAdUid != user.uid) {
      debugPrint(
        '🐱 Discarding Rewarded ad belonging to another user.',
      );

      _disposeCurrentAd();
    }

    // ----------------------------------------------------------
    // Existing load
    // ----------------------------------------------------------

    if (_adLoading) {
      if (_loadingPurpose == purpose &&
          _loadingUid == user.uid) {
        debugPrint(
          '🐱 Rewarded ad loading already in progress: $purpose',
        );

        return;
      }

      debugPrint(
        '🐱 Replacing stale Rewarded ad load. '
        'Old purpose: $_loadingPurpose '
        'Old UID length: ${_loadingUid.length} '
        'New purpose: $purpose',
      );

      _loadRequestId++;

      _adLoading = false;
      _loadingPurpose = '';
      _loadingUid = '';
    }

    // ----------------------------------------------------------
    // Remove old ad
    // ----------------------------------------------------------

    if (_rewardedAd != null) {
      _disposeCurrentAd();
    }

    final int requestId = ++_loadRequestId;

    _adLoading = true;
    _loadingPurpose = purpose;
    _loadingUid = user.uid;

    _adReady = false;
    _adLoadError = '';

    _rewardedAdPurpose = '';
    _rewardedAdUid = '';

    _notify();

    final String adUnitId = _getAdUnitId(purpose);

    debugPrint(
      '==================================================',
    );

    debugPrint(
      '🐱 STELLURIINI ADMOB LOAD START',
    );

    debugPrint(
      'Purpose: $purpose',
    );

    debugPrint(
      'Ad Unit ID: $adUnitId',
    );

    debugPrint(
      'User UID length: ${user.uid.length}',
    );

    debugPrint(
      'Notify load error: $notifyOnLoadError',
    );

    debugPrint(
      '==================================================',
    );

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          unawaited(
            _prepareLoadedAd(
              ad: ad,
              purpose: purpose,
              adUnitId: adUnitId,
              userUid: user.uid,
              requestId: requestId,
              notifyOnLoadError: notifyOnLoadError,
            ),
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          if (_disposed) {
            return;
          }

          if (requestId != _loadRequestId) {
            return;
          }

          final String detailedError =
              'LOAD_FAILED | '
              'Purpose: $purpose | '
              'Ad Unit ID: $adUnitId | '
              'Code: ${error.code} | '
              'Domain: ${error.domain} | '
              'Message: ${error.message}';

          debugPrint(
            '==================================================',
          );

          debugPrint(
            '🐱 STELLURIINI ADMOB LOAD FAILED',
          );

          debugPrint(
            'Purpose: $purpose',
          );

          debugPrint(
            'Ad Unit ID: $adUnitId',
          );

          debugPrint(
            'Code: ${error.code}',
          );

          debugPrint(
            'Domain: ${error.domain}',
          );

          debugPrint(
            'Message: ${error.message}',
          );

          debugPrint(
            'FULL ERROR: $detailedError',
          );

          debugPrint(
            'Notify user: $notifyOnLoadError',
          );

          debugPrint(
            '==================================================',
          );

          _rewardedAd = null;
          _adReady = false;
          _adLoading = false;

          _loadingPurpose = '';
          _loadingUid = '';

          _rewardedAdPurpose = '';
          _rewardedAdUid = '';

          _adLoadError = detailedError;

          _notify();

          if (notifyOnLoadError) {
            onAdLoadError?.call(
              purpose,
              error,
            );
          } else {
            debugPrint(
              '🐱 Silent background ad load failure. '
              'No user notification.',
            );
          }
        },
      ),
    );
  }

  // ============================================================
  // 🔐 PREPARE LOADED AD
  // ============================================================
  //
  // IMPORTANT:
  //
  // setServerSideOptions() is asynchronous.
  //
  // We wait for it to complete before the ad becomes ready.
  //
  // This guarantees that the SSV custom data is configured
  // before HomeAdManager allows the ad to be shown.
  //
  // ============================================================

  Future<void> _prepareLoadedAd({
    required RewardedAd ad,
    required String purpose,
    required String adUnitId,
    required String userUid,
    required int requestId,
    required bool notifyOnLoadError,
  }) async {
    if (_disposed) {
      unawaited(ad.dispose());
      return;
    }

    if (requestId != _loadRequestId) {
      debugPrint(
        '🐱 Ignoring stale rewarded ad callback.',
      );

      unawaited(ad.dispose());

      return;
    }

    final User? currentUser = _auth.currentUser;

    if (currentUser == null ||
        currentUser.uid != userUid) {
      debugPrint(
        '🐱 Firebase user changed before SSV configuration.',
      );

      unawaited(ad.dispose());

      if (requestId == _loadRequestId) {
        _adLoading = false;
        _loadingPurpose = '';
        _loadingUid = '';

        _rewardedAd = null;
        _adReady = false;
        _rewardedAdPurpose = '';
        _rewardedAdUid = '';

        _adLoadError =
            'AUTH_CHANGED_BEFORE_SSV_SETUP | '
            'Purpose: $purpose';

        _notify();
      }

      return;
    }

    debugPrint(
      '==================================================',
    );

    debugPrint(
      '🐱 STELLURIINI ADMOB LOAD SUCCESS',
    );

    debugPrint(
      'Purpose: $purpose',
    );

    debugPrint(
      'Ad Unit ID: $adUnitId',
    );

    debugPrint(
      '==================================================',
    );

    try {
      final ServerSideVerificationOptions
          serverSideOptions =
          ServerSideVerificationOptions(
        customData: '$userUid:$purpose',
      );

      await ad.setServerSideOptions(
        serverSideOptions,
      );

      debugPrint(
        '🐱 STELLURIINI SSV CUSTOM DATA SET',
      );

      debugPrint(
        'Purpose: $purpose',
      );

      debugPrint(
        'Custom data format: UID:$purpose',
      );
    } catch (error) {
      debugPrint(
        '🐱 AdMob SSV setup failed: $error',
      );

      unawaited(ad.dispose());

      if (requestId != _loadRequestId ||
          _disposed) {
        return;
      }

      _rewardedAd = null;
      _adReady = false;

      _adLoading = false;

      _loadingPurpose = '';
      _loadingUid = '';

      _rewardedAdPurpose = '';
      _rewardedAdUid = '';

      _adLoadError =
          'SSV_SETUP_FAILED | '
          'Purpose: $purpose | '
          'Ad Unit ID: $adUnitId | '
          'Error: $error';

      _notify();

      if (notifyOnLoadError) {
        debugPrint(
          '🐱 SSV setup failure is reported to HomePage.',
        );
      }

      return;
    }

    // ----------------------------------------------------------
    // Verify request is still current after async SSV setup
    // ----------------------------------------------------------

    if (_disposed ||
        requestId != _loadRequestId) {
      debugPrint(
        '🐱 Rewarded ad became stale while configuring SSV.',
      );

      unawaited(ad.dispose());

      return;
    }

    final User? latestUser = _auth.currentUser;

    if (latestUser == null ||
        latestUser.uid != userUid) {
      debugPrint(
        '🐱 Firebase user changed during SSV configuration.',
      );

      unawaited(ad.dispose());

      _adLoading = false;
      _loadingPurpose = '';
      _loadingUid = '';

      _rewardedAd = null;
      _adReady = false;

      _rewardedAdPurpose = '';
      _rewardedAdUid = '';

      _adLoadError =
          'AUTH_CHANGED_DURING_SSV_SETUP | '
          'Purpose: $purpose';

      _notify();

      return;
    }

    // ----------------------------------------------------------
    // Store the fully prepared ad
    // ----------------------------------------------------------

    _rewardedAd = ad;

    _rewardedAdPurpose = purpose;

    _rewardedAdUid = userUid;

    _adReady = true;

    _adLoading = false;

    _loadingPurpose = '';

    _loadingUid = '';

    _adLoadError = '';

    // ----------------------------------------------------------
    // Fullscreen callbacks
    // ----------------------------------------------------------

    ad.fullScreenContentCallback =
        FullScreenContentCallback<RewardedAd>(
      onAdShowedFullScreenContent: (
        RewardedAd showedAd,
      ) {
        debugPrint(
          '==================================================',
        );

        debugPrint(
          '🐱 STELLURIINI ADMOB SHOWN',
        );

        debugPrint(
          'Purpose: $purpose',
        );

        debugPrint(
          'Ad Unit ID: $adUnitId',
        );

        debugPrint(
          '==================================================',
        );
      },
      onAdImpression: (
        RewardedAd impressionAd,
      ) {
        debugPrint(
          '🐱 STELLURIINI ADMOB IMPRESSION',
        );

        debugPrint(
          'Purpose: $purpose',
        );

        debugPrint(
          'Ad Unit ID: $adUnitId',
        );
      },
      onAdClicked: (
        RewardedAd clickedAd,
      ) {
        debugPrint(
          '🐱 STELLURIINI ADMOB CLICKED',
        );

        debugPrint(
          'Purpose: $purpose',
        );

        debugPrint(
          'Ad Unit ID: $adUnitId',
        );
      },
      onAdDismissedFullScreenContent: (
        RewardedAd dismissedAd,
      ) {
        debugPrint(
          '==================================================',
        );

        debugPrint(
          '🐱 STELLURIINI ADMOB DISMISSED',
        );

        debugPrint(
          'Purpose: $purpose',
        );

        debugPrint(
          'Ad Unit ID: $adUnitId',
        );

        debugPrint(
          '==================================================',
        );

        unawaited(
          dismissedAd.dispose(),
        );

        if (identical(
          _rewardedAd,
          dismissedAd,
        )) {
          _rewardedAd = null;
          _adReady = false;

          _rewardedAdPurpose = '';
          _rewardedAdUid = '';
        }

        _finishFlow(purpose);

        _notify();

        onAdDismissed?.call(purpose);

        if (!_disposed) {
          unawaited(
            _reloadAfterDismiss(purpose),
          );
        }
      },
      onAdFailedToShowFullScreenContent: (
        RewardedAd failedAd,
        AdError error,
      ) {
        debugPrint(
          '==================================================',
        );

        debugPrint(
          '🐱 STELLURIINI ADMOB SHOW FAILED',
        );

        debugPrint(
          'Purpose: $purpose',
        );

        debugPrint(
          'Ad Unit ID: $adUnitId',
        );

        debugPrint(
          'Code: ${error.code}',
        );

        debugPrint(
          'Domain: ${error.domain}',
        );

        debugPrint(
          'Message: ${error.message}',
        );

        debugPrint(
          '==================================================',
        );

        unawaited(
          failedAd.dispose(),
        );

        if (identical(
          _rewardedAd,
          failedAd,
        )) {
          _rewardedAd = null;
          _adReady = false;

          _rewardedAdPurpose = '';
          _rewardedAdUid = '';
        }

        _finishFlow(purpose);

        _adLoadError =
            'SHOW_FAILED | '
            'Purpose: $purpose | '
            'Ad Unit ID: $adUnitId | '
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
            _reloadAfterDismiss(purpose),
          );
        }
      },
    );

    debugPrint(
      '🐱 Stelluriini Rewarded ad is READY.',
    );

    debugPrint(
      'Purpose: $purpose',
    );

    debugPrint(
      'User UID length: ${userUid.length}',
    );

    _notify();
  }

  // ============================================================
  // 🔄 RELOAD AFTER DISMISS
  // ============================================================

  Future<void> _reloadAfterDismiss(
    String purpose,
  ) async {
    if (_disposed) {
      return;
    }

    await Future<void>.delayed(
      const Duration(seconds: 5),
    );

    if (_disposed) {
      return;
    }

    if (_rewardedAd != null &&
        _adReady) {
      return;
    }

    if (_adLoading) {
      return;
    }

    if (_auth.currentUser == null) {
      return;
    }

    debugPrint(
      '🐱 Starting silent background AdMob reload: $purpose',
    );

    await loadRewardedAd(
      purpose: purpose,
      notifyOnLoadError: false,
    );
  }

  // ============================================================
  // 🛡️ SCHEDULE BACKEND REWARD CALLBACK
  // ============================================================
  //
  // IMPORTANT:
  //
  // This does NOT verify SSV on the device.
  //
  // It waits briefly for Google's verified SSV callback to reach
  // the backend.
  //
  // The callback passed from HomePage must still call the backend
  // function that validates/consumes the verified reward.
  //
  // ============================================================

  void _scheduleBackendRewardCallback({
    required String purpose,
    required String expectedUid,
  }) {
    unawaited(
      () async {
        debugPrint(
          '==================================================',
        );

        debugPrint(
          '🐱 STELLURIINI SSV BACKEND WAIT START',
        );

        debugPrint(
          'Purpose: $purpose',
        );

        debugPrint(
          'Waiting: ${ssvGracePeriod.inSeconds} seconds',
        );

        debugPrint(
          'Expected UID length: ${expectedUid.length}',
        );

        debugPrint(
          '==================================================',
        );

        await Future<void>.delayed(
          ssvGracePeriod,
        );

        if (_disposed) {
          debugPrint(
            '🐱 Backend reward callback cancelled: '
            'manager disposed.',
          );

          return;
        }

        final User? currentUser = _auth.currentUser;

        if (currentUser == null) {
          debugPrint(
            '🐱 Backend reward callback cancelled: '
            'no authenticated user.',
          );

          return;
        }

        if (currentUser.uid != expectedUid) {
          debugPrint(
            '🐱 Backend reward callback cancelled: '
            'Firebase user changed.',
          );

          return;
        }

        debugPrint(
          '==================================================',
        );

        debugPrint(
          '🐱 STELLURIINI SSV BACKEND WAIT COMPLETE',
        );

        debugPrint(
          'Purpose: $purpose',
        );

        debugPrint(
          'Calling Firebase reward callback now.',
        );

        debugPrint(
          '==================================================',
        );

        try {
          if (purpose == miningStartPurpose) {
            await onMiningStartReward?.call();
          } else if (purpose == powerBoostPurpose) {
            await onPowerBoostReward?.call();
          } else {
            debugPrint(
              '🐱 Unknown reward callback purpose: $purpose',
            );

            return;
          }

          debugPrint(
            '🐱 Firebase reward callback completed: $purpose',
          );
        } catch (error) {
          debugPrint(
            '🐱 Firebase reward callback failed: $purpose',
          );

          debugPrint(
            '🐱 Error: $error',
          );
        }
      }(),
    );
  }

  // ============================================================
  // ⛏️ SHOW MINING START AD
  // ============================================================

  Future<bool> showMiningStartAd() async {
    if (_disposed) {
      return false;
    }

    if (_miningAdFlowActive) {
      debugPrint(
        '🐱 Mining Start ad flow already active.',
      );

      return false;
    }

    if (_powerBoostAdFlowActive) {
      debugPrint(
        '🐱 Power Boost ad flow is active.',
      );

      return false;
    }

    final User? user = _auth.currentUser;

    if (user == null) {
      debugPrint(
        '🐱 Cannot show Mining Start ad: '
        'no authenticated Firebase user.',
      );

      return false;
    }

    _miningAdFlowActive = true;
    _adLoadError = '';

    _notify();

    try {
      final bool ready = await waitForRewardedAd(
        purpose: miningStartPurpose,
      );

      if (_disposed) {
        _miningAdFlowActive = false;
        return false;
      }

      final User? currentUser = _auth.currentUser;

      if (currentUser == null ||
          currentUser.uid != user.uid) {
        debugPrint(
          '🐱 Mining Start ad cancelled: Firebase user changed.',
        );

        _miningAdFlowActive = false;

        _disposeCurrentAd();

        _notify();

        return false;
      }

      if (!ready ||
          _rewardedAd == null ||
          !_adReady ||
          _rewardedAdPurpose != miningStartPurpose ||
          _rewardedAdUid != user.uid) {
        _miningAdFlowActive = false;

        debugPrint(
          '🐱 Mining Start ad was not ready.',
        );

        debugPrint(
          'Last AdMob error: $_adLoadError',
        );

        _notify();

        return false;
      }

      final RewardedAd ad = _rewardedAd!;

      final String adUid = _rewardedAdUid;

      if (ad.adUnitId != miningRewardedAdUnitId) {
        debugPrint(
          '🐱 Mining Start ad unit mismatch. '
          'Expected: $miningRewardedAdUnitId '
          'Actual: ${ad.adUnitId}',
        );

        _miningAdFlowActive = false;

        _disposeCurrentAd();

        _adLoadError =
            'AD_UNIT_MISMATCH | '
            'Purpose: $miningStartPurpose';

        _notify();

        return false;
      }

      _rewardedAd = null;
      _adReady = false;

      _rewardedAdPurpose = '';
      _rewardedAdUid = '';

      _notify();

      bool rewardEarned = false;

      debugPrint(
        '==================================================',
      );

      debugPrint(
        '🐱 STELLURIINI SHOW MINING START AD',
      );

      debugPrint(
        'Ad Unit ID: $miningRewardedAdUnitId',
      );

      debugPrint(
        'SSV Purpose: $miningStartPurpose',
      );

      debugPrint(
        'SSV Custom Data: $adUid:$miningStartPurpose',
      );

      debugPrint(
        '==================================================',
      );

      ad.show(
        onUserEarnedReward: (
          AdWithoutView adWithoutView,
          RewardItem reward,
        ) {
          if (rewardEarned) {
            debugPrint(
              '🐱 Mining Start reward callback already received.',
            );

            return;
          }

          rewardEarned = true;

          debugPrint(
            '==================================================',
          );

          debugPrint(
            '🐱 STELLURIINI MINING START REWARD RECEIVED',
          );

          debugPrint(
            'Reward amount: ${reward.amount}',
          );

          debugPrint(
            'Reward type: ${reward.type}',
          );

          debugPrint(
            'IMPORTANT: Firebase callback is delayed '
            'for backend SSV propagation.',
          );

          debugPrint(
            '==================================================',
          );

          _scheduleBackendRewardCallback(
            purpose: miningStartPurpose,
            expectedUid: adUid,
          );
        },
      );

      return true;
    } catch (error) {
      debugPrint(
        '🐱 Mining Start ad flow error: $error',
      );

      _miningAdFlowActive = false;

      _notify();

      return false;
    }
  }

  // ============================================================
  // ⚡ SHOW POWER BOOST AD
  // ============================================================

  Future<bool> showPowerBoostAd() async {
    if (_disposed) {
      return false;
    }

    if (_powerBoostAdFlowActive) {
      debugPrint(
        '🐱 Power Boost ad flow already active.',
      );

      return false;
    }

    if (_miningAdFlowActive) {
      debugPrint(
        '🐱 Mining Start ad flow is active.',
      );

      return false;
    }

    final User? user = _auth.currentUser;

    if (user == null) {
      debugPrint(
        '🐱 Cannot show Power Boost ad: '
        'no authenticated Firebase user.',
      );

      return false;
    }

    _powerBoostAdFlowActive = true;
    _adLoadError = '';

    _notify();

    try {
      if (_rewardedAd != null &&
          _rewardedAdPurpose != powerBoostPurpose) {
        _disposeCurrentAd();
      }

      if (_adLoading &&
          _loadingPurpose != powerBoostPurpose) {
        debugPrint(
          '🐱 Switching active ad load to Power Boost.',
        );

        _loadRequestId++;

        _adLoading = false;
        _loadingPurpose = '';
        _loadingUid = '';
      }

      final bool ready = await waitForRewardedAd(
        purpose: powerBoostPurpose,
      );

      if (_disposed) {
        _powerBoostAdFlowActive = false;
        return false;
      }

      final User? currentUser = _auth.currentUser;

      if (currentUser == null ||
          currentUser.uid != user.uid) {
        debugPrint(
          '🐱 Power Boost ad cancelled: Firebase user changed.',
        );

        _powerBoostAdFlowActive = false;

        _disposeCurrentAd();

        _notify();

        return false;
      }

      if (!ready ||
          _rewardedAd == null ||
          !_adReady ||
          _rewardedAdPurpose != powerBoostPurpose ||
          _rewardedAdUid != user.uid) {
        _powerBoostAdFlowActive = false;

        debugPrint(
          '🐱 Power Boost ad was not ready.',
        );

        debugPrint(
          'Last AdMob error: $_adLoadError',
        );

        _notify();

        return false;
      }

      final RewardedAd ad = _rewardedAd!;

      final String adUid = _rewardedAdUid;

      if (ad.adUnitId != powerBoostRewardedAdUnitId) {
        debugPrint(
          '🐱 Power Boost ad unit mismatch. '
          'Expected: $powerBoostRewardedAdUnitId '
          'Actual: ${ad.adUnitId}',
        );

        _powerBoostAdFlowActive = false;

        _disposeCurrentAd();

        _adLoadError =
            'AD_UNIT_MISMATCH | '
            'Purpose: $powerBoostPurpose';

        _notify();

        return false;
      }

      _rewardedAd = null;
      _adReady = false;

      _rewardedAdPurpose = '';
      _rewardedAdUid = '';

      _notify();

      bool rewardEarned = false;

      debugPrint(
        '==================================================',
      );

      debugPrint(
        '🐱 STELLURIINI SHOW POWER BOOST AD',
      );

      debugPrint(
        'Ad Unit ID: $powerBoostRewardedAdUnitId',
      );

      debugPrint(
        'SSV Purpose: $powerBoostPurpose',
      );

      debugPrint(
        'SSV Custom Data: $adUid:$powerBoostPurpose',
      );

      debugPrint(
        '==================================================',
      );

      ad.show(
        onUserEarnedReward: (
          AdWithoutView adWithoutView,
          RewardItem reward,
        ) {
          if (rewardEarned) {
            debugPrint(
              '🐱 Power Boost reward callback already received.',
            );

            return;
          }

          rewardEarned = true;

          debugPrint(
            '==================================================',
          );

          debugPrint(
            '🐱 STELLURIINI POWER BOOST REWARD RECEIVED',
          );

          debugPrint(
            'Reward amount: ${reward.amount}',
          );

          debugPrint(
            'Reward type: ${reward.type}',
          );

          debugPrint(
            'IMPORTANT: Firebase callback is delayed '
            'for backend SSV propagation.',
          );

          debugPrint(
            '==================================================',
          );

          _scheduleBackendRewardCallback(
            purpose: powerBoostPurpose,
            expectedUid: adUid,
          );
        },
      );

      return true;
    } catch (error) {
      debugPrint(
        '🐱 Power Boost ad flow error: $error',
      );

      _powerBoostAdFlowActive = false;

      _notify();

      return false;
    }
  }

  // ============================================================
  // FINISH FLOW
  // ============================================================

  void _finishFlow(String purpose) {
    if (purpose == miningStartPurpose) {
      _miningAdFlowActive = false;
    }

    if (purpose == powerBoostPurpose) {
      _powerBoostAdFlowActive = false;
    }
  }

  // ============================================================
  // DISPOSE CURRENT AD
  // ============================================================

  void _disposeCurrentAd() {
    final RewardedAd? ad = _rewardedAd;

    _rewardedAd = null;

    _adReady = false;

    _rewardedAdPurpose = '';

    _rewardedAdUid = '';

    if (ad != null) {
      unawaited(
        ad.dispose(),
      );
    }
  }

  // ============================================================
  // CLEAR CURRENT AD
  // ============================================================

  void clearCurrentAd() {
    _loadRequestId++;

    _disposeCurrentAd();

    _adLoading = false;

    _loadingPurpose = '';

    _loadingUid = '';

    _adLoadError = '';

    _rewardedAdPurpose = '';

    _rewardedAdUid = '';

    _notify();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _disposed = true;

    _loadRequestId++;

    final RewardedAd? ad = _rewardedAd;

    _rewardedAd = null;

    _adReady = false;

    _adLoading = false;

    _loadingPurpose = '';

    _loadingUid = '';

    _rewardedAdPurpose = '';

    _rewardedAdUid = '';

    if (ad != null) {
      unawaited(
        ad.dispose(),
      );
    }

    super.dispose();
  }
}