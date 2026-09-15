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
// MAINOSYKSIKÖT:
//
//   mining_start
//     → Stelluriini Reward
//
//   power_boost
//     → Stelluriini Power Boost
//
// Molemmat ovat omia AdMob Rewarded -mainosyksiköitä.
//
// SSV customData erottaa käyttötarkoituksen:
//   UID:mining_start
//   UID:power_boost
//
// ============================================================

class HomeAdManager extends ChangeNotifier {
  // ============================================================
  // 📺 MINING START REWARDED AD
  // ============================================================

  static const String miningRewardedAdUnitId =
      'ca-app-pub-1131012057145658/2252768949';

  // ============================================================
  // ⚡ POWER BOOST REWARDED AD
  // ============================================================

  static const String powerBoostRewardedAdUnitId =
      'ca-app-pub-1131012057145658/6674097787';

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
      '';

  String _adLoadError =
      '';

  // ============================================================
  // 🔒 FLOW STATE
  // ============================================================

  bool _miningAdFlowActive =
      false;

  bool _powerBoostAdFlowActive =
      false;

  // ============================================================
  // INTERNAL STATE
  // ============================================================

  bool _disposed =
      false;

  int _loadRequestId =
      0;

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
    if (purpose ==
        powerBoostPurpose) {
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
        _rewardedAdPurpose ==
            purpose) {
      debugPrint(
        'Rewarded ad already ready: $purpose',
      );

      return true;
    }

    // ----------------------------------------------------------
    // WRONG AD IS LOADED
    // ----------------------------------------------------------

    if (_rewardedAd != null &&
        _rewardedAdPurpose !=
            purpose) {
      debugPrint(
        'Different Rewarded ad is loaded. '
        'Replacing it with: $purpose',
      );

      _disposeCurrentAd();
    }

    // ----------------------------------------------------------
    // START LOAD
    // ----------------------------------------------------------

    if (!_adLoading) {
      await loadRewardedAd(
        purpose: purpose,
      );
    }

    // ----------------------------------------------------------
    // WAIT
    // ----------------------------------------------------------

