import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../data/cat_facts.dart';
import '../../localization.dart';
import '../../widgets/home_drawer.dart';
import '../../widgets/stelluriini_logo.dart';
import '../about/about_page.dart';
import '../achievements/achievements_page.dart';
import '../history/transaction_history_page.dart';
import '../roadmap/roadmap_page.dart';
import '../whitepaper/whitepaper_page.dart';
import 'cat_fact_card.dart';
import 'home_ad_manager.dart';
import 'home_stats_card.dart';
import 'power_boost_card.dart';
import 'stella_mining_card.dart';

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
  static const Color backgroundColor = Color(0xFF120B24);
  static const Color surfaceColor = Color(0xFF1A0E31);
  static const Color cardColor = Color(0xFF21113B);
  static const Color accentColor = Color(0xFFB58CFF);
  static const Color pinkColor = Color(0xFFFFB7E8);
  static const Color primaryTextColor = Color(0xFFF8F4FF);
  static const Color secondaryTextColor = Color(0xFFBDB4D1);

  // These defaults mirror the current server-side mining configuration.
  static const double defaultAdHashRateBonus = 5.0;
  static const int defaultMaxAdsPerDay = 5;
  static const double defaultDailyHashRate = 1.0;
  static const double miningPerHashPerHour = 0.10;

  static const int defaultMiningDurationMs =
      24 * 60 * 60 * 1000;

  static const int defaultAdCooldownMs =
      60 * 60 * 1000;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  late final AnimationController _catAnimation;
  late final HomeAdManager _adManager;

  Timer? _miningTimer;
  Timer? _boostTimer;
  Timer? _refreshTimer;

  bool _loading = true;
  bool _actionLoading = false;
  bool _miningActive = false;

  double _hashRate = defaultDailyHashRate;
  double _unclaimedMining = 0;
  double _estimatedTotal = 0;

  int _miningDurationMs = defaultMiningDurationMs;
  int _miningRemainingMs = 0;
  int _streak = 1;

  int _adsToday = 0;
  int _maxAdsPerDay = defaultMaxAdsPerDay;

  double _adHashRateBonus = defaultAdHashRateBonus;

  int _adCooldownMs = defaultAdCooldownMs;
  int _cooldownRemainingMs = 0;

  bool _serverCanWatchAd = true;

  bool _boostActive = false;
  int _boostRemainingMs = 0;

  String _username = '';

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

  Future<void> _initialize() async {
    try {
      await _loadUsername();
      await _loadMiningStatus();
    } catch (e) {
      if (mounted) {
        _showMessage('⚠️ ${_errorText(e)}');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }

    _startRefreshTimer();
  }

  Future<void> _loadUsername() async {
    final User? user = _auth.currentUser;

    if (user == null) return;

    try {
      final result = await _functions
          .httpsCallable('getUserProfile')
          .call();

      final dynamic raw = result.data;

      if (raw is Map) {
        final data = Map<String, dynamic>.from(raw);

        final username =
            data['username']?.toString().trim() ?? '';

        if (mounted && username.isNotEmpty) {
          setState(() => _username = username);
          return;
        }
      }
    } catch (_) {}

    final displayName =
        user.displayName?.trim() ?? '';

    if (mounted && displayName.isNotEmpty) {
      setState(() => _username = displayName);
    }
  }

  Future<void> _loadMiningStatus() async {
    final User? user = _auth.currentUser;

    if (user == null) return;

    try {
      final result = await _functions
          .httpsCallable('getMiningStatus')
          .call();

      final dynamic raw = result.data;

      if (raw is! Map || !mounted) return;

      final data = Map<String, dynamic>.from(raw);

      final miningActive =
          _asBool(data['miningActive']) ??
              _asBool(data['active']) ??
              false;

      final hashRate =
          _asDouble(data['hashRate']) ??
              _asDouble(data['dailyHashRate']) ??
              _asDouble(data['effectiveHashRate']) ??
              defaultDailyHashRate;

      final unclaimed =
          _asDouble(data['unclaimedMining']) ??
              _asDouble(data['unclaimed']) ??
              _asDouble(data['miningBalance']) ??
              0;

      final total =
          _asDouble(data['estimatedTotal']) ??
              _asDouble(data['totalStl']) ??
              _asDouble(data['totalBalance']) ??
              0;

      final remaining =
          _asInt(data['miningRemainingMs']) ??
              _asInt(data['remainingMs']) ??
              _asInt(data['remainingTimeMs']) ??
              0;

      final duration =
          _asInt(data['miningDurationMs']) ??
              _asInt(data['durationMs']) ??
              defaultMiningDurationMs;

      final streak =
          _asInt(data['dailyStreak']) ??
              _asInt(data['streak']) ??
              1;

      final adsToday =
          _asInt(data['adsToday']) ??
              _asInt(data['adCountToday']) ??
              0;

      final maxAds =
          _asInt(data['maxAdsPerDay']) ??
              defaultMaxAdsPerDay;

      final adBonus =
          _asDouble(data['adHashRateBonus']) ??
              defaultAdHashRateBonus;

      final cooldown =
          _asInt(data['adCooldownMs']) ??
              defaultAdCooldownMs;

      final cooldownRemaining =
          _asInt(data['cooldownRemainingMs']) ?? 0;

      final serverCanWatchAd =
          _asBool(data['canWatchAd']) ?? true;

      final serverBoostActive =
          _asBool(data['adBoostActive']) ??
              _asBool(data['boostActive']) ??
              false;

      final serverBoostRemaining =
          _asInt(data['adBoostRemainingMs']) ??
              _asInt(data['boostRemainingMs']) ??
              _asInt(data['remainingBoostMs']) ??
              0;

      final safeDuration =
          duration > 0
              ? duration
              : defaultMiningDurationMs;

      bool boostActive = serverBoostActive;
      int boostRemaining = serverBoostRemaining;

      if (_boostActive &&
          _boostRemainingMs > 0 &&
          !serverBoostActive &&
          serverBoostRemaining <= 0) {
        boostActive = true;
        boostRemaining = _boostRemainingMs;
      }

      if (serverBoostActive &&
          serverBoostRemaining > 0 &&
          _boostRemainingMs > serverBoostRemaining) {
        boostRemaining = _boostRemainingMs;
      }

      if (boostRemaining <= 0) {
        boostActive = false;
        boostRemaining = 0;
      }

      setState(() {
        _miningActive = miningActive;
        _hashRate = hashRate.isFinite
            ? hashRate
            : defaultDailyHashRate;

        _unclaimedMining = unclaimed.isFinite
            ? unclaimed
            : 0;

        _estimatedTotal = total.isFinite
            ? total
            : 0;

        _miningDurationMs = safeDuration;

        _miningRemainingMs =
            remaining.clamp(0, safeDuration).toInt();

        _streak =
            streak.clamp(1, 7).toInt();

        _adsToday =
            adsToday.clamp(0, maxAds).toInt();

        _maxAdsPerDay =
            maxAds > 0
                ? maxAds
                : defaultMaxAdsPerDay;

        _adHashRateBonus =
            adBonus.isFinite && adBonus >= 0
                ? adBonus
                : defaultAdHashRateBonus;

        _adCooldownMs =
            cooldown > 0
                ? cooldown
                : defaultAdCooldownMs;

        _cooldownRemainingMs =
            cooldownRemaining.clamp(
              0,
              _adCooldownMs,
            ).toInt();

        _serverCanWatchAd =
            serverCanWatchAd;

        _boostActive = boostActive;
        _boostRemainingMs =
            boostRemaining.clamp(
              0,
              safeDuration,
            ).toInt();
      });

      _startMiningTimer();
      _startBoostTimer();
    } catch (e) {
      if (mounted) {
        _showMessage('⚠️ ${_errorText(e)}');
      }
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (!_loading && !_actionLoading) {
          _loadMiningStatus();
        }
      },
    );
  }

  void _startMiningTimer() {
    _miningTimer?.cancel();

    if (!_miningActive || _miningRemainingMs <= 0) {
      return;
    }

    _miningTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        if (_miningRemainingMs <= 1000) {
          setState(() {
            _miningRemainingMs = 0;
            _miningActive = false;
          });

          _miningTimer?.cancel();

          // The server is the source of truth for mining.
          // Refresh once the local countdown reaches zero.
          _loadMiningStatus();

          return;
        }

        setState(() {
          _miningRemainingMs -= 1000;
        });
      },
    );
  }

  void _startBoostTimer() {
    _boostTimer?.cancel();

    if (!_boostActive || _boostRemainingMs <= 0) {
      return;
    }

    _boostTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

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

  Future<void> _startMining() async {
    if (_actionLoading || _miningActive) {
      return;
    }

    if (_adManager.miningAdFlowActive) {
      return;
    }

    setState(() => _actionLoading = true);

    try {
      final shown =
          await _adManager.showMiningStartAd();

      if (!shown && mounted) {
        setState(() => _actionLoading = false);

        _showMessage(
          '⚠️ ${_t('prepareAd')}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _actionLoading = false);

        _showMessage(
          '⚠️ ${_errorText(e)}',
        );
      }
    }
  }

  Future<void> _startMiningAfterAd() async {
    if (!mounted) return;

    try {
      final result = await _functions
          .httpsCallable('claimMining')
          .call();

      final dynamic raw = result.data;

      if (raw is! Map) {
        throw Exception(
          'Invalid mining response.',
        );
      }

      final data =
          Map<String, dynamic>.from(raw);

      final started =
          _asBool(data['started']) ??
              _asBool(data['miningStarted']) ??
              false;

      if (!started) {
        throw Exception(
          'Mining could not be started.',
        );
      }

      if (mounted) {
        final streak =
            _asInt(data['dailyStreak']) ??
                _streak;

        setState(() {
          _miningActive = true;
          _streak =
              streak.clamp(1, 7).toInt();
        });
      }

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
        setState(
          () => _actionLoading = false,
        );
      }
    }
  }

  Future<void> _watchAd() async {
    if (_actionLoading) return;

    if (!_miningActive ||
        _miningRemainingMs <= 0) {
      _showMessage(
        '🐱 Aloita louhinta ensin',
      );
      return;
    }

    if (!_canUseBoost) {
      _showMessage(
        '🐱 ${_t('maxBoostsInfo')}',
      );
      return;
    }

    setState(() => _actionLoading = true);

    try {
      final shown =
          await _adManager.showPowerBoostAd();

      if (!shown && mounted) {
        setState(
          () => _actionLoading = false,
        );

        _showMessage(
          '⚠️ ${_t('adNotAvailable')}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _actionLoading = false,
        );

        _showMessage(
          '⚠️ ${_errorText(e)}',
        );
      }
    }
  }

  Future<void> _waitForServerSidePowerBoost() async {
    try {
      final result = await _functions
          .httpsCallable('powerBoost')
          .call();

      final dynamic raw = result.data;

      if (raw is! Map) {
        throw Exception(
          'Invalid Power Boost response.',
        );
      }

      final data =
          Map<String, dynamic>.from(raw);

      final active =
          _asBool(data['boostActive']) ??
              _asBool(data['active']) ??
              false;

      final remaining =
          _asInt(data['boostRemainingMs']) ??
              _asInt(data['remainingBoostMs']) ??
              _asInt(data['adBoostRemainingMs']) ??
              0;

      final ads =
          _asInt(data['adsToday']);

      final bonus =
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

      if (!mounted) return;

      setState(() {
        _boostActive = true;
        _boostRemainingMs = remaining;

        if (ads != null) {
          _adsToday = ads.clamp(
            0,
            _maxAdsPerDay,
          ).toInt();
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
        setState(
          () => _actionLoading = false,
        );
      }
    }
  }

  void _onAdManagerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleAdLoadError(
    String purpose,
    LoadAdError error,
  ) {
    if (!mounted) return;

    setState(
      () => _actionLoading = false,
    );

    _showMessage(
      '⚠️ ${_adLoadErrorText(purpose, error)}',
    );
  }

  void _handleAdShowError(
    String purpose,
    AdError error,
  ) {
    if (!mounted) return;

    setState(
      () => _actionLoading = false,
    );

    _showMessage(
      '⚠️ ${_adShowErrorText(purpose, error)}',
    );
  }

  void _handleAdDismissed(String purpose) {
    if (!mounted) return;

    if (purpose ==
            HomeAdManager.powerBoostPurpose ||
        purpose ==
            HomeAdManager.miningStartPurpose) {
      setState(
        () => _actionLoading = false,
      );
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      if (mounted) {
        _showMessage(
          '⚠️ ${_errorText(e)}',
        );
      }
    }
  }

  void _openAbout() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AboutPage(
          languageCode:
              widget.languageCode,
        ),
      ),
    );
  }

  void _openWhitePaper() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WhitePaperPage(
          languageCode:
              widget.languageCode,
        ),
      ),
    );
  }

  void _openRoadmap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoadmapPage(
          languageCode:
              widget.languageCode,
        ),
      ),
    );
  }

  void _openAchievements() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AchievementsPage(
          languageCode:
              widget.languageCode,
        ),
      ),
    );
  }

  void _openTransactionHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            TransactionHistoryPage(
          languageCode:
              widget.languageCode,
        ),
      ),
    );
  }

  Future<void> _showLanguageDialog() async {
    final languages =
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
                final code =
                    languages.keys.elementAt(
                  index,
                );

                final name =
                    languages[code] ?? code;

                return ListTile(
                  title: Text(
                    name,
                    style: const TextStyle(
                      color: primaryTextColor,
                    ),
                  ),
                  trailing:
                      code ==
                              widget.languageCode
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
                      widget.changeLanguage(
                        code,
                      );
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

  Widget _buildDailyCatFact() {
    return CatFactCard(
      title: _t('catFact'),
      fact: CatFacts.getDailyFact(
        languageCode:
            widget.languageCode,
      ),
    );
  }

  Widget _buildStellaMiningCard() {
    return StellaMiningCard(
      languageCode:
          widget.languageCode,
      unclaimedMining:
          _unclaimedMining,
      miningTitle:
          _t('stellaMiningTitle'),
      miningSubtitle:
          _t('stellaMiningSubtitle'),
      timerText:
          _formatDuration(
        _miningRemainingMs,
      ),
      timerLabel:
          _t('miningTimeRemaining'),
      catAnimation:
          _catAnimation,
      miningActive:
          _miningActive,
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
          '${_t('day')} $_streak',
      dailyStreak:
          _streak,
      boostActive:
          _boostActive,
      miningButton:
          _buildMiningButton(),
    );
  }

  Widget _buildStatsRow() {
    return HomeStatsCard(
      hashRateTitle:
          _t('hashRate'),
      hashRateValue:
          '${_formatNumber(
        _effectiveHashRate,
      )} H/s',
      totalStlTitle:
          _t('totalStl'),
      totalStlValue:
          '${_formatNumber(
        _estimatedTotal,
      )} STL',
    );
  }

  Widget _buildAdButton() {
    final canUse =
        _canUseBoost;

    final adsTodayLabel =
        AppLocalizations
            .forLanguage(
              widget.languageCode,
            )
            .getWithParams(
              'adsToday',
              params: {
                'current':
                    _adsToday.toString(),
                'max':
                    _maxAdsPerDay.toString(),
              },
            );

    final subtitle = _boostActive
        ? _t('powerBoostActive')
        : _t('watchAdSubtitle');

    final remainingText =
        AppLocalizations
            .forLanguage(
              widget.languageCode,
            )
            .getWithParams(
              'remaining',
              params: {
                'time':
                    _formatDuration(
                  _boostRemainingMs,
                ),
              },
            );

    return PowerBoostCard(
      boostActive:
          _boostActive,
      boostRemainingMs:
          _boostRemainingMs,
      adsToday:
          _adsToday,
      maxAdsPerDay:
          _maxAdsPerDay,
      canUse:
          canUse,
      subtitle:
          subtitle,
      title:
          _t('powerBoost'),
      activeText:
          _t('active'),
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

  Widget _buildHeader() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        10,
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) {
              return IconButton(
                onPressed: () {
                  Scaffold.of(context)
                      .openDrawer();
                },
                icon: const Icon(
                  Icons.menu_rounded,
                  color:
                      primaryTextColor,
                  size: 30,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Center(
              child: StelluriiniLogo(
                size: 48,
              ),
            ),
          ),
          const SizedBox(width: 54),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    final greeting = _username.isEmpty
        ? _t('welcome')
        : '${_t('welcome')}, $_username';

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 6,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              color:
                  primaryTextColor,
              fontSize: 23,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _t('stellaWelcome'),
            style: const TextStyle(
              color: