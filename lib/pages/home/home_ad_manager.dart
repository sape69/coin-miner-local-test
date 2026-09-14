import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// ============================================================
// 🐱 STELLURIINI HOME AD MANAGER
// ============================================================
//
// Tämä luokka hallitsee HomePagen Rewarded Ad -toimintoja.
//
// HomePage vastaa:
//   • Mining Start -toiminnon backend-logiikasta
//   • Power Boost -toiminnon backend-logiikasta
//   • käyttöliittymästä
//
// Tämä luokka vastaa:
//   • RewardedAd-olion hallinnasta
//   • mainoksen lataamisesta
//   • mainoksen odottamisesta
//   • SSV customData -asetuksesta
//   • mainoksen näyttämisestä
//   • mainoksen sulkemisesta
//   • AdMob-virheistä
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
  //
  // HomePage saa näiden kautta tiedon siitä,
  // mitä mainoksen jälkeen tapahtui.
  //
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
  // 📺 REWARDED AD STATE
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
  // 📖 PUBLIC STATE
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
  // 🧹 NOTIFY SAFELY
  // ============================================================

  void _notify() {
    notifyListeners();
  }

  // ============================================================
  // 📺 WAIT FOR REWARDED AD
  // ============================================================

  Future<bool> waitForRewardedAd({
    required String purpose,
  }) async {
    if (_rewardedAd != null &&
        _adReady &&
        _rewardedAdPurpose == purpose) {
      debugPrint(
        'Rewarded ad already ready for $purpose.',
      );

      return true;
    }

    await loadRewardedAd(
      purpose: purpose,
    );

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
  // 📺 LOAD REWARDED AD
  // ============================================================

  Future<void> loadRewardedAd({
    required String purpose,
  }) async {
    // ----------------------------------------------------------
    // Älä käynnistä useita latauksia samaan aikaan.
    // ----------------------------------------------------------

    if (_adLoading) {
      debugPrint(
        'Ad load already in progress. '
        'Requested purpose: $purpose',
      );

      return;
    }

    // ----------------------------------------------------------
    // Jos oikea mainos on jo ladattu, käytetään sitä.
    // ----------------------------------------------------------

    if (_rewardedAd != null &&
        _adReady &&
        _rewardedAdPurpose == purpose) {
      debugPrint(
        'Rewarded ad already ready: $purpose',
      );

      return;
    }

    // ----------------------------------------------------------
    // Jos tarkoitus vaihtuu, vanha mainos vapautetaan.
    // ----------------------------------------------------------

    if (_rewardedAd != null &&
        _rewardedAdPurpose != purpose) {
      debugPrint(
        'Disposing old rewarded ad. '
        'Old purpose: $_rewardedAdPurpose, '
        'new purpose: $purpose',
      );

      _rewardedAd?.dispose();

      _rewardedAd = null;

      _adReady = false;
    }

    // ----------------------------------------------------------
    // Firebase-käyttäjä tarvitaan SSV customDataa varten.
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
    // Aloita lataus.
    // ----------------------------------------------------------

    _adLoading = true;

    _adLoadError = '';

    _notify();

    debugPrint(
      '==================================================',
    );

    debugPrint(
      'STELLURIINI ADMOB LOAD START',
    );

    debugPrint(
      'PRODUCTION REWARDED AD UNIT: '
      '$rewardedAdUnitId',
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
      adUnitId:
          rewardedAdUnitId,
      request:
          const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        // ======================================================
        // ✅ AD LOADED
        // ======================================================

        onAdLoaded: (
          RewardedAd ad,
        ) {
          debugPrint(
            '==================================================',
          );

          debugPrint(
            'STELLURIINI ADMOB LOAD SUCCESS',
          );

          debugPrint(
            'PRODUCTION REWARDED AD',
          );

          debugPrint(
            'Purpose: $purpose',
          );

          debugPrint(
            '==================================================',
          );

          // ----------------------------------------------------
          // Manager voi olla jo poistettu.
          // ----------------------------------------------------

          if (_disposed) {
            ad.dispose();

            return;
          }

          // ----------------------------------------------------
          // Aseta AdMob SSV custom data.
          //
          // Esimerkiksi:
          //
          // UID:power_boost
          //
          // tai
          //
          // UID:mining_start
          //
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

            _rewardedAd = null;

            _adReady = false;

            _adLoading = false;

            _adLoadError =
                'SSV_SETUP_FAILED: $error';

            _notify();

            return;
          }

          // ----------------------------------------------------
          // Tallenna valmis mainos.
          // ----------------------------------------------------

          _rewardedAd = ad;

          _rewardedAdPurpose =
              purpose;

          _adReady = true;

          _adLoading = false;

          _adLoadError = '';

          // ----------------------------------------------------
          // Full screen callbackit.
          // ----------------------------------------------------

          ad.fullScreenContentCallback =
              FullScreenContentCallback(
            // ==================================================
            // AD SHOWN
            // ==================================================

            onAdShowedFullScreenContent:
                (
              RewardedAd showedAd,
            ) {
              debugPrint(
                'Rewarded production ad showed: '
                '$purpose',
              );
            },

            // ==================================================
            // AD DISMISSED
            // ==================================================

            onAdDismissedFullScreenContent:
                (
              RewardedAd dismissedAd,
            ) {
              debugPrint(
                'Rewarded production ad dismissed: '
                '$purpose',
              );

              dismissedAd.dispose();

              if (identical(
                _rewardedAd,
                dismissedAd,
              )) {
                _rewardedAd = null;

                _adReady = false;
              }

              // ------------------------------------------------
              // Vapauta flow-tila.
              // ------------------------------------------------

              if (purpose ==
                  miningStartPurpose) {
                _miningAdFlowActive =
                    false;
              } else if (purpose ==
                  powerBoostPurpose) {
                _powerBoostAdFlowActive =
                    false;
              }

              _notify();

              // ------------------------------------------------
              // Ilmoita HomePagelle.
              // ------------------------------------------------

              onAdDismissed?.call(
                purpose,
              );

              // ------------------------------------------------
              // Seuraava mainos ladataan vasta
              // nykyisen mainoksen sulkemisen jälkeen.
              //
              // Power Boost on seuraava oletusmainos.
              // ------------------------------------------------

              Future<void>.delayed(
                Duration.zero,
                () async {
                  if (_disposed) {
                    return;
                  }

                  await loadRewardedAd(
                    purpose:
                        powerBoostPurpose,
                  );
                },
              );
            },

            // ==================================================
            // AD SHOW FAILED
            // ==================================================

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

              if (purpose ==
                  miningStartPurpose) {
                _miningAdFlowActive =
                    false;
              } else if (purpose ==
                  powerBoostPurpose) {
                _powerBoostAdFlowActive =
                    false;
              }

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
              // Yritetään ladata seuraava mainos.
              // ------------------------------------------------

              Future<void>.delayed(
                Duration.zero,
                () async {
                  if (_disposed) {
                    return;
                  }

                  await loadRewardedAd(
                    purpose:
                        powerBoostPurpose,
                  );
                },
              );
            },
          );

          _notify();
        },

        // ======================================================
        // ❌ AD LOAD FAILED
        // ======================================================

        onAdFailedToLoad: (
          LoadAdError error,
        ) {
          final String detailedError =
              'Code: ${error.code}\n'
              'Domain: ${error.domain}\n'
              'Message: ${error.message}';

          debugPrint(
            '==================================================',
          );

          debugPrint(
            'STELLURIINI ADMOB PRODUCTION LOAD FAILED',
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
            'Response info: '
            '${error.responseInfo}',
          );

          debugPrint(
            '==================================================',
          );

          _rewardedAd = null;

          _adReady = false;

          _adLoading = false;

          _adLoadError =
              detailedError;

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

          _notify();

          onAdLoadError?.call(
            purpose,
            error,
          );

          // ----------------------------------------------------
          // TÄRKEÄ:
          //
          // Ei automaattista latauslooppiä.
          //
          // Seuraava käyttäjän painallus tekee uuden yrityksen.
          // ----------------------------------------------------

          debugPrint(
            'No automatic AdMob reload '
            'after load failure.',
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
        _miningAdFlowActive =
            false;

        _notify();

        return false;
      }

      final RewardedAd ad =
          _rewardedAd!;

      _rewardedAd = null;

      _adReady = false;

      _notify();

      bool rewardEarned =
          false;

      debugPrint(
        'Showing Mining Start rewarded ad.',
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
            'Mining Start client reward '
            'callback received.',
          );

          try {
            if (onMiningStartReward !=
                null) {
              await onMiningStartReward!();
            }
          } catch (error) {
            debugPrint(
              'Mining Start reward callback '
              'error: $error',
            );
          }
        },
      );

      return true;
    } catch (error) {
      debugPrint(
        'Start Mining ad flow error: $error',
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

    _powerBoostAdFlowActive =
        true;

    _adLoadError = '';

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

      _rewardedAd = null;

      _adReady = false;

      _notify();

      bool rewardProcessed =
          false;

      debugPrint(
        'Showing Power Boost rewarded ad.',
      );

      ad.show(
        onUserEarnedReward: (
          AdWithoutView adWithoutView,
          RewardItem reward,
        ) async {
          if (rewardProcessed) {
            return;
          }

          rewardProcessed = true;

          debugPrint(
            'Power Boost client reward '
            'callback received.',
          );

          try {
            if (onPowerBoostReward !=
                null) {
              await onPowerBoostReward!();
            }
          } catch (error) {
            debugPrint(
              'Power Boost reward callback '
              'error: $error',
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
  // 🔄 CLEAR CURRENT AD
  // ============================================================

  void clearCurrentAd() {
    _rewardedAd?.dispose();

    _rewardedAd = null;

    _adReady = false;

    _adLoading = false;

    _adLoadError = '';

    _notify();
  }

  // ============================================================
  // 🧹 DISPOSE STATE
  // ============================================================

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;

    _rewardedAd?.dispose();

    _rewardedAd = null;

    super.dispose();
  }
}