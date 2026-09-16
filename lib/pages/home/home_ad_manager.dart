import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// ============================================================
// 🐱 STELLURIINI HOME AD MANAGER
// ============================================================
//
// STELLURIININ OIKEAT ADMOB-MAINOSYKSIKÖT
//
// Käytetään Stelluriini-projektin omia Rewarded-mainosyksiköitä.
//
// Flutter
//    ↓
// Google Mobile Ads SDK
//    ↓
// Stelluriinin Rewarded Ad
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

  static const String powerBoostPurpose =
      'power_boost';

  static const String miningStartPurpose =
      'mining_start';

  // ============================================================
  // ⏳ SSV WAIT
  // ============================================================

  static const Duration ssvGracePeriod =
      Duration(
    seconds: 8,
  );

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

  String _rewardedAdPurpose = '';

  String _loadingPurpose = '';

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
  // GET AD UNIT ID
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
  // WAIT FOR REWARDED AD
  // ============================================================

  Future<bool> waitForRewardedAd({
    required String purpose,
  }) async {
    if (_disposed) {
      return false;
    }

    // ----------------------------------------------------------
    // AD ALREADY READY FOR THIS PURPOSE
    // ----------------------------------------------------------

    if (_rewardedAd != null &&
        _adReady &&
        _rewardedAdPurpose == purpose) {
      debugPrint(
        '🐱 Stelluriini Rewarded ad already ready: $purpose',
      );

      return true;
    }

    // ----------------------------------------------------------
    // WRONG READY AD
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
    // WRONG AD IS CURRENTLY LOADING
    // ----------------------------------------------------------

    if (_adLoading &&
        _loadingPurpose != purpose) {
      debugPrint(
        '🐱 Different Rewarded ad is currently loading. '
        'Cancelling stale load logically and switching to: '
        '$purpose',
      );

      _loadRequestId++;

      _adLoading = false;
      _loadingPurpose = '';

      _rewardedAd = null;
      _adReady = false;
      _rewardedAdPurpose = '';

      _notify();
    }

    // ----------------------------------------------------------
    // START LOAD
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
          '🐱 Stelluriini Rewarded ad became ready: $purpose',
        );

        return true;
      }

      if (_adLoading &&
          _loadingPurpose != purpose) {
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
        _rewardedAdPurpose == purpose;

    debugPrint(
      '🐱 Rewarded ad wait finished. '
      'Purpose: $purpose '
      'Ready: $ready',
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

    // ----------------------------------------------------------
    // ALREADY READY
    // ----------------------------------------------------------

    if (_rewardedAd != null &&
        _adReady &&
        _rewardedAdPurpose == purpose) {
      debugPrint(
        '🐱 Stelluriini Rewarded ad already ready: $purpose',
      );

      return;
    }

    // ----------------------------------------------------------
    // DIFFERENT AD IS ALREADY LOADING
    // ----------------------------------------------------------

    if (_adLoading) {
      if (_loadingPurpose == purpose) {
        debugPrint(
          '🐱 Rewarded ad loading already in progress: '
          '$purpose',
        );

        return;
      }

      debugPrint(
        '🐱 Replacing stale Rewarded ad load. '
        'Old: $_loadingPurpose '
        'New: $purpose',
      );

      _loadRequestId++;

      _adLoading = false;
      _loadingPurpose = '';
    }

    // ----------------------------------------------------------
    // AUTH CHECK
    // ----------------------------------------------------------

    final User? user =
        _auth.currentUser;

    if (user == null) {
      debugPrint(
        '🐱 Cannot load rewarded ad: '
        'no authenticated Firebase user.',
      );

      _adLoading = false;
      _loadingPurpose = '';
      _adReady = false;
      _adLoadError = 'NO_AUTH_USER';

      _notify();

      return;
    }

    // ----------------------------------------------------------
    // CLEAR OLD AD
    // ----------------------------------------------------------

    if (_rewardedAd != null) {
      _disposeCurrentAd();
    }

    // ----------------------------------------------------------
    // REQUEST ID
    // ----------------------------------------------------------

    final int requestId =
        ++_loadRequestId;

    // ----------------------------------------------------------
    // STATE
    // ----------------------------------------------------------

    _adLoading = true;
    _loadingPurpose = purpose;
    _adReady = false;
    _adLoadError = '';
    _rewardedAdPurpose = purpose;

    _notify();

    // ----------------------------------------------------------
    // AD UNIT
    // ----------------------------------------------------------

    final String adUnitId =
        _getAdUnitId(
      purpose,
    );

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

    // ==========================================================
    // LOAD
    // ==========================================================

    RewardedAd.load(
      adUnitId: adUnitId,
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
              '🐱 Ignoring stale rewarded ad callback.',
            );

            ad.dispose();
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

          // ----------------------------------------------------
          // SSV
          // ----------------------------------------------------

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

            ad.dispose();

            _rewardedAd = null;
            _adReady = false;
            _adLoading = false;
            _loadingPurpose = '';

            _adLoadError =
                'SSV_SETUP_FAILED: $error';

            _notify();

            return;
          }

          // ----------------------------------------------------
          // STORE AD
          // ----------------------------------------------------

          _rewardedAd = ad;
          _rewardedAdPurpose = purpose;
          _adReady = true;
          _adLoading = false;
          _loadingPurpose = '';
          _adLoadError = '';

          // ====================================================
          // FULL SCREEN CALLBACKS
          // ====================================================

          ad.fullScreenContentCallback =
              FullScreenContentCallback<RewardedAd>(
            // --------------------------------------------------
            // SHOWN
            // --------------------------------------------------

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
                '==================================================',
              );
            },

            // --------------------------------------------------
            // IMPRESSION
            // --------------------------------------------------

            onAdImpression: (
              RewardedAd impressionAd,
            ) {
              debugPrint(
                '🐱 STELLURIINI ADMOB IMPRESSION',
              );

              debugPrint(
                'Purpose: $purpose',
              );
            },

            // --------------------------------------------------
            // CLICK
            // --------------------------------------------------

            onAdClicked: (
              RewardedAd clickedAd,
            ) {
              debugPrint(
                '🐱 STELLURIINI ADMOB CLICKED',
              );

              debugPrint(
                'Purpose: $purpose',
              );
            },

            // --------------------------------------------------
            // DISMISSED
            // --------------------------------------------------

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
                '==================================================',
              );

              dismissedAd.dispose();

              if (identical(
                _rewardedAd,
                dismissedAd,
              )) {
                _rewardedAd = null;
                _adReady = false;
                _rewardedAdPurpose = '';
              }

              _finishFlow(
                purpose,
              );

              _notify();

              onAdDismissed?.call(
                purpose,
              );

              // ------------------------------------------------
              // Hiljainen taustalataus.
              // ------------------------------------------------

              if (!_disposed) {
                unawaited(
                  _reloadAfterDismiss(
                    purpose,
                  ),
                );
              }
            },

            // --------------------------------------------------
            // SHOW FAILED
            // --------------------------------------------------

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
                _rewardedAdPurpose = '';
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
            'Response info: ${error.responseInfo}',
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
          _rewardedAdPurpose = '';

          _adLoadError =
              'Code: ${error.code} | '
              'Domain: ${error.domain} | '
              'Message: ${error.message}';

          _notify();

          // ----------------------------------------------------
          // Vain käyttäjän aloittama lataus ilmoittaa virheestä.
          // ----------------------------------------------------

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
  // 🔄 RELOAD AFTER DISMISS
  // ============================================================

  Future<void> _reloadAfterDismiss(
    String purpose,
  ) async {
    if (_disposed) {
      return;
    }

    await Future<void>.delayed(
      const Duration(
        seconds: 5,
      ),
    );

    if (_disposed) {
      return;
    }

    // ----------------------------------------------------------
    // Jos toinen mainostyyppi on jo valmis, ei korvata sitä.
    // ----------------------------------------------------------

    if (_rewardedAd != null &&
        _adReady) {
      return;
    }

    // ----------------------------------------------------------
    // Jos toinen mainostyyppi on latautumassa, ei korvata sitä.
    // ----------------------------------------------------------

    if (_adLoading) {
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
  // 🛡️ DELAYED SSV REWARD CALLBACK
  // ============================================================

  void _scheduleVerifiedRewardCallback({
    required String purpose,
    required bool Function() isRewardAlreadyHandled,
    required void Function() markRewardHandled,
  }) {
    unawaited(
      () async {
        debugPrint(
          '==================================================',
        );

        debugPrint(
          '🐱 STELLURIINI SSV GRACE PERIOD START',
        );

        debugPrint(
          'Purpose: $purpose',
        );

        debugPrint(
          'Waiting: '
          '${ssvGracePeriod.inSeconds} seconds',
        );

        debugPrint(
          '==================================================',
        );

        await Future<void>.delayed(
          ssvGracePeriod,
        );

        if (_disposed) {
          debugPrint(
            '🐱 SSV reward callback cancelled: manager disposed.',
          );

          return;
        }

        if (isRewardAlreadyHandled()) {
          debugPrint(
            '🐱 SSV reward callback already handled.',
          );

          return;
        }

        markRewardHandled();

        debugPrint(
          '==================================================',
        );

        debugPrint(
          '🐱 STELLURIINI SSV GRACE PERIOD COMPLETE',
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
          }
        } catch (error) {
          debugPrint(
            '🐱 Verified reward callback error: $error',
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

    _miningAdFlowActive = true;
    _adLoadError = '';

    _notify();

    try {
      final bool ready =
          await waitForRewardedAd(
        purpose: miningStartPurpose,
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
      _rewardedAdPurpose = '';

      _notify();

      bool rewardEarned = false;

      bool rewardCallbackHandled =
          false;

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
        'SSV Custom Data: '
        '${_auth.currentUser?.uid}:$miningStartPurpose',
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
            'for SSV verification.',
          );

          debugPrint(
            '==================================================',
          );

          _scheduleVerifiedRewardCallback(
            purpose: miningStartPurpose,
            isRewardAlreadyHandled: () =>
                rewardCallbackHandled,
            markRewardHandled: () {
              rewardCallbackHandled = true;
            },
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

    _powerBoostAdFlowActive = true;
    _adLoadError = '';

    _notify();

    try {
      // --------------------------------------------------------
      // Varmistetaan, ettei väärä valmis mainos ole käytössä.
      // --------------------------------------------------------

      if (_rewardedAd != null &&
          _rewardedAdPurpose !=
              powerBoostPurpose) {
        _disposeCurrentAd();
      }

      // --------------------------------------------------------
      // Varmistetaan, ettei väärä mainostyyppi jää latautumaan.
      // --------------------------------------------------------

      if (_adLoading &&
          _loadingPurpose !=
              powerBoostPurpose) {
        debugPrint(
          '🐱 Switching active ad load to Power Boost.',
        );

        _loadRequestId++;

        _adLoading = false;
        _loadingPurpose = '';
      }

      // --------------------------------------------------------
      // Ladataan nimenomaan Power Boost -mainos.
      // --------------------------------------------------------

      final bool ready =
          await waitForRewardedAd(
        purpose: powerBoostPurpose,
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
      _rewardedAdPurpose = '';

      _notify();

      bool rewardEarned = false;

      bool rewardCallbackHandled =
          false;

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
        'SSV Custom Data: '
        '${_auth.currentUser?.uid}:$powerBoostPurpose',
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
            'for SSV verification.',
          );

          debugPrint(
            '==================================================',
          );

          _scheduleVerifiedRewardCallback(
            purpose: powerBoostPurpose,
            isRewardAlreadyHandled: () =>
                rewardCallbackHandled,
            markRewardHandled: () {
              rewardCallbackHandled = true;
            },
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

  void _finishFlow(
    String purpose,
  ) {
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
    final RewardedAd? ad =
        _rewardedAd;

    _rewardedAd = null;
    _adReady = false;
    _rewardedAdPurpose = '';

    ad?.dispose();
  }

  // ============================================================
  // CLEAR CURRENT AD
  // ============================================================

  void clearCurrentAd() {
    _loadRequestId++;

    _disposeCurrentAd();

    _adLoading = false;
    _loadingPurpose = '';
    _adLoadError = '';
    _rewardedAdPurpose = '';

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

    _loadingPurpose = '';

    super.dispose();
  }
}