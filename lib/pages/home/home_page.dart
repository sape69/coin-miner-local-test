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
import '../history/transaction_history_page.dart';
import '../roadmap/roadmap_page.dart';
import '../token/stl_token_page.dart';
import '../tokenomics/tokenomics_page.dart';
import '../whitepaper/whitepaper_page.dart';
import 'cat_fact_card.dart';
import 'home_stats_card.dart';
import 'mining_progress_card.dart';
import 'stella_mining_card.dart';

// ============================================================
// 🐱 STELLURIINI HOME PAGE
// ============================================================

class HomePage extends StatefulWidget {
  final String languageCode;
  final Future<void> Function(String) changeLanguage;

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
  // 🎨 STELLA COLORS
  // ============================================================

  static const Color backgroundColor = Color(0xFF120B24);
  static const Color cardColor = Color(0xFF21113B);
  static const Color accentColor = Color(0xFFB58CFF);
  static const Color pinkColor = Color(0xFFFFB7E8);
  static const Color goldColor = Color(0xFFFFD166);
  static const Color secondaryTextColor = Color(0xFFBFAEDB);

  // ============================================================
  // ⚡ STELLA POWER BOOST
  // ============================================================

  static const double defaultAdHashRateBonus = 0.5833;

  static const int defaultMaxAdsPerDay = 6;

  static const int defaultAdBoostDurationMs =
      4 * 60 * 60 * 1000;

  // ============================================================
  // ⛏️ DAILY HASH RATE
  // ============================================================

  static const double defaultDailyHashRate = 0.5;
  static const double dailyHashRateStep = 0.5;
  static const double maximumDailyHashRate = 3.5;

  // ============================================================
  // 💰 MINING RATE
  // ============================================================

  static const double miningPerHashPerHour = 0.10;

  // ============================================================
  // ⏱️ MINING DURATION
  // ============================================================

  static const int defaultMiningDurationMs =
      24 * 60 * 60 * 1000;

  // ============================================================
  // 🐱 FIREBASE
  // ============================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  // ============================================================
  // 📺 ADMOB TEST REWARDED AD
  // ============================================================

  static const String _rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  RewardedAd? _rewardedAd;

  bool _adReady = false;
  bool _adLoading = false;

  // ============================================================
  // ⛏️ MINING STATE
  // ============================================================

  bool _loading = true;
  bool _actionLoading = false;
  bool _miningActive = false;

  double _hashRate = defaultDailyHashRate;

  double _unclaimedMining = 0.0;
  double _estimatedTotal = 0.0;
  double _miningPerHour = 0.0;

  int _miningRemainingMs = 0;

  int _miningDurationMs = defaultMiningDurationMs;

  // ============================================================
  // 🎁 DAILY HASH RATE STATE
  // ============================================================

  int _streak = 0;

  double _dailyHashRate = defaultDailyHashRate;

  // ============================================================
  // ⚡ POWER BOOST STATE
  // ============================================================

  int _adsToday = 0;

  int _maxAdsPerDay = defaultMaxAdsPerDay;

  double _adHashRateBonus = defaultAdHashRateBonus;

  bool _canWatchAd = false;

  int _cooldownRemainingMs = 0;

  bool _adBoostActive = false;

  int _adBoostRemainingMs = 0;

  double _effectiveHashRate = defaultDailyHashRate;

  // ============================================================
  // ⏱️ TIMERS
  // ============================================================

  Timer? _uiTimer;
  Timer? _refreshTimer;

  // ============================================================
  // 🐱 STELLA ANIMATION
  // ============================================================

  late AnimationController _catController;
  late Animation<double> _catAnimation;

  // ============================================================
  // 🌍 LOCALIZATION
  // ============================================================

  AppLocalizations get _localization =>
      AppLocalizations(widget.languageCode);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _catController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _catAnimation = Tween<double>(
      begin: 0,
      end: 8,
    ).animate(
      CurvedAnimation(
        parent: _catController,
        curve: Curves.easeInOut,
      ),
    );

    _initialize();
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> _initialize() async {
    try {
      await _ensureSignedIn();
      await _loadMiningStatus();

      if (!mounted) {
        return;
      }

      await _loadRewardedAd();
      _startTimers();
    } catch (error) {
      debugPrint(
        'Initialize error: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      _showMessage(
        _localization.get(
          'serverConnectionFailed',
        ),
      );
    }
  }

  // ============================================================
  // AUTH
  // ============================================================

  Future<void> _ensureSignedIn() async {
    if (_auth.currentUser != null) {
      return;
    }

    await _auth.signInAnonymously();
  }

