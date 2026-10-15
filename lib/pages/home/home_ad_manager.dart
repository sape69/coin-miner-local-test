import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class HomeAdManager extends ChangeNotifier {
  // ============================================================
  // 🐱 STELLURIINI - ADMOB MANAGER
  // ============================================================
  //
  // AdMob Rewarded Ad ei anna STL-tokenia.
  //
  // AdMob toimii vain hyväksyntänä:
  //
  // 1. Mining Start
  // 2. Power Boost
  //
  // Lopullinen oikeutus tarkistetaan Firebase Functionsissa
  // AdMob Server-Side Verificationin kautta.
  //
  // ============================================================

  // ============================================================
  // 📺 ADMOB AD UNITS
  // ============================================================

  static const String miningRewardedAdUnitId =
      'ca-app-pub-1131012057145658/6674097787';

  static const String powerBoostRewardedAdUnitId =
      'ca-app-pub-1131012057145658/7225738491';

  static const String miningStartPurpose =
      'mining_start';

  static const String powerBoostPurpose =
      'power_boost';

  // ============================================================
  // ⏱️ TIMING
  // ============================================================

  static const Duration adLoadTimeout =
      Duration(seconds: 20);

  static const Duration adReadyTimeout =
      Duration(seconds: 20);

  static const Duration adCheckInterval =
      Duration(milliseconds: 200);

  static const Duration reloadDelay =
      Duration(seconds: 3);

  // ============================================================
  // 🔁 AUTOMATIC RETRY
  // ============================================================

  static const int maxAdLoadAttempts = 3;

  static const Duration adRetryDelay =
      Duration(milliseconds: 700);

  // ============================================================
  // 🔥 FIREBASE AUTH
  // ============================================================

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // 🔔 CALLBACKS
  // ============================================================

  final Future<void> Function()?
      onMiningStartReward;

  final Future<void> Function()?
      onPowerBoostReward;

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
  // 🔐 UMP CONSENT
  // ============================================================

  bool _canRequestAds = false;

  bool _consentCheckCompleted = false;

  Future<bool>? _consentCheckFuture;

  // ============================================================
  // 🔒 UMP PRIVACY OPTIONS
  // ============================================================

  bool _privacyOptionsRequired = false;

  // ============================================================
  // 🔒 FLOW PROTECTION
  // ============================================================

  bool _miningAdFlowActive = false;

  bool _powerBoostAdFlowActive = false;

  bool _miningRewardCallbackStarted = false;

  bool _powerBoostRewardCallbackStarted = false;

  bool _disposed = false;

  int _loadRequestId = 0;

  // ============================================================
  // 📺 ADMOB INITIALIZATION
  // ============================================================

  static Future<InitializationStatus>?
      _mobileAdsInitialization;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  HomeAdManager({
    this.onMiningStartReward,
    this.onPowerBoostReward,
    this.onAdLoadError,
    this.onAdShowError,
    this.onAdDismissed,
  }) {
    debugPrint(
      '🐱 [ADMOB] HomeAdManager created.',
    );

    unawaited(
      _initializeAndPreload(),
    );
  }

  // ============================================================
  // GETTERS
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

  bool get canRequestAds =>
      _canRequestAds;

  bool get consentCheckCompleted =>
      _consentCheckCompleted;

  bool get privacyOptionsRequired =>
      _privacyOptionsRequired;

  // ============================================================
  // 🔔 NOTIFY
  // ============================================================

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  // ============================================================
  // 🔐 UMP CONSENT
  // ============================================================

  Future<bool> _checkAdConsent() async {
    if (_disposed) {
      return false;
    }

    final Future<bool>? existing =
        _consentCheckFuture;

    if (existing != null) {
      return existing;
    }

    final Future<bool> future =
        _performConsentCheck();

    _consentCheckFuture =
        future;

    try {
      return await future;
    } finally {
      if (identical(
        _consentCheckFuture,
        future,
      )) {
        _consentCheckFuture = null;
      }
    }
  }

  Future<bool> _performConsentCheck() async {
    if (_disposed) {
      return false;
    }

    try {
      debugPrint(
        '🐱 [ADMOB] UMP consent check started.',
      );

      final ConsentRequestParameters params =
          ConsentRequestParameters();

      final Completer<void> updateCompleter =
          Completer<void>();

      ConsentInformation.instance
          .requestConsentInfoUpdate(
        params,
        () {
          if (!updateCompleter.isCompleted) {
            updateCompleter.complete();
          }
        },
        (FormError error) {
          if (!updateCompleter.isCompleted) {
            updateCompleter.completeError(
              error,
            );
          }
        },
      );

      await updateCompleter.future;

      if (_disposed) {
        return false;
      }

      // ========================================================
      // 🔒 PRIVACY OPTIONS REQUIREMENT
      // ========================================================

      final PrivacyOptionsRequirementStatus
          privacyOptionsStatus =
          await ConsentInformation
              .instance
              .getPrivacyOptionsRequirementStatus();

      _privacyOptionsRequired =
          privacyOptionsStatus ==
              PrivacyOptionsRequirementStatus.required;

      debugPrint(
        '🐱 [ADMOB] Privacy options required: '
        '$_privacyOptionsRequired',
      );

      // ========================================================
      // 📋 SHOW REQUIRED CONSENT FORM
      // ========================================================

      final Completer<FormError?>
          formCompleter =
          Completer<FormError?>();

      ConsentForm
          .loadAndShowConsentFormIfRequired(
        (
          FormError? error,
        ) {
          if (!formCompleter.isCompleted) {
            formCompleter.complete(error);
          }
        },
      );

      final FormError? formError =
          await formCompleter.future;

      if (formError != null) {
        debugPrint(
          '⚠️ [ADMOB] UMP form error: '
          '${formError.errorCode} '
          '${formError.message}',
        );
      }

      if (_disposed) {
        return false;
      }

      final bool canRequest =
          await ConsentInformation
              .instance
              .canRequestAds();

      if (_disposed) {
        return false;
      }

      _canRequestAds =
          canRequest;

      _consentCheckCompleted =
          true;

      debugPrint(
        canRequest
            ? '✅ [ADMOB] Ad requests allowed.'
            : '⚠️ [ADMOB] Ad requests not allowed.',
      );

      _notify();

      return canRequest;
    } catch (error) {
      debugPrint(
        '❌ [ADMOB] Consent check failed: '
        '$error',
      );

      if (_disposed) {
        return false;
      }

      _privacyOptionsRequired =
          false;

      try {
        final bool canRequest =
            await ConsentInformation
                .instance
                .canRequestAds();

        _canRequestAds =
            canRequest;

        _consentCheckCompleted =
            true;

        if (canRequest) {
          _notify();

          return true;
        }
      } catch (fallbackError) {
        debugPrint(
          '❌ [ADMOB] Consent fallback failed: '
          '$fallbackError',
        );
      }

      _canRequestAds = false;

      _consentCheckCompleted = true;

      _adLoadError =
          'CONSENT_CHECK_FAILED | $error';

      _notify();

      return false;
    }
  }

  // ============================================================
  // 🔒 SHOW PRIVACY OPTIONS
  // ============================================================

  void showPrivacyOptionsForm() {
    if (_disposed) {
      return;
    }

    if (!_privacyOptionsRequired) {
      debugPrint(
        '🐱 [ADMOB] Privacy options form is not required.',
      );

      return;
    }

    debugPrint(
      '🐱 [ADMOB] Opening privacy options form.',
    );

    unawaited(
      ConsentForm.showPrivacyOptionsForm(
        (
          FormError? formError,
        ) {
          if (formError != null) {
            debugPrint(
              '❌ [ADMOB] Privacy options form error: '
              '${formError.errorCode} '
              '${formError.message}',
            );
          } else {
            debugPrint(
              '✅ [ADMOB] Privacy options form dismissed.',
            );
          }

          if (!_disposed) {
            unawaited(
              _refreshConsentAfterPrivacyOptions(),
            );
          }
        },
      ),
    );
  }

  // ============================================================
  // 🔄 REFRESH CONSENT AFTER PRIVACY OPTIONS
  // ============================================================

  Future<void> _refreshConsentAfterPrivacyOptions() async {
    if (_disposed) {
      return;
    }

    try {
      final bool canRequest =
          await ConsentInformation
              .instance
              .canRequestAds();

      if (_disposed) {
        return;
      }

      final PrivacyOptionsRequirementStatus
          privacyOptionsStatus =
          await ConsentInformation
              .instance
              .getPrivacyOptionsRequirementStatus();

      _canRequestAds =
          canRequest;

      _privacyOptionsRequired =
          privacyOptionsStatus ==
              PrivacyOptionsRequirementStatus.required;

      _consentCheckCompleted =
          true;

      _disposeCurrentAd();

      _notify();

      if (canRequest) {
        final User? user =
            _auth.currentUser;

        if (user != null &&
            !_disposed) {
          await loadRewardedAd(
            purpose:
                miningStartPurpose,
            notifyOnLoadError: false,
          );
        }
      }
    } catch (error) {
      debugPrint(
        '❌ [ADMOB] Consent refresh after privacy options failed: '
        '$error',
      );
    }
  }

  // ============================================================
  // 📺 INITIALIZE ADMOB
  // ============================================================

  Future<void> _initializeAdMob() async {
    if (_mobileAdsInitialization != null) {
      await _mobileAdsInitialization;

      return;
    }

    debugPrint(
      '🐱 [ADMOB] Initializing Mobile Ads...',
    );

    _mobileAdsInitialization =
        MobileAds.instance.initialize();

    try {
      final InitializationStatus status =
          await _mobileAdsInitialization!;

      debugPrint(
        '✅ [ADMOB] Mobile Ads initialized.',
      );

      debugPrint(
        '🐱 [ADMOB] Adapter statuses: '
        '${status.adapterStatuses}',
      );
    } catch (error) {
      _mobileAdsInitialization = null;

      debugPrint(
        '❌ [ADMOB] Mobile Ads initialization failed: '
        '$error',
      );

      rethrow;
    }
  }  // ============================================================
  // 🚀 INITIALIZE + PRELOAD
  // ============================================================

  Future<void> _initializeAndPreload() async {
    if (_disposed) {
      return;
    }

    try {
      final bool allowed =
          await _checkAdConsent();

      if (!allowed) {
        debugPrint(
          '⚠️ [ADMOB] Preload skipped: consent not available.',
        );

        return;
      }

      await _initializeAdMob();

      if (_disposed) {
        return;
      }

      await _preloadMiningAd();
    } catch (error) {
      debugPrint(
        '❌ [ADMOB] Initialization failed: '
        '$error',
      );

      if (!_disposed) {
        _adLoadError =
            'ADMOB_INITIALIZATION_FAILED | $error';

        _notify();
      }
    }
  }

  // ============================================================
  // 📱 AD UNIT ID
  // ============================================================

  String get _rewardedAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/5224354917';
    }

    return 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  }

  // ============================================================
  // 🧹 AD STATE
  // ============================================================

  void _clearAdState() {
    _rewardedAd = null;
    _rewardedAdPurpose = '';
    _rewardedAdUserUid = '';
    _adReady = false;
  }

  void _disposeCurrentAd() {
    try {
      _rewardedAd?.dispose();
    } catch (_) {}

    _clearAdState();
  }

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
  // 🔄 PRELOAD
  // ============================================================

  Future<void> _preloadMiningAd() async {
    if (_disposed) {
      return;
    }

    final User? user =
        _auth.currentUser;

    if (user == null) {
      debugPrint(
        '⚠️ [ADMOB] Preload skipped: no user.',
      );

      return;
    }

    await loadRewardedAd(
      purpose:
          miningStartPurpose,
      uid:
          user.uid,
    );
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

    final User? user =
        _auth.currentUser;

    if (user == null) {
      return false;
    }

    if (_isReadyFor(
      purpose,
      user.uid,
    )) {
      return true;
    }

    for (
      int attempt = 1;
      attempt <= maxAdLoadAttempts;
      attempt++
    ) {
      if (_disposed) {
        return false;
      }

      if (_isReadyFor(
        purpose,
        user.uid,
      )) {
        return true;
      }

      debugPrint(
        '⏳ [ADMOB] Waiting for ad: '
        '$purpose '
        'attempt=$attempt/$maxAdLoadAttempts',
      );

      await loadRewardedAd(
        purpose:
            purpose,
        uid:
            user.uid,
      );

      if (_disposed) {
        return false;
      }

      if (_isReadyFor(
        purpose,
        user.uid,
      )) {
        return true;
      }

      if (attempt <
          maxAdLoadAttempts) {
        await Future<void>.delayed(
          const Duration(
            milliseconds:
                500,
          ),
        );
      }
    }

    return false;
  }

  // ============================================================
  // 🔄 LOAD REWARDED AD
  // ============================================================

  Future<void> loadRewardedAd({
    required String purpose,
    required String uid,
  }) async {
    if (_disposed) {
      return;
    }

    if (uid.isEmpty) {
      return;
    }

    final User? currentUser =
        _auth.currentUser;

    if (currentUser == null ||
        currentUser.uid != uid) {
      return;
    }

    if (_adLoading &&
        _loadingPurpose == purpose) {
      return;
    }

    if (_isReadyFor(
      purpose,
      uid,
    )) {
      return;
    }

    final int requestId =
        ++_loadRequestId;

    _adLoading = true;
    _loadingPurpose = purpose;
    _adLoadError = '';

    _disposeCurrentAd();

    _notify();

    debugPrint(
      '📥 [ADMOB] Loading rewarded ad: '
      '$purpose',
    );

    try {
      await RewardedAd.load(
        adUnitId:
            _rewardedAdUnitId,
        request:
            const AdRequest(),
        rewardedAdLoadCallback:
            RewardedAdLoadCallback(
          onAdLoaded:
              (
            RewardedAd ad,
          ) async {
            // ==================================================
            // 🔐 ADMOB SERVER-SIDE VERIFICATION
            // ==================================================

            try {
              await ad.setServerSideOptions(
                ServerSideVerificationOptions(
                  customData:
                      '$uid:$purpose',
                ),
              );
            } catch (error) {
              ad.dispose();

              if (_disposed ||
                  requestId !=
                      _loadRequestId) {
                return;
              }

              _adLoading = false;
              _loadingPurpose = '';
              _clearAdState();
              _adLoadError =
                  'SSV_SETUP_FAILED | '
                  '$error';
              _notify();
              return;
            }

            if (_disposed ||
                requestId !=
                    _loadRequestId) {
              ad.dispose();
              return;
            }

            final User? verifiedUser =
                _auth.currentUser;

            if (verifiedUser == null ||
                verifiedUser.uid != uid) {
              ad.dispose();
              _adLoading = false;
              _loadingPurpose = '';
              _clearAdState();
              return;
            }

            _rewardedAd = ad;
            _rewardedAdPurpose =
                purpose;
            _rewardedAdUserUid =
                uid;
            _adReady = true;
            _adLoading = false;
            _loadingPurpose = '';
            _adLoadError = '';

            _notify();

            debugPrint(
              '✅ [ADMOB] Rewarded ad ready: '
              '$purpose',
            );
          },
          onAdFailedToLoad:
              (
            LoadAdError error,
          ) {
            if (_disposed ||
                requestId !=
                    _loadRequestId) {
              return;
            }

            debugPrint(
              '❌ [ADMOB] Failed to load: '
              '$purpose | '
              '${error.message}',
            );

            _adLoading = false;
            _loadingPurpose = '';
            _clearAdState();

            _adLoadError =
                'LOAD_FAILED | '
                'Purpose: $purpose | '
                'Code: ${error.code} | '
                'Message: ${error.message}';

            _notify();

            onAdLoadError?.call(
              purpose,
              error,
            );
          },
        ),
      );
    } catch (error) {
      if (_disposed ||
          requestId !=
              _loadRequestId) {
        return;
      }

      debugPrint(
        '❌ [ADMOB] Load exception: '
        '$purpose | $error',
      );

      _adLoading = false;
      _loadingPurpose = '';
      _clearAdState();

      _adLoadError =
          'LOAD_EXCEPTION | '
          'Purpose: $purpose | '
          'Error: $error';

      _notify();
    }
  }    ad.fullScreenContentCallback =
        FullScreenContentCallback<RewardedAd>(
      onAdShowedFullScreenContent:
          (
        RewardedAd ad,
      ) async {
        debugPrint(
          '✅ [ADMOB] Ad shown: '
          '$purpose',
        );

        // 🔒 Varmistetaan Androidin immersive fullscreen.
        try {
          await SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.immersive,
          );
        } catch (error) {
          debugPrint(
            '⚠️ [ADMOB] Immersive mode failed: '
            '$error',
          );
        }
      },
      onAdImpression:
          (
        RewardedAd ad,
      ) {
        debugPrint(
          '🐱 [ADMOB] Impression: '
          '$purpose',
        );
      },
      onAdClicked:
          (
        RewardedAd ad,
      ) {
        debugPrint(
          '🐱 [ADMOB] Clicked: '
          '$purpose',
        );
      },
      onAdDismissedFullScreenContent:
          (
        RewardedAd ad,
      ) async {
        debugPrint(
          '🐱 [ADMOB] Ad dismissed: '
          '$purpose',
        );

        // 🔓 Palautetaan sovelluksen normaali
        // edge-to-edge-näyttö mainoksen jälkeen.
        try {
          await SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.edgeToEdge,
          );
        } catch (error) {
          debugPrint(
            '⚠️ [ADMOB] Failed to restore '
            'edge-to-edge mode: '
            '$error',
          );
        }

        try {
          ad.dispose();
        } catch (_) {}

        _clearAdState();

        _setFlowActive(
          purpose,
          false,
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
      onAdFailedToShowFullScreenContent:
          (
        RewardedAd ad,
        AdError error,
      ) async {
        debugPrint(
          '❌ [ADMOB] Failed to show: '
          '$purpose | '
          '${error.message}',
        );

        // 🔓 Palautetaan normaali näyttötila,
        // jos fullscreen-mainos epäonnistui.
        try {
          await SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.edgeToEdge,
          );
        } catch (restoreError) {
          debugPrint(
            '⚠️ [ADMOB] Failed to restore '
            'edge-to-edge mode: '
            '$restoreError',
          );
        }

        try {
          ad.dispose();
        } catch (_) {}

        _clearAdState();

        _setFlowActive(
          purpose,
          false,
        );

        _resetRewardCallbackState(
          purpose,
        );

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
    );  // ============================================================
  // ▶️ SHOW MINING START AD
  // ============================================================

  Future<bool> showMiningStartAd() async {
    return _showRewardedAd(
      purpose:
          miningStartPurpose,
    );
  }

  // ============================================================
  // ⚡ SHOW POWER BOOST AD
  // ============================================================

  Future<bool> showPowerBoostAd() async {
    return _showRewardedAd(
      purpose:
          powerBoostPurpose,
    );
  }

  // ============================================================
  // ▶️ SHOW REWARDED AD
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
      debugPrint(
        '❌ [ADMOB] No authenticated user.',
      );

      return false;
    }

    final bool allowed =
        _consentCheckCompleted
            ? _canRequestAds
            : await _checkAdConsent();

    if (!allowed) {
      debugPrint(
        '⚠️ [ADMOB] Ad request not allowed.',
      );

      return false;
    }

    if (purpose ==
            miningStartPurpose &&
        _miningAdFlowActive) {
      return false;
    }

    if (purpose ==
            powerBoostPurpose &&
        _powerBoostAdFlowActive) {
      return false;
    }

    if (purpose ==
            miningStartPurpose &&
        _powerBoostAdFlowActive) {
      return false;
    }

    if (purpose ==
            powerBoostPurpose &&
        _miningAdFlowActive) {
      return false;
    }

    if (purpose ==
            miningStartPurpose &&
        _miningRewardCallbackStarted) {
      return false;
    }

    if (purpose ==
            powerBoostPurpose &&
        _powerBoostRewardCallbackStarted) {
      return false;
    }

    _setFlowActive(
      purpose,
      true,
    );

    _adLoadError = '';

    _notify();

    RewardedAd? ad;

    try {
      final bool ready =
          await waitForRewardedAd(
        purpose:
            purpose,
      );

      if (_disposed) {
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
        debugPrint(
          '❌ [ADMOB] Ad not ready after '
          '$maxAdLoadAttempts attempts.',
        );

        _setFlowActive(
          purpose,
          false,
        );

        _notify();

        return false;
      }

      ad = _rewardedAd;

      if (ad == null) {
        _setFlowActive(
          purpose,
          false,
        );

        return false;
      }

      _clearAdState();

      _notify();

      bool rewardEarned = false;

      // ========================================================
      // 🔒 FULLSCREEN / IMMERSIVE MODE
      // ========================================================

      try {
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.immersive,
        );

        debugPrint(
          '🔒 [ADMOB] Immersive fullscreen enabled.',
        );
      } catch (error) {
        debugPrint(
          '⚠️ [ADMOB] Failed to enable immersive mode: '
          '$error',
        );
      }

      await ad.setImmersiveMode(true);

      ad.show(
        onUserEarnedReward:
            (
          AdWithoutView adWithoutView,
          RewardItem reward,
        ) {
          if (rewardEarned) {
            return;
          }

          rewardEarned = true;

          debugPrint(
            '🎁 [ADMOB] Reward received.'
            ' Purpose=$purpose '
            'Amount=${reward.amount} '
            'Type=${reward.type}',
          );

          _handleRewardEarned(
            purpose,
          );
        },
      );

      debugPrint(
        '✅ [ADMOB] Ad.show() called: '
        '$purpose',
      );

      return true;
    } catch (error) {
      debugPrint(
        '❌ [ADMOB] Show exception: '
        '$purpose | $error',
      );

      // ========================================================
      // 🔓 RESTORE NORMAL SYSTEM UI
      // ========================================================

      try {
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.edgeToEdge,
        );
      } catch (restoreError) {
        debugPrint(
          '⚠️ [ADMOB] Failed to restore '
          'edge-to-edge mode: '
          '$restoreError',
        );
      }

      try {
        ad?.dispose();
      } catch (_) {}

      _clearAdState();

      _setFlowActive(
        purpose,
        false,
      );

      _resetRewardCallbackState(
        purpose,
      );

      _adLoadError =
          'SHOW_EXCEPTION | '
          'Purpose: $purpose | '
          'Error: $error';

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
    if (purpose ==
        miningStartPurpose) {
      _miningAdFlowActive =
          active;
    }

    if (purpose ==
        powerBoostPurpose) {
      _powerBoostAdFlowActive =
          active;
    }
  }

  void _resetRewardCallbackState(
    String purpose,
  ) {
    if (purpose ==
        miningStartPurpose) {
      _miningRewardCallbackStarted =
          false;
    }

    if (purpose ==
        powerBoostPurpose) {
      _powerBoostRewardCallbackStarted =
          false;
    }
  }

  // ============================================================
  // 🧹 DISPOSE
  // ============================================================

  @override
  void dispose() {
    _disposed = true;

    _loadRequestId++;

    _disposeCurrentAd();

    super.dispose();
  }
}