import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class HomeAdManager extends ChangeNotifier {
  // ============================================================
  // 🐱 STELLURIINI - HOME AD MANAGER
  // ============================================================
  //
  // AdMob Rewarded Ads
  //
  // TEST MODE:
  // Käytetään Googlen virallista test Rewarded Ad ID:tä
  // sekä Mining Startiin että Power Boostiin.
  //
  // SSV customData:
  //
  //     uid:purpose
  //
  // Esimerkiksi:
  //
  //     abc123:mining_start
  //     abc123:power_boost
  //
  // Backend:
  //
  //     adMobReward
  //
  // vastaanottaa SSV:n ja vahvistaa palkinnon.
  //
  // ============================================================

  // ============================================================
  // REAL ADMOB IDS
  // ============================================================
  //
  // Nämä jätetään talteen, jotta oikeat ID:t voidaan palauttaa
  // myöhemmin, kun AdMob-tilin rajoitus on poistunut.
  //
  // ÄLÄ KÄYTÄ NÄITÄ TESTIVERSIOSSA.
  //

  static const String miningRewardedAdUnitId =
      'ca-app-pub-1131012057145658/6674097787';

  static const String powerBoostRewardedAdUnitId =
      'ca-app-pub-1131012057145658/7225738491';

  // ============================================================
  // GOOGLE TEST REWARDED AD
  // ============================================================
  //
  // Googlen virallinen Rewarded Ad test ID.
  //
  // Tätä käytetään nyt KAIKISSA Rewarded Ads -mainoksissa.
  //

  static const String testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // ============================================================
  // PURPOSES
  // ============================================================

  static const String miningStartPurpose =
      'mining_start';

  static const String powerBoostPurpose =
      'power_boost';

  // ============================================================
  // CALLBACK
  // ============================================================

  void Function(String purpose)? onRewarded;

  // ============================================================
  // INTERNAL STATE
  // ============================================================

  RewardedAd? _rewardedAd;

  String? _loadedPurpose;

  String? _loadingPurpose;

  bool _isLoading = false;

  bool _isShowing = false;

  bool _disposed = false;

  String? _lastError;

  // Estää saman purpose-mainoksen käynnistymisen useita kertoja
  // samanaikaisesti.
  final Set<String> _loadingPurposes =
      <String>{};

  final Set<String> _showingPurposes =
      <String>{};

  // ============================================================
  // PUBLIC GETTERS
  // ============================================================

  bool get isLoading =>
      _isLoading;

  bool get isShowing =>
      _isShowing;

  bool get isReady =>
      _rewardedAd != null &&
      _loadedPurpose != null;

  String? get loadedPurpose =>
      _loadedPurpose;

  String? get lastError =>
      _lastError;

  // ============================================================
  // CURRENT USER
  // ============================================================

  String? get _uid {
    final user =
        FirebaseAuth.instance.currentUser;

    return user?.uid;
  }

  // ============================================================
  // ADMOB INITIALIZATION
  // ============================================================

  Future<void> initialize() async {
    if (_disposed) {
      return;
    }

    try {
      await MobileAds.instance.initialize();

      if (_disposed) {
        return;
      }

      debugPrint(
        '🐱 AdMob initialized.',
      );
    } catch (error) {
      debugPrint(
        '🐱 AdMob initialization error: $error',
      );
    }
  }

  // ============================================================
  // AD UNIT ID
  // ============================================================
  //
  // TÄRKEÄ:
  //
  // Testitilassa palautetaan aina Googlen test Rewarded Ad ID.
  //
  // Tämä tarkoittaa, että sekä:
  //
  //     Mining Start
  //
  // että:
  //
  //     Power Boost
  //
  // käyttävät samaa virallista testimainosta.
  //
  // ============================================================

  String _rewardedAdUnitIdForPurpose(
    String purpose,
  ) {
    return testRewardedAdUnitId;
  }

  // ============================================================
  // LOAD REWARDED AD
  // ============================================================

  Future<void> loadRewardedAd(
    String purpose,
  ) async {
    if (_disposed) {
      return;
    }

    final uid =
        _uid;

    if (uid == null ||
        uid.isEmpty) {
      _lastError =
          'User is not authenticated.';

      _safeNotify();

      debugPrint(
        '🐱 Cannot load Rewarded Ad: user not authenticated.',
      );

      return;
    }

    if (purpose != miningStartPurpose &&
        purpose != powerBoostPurpose) {
      _lastError =
          'Invalid Rewarded Ad purpose.';

      _safeNotify();

      debugPrint(
        '🐱 Invalid Rewarded Ad purpose: $purpose',
      );

      return;
    }

    // Jos juuri sama mainos on jo ladattu, ei ladata uudelleen.
    if (_rewardedAd != null &&
        _loadedPurpose == purpose) {
      debugPrint(
        '🐱 Rewarded Ad already loaded: $purpose',
      );

      return;
    }

    // Estetään useampi samanaikainen lataus.
    if (_loadingPurposes.contains(purpose)) {
      debugPrint(
        '🐱 Rewarded Ad already loading: $purpose',
      );

      return;
    }

    _loadingPurposes.add(
      purpose,
    );

    _isLoading = true;

    _loadingPurpose =
        purpose;

    _lastError = null;

    _safeNotify();

    final adUnitId =
        _rewardedAdUnitIdForPurpose(
      purpose,
    );

    debugPrint(
      '🐱 Loading TEST Rewarded Ad.',
    );

    debugPrint(
      '🐱 Purpose: $purpose',
    );

    debugPrint(
      '🐱 Test Ad Unit ID: $adUnitId',
    );

    try {
      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback:
            RewardedAdLoadCallback(
          onAdLoaded:
              (
                RewardedAd ad,
              ) {
            if (_disposed) {
              ad.dispose();

              _loadingPurposes.remove(
                purpose,
              );

              return;
            }

            // Jos jokin vanha mainos on vielä muistissa,
            // vapautetaan se ennen uuden asettamista.
            _rewardedAd?.dispose();

            _rewardedAd =
                ad;

            _loadedPurpose =
                purpose;

            _loadingPurpose =
                null;

            _isLoading =
                false;

            _loadingPurposes.remove(
              purpose,
            );

            _lastError =
                null;

            debugPrint(
              '🐱 Rewarded Ad loaded successfully.',
            );

            debugPrint(
              '🐱 Purpose: $purpose',
            );

            _safeNotify();
          },
          onAdFailedToLoad:
              (
                LoadAdError error,
              ) {
            _rewardedAd?.dispose();

            _rewardedAd =
                null;

            _loadedPurpose =
                null;

            _loadingPurpose =
                null;

            _isLoading =
                false;

            _loadingPurposes.remove(
              purpose,
            );

            _lastError =
                error.message;

            debugPrint(
              '🐱 Rewarded Ad failed to load.',
            );

            debugPrint(
              '🐱 Purpose: $purpose',
            );

            debugPrint(
              '🐱 Error: $error',
            );

            _safeNotify();
          },
        ),
      );
    } catch (error) {
      _rewardedAd?.dispose();

      _rewardedAd =
          null;

      _loadedPurpose =
          null;

      _loadingPurpose =
          null;

      _isLoading =
          false;

      _loadingPurposes.remove(
        purpose,
      );

      _lastError =
          error.toString();

      debugPrint(
        '🐱 Rewarded Ad load exception: $error',
      );

      _safeNotify();
    }
  }

  // ============================================================
  // SHOW REWARDED AD
  // ============================================================

  Future<bool> showRewardedAd(
    String purpose,
  ) async {
    if (_disposed) {
      return false;
    }

    final uid =
        _uid;

    if (uid == null ||
        uid.isEmpty) {
      debugPrint(
        '🐱 Cannot show Rewarded Ad: user not authenticated.',
      );

      return false;
    }

    if (purpose != miningStartPurpose &&
        purpose != powerBoostPurpose) {
      debugPrint(
        '🐱 Invalid Rewarded Ad purpose: $purpose',
      );

      return false;
    }

    if (_isShowing) {
      debugPrint(
        '🐱 Rewarded Ad is already showing.',
      );

      return false;
    }

    final ad =
        _rewardedAd;

    if (ad == null ||
        _loadedPurpose != purpose) {
      debugPrint(
        '🐱 Rewarded Ad is not ready for purpose: $purpose',
      );

      // Yritetään ladata oikea mainos seuraavaa yritystä varten.
      unawaited(
        loadRewardedAd(
          purpose,
        ),
      );

      return false;
    }

    _rewardedAd =
        null;

    _loadedPurpose =
        null;

    _isShowing =
        true;

    _showingPurposes.add(
      purpose,
    );

    _safeNotify();

    bool rewardEarned =
        false;

    bool completed =
        false;

    final completer =
        Completer<bool>();

    // ----------------------------------------------------------
    // SERVER SIDE VERIFICATION
    // ----------------------------------------------------------
    //
    // customData:
    //
    //     uid:purpose
    //
    // Backend adMobReward käyttää tätä tietoa.
    //

    final customData =
        '$uid:$purpose';

    try {
      ad.setServerSideVerificationOptions(
        ServerSideVerificationOptions(
          customData:
              customData,
        ),
      );
    } catch (error) {
      debugPrint(
        '🐱 Failed to set SSV options: $error',
      );
    }

    // ----------------------------------------------------------
    // FULLSCREEN CALLBACK
    // ----------------------------------------------------------

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdShowedFullScreenContent:
          (
            RewardedAd ad,
          ) {
        debugPrint(
          '🐱 Rewarded Ad shown.',
        );

        debugPrint(
          '🐱 Purpose: $purpose',
        );
      },
      onAdDismissedFullScreenContent:
          (
            RewardedAd ad,
          ) {
        debugPrint(
          '🐱 Rewarded Ad dismissed.',
        );

        ad.dispose();

        _finishShowing(
          purpose,
          rewardEarned,
          completer,
        );
      },
      onAdFailedToShowFullScreenContent:
          (
            RewardedAd ad,
            AdError error,
          ) {
        debugPrint(
          '🐱 Rewarded Ad failed to show.',
        );

        debugPrint(
          '🐱 Error: $error',
        );

        ad.dispose();

        _finishShowing(
          purpose,
          false,
          completer,
        );
      },
      onAdImpression:
          (
            RewardedAd ad,
          ) {
        debugPrint(
          '🐱 Rewarded Ad impression.',
        );
      },
      onAdClicked:
          (
            RewardedAd ad,
          ) {
        debugPrint(
          '🐱 Rewarded Ad clicked.',
        );
      },
      onAdWillDismissFullScreenContent:
          (
            RewardedAd ad,
          ) {
        debugPrint(
          '🐱 Rewarded Ad will dismiss.',
        );
      },
    );

    // ----------------------------------------------------------
    // SHOW
    // ----------------------------------------------------------

    try {
      ad.show(
        onUserEarnedReward:
            (
              AdWithoutView ad,
              RewardItem reward,
            ) {
          rewardEarned =
              true;

          debugPrint(
            '🐱 Reward earned.',
          );

          debugPrint(
            '🐱 Purpose: $purpose',
          );

          debugPrint(
            '🐱 Reward amount: ${reward.amount}',
          );

          debugPrint(
            '🐱 Reward type: ${reward.type}',
          );

          if (onRewarded != null) {
            try {
              onRewarded!(
                purpose,
              );
            } catch (error) {
              debugPrint(
                '🐱 onRewarded callback error: $error',
              );
            }
          }
        },
      );
    } catch (error) {
      debugPrint(
        '🐱 Rewarded Ad show exception: $error',
      );

      try {
        ad.dispose();
      } catch (_) {}

      _finishShowing(
        purpose,
        false,
        completer,
      );
    }

    return completer.future;
  }

  // ============================================================
  // FINISH SHOWING
  // ============================================================

  void _finishShowing(
    String purpose,
    bool rewardEarned,
    Completer<bool> completer,
  ) {
    if (completedOrFinished(
      completer,
    )) {
      return;
    }

    _isShowing =
        false;

    _showingPurposes.remove(
      purpose,
    );

    _safeNotify();

    // ----------------------------------------------------------
    // Lataa seuraava testimainos automaattisesti.
    // ----------------------------------------------------------

    unawaited(
      loadRewardedAd(
        purpose,
      ),
    );

    if (!completer.isCompleted) {
      completer.complete(
        rewardEarned,
      );
    }
  }

  // ============================================================
  // COMPLETER SAFETY
  // ============================================================

  bool completedOrFinished(
    Completer<bool> completer,
  ) {
    return completer.isCompleted;
  }

  // ============================================================
  // PRELOAD
  // ============================================================

  Future<void> preload(
    String purpose,
  ) async {
    if (_disposed) {
      return;
    }

    if (_rewardedAd != null &&
        _loadedPurpose == purpose) {
      return;
    }

    await loadRewardedAd(
      purpose,
    );
  }

  // ============================================================
  // PRELOAD BOTH
  // ============================================================

  Future<void> preloadBoth() async {
    if (_disposed) {
      return;
    }

    await Future.wait(
      <Future<void>>[
        preload(
          miningStartPurpose,
        ),
        preload(
          powerBoostPurpose,
        ),
      ],
    );
  }

  // ============================================================
  // CONVENIENCE METHODS
  // ============================================================

  Future<bool> showMiningStartAd() {
    return showRewardedAd(
      miningStartPurpose,
    );
  }

  Future<bool> showPowerBoostAd() {
    return showRewardedAd(
      powerBoostPurpose,
    );
  }

  // ============================================================
  // DISPOSE CURRENT AD
  // ============================================================

  void disposeRewardedAd() {
    try {
      _rewardedAd?.dispose();
    } catch (_) {}

    _rewardedAd =
        null;

    _loadedPurpose =
        null;

    _loadingPurpose =
        null;

    _isLoading =
        false;

    _safeNotify();
  }

  // ============================================================
  // SAFE NOTIFY
  // ============================================================

  void _safeNotify() {
    if (_disposed) {
      return;
    }

    try {
      notifyListeners();
    } catch (error) {
      debugPrint(
        '🐱 notifyListeners error: $error',
      );
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _disposed =
        true;

    _loadingPurposes.clear();

    _showingPurposes.clear();

    try {
      _rewardedAd?.dispose();
    } catch (_) {}

    _rewardedAd =
        null;

    _loadedPurpose =
        null;

    _loadingPurpose =
        null;

    _isLoading =
        false;

    _isShowing =
        false;

    super.dispose();
  }
}