  // ============================================================
  // TIMERS
  // ============================================================

  void _startTimers() {
    _uiTimer?.cancel();

    _uiTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) {
          return;
        }

        setState(() {
          if (_miningActive &&
              _miningRemainingMs > 0) {
            _miningRemainingMs -= 1000;

            if (_miningRemainingMs <= 0) {
              _miningRemainingMs = 0;
              _miningActive = false;
            }
          }

          if (_adBoostActive &&
              _adBoostRemainingMs > 0) {
            _adBoostRemainingMs -= 1000;

            if (_adBoostRemainingMs <= 0) {
              _adBoostRemainingMs = 0;
              _adBoostActive = false;
            }
          }

          if (!_adBoostActive &&
              _cooldownRemainingMs > 0) {
            _cooldownRemainingMs -= 1000;

            if (_cooldownRemainingMs <= 0) {
              _cooldownRemainingMs = 0;
            }
          }

          if (!_adBoostActive &&
              _cooldownRemainingMs <= 0 &&
              _adsToday < _maxAdsPerDay) {
            _canWatchAd = true;
          }

          _recalculateMiningPerHour();
        });
      },
    );

    _refreshTimer?.cancel();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) async {
        await _loadMiningStatus();
      },
    );
  }

  // ============================================================
  // MINING RATE
  // ============================================================

  void _recalculateMiningPerHour() {
    _effectiveHashRate = _adBoostActive
        ? _hashRate + _adHashRateBonus
        : _hashRate;

    _miningPerHour =
        _effectiveHashRate * miningPerHashPerHour;
  }

  // ============================================================
  // LOAD MINING STATUS
  // ============================================================

  Future<void> _loadMiningStatus() async {
    try {
      final callable =
          _functions.httpsCallable(
        'getMiningStatus',
      );

      final result = await callable.call();

      final data =
          Map<String, dynamic>.from(
        result.data as Map,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        // ------------------------------------------------------
        // DAILY STREAK
        // ------------------------------------------------------

        _streak = _toInt(
          data['dailyStreak'] ??
              data['streak'],
        );

        // ------------------------------------------------------
        // DAILY HASH RATE
        // ------------------------------------------------------

        final double backendDailyHashRate =
            _toDouble(
          data['dailyHashRate'],
        );

        if (backendDailyHashRate >=
                defaultDailyHashRate &&
            backendDailyHashRate <=
                maximumDailyHashRate) {
          _dailyHashRate =
              backendDailyHashRate;
        } else {
          _dailyHashRate =
              _calculateDailyHashRate(
            _streak,
          );
        }

        // ------------------------------------------------------
        // BASE HASH RATE
        // ------------------------------------------------------

        final double backendHashRate =
            _toDouble(
          data['hashRate'],
        );

        if (backendHashRate >=
                defaultDailyHashRate &&
            backendHashRate <=
                maximumDailyHashRate) {
          _hashRate = backendHashRate;
        } else {
          _hashRate = _dailyHashRate;
        }

        // ------------------------------------------------------
        // MINING
        // ------------------------------------------------------

        _unclaimedMining =
            _toDouble(
          data['unclaimedMining'],
        );

        _estimatedTotal =
            _toDouble(
          data['estimatedTotal'],
        );

        _miningActive =
            data['miningActive'] == true;

        _miningRemainingMs =
            _toInt(
          data['miningRemainingMs'],
        );

        _miningDurationMs =
            _toInt(
          data['miningDurationMs'],
        );

        if (_miningDurationMs <= 0) {
          _miningDurationMs =
              defaultMiningDurationMs;
        }

        // ------------------------------------------------------
        // POWER BOOST
        // ------------------------------------------------------

        _adsToday =
            _toInt(
          data['adsToday'],
        );

        _maxAdsPerDay =
            _toInt(
          data['maxAdsPerDay'],
        );

        if (_maxAdsPerDay <= 0) {
          _maxAdsPerDay =
              defaultMaxAdsPerDay;
        }

        final double backendAdBonus =
            _toDouble(
          data['adHashRateBonus'],
        );

        _adHashRateBonus =
            backendAdBonus > 0
                ? backendAdBonus
                : defaultAdHashRateBonus;

        _adBoostActive =
            data['adBoostActive'] == true;

        _adBoostRemainingMs =
            _toInt(
          data['adBoostRemainingMs'],
        );

        _cooldownRemainingMs =
            _toInt(
          data['cooldownRemainingMs'],
        );

        if (_adBoostRemainingMs <= 0) {
          _adBoostRemainingMs = 0;
          _adBoostActive = false;
        }

        // ------------------------------------------------------
        // EFFECTIVE HASH RATE
        // ------------------------------------------------------

        _recalculateMiningPerHour();

        // ------------------------------------------------------
        // AD AVAILABILITY
        // ------------------------------------------------------

        _canWatchAd =
            data['canWatchAd'] == true;

        if (_adBoostActive ||
            _adBoostRemainingMs > 0 ||
            _cooldownRemainingMs > 0 ||
            _adsToday >= _maxAdsPerDay) {
          _canWatchAd = false;
        }

        _loading = false;
      });
    } catch (error) {
      debugPrint(
        'Mining status error: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });
    }
  }

  // ============================================================
  // ⛏️ START / COLLECT MINING
  // ============================================================

  Future<void> _startMining() async {
    if (_actionLoading) {
      return;
    }

    if (_miningActive) {
      _showMessage(
        _localization.get(
          'stellaAlreadyMining',
        ),
      );

      return;
    }

    if (_rewardedAd == null ||
        !_adReady) {
      _showMessage(
        _localization.get(
          'prepareAd',
        ),
      );

      await _loadRewardedAd();
      return;
    }

    final RewardedAd ad = _rewardedAd!;

    _rewardedAd = null;
    _adReady = false;

    bool rewardEarned = false;

    ad.show(
      onUserEarnedReward: (
        AdWithoutView adWithoutView,
        RewardItem reward,
      ) async {
        if (rewardEarned) {
          return;
        }

        rewardEarned = true;

        await _startMiningAfterAd();
      },
    );
  }

  // ============================================================
  // ⛏️ START MINING AFTER AD
  // ============================================================

  Future<void> _startMiningAfterAd() async {
    if (_actionLoading) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _actionLoading = true;
    });

    try {
      final callable =
          _functions.httpsCallable(
        'claimMining',
      );

      final result =
          await callable.call();

      final data =
          Map<String, dynamic>.from(
        result.data as Map,
      );

      if (!mounted) {
        return;
      }

      final bool started =
          data['started'] == true;

      final bool alreadyMining =
          data['miningActive'] == true &&
              !started;

      final double collected =
          _toDouble(
        data['collected'],
      );

      // --------------------------------------------------------
      // DAILY HASH RATE
      // --------------------------------------------------------

      final int returnedStreak =
          _toInt(
        data['dailyStreak'] ??
            data['streak'],
      );

      final double returnedDailyHashRate =
          _toDouble(
        data['dailyHashRate'],
      );

      if (returnedStreak > 0) {
        _streak = returnedStreak;
      }

      if (returnedDailyHashRate >=
              defaultDailyHashRate &&
          returnedDailyHashRate <=
              maximumDailyHashRate) {
        _dailyHashRate =
            returnedDailyHashRate;
      } else {
        _dailyHashRate =
            _calculateDailyHashRate(
          _streak,
        );
      }

      _hashRate = _dailyHashRate;

      _recalculateMiningPerHour();

      // --------------------------------------------------------
      // MESSAGE
      // --------------------------------------------------------

      if (alreadyMining) {
        _showMessage(
          _localization.get(
            'stellaAlreadyMining',
          ),
        );
      } else if (collected > 0 &&
          started) {
        _showMessage(
          _localization.getWithParams(
            'miningCollected',
            params: {
              'amount':
                  _formatStl(
                collected,
              ),
            },
          ),
        );
      } else if (started) {
        _showMessage(
          _localization.getWithParams(
            'dailyHashRateSuccess',
            params: {
              'day':
                  _streak.toString(),
              'rate':
                  _dailyHashRate
                      .toStringAsFixed(1),
              'amount':
                  _dailyHashRate
                      .toStringAsFixed(1),
              'streak':
                  _streak.toString(),
            },
          ),
        );
      } else {
        _showMessage(
          _localization.get(
            'miningStartFailed',
          ),
        );
      }

      await _loadMiningStatus();
    } catch (error) {
      debugPrint(
        'Start mining after ad error: $error',
      );

      if (mounted) {
        _showMessage(
          _localization.get(
            'miningStartFailed',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _actionLoading = false;
        });
      }

      await _loadRewardedAd();
    }
  }

  // ============================================================
  // 📺 LOAD REWARDED AD
  // ============================================================

  Future<void> _loadRewardedAd() async {
    if (_adLoading) {
      return;
    }

    if (_rewardedAd != null) {
      return;
    }

    _adLoading = true;

    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (
          RewardedAd ad,
        ) {
          _rewardedAd = ad;
          _adReady = true;
          _adLoading = false;

          ad.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (
              RewardedAd dismissedAd,
            ) {
              dismissedAd.dispose();

              _rewardedAd = null;
              _adReady = false;

              if (mounted) {
                setState(() {});
              }

              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (
              RewardedAd failedAd,
              AdError error,
            ) {
              debugPrint(
                'Ad failed to show: $error',
              );

              failedAd.dispose();

              _rewardedAd = null;
              _adReady = false;

              if (mounted) {
                setState(() {});
              }

              _loadRewardedAd();
            },
          );

          if (mounted) {
            setState(() {});
          }
        },
        onAdFailedToLoad: (
          LoadAdError error,
        ) {
          debugPrint(
            'Ad failed to load: $error',
          );

          _rewardedAd = null;
          _adReady = false;
          _adLoading = false;

          if (mounted) {
            setState(() {});
          }

          Future.delayed(
            const Duration(seconds: 10),
            () {
              if (mounted) {
                _loadRewardedAd();
              }
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // 📺 WATCH POWER BOOST AD
  // ============================================================

  Future<void> _watchAd() async {
    if (_actionLoading) {
      return;
    }

    if (_adBoostActive &&
        _adBoostRemainingMs > 0) {
      _showMessage(
        _localization.getWithParams(
          'powerBoostActiveMessage',
          params: {
            'amount':
                _adHashRateBonus
                    .toStringAsFixed(4),
            'time':
                _formatDuration(
              _adBoostRemainingMs,
            ),
          },
        ),
      );

      return;
    }

    if (_adsToday >= _maxAdsPerDay) {
      _showMessage(
        _localization.get(
          'dailyLimitReached',
        ),
      );

      return;
    }

    if (_cooldownRemainingMs > 0) {
      _showMessage(
        _localization.getWithParams(
          'nextPowerBoostMessage',
          params: {
            'time':
                _formatDuration(
              _cooldownRemainingMs,
            ),
          },
        ),
      );

      return;
    }

    if (!_canWatchAd) {
      _showMessage(
        _localization.get(
          'prepareAd',
        ),
      );

      await _loadMiningStatus();
      return;
    }

    if (_rewardedAd == null ||
        !_adReady) {
      _showMessage(
        _localization.get(
          'prepareAd',
        ),
      );

      await _loadRewardedAd();
      return;
    }

    final RewardedAd ad = _rewardedAd!;

    _rewardedAd = null;
    _adReady = false;

    bool rewardProcessed = false;

    ad.show(
      onUserEarnedReward: (
        AdWithoutView adWithoutView,
        RewardItem reward,
      ) async {
        if (rewardProcessed) {
          return;
        }

        rewardProcessed = true;

        await _giveTestAdReward();
      },
    );
  }

  // ============================================================
  // 🎁 POWER BOOST REWARD
  // ============================================================

  Future<void> _giveTestAdReward() async {
    if (_actionLoading) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _actionLoading = true;
    });

    try {
      final callable =
          _functions.httpsCallable(
        'testAdReward',
      );

      final result =
          await callable.call();

      final data =
          Map<String, dynamic>.from(
        result.data as Map,
      );

      if (!mounted) {
        return;
      }

      final bool rewarded =
          data['rewarded'] == true;

      final bool duplicate =
          data['duplicate'] == true;

      final bool boostActive =
          data['adBoostActive'] == true;

      final double bonus =
          _toDouble(
        data['bonus'],
      );

      final double boostAmount =
          bonus > 0
              ? bonus
              : defaultAdHashRateBonus;

      if (rewarded) {
        final int backendDuration =
            _toInt(
          data['adBoostDurationMs'],
        );

        final int duration =
            backendDuration > 0
                ? backendDuration
                : defaultAdBoostDurationMs;

        setState(() {
          _adBoostActive = true;

          _adBoostRemainingMs =
              duration;

          _adHashRateBonus =
              boostAmount;

          _cooldownRemainingMs =
              duration;

          _canWatchAd = false;

          _recalculateMiningPerHour();
        });

        _showMessage(
          _localization.getWithParams(
            'powerBoostReward',
            params: {
              'amount':
                  boostAmount
                      .toStringAsFixed(4),
            },
          ),
        );
      } else if (duplicate) {
        _showMessage(
          _localization.get(
            'adRewardDuplicate',
          ),
        );
      } else if (boostActive) {
        _showMessage(
          _localization.get(
            'powerBoostAlreadyActive',
          ),
        );
      } else {
        _showMessage(
          data['message']?.toString() ??
              _localization.get(
                'powerBoostFailed',
              ),
        );
      }

      await _loadMiningStatus();
    } catch (error) {
      debugPrint(
        'Test ad reward error: $error',
      );

      if (mounted) {
        _showMessage(
          _localization.get(
            'testAdRewardFailed',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _actionLoading = false;
        });
      }

      await _loadRewardedAd();
    }
  }

  // ============================================================
  // 🌍 LANGUAGE DIALOG
  // ============================================================

  Future<void> _showLanguageDialog() async {
    final AppLocalizations localization =
        _localization;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(24),
          ),
          title: Text(
            '🐱 ${localization.get(
              'selectLanguage',
            )}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children:
                  AppLocalizations
                      .supportedLanguages
                      .entries
                      .map(
                (entry) {
                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child: _languageButton(
                      context:
                          dialogContext,
                      code:
                          entry.key,
                      title:
                          entry.value,
                    ),
                  );
                },
              ).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _languageButton({
    required BuildContext context,
    required String code,
    required String title,
  }) {
    final bool selected =
        widget.languageCode == code;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          Navigator.pop(context);

          await widget.changeLanguage(
            code,
          );

          if (mounted) {
            _showMessage(
              _languageChangedMessage(
                code,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              selected
                  ? accentColor
                  : const Color(0xFF35204F),
          foregroundColor:
              Colors.white,
          padding:
              const EdgeInsets.symmetric(
            vertical: 14,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontWeight:
                      selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: goldColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  String _languageChangedMessage(
    String code,
  ) {
    switch (code) {
      case 'fi':
        return '🐱 Stella vaihtoi kieleksi suomen!';

      case 'de':
        return '🐱 Stella hat die Sprache auf Deutsch geändert!';

      case 'es':
        return '🐱 ¡Stella cambió el idioma a español!';

      case 'fr':
        return '🐱 Stella a changé la langue en français !';

      case 'zh':
        return '🐱 Stella 已将语言切换为中文！';

      case 'vi':
        return '🐱 Stella đã đổi ngôn ngữ sang tiếng Việt!';

      case 'ja':
        return '🐱 Stella は日本語に変更しました！';

      case 'en':
      default:
        return '🐱 Stella changed the language to English!';
    }
  }

  // ============================================================
  // 🧭 PAGE NAVIGATION
  // ============================================================

  Future<void> _openPage(
    Widget page,
  ) async {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();

    await Future<void>.delayed(
      Duration.zero,
    );

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => page,
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadMiningStatus();
  }

  // ============================================================
  // 🐱 DAILY CAT FACT
  // ============================================================

  Widget _buildDailyCatFact() {
    final String fact =
        CatFacts.getDailyFact(
      languageCode:
          widget.languageCode,
    );

    return CatFactCard(
      title:
          '🐱 ${_localization.get(
        'stellaFacts',
      )}',
      fact: fact,
    );
  }

  // ============================================================
  // 🔢 HELPERS
  // ============================================================

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  double _calculateDailyHashRate(
    int streak,
  ) {
    if (streak <= 0) {
      return defaultDailyHashRate;
    }

    final double rate =
        defaultDailyHashRate +
            ((streak - 1) *
                dailyHashRateStep);

    return rate
        .clamp(
          defaultDailyHashRate,
          maximumDailyHashRate,
        )
        .toDouble();
  }

  String _formatStl(
    double value,
  ) {
    return value.toStringAsFixed(4);
  }

  String _formatDuration(
    int milliseconds,
  ) {
    final Duration duration =
        Duration(
      milliseconds:
          milliseconds < 0
              ? 0
              : milliseconds,
    );

    final String hours =
        duration.inHours
            .toString()
            .padLeft(
              2,
              '0',
            );

    final String minutes =
        (duration.inMinutes % 60)
            .toString()
            .padLeft(
              2,
              '0',
            );

    final String seconds =
        (duration.inSeconds % 60)
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$hours:$minutes:$seconds';
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
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          behavior:
              SnackBarBehavior.floating,
          backgroundColor:
              cardColor,
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

  // ============================================================
  // 🧹 DISPOSE
  // ============================================================

  @override
  void dispose() {
    _uiTimer?.cancel();
    _refreshTimer?.cancel();

    _rewardedAd?.dispose();

    _catController.dispose();

    super.dispose();
  }

  // ============================================================
  // 🏠 BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          backgroundColor,

      drawer: HomeDrawer(
        onLanguagePressed:
            _showLanguageDialog,

        onAboutPressed: () {
          _openPage(
            const AboutPage(),
          );
        },

        onWhitePaperPressed: () {
          _openPage(
            const WhitePaperPage(),
          );
        },

        onTokenPressed: () {
          _openPage(
            const StlTokenPage(),
          );
        },

        onTokenomicsPressed: () {
          _openPage(
            const TokenomicsPage(),
          );
        },

        onRoadmapPressed: () {
          _openPage(
            const RoadmapPage(),
          );
        },

        onTransactionHistoryPressed: () {
          _openPage(
            const TransactionHistoryPage(),
          );
        },
      ),

      body: SafeArea(
        child:
            _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(
                      color:
                          accentColor,
                    ),
                  )
                : RefreshIndicator(
                    color:
                        accentColor,
                    onRefresh:
                        _loadMiningStatus,
                    child:
                        ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.all(
                        20,
                      ),
                      children: [
                        _buildHeader(),

                        const SizedBox(
                          height: 24,
                        ),

                        _buildStellaMiningCard(),

                        const SizedBox(
                          height: 20,
                        ),

                        _buildStatsRow(),

                        const SizedBox(
                          height: 20,
                        ),

                        _buildMiningProgress(),

                        const SizedBox(
                          height: 24,
                        ),

                        _buildMiningButton(),

                        const SizedBox(
                          height: 16,
                        ),

                        _buildAdButton(),

                        const SizedBox(
                          height: 28,
                        ),

                        _buildDailyCatFact(),

                        const SizedBox(
                          height: 30,
                        ),

                        _buildStellaFooter(),

                        const SizedBox(
                          height: 30,
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  // ============================================================
  // 🐱 HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        Builder(
          builder: (context) {
            return Container(
              width: 52,
              height: 52,
              decoration:
                  BoxDecoration(
                color:
                    cardColor,
                borderRadius:
                    BorderRadius.circular(
                  17,
                ),
                border:
                    Border.all(
                  color:
                      accentColor.withValues(
                    alpha: 0.45,
                  ),
                ),
              ),
              child:
                  IconButton(
                onPressed: () {
                  Scaffold.of(
                    context,
                  ).openDrawer();
                },
                icon:
                    const Icon(
                  Icons.menu_rounded,
                  color:
                      pinkColor,
                  size: 29,
                ),
                tooltip:
                    _localization.get(
                  'menu',
                ),
              ),
            );
          },
        ),

        const SizedBox(
          width: 12,
        ),

        const StelluriiniLogo(
          size: 58,
        ),

        const SizedBox(
          width: 14,
        ),

        Expanded(
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'STELLURIINI',
                style:
                    TextStyle(
                  color:
                      Colors.white,
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                  letterSpacing:
                      1.2,
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                _localization.get(
                  'stellaMining',
                ),
                style:
                    const TextStyle(
                  color:
                      pinkColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        IconButton(
          onPressed:
              _loadMiningStatus,
          icon:
              const Icon(
            Icons.refresh_rounded,
            color:
                Colors.white,
          ),
          tooltip:
              _localization.get(
            'refresh',
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 🐱 STELLA MINING CARD
  // ============================================================

  Widget _buildStellaMiningCard() {
    final bool completed =
        !_miningActive &&
            _unclaimedMining > 0;

    final String title;
    final String subtitle;
    final String timerText;
    final String timerLabel;

    if (_miningActive) {
      title =
          _localization.get(
        'stellaIsMining',
      );

      subtitle =
          _localization.get(
        'stellaMiningNow',
      );

      timerText =
          _formatDuration(
        _miningRemainingMs,
      );

      timerLabel =
          _localization.get(
        'timeRemaining',
      );
    } else if (completed) {
      title =
          _localization.get(
        'miningComplete',
      );

      subtitle =
          _localization.get(
        'stlReadyToCollect',
      );

      timerText =
          '00:00:00';

      timerLabel =
          _localization.get(
        'miningFinished',
      );
    } else {
      title =
          _localization.get(
        'stellaIsResting',
      );

      subtitle =
          _localization.get(
        'stellaWaiting',
      );

      timerText =
          _localization.get(
        'ready',
      );

      timerLabel =
          _localization.get(
        'waitingForStella',
      );
    }

    return StellaMiningCard(
      unclaimedMining: _unclaimedMining,
      miningTitle: title,
      miningSubtitle: subtitle,
      timerText: timerText,
      timerLabel: timerLabel,
      catAnimation: _catAnimation,
    );
  }

  // ============================================================
  // 📊 STATS
  // ============================================================

  Widget _buildStatsRow() {
    return HomeStatsCard(
      hashRateTitle:
          _localization.get(
        'hashRate',
      ),
      hashRateValue:
          '${_effectiveHashRate.toStringAsFixed(4)} HR',
      totalStlTitle:
          _localization.get(
        'totalStl',
      ),
      totalStlValue:
          '${_formatStl(
            _estimatedTotal,
          )} STL',
    );
  }

  // ============================================================
  // 📈 MINING PROGRESS
  // ============================================================

  Widget _buildMiningProgress() {
    return MiningProgressCard(
      miningActive: _miningActive,
      miningRemainingMs: _miningRemainingMs,
      miningDurationMs: _miningDurationMs,
      title:
          _localization.get(
        'stellaMiningProgress',
      ),
      stlPerHourText:
          _localization.getWithParams(
        'stlPerHour',
        params: {
          'amount':
              _miningPerHour
                  .toStringAsFixed(4),
        },
      ),
      dailyHashRateText:
          _localization.getWithParams(
        'dailyHashRateLabel',
        params: {
          'amount':
              _dailyHashRate
                  .toStringAsFixed(1),
        },
      ),
      dailyHashRateDayText:
          _localization.getWithParams(
        'dailyHashRateDay',
        params: {
          'day':
              _streak.toString(),
          'amount':
              _dailyHashRate
                  .toStringAsFixed(1),
        },
      ),
      hashRateBonusText:
          _adBoostActive
              ? _localization.getWithParams(
                  'hashRateBonus',
                  params: {
                    'amount':
                        _adHashRateBonus
                            .toStringAsFixed(4),
                  },
                )
              : '',
      effectiveHashRateText:
          _adBoostActive
              ? _localization.getWithParams(
                  'effectiveHashRateLabel',
                  params: {
                    'amount':
                        _effectiveHashRate
                            .toStringAsFixed(4),
                  },
                )
              : '',
    );
  }

  // ============================================================
  // ⛏️ MINING BUTTON
  // ============================================================

  Widget _buildMiningButton() {
    final bool completed =
        !_miningActive &&
            _unclaimedMining > 0;

    String text;
    IconData icon;
    VoidCallback? onPressed;

    if (_actionLoading) {
      text =
          _localization.get(
        'stellaIsWorking',
      );

      icon =
          Icons.hourglass_top_rounded;

      onPressed = null;
    } else if (_miningActive) {
      text =
          _localization.get(
        'stellaIsMiningButton',
      );

      icon =
          Icons.lock_rounded;

      onPressed = () {
        _showMessage(
          _localization.get(
            'stellaAlreadyMining',
          ),
        );
      };
    } else if (completed) {
      text =
          _localization.get(
        'watchAdCollectRestart',
      );

      icon =
          Icons.inventory_2_rounded;

      onPressed =
          _startMining;
    } else {
      text =
          _localization.get(
        'watchAdStartMining',
      );

      icon =
          Icons.play_arrow_rounded;

      onPressed =
          _startMining;
    }

    return SizedBox(
      width:
          double.infinity,
      height:
          62,
      child:
          ElevatedButton.icon(
        onPressed:
            onPressed,
        icon:
            Icon(icon),
        label:
            Text(
          text,
          textAlign:
              TextAlign.center,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
            letterSpacing:
                0.5,
          ),
        ),
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              accentColor,
          foregroundColor:
              Colors.white,
          disabledBackgroundColor:
              const Color(
                0xFF4A315F,
              ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 📺 POWER BOOST CARD
  // ============================================================

  Widget _buildAdButton() {
    final bool boostActive =
        _adBoostActive &&
            _adBoostRemainingMs > 0;

    final bool canUse =
        _canWatchAd &&
            _adReady &&
            !_actionLoading &&
            !boostActive &&
            _adsToday < _maxAdsPerDay &&
            _cooldownRemainingMs <= 0;

    String subtitle;

    if (_adsToday >=
        _maxAdsPerDay) {
      subtitle =
          _localization.get(
        'dailyLimitReached',
      );
    } else if (boostActive) {
      subtitle =
          _formatDuration(
        _adBoostRemainingMs,
      );
    } else if (_cooldownRemainingMs > 0) {
      subtitle =
          _formatDuration(
        _cooldownRemainingMs,
      );
    } else if (!_adReady) {
      subtitle =
          _localization.get(
        'adLoading',
      );
    } else {
      subtitle =
          _localization.getWithParams(
        'powerBoostOffer',
        params: {
          'amount':
              _adHashRateBonus
                  .toStringAsFixed(4),
          'hours': '4',
        },
      );
    }

    return Container(
      padding:
          const EdgeInsets.all(
        18,
      ),
      decoration:
          BoxDecoration(
        color:
            cardColor,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        border:
            Border.all(
          color:
              boostActive
                  ? goldColor.withValues(
                      alpha: 0.40,
                    )
                  : pinkColor.withValues(
                      alpha: 0.30,
                    ),
        ),
      ),
      child:
          Column(
        children: [
          Row(
            children: [
              Text(
                boostActive
                    ? '⚡'
                    : '📺',
                style:
                    const TextStyle(
                  fontSize: 28,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localization.get(
                        'powerBoost',
                      ),
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      boostActive
                          ? _localization.get(
                              'powerBoostActive',
                            )
                          : subtitle,
                      style:
                          const TextStyle(
                        color:
                            secondaryTextColor,
                        fontSize:
                            12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          if (boostActive)
            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.all(
                14,
              ),
              decoration:
                  BoxDecoration(
                color:
                    goldColor.withValues(
                  alpha: 0.08,
                ),
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
                border:
                    Border.all(
                  color:
                      goldColor.withValues(
                    alpha: 0.25,
                  ),
                ),
              ),
              child:
                  Column(
                children: [
                  Text(
                    _localization.get(
                      'powerBoostActiveTitle',
                    ),
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      color:
                          goldColor,
                      fontWeight:
                          FontWeight.bold,
                      fontSize:
                          12,
                    ),
                  ),

                  const SizedBox(
                    height: 7,
                  ),

                  Text(
                    _localization.getWithParams(
                      'remaining',
                      params: {
                        'time':
                            _formatDuration(
                          _adBoostRemainingMs,
                        ),
                      },
                    ),
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize:
                          18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    _localization.getWithParams(
                      'hashRateBonus',
                      params: {
                        'amount':
                            _adHashRateBonus
                                .toStringAsFixed(4),
                      },
                    ),
                    style:
                        const TextStyle(
                      color:
                          pinkColor,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    _localization.getWithParams(
                      'effectiveHashRateLabel',
                      params: {
                        'amount':
                            _effectiveHashRate
                                .toStringAsFixed(4),
                      },
                    ),
                    style:
                        const TextStyle(
                      color:
                          goldColor,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    _localization.get(
                      'nextAdAfterBoost',
                    ),
                    textAlign:
                        TextAlign.center,
                    style:
                        TextStyle(
                      color:
                          Colors.white.withValues(
                        alpha: 0.50,
                      ),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width:
                  double.infinity,
              child:
                  OutlinedButton(
                onPressed:
                    canUse
                        ? _watchAd
                        : null,
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      pinkColor,
                  disabledForegroundColor:
                      Colors.white.withValues(
                    alpha: 0.35,
                  ),
                  side:
                      const BorderSide(
                    color:
                        pinkColor,
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                ),
                child:
                    Text(
                  _localization.get(
                    'watchAd',
                  ),
                  textAlign:
                      TextAlign.center,
                  maxLines:
                      1,
                  overflow:
                      TextOverflow.ellipsis,
                ),
              ),
            ),

          const SizedBox(
            height: 10,
          ),

          Text(
            _localization.getWithParams(
              'adsToday',
              params: {
                'current':
                    _adsToday.toString(),
                'max':
                    _maxAdsPerDay.toString(),
              },
            ),
            style:
                const TextStyle(
              color:
                  Color(0xFF8D7BA8),
              fontSize:
                  11,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            _localization.getWithParams(
              'maxBoostsInfo',
              params: {
                'count':
                    _maxAdsPerDay.toString(),
              },
            ),
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  Color(0xFF6F5C84),
              fontSize:
                  10,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🐱 STELLA FOOTER
  // ============================================================

  Widget _buildStellaFooter() {
    return Center(
      child:
          Column(
        children: [
          const Text(
            '🐱💜⛏️',
            style:
                TextStyle(
              fontSize:
                  28,
            ),
          ),

          const SizedBox(
            height:
                8,
          ),

          Text(
            _localization.get(
              'footerTagline',
            ),
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  Color(0xFF8D7BA8),
              fontStyle:
                  FontStyle.italic,
            ),
          ),

          const SizedBox(
            height:
                4,
          ),

          Text(
            _localization.get(
              'footerToken',
            ),
            style:
                const TextStyle(
              color:
                  Color(0xFF5F4D70),
              fontSize:
                  11,
              letterSpacing:
                  2,
            ),
          ),
        ],
      ),
    );
  }
}