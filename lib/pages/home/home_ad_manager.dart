import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// ============================================================
// 🐱 STELLURIINI HOME AD MANAGER
// ============================================================
//
// Hallitsee HomePagen Rewarded-mainoksia.
//
// Käyttötarkoitukset:
//
//   ⛏️ mining_start
//   ⚡ power_boost
//
// Mining ja Power Boost käyttävät erillisiä RewardedAd-
// instansseja ja erillisiä AdMob Ad Unit ID:itä.
//
// ============================================================

class HomeAdManager extends ChangeNotifier {
  // ============================================================
  // ⛏️ MINING ADMOB
  // ============================================================

  static const String miningRewardedAdUnitId =
      'ca-app-pub-1131012057145658/6674097787';

  // ============================================================
  // ⚡ POWER BOOST ADMOB
  // ============================================================

  static const String powerBoostRewardedAdUnitId =
      'ca-app-pub-1131012057145658/7225738491';

  // ============================================================
  // 🔐 SSV PURPOSES
  // ============================================================

  static const String powerBoostPurpose =
      'power_boost';

  static const String miningStartPurpose =
      'mining_start';

  // ============================================================
  // 👤 FIREBASE AUTH
  // ============================================================

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

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
  // ⛏️ MINING REWARDED AD
  // ============================================================

  RewardedAd? _miningRewardedAd;

  bool _miningAdReady = false;

  bool _miningAdLoading = false;

  String _miningAdLoadError = '';

  // ============================================================
  // ⚡ POWER BOOST REWARDED AD
  // ============================================================

  RewardedAd? _powerBoostRewardedAd;

  bool _powerBoostAdReady = false;

  bool _powerBoostAdLoading = false;

  String _powerBoostAdLoadError = '';

  // ============================================================
  // 🔒 FLOW STATE
  // ============================================================

  bool _miningAdFlowActive = false;

  bool _powerBoostAdFlowActive = false;

  // ============================================================
  // INTERNAL STATE
  // ============================================================

  bool _disposed = false;

  int _miningLoadRequestId = 0;

  int _powerBoostLoadRequestId = 0;

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

  // ------------------------------------------------------------
  // ⛏️ MINING
  // ------------------------------------------------------------

  RewardedAd? get miningRewardedAd =>
      _miningRewardedAd;

  bool get miningAdReady =>
      _miningAdReady;

  bool get miningAdLoading =>
      _miningAdLoading;

  String get miningAdLoadError =>
      _miningAdLoadError;

  // ------------------------------------------------------------
  // ⚡ POWER BOOST
  // ------------------------------------------------------------

  RewardedAd? get powerBoostRewardedAd =>
      _powerBoostRewardedAd;

  bool get powerBoostAdReady =>
      _powerBoostAdReady;

  bool get powerBoostAdLoading =>
      _powerBoostAdLoading;

  String get powerBoostAdLoadError =>
      _powerBoostAdLoadError;

  // ------------------------------------------------------------
  // 🔒 FLOW STATE
  // ------------------------------------------------------------

  bool get miningAdFlowActive =>
      _miningAdFlowActive;

  bool get powerBoostAdFlowActive =>
      _powerBoostAdFlowActive;

  // ------------------------------------------------------------
  // GENERAL GETTERS
  // ------------------------------------------------------------

  RewardedAd? get rewardedAd {
    if (_miningAdFlowActive) {
      return _miningRewardedAd;
    }

    if (_powerBoostAdFlowActive) {
      return _powerBoostRewardedAd;
    }

    if (_miningAdReady) {
      return _miningRewardedAd;
    }

    return _powerBoostRewardedAd;
  }

  bool get adReady =>
      _miningAdReady ||
      _powerBoostAdReady;

  bool get adLoading =>
      _miningAdLoading ||
      _powerBoostAdLoading;

  String get rewardedAdPurpose {
    if (_miningAdFlowActive ||
        _miningAdReady ||
        _miningAdLoading) {
      return miningStartPurpose;
    }

    if (_powerBoostAdFlowActive ||
        _powerBoostAdReady ||
        _powerBoostAdLoading) {
      return powerBoostPurpose;
    }

    return powerBoostPurpose;
  }

