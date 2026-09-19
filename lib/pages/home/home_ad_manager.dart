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
  // LOAD POWER BOOST AD IN BACKGROUND
  // ============================================================
  //
  // Power Boost -mainos voidaan valmistella etukäteen.
  //
  // Tämä tarkoittaa, ettei käyttäjän tarvitse odottaa koko
  // RewardedAd.load()-prosessia vasta painikkeen painamisen
  // jälkeen.
  //
  // ============================================================

  void preloadPowerBoostAd() {
    if (_disposed) {
      return;
    }

    if (_rewardedAd != null &&
        _adReady &&
        _rewardedAdPurpose == powerBoostPurpose) {
      debugPrint(
        '🐱 Power Boost ad already preloaded.',
      );

      return;
    }

    if (_adLoading) {
      debugPrint(
        '🐱 Ad preload already in progress: '
        '$_loadingPurpose',
      );

      return;
    }

    unawaited(
      loadRewardedAd(
        purpose: powerBoostPurpose,
        notifyOnLoadError: false,
      ),
    );
  }

  // ============================================================
  // LOAD MINING START AD IN BACKGROUND
  // ============================================================

  void preloadMiningStartAd() {
    if (_disposed) {
      return;
    }

    if (_rewardedAd != null &&
        _adReady &&
        _rewardedAdPurpose == miningStartPurpose) {
      debugPrint(
        '🐱 Mining Start ad already preloaded.',
      );

      return;
    }

    if (_adLoading) {
      debugPrint(
        '🐱 Ad preload already in progress: '
        '$_loadingPurpose',
      );

      return;
    }

    unawaited(
      loadRewardedAd(
        purpose: miningStartPurpose,
        notifyOnLoadError: false,
      ),
    );
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

    if (_rewardedAd != null &&
        _adReady &&
        _rewardedAdPurpose == purpose) {
      debugPrint(
        '🐱 Stelluriini Rewarded ad already ready: $purpose',
      );

      return true;
    }

    if (_rewardedAd != null &&
        _rewardedAdPurpose != purpose) {
      debugPrint(
        '🐱 Different Rewarded ad is loaded. '
        'Replacing it with: $purpose',
      );

      _disposeCurrentAd();
    }

    if (_adLoading &&
        _loadingPurpose != purpose) {
      debugPrint(
        '🐱 Different Rewarded ad is currently loading. '
        'Switching to: $purpose',
      );

      _loadRequestId++;

      _adLoading = false;
      _loadingPurpose = '';

      _rewardedAd = null;
      _adReady = false;
      _rewardedAdPurpose = '';

      _notify();
    }

    if (!_adLoading) {
      await loadRewardedAd(
        purpose: purpose,
        notifyOnLoadError: true,
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

    if (_rewardedAd != null &&
        _adReady &&
        _rewardedAdPurpose == purpose) {
      debugPrint(
        '🐱 Stelluriini Rewarded ad already ready: $purpose',
      );

      return;
    }

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

      _adLoadError =
          'NO_AUTH_USER | '
          'Purpose: $purpose';

      _notify();

      return;
    }

    if (_rewardedAd != null) {
      _disposeCurrentAd();
    }

    final int requestId =
        ++_loadRequestId;

    _adLoading = true;
    _loadingPurpose = purpose;
    _adReady = false;
    _adLoadError = '';
    _rewardedAdPurpose = purpose;

    _notify();

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

    try {
      RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback:
            RewardedAdLoadCallback(
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
              _rewardedAdPurpose = '';

              _adLoadError =
                  'SSV_SETUP_FAILED | '
                  'Purpose: $purpose | '
                  'Ad Unit ID: $adUnitId | '
                  'Error: $error';

              _notify();

              return;
            }

            _rewardedAd = ad;
            _rewardedAdPurpose = purpose;
            _adReady = true;
            _adLoading = false;
            _loadingPurpose = '';
            _adLoadError = '';

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

                if (!_disposed) {
                  unawaited(
                    _reloadAfterDismiss(
                      purpose,
                    ),
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
                    _reloadAfterDismiss(
                      purpose,
                    ),
                  );
                }
              },
            );

            _notify();
          },

          onAdFailedToLoad: (
            LoadAdError error,
          ) {
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
            _rewardedAdPurpose = '';

            _adLoadError =
                detailedError;

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
        },
      );
    } catch (error) {
      if (_disposed) {
        return;
      }

      if (requestId != _loadRequestId) {
        return;
      }

      _rewardedAd = null;
      _adReady = false;
      _adLoading = false;
      _loadingPurpose = '';
      _rewardedAdPurpose = '';

      _adLoadError =
          'LOAD_EXCEPTION | '
          'Purpose: $purpose | '
          'Ad Unit ID: $adUnitId | '
          'Error: $error';

      debugPrint(
        '==================================================',
      );

      debugPrint(
        '🐱 STELLURIINI ADMOB LOAD EXCEPTION',
      );

      debugPrint(
        'Purpose: $purpose',
      );

      debugPrint(
        'Ad Unit ID: $adUnitId',
      );

      debugPrint(
        'Error: $error',
      );

      debugPrint(
        '==================================================',
      );

      _notify();

      if (notifyOnLoadError) {
        debugPrint(
          '🐱 Rewarded ad load exception occurred.',
        );
      }
    }
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

    if (_rewardedAd != null &&
        _adReady) {
      return;
    }

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
  // 🛡️ DELAYED REWARD CALLBACK
  // ============================================================

  void _scheduleVerifiedRewardCallback({
    required String purpose,
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

          debugPrint(
            '🐱 Firebase reward callback completed: '
            '$purpose',
          );
        } catch (error) {
          debugPrint(
            '🐱 Firebase reward callback failed: '
            '$purpose',
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

        debugPrint(
          '🐱 Mining Start ad was not ready.',
        );

        debugPrint(
          'Last AdMob error: $_adLoadError',
        );

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

      try {
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
            );
          },
        );

        return true;
      } catch (error) {
        debugPrint(
          '==================================================',
        );

        debugPrint(
          '🐱 STELLURIINI MINING START SHOW EXCEPTION',
        );

        debugPrint(
          'Error: $error',
        );

        debugPrint(
          '==================================================',
        );

        ad.dispose();

        _miningAdFlowActive = false;

        _adReady = false;
        _rewardedAd = null;
        _rewardedAdPurpose = '';

        _adLoadError =
            'SHOW_EXCEPTION | '
            'Purpose: $miningStartPurpose | '
            'Ad Unit ID: $miningRewardedAdUnitId | '
            'Error: $error';

        _notify();

        return false;
      }
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
      if (_rewardedAd != null &&
          _rewardedAdPurpose !=
              powerBoostPurpose) {
        _disposeCurrentAd();
      }

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

        debugPrint(
          '🐱 Power Boost ad was not ready.',
        );

        debugPrint(
          'Last AdMob error: $_adLoadError',
        );

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

      try {
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
            );
          },
        );

        return true;
      } catch (error) {
        debugPrint(
          '==================================================',
        );

        debugPrint(
          '🐱 STELLURIINI POWER BOOST SHOW EXCEPTION',
        );

        debugPrint(
          'Error: $error',
        );

        debugPrint(
          '==================================================',
        );

        ad.dispose();

        _powerBoostAdFlowActive = false;

        _adReady = false;
        _rewardedAd = null;
        _rewardedAdPurpose = '';

        _adLoadError =
            'SHOW_EXCEPTION | '
            'Purpose: $powerBoostPurpose | '
            'Ad Unit ID: $powerBoostRewardedAdUnitId | '
            'Error: $error';

        _notify();

        return false;
      }
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