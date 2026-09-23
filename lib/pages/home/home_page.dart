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

  static const double defaultAdHashRateBonus = 0.5833;
  static const int defaultMaxAdsPerDay = 6;
  static const double defaultDailyHashRate = 0.5;
  static const double miningPerHashPerHour = 0.10;
  static const int defaultMiningDurationMs =
      24 * 60 * 60 * 1000;

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

  int _adCooldownMs = 4 * 60 * 60 * 1000;
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

    final displayName = user.displayName?.trim() ?? '';

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
              _asDouble(data['effectiveHashRate']) ??
              _asDouble(data['dailyHashRate']) ??
              defaultDailyHashRate;

      final unclaimed =
          _asDouble(data['unclaimedMining']) ??
              _asDouble(data['unclaimed']) ??
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
              _adCooldownMs;

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
        _hashRate = hashRate;
        _unclaimedMining = unclaimed;
        _estimatedTotal = total;

        _miningDurationMs = safeDuration;
        _miningRemainingMs =
            remaining.clamp(0, safeDuration);

        _streak = streak.clamp(1, 7);

        _adsToday = adsToday.clamp(0, maxAds);
        _maxAdsPerDay = maxAds;

        _adHashRateBonus = adBonus;
        _adCooldownMs = cooldown;
        _cooldownRemainingMs = cooldownRemaining;
        _serverCanWatchAd = serverCanWatchAd;

        _boostActive = boostActive;
        _boostRemainingMs = boostRemaining;
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
          return;
        }

        setState(() {
          _miningRemainingMs -= 1000;

          _unclaimedMining +=
              (_effectiveHashRate * miningPerHashPerHour) /
                  3600;
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
    if (_actionLoading || _miningActive) return;

    if (_adManager.miningAdFlowActive) return;

    setState(() => _actionLoading = true);

    try {
      final shown =
          await _adManager.showMiningStartAd();

      if (!shown && mounted) {
        setState(() => _actionLoading = false);
        _showMessage('⚠️ ${_t('prepareAd')}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _actionLoading = false);
        _showMessage('⚠️ ${_errorText(e)}');
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

      if (raw is Map) {
        final data = Map<String, dynamic>.from(raw);

        final started =
            _asBool(data['started']) ??
                _asBool(data['miningStarted']) ??
                true;

        if (started && mounted) {
          final streak =
              _asInt(data['dailyStreak']) ?? _streak;

          setState(() {
            _miningActive = true;
            _streak = streak.clamp(1, 7);
          });
        }
      }

      await _loadMiningStatus();

      if (mounted) {
        _showMessage('🐱 ${_t('miningStarted')}');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('⚠️ ${_errorText(e)}');
      }
    } finally {
      if (mounted) {
        setState(() => _actionLoading = false);
      }
    }
  }

  Future<void> _watchAd() async {
    if (_actionLoading) return;

    if (!_miningActive || _miningRemainingMs <= 0) {
      _showMessage('🐱 Aloita louhinta ensin');
      return;
    }

    if (!_canUseBoost) {
      _showMessage('🐱 ${_t('maxBoostsInfo')}');
      return;
    }

    setState(() => _actionLoading = true);

    try {
      final shown =
          await _adManager.showPowerBoostAd();

      if (!shown && mounted) {
        setState(() => _actionLoading = false);
        _showMessage('⚠️ ${_t('adNotAvailable')}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _actionLoading = false);
        _showMessage('⚠️ ${_errorText(e)}');
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
        throw Exception('Invalid Power Boost response.');
      }

      final data = Map<String, dynamic>.from(raw);

      final active =
          _asBool(data['boostActive']) ??
              _asBool(data['active']) ??
              false;

      final remaining =
          _asInt(data['boostRemainingMs']) ??
              _asInt(data['remainingBoostMs']) ??
              _asInt(data['adBoostRemainingMs']) ??
              0;

      final ads = _asInt(data['adsToday']);

      final bonus =
          _asDouble(data['adHashRateBonus']) ??
              _asDouble(data['hashRateBonus']) ??
              _asDouble(data['boostHashRateBonus']);

      if (!active || remaining <= 0) {
        throw Exception(
          'Power Boost verification did not return an active boost.',
        );
      }

      if (!mounted) return;

      setState(() {
        _boostActive = true;
        _boostRemainingMs = remaining;

        if (ads != null) {
          _adsToday = ads;
        }

        if (bonus != null && bonus > 0) {
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
        _showMessage('⚠️ ${_errorText(e)}');
      }
    } finally {
      if (mounted) {
        setState(() => _actionLoading = false);
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

    setState(() => _actionLoading = false);

    _showMessage(
      '⚠️ ${_adLoadErrorText(purpose, error)}',
    );
  }

  void _handleAdShowError(
    String purpose,
    AdError error,
  ) {
    if (!mounted) return;

    setState(() => _actionLoading = false);

    _showMessage(
      '⚠️ ${_adShowErrorText(purpose, error)}',
    );
  }

  void _handleAdDismissed(String purpose) {
    if (!mounted) return;

    if (purpose == HomeAdManager.powerBoostPurpose ||
        purpose == HomeAdManager.miningStartPurpose) {
      setState(() => _actionLoading = false);
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      if (mounted) {
        _showMessage('⚠️ ${_errorText(e)}');
      }
    }
  }

  void _openAbout() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AboutPage(
          languageCode: widget.languageCode,
        ),
      ),
    );
  }

  void _openWhitePaper() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WhitePaperPage(
          languageCode: widget.languageCode,
        ),
      ),
    );
  }

  void _openRoadmap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoadmapPage(
          languageCode: widget.languageCode,
        ),
      ),
    );
  }

  void _openAchievements() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AchievementsPage(
          languageCode: widget.languageCode,
        ),
      ),
    );
  }

  void _openTransactionHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionHistoryPage(
          languageCode: widget.languageCode,
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
                    languages.keys.elementAt(index);

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
                      code == widget.languageCode
                          ? const Icon(
                              Icons.check,
                              color: accentColor,
                            )
                          : null,
                  onTap: () {
                    Navigator.of(dialogContext).pop();

                    if (code != widget.languageCode) {
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

  Widget _buildDailyCatFact() {
    return CatFactCard(
      title: _t('catFact'),
      fact: CatFacts.getDailyFact(
        languageCode: widget.languageCode,
      ),
    );
  }

  Widget _buildStellaMiningCard() {
    return StellaMiningCard(
      languageCode: widget.languageCode,
      unclaimedMining: _unclaimedMining,
      miningTitle: _t('stellaMiningTitle'),
      miningSubtitle: _t('stellaMiningSubtitle'),
      timerText: _formatDuration(_miningRemainingMs),
      timerLabel: _t('miningTimeRemaining'),
      catAnimation: _catAnimation,
      miningActive: _miningActive,
      miningRemainingMs: _miningRemainingMs,
      miningDurationMs: _miningDurationMs,
      miningProgressTitle: _t('miningProgress'),
      stlPerHourText:
          '${_formatNumber(
        _effectiveHashRate * miningPerHashPerHour,
      )} STL/h',
      dailyHashRateText:
          '${_formatNumber(_effectiveHashRate)} H/s',
      dailyHashRateDayText:
          '${_t('day')} $_streak',
      dailyStreak: _streak,
      boostActive: _boostActive,
      miningButton: _buildMiningButton(),
    );
  }

  Widget _buildStatsRow() {
    return HomeStatsCard(
      hashRateTitle: _t('hashRate'),
      hashRateValue:
          '${_formatNumber(_effectiveHashRate)} H/s',
      totalStlTitle: _t('totalStl'),
      totalStlValue:
          '${_formatNumber(_estimatedTotal)} STL',
    );
  }

  Widget _buildAdButton() {
    final canUse = _canUseBoost;

    final adsTodayLabel =
        AppLocalizations.forLanguage(
      widget.languageCode,
    ).getWithParams(
      'adsToday',
      params: {
        'current': _adsToday.toString(),
        'max': _maxAdsPerDay.toString(),
      },
    );

    final subtitle = _boostActive
        ? _t('powerBoostActive')
        : _t('watchAdSubtitle');

    final remainingText =
        AppLocalizations.forLanguage(
      widget.languageCode,
    ).getWithParams(
      'remaining',
      params: {
        'time': _formatDuration(_boostRemainingMs),
      },
    );

    return PowerBoostCard(
      boostActive: _boostActive,
      boostRemainingMs: _boostRemainingMs,
      adsToday: _adsToday,
      maxAdsPerDay: _maxAdsPerDay,
      canUse: canUse,
      subtitle: subtitle,
      title: _t('powerBoost'),
      activeText: _t('active'),
      activeTitle: _t('powerBoostActive'),
      remainingText: remainingText,
      hashRateBonusText:
          '+${_formatNumber(_adHashRateBonus)} H/s',
      effectiveHashRateText:
          '${_formatNumber(_effectiveHashRate)} H/s',
      nextAdAfterBoostText: _t('nextAdAfterBoost'),
      watchAdText: _t('watchAd'),
      adsTodayText: adsTodayLabel,
      maxBoostsInfoText:
          '$_adsToday/$_maxAdsPerDay',
      onPressed: canUse ? _watchAd : null,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
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
                  Scaffold.of(context).openDrawer();
                },
                icon: const Icon(
                  Icons.menu_rounded,
                  color: primaryTextColor,
                  size: 30,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Center(
              child: StelluriiniLogo(size: 48),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: primaryTextColor,
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _t('stellaWelcome'),
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiningButton() {
    final disabled =
        _actionLoading || _miningActive;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton(
          onPressed:
              disabled ? null : _startMining,
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: backgroundColor,
            disabledBackgroundColor:
                accentColor.withValues(alpha: 0.35),
            disabledForegroundColor:
                primaryTextColor.withValues(alpha: 0.6),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: _actionLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: backgroundColor,
                  ),
                )
              : Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.pets_rounded,
                      size: 25,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _miningActive
                          ? _t('miningActive')
                          : _t('startMining'),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        24,
        24,
        30,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.pets_rounded,
            color: pinkColor,
            size: 22,
          ),
          const SizedBox(height: 8),
          const Text(
            'Stelluriini (STL)',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _t('stelluriiniStlSolanaFooter'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const StelluriiniLogo(size: 76),
                const SizedBox(height: 22),
                const CircularProgressIndicator(
                  color: accentColor,
                ),
                const SizedBox(height: 18),
                Text(
                  _t('loading'),
                  style: const TextStyle(
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: HomeDrawer(
        languageCode: widget.languageCode,
        onLanguagePressed: _showLanguageDialog,
        onAboutPressed: _openAbout,
        onWhitePaperPressed: _openWhitePaper,
        onRoadmapPressed: _openRoadmap,
        onAchievementsPressed: _openAchievements,
        onTransactionHistoryPressed:
            _openTransactionHistory,
        onLogoutPressed: _logout,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: accentColor,
          backgroundColor: cardColor,
          onRefresh: _loadMiningStatus,
          child: CustomScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),
              SliverToBoxAdapter(
                child: _buildGreeting(),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 12),
              ),
              SliverToBoxAdapter(
                child: _buildStellaMiningCard(),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 16),
              ),
              SliverToBoxAdapter(
                child: _buildStatsRow(),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 14),
              ),
              SliverToBoxAdapter(
                child: _buildAdButton(),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 14),
              ),
              SliverToBoxAdapter(
                child: _buildDailyCatFact(),
              ),
              SliverToBoxAdapter(
                child: _buildFooter(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double get _effectiveHashRate {
    if (_boostActive && _boostRemainingMs > 0) {
      return _hashRate + _adHashRateBonus;
    }

    return _hashRate;
  }

  bool get _canUseBoost {
    if (_actionLoading) return false;

    if (_adsToday >= _maxAdsPerDay) {
      return false;
    }

    if (_boostActive && _boostRemainingMs > 0) {
      return false;
    }

    if (_adManager.powerBoostAdFlowActive) {
      return false;
    }

    if (_cooldownRemainingMs > 0) {
      return false;
    }

    if (!_serverCanWatchAd) {
      return false;
    }

    return true;
  }

  String _formatDuration(int milliseconds) {
    if (milliseconds <= 0) {
      return '00:00:00';
    }

    final totalSeconds = milliseconds ~/ 1000;
    final hours = totalSeconds ~/ 3600;
    final minutes =
        (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String _formatNumber(double value) {
    if (!value.isFinite) {
      return '0.0000';
    }

    return value.toStringAsFixed(4);
  }

  String _errorText(Object error) {
    if (error is FirebaseFunctionsException) {
      final message = error.message?.trim();

      if (message != null && message.isNotEmpty) {
        return message;
      }

      return error.code;
    }

    return error
        .toString()
        .replaceFirst('Exception: ', '');
  }

  String _adLoadErrorText(
    String purpose,
    LoadAdError error,
  ) {
    if (error.code == 3) {
      return '${_t('adNotAvailable')} (${error.code})';
    }

    final message = error.message.trim();

    if (message.isNotEmpty) {
      return message;
    }

    return '${_t('adLoadError')} (${error.code})';
  }

  String _adShowErrorText(
    String purpose,
    AdError error,
  ) {
    final message = error.message.trim();

    if (message.isNotEmpty) {
      return message;
    }

    return '${_t('adShowError')} (${error.code})';
  }

  String _t(String key) {
    return AppLocalizations
        .forLanguage(widget.languageCode)
        .get(key);
  }

  double? _asDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  bool? _asBool(dynamic value) {
    if (value == null) return null;

    if (value is bool) {
      return value;
    }

    if (value is String) {
      final normalized =
          value.toLowerCase().trim();

      if (normalized == 'true' ||
          normalized == '1') {
        return true;
      }

      if (normalized == 'false' ||
          normalized == '0') {
        return false;
      }
    }

    return null;
  }

  void _showMessage(String message) {
    if (!mounted) return;

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
          backgroundColor: surfaceColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }
}