  String get adLoadError {
    if (_miningAdFlowActive ||
        _miningAdReady ||
        _miningAdLoading) {
      return _miningAdLoadError;
    }

    if (_powerBoostAdFlowActive ||
        _powerBoostAdReady ||
        _powerBoostAdLoading) {
      return _powerBoostAdLoadError;
    }

    return '';
  }

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
  // ⏳ WAIT FOR REWARDED AD
  // ============================================================

  Future<bool> waitForRewardedAd({
    required String purpose,
  }) async {
    if (_disposed) {
      return false;
    }

    // ==========================================================
    // ⛏️ MINING
    // ==========================================================

    if (purpose == miningStartPurpose) {
      if (_miningRewardedAd != null &&
          _miningAdReady) {
        debugPrint(
          'Mining rewarded ad already ready.',
        );

        return true;
      }

      if (!_miningAdLoading) {
        await loadRewardedAd(
          purpose: purpose,
        );
      }

      const int maxWaitChecks = 150;

      const Duration checkInterval =
          Duration(
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

        if (_miningRewardedAd != null &&
            _miningAdReady) {
          debugPrint(
            'Mining rewarded ad became ready.',
          );

          return true;
        }

        if (!_miningAdLoading) {
          break;
        }

        await Future<void>.delayed(
          checkInterval,
        );
      }

      final bool ready =
          !_disposed &&
          _miningRewardedAd != null &&
          _miningAdReady;

      debugPrint(
        'Mining rewarded ad wait finished. '
        'Ready: $ready',
      );

      return ready;
    }

    // ==========================================================
    // ⚡ POWER BOOST
    // ==========================================================

    if (purpose == powerBoostPurpose) {
      if (_powerBoostRewardedAd != null &&
          _powerBoostAdReady) {
        debugPrint(
          'Power Boost rewarded ad already ready.',
        );

        return true;
      }

      if (!_powerBoostAdLoading) {
        await loadRewardedAd(
          purpose: purpose,
        );
      }

      const int maxWaitChecks = 150;

      const Duration checkInterval =
          Duration(
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

        if (_powerBoostRewardedAd != null &&
            _powerBoostAdReady) {
          debugPrint(
            'Power Boost rewarded ad became ready.',
          );

          return true;
        }

        if (!_powerBoostAdLoading) {
          break;
        }

        await Future<void>.delayed(
          checkInterval,
        );
      }

      final bool ready =
          !_disposed &&
          _powerBoostRewardedAd != null &&
          _powerBoostAdReady;

      debugPrint(
        'Power Boost rewarded ad wait finished. '
        'Ready: $ready',
      );

      return ready;
    }

    debugPrint(
      'Unknown rewarded ad purpose: $purpose',
    );

    return false;
  }

  // ============================================================
  // 📺 LOAD REWARDED AD
  // ============================================================

  Future<void> loadRewardedAd({
    required String purpose,
  }) async {
    if (_disposed) {
      return;
    }

    if (purpose == miningStartPurpose) {
      await _loadMiningRewardedAd();
      return;
    }

    if (purpose == powerBoostPurpose) {
      await _loadPowerBoostRewardedAd();
      return;
    }

    debugPrint(
      'Cannot load rewarded ad. '
      'Unknown purpose: $purpose',
    );
  }

  // ============================================================
  // ⛏️ LOAD MINING AD
  // ============================================================

