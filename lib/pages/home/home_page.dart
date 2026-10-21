import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/cat_facts.dart';
import '../../localization.dart';
import '../../services/app_update_service.dart';
import '../../services/mining_notification_service.dart';
import '../../widgets/home_drawer.dart';
import '../../widgets/stelluriini_space_background.dart';
import '../about/about_page.dart';
import '../account/account_deletion_page.dart';
import '../achievements/achievements_page.dart';
import '../history/transaction_history_page.dart';
import '../referrals/referrals_page.dart';
import '../roadmap/roadmap_page.dart';
import '../whitepaper/whitepaper_page.dart';
import 'cat_fact_card.dart';
import 'dialogs/app_update_dialog.dart';
import 'dialogs/delete_account_dialog.dart';
import 'home_ad_manager.dart';
import 'home_stats_card.dart';
import 'power_boost_card.dart';
import 'stella_mining_card.dart';
import 'widgets/home_greeting.dart';
import 'widgets/home_header.dart';

class HomePage extends StatefulWidget {
  final String languageCode;
  final ValueChanged<String> changeLanguage;

  const HomePage({
    super.key,
    required this.languageCode,
    required this.changeLanguage,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // 🎨 STELLURIINI / STELLA THEME
  // ============================================================

  static const Color backgroundColor = Color(0xFF120B24);
  static const Color surfaceColor = Color(0xFF1A0E31);
  static const Color cardColor = Color(0xFF21113B);
  static const Color accentColor = Color(0xFFB58CFF);
  
  static const Color primaryTextColor = Color(0xFFF8F4FF);
  static const Color secondaryTextColor = Color(0xFFBDB4D1);

  // ============================================================
  // ⛏️ DEFAULT MINING CONFIG
  // ============================================================

  static const double defaultAdHashRateBonus = 0.5833;
  static const int defaultMaxAdsPerDay = 6;
  static const double defaultDailyHashRate = 0.5;
  static const double miningPerHashPerHour = 0.10;

  static const int defaultMiningDurationMs =
      24 * 60 * 60 * 1000;

  static const int defaultAdCooldownMs =
      4 * 60 * 60 * 1000;

  // ============================================================
  // 🔥 FIREBASE
  // ============================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  // ============================================================
  // 🔔 MINING NOTIFICATIONS
  // ============================================================

  final MiningNotificationService _miningNotificationService =
      MiningNotificationService.instance;

  // ============================================================
  // 📱 APP UPDATE
  // ============================================================

  final AppUpdateService _appUpdateService =
      AppUpdateService.instance;

  bool _updateDialogShown = false;

  // ============================================================
  // 🎬 ANIMATION / ADS
  // ============================================================

  late final AnimationController _catAnimation;
  late final HomeAdManager _adManager;

  // ============================================================
  // ⏱️ TIMERS
  // ============================================================

  Timer? _miningTimer;
  Timer? _boostTimer;
  Timer? _refreshTimer;

  // ============================================================
  // 📱 PAGE STATE
  // ============================================================

  bool _loading = true;
  bool _actionLoading = false;
  bool _miningActive = false;
  bool _deletingAccount = false;

  double _hashRate = defaultDailyHashRate;
  double _unclaimedMining = 0;
  double _estimatedTotal = 0;

  int _miningDurationMs = defaultMiningDurationMs;
  int _miningRemainingMs = 0;

  int _streak = 1;

  // ============================================================
  // 📺 AD / POWER BOOST STATE
  // ============================================================

  int _adsToday = 0;
  int _maxAdsPerDay = defaultMaxAdsPerDay;

  double _adHashRateBonus = defaultAdHashRateBonus;

  int _cooldownRemainingMs = 0;

  bool _serverCanWatchAd = true;

  bool _boostActive = false;
  int _boostRemainingMs = 0;

  // ============================================================
  // 👤 USER
  // ============================================================

  String _username = '';

  // ============================================================
  // 📱 APP VERSION
  // ============================================================

  String _appVersion = '';
  String _buildNumber = '';

  // ============================================================
  // 🌐 LOCALIZATION
  // ============================================================

  AppLocalizations get _localization =>
      AppLocalizations(widget.languageCode);

  String _t(String key) {
    return _localization.get(key);
  }

  String _tp(
    String key, {
    Map<String, dynamic>? params,
  }) {
    return _localization.getWithParams(
      key,
      params: params,
    );
  }

  // ============================================================
  // 📊 EFFECTIVE HASH RATE
  // ============================================================

  double get _effectiveHashRate {
    final double base = _hashRate.isFinite
        ? _hashRate
        : defaultDailyHashRate;

    final double boost =
        _boostActive &&
                _adHashRateBonus.isFinite &&
                _adHashRateBonus > 0
            ? _adHashRateBonus
            : 0.0;

    final double result = base + boost;

    if (!result.isFinite || result < 0) {
      return defaultDailyHashRate;
    }

    return result;
  }

  // ============================================================
  // 📺 CAN USE POWER BOOST
  // ============================================================

  bool get _canUseBoost {
    if (!_miningActive) {
      return false;
    }

    if (_miningRemainingMs <= 0) {
      return false;
    }

    if (_actionLoading) {
      return false;
    }

    if (_boostActive && _boostRemainingMs > 0) {
      return false;
    }

    if (_adsToday >= _maxAdsPerDay) {
      return false;
    }

    if (!_serverCanWatchAd) {
      return false;
    }

    if (_cooldownRemainingMs > 0) {
      return false;
    }

    return true;
  }

  // ============================================================
  // 🚀 INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _catAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _adManager = HomeAdManager(
      onMiningStartReward: _startMiningAfterAd,
      onPowerBoostReward: _waitForServerSidePowerBoost,
      onAdLoadError: _handleAdLoadError,
      onAdShowError: _handleAdShowError,
      onAdDismissed: _handleAdDismissed,
    );

    _adManager.addListener(_onAdManagerChanged);

    _initialize();
  }