    const int maxWaitChecks =
        150;

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
          _rewardedAdPurpose ==
              purpose) {
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
        _rewardedAdPurpose ==
            purpose;

    debugPrint(
      'Rewarded ad wait finished. '
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
  }) async {
    if (_disposed) {
      return;
    }

    // ----------------------------------------------------------
    // ALREADY READY
    // ----------------------------------------------------------

    if (_rewardedAd != null &&
        _adReady &&
        _rewardedAdPurpose ==
            purpose) {
      debugPrint(
        'Rewarded ad already ready: $purpose',
      );

      return;
    }

    // ----------------------------------------------------------
    // ALREADY LOADING
    // ----------------------------------------------------------

    if (_adLoading) {
      debugPrint(
        'Rewarded ad loading already in progress. '
        'Requested purpose: $purpose',
      );

      return;
    }

    // ----------------------------------------------------------
    // AUTH CHECK
    // ----------------------------------------------------------

    final User? user =
        _auth.currentUser;

    if (user == null) {
      debugPrint(
        'Cannot load rewarded ad: '
        'no authenticated Firebase user.',
      );

      _adLoading = false;
      _adReady = false;
      _adLoadError =
          'NO_AUTH_USER';

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
    _adReady = false;
    _adLoadError = '';
    _rewardedAdPurpose =
        purpose;

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
      'STELLURIINI ADMOB LOAD START',
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
      '==================================================',
    );

    // ==========================================================
    // LOAD
    // ==========================================================

    RewardedAd.load(
      adUnitId:
          adUnitId,
      request:
          const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        // ======================================================
        // ✅ LOADED
        // ======================================================

        onAdLoaded:
            (
          RewardedAd ad,
        ) {
          if (_disposed) {
            ad.dispose();
            return;
          }

          if (requestId !=
              _loadRequestId) {
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
          } catch (error) {
            debugPrint(
              'AdMob SSV setup failed: $error',
            );

            ad.dispose();

            _rewardedAd =
                null;

            _adReady =
                false;

            _adLoading =
                false;

            _adLoadError =
                'SSV_SETUP_FAILED: $error';

            _notify();

            return;
          }

          // ----------------------------------------------------
          // STORE AD
          // ----------------------------------------------------

          _rewardedAd =
              ad;

          _rewardedAdPurpose =
              purpose;

          _adReady =
              true;

          _adLoading =
              false;

          _adLoadError =
              '';

          // ====================================================
          // FULL SCREEN CALLBACKS
          // ====================================================
          //
          // TÄRKEÄ:
          //
          // Tässä käytetään eksplisiittisesti:
          //
          // FullScreenContentCallback<RewardedAd>
          //
          // Tämä korjaa google_mobile_ads:n generic-tyyppivirheet.
          //
          // ====================================================

          ad.fullScreenContentCallback =
              FullScreenContentCallback<RewardedAd>(
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
            // IMPRESSION
            // --------------------------------------------------

            onAdImpression:
                (
              RewardedAd impressionAd,
            ) {
              debugPrint(
                'STELLURIINI ADMOB IMPRESSION',
              );

              debugPrint(
                'Purpose: $purpose',
              );
            },

            // --------------------------------------------------
            // CLICK
            // --------------------------------------------------

            onAdClicked:
                (
              RewardedAd clickedAd,
            ) {
              debugPrint(
                'STELLURIINI ADMOB CLICKED',
              );

              debugPrint(
                'Purpose: $purpose',
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
                _rewardedAd =
                    null;

                _adReady =
                    false;
              }

              _finishFlow(
                purpose,
              );

              _notify();

              onAdDismissed?.call(
                purpose,
              );

              // ------------------------------------------------
              // Lataa seuraava saman tarkoituksen mainos
              // valmiiksi seuraavaa painallusta varten.
              // ------------------------------------------------

              if (!_disposed) {
                unawaited(
                  loadRewardedAd(
                    purpose:
                        purpose,
                  ),
                );
              }
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
                _rewardedAd =
                    null;

                _adReady =
                    false;
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

              // ------------------------------------------------
              // Yritetään ladata uusi mainos.
              // ------------------------------------------------

              if (!_disposed) {
                unawaited(
                  loadRewardedAd(
                    purpose:
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

        onAdFailedToLoad:
            (
          LoadAdError error,
        ) {
          if (_disposed) {
            return;
          }

          if (requestId !=
              _loadRequestId) {
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
            '==================================================',
          );

          _rewardedAd =
              null;

          _adReady =
              false;

          _adLoading =
              false;

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
            'No automatic reload after initial load failure.',
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

    _miningAdFlowActive =
        true;

    _adLoadError =
        '';

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
        _miningAdFlowActive =
            false;

        _notify();

        return false;
      }

      final RewardedAd ad =
          _rewardedAd!;

      _rewardedAd =
          null;

      _adReady =
          false;

      _notify();

      bool rewardEarned =
          false;

      debugPrint(
        '==================================================',
      );

      debugPrint(
        'STELLURIINI SHOW MINING START',
      );

      debugPrint(
        'Ad Unit ID: $miningRewardedAdUnitId',
      );

      debugPrint(
        'Waiting for onUserEarnedReward...',
      );

      debugPrint(
        '==================================================',
      );

      ad.show(
        onUserEarnedReward:
            (
          AdWithoutView adWithoutView,
          RewardItem reward,
        ) async {
          if (rewardEarned) {
            return;
          }

          rewardEarned =
              true;

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

      _miningAdFlowActive =
          false;

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

    _powerBoostAdFlowActive =
        true;

    _adLoadError =
        '';

    _notify();

    try {
      // --------------------------------------------------------
      // Varmistetaan, ettei mining-mainos ole käytössä.
      // --------------------------------------------------------

      if (_rewardedAd != null &&
          _rewardedAdPurpose !=
              powerBoostPurpose) {
        _disposeCurrentAd();
      }

      // --------------------------------------------------------
      // Ladataan nimenomaan Power Boost -mainosyksikkö.
      // --------------------------------------------------------

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
        _powerBoostAdFlowActive =
            false;

        _notify();

        return false;
      }

      final RewardedAd ad =
          _rewardedAd!;

      _rewardedAd =
          null;

      _adReady =
          false;

      _notify();

      bool rewardEarned =
          false;

      debugPrint(
        '==================================================',
      );

      debugPrint(
        'STELLURIINI SHOW POWER BOOST',
      );

      debugPrint(
        'Ad Unit ID: $powerBoostRewardedAdUnitId',
      );

      debugPrint(
        'Waiting for onUserEarnedReward...',
      );

      debugPrint(
        '==================================================',
      );

      ad.show(
        onUserEarnedReward:
            (
          AdWithoutView adWithoutView,
          RewardItem reward,
        ) async {
          if (rewardEarned) {
            return;
          }

          rewardEarned =
              true;

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

      _powerBoostAdFlowActive =
          false;

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
      _miningAdFlowActive =
          false;
    }

    if (purpose ==
        powerBoostPurpose) {
      _powerBoostAdFlowActive =
          false;
    }
  }

  // ============================================================
  // DISPOSE CURRENT AD
  // ============================================================

  void _disposeCurrentAd() {
    final RewardedAd? ad =
        _rewardedAd;

    _rewardedAd =
        null;

    _adReady =
        false;

    ad?.dispose();
  }

  // ============================================================
  // CLEAR CURRENT AD
  // ============================================================

  void clearCurrentAd() {
    _loadRequestId++;

    _disposeCurrentAd();

    _adLoading =
        false;

    _adLoadError =
        '';

    _rewardedAdPurpose =
        '';

    _notify();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _disposed =
        true;

    _loadRequestId++;

    _rewardedAd?.dispose();

    _rewardedAd =
        null;

    super.dispose();
  }
}