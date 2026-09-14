import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  const HomePage({
    super.key,
    required this.languageCode,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  // ==========================================
  // STELLURIINI COLORS
  // ==========================================

  static const Color backgroundColor = Color(0xFF120B24);
  static const Color surfaceColor = Color(0xFF1A0E31);
  static const Color cardColor = Color(0xFF21113B);
  static const Color accentColor = Color(0xFFB58CFF);
  static const Color pinkColor = Color(0xFFFFB7E8);
  static const Color goldColor = Color(0xFFFFD166);

  // ==========================================
  // MINING CONFIG
  // ==========================================

  static const double defaultAdHashRateBonus = 0.5833;
  static const int defaultMaxAdsPerDay = 6;

  static const double defaultDailyHashRate = 0.5;
  static const double dailyHashRateStep = 0.5;
  static const double maximumDailyHashRate = 3.5;

  static const double miningPerHashPerHour = 0.10;

  static const int defaultMiningDurationMs =
      24 * 60 * 60 * 1000;

  // ==========================================
  // FIREBASE
  // ==========================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  // ==========================================
  // STATE
  // ==========================================

  bool _loading = true;
  bool _actionLoading = false;
  bool _miningActive = false;

  double _hashRate = 0.0;
  double _unclaimedMining = 0.0;
  double _estimatedTotal = 0.0;
  double _miningPerHour = 0.0;

  int _miningRemainingMs = 0;
  int _miningDurationMs =
      defaultMiningDurationMs;

  // ==========================================
  // DAILY HASH RATE
  // ==========================================

  int _streak = 0;
  double _dailyHashRate =
      defaultDailyHashRate;

  // ==========================================
  // POWER BOOST
  // ==========================================

  int _adsToday = 0;
  int _maxAdsPerDay =
      defaultMaxAdsPerDay;

  double _adHashRateBonus =
      defaultAdHashRateBonus;

  bool _canWatchAd = false;
  int _cooldownRemainingMs = 0;

  bool _adBoostActive = false;
  int _adBoostRemainingMs = 0;

  double _effectiveHashRate = 0.0;

  // ==========================================
  // USER
  // ==========================================

  String _username = '';

  // ==========================================
  // TIMERS
  // ==========================================

  Timer? _uiTimer;
  Timer? _refreshTimer;

  // ==========================================
  // STELLA ANIMATION
  // ==========================================

  late final AnimationController _catController;
  late final Animation<double> _catAnimation;

  // ==========================================
  // ADMOB MANAGER
  // ==========================================

  late final HomeAdManager _adManager;

  // ==========================================
  // LOCALIZATION
  // ==========================================

  AppLocalizations get _localization =>
      AppLocalizations(widget.languageCode);

  // ==========================================
  // INIT
  // ==========================================

  @override
  void initState() {
    super.initState();

    _catController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1800,
      ),
    );

    _catAnimation = CurvedAnimation(
      parent: _catController,
      curve: Curves.easeInOut,
    );

    _catController.repeat(
      reverse: true,
    );

    _adManager = HomeAdManager(
      onMiningStartReward:
          _startMiningAfterAd,
      onPowerBoostReward:
          _waitForServerSidePowerBoost,
      onAdLoadError:
          _handleAdLoadError,
      onAdShowError:
          _handleAdShowError,
      onAdDismissed:
          _handleAdDismissed,
    );

    _adManager.addListener(
      _onAdManagerChanged,
    );

    _initialize();
  }

  // ==========================================
  // ADMOB CALLBACKS
  // ==========================================

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

    _showDetailedAdLoadError(
      purpose,
      error,
    );
  }

  void _handleAdShowError(
    String purpose,
    AdError error,
  ) {
    if (!mounted) {
      return;
    }

    _actionLoading = false;

    _showMessage(
      '⚠️ ${_localization.t('adLoadError')}',
    );
  }

  void _handleAdDismissed(
    String purpose,
  ) {
    if (!mounted) {
      return;
    }

    /*
     * Älä nollaa _actionLoading-arvoa tässä.
     *
     * Reward callback voi olla jo käynnistänyt
     * palvelinpuolen vahvistuksen.
     */
  }

  // ==========================================
  // INITIALIZE
  // ==========================================

  Future<void> _initialize() async {
    try {
      await _loadUsername();
      await _loadMiningStatus();

      _startTimers();
    } catch (error) {
      debugPrint(
        'HomePage initialization error: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ==========================================
  // USERNAME
  // ==========================================

  Future<void> _loadUsername() async {
    try {
      final User? user =
          _auth.currentUser;

      if (user == null) {
        return;
      }

      await user.reload();

      final User? refreshedUser =
          _auth.currentUser;

      if (!mounted) {
        return;
      }

      setState(() {
        _username =
            refreshedUser?.displayName ??
                '';
      });
    } catch (error) {
      debugPrint(
        'Username loading error: $error',
      );
    }
  }

  // ==========================================
  // LOGOUT
  // ==========================================

  Future<void> _logout() async {
    Navigator.of(context).pop();

    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (
        BuildContext context,
      ) {
        return AlertDialog(
          backgroundColor: surfaceColor,
          title: Text(
            _localization.t('logout'),
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          content: Text(
            _localization.t(
              'logoutConfirmation',
            ),
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context)
                      .pop(false),
              child: Text(
                _localization.t(
                  'cancel',
                ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context)
                      .pop(true),
              child: Text(
                _localization.t(
                  'logout',
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _auth.signOut();
    } catch (error) {
      debugPrint(
        'Logout error: $error',
      );
    }
  }

  // ==========================================
  // TIMERS
  // ==========================================

  void _startTimers() {
    _uiTimer?.cancel();
    _refreshTimer?.cancel();

    _uiTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) {
          return;
        }

        bool changed = false;

        if (_miningRemainingMs > 0) {
          _miningRemainingMs -= 1000;

          if (_miningRemainingMs < 0) {
            _miningRemainingMs = 0;
          }

          changed = true;
        }

        if (_adBoostRemainingMs > 0) {
          _adBoostRemainingMs -= 1000;

          if (_adBoostRemainingMs <= 0) {
            _adBoostRemainingMs = 0;
            _adBoostActive = false;
          }

          changed = true;
        }

        if (_cooldownRemainingMs > 0) {
          _cooldownRemainingMs -= 1000;

          if (_cooldownRemainingMs < 0) {
            _cooldownRemainingMs = 0;
          }

          changed = true;
        }

        final bool newCanWatchAd =
            !_adBoostActive &&
            _adsToday < _maxAdsPerDay &&
            _cooldownRemainingMs <= 0;

        if (_canWatchAd != newCanWatchAd) {
          _canWatchAd = newCanWatchAd;
          changed = true;
        }

        _recalculateMiningPerHour();

        if (changed) {
          setState(() {});
        }
      },
    );

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        _loadMiningStatus();
      },
    );
  }

  // ==========================================
  // MINING CALCULATION
  // ==========================================

  void _recalculateMiningPerHour() {
    _effectiveHashRate =
        _hashRate +
            (_adBoostActive
                ? _adHashRateBonus
                : 0.0);

    _miningPerHour =
        _effectiveHashRate *
            miningPerHashPerHour;
  }

  // ==========================================
  // LOAD MINING STATUS
  // ==========================================

  Future<void> _loadMiningStatus() async {
    try {
      final User? user =
          _auth.currentUser;

      if (user == null) {
        return;
      }

      final HttpsCallable callable =
          _functions.httpsCallable(
        'getMiningStatus',
      );

      final HttpsCallableResult result =
          await callable.call();

      final dynamic data =
          result.data;

      if (data is! Map) {
        return;
      }

      final Map<dynamic, dynamic> map =
          data;

      if (!mounted) {
        return;
      }

      final double hashRate =
          _toDouble(
        map['hashRate'],
      );

      final double unclaimed =
          _toDouble(
        map['unclaimedMining'],
      );

      final double estimatedTotal =
          _toDouble(
        map['estimatedTotal'],
      );

      final int streak =
          _toInt(
        map['dailyStreak'] ??
            map['streak'],
      );

      double dailyHashRate =
          _toDouble(
        map['dailyHashRate'],
      );

      if (!_isValidDailyHashRate(
        dailyHashRate,
      )) {
        dailyHashRate =
            _calculateDailyHashRate(
          streak,
        );
      }

      final bool miningActive =
          map['miningActive'] == true;

      final int miningRemainingMs =
          _toInt(
        map['miningRemainingMs'],
      );

      final int miningDurationMs =
          _toInt(
        map['miningDurationMs'],
      );

      final int adsToday =
          _toInt(
        map['adsToday'],
      );

      final int maxAdsPerDay =
          _toInt(
        map['maxAdsPerDay'],
      );

      final double adHashRateBonus =
          _toDouble(
        map['adHashRateBonus'],
      );

      final int cooldownRemainingMs =
          _toInt(
        map['cooldownRemainingMs'],
      );

      final bool adBoostActive =
          map['adBoostActive'] == true;

      final int adBoostRemainingMs =
          _toInt(
        map['adBoostRemainingMs'],
      );

      setState(() {
        _hashRate = hashRate;
        _unclaimedMining = unclaimed;
        _estimatedTotal = estimatedTotal;

        _streak = streak;
        _dailyHashRate =
            dailyHashRate;

        _miningActive =
            miningActive;

        _miningRemainingMs =
            miningRemainingMs;

        _miningDurationMs =
            miningDurationMs > 0
                ? miningDurationMs
                : defaultMiningDurationMs;

        _adsToday = adsToday;

        _maxAdsPerDay =
            maxAdsPerDay > 0
                ? maxAdsPerDay
                : defaultMaxAdsPerDay;

        _adHashRateBonus =
            adHashRateBonus > 0
                ? adHashRateBonus
                : defaultAdHashRateBonus;

        _cooldownRemainingMs =
            cooldownRemainingMs;

        _adBoostActive =
            adBoostActive;

        _adBoostRemainingMs =
            adBoostRemainingMs;
      });

      _recalculateMiningPerHour();

      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      debugPrint(
        'Mining status loading error: $error',
      );
    }
  }

  // ==========================================
  // WAIT FOR ADMOB
  // ==========================================

  Future<bool> _waitForRewardedAd(
    String purpose,
  ) async {
    return _adManager
        .waitForRewardedAd(
      purpose: purpose,
    );
  }

  // ==========================================
  // START MINING
  // ==========================================

  Future<void> _startMining() async {
    if (_adManager.miningAdFlowActive ||
        _actionLoading ||
        _miningActive) {
      return;
    }

    setState(() {
      _actionLoading = true;
    });

    try {
      final bool shown =
          await _adManager
              .showMiningStartAd();

      if (!shown) {
        if (mounted) {
          setState(() {
            _actionLoading = false;
          });

          _showAdLoadError();
        }

        return;
      }

      /*
       * HomeAdManager hoitaa:
       *
       * 1. mainoksen lataamisen
       * 2. SSV customData -asetuksen
       * 3. mainoksen näyttämisen
       * 4. client reward callbackin
       *
       * Reward callback jatkaa
       * _startMiningAfterAd()-metodiin.
       */
    } catch (error) {
      debugPrint(
        'Start mining ad error: $error',
      );

      if (mounted) {
        setState(() {
          _actionLoading = false;
        });

        _showMessage(
          '⚠️ $error',
        );
      }
    }
  }

  // ==========================================
  // CLAIM MINING WITH SSV RETRY
  // ==========================================

  Future<HttpsCallableResult?>
      _claimMiningWithSsvRetry() async {
    const int maxAttempts = 15;

    for (int attempt = 1;
        attempt <= maxAttempts;
        attempt++) {
      try {
        final HttpsCallable callable =
            _functions.httpsCallable(
          'claimMining',
        );

        final HttpsCallableResult result =
            await callable.call();

        return result;
      } on FirebaseFunctionsException catch (
        error
      ) {
        final String text =
            '${error.code} '
            '${error.message ?? ''}'
                .toLowerCase();

        final bool retryable =
            text.contains('admob') ||
            text.contains('reward') ||
            text.contains('mining_start') ||
            text.contains('mining start') ||
            text.contains('verified');

        if (!retryable ||
            attempt >= maxAttempts) {
          rethrow;
        }

        debugPrint(
          'claimMining SSV retry '
          '$attempt/$maxAttempts: '
          '${error.message}',
        );

        await Future<void>.delayed(
          const Duration(seconds: 2),
        );
      } catch (error) {
        debugPrint(
          'claimMining unexpected error: '
          '$error',
        );

        rethrow;
      }
    }

    return null;
  }

  // ==========================================
  // AFTER MINING START AD
  // ==========================================

  Future<void> _startMiningAfterAd() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _actionLoading = true;
    });

    try {
      final HttpsCallableResult?
          result =
          await _claimMiningWithSsvRetry();

      if (result == null) {
        _showMessage(
          _localization.t(
            'miningStartFailed',
          ),
        );

        return;
      }

      final dynamic data =
          result.data;

      if (data is Map) {
        final bool started =
            data['started'] == true;

        final bool miningActive =
            data['miningActive'] == true;

        final double collected =
            _toDouble(
          data['collected'],
        );

        final int dailyStreak =
            _toInt(
          data['dailyStreak'],
        );

        final double dailyHashRate =
            _toDouble(
          data['dailyHashRate'],
        );

        if (started) {
          _showMessage(
            _localization.t(
              'miningStarted',
            ),
          );
        } else if (miningActive) {
          _showMessage(
            _localization.t(
              'alreadyMining',
            ),
          );
        } else if (collected > 0) {
          _showMessage(
            '${_localization.t('miningCollected')} '
            '${_formatStl(collected)} STL',
          );
        } else {
          _showMessage(
            _localization.t(
              'miningStartFailed',
            ),
          );
        }

        if (mounted) {
          setState(() {
            _miningActive =
                miningActive;

            if (dailyStreak > 0) {
              _streak =
                  dailyStreak;
            }

            if (_isValidDailyHashRate(
              dailyHashRate,
            )) {
              _dailyHashRate =
                  dailyHashRate;
            }
          });
        }
      }

      await _loadMiningStatus();
    } on FirebaseFunctionsException catch (
      error
    ) {
      debugPrint(
        'Start mining Firebase error: '
        '${error.code} '
        '${error.message}',
      );

      if (mounted) {
        _showMessage(
          '⚠️ ${error.message ?? error.code}',
        );
      }
    } catch (error) {
      debugPrint(
        'Start mining error: $error',
      );

      if (mounted) {
        _showMessage(
          '⚠️ $error',
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

  // ==========================================
  // POWER BOOST
  // ==========================================

  Future<void> _watchAd() async {
    if (_adManager.powerBoostAdFlowActive ||
        _actionLoading ||
        _adBoostActive) {
      return;
    }

    if (!_canWatchAd) {
      await _loadMiningStatus();

      if (!_canWatchAd) {
        if (mounted) {
          _showMessage(
            _localization.t(
              'prepareAd',
            ),
          );
        }

        return;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _actionLoading = true;
    });

    try {
      final bool shown =
          await _adManager
              .showPowerBoostAd();

      if (!shown) {
        if (mounted) {
          setState(() {
            _actionLoading = false;
          });

          _showAdLoadError();
        }

        return;
      }

      /*
       * Reward callback jatkaa
       * _waitForServerSidePowerBoost()
       * -metodiin.
       */
    } catch (error) {
      debugPrint(
        'Power Boost ad error: $error',
      );

      if (mounted) {
        setState(() {
          _actionLoading = false;
        });

        _showMessage(
          '⚠️ $error',
        );
      }
    }
  }

  // ==========================================
  // WAIT FOR SERVER SIDE POWER BOOST
  // ==========================================

  Future<void>
      _waitForServerSidePowerBoost() async {
    const int maxAttempts = 6;

    for (int attempt = 1;
        attempt <= maxAttempts;
        attempt++) {
      if (!mounted) {
        return;
      }

      try {
        await _loadMiningStatus();

        if (_adBoostActive) {
          if (mounted) {
            _showMessage(
              _localization.t(
                'powerBoostReward',
              ),
            );
          }

          return;
        }

        debugPrint(
          'Waiting for Power Boost SSV '
          'verification '
          '$attempt/$maxAttempts',
        );
      } catch (error) {
        debugPrint(
          'Power Boost verification error: '
          '$error',
        );
      }

      if (attempt < maxAttempts) {
        await Future<void>.delayed(
          const Duration(seconds: 2),
        );
      }
    }

    if (mounted) {
      _showMessage(
        _localization.t(
          'prepareAd',
        ),
      );
    }

    if (mounted) {
      setState(() {
        _actionLoading = false;
      });
    }

    await _loadMiningStatus();

    if (mounted) {
      setState(() {
        _actionLoading = false;
      });
    }

    await _adManager.loadRewardedAd(
      purpose:
          HomeAdManager.powerBoostPurpose,
    );
  }

  // ==========================================
  // ADMOB ERROR
  // ==========================================

  void _showDetailedAdLoadError(
    String purpose,
    LoadAdError error,
  ) {
    final String purposeText =
        purpose ==
                HomeAdManager.miningStartPurpose
            ? 'Mining Start'
            : 'Power Boost';

    final String message =
        '$purposeText\n'
        'Code: ${error.code}\n'
        'Domain: ${error.domain}\n'
        'Message: ${error.message}';

    _showMessage(
      '⚠️ $message',
    );
  }

  void _showAdLoadError() {
    final String error =
        _adManager.adLoadError;

    if (error.isEmpty) {
      _showMessage(
        _localization.t(
          'prepareAd',
        ),
      );

      return;
    }

    _showMessage(
      '⚠️ $error',
    );
  }

  // ==========================================
  // LANGUAGE DIALOG
  // ==========================================

  Future<void> _showLanguageDialog() async {
    final List<String> languages =
        AppLocalizations.supportedLanguages;

    final String? selected =
        await showDialog<String>(
      context: context,
      builder: (
        BuildContext context,
      ) {
        return AlertDialog(
          backgroundColor: surfaceColor,
          title: Text(
            _localization.t(
              'language',
            ),
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount:
                  languages.length,
              itemBuilder: (
                BuildContext context,
                int index,
              ) {
                final String code =
                    languages[index];

                return ListTile(
                  title: Text(
                    _languageName(code),
                    style:
                        const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  trailing:
                      code ==
                              widget
                                  .languageCode
                          ? const Icon(
                              Icons.check,
                              color:
                                  accentColor,
                            )
                          : null,
                  onTap: () =>
                      Navigator.of(
                    context,
                  ).pop(code),
                );
              },
            ),
          ),
        );
      },
    );

    if (selected == null ||
        selected ==
            widget.languageCode ||
        !mounted) {
      return;
    }

    _showMessage(
      _languageChangedMessage(
        selected,
      ),
    );
  }

  String _languageName(
    String code,
  ) {
    switch (code) {
      case 'fi':
        return 'Suomi';
      case 'en':
        return 'English';
      case 'de':
        return 'Deutsch';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'zh':
        return '中文';
      case 'vi':
        return 'Tiếng Việt';
      case 'ja':
        return '日本語';
      default:
        return code;
    }
  }

  Widget _languageButton() {
    return IconButton(
      tooltip: _localization.t(
        'language',
      ),
      icon: const Icon(
        Icons.language,
      ),
      onPressed:
          _showLanguageDialog,
    );
  }

  String _languageChangedMessage(
    String code,
  ) {
    return '${_localization.t('language')}: '
        '${_languageName(code)}';
  }

  // ==========================================
  // OPEN PAGE
  // ==========================================

  void _openPage(
    Widget page,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }

  // ==========================================
  // DAILY CAT FACT
  // ==========================================

  Widget _buildDailyCatFact() {
    if (catFacts.isEmpty) {
      return const SizedBox.shrink();
    }

    final int index =
        DateTime.now().day %
            catFacts.length;

    final String fact =
        catFacts[index];

    return CatFactCard(
      fact: fact,
      languageCode:
          widget.languageCode,
    );
  }

  // ==========================================
  // HEADER
  // ==========================================

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(
                Icons.menu_rounded,
                color: Colors.white,
              ),
              onPressed: () {
                Scaffold.of(context)
                    .openDrawer();
              },
            );
          },
        ),
        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Stelluriini',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              Text(
                'STL • Stella Mining',
                style: TextStyle(
                  color:
                      Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (_username.isNotEmpty)
          Flexible(
            child: Text(
              _username,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color: pinkColor,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        _languageButton(),
        IconButton(
          tooltip: _localization.t(
            'refresh',
          ),
          icon: const Icon(
            Icons.refresh_rounded,
            color: Colors.white,
          ),
          onPressed:
              _loadMiningStatus,
        ),
      ],
    );
  }

  // ==========================================
  // STELLA MINING CARD
  // ==========================================

  Widget _buildStellaMiningCard() {
    final bool completed =
        !_miningActive &&
            _miningRemainingMs <= 0 &&
            _unclaimedMining > 0;

    final String title =
        completed
            ? _localization.t(
                'miningReadyToCollect',
              )
            : _localization.t(
                'stellaMining',
              );

    final String subtitle =
        completed
            ? _localization.t(
                'miningCompleted',
              )
            : _localization.t(
                'stellaMiningSubtitle',
              );

    final String timerText =
        _formatDuration(
      _miningRemainingMs,
    );

    return StellaMiningCard(
      languageCode:
          widget.languageCode,
      title: title,
      subtitle: subtitle,
      unclaimedMining:
          _unclaimedMining,
      timerText: timerText,
      dailyStreak: _streak,
      catAnimation:
          _catAnimation,
    );
  }

  // ==========================================
  // STATS
  // ==========================================

  Widget _buildStatsRow() {
    return HomeStatsCard(
      languageCode:
          widget.languageCode,
      hashRate:
          _effectiveHashRate,
      totalStl:
          _estimatedTotal,
    );
  }

  // ==========================================
  // MINING BUTTON
  // ==========================================

  Widget _buildMiningButton() {
    final bool completed =
        !_miningActive &&
            _miningRemainingMs <= 0 &&
            _unclaimedMining > 0;

    String text;
    IconData icon;

    if (_actionLoading) {
      text = _localization.t(
        'loading',
      );
      icon =
          Icons.hourglass_top_rounded;
    } else if (_miningActive) {
      text = _localization.t(
        'miningActive',
      );
      icon =
          Icons.auto_graph_rounded;
    } else if (completed) {
      text = _localization.t(
        'collectMining',
      );
      icon =
          Icons.pets_rounded;
    } else {
      text = _localization.t(
        'startMining',
      );
      icon =
          Icons.play_arrow_rounded;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed:
            _actionLoading ||
                    _miningActive
                ? null
                : _startMining,
        icon: Icon(icon),
        label: Text(text),
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
              Colors.white54,
          padding:
              const EdgeInsets.symmetric(
            vertical: 16,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // POWER BOOST BUTTON
  // ==========================================

  Widget _buildAdButton() {
    final bool boostActive =
        _adBoostActive;

    final bool canUse =
        _canWatchAd &&
            !_actionLoading &&
            !_adManager
                .powerBoostAdFlowActive;

    String subtitle;

    if (boostActive) {
      subtitle =
          '${_localization.t('powerBoostActive')} '
          '${_formatDuration(_adBoostRemainingMs)}';
    } else if (_adsToday >=
        _maxAdsPerDay) {
      subtitle =
          _localization.t(
        'dailyAdLimitReached',
      );
    } else if (_cooldownRemainingMs >
        0) {
      subtitle =
          '${_localization.t('cooldown')}: '
          '${_formatDuration(_cooldownRemainingMs)}';
    } else if (_adManager
        .adLoading) {
      subtitle =
          _localization.t(
        'prepareAd',
      );
    } else if (!_adManager.adReady ||
        _adManager
                .rewardedAdPurpose !=
            HomeAdManager
                .powerBoostPurpose) {
      subtitle =
          _localization.t(
        'prepareAd',
      );
    } else {
      subtitle =
          _localization.t(
        'powerBoostSubtitle',
      );
    }

    return PowerBoostCard(
      languageCode:
          widget.languageCode,
      canUse: canUse,
      boostActive: boostActive,
      adsToday: _adsToday,
      maxAdsPerDay:
          _maxAdsPerDay,
      adHashRateBonus:
          _adHashRateBonus,
      subtitle: subtitle,
      onPressed:
          canUse ? _watchAd : null,
    );
  }

  // ==========================================
  // FOOTER
  // ==========================================

  Widget _buildStellaFooter() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 24,
      ),
      child: Column(
        children: [
          const StelluriiniLogo(
            size: 52,
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            'Stelluriini (STL)',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            _localization.t(
              'stelluriiniStlSolanaFooter',
            ),
            textAlign:
                TextAlign.center,
            style: const TextStyle(
              color:
                  Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HELPERS
  // ==========================================

  double _toDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  int _toInt(
    dynamic value,
  ) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  bool _isValidDailyHashRate(
    double value,
  ) {
    return value >=
            defaultDailyHashRate &&
        value <=
            maximumDailyHashRate;
  }

  double _calculateDailyHashRate(
    int streak,
  ) {
    final int day =
        streak.clamp(1, 7);

    return defaultDailyHashRate +
        ((day - 1) *
            dailyHashRateStep);
  }

  String _formatStl(
    double value,
  ) {
    return value.toStringAsFixed(
      4,
    );
  }

  String _formatDuration(
    int milliseconds,
  ) {
    if (milliseconds <= 0) {
      return '00:00:00';
    }

    final Duration duration =
        Duration(
      milliseconds: milliseconds,
    );

    final int hours =
        duration.inHours;

    final int minutes =
        duration.inMinutes % 60;

    final int seconds =
        duration.inSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

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
          content: Text(message),
          backgroundColor:
              surfaceColor,
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          backgroundColor,
      drawer: HomeDrawer(
        languageCode:
            widget.languageCode,
        onHome:
            () =>
                Navigator.of(context)
                    .pop(),
        onAbout: () {
          Navigator.of(context)
              .pop();

          _openPage(
            AboutPage(
              languageCode:
                  widget.languageCode,
            ),
          );
        },
        onWhitePaper: () {
          Navigator.of(context)
              .pop();

          _openPage(
            WhitePaperPage(
              languageCode:
                  widget.languageCode,
            ),
          );
        },
        onRoadmap: () {
          Navigator.of(context)
              .pop();

          _openPage(
            RoadmapPage(
              languageCode:
                  widget.languageCode,
            ),
          );
        },
        onAchievements: () {
          Navigator.of(context)
              .pop();

          _openPage(
            AchievementsPage(
              languageCode:
                  widget.languageCode,
            ),
          );
        },
        onHistory: () {
          Navigator.of(context)
              .pop();

          _openPage(
            TransactionHistoryPage(
              languageCode:
                  widget.languageCode,
            ),
          );
        },
        onLogout: _logout,
      ),
      body: SafeArea(
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
                      const EdgeInsets.all(
                    16,
                  ),
                  children: [
                    _buildHeader(),

                    const SizedBox(
                      height: 16,
                    ),

                    _buildStellaMiningCard(),

                    const SizedBox(
                      height: 14,
                    ),

                    _buildStatsRow(),

                    const SizedBox(
                      height: 14,
                    ),

                    _buildMiningButton(),

                    const SizedBox(
                      height: 14,
                    ),

                    _buildAdButton(),

                    const SizedBox(
                      height: 14,
                    ),

                    _buildDailyCatFact(),

                    _buildStellaFooter(),
                  ],
                ),
              ),
      ),
    );
  }

  // ==========================================
  // DISPOSE
  // ==========================================

  @override
  void dispose() {
    _uiTimer?.cancel();
    _refreshTimer?.cancel();

    _adManager.removeListener(
      _onAdManagerChanged,
    );

    _adManager.dispose();

    _catController.dispose();

    super.dispose();
  }
}