  // ============================================================
  // 🔄 LANGUAGE CHANGE
  // ============================================================

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.languageCode != widget.languageCode &&
        _miningActive &&
        _miningRemainingMs > 0) {
      unawaited(
        _miningNotificationService.scheduleMiningCompletion(
          Duration(milliseconds: _miningRemainingMs),
          languageCode: widget.languageCode,
        ),
      );
    }
  }

  // ============================================================
  // 🧹 DISPOSE
  // ============================================================

  @override
  void dispose() {
    _miningTimer?.cancel();
    _boostTimer?.cancel();
    _refreshTimer?.cancel();

    _adManager.removeListener(_onAdManagerChanged);
    _adManager.dispose();
    _catAnimation.dispose();

    super.dispose();
  }

  // ============================================================
  // 🔄 INITIALIZE
  // ============================================================

  Future<void> _initialize() async {
    try {
      await _miningNotificationService.requestPermission();

      await _loadAppVersion();
      await _loadUsername();
      await _loadMiningStatus();
    } catch (e) {
      if (mounted) {
        _showMessage('⚠️ ${_errorText(e)}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }

    _startRefreshTimer();

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkForAppUpdate();
      });
    }
  }

  // ============================================================
  // 📱 LOAD APP VERSION
  // ============================================================

  Future<void> _loadAppVersion() async {
    try {
      final PackageInfo info =
          await PackageInfo.fromPlatform();

      if (!mounted) {
        return;
      }

      setState(() {
        _appVersion = info.version;
        _buildNumber = info.buildNumber;
      });
    } catch (_) {
      // Versionumero ei estä sovelluksen käyttöä.
    }
  }

  // ============================================================
  // 🔄 CHECK FOR APP UPDATE
  // ============================================================

  Future<void> _checkForAppUpdate() async {
    if (!mounted || _updateDialogShown) {
      return;
    }

    final AppUpdateInfo? updateInfo =
        await _appUpdateService.checkForUpdate();

    if (!mounted ||
        updateInfo == null ||
        _updateDialogShown) {
      return;
    }

    _updateDialogShown = true;

    final Map<String, String> texts =
        _appUpdateTexts(updateInfo.latestVersion);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return AppUpdateDialog(
          updateInfo: updateInfo,
          texts: texts,
          onOpenUpdate:
              _appUpdateService.openUpdateUrl,
          onOpenError: () {
            if (mounted) {
              _showMessage(texts['openError']!);
            }
          },
        );
      },
    );
  }

  // ============================================================
  // 🌐 APP UPDATE TEXTS
  // ============================================================

  Map<String, String> _appUpdateTexts(
    String latestVersion,
  ) {
    final String code =
        AppLocalizations.normalizeLanguageCode(
      widget.languageCode,
    );

    switch (code) {
      case 'fi':
        return {
          'title': '🐱 Stelluriinista on uusi versio!',
          'message':
              'Uusi versio $latestVersion on saatavilla. '
              'Päivitä Stelluriini Google Playsta, jotta saat '
              'uusimmat ominaisuudet ja korjaukset.',
          'update': 'Päivitä nyt',
          'later': 'Myöhemmin',
          'openError':
              'Google Playta ei voitu avata.',
        };

      case 'de':
        return {
          'title':
              '🐱 Eine neue Stelluriini-Version ist verfügbar!',
          'message':
              'Die neue Version $latestVersion ist verfügbar. '
              'Aktualisiere Stelluriini über Google Play, '
              'um die neuesten Funktionen und Verbesserungen '
              'zu erhalten.',
          'update': 'Jetzt aktualisieren',
          'later': 'Später',
          'openError':
              'Google Play konnte nicht geöffnet werden.',
        };

      case 'es':
        return {
          'title':
              '🐱 ¡Hay una nueva versión de Stelluriini!',
          'message':
              'La nueva versión $latestVersion ya está disponible. '
              'Actualiza Stelluriini desde Google Play para '
              'obtener las últimas funciones y mejoras.',
          'update': 'Actualizar ahora',
          'later': 'Más tarde',
          'openError':
              'No se pudo abrir Google Play.',
        };

      case 'fr':
        return {
          'title':
              '🐱 Une nouvelle version de Stelluriini est disponible !',
          'message':
              'La version $latestVersion est disponible. '
              'Mettez à jour Stelluriini depuis Google Play '
              'pour profiter des dernières fonctionnalités '
              'et améliorations.',
          'update': 'Mettre à jour',
          'later': 'Plus tard',
          'openError':
              'Impossible d’ouvrir Google Play.',
        };

      case 'zh':
        return {
          'title': '🐱 Stelluriini 有新版本！',
          'message':
              '新版本 $latestVersion 已经发布。'
              '请通过 Google Play 更新 Stelluriini，'
              '以获得最新功能和改进。',
          'update': '立即更新',
          'later': '稍后',
          'openError': '无法打开 Google Play。',
        };

      case 'vi':
        return {
          'title':
              '🐱 Stelluriini có phiên bản mới!',
          'message':
              'Phiên bản $latestVersion đã có sẵn. '
              'Hãy cập nhật Stelluriini từ Google Play '
              'để nhận các tính năng và cải tiến mới nhất.',
          'update': 'Cập nhật ngay',
          'later': 'Để sau',
          'openError':
              'Không thể mở Google Play.',
        };

      case 'ja':
        return {
          'title':
              '🐱 Stelluriiniの新しいバージョンがあります！',
          'message':
              '新しいバージョン $latestVersion が利用可能です。'
              '最新の機能と改善を利用するには、'
              'Google PlayからStelluriiniを更新してください。',
          'update': '今すぐ更新',
          'later': '後で',
          'openError':
              'Google Playを開けませんでした。',
        };

      case 'en':
      default:
        return {
          'title':
              '🐱 A new version of Stelluriini is available!',
          'message':
              'Version $latestVersion is now available. '
              'Update Stelluriini from Google Play to get '
              'the latest features and improvements.',
          'update': 'Update now',
          'later': 'Later',
          'openError':
              'Google Play could not be opened.',
        };
    }
  }

  // ============================================================
  // 👤 LOAD USERNAME
  // ============================================================

  Future<void> _loadUsername() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      final HttpsCallable callable =
          _functions.httpsCallable('getUserProfile');

      final HttpsCallableResult<dynamic> result =
          await callable.call();

      final dynamic raw = result.data;

      if (raw is Map) {
        final Map<String, dynamic> data =
            Map<String, dynamic>.from(raw);

        String username = '';

        final dynamic rawProfile =
            data['profile'];

        if (rawProfile is Map) {
          final Map<String, dynamic> profile =
              Map<String, dynamic>.from(rawProfile);

          username =
              profile['username']?.toString().trim() ?? '';
        }

        if (username.isEmpty) {
          username =
              data['username']?.toString().trim() ?? '';
        }

        if (mounted && username.isNotEmpty) {
          setState(() {
            _username = username;
          });

          return;
        }
      }
    } catch (_) {
      // Firebase profile is optional.
    }

    final String displayName =
        user.displayName?.trim() ?? '';

    if (mounted && displayName.isNotEmpty) {
      setState(() {
        _username = displayName;
      });
    }
  }

  // ============================================================
  // ⛏️ LOAD MINING STATUS
  // ============================================================

  Future<void> _loadMiningStatus() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      await _miningNotificationService
          .cancelMiningCompletion();
      return;
    }

    try {
      final HttpsCallable callable =
          _functions.httpsCallable('getMiningStatus');

      final HttpsCallableResult<dynamic> result =
          await callable.call();

      final dynamic raw = result.data;

      if (raw is! Map || !mounted) {
        return;
      }

      final Map<String, dynamic> data =
          Map<String, dynamic>.from(raw);

      final bool miningActive =
          _asBool(data['miningActive']) ??
              _asBool(data['active']) ??
              false;

      final double hashRate =
          _asDouble(data['hashRate']) ??
              _asDouble(data['dailyHashRate']) ??
              _asDouble(data['effectiveHashRate']) ??
              defaultDailyHashRate;

      final double unclaimed =
          _asDouble(data['unclaimedMining']) ??
              _asDouble(data['unclaimed']) ??
              _asDouble(data['miningBalance']) ??
              0.0;

      final double total =
          _asDouble(data['estimatedTotal']) ??
              _asDouble(data['totalStl']) ??
              _asDouble(data['totalBalance']) ??
              0.0;

      final int remaining =
          _asInt(data['miningRemainingMs']) ??
              _asInt(data['remainingMs']) ??
              _asInt(data['remainingTimeMs']) ??
              0;

      final int duration =
          _asInt(data['miningDurationMs']) ??
              _asInt(data['durationMs']) ??
              defaultMiningDurationMs;

      final int streak =
          _asInt(data['dailyStreak']) ??
              _asInt(data['streak']) ??
              1;

      final int adsToday =
          _asInt(data['adsToday']) ??
              _asInt(data['adCountToday']) ??
              0;

      final int maxAds =
          _asInt(data['maxAdsPerDay']) ??
              defaultMaxAdsPerDay;

      final double adBonus =
          _asDouble(data['adHashRateBonus']) ??
              defaultAdHashRateBonus;

      final int cooldownRemaining =
          _asInt(data['cooldownRemainingMs']) ?? 0;

      final bool serverCanWatchAd =
          _asBool(data['canWatchAd']) ?? true;

      final bool serverBoostActive =
          _asBool(data['adBoostActive']) ??
              _asBool(data['boostActive']) ??
              false;

      final int serverBoostRemaining =
          _asInt(data['adBoostRemainingMs']) ??
              _asInt(data['boostRemainingMs']) ??
              _asInt(data['remainingBoostMs']) ??
              0;

      final int safeDuration =
          duration > 0
              ? duration
              : defaultMiningDurationMs;

      final int safeRemaining =
          remaining.clamp(0, safeDuration).toInt();

      final bool safeMiningActive =
          miningActive && safeRemaining > 0;

      // ----------------------------------------------------------
      // IMPORTANT:
      // The server is the single source of truth for Power Boost.
      //
      // Do NOT restore an old local boost when the server says
      // that no boost is active. The previous implementation did
      // exactly that and could keep the old boost timer alive
      // after a mining cycle had ended.
      // ----------------------------------------------------------

      final bool boostActive =
          safeMiningActive &&
          serverBoostActive &&
          serverBoostRemaining > 0;

      final int boostRemaining =
          boostActive
              ? serverBoostRemaining
                  .clamp(0, safeRemaining)
                  .toInt()
              : 0;

      final double safeHashRate =
          hashRate.isFinite && hashRate >= 0
              ? hashRate
              : defaultDailyHashRate;

      final double safeUnclaimed =
          unclaimed.isFinite && unclaimed >= 0
              ? unclaimed
              : 0.0;

      final double safeTotal =
          total.isFinite && total >= 0
              ? total
              : 0.0;

      final int safeMaxAds =
          maxAds > 0
              ? maxAds
              : defaultMaxAdsPerDay;

      final double safeAdBonus =
          adBonus.isFinite && adBonus >= 0
              ? adBonus
              : defaultAdHashRateBonus;

      final int safeCooldownRemaining =
          cooldownRemaining
              .clamp(0, defaultAdCooldownMs)
              .toInt();

      final int safeStreak =
          streak > 0 ? streak : 1;

      if (!mounted) {
        return;
      }

      setState(() {
        _miningActive = safeMiningActive;

        _hashRate = safeHashRate;
        _unclaimedMining = safeUnclaimed;
        _estimatedTotal = safeTotal;

        _miningDurationMs = safeDuration;
        _miningRemainingMs = safeRemaining;

        _streak = safeStreak;

        _maxAdsPerDay = safeMaxAds;

        _adsToday =
            adsToday.clamp(0, safeMaxAds).toInt();

        _adHashRateBonus = safeAdBonus;

        _cooldownRemainingMs =
            safeCooldownRemaining;

        _serverCanWatchAd = serverCanWatchAd;

        _boostActive = boostActive;

        _boostRemainingMs =
            boostRemaining;
      });

      // ----------------------------------------------------------
      // IMPORTANT:
      // Do not cancel a valid Android completion notification
      // simply because a refresh temporarily reports inactive.
      //
      // Only create the notification if one does not already
      // exist. This prevents the 30-second refresh timer and the
      // boost timer from repeatedly replacing the same notification.
      // ----------------------------------------------------------

      if (safeMiningActive && safeRemaining > 0) {
        final bool hasPending =
            await _miningNotificationService
                .hasPendingMiningCompletion();

        if (!hasPending) {
          await _miningNotificationService
              .scheduleMiningCompletion(
            Duration(milliseconds: safeRemaining),
            languageCode: widget.languageCode,
          );
        }
      }

      _startMiningTimer();
      _startBoostTimer();
    } catch (e) {
      if (mounted) {
        _showMessage('⚠️ ${_errorText(e)}');
      }
    }
  }

  // ============================================================
  // 🔄 REFRESH TIMER
  // ============================================================

  void _startRefreshTimer() {
    _refreshTimer?.cancel();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (!_loading &&
            !_actionLoading &&
            !_deletingAccount &&
            mounted) {
          _loadMiningStatus();
        }
      },
    );
  }

  // ============================================================
  // ⛏️ MINING TIMER
  // ============================================================

  void _startMiningTimer() {
    _miningTimer?.cancel();

    if (!_miningActive ||
        _miningRemainingMs <= 0) {
      return;
    }

    _miningTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) {
          return;
        }

        if (_miningRemainingMs <= 1000) {
          setState(() {
            _miningRemainingMs = 0;
            _miningActive = false;
          });

          _miningTimer?.cancel();

          // IMPORTANT:
          // Do NOT cancel the scheduled mining-completion
          // notification here. Android may still be waiting
          // to deliver it at the scheduled completion time.
          //
          // Also do not immediately call _loadMiningStatus().
          // That could receive "miningActive: false" from the
          // server and cancel the notification before Android
          // has delivered it.
          //
          // The normal 30-second refresh will update the server
          // state afterwards.
          return;
        }

        setState(() {
          _miningRemainingMs -= 1000;
        });
      },
    );
  }

  // ============================================================
  // 🐾 POWER BOOST TIMER
  // ============================================================

  void _startBoostTimer() {
    _boostTimer?.cancel();

    if (!_boostActive ||
        _boostRemainingMs <= 0) {
      return;
    }

    _boostTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) {
          return;
        }

        if (_boostRemainingMs <= 1000) {
          setState(() {
            _boostRemainingMs = 0;
            _boostActive = false;
          });

          _boostTimer?.cancel();

          _loadMiningStatus();

          return;
        }

        setState(() {
          _boostRemainingMs -= 1000;
        });
      },
    );
  }

  // ============================================================
  // 📺 START MINING → SHOW AD
  // ============================================================

  Future<void> _startMining() async {
    if (_actionLoading ||
        _deletingAccount ||
        _miningActive ||
        _adManager.miningAdFlowActive) {
      return;
    }

    setState(() {
      _actionLoading = true;
    });

    try {
      final bool shown =
          await _adManager.showMiningStartAd();

      if (!shown && mounted) {
        setState(() {
          _actionLoading = false;
        });

        _showMessage(
          '⚠️ ${_t('prepareAd')}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _actionLoading = false;
        });

        _showMessage(
          '⚠️ ${_errorText(e)}',
        );
      }
    }
  }

  // ============================================================
  // ⛏️ START MINING AFTER AD
  // ============================================================

  Future<void> _startMiningAfterAd() async {
    if (!mounted) {
      return;
    }

    try {
      final HttpsCallable callable =
          _functions.httpsCallable('claimMining');

      final HttpsCallableResult<dynamic> result =
          await callable.call();

      final dynamic raw = result.data;

      if (raw is! Map) {
        throw Exception(
          'Invalid mining response.',
        );
      }

      final Map<String, dynamic> data =
          Map<String, dynamic>.from(raw);

      final bool started =
          _asBool(data['started']) ??
              _asBool(data['miningStarted']) ??
              false;

      if (!started) {
        throw Exception(
          'Mining could not be started.',
        );
      }

      // ----------------------------------------------------------
      // IMPORTANT:
      // A new mining cycle always starts with a clean local
      // Power Boost state. The backend also resets the boost
      // fields when a new mining session starts.
      // ----------------------------------------------------------

      _boostTimer?.cancel();

      if (mounted) {
        final int streak =
            _asInt(data['dailyStreak']) ??
                _streak;

        final int safeStreak =
            streak > 0 ? streak : 1;

        setState(() {
          _miningActive = true;
          _streak = safeStreak;

          _boostActive = false;
          _boostRemainingMs = 0;
        });
      }

      // A previous mining cycle may have left a completion
      // notification pending. Remove it before loading the
      // new mining session so the new completion time can be
      // scheduled correctly.
      await _miningNotificationService
          .cancelMiningCompletion();

      await _loadMiningStatus();

      if (mounted) {
        _showMessage(
          '🐱 ${_t('miningStarted')}',
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage(
          '⚠️ ${_errorText(e)}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _actionLoading = false;
        });
      }
    }
  }

  // ============================================================
  // 📺 WATCH POWER BOOST AD
  // ============================================================

  Future<void> _watchAd() async {
    if (_actionLoading ||
        _deletingAccount) {
      return;
    }

    if (!_miningActive ||
        _miningRemainingMs <= 0) {
      _showMessage(
        '🐱 ${_t('startMining')}',
      );
      return;
    }

    if (!_canUseBoost) {
      _showMessage(
        '🐱 ${_t('maxBoostsInfo')}',
      );
      return;
    }

    setState(() {
      _actionLoading = true;
    });

    try {
      final bool shown =
          await _adManager.showPowerBoostAd();

      if (!shown && mounted) {
        setState(() {
          _actionLoading = false;
        });

        _showMessage(
          '⚠️ ${_t('adNotAvailable')}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _actionLoading = false;
        });

        _showMessage(
          '⚠️ ${_errorText(e)}',
        );
      }
    }
  }

  // ============================================================
  // 🐾 VERIFY POWER BOOST ON SERVER
  // ============================================================

  Future<void> _waitForServerSidePowerBoost() async {
    try {
      final HttpsCallable callable =
          _functions.httpsCallable('powerBoost');

      final HttpsCallableResult<dynamic> result =
          await callable.call();

      final dynamic raw = result.data;

      if (raw is! Map) {
        throw Exception(
          'Invalid Power Boost response.',
        );
      }

      final Map<String, dynamic> data =
          Map<String, dynamic>.from(raw);

      final bool active =
          _asBool(data['boostActive']) ??
              _asBool(data['active']) ??
              false;

      final int remaining =
          _asInt(data['boostRemainingMs']) ??
              _asInt(data['remainingBoostMs']) ??
              _asInt(data['adBoostRemainingMs']) ??
              0;

      final int? ads =
          _asInt(data['adsToday']);

      final double? bonus =
          _asDouble(data['adHashRateBonus']) ??
              _asDouble(data['hashRateBonus']) ??
              _asDouble(
                data['boostHashRateBonus'],
              );

      if (!active || remaining <= 0) {
        throw Exception(
          'Power Boost verification did not '
          'return an active boost.',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _boostActive = true;
        _boostRemainingMs = remaining;

        if (ads != null) {
          _adsToday =
              ads.clamp(0, _maxAdsPerDay).toInt();
        }

        if (bonus != null &&
            bonus.isFinite &&
            bonus > 0) {
          _adHashRateBonus = bonus;
        }

        _serverCanWatchAd = false;
        _cooldownRemainingMs = 0;
      });

      _startBoostTimer();

      await _loadMiningStatus();

      if (mounted) {
        _showMessage(
          '🐾 ${_t('powerBoostActive')} '
          '• +${_formatNumber(_adHashRateBonus)} H/s',
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage(
          '⚠️ ${_errorText(e)}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _actionLoading = false;
        });
      }
    }
  }

  // ============================================================
  // 📺 AD MANAGER LISTENER
  // ============================================================

  void _onAdManagerChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ============================================================
  // ❌ AD LOAD ERROR
  // ============================================================

  void _handleAdLoadError(
    String purpose,
    LoadAdError error,
  ) {
    if (!mounted) {
      return;
    }

    setState(() {
      _actionLoading = false;
    });

    _showMessage(
      '⚠️ ${_adLoadErrorText(
        purpose,
        error,
      )}',
    );
  }

  // ============================================================
  // ❌ AD SHOW ERROR
  // ============================================================

  void _handleAdShowError(
    String purpose,
    AdError error,
  ) {
    if (!mounted) {
      return;
    }

    setState(() {
      _actionLoading = false;
    });

    _showMessage(
      '⚠️ ${_adShowErrorText(
        purpose,
        error,
      )}',
    );
  }

  // ============================================================
  // 📺 AD DISMISSED
  // ============================================================

  void _handleAdDismissed(String purpose) {
    if (!mounted) {
      return;
    }

    if (purpose ==
            HomeAdManager.powerBoostPurpose ||
        purpose ==
            HomeAdManager.miningStartPurpose) {
      setState(() {
        _actionLoading = false;
      });
    }
  }

  // ============================================================
  // 🗑️ DELETE ACCOUNT CONFIRMATION
  // ============================================================

  Future<void> _showDeleteAccountConfirmation() async {
    if (!mounted || _deletingAccount) {
      return;
    }

    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return DeleteAccountDialog(
          title: _t(
            'accountDeletionDialogTitle',
          ),
          message: _t(
            'accountDeletionDialogMessage',
          ),
          cancelLabel:
              _t('accountDeletionCancel'),
          confirmLabel:
              _t('accountDeletionConfirm'),
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _deleteAccount();
  }

  // ============================================================
  // 🗑️ DELETE ACCOUNT
  // ============================================================

  Future<void> _deleteAccount() async {
    if (_deletingAccount) {
      return;
    }

    final User? currentUser =
        _auth.currentUser;

    if (currentUser == null) {
      _showMessage(
        '⚠️ ${_t('accountDeletionFailed')}',
      );
      return;
    }

    if (mounted) {
      setState(() {
        _deletingAccount = true;
        _actionLoading = true;
      });
    }

    _miningTimer?.cancel();
    _boostTimer?.cancel();
    _refreshTimer?.cancel();

    await _miningNotificationService
        .cancelMiningCompletion();

    try {
      final HttpsCallable callable =
          _functions.httpsCallable(
        'deleteAccount',
      );

      final HttpsCallableResult<dynamic> result =
          await callable.call();

      final dynamic raw = result.data;

      bool success = false;

      if (raw is Map) {
        final Map<String, dynamic> data =
            Map<String, dynamic>.from(raw);

        success =
            _asBool(data['success']) ?? false;
      }

      if (!success) {
        throw FirebaseFunctionsException(
          code: 'internal',
          message:
              _t('accountDeletionFailed'),
        );
      }

      await _auth.signOut();

      if (!mounted) {
        return;
      }

      _showMessage(
        '🐱 ${_t('accountDeletionSuccess')}',
      );
    } on FirebaseFunctionsException catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      _showMessage(
        '⚠️ ${_deleteAccountErrorText(error)}',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        '⚠️ ${_errorText(e)}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingAccount = false;
          _actionLoading = false;
        });
      }
    }
  }

  // ============================================================
  // 🗑️ DELETE ACCOUNT ERROR
  // ============================================================

  String _deleteAccountErrorText(
    FirebaseFunctionsException error,
  ) {
    switch (error.code) {
      case 'unauthenticated':
        return _t(
          'accountDeletionSessionExpired',
        );

      case 'permission-denied':
        return _t(
          'accountDeletionPermissionDenied',
        );

      case 'unavailable':
        return _t(
          'accountDeletionUnavailable',
        );

      case 'deadline-exceeded':
        return _t(
          'accountDeletionTimeout',
        );

      case 'internal':
      default:
        return _t(
          'accountDeletionFailed',
        );
    }
  }

  // ============================================================
  // 🚪 LOGOUT
  // ============================================================

  Future<void> _logout() async {
    if (_deletingAccount) {
      return;
    }

    try {
      await _auth.signOut();

      await _miningNotificationService
          .cancelMiningCompletion();
    } catch (e) {
      if (mounted) {
        _showMessage(
          '⚠️ ${_errorText(e)}',
        );
      }
    }
  }

  // ============================================================
  // 🗑️ OPEN ACCOUNT DELETION
  // ============================================================

  Future<void> _openAccountDeletion() async {
    if (!mounted || _deletingAccount) {
      return;
    }

    Navigator.of(context).pop();

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AccountDeletionPage(
          languageCode: widget.languageCode,
          onDeleteAccountPressed:
              _showDeleteAccountConfirmation,
        ),
      ),
    );

    if (mounted && !_deletingAccount) {
      await _loadMiningStatus();
    }
  }

  // ============================================================
  // 🧭 NAVIGATION
  // ============================================================

  Future<void> _openPage(Widget page) async {
    if (!mounted || _deletingAccount) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );

    if (mounted && !_deletingAccount) {
      await _loadMiningStatus();
    }
  }

  void _openAbout() {
    _openPage(
      AboutPage(
        languageCode: widget.languageCode,
      ),
    );
  }

  void _openWhitePaper() {
    _openPage(
      WhitePaperPage(
        languageCode: widget.languageCode,
      ),
    );
  }

  void _openRoadmap() {
    _openPage(
      RoadmapPage(
        languageCode: widget.languageCode,
      ),
    );
  }

  void _openAchievements() {
    _openPage(
      AchievementsPage(
        languageCode: widget.languageCode,
      ),
    );
  }

  void _openTransactionHistory() {
    _openPage(
      TransactionHistoryPage(
        languageCode: widget.languageCode,
      ),
    );
  }

  void _openReferrals() {
    _openPage(
      ReferralsPage(
        languageCode: widget.languageCode,
      ),
    );
  }

  // ============================================================
  // 🌐 LANGUAGE DIALOG
  // ============================================================

  Future<void> _showLanguageDialog() async {
    final Map<String, String> languages =
        AppLocalizations.supportedLanguages;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: Text(
            _t('language'),
            style: const TextStyle(
              color: primaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: languages.length,
              itemBuilder: (_, index) {
                final String code =
                    languages.keys.elementAt(index);

                final String name =
                    languages[code] ?? code;

                return ListTile(
                  title: Text(
                    name,
                    style: const TextStyle(
                      color: primaryTextColor,
                    ),
                  ),
                  trailing:
                      code == widget.languageCode
                          ? const Icon(
                              Icons.check,
                              color: accentColor,
                            )
                          : null,
                  onTap: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();

                    if (code !=
                        widget.languageCode) {
                      widget.changeLanguage(code);
                    }
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // 🐱 DAILY CAT FACT
  // ============================================================

  Widget _buildDailyCatFact() {
    return CatFactCard(
      title: _t('catFact'),
      fact: CatFacts.getDailyFact(
        languageCode: widget.languageCode,
      ),
    );
  }

  // ============================================================
  // ⛏️ STELLA MINING CARD
  // ============================================================

  Widget _buildStellaMiningCard() {
    final int displayStreak =
        _streak.clamp(1, 7).toInt();

    return StellaMiningCard(
      languageCode: widget.languageCode,
      unclaimedMining: _unclaimedMining,
      miningTitle:
          _t('stellaMiningTitle'),
      miningSubtitle:
          _t('stellaMiningSubtitle'),
      timerText:
          _formatDuration(_miningRemainingMs),
      timerLabel: _tp(
        'miningTimeRemaining',
        params: {
          'time':
              _formatDuration(_miningRemainingMs),
        },
      ),
      catAnimation: _catAnimation,
      miningActive: _miningActive,
      miningRemainingMs:
          _miningRemainingMs,
      miningDurationMs:
          _miningDurationMs,
      miningProgressTitle:
          _t('miningProgress'),
      stlPerHourText:
          '${_formatNumber(
            _effectiveHashRate *
                miningPerHashPerHour,
          )} STL/h',
      dailyHashRateText:
          '${_formatNumber(
            _effectiveHashRate,
          )} H/s',
      dailyHashRateDayText:
          '${_t('day')} $displayStreak',
      dailyStreak: displayStreak,
      boostActive: _boostActive,
      miningButton: _buildMiningButton(),
    );
  }

  // ============================================================
  // 📊 STATS
  // ============================================================

  Widget _buildStatsRow() {
    return HomeStatsCard(
      hashRateTitle: _t('hashRate'),
      hashRateValue:
          '${_formatNumber(
            _effectiveHashRate,
          )} H/s',
      totalStlTitle: _t('totalStl'),
      totalStlValue:
          '${_formatNumber(
            _estimatedTotal,
          )} STL',
    );
  }

  // ============================================================
  // ⛏️ MINING BUTTON
  // ============================================================

  Widget _buildMiningButton() {
    final bool busy =
        _actionLoading ||
            _deletingAccount ||
            _adManager.miningAdFlowActive;

    final bool enabled =
        !_miningActive && !busy;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed:
            enabled ? _startMining : null,
        icon: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primaryTextColor,
                ),
              )
            : const Icon(
                Icons.play_arrow_rounded,
              ),
        label: Text(
          _miningActive
              ? _t('miningActive')
              : _t('startMining'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: backgroundColor,
          disabledBackgroundColor:
              surfaceColor,
          disabledForegroundColor:
              secondaryTextColor,
          minimumSize:
              const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 🐾 POWER BOOST CARD
  // ============================================================

  Widget _buildAdButton() {
    final bool canUse =
        _canUseBoost;

    final String adsTodayLabel =
        _tp(
      'adsToday',
      params: {
        'current':
            _adsToday.toString(),
        'max':
            _maxAdsPerDay.toString(),
      },
    );

    final String subtitle =
        _boostActive
            ? _t('powerBoostActive')
            : _t('watchAdSubtitle');

    final String remainingText =
        _tp(
      'remaining',
      params: {
        'time': _formatDuration(
          _boostRemainingMs,
        ),
      },
    );

    return PowerBoostCard(
      boostActive: _boostActive,
      boostRemainingMs:
          _boostRemainingMs,
      adsToday: _adsToday,
      maxAdsPerDay:
          _maxAdsPerDay,
      canUse: canUse,
      subtitle: subtitle,
      title: _t('powerBoost'),
      activeText: _t('active'),
      activeTitle:
          _t('powerBoostActive'),
      remainingText:
          remainingText,
      hashRateBonusText:
          '+${_formatNumber(
            _adHashRateBonus,
          )} H/s',
      effectiveHashRateText:
          '${_formatNumber(
            _effectiveHashRate,
          )} H/s',
      nextAdAfterBoostText:
          _t('nextAdAfterBoost'),
      watchAdText:
          _t('watchAd'),
      adsTodayText:
          adsTodayLabel,
      maxBoostsInfoText:
          '$_adsToday/$_maxAdsPerDay',
      onPressed:
          canUse ? _watchAd : null,
    );
  }

  // ============================================================
  // 👋 GREETING
  // ============================================================

  Widget _buildGreeting() {
    final String greeting =
        _username.isEmpty
            ? _t('welcome')
            : '${_t('welcome')}, $_username';

    return HomeGreeting(
      greeting: greeting,
      subtitle: _t('stellaWelcome'),
      primaryTextColor: primaryTextColor,
      secondaryTextColor: secondaryTextColor,
    );
  }

  // ============================================================
  // 🐱 FOOTER
  // ============================================================

  Widget _buildStellaFooter() {
    return Padding(
      padding:
          const EdgeInsets.only(
        top: 20,
        bottom: 18,
      ),
      child: Column(
        children: [
          const Text(
            '🐱💜⛏️',
            style: TextStyle(
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t('footerMiningFuture'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'STELLURIINI • STL',
            style: TextStyle(
              color: accentColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          if (_appVersion.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              _buildNumber.isNotEmpty
                  ? '${_t('appVersion')} '
                    '$_appVersion '
                    '(build $_buildNumber)'
                  : '${_t('appVersion')} '
                    '$_appVersion',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: secondaryTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 8),
          const SelectableText(
            'stelluriini.app@gmail.com',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accentColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          if (_adManager
              .privacyOptionsRequired) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed:
                  _showPrivacyOptions,
              icon: const Icon(
                Icons.privacy_tip_outlined,
                size: 18,
              ),
              label: Text(
                _privacyOptionsLabel(),
              ),
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    accentColor,
                side: BorderSide(
                  color: accentColor
                      .withValues(
                    alpha: 0.45,
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // 🔐 PRIVACY OPTIONS
  // ============================================================

  void _showPrivacyOptions() {
    if (!_adManager
        .privacyOptionsRequired) {
      return;
    }

    _adManager
        .showPrivacyOptionsForm();
  }

  String _privacyOptionsLabel() {
    switch (widget.languageCode) {
      case 'fi':
        return 'Tietosuoja-asetukset';

      case 'de':
        return 'Datenschutzeinstellungen';

      case 'es':
        return 'Opciones de privacidad';

      case 'fr':
        return 'Options de confidentialité';

      case 'zh':
        return '隐私选项';

      case 'vi':
        return 'Tùy chọn quyền riêng tư';

      case 'ja':
        return 'プライバシー設定';

      case 'en':
      default:
        return 'Privacy options';
    }
  }

  // ============================================================
  // 🏠 MAIN BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          backgroundColor,
      drawer: HomeDrawer(
        languageCode:
            widget.languageCode,
        onLanguagePressed:
            _showLanguageDialog,
        onAboutPressed:
            _openAbout,
        onWhitePaperPressed:
            _openWhitePaper,
        onRoadmapPressed:
            _openRoadmap,
        onAchievementsPressed:
            _openAchievements,
        onTransactionHistoryPressed:
            _openTransactionHistory,
        onReferralPressed:
            _openReferrals,
        onAccountDeletionPressed:
            _openAccountDeletion,
        onLogoutPressed:
            _logout,
      ),
      body:
          StelluriiniSpaceBackground(
        overlayOpacity: 0.48,
        child: SafeArea(
          child: _loading
              ? const Center(
                  child:
                      CircularProgressIndicator(
                    color: accentColor,
                  ),
                )
              : RefreshIndicator(
                  color: accentColor,
                  backgroundColor:
                      cardColor,
                  onRefresh:
                      _loadMiningStatus,
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.fromLTRB(
                      0,
                      0,
                      0,
                      12,
                    ),
                    children: [
                      const HomeHeader(
                        primaryTextColor:
                            primaryTextColor,
                      ),
                      _buildGreeting(),
                      const SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        child:
                            _buildStellaMiningCard(),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        child:
                            _buildStatsRow(),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        child:
                            _buildAdButton(),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        child:
                            _buildDailyCatFact(),
                      ),
                      _buildStellaFooter(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // ============================================================
  // 🔢 SAFE CONVERTERS
  // ============================================================

  double? _asDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      final double result =
          value.toDouble();

      return result.isFinite
          ? result
          : null;
    }

    if (value is String) {
      final double? result =
          double.tryParse(
        value.trim(),
      );

      if (result != null &&
          result.isFinite) {
        return result;
      }
    }

    return null;
  }

  int? _asInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(
        value.trim(),
      );
    }

    return null;
  }

  bool? _asBool(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is bool) {
      return value;
    }

    if (value is String) {
      final String normalized =
          value.trim().toLowerCase();

      if (normalized == 'true') {
        return true;
      }

      if (normalized == 'false') {
        return false;
      }
    }

    if (value is num) {
      if (value == 1) {
        return true;
      }

      if (value == 0) {
        return false;
      }
    }

    return null;
  }

  // ============================================================
  // ⏱️ FORMAT DURATION
  // ============================================================

  String _formatDuration(
    int milliseconds,
  ) {
    final int safeMs =
        milliseconds < 0
            ? 0
            : milliseconds;

    final int totalSeconds =
        safeMs ~/ 1000;

    final int hours =
        totalSeconds ~/ 3600;

    final int minutes =
        (totalSeconds % 3600) ~/ 60;

    final int seconds =
        totalSeconds % 60;

    final String hoursText =
        hours.toString().padLeft(
              2,
              '0',
            );

    final String minutesText =
        minutes.toString().padLeft(
              2,
              '0',
            );

    final String secondsText =
        seconds.toString().padLeft(
              2,
              '0',
            );

    return '$hoursText:'
        '$minutesText:'
        '$secondsText';
  }

  // ============================================================
  // 🔢 FORMAT NUMBER
  // ============================================================

  String _formatNumber(
    double value,
  ) {
    if (!value.isFinite) {
      return '0';
    }

    if (value.abs() >= 1000) {
      return value.toStringAsFixed(2);
    }

    if (value ==
        value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  // ============================================================
  // ⚠️ ERROR TEXT
  // ============================================================

  String _errorText(Object error) {
    if (error
        is FirebaseFunctionsException) {
      final String? message =
          error.message?.trim();

      if (message != null &&
          message.isNotEmpty) {
        return message;
      }

      return error.code;
    }

    final String text =
        error.toString();

    if (text.startsWith(
      'Exception: ',
    )) {
      return text.substring(
        'Exception: '.length,
      );
    }

    return text;
  }

  // ============================================================
  // 📺 AD LOAD ERROR TEXT
  // ============================================================

  String _adLoadErrorText(
    String purpose,
    LoadAdError error,
  ) {
    final String message =
        error.message.trim();

    if (message.isNotEmpty) {
      return message;
    }

    return purpose ==
            HomeAdManager.powerBoostPurpose
        ? _t('adNotAvailable')
        : _t('prepareAd');
  }

  // ============================================================
  // 📺 AD SHOW ERROR TEXT
  // ============================================================

  String _adShowErrorText(
    String purpose,
    AdError error,
  ) {
    final String message =
        error.message.trim();

    if (message.isNotEmpty) {
      return message;
    }

    return purpose ==
            HomeAdManager.powerBoostPurpose
        ? _t('adNotAvailable')
        : _t('prepareAd');
  }

  // ============================================================
  // 💬 MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: primaryTextColor,
            ),
          ),
          backgroundColor:
              cardColor,
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      );
  }
}