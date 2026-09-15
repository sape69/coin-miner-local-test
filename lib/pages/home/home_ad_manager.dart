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
// Tarkoitukset:
//
//   mining_start
//   power_boost
//
// Molemmat käyttävät samaa tuotannon Rewarded Ad Unit ID:tä,
// mutta SSV customData erottaa käyttötarkoitukset.
//
// ============================================================

class HomeAdManager extends ChangeNotifier {
  // ============================================================
  // 📺 PRODUCTION ADMOB
  // ============================================================

  static const String rewardedAdUnitId =
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
  // 📺 CURRENT AD
  // ============================================================

  RewardedAd? _rewardedAd;

  bool _adReady = false;

  bool _adLoading = false;

  String _rewardedAdPurpose =
      powerBoostPurpose;

  String _adLoadError = '';

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
  // SAFE NOTIFY
  // ============================================================

  void _notify() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  // ============================================================
  // WAIT FOR AD
  // ============================================================

  Future<bool> waitForRewardedAd({
    required String purpose,
  }) async {
    if (_disposed) {
      return false;
    }

    if (_rewardedAd != null &&
        _adReady &&
        _rewardedAdPurpose == purpose) {
      debugPrint(
        'Rewarded ad already ready: $purpose',
      );

      return true;
    }

    if (_rewardedAd != null &&
        _rewardedAdPurpose != purpose) {
      _disposeCurrentAd();
    }

    if (!_adLoading) {
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

      if (_rewardedAd != null &&
          _adReady &&
          _rewardedAdPurpose == purpose) {
        debugPrint(
          'Rewarded ad became ready: $purpose',
        );

        return true;
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
        _rewardedAdPurpose == purpose;

    debugPrint(
      'Rewarded ad wait finished. '
      'Purpose: $purpose '
      'Ready: $ready',
    );

    return ready;
  }

  // ============================================================
  // LOAD REWARDED AD
  // ============================================================

  Future<void> loadRewardedAd({
    required String purpose,
  }) async {
    if (_disposed) {
      return;
    }

    if (_rewardedAd != null &&
        _adReady &&
        _rewardedAdPurpose == purpose) {
      debugPrint(
        'Rewarded ad already ready: $purpose',
      );

      return;
    }

    if (_adLoading) {
      debugPrint(
        'Rewarded ad loading already in progress. '
        'Requested purpose: $purpose',
      );

      return;
    }

    final User? user =
        _auth.currentUser;

    if (user == null) {
      debugPrint(
        'Cannot load rewarded ad: '
        'no authenticated Firebase user.',
      );

      _adLoading = false;
      _adReady = false;
      _adLoadError = 'NO_AUTH_USER';

      _notify();

      return;
    }

    if (_rewardedAd != null) {
      _disposeCurrentAd();
    }

    final int requestId =
        ++_loadRequestId;

    _adLoading = true;
    _adReady = false;
    _adLoadError = '';
    _rewardedAdPurpose = purpose;

    _notify();

    debugPrint(
      '==================================================',
    );

    debugPrint(
      'STELLURIINI ADMOB LOAD START',
    );

    debugPrint(
      'AD UNIT: $rewardedAdUnitId',
    );

    debugPrint(
      'Purpose: $purpose',
    );

    debugPrint(
      'User UID length: ${user.uid.length}',
    );

    debugPrint(
      '==================================================',
    );

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        // ======================================================
        // ✅ LOADED
        // ======================================================

        onAdLoaded: (
          RewardedAd ad,
        ) {
          if (_disposed) {
            ad.dispose();
            return;
          }

          if (requestId != _loadRequestId) {
            debugPrint(
              'Ignoring stale rewarded ad callback.',
            );

            ad.dispose();
            return;
          }

          debugPrint(
            '==================================================',
          );

          debugPrint(
            'STELLURIINI ADMOB LOAD SUCCESS',
          );

          debugPrint(
            'Purpose: $purpose',
          );

          debugPrint(
            '==================================================',
          );

          try {
            final ServerSideVerificationOptions
                serverSideOptions =
                ServerSideVerificationOptions(
              customData:
                  '${user.uid}:$purpose',
            );

            ad.setServerSideOptions(
              serverSideOptions,
            );
          } catch (error) {
            debugPrint(
              'AdMob SSV setup failed: $error',
            );

            ad.dispose();

            _rewardedAd = null;
            _adReady = false;
            _adLoading = false;

            _adLoadError =
                'SSV_SETUP_FAILED: $error';

            _notify();

            return;
          }

          _rewardedAd = ad;

          _rewardedAdPurpose =
              purpose;

          _adReady = true;

          _adLoading = false;

          _adLoadError = '';

          // ====================================================
          // FULL SCREEN CALLBACKS
          // ====================================================

          ad.fullScreenContentCallback =
              FullScreenContentCallback(
            // --------------------------------------------------
            // SHOWN
            // --------------------------------------------------

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

            // --------------------------------------------------
            // DISMISSED
            // --------------------------------------------------

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

              if (identical(
                _rewardedAd,
                dismissedAd,
              )) {
                _rewardedAd = null;
                _adReady = false;
              }

              _finishFlow(
                purpose,
              );

              _notify();

              onAdDismissed?.call(
                purpose,
              );

              // ------------------------------------------------
              // HUOMIO:
              //
              // Normaali RewardedAd-polku kutsuu palkkiokäsittelyn
              // onUserEarnedReward-callbackissa.
              //
              // Jos callback ei jostain syystä saavu ennen
              // mainoksen sulkemista, emme tässä kohtaa voi
              // turvallisesti antaa palkkiota suoraan.
              //
              // Firebase SSV toimii lopullisena vahvistuksena.
              //
              // Siksi emme kutsu callbackia automaattisesti tässä.
              //
              // ------------------------------------------------
            },

            // --------------------------------------------------
            // SHOW FAILED
            // --------------------------------------------------

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

              if (identical(
                _rewardedAd,
                failedAd,
              )) {
                _rewardedAd = null;
                _adReady = false;
              }

              _finishFlow(
                purpose,
              );

              _adLoadError =
                  'SHOW_FAILED | '
                  'Code: ${error.code} | '
                  'Domain: ${error.domain} | '
                  'Message: ${error.message}';

              _notify();

              onAdShowError?.call(
                purpose,
                error,
              );
            },
          );

          _notify();
        },

        // ======================================================
        // ❌ LOAD FAILED
        // ======================================================

        onAdFailedToLoad: (
          LoadAdError error,
        ) {
          if (_disposed) {
            return;
          }

          if (requestId != _loadRequestId) {
            return;
          }

          debugPrint(
            '==================================================',
          );

          debugPrint(
            'STELLURIINI ADMOB LOAD FAILED',
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
            'Response info: ${error.responseInfo}',
          );

          debugPrint(
            '==================================================',
          );

          _rewardedAd = null;

          _adReady = false;

          _adLoading = false;

          _adLoadError =
              'Code: ${error.code} | '
              'Domain: ${error.domain} | '
              'Message: ${error.message}';

          _finishFlow(
            purpose,
          );

          _notify();

          onAdLoadError?.call(
            purpose,
            error,
          );

          debugPrint(
            'No automatic reload after AdMob load failure.',
          );
        },
      ),
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

