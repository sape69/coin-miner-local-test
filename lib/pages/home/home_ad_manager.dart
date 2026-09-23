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
  // 🔥 FIREBASE
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
  });

  // ============================================================
  // GETTERS
  // ============================================================

  RewardedAd? get rewardedAd => _rewardedAd;

  bool get adReady => _adReady;

  bool get adLoading => _adLoading;

  String get rewardedAdPurpose => _rewardedAdPurpose;

  String get adLoadError => _adLoadError;

  bool get miningAdFlowActive => _miningAdFlowActive;

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

  void _clearAdState({
    bool clearError = false,
  }) {
    _rewardedAd = null;
    _adReady = false;
    _rewardedAdPurpose = '';
    _rewardedAdUserUid = '';

    if (clearError) {
      _adLoadError = '';
    }
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
      return false;
    }

    if (_isReadyFor(
      purpose,
      user.uid,
    )) {
      return true;
    }

    if (_rewardedAd != null &&
        !_isReadyFor(
          purpose,
          user.uid,
        )) {
      _disposeCurrentAd();
    }

    if (_adLoading &&
        _loadingPurpose != purpose) {
      _loadRequestId++;
      _adLoading = false;
      _loadingPurpose = '';
    }

    if (!_adLoading) {
      await loadRewardedAd(
        purpose: purpose,
        notifyOnLoadError: true,
      );
    }

    const int maxChecks = 150;
    const Duration interval =
        Duration(milliseconds: 200);

    for (
      int i = 0;
      i < maxChecks;
      i++
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
        return true;
      }

      if (_adLoading &&
          _loadingPurpose != purpose) {
        return false;
      }

      if (!_adLoading) {
        break;
      }

      await Future<void>.delayed(
        interval,
      );
    }

    final User? finalUser =
        _auth.currentUser;

    return !_disposed &&
        finalUser != null &&
        _isReadyFor(
          purpose,
          finalUser.uid,
        );
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
      return;
    }

    if (_adLoading) {
      if (_loadingPurpose == purpose) {
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
        _getAdUnitId(purpose);

    _adLoading = true;
    _loadingPurpose = purpose;
    _adReady = false;
    _adLoadError = '';
    _rewardedAdPurpose = '';
    _rewardedAdUserUid = '';

    _notify();

    debugPrint(
      '🐱 Loading AdMob rewarded ad: $purpose',
    );

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (
          RewardedAd ad,
        ) async {
          if (_disposed) {
            ad.dispose();
            return;
          }

          if (requestId != _loadRequestId) {
            ad.dispose();
            return;
          }

          final User? activeUser =
              _auth.currentUser;

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

          try {
            await ad.setServerSideOptions(
              ServerSideVerificationOptions(
                customData:
                    '$loadingUid:$purpose',
              ),
            );
          } catch (error) {
            ad.dispose();

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
              requestId != _loadRequestId) {
            ad.dispose();
            return;
          }

          final User? verifiedUser =
              _auth.currentUser;

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

          _rewardedAd = ad;
          _rewardedAdPurpose = purpose;
          _rewardedAdUserUid = loadingUid;
          _adReady = true;
          _adLoading = false;
          _loadingPurpose = '';
          _adLoadError = '';

          ad.fullScreenContentCallback =
              FullScreenContentCallback<RewardedAd>(
            onAdShowedFullScreenContent: (
              RewardedAd ad,
            ) {
              debugPrint(
                '🐱 AdMob shown: $purpose',
              );
            },
            onAdImpression: (
              RewardedAd ad,
            ) {
              debugPrint(
                '🐱 AdMob impression: $purpose',
              );
            },
            onAdClicked: (
              RewardedAd ad,
            ) {
              debugPrint(
                '🐱 AdMob clicked: $purpose',
              );
            },
            onAdDismissedFullScreenContent: (
              RewardedAd ad,
            ) {
              ad.dispose();

              _finishFlow(purpose);
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
              ad.dispose();

              _finishFlow(purpose);

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
            '🐱 AdMob rewarded ad ready: $purpose',
          );
        },
        onAdFailedToLoad: (
          LoadAdError error,
        ) {
          if (_disposed ||
              requestId != _loadRequestId) {
            return;
          }

          _rewardedAd = null;
          _adReady = false;
          _adLoading = false;
          _loadingPurpose = '';
          _rewardedAdPurpose = '';
          _rewardedAdUserUid = '';

          _adLoadError =
              'LOAD_FAILED | '
              'Purpose: $purpose | '
              'Code: ${error.code} | '
              'Domain: ${error.domain} | '
              'Message: ${error.message}';

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
  // 🔄 RELOAD AFTER DISMISS
  // ============================================================

  Future<void> _reloadAfterDismiss(
    String purpose,
  ) async {
    await Future<void>.delayed(
      const Duration(seconds: 5),
    );

    if (_disposed) {
      return;
    }

    final User? user =
        _auth.currentUser;

    if (user == null) {
      return;
    }

    if (_isReadyFor(
      purpose,
      user.uid,
    )) {
      return;
    }

    if (_adLoading) {
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

  void _handleRewardEarned({
    required String purpose,
  }) {
    if (_disposed) {
      return;
    }

    if (purpose == miningStartPurpose) {
      if (_miningRewardCallbackStarted) {
        return;
      }

      _miningRewardCallbackStarted = true;
    }

    if (purpose == powerBoostPurpose) {
      if (_powerBoostRewardCallbackStarted) {
        return;
      }

      _powerBoostRewardCallbackStarted = true;
    }

    debugPrint(
      '🐱 AdMob reward received: $purpose',
    );

    unawaited(
      _executeRewardCallback(
        purpose: purpose,
      ),
    );
  }

  // ============================================================
  // 🔐 BACKEND CALLBACK
  // ============================================================

  Future<void> _executeRewardCallback({
    required String purpose,
  }) async {
    try {
      if (purpose == miningStartPurpose) {
        await onMiningStartReward?.call();
      } else if (purpose == powerBoostPurpose) {
        await onPowerBoostReward?.call();
      }
    } catch (error) {
      debugPrint(
        '🐱 Backend reward callback failed: '
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

    final User? user =
        _auth.currentUser;

    if (user == null) {
      return false;
    }

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

    _setFlowActive(
      purpose,
      true,
    );

    _resetRewardCallbackState(
      purpose,
    );

    _adLoadError = '';

    _notify();

    try {
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
        _setFlowActive(
          purpose,
          false,
        );

        _notify();

        return false;
      }

      final RewardedAd ad =
          _rewardedAd!;

      _clearAdState();

      _notify();

      bool rewardEarned = false;

      debugPrint(
        '🐱 Showing rewarded ad: $purpose',
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
            '🐱 Reward callback: '
            '$purpose | '
            '${reward.amount} ${reward.type}',
          );

          _handleRewardEarned(
            purpose: purpose,
          );
        },
      );

      return true;
    } catch (error) {
      debugPrint(
        '🐱 Rewarded ad show error: '
        '$purpose | $error',
      );

      _setFlowActive(
        purpose,
        false,
      );

      _notify();

      return false;
    }
  }

  // ============================================================
  // 🔄 FLOW STATE
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

  void _finishFlow(
    String purpose,
  ) {
    _setFlowActive(
      purpose,
      false,
    );
  }

  // ============================================================
  // 🎁 REWARD CALLBACK STATE
  // ============================================================

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
  // 🧹 CLEAR
  // ============================================================

  void clearCurrentAd() {
    _loadRequestId++;

    _disposeCurrentAd();

    _adLoading = false;
    _loadingPurpose = '';
    _adLoadError = '';

    _miningRewardCallbackStarted = false;
    _powerBoostRewardCallbackStarted = false;

    _notify();
  }

  // ============================================================
  // 🗑️ DISPOSE
  // ============================================================

  @override
  void dispose() {
    _disposed = true;

    _loadRequestId++;

    _rewardedAd?.dispose();

    _rewardedAd = null;

    _adLoading = false;
    _loadingPurpose = '';
    _rewardedAdPurpose = '';
    _rewardedAdUserUid = '';

    _miningAdFlowActive = false;
    _powerBoostAdFlowActive = false;

    _miningRewardCallbackStarted = false;
    _powerBoostRewardCallbackStarted = false;

    super.dispose();
  }
}