  Future<void> _loadMiningRewardedAd() async {
    if (_disposed) {
      return;
    }

    if (_miningRewardedAd != null &&
        _miningAdReady) {
      debugPrint(
        'Mining rewarded ad already ready.',
      );

      return;
    }

    if (_miningAdLoading) {
      debugPrint(
        'Mining rewarded ad loading already in progress.',
      );

      return;
    }

    final User? user =
        _auth.currentUser;

    if (user == null) {
      debugPrint(
        'Cannot load Mining rewarded ad: '
        'no authenticated Firebase user.',
      );

      _miningAdLoading = false;
      _miningAdReady = false;
      _miningAdLoadError =
          'NO_AUTH_USER';

      _notify();

      return;
    }

    _disposeMiningAd();

    final int requestId =
        ++_miningLoadRequestId;

    _miningAdLoading = true;
    _miningAdReady = false;
    _miningAdLoadError = '';

    _notify();

    debugPrint(
      '==================================================',
    );

    debugPrint(
      'STELLURIINI MINING ADMOB LOAD START',
    );

    debugPrint(
      'AD UNIT: $miningRewardedAdUnitId',
    );

    debugPrint(
      'Purpose: $miningStartPurpose',
    );

    debugPrint(
      'User UID length: ${user.uid.length}',
    );

    debugPrint(
      '==================================================',
    );

    RewardedAd.load(
      adUnitId:
          miningRewardedAdUnitId,
      request:
          const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (
          RewardedAd ad,
        ) {
          if (_disposed) {
            ad.dispose();
            return;
          }

          if (requestId !=
              _miningLoadRequestId) {
            debugPrint(
              'Ignoring stale Mining rewarded ad callback.',
            );

            ad.dispose();
            return;
          }

          debugPrint(
            '==================================================',
          );

          debugPrint(
            'STELLURIINI MINING ADMOB LOAD SUCCESS',
          );

          debugPrint(
            'Purpose: $miningStartPurpose',
          );

          debugPrint(
            '==================================================',
          );

          try {
            final ServerSideVerificationOptions
                serverSideOptions =
                ServerSideVerificationOptions(
              customData:
                  '${user.uid}:$miningStartPurpose',
            );

            ad.setServerSideOptions(
              serverSideOptions,
            );
          } catch (error) {
            debugPrint(
              'Mining SSV setup failed: $error',
            );

            ad.dispose();

            _miningRewardedAd = null;
            _miningAdReady = false;
            _miningAdLoading = false;

            _miningAdLoadError =
                'SSV_SETUP_FAILED: $error';

            _notify();

            return;
          }

          _miningRewardedAd = ad;

          _miningAdReady = true;

          _miningAdLoading = false;

          _miningAdLoadError = '';

          ad.fullScreenContentCallback =
              _createFullScreenCallback(
            purpose:
                miningStartPurpose,
            isMining: true,
          );

          _notify();
        },
        onAdFailedToLoad: (
          LoadAdError error,
        ) {
          if (_disposed) {
            return;
          }

          if (requestId !=
              _miningLoadRequestId) {
            return;
          }

          debugPrint(
            '==================================================',
          );

          debugPrint(
            'STELLURIINI MINING ADMOB LOAD FAILED',
          );

          debugPrint(
            'Purpose: $miningStartPurpose',
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
            'Response info: ${error.responseInfo}',
          );

          debugPrint(
            '==================================================',
          );

          _miningRewardedAd = null;

          _miningAdReady = false;

          _miningAdLoading = false;

          _miningAdLoadError =
              'Code: ${error.code} | '
              'Domain: ${error.domain} | '
              'Message: ${error.message}';

          _finishFlow(
            miningStartPurpose,
          );

          _notify();

          onAdLoadError?.call(
            miningStartPurpose,
            error,
          );
        },
      ),
    );
  }

  // ============================================================
  // ⚡ LOAD POWER BOOST AD
  // ============================================================

  Future<void> _loadPowerBoostRewardedAd() async {
    if (_disposed) {
      return;
    }

    if (_powerBoostRewardedAd != null &&
        _powerBoostAdReady) {
      debugPrint(
        'Power Boost rewarded ad already ready.',
      );

      return;
    }

    if (_powerBoostAdLoading) {
      debugPrint(
        'Power Boost rewarded ad loading already in progress.',
      );

      return;
    }

    final User? user =
        _auth.currentUser;

    if (user == null) {
      debugPrint(
        'Cannot load Power Boost rewarded ad: '
        'no authenticated Firebase user.',
      );

      _powerBoostAdLoading = false;
      _powerBoostAdReady = false;
      _powerBoostAdLoadError =
          'NO_AUTH_USER';

      _notify();

      return;
    }

    _disposePowerBoostAd();

    final int requestId =
        ++_powerBoostLoadRequestId;

    _powerBoostAdLoading = true;
    _powerBoostAdReady = false;
    _powerBoostAdLoadError = '';

    _notify();

    debugPrint(
      '==================================================',
    );

    debugPrint(
      'STELLURIINI POWER BOOST ADMOB LOAD START',
    );

    debugPrint(
      'AD UNIT: $powerBoostRewardedAdUnitId',
    );

    debugPrint(
      'Purpose: $powerBoostPurpose',
    );

    debugPrint(
      'User UID length: ${user.uid.length}',
    );

    debugPrint(
      '==================================================',
    );

    RewardedAd.load(
      adUnitId:
          powerBoostRewardedAdUnitId,
      request:
          const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (
          RewardedAd ad,
        ) {
          if (_disposed) {
            ad.dispose();
            return;
          }

          if (requestId !=
              _powerBoostLoadRequestId) {
            debugPrint(
              'Ignoring stale Power Boost rewarded ad callback.',
            );

            ad.dispose();
            return;
          }

          debugPrint(
            '==================================================',
          );

          debugPrint(
            'STELLURIINI POWER BOOST ADMOB LOAD SUCCESS',
          );

          debugPrint(
            'Purpose: $powerBoostPurpose',
          );

          debugPrint(
            '==================================================',
          );

          try {
            final ServerSideVerificationOptions
                serverSideOptions =
                ServerSideVerificationOptions(
              customData:
                  '${user.uid}:$powerBoostPurpose',
            );

            ad.setServerSideOptions(
              serverSideOptions,
            );
          } catch (error) {
            debugPrint(
              'Power Boost SSV setup failed: $error',
            );

            ad.dispose();

            _powerBoostRewardedAd = null;
            _powerBoostAdReady = false;
            _powerBoostAdLoading = false;

            _powerBoostAdLoadError =
                'SSV_SETUP_FAILED: $error';

            _notify();

            return;
          }

          _powerBoostRewardedAd = ad;

          _powerBoostAdReady = true;

          _powerBoostAdLoading = false;

          _powerBoostAdLoadError = '';

          ad.fullScreenContentCallback =
              _createFullScreenCallback(
            purpose:
                powerBoostPurpose,
            isMining: false,
          );

          _notify();
        },
        onAdFailedToLoad: (
          LoadAdError error,
        ) {
          if (_disposed) {
            return;
          }

          if (requestId !=
              _powerBoostLoadRequestId) {
            return;
          }

          debugPrint(
            '==================================================',
          );

          debugPrint(
            'STELLURIINI POWER BOOST ADMOB LOAD FAILED',
          );

          debugPrint(
            'Purpose: $powerBoostPurpose',
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
            'Response info: ${error.responseInfo}',
          );

          debugPrint(
            '==================================================',
          );

          _powerBoostRewardedAd = null;

          _powerBoostAdReady = false;

          _powerBoostAdLoading = false;

          _powerBoostAdLoadError =
              'Code: ${error.code} | '
              'Domain: ${error.domain} | '
              'Message: ${error.message}';

          _finishFlow(
            powerBoostPurpose,
          );

          _notify();

          onAdLoadError?.call(
            powerBoostPurpose,
            error,
          );
        },
      ),
    );
  }

  // ============================================================
  // 🖥️ FULL SCREEN CALLBACK
  // ============================================================

  FullScreenContentCallback
      _createFullScreenCallback({
    required String purpose,
    required bool isMining,
  }) {
    return FullScreenContentCallback(
      // ========================================================
      // SHOWN
      // ========================================================

      onAdShowedFullScreenContent:
          (
        RewardedAd showedAd,
      ) {
        debugPrint(
          '==================================================',
        );

        debugPrint(
          'STELLURIINI ADMOB SHOWN',
        );

        debugPrint(
          'Purpose: $purpose',
        );

        debugPrint(
          '==================================================',
        );
      },

      // ========================================================
      // DISMISSED
      // ========================================================

      onAdDismissedFullScreenContent:
          (
        RewardedAd dismissedAd,
      ) async {
        debugPrint(
          '==================================================',
        );

        debugPrint(
          'STELLURIINI ADMOB DISMISSED',
        );

        debugPrint(
          'Purpose: $purpose',
        );

        debugPrint(
          '==================================================',
        );

        dismissedAd.dispose();

        if (isMining) {
          if (identical(
            _miningRewardedAd,
            dismissedAd,
          )) {
            _miningRewardedAd = null;
            _miningAdReady = false;
          }
        } else {
          if (identical(
            _powerBoostRewardedAd,
            dismissedAd,
          )) {
            _powerBoostRewardedAd = null;
            _powerBoostAdReady = false;
          }
        }

        _finishFlow(
          purpose,
        );

        _notify();

        onAdDismissed?.call(
          purpose,
        );
      },

      // ========================================================
      // SHOW FAILED
      // ========================================================

      onAdFailedToShowFullScreenContent:
          (
        RewardedAd failedAd,
        AdError error,
      ) {
        debugPrint(
          '==================================================',
        );

        debugPrint(
          'STELLURIINI ADMOB SHOW FAILED',
        );

        debugPrint(
          'Purpose: $purpose',
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

        failedAd.dispose();

        if (isMining) {
          if (identical(
            _miningRewardedAd,
            failedAd,
          )) {
            _miningRewardedAd = null;
            _miningAdReady = false;
          }

          _miningAdLoadError =
              'SHOW_FAILED | '
              'Code: ${error.code} | '
              'Domain: ${error.domain} | '
              'Message: ${error.message}';
        } else {
          if (identical(
            _powerBoostRewardedAd,
            failedAd,
          )) {
            _powerBoostRewardedAd = null;
            _powerBoostAdReady = false;
          }

          _powerBoostAdLoadError =
              'SHOW_FAILED | '
              'Code: ${error.code} | '
              'Domain: ${error.domain} | '
              'Message: ${error.message}';
        }

        _finishFlow(
          purpose,
        );

        _notify();

        onAdShowError?.call(
          purpose,
          error,
        );
      },
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
        'Mining Start ad flow already active.',
      );

      return false;
    }

    if (_powerBoostAdFlowActive) {
      debugPrint(
        'Power Boost ad flow is active.',
      );

      return false;
    }

    _miningAdFlowActive = true;

    _miningAdLoadError = '';

    _notify();

    try {
      final bool ready =
          await waitForRewardedAd(
        purpose:
            miningStartPurpose,
      );

      if (_disposed) {
        return false;
      }

      if (!ready ||
          _miningRewardedAd == null ||
          !_miningAdReady) {
        _miningAdFlowActive = false;

        _notify();

        return false;
      }

      final RewardedAd ad =
          _miningRewardedAd!;

      _miningRewardedAd = null;

      _miningAdReady = false;

      _notify();

      bool rewardEarned = false;

      debugPrint(
        '==================================================',
      );

      debugPrint(
        'STELLURIINI SHOW MINING START',
      );

      debugPrint(
        'Waiting for onUserEarnedReward...',
      );

      debugPrint(
        '==================================================',
      );

      ad.show(
        onUserEarnedReward: (
          AdWithoutView adWithoutView,
          RewardItem reward,
        ) async {
          if (rewardEarned) {
            return;
          }

          rewardEarned = true;

          debugPrint(
            '==================================================',
          );

          debugPrint(
            'STELLURIINI MINING START REWARD RECEIVED',
          );

          debugPrint(
            'Reward amount: ${reward.amount}',
          );

          debugPrint(
            'Reward type: ${reward.type}',
          );

          debugPrint(
            'Calling Firebase claimMining...',
          );

          debugPrint(
            '==================================================',
          );

          try {
            await onMiningStartReward?.call();
          } catch (error) {
            debugPrint(
              'Mining Start reward callback error: '
              '$error',
            );
          }
        },
      );

      return true;
    } catch (error) {
      debugPrint(
        'Mining Start ad flow error: $error',
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
        'Power Boost ad flow already active.',
      );

      return false;
    }

    if (_miningAdFlowActive) {
      debugPrint(
        'Mining Start ad flow is active.',
      );

      return false;
    }

    _powerBoostAdFlowActive = true;

    _powerBoostAdLoadError = '';

    _notify();

    try {
      final bool ready =
          await waitForRewardedAd(
        purpose:
            powerBoostPurpose,
      );

      if (_disposed) {
        return false;
      }

      if (!ready ||
          _powerBoostRewardedAd == null ||
          !_powerBoostAdReady) {
        _powerBoostAdFlowActive = false;

        _notify();

        return false;
      }

      final RewardedAd ad =
          _powerBoostRewardedAd!;

      _powerBoostRewardedAd = null;

      _powerBoostAdReady = false;

      _notify();

      bool rewardEarned = false;

      debugPrint(
        '==================================================',
      );

      debugPrint(
        'STELLURIINI SHOW POWER BOOST',
      );

      debugPrint(
        'Waiting for onUserEarnedReward...',
      );

      debugPrint(
        '==================================================',
      );

      ad.show(
        onUserEarnedReward: (
          AdWithoutView adWithoutView,
          RewardItem reward,
        ) async {
          if (rewardEarned) {
            return;
          }

          rewardEarned = true;

          debugPrint(
            '==================================================',
          );

          debugPrint(
            'STELLURIINI POWER BOOST REWARD RECEIVED',
          );

          debugPrint(
            'Reward amount: ${reward.amount}',
          );

          debugPrint(
            'Reward type: ${reward.type}',
          );

          debugPrint(
            'Calling Firebase powerBoost...',
          );

          debugPrint(
            '==================================================',
          );

          try {
            await onPowerBoostReward?.call();
          } catch (error) {
            debugPrint(
              'Power Boost reward callback error: '
              '$error',
            );
          }
        },
      );

      return true;
    } catch (error) {
      debugPrint(
        'Power Boost ad flow error: $error',
      );

      _powerBoostAdFlowActive = false;

      _notify();

      return false;
    }
  }

  // ============================================================
  // FINISH FLOW
  // ============================================================

  void _finishFlow(
    String purpose,
  ) {
    if (purpose ==
        miningStartPurpose) {
      _miningAdFlowActive = false;
    }

    if (purpose ==
        powerBoostPurpose) {
      _powerBoostAdFlowActive = false;
    }
  }

  // ============================================================
  // ⛏️ DISPOSE MINING AD
  // ============================================================

  void _disposeMiningAd() {
    final RewardedAd? ad =
        _miningRewardedAd;

    _miningRewardedAd = null;

    _miningAdReady = false;

    ad?.dispose();
  }

  // ============================================================
  // ⚡ DISPOSE POWER BOOST AD
  // ============================================================

  void _disposePowerBoostAd() {
    final RewardedAd? ad =
        _powerBoostRewardedAd;

    _powerBoostRewardedAd = null;

    _powerBoostAdReady = false;

    ad?.dispose();
  }

  // ============================================================
  // 🧹 CLEAR CURRENT ADS
  // ============================================================

  void clearCurrentAd() {
    _miningLoadRequestId++;
    _powerBoostLoadRequestId++;

    _disposeMiningAd();
    _disposePowerBoostAd();

    _miningAdLoading = false;
    _powerBoostAdLoading = false;

    _miningAdLoadError = '';
    _powerBoostAdLoadError = '';

    _notify();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _disposed = true;

    _miningLoadRequestId++;
    _powerBoostLoadRequestId++;

    _miningRewardedAd?.dispose();
    _powerBoostRewardedAd?.dispose();

    _miningRewardedAd = null;
    _powerBoostRewardedAd = null;

    super.dispose();
  }
}