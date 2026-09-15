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
  // ============================================================
  // THEME
  // ============================================================

  static const Color backgroundColor = Color(0xFF120B24);
  static const Color surfaceColor = Color(0xFF1A0E31);
  static const Color cardColor = Color(0xFF21113B);
  static const Color accentColor = Color(0xFFB58CFF);
  static const Color pinkColor = Color(0xFFFFB7E8);

  static const Color primaryTextColor = Color(0xFFF8F4FF);
  static const Color secondaryTextColor = Color(0xFFBDB4D1);

  // ============================================================
  // MINING CONFIG
  // ============================================================

  static const double defaultAdHashRateBonus = 0.5833;
  static const int defaultMaxAdsPerDay = 6;

  static const double defaultDailyHashRate = 0.5;
  static const double dailyHashRateStep = 0.5;
  static const double maximumDailyHashRate = 3.5;

  static const double miningPerHashPerHour = 0.10;

  static const int defaultMiningDurationMs =
      24 * 60 * 60 * 1000;

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  // ============================================================
  // STATE
  // ============================================================

  bool _loading = true;
  bool _actionLoading = false;
  bool _miningActive = false;

  double _hashRate = defaultDailyHashRate;
  double _unclaimedMining = 0.0;
  double _estimatedTotal = 0.0;

  int _miningDurationMs = defaultMiningDurationMs;
  int _miningRemainingMs = 0;

  int _streak = 1;

  double _dailyHashRate = defaultDailyHashRate;

  int _adsToday = 0;
  int _maxAdsPerDay = defaultMaxAdsPerDay;

  double _adHashRateBonus = defaultAdHashRateBonus;

  int _adCooldownMs = 4 * 60 * 60 * 1000;

  bool _boostActive = false;
  int _boostRemainingMs = 0;

  String _username = '';

  Timer? _miningTimer;
  Timer? _boostTimer;
  Timer? _refreshTimer;

  late final AnimationController _catAnimation;

  late final HomeAdManager _adManager;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _catAnimation = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1800,
      ),
    );

    _catAnimation.repeat(reverse: true);

    _adManager = HomeAdManager(
      onMiningStartReward: _startMiningAfterAd,
      onPowerBoostReward: _waitForServerSidePowerBoost,
      onAdLoadError: _handleAdLoadError,
      onAdShowError: _handleAdShowError,
      onAdDismissed: _handleAdDismissed,
    );

    _adManager.addListener(
      _onAdManagerChanged,
    );

    _initialize();
  }

  @override
  void dispose() {
    _miningTimer?.cancel();
    _boostTimer?.cancel();
    _refreshTimer?.cancel();

    _adManager.removeListener(
      _onAdManagerChanged,
    );

    _adManager.dispose();

    _catAnimation.dispose();

    super.dispose();
  }

  // ============================================================
  // INITIALIZATION
  // ============================================================

  Future<void> _initialize() async {
    try {
      await _loadUsername();
      await _loadMiningStatus();
    } catch (e) {
      if (mounted) {
        _showMessage(
          '⚠️ ${_errorText(e)}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }

    _startRefreshTimer();
  }

  Future<void> _loadUsername() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      final HttpsCallableResult<dynamic> result =
          await _functions
              .httpsCallable(
                'getUserProfile',
              )
              .call();

      final dynamic raw = result.data;

      if (raw is Map) {
        final Map<String, dynamic> data =
            Map<String, dynamic>.from(raw);

        final String username =
            data['username']?.toString().trim() ?? '';

        if (mounted && username.isNotEmpty) {
          setState(() {
            _username = username;
          });

          return;
        }
      }
    } catch (_) {
      // Firebase Auth toimii varavaihtoehtona.
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
  // MINING STATUS
  // ============================================================

  Future<void> _loadMiningStatus() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      final HttpsCallableResult<dynamic> result =
          await _functions
              .httpsCallable(
                'getMiningStatus',
              )
              .call();

      final dynamic raw = result.data;

      if (raw is! Map) {
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
              _asDouble(data['effectiveHashRate']) ??
              _asDouble(data['dailyHashRate']) ??
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

      final double dailyHashRate =
          _asDouble(data['dailyHashRate']) ??
              _calculateDailyHashRate(streak);

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

      final int cooldown =
          _asInt(data['adCooldownMs']) ??
              _adCooldownMs;

      final bool boostActive =
          _asBool(data['boostActive']) ??
              false;

      final int boostRemaining =
          _asInt(data['boostRemainingMs']) ??
              _asInt(data['remainingBoostMs']) ??
              0;

      if (!mounted) {
        return;
      }

      final int safeDuration =
          duration > 0
              ? duration
              : defaultMiningDurationMs;

      setState(() {
        _miningActive = miningActive;

        _hashRate = hashRate;

        _unclaimedMining = unclaimed;

        _estimatedTotal = total;

        _miningDurationMs = safeDuration;

        _miningRemainingMs =
            remaining.clamp(
          0,
          safeDuration,
        );

        _streak = streak.clamp(1, 7);

        _dailyHashRate =
            dailyHashRate.clamp(
          defaultDailyHashRate,
          maximumDailyHashRate,
        );

        _adsToday = adsToday.clamp(
          0,
          maxAds,
        );

        _maxAdsPerDay = maxAds;

        _adHashRateBonus = adBonus;

        _adCooldownMs = cooldown;

        _boostActive = boostActive;

        _boostRemainingMs = boostRemaining;
      });

      _startMiningTimer();
      _startBoostTimer();
    } catch (e) {
      if (mounted) {
        _showMessage(
          '⚠️ ${_errorText(e)}',
        );
      }
    }
  }

  // ============================================================
  // REFRESH TIMER
  // ============================================================

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

  // ============================================================
  // MINING TIMER
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
          return;
        }

        setState(() {
          _miningRemainingMs -= 1000;

          _unclaimedMining +=
              (_effectiveHashRate *
                  miningPerHashPerHour) /
              3600.0;
        });
      },
    );
  }

  // ============================================================
  // BOOST TIMER
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
          return;
        }

        setState(() {
          _boostRemainingMs -= 1000;
        });
      },
    );
  }

  // ============================================================
  // MINING START
  // ============================================================

  Future<void> _startMining() async {
    if (_actionLoading || _miningActive) {
      return;
    }

    if (_adManager.miningAdFlowActive) {
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
  // MINING START AFTER AD
  // ============================================================

  Future<void> _startMiningAfterAd() async {
    if (!mounted) {
      return;
    }

    try {
      HttpsCallableResult<dynamic>? result;

      Object? lastError;

      for (int attempt = 0;
          attempt < 15;
          attempt++) {
        try {
          result = await _functions
              .httpsCallable(
                'claimMining',
              )
              .call();

          break;
        } catch (e) {
          lastError = e;

          final String text =
              e.toString().toLowerCase();

          final bool retryable =
              text.contains('admob') ||
                  text.contains('reward') ||
                  text.contains('mining_start') ||
                  text.contains('mining start') ||
                  text.contains('verified');

          if (!retryable || attempt == 14) {
            rethrow;
          }

          await Future.delayed(
            const Duration(seconds: 2),
          );
        }
      }

      if (result == null) {
        throw lastError ??
            Exception(
              'Mining start failed.',
            );
      }

      final dynamic raw = result.data;

      if (raw is Map) {
        final Map<String, dynamic> data =
            Map<String, dynamic>.from(raw);

        final bool started =
            _asBool(data['started']) ??
                _asBool(data['miningStarted']) ??
                true;

        if (started && mounted) {
          final int streak =
              _asInt(data['dailyStreak']) ??
                  _streak;

          final double dailyHash =
              _asDouble(data['dailyHashRate']) ??
                  _calculateDailyHashRate(
                    streak,
                  );

          setState(() {
            _miningActive = true;

            _streak = streak.clamp(1, 7);

            _dailyHashRate =
                dailyHash.clamp(
              defaultDailyHashRate,
              maximumDailyHashRate,
            );
          });
        }
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
        setState(() {
          _actionLoading = false;
        });
      }
    }
  }

  // ============================================================
  // POWER BOOST
  // ============================================================

  Future<void> _watchAd() async {
    if (_actionLoading) {
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
  // POWER BOOST BACKEND VERIFICATION
  // ============================================================

  Future<void> _waitForServerSidePowerBoost() async {
    try {
      await Future.delayed(
        const Duration(seconds: 1),
      );

      bool verified = false;

      for (int attempt = 0;
          attempt < 15;
          attempt++) {
        try {
          final HttpsCallableResult<dynamic> result =
              await _functions
                  .httpsCallable(
                    'powerBoost',
                  )
                  .call();

          final dynamic raw = result.data;

          if (raw is Map) {
            final Map<String, dynamic> data =
                Map<String, dynamic>.from(raw);

            final bool active =
                _asBool(data['boostActive']) ??
                    _asBool(data['active']) ??
                    true;

            final int remaining =
                _asInt(
                      data['boostRemainingMs'],
                    ) ??
                    _asInt(
                      data['remainingBoostMs'],
                    ) ??
                    4 *
                        60 *
                        60 *
                        1000;

            if (mounted) {
              setState(() {
                _boostActive = active;

                _boostRemainingMs = remaining;

                final int? ads =
                    _asInt(data['adsToday']);

                if (ads != null) {
                  _adsToday = ads;
                }
              });
            }
          }

          verified = true;
          break;
        } catch (e) {
          final String text =
              e.toString().toLowerCase();

          final bool retryable =
              text.contains('admob') ||
                  text.contains('reward') ||
                  text.contains('verified') ||
                  text.contains('power boost');

          if (!retryable || attempt == 14) {
            rethrow;
          }

          await Future.delayed(
            const Duration(seconds: 2),
          );
        }
      }

      if (verified) {
        await _loadMiningStatus();

        if (mounted) {
          _showMessage(
            '🐾 ${_t('powerBoostActive')}',
          );
        }
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
  // ADMOB CALLBACKS
  // ============================================================

  void _onAdManagerChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

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

  void _handleAdDismissed(
    String purpose,
  ) {
    // Reward callback käsittelee tarvittaessa
    // backend-vahvistuksen ennen lataustilan
    // vapauttamista.
  }

  // ============================================================
  // DRAWER
  // ============================================================

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

  // ============================================================
  // LANGUAGE
  // ============================================================

  Future<void> _showLanguageDialog() async {
    final Map<String, String> languages =
        AppLocalizations.supportedLanguages;

    await showDialog<void>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
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
              itemBuilder: (
                BuildContext context,
                int index,
              ) {
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
  // CAT FACT
  // ============================================================

  Widget _buildDailyCatFact() {
    final String fact =
        CatFacts.getDailyFact(
      languageCode:
          widget.languageCode,
    );

    return CatFactCard(
      title: _t('catFact'),
      fact: fact,
    );
  }

  // ============================================================
  // STELLA MINING CARD
  // ============================================================

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
        _hashRate *
            miningPerHashPerHour,
      )} STL/h',
      dailyHashRateText:
          '${_formatNumber(
        _dailyHashRate,
      )} H/s',
      dailyHashRateDayText:
          '${_t('day')} $_streak',
      dailyStreak:
          _streak,
    );
  }

  // ============================================================
  // STATS CARD
  // ============================================================

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

  // ============================================================
  // POWER BOOST CARD
  // ============================================================

  Widget _buildAdButton() {
    final bool canUse =
        _canUseBoost;

    final String subtitle =
        _boostActive
            ? _t('powerBoostActive')
            : _t('watchAdSubtitle');

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
          _t('remaining'),
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
          _t('adsToday'),
      maxBoostsInfoText:
          '$_adsToday/$_maxAdsPerDay',
      onPressed:
          canUse
              ? _watchAd
              : null,
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

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
            builder:
                (BuildContext context) {
              return IconButton(
                onPressed: () {
                  Scaffold.of(
                    context,
                  ).openDrawer();
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
          const SizedBox(
            width: 8,
          ),
          const Expanded(
            child: Center(
              child: StelluriiniLogo(
                size: 48,
              ),
            ),
          ),
          const SizedBox(
            width: 54,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GREETING
  // ============================================================

  Widget _buildGreeting() {
    final String greeting =
        _username.isEmpty
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
              color: primaryTextColor,
              fontSize: 23,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
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

  // ============================================================
  // START MINING BUTTON
  // ============================================================

  Widget _buildMiningButton() {
    final bool disabled =
        _actionLoading ||
            _miningActive;

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 22,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton(
          onPressed:
              disabled
                  ? null
                  : _startMining,
          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                accentColor,
            foregroundColor:
                backgroundColor,
            disabledBackgroundColor:
                accentColor.withValues(
              alpha: 0.35,
            ),
            disabledForegroundColor:
                primaryTextColor
                    .withValues(
              alpha: 0.6,
            ),
            elevation: 0,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
            ),
          ),
          child:
              _actionLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color:
                            backgroundColor,
                      ),
                    )
                  : Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        const Icon(
                          Icons
                              .pets_rounded,
                          size: 25,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          _miningActive
                              ? _t(
                                  'miningActive',
                                )
                              : _t(
                                  'startMining',
                                ),
                          style:
                              const TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================

  Widget _buildFooter() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
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
          const SizedBox(
            height: 8,
          ),
          const Text(
            'Stelluriini (STL)',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primaryTextColor,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            _t(
              'stelluriiniStlSolanaFooter',
            ),
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (_loading) {
      return Scaffold(
        backgroundColor:
            backgroundColor,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const StelluriiniLogo(
                  size: 76,
                ),
                const SizedBox(
                  height: 22,
                ),
                const CircularProgressIndicator(
                  color: accentColor,
                ),
                const SizedBox(
                  height: 18,
                ),
                Text(
                  _t('loading'),
                  style:
                      const TextStyle(
                    color:
                        secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
        onLogoutPressed:
            _logout,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: accentColor,
          backgroundColor:
              cardColor,
          onRefresh:
              _loadMiningStatus,
          child: CustomScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child:
                    _buildHeader(),
              ),
              SliverToBoxAdapter(
                child:
                    _buildGreeting(),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 12,
                ),
              ),
              SliverToBoxAdapter(
                child:
                    _buildStellaMiningCard(),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 14,
                ),
              ),
              SliverToBoxAdapter(
                child:
                    _buildMiningButton(),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 16,
                ),
              ),
              SliverToBoxAdapter(
                child:
                    _buildStatsRow(),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 14,
                ),
              ),
              SliverToBoxAdapter(
                child:
                    _buildAdButton(),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 14,
                ),
              ),
              SliverToBoxAdapter(
                child:
                    _buildDailyCatFact(),
              ),
              SliverToBoxAdapter(
                child:
                    _buildFooter(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CALCULATED VALUES
  // ============================================================

  double get _effectiveHashRate {
    if (_boostActive) {
      return _hashRate +
          _adHashRateBonus;
    }

    return _hashRate;
  }

  bool get _canUseBoost {
    if (_actionLoading) {
      return false;
    }

    if (_adsToday >=
        _maxAdsPerDay) {
      return false;
    }

    if (_boostActive) {
      return false;
    }

    if (_adManager
        .powerBoostAdFlowActive) {
      return false;
    }

    return true;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  double _calculateDailyHashRate(
    int streak,
  ) {
    final int day =
        streak.clamp(1, 7);

    final double value =
        defaultDailyHashRate +
            ((day - 1) *
                dailyHashRateStep);

    return value.clamp(
      defaultDailyHashRate,
      maximumDailyHashRate,
    );
  }

  String _formatDuration(
    int milliseconds,
  ) {
    if (milliseconds <= 0) {
      return '00:00:00';
    }

    final int totalSeconds =
        milliseconds ~/ 1000;

    final int hours =
        totalSeconds ~/ 3600;

    final int minutes =
        (totalSeconds % 3600) ~/ 60;

    final int seconds =
        totalSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String _formatNumber(
    double value,
  ) {
    if (!value.isFinite) {
      return '0.0000';
    }

    return value.toStringAsFixed(4);
  }

  String _errorText(
    Object error,
  ) {
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

    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        );
  }

  String _adLoadErrorText(
    String purpose,
    LoadAdError error,
  ) {
    if (error.code == 3) {
      return '${_t('adNotAvailable')} '
          '(${error.code})';
    }

    final String message =
        error.message.trim();

    if (message.isNotEmpty) {
      return message;
    }

    return '${_t('adLoadError')} '
        '(${error.code})';
  }

  String _adShowErrorText(
    String purpose,
    AdError error,
  ) {
    final String message =
        error.message.trim();

    if (message.isNotEmpty) {
      return message;
    }

    return '${_t('adShowError')} '
        '(${error.code})';
  }

  String _t(
    String key,
  ) {
    final AppLocalizations localizations =
        AppLocalizations.of(context);

    return localizations.t(
      key,
      languageCode:
          widget.languageCode,
    );
  }

  // ============================================================
  // CONVERSION HELPERS
  // ============================================================

  double? _asDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  int? _asInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }

  bool? _asBool(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is bool) {
      return value;
    }

    if (value is String) {
      final String normalized =
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

  // ============================================================
  // SNACKBAR
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
              color:
                  primaryTextColor,
            ),
          ),
          backgroundColor:
              surfaceColor,
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(
            16,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
        ),
      );
  }
}