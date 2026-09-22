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
// onUserEarnedReward
//    ↓
// Cloud Function
//    ↓
// Google AdMob SSV
//    ↓
// Firestore admobRewards
//    ↓
// claimMining / powerBoost
//
// ============================================================
//
// IMPORTANT:
//
// AdMob SDK:n reward callback EI yksin hyväksy Stelluriinin
// rewardia.
//
// onUserEarnedReward kertoo vain, että Google Mobile Ads SDK
// ilmoitti rewardin ansaituksi.
//
// Varsinainen hyväksyntä tapahtuu backendissä.
//
// Tämä tiedosto EI yritä päätellä SSV:n onnistumista
// ajastimella.
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
  // 👤 AD USER BINDING
  // ============================================================
  //
  // SSV custom_data sisältää sen käyttäjän UID:n, joka oli
  // kirjautuneena mainoksen lataushetkellä.
  //
  // Säilytetään UID myös täällä, jotta sama ladattu mainos
  // voidaan näyttää vain samalle Firebase-käyttäjälle.
  //
  // Tämä estää tilanteen, jossa käyttäjä vaihtuu mainoksen
  // lataamisen ja näyttämisen välissä.
  //

  String _rewardedAdUserUid = '';

  // ============================================================
  // 🔒 FLOW STATE
  // ============================================================

  bool _miningAdFlowActive = false;

  bool _powerBoostAdFlowActive = false;

  // ============================================================
  // 🎁 REWARD CALLBACK STATE
  // ============================================================
  //
  // Estetään saman rewarded-mainoksen callbackin käsittely
  // useammin kuin kerran.
  //
  // Tämä EI ole SSV-varmistus.
  //
  // SSV-varmistus tapahtuu backendissä.
  //

  bool _miningRewardCallbackStarted = false;

  bool _powerBoostRewardCallbackStarted = false;

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
  // GET AD UNIT ID
  // ============================================================

  String _getAdUnitId(
    String purpose,
  ) {
    switch (purpose) {
      case powerBoostPurpose:
        return powerBoostRewardedAdUnitId;

      case miningStartPurpose:
      default:
        return miningRewardedAdUnitId;
    }
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

    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      debugPrint(
        '🐱 Cannot wait for rewarded ad: '
        'no authenticated Firebase user.',
      );

      return false;
    }

    if (_rewardedAd != null &&
        _adReady &&
        _rewardedAdPurpose == purpose &&
        _rewardedAdUserUid == currentUser.uid) {
      debugPrint(
        '🐱 Stelluriini Rewarded ad already ready: $purpose',
      );

      return true;
    }

    if (_rewardedAd != null &&
        (_rewardedAdPurpose != purpose ||
            _rewardedAdUserUid != currentUser.uid)) {
      debugPrint(
        '🐱 Existing Rewarded ad belongs to a different '
        'purpose or user. Replacing it.',
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
      _rewardedAdUserUid = '';

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
        Duration(milliseconds: 200);

    for (
      int check = 0;
      check < maxWaitChecks;
      check++
    ) {
      if (_disposed) {
        return false;
      }

      final User? activeUser = _auth.currentUser;

      if (activeUser == null) {
        return false;
      }

      if (_rewardedAd != null &&
          _adReady &&
          _rewardedAdPurpose == purpose &&
          _rewardedAdUserUid == activeUser.uid) {
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

    final User? finalUser = _auth.currentUser;

    final bool ready =
        !_disposed &&
        finalUser != null &&
        _rewardedAd != null &&
        _adReady &&
        _rewardedAdPurpose == purpose &&
        _rewardedAdUserUid == finalUser.uid;

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

    final User? user = _auth.currentUser;

    if (user == null) {
      debugPrint(
        '🐱 Cannot load rewarded ad: '
        'no authenticated Firebase user.',
      );

      _adLoading = false;
      _loadingPurpose = '';
      _adReady = false;
      _rewardedAdPurpose = '';
      _rewardedAdUserUid = '';

      _adLoadError =
          'NO_AUTH_USER | '
          'Purpose: $purpose';

      _notify();

      return;
    }

    if (_rewardedAd != null &&
        _adReady &&
        _rewardedAdPurpose == purpose &&
        _rewardedAdUserUid == user.uid) {
      debugPrint(
        '🐱 Stelluriini Rewarded ad already ready: $purpose',
      );

      return;
    }

    if (_adLoading) {
      if (_loadingPurpose == purpose) {
        debugPrint(
          '🐱 Rewarded ad loading already in progress: $purpose',
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

    if (_rewardedAd != null) {
      _disposeCurrentAd();
    }

    final int requestId = ++_loadRequestId;

    final String loadingUserUid = user.uid;

    _adLoading = true;
    _loadingPurpose = purpose;
    _adReady = false;
    _adLoadError = '';
    _rewardedAdPurpose = '';
    _rewardedAdUserUid = '';

    _notify();

    final String adUnitId =
        _getAdUnitId(purpose);

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
      'User UID length: ${loadingUserUid.length}',
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

          final User? activeUser = _auth.currentUser;

          if (activeUser == null ||
              activeUser.uid != loadingUserUid) {
            debugPrint(
              '🐱 Loaded Rewarded ad belongs to a user '
              'who is no longer active.',
            );

            ad.dispose();

            _rewardedAd = null;
            _adReady = false;
            _adLoading = false;
            _loadingPurpose = '';
            _rewardedAdPurpose = '';
            _rewardedAdUserUid = '';

            _adLoadError =
                'AUTH_USER_CHANGED | '
                'Purpose: $purpose';

            _notify();

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
                  '$loadingUserUid:$purpose',
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
            _rewardedAdUserUid = '';

            _adLoadError =
                'SSV_SETUP_FAILED | '
                'Purpose: $purpose | '
                'Ad Unit ID: $adUnitId | '
                'Error: $error';

            _notify();

            debugPrint(
              '🐱 SSV setup failure: '
              'user notification handled by ad manager state.',
            );

            return;
          }

          _rewardedAd = ad;
          _rewardedAdPurpose = purpose;
          _rewardedAdUserUid = loadingUserUid;
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
          _rewardedAdUserUid = '';

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

    final User? user = _auth.currentUser;

    if (user == null) {
      return;
    }

    if (_rewardedAd != null &&
        _adReady &&
        _rewardedAdUserUid == user.uid) {
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
  // 🎁 REWARD CALLBACK
  // ============================================================
  //
  // TÄRKEÄ:
  //
  // Tämä callback ei vahvista Stelluriinin rewardia.
  //
  // Se kertoo vain, että AdMob SDK ilmoitti rewardin
  // ansaituksi.
  //
  // Backend vastaa:
  //
  // 1. vastaanottaa Cloud Function -pyynnön
  // 2. tarkistaa SSV-tiedon
  // 3. tarkistaa rewardin tarkoituksen
  // 4. tarkistaa käyttäjän
  // 5. tarkistaa ettei rewardia ole käytetty aiemmin
  // 6. hyväksyy tai hylkää toiminnon
  //
  // ============================================================

  void _handleRewardEarned({
    required String purpose,
  }) {
    if (_disposed) {
      return;
    }

    if (purpose == miningStartPurpose) {
      if (_miningRewardCallbackStarted) {
        debugPrint(
          '🐱 Mining Start reward callback already started.',
        );

        return;
      }

      _miningRewardCallbackStarted = true;
    }

    if (purpose == powerBoostPurpose) {
      if (_powerBoostRewardCallbackStarted) {
        debugPrint(
          '🐱 Power Boost reward callback already started.',
        );

        return;
      }

      _powerBoostRewardCallbackStarted = true;
    }

    debugPrint(
      '==================================================',
    );

    debugPrint(
      '🐱 STELLURIINI ADMOB REWARD CALLBACK',
    );

    debugPrint(
      'Purpose: $purpose',
    );

    debugPrint(
      'AdMob SDK reward received.',
    );

    debugPrint(
      'Backend SSV verification is required.',
    );

    debugPrint(
      '==================================================',
    );

    unawaited(
      _executeRewardCallback(
        purpose: purpose,
      ),
    );
  }

  // ============================================================
  // 🔐 EXECUTE BACKEND REWARD CALLBACK
  // ============================================================

  Future<void> _executeRewardCallback({
    required String purpose,
  }) async {
    if (_disposed) {
      return;
    }

    try {
      if (purpose == miningStartPurpose) {
        await onMiningStartReward?.call();
      } else if (purpose == powerBoostPurpose) {
        await onPowerBoostReward?.call();
      }

      debugPrint(
        '🐱 Backend reward callback completed: $purpose',
      );
    } catch (error) {
      debugPrint(
        '🐱 Backend reward callback failed: $purpose',
      );

      debugPrint(
        '🐱 Error: $error',
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

    _miningRewardCallbackStarted = false;

    _adLoadError = '';

    _notify();

    try {
      final bool ready =
          await waitForRewardedAd(
        purpose: miningStartPurpose,
      );

      if (_disposed) {
        _miningAdFlowActive = false;
        return false;
      }

      if (!ready ||
          _rewardedAd == null ||
          !_adReady ||
          _rewardedAdPurpose !=
              miningStartPurpose ||
          _rewardedAdUserUid !=
              user.uid) {
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
      _rewardedAdUserUid = '';

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
        '${user.uid}:'
        '$miningStartPurpose',
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
            'Cloud Function will perform SSV verification.',
          );

          debugPrint(
            '==================================================',
          );

          _handleRewardEarned(
            purpose: miningStartPurpose,
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

    _powerBoostRewardCallbackStarted = false;

    _adLoadError = '';

    _notify();

    try {
      if (_rewardedAd != null &&
          (_rewardedAdPurpose !=
                  powerBoostPurpose ||
              _rewardedAdUserUid !=
                  user.uid)) {
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
        _powerBoostAdFlowActive = false;
        return false;
      }

      if (!ready ||
          _rewardedAd == null ||
          !_adReady ||
          _rewardedAdPurpose !=
              powerBoostPurpose ||
          _rewardedAdUserUid !=
              user.uid) {
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
      _rewardedAdUserUid = '';

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
        '${user.uid}:'
        '$powerBoostPurpose',
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
            'Cloud Function will perform SSV verification.',
          );

          debugPrint(
            '==================================================',
          );

          _handleRewardEarned(
            purpose: powerBoostPurpose,
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
    _rewardedAdUserUid = '';

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
    _rewardedAdUserUid = '';

    _miningRewardCallbackStarted = false;
    _powerBoostRewardCallbackStarted = false;

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