    _adLoadError = '';

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
          _rewardedAd == null ||
          !_adReady ||
          _rewardedAdPurpose !=
              miningStartPurpose) {
        _miningAdFlowActive = false;

        _notify();

        return false;
      }

      final RewardedAd ad =
          _rewardedAd!;

      _rewardedAd = null;
      _adReady = false;

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

    _adLoadError = '';

    _notify();

    try {
      if (_rewardedAd != null &&
          _rewardedAdPurpose !=
              powerBoostPurpose) {
        _disposeCurrentAd();
      }

      final bool ready =
          await waitForRewardedAd(
        purpose:
            powerBoostPurpose,
      );

      if (_disposed) {
        return false;
      }

      if (!ready ||
          _rewardedAd == null ||
          !_adReady ||
          _rewardedAdPurpose !=
              powerBoostPurpose) {
        _powerBoostAdFlowActive = false;

        _notify();

        return false;
      }

      final RewardedAd ad =
          _rewardedAd!;

      _rewardedAd = null;
      _adReady = false;

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
  // DISPOSE CURRENT AD
  // ============================================================

  void _disposeCurrentAd() {
    final RewardedAd? ad =
        _rewardedAd;

    _rewardedAd = null;

    _adReady = false;

    ad?.dispose();
  }

  // ============================================================
  // CLEAR CURRENT AD
  // ============================================================

  void clearCurrentAd() {
    _loadRequestId++;

    _disposeCurrentAd();

    _adLoading = false;

    _adLoadError = '';

    _notify();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _disposed = true;

    _loadRequestId++;

    _rewardedAd?.dispose();

    _rewardedAd = null;

    super.dispose();
  }
}