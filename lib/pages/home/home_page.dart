import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../data/cat_facts.dart';
import '../../localization.dart';
import '../../widgets/home_drawer.dart';
import 'cat_fact_card.dart';

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

  /// Daily Hash Rate.
  ///
  /// Day 1 = 0.5 HR
  /// Day 2 = 1.0 HR
  /// Day 3 = 1.5 HR
  /// Day 4 = 2.0 HR
  /// Day 5 = 2.5 HR
  /// Day 6 = 3.0 HR
  /// Day 7+ = 3.5 HR
  double _hashRate = defaultDailyHashRate;

  double _miningBalance = 0.0;
  double _unclaimedMining = 0.0;
  double _estimatedTotal = 0.0;
  double _miningPerHour = 0.0;

  int _miningRemainingMs = 0;

  int _miningDurationMs =
      defaultMiningDurationMs;

  // ============================================================
  // 🎁 DAILY BONUS
  // ============================================================

  bool _dailyClaimed = false;
  int _streak = 0;

  double _dailyHashRateBonus =
      defaultDailyHashRate;

  // ============================================================
  // ⚡ POWER BOOST STATE
  // ============================================================

  int _adsToday = 0;

  int _maxAdsPerDay =
      defaultMaxAdsPerDay;

  double _adHashRateBonus =
      defaultAdHashRateBonus;

  bool _canWatchAd = false;

  /// Remaining cooldown / active boost time.
  int _cooldownRemainingMs = 0;

  bool _adBoostActive = false;

  int _adBoostRemainingMs = 0;

  /// Effective Hash Rate:
  ///
  /// Daily HR
  /// +
  /// active Power Boost
  double _effectiveHashRate =
      defaultDailyHashRate;

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
          // ----------------------------------------------------
          // MINING TIMER
          // ----------------------------------------------------

          if (_miningActive &&
              _miningRemainingMs > 0) {
            _miningRemainingMs -= 1000;

            if (_miningRemainingMs <= 0) {
              _miningRemainingMs = 0;
              _miningActive = false;
            }
          }

          // ----------------------------------------------------
          // POWER BOOST TIMER
          // ----------------------------------------------------

          if (_adBoostActive &&
              _adBoostRemainingMs > 0) {
            _adBoostRemainingMs -= 1000;

            if (_adBoostRemainingMs <= 0) {
              _adBoostRemainingMs = 0;
              _adBoostActive = false;

              _effectiveHashRate =
                  _hashRate;

              _cooldownRemainingMs = 0;

              _recalculateMiningPerHour();
            }
          }

          // ----------------------------------------------------
          // COOLDOWN TIMER
          // ----------------------------------------------------

          if (!_adBoostActive &&
              _cooldownRemainingMs > 0) {
            _cooldownRemainingMs -= 1000;

            if (_cooldownRemainingMs <= 0) {
              _cooldownRemainingMs = 0;
            }
          }

          // ----------------------------------------------------
          // AD AVAILABILITY
          //
          // The server remains authoritative. This only
          // updates the local UI between server refreshes.
          // ----------------------------------------------------

          if (!_adBoostActive &&
              _cooldownRemainingMs <= 0 &&
              _adsToday < _maxAdsPerDay) {
            _canWatchAd = true;
          }

          // ----------------------------------------------------
          // LIVE MINING
          // ----------------------------------------------------

          _updateLiveMiningAmount();
        });
      },
    );

    // ----------------------------------------------------------
    // SERVER REFRESH
    // ----------------------------------------------------------

    _refreshTimer?.cancel();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) async {
        await _loadMiningStatus();
      },
    );
  }

  // ============================================================
  // LIVE MINING
  // ============================================================

  void _updateLiveMiningAmount() {
    if (!_miningActive) {
      return;
    }

    final double liveMiningPerHour =
        _effectiveHashRate *
        miningPerHashPerHour;

    if (liveMiningPerHour <= 0) {
      return;
    }

    final double perSecond =
        liveMiningPerHour / 3600.0;

    _unclaimedMining += perSecond;

    _estimatedTotal =
        _miningBalance +
        _unclaimedMining;
  }

  // ============================================================
  // MINING RATE
  // ============================================================

  void _recalculateMiningPerHour() {
    _effectiveHashRate =
        _adBoostActive
            ? _hashRate +
                _adHashRateBonus
            : _hashRate;

    _miningPerHour =
        _effectiveHashRate *
        miningPerHashPerHour;
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

      final result =
          await callable.call();

      final data =
          Map<String, dynamic>.from(
        result.data as Map,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        // ------------------------------------------------------
        // MINING
        // ------------------------------------------------------

        _hashRate = _toDouble(
          data['hashRate'],
        );

        if (_hashRate <= 0) {
          _hashRate =
              defaultDailyHashRate;
        }

        _miningBalance = _toDouble(
          data['miningBalance'],
        );

        _unclaimedMining = _toDouble(
          data['unclaimedMining'],
        );

        _estimatedTotal = _toDouble(
          data['estimatedTotal'],
        );

        _miningPerHour = _toDouble(
          data['miningPerHour'],
        );

        _miningActive =
            data['miningActive'] == true;

        _miningRemainingMs = _toInt(
          data['miningRemainingMs'],
        );

        _miningDurationMs = _toInt(
          data['miningDurationMs'],
        );

        if (_miningDurationMs <= 0) {
          _miningDurationMs =
              defaultMiningDurationMs;
        }

        // ------------------------------------------------------
        // DAILY
        // ------------------------------------------------------

        _dailyClaimed =
            data['dailyClaimed'] == true;

        _streak = _toInt(
          data['streak'] ??
              data['dailyStreak'],
        );

        _dailyHashRateBonus =
            _toDouble(
          data['dailyHashRateBonus'],
        );

        if (_dailyHashRateBonus <= 0) {
          _dailyHashRateBonus =
              _hashRate > 0
                  ? _hashRate
                  : _calculateDailyHashRate(
                      _streak,
                    );
        }

        // ------------------------------------------------------
        // POWER BOOST
        // ------------------------------------------------------

        _adsToday = _toInt(
          data['adsToday'],
        );

        _maxAdsPerDay = _toInt(
          data['maxAdsPerDay'],
        );

        if (_maxAdsPerDay <= 0) {
          _maxAdsPerDay =
              defaultMaxAdsPerDay;
        }

        _adHashRateBonus =
            _toDouble(
          data['adHashRateBonus'],
        );

        if (_adHashRateBonus <= 0) {
          _adHashRateBonus =
              defaultAdHashRateBonus;
        }

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

        // If the backend says there is no remaining time,
        // the boost cannot remain visually active.
        if (_adBoostRemainingMs <= 0) {
          _adBoostRemainingMs = 0;
          _adBoostActive = false;
        }

        // ------------------------------------------------------
        // EFFECTIVE HASH RATE
        // ------------------------------------------------------

        final double backendEffectiveHashRate =
            _toDouble(
          data['effectiveHashRate'],
        );

        if (backendEffectiveHashRate > 0) {
          _effectiveHashRate =
              backendEffectiveHashRate;
        } else {
          _effectiveHashRate =
              _adBoostActive
                  ? _hashRate +
                      _adHashRateBonus
                  : _hashRate;
        }

        // ------------------------------------------------------
        // CAN WATCH AD
        // ------------------------------------------------------

        _canWatchAd =
            data['canWatchAd'] == true;

        if (_adBoostActive ||
            _adBoostRemainingMs > 0) {
          _canWatchAd = false;
        }

        if (_adsToday >=
            _maxAdsPerDay) {
          _canWatchAd = false;
        }

        // ------------------------------------------------------
        // FALLBACK MINING RATE
        // ------------------------------------------------------

        if (_miningPerHour <= 0) {
          _miningPerHour =
              _effectiveHashRate *
              miningPerHashPerHour;
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

    final RewardedAd ad =
        _rewardedAd!;

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
              started == false;

      final double collected =
          _toDouble(
        data['collected'],
      );

      if (alreadyMining) {
        _showMessage(
          _localization.get(
            'stellaAlreadyMining',
          ),
        );
      } else if (collected > 0) {
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
          _localization.get(
            'miningStarted',
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
  // 🎁 DAILY CHECK-IN
  // ============================================================

  Future<void> _dailyCheckIn() async {
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
        'dailyCheckIn',
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

      final bool alreadyClaimed =
          data['alreadyClaimed'] == true;

      if (alreadyClaimed) {
        _showMessage(
          _localization.get(
            'dailyBonusAlreadyClaimed',
          ),
        );
      } else {
        final double dailyHashRate =
            _toDouble(
          data['dailyHashRate'],
        );

        final int streak =
            _toInt(
          data['dailyStreak'] ??
              data['streak'],
        );

        final double displayedHashRate =
            dailyHashRate > 0
                ? dailyHashRate
                : _calculateDailyHashRate(
                    streak,
                  );

        _showMessage(
          '🐱 Daily Hash Rate: '
          '${displayedHashRate.toStringAsFixed(1)} HR '
          '• Day $streak',
        );
      }

      await _loadMiningStatus();
    } catch (error) {
      debugPrint(
        'Daily error: $error',
      );

      if (mounted) {
        _showMessage(
          _localization.get(
            'dailyBonusFailed',
          ),
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

    // ----------------------------------------------------------
    // ACTIVE BOOST
    // ----------------------------------------------------------

    if (_adBoostActive &&
        _adBoostRemainingMs > 0) {
      _showMessage(
        '⚡ Stella’s Power Boost is active. '
        'Next ad in '
        '${_formatDuration(
          _adBoostRemainingMs,
        )}.',
      );

      return;
    }

    // ----------------------------------------------------------
    // DAILY LIMIT
    // ----------------------------------------------------------

    if (_adsToday >=
        _maxAdsPerDay) {
      _showMessage(
        _localization.get(
          'dailyLimitReached',
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // COOLDOWN
    // ----------------------------------------------------------

    if (_cooldownRemainingMs > 0) {
      _showMessage(
        '⏳ Next Power Boost in '
        '${_formatDuration(
          _cooldownRemainingMs,
        )}.',
      );

      return;
    }

    // ----------------------------------------------------------
    // BACKEND AVAILABILITY
    // ----------------------------------------------------------

    if (!_canWatchAd) {
      _showMessage(
        _localization.get(
          'prepareAd',
        ),
      );

      await _loadMiningStatus();

      return;
    }

    // ----------------------------------------------------------
    // AD READY
    // ----------------------------------------------------------

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

    final RewardedAd ad =
        _rewardedAd!;

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

        _showMessage(
          '⚡ Power Boost activated! '
          '+${boostAmount.toStringAsFixed(4)} HR '
          'for 4 hours 🐱',
        );

        // ------------------------------------------------------
        // Immediate local UI update.
        //
        // Backend remains authoritative and the next status
        // refresh will synchronize everything again.
        // ------------------------------------------------------

        setState(() {
          _adBoostActive = true;

          _adBoostRemainingMs =
              duration;

          _adHashRateBonus =
              boostAmount;

          _effectiveHashRate =
              _hashRate +
              _adHashRateBonus;

          _miningPerHour =
              _effectiveHashRate *
              miningPerHashPerHour;

          _canWatchAd = false;

          _cooldownRemainingMs =
              duration;
        });
      } else if (duplicate) {
        _showMessage(
          _localization.get(
            'adRewardDuplicate',
          ),
        );
      } else if (boostActive) {
        _showMessage(
          '⚡ Stella already has an active '
          'Power Boost. Please wait until it ends.',
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
  // 🌍 LANGUAGE
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
                      context: dialogContext,
                      code: entry.key,
                      title: entry.value,
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
                  : const Color(
                      0xFF35204F,
                    ),
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
  // 🐱 DRAWER PAGE MESSAGE
  // ============================================================

  void _showStellaPageMessage(
    String titleKey,
  ) {
    _showMessage(
      _localization.getWithParams(
        'comingSoon',
        params: {
          'title':
              _localization.get(
            titleKey,
          ),
        },
      ),
    );
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
            style: const TextStyle(
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
                BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ============================================================
  // DISPOSE
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          backgroundColor,

      // ========================================================
      // 🐱 STELLA DRAWER
      // ========================================================

      drawer: HomeDrawer(
        onLanguagePressed:
            _showLanguageDialog,

        onAboutPressed: () {
          _showStellaPageMessage(
            'about',
          );
        },

        onWhitePaperPressed: () {
          _showStellaPageMessage(
            'whitePaper',
          );
        },

        onTokenPressed: () {
          _showStellaPageMessage(
            'token',
          );
        },

        onTokenomicsPressed: () {
          _showStellaPageMessage(
            'tokenomics',
          );
        },

        onRoadmapPressed: () {
          _showStellaPageMessage(
            'roadmap',
          );
        },

        onTransactionHistoryPressed: () {
          _showStellaPageMessage(
            'transactionHistory',
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
                          height: 24,
                        ),

                        _buildDailyBonusCard(),

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

        Container(
          width: 58,
          height: 58,
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
            gradient:
                const LinearGradient(
              colors: [
                pinkColor,
                accentColor,
              ],
            ),
            boxShadow:
                const [
              BoxShadow(
                color:
                    Color(0x663C1B63),
                blurRadius: 20,
              ),
            ],
          ),
          child:
              const Center(
            child:
                Text(
              '🐱',
              style:
                  TextStyle(
                fontSize: 30,
              ),
            ),
          ),
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

    return Container(
      padding:
          const EdgeInsets.all(
        24,
      ),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          30,
        ),
        gradient:
            const LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            Color(0xFF2D174D),
            Color(0xFF1B1033),
          ],
        ),
        border:
            Border.all(
          color:
              accentColor.withValues(
            alpha: 0.4,
          ),
        ),
        boxShadow:
            const [
              BoxShadow(
                color:
                    Color(0x55000000),
                blurRadius: 25,
                offset:
                    Offset(0, 10),
              ),
            ],
      ),
      child:
          Column(
        children: [
          AnimatedBuilder(
            animation:
                _catAnimation,
            builder:
                (
              context,
              child,
            ) {
              return Transform.translate(
                offset:
                    Offset(
                  0,
                  -_catAnimation.value,
                ),
                child:
                    child,
              );
            },
            child:
                Container(
              width: 110,
              height: 110,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color:
                    accentColor.withValues(
                  alpha: 0.15,
                ),
              ),
              child:
                  const Center(
                child:
                    Text(
                  '🐱⛏️',
                  style:
                      TextStyle(
                    fontSize: 55,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          Text(
            title,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  Colors.white,
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            subtitle,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  secondaryTextColor,
              fontSize: 14,
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          Text(
            _formatStl(
              _unclaimedMining,
            ),
            style:
                const TextStyle(
              color:
                  goldColor,
              fontSize: 38,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            _localization.get(
              'stlMined',
            ),
            style:
                const TextStyle(
              color:
                  Color(0xFFBFAEDB),
              letterSpacing:
                  2,
              fontSize: 12,
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 20,
            ),
            decoration:
                BoxDecoration(
              color:
                  Colors.black.withValues(
                alpha: 0.20,
              ),
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
            ),
            child:
                Column(
              children: [
                Text(
                  timerText,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 27,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  timerLabel,
                  style:
                      const TextStyle(
                    color:
                        Color(0xFFBFAEDB),
                    fontSize: 11,
                    letterSpacing:
                        1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 📊 STATS
  // ============================================================

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child:
              _buildStatCard(
            icon:
                Icons.bolt_rounded,
            title:
                _localization.get(
              'hashRate',
            ),
            value:
                '${_effectiveHashRate.toStringAsFixed(4)} HR',
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        Expanded(
          child:
              _buildStatCard(
            icon:
                Icons.currency_bitcoin_rounded,
            title:
                _localization.get(
              'totalStl',
            ),
            value:
                '${_formatStl(
                  _estimatedTotal,
                )} STL',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration:
          BoxDecoration(
        color:
            cardColor,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border:
            Border.all(
          color:
              Colors.white.withValues(
            alpha: 0.06,
          ),
        ),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color:
                pinkColor,
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            title,
            style:
                const TextStyle(
              color:
                  Color(0xFFBFAEDB),
              fontSize: 10,
              letterSpacing:
                  1,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            value,
            maxLines:
                1,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              color:
                  Colors.white,
              fontSize: 15,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 📈 MINING PROGRESS
  // ============================================================

  Widget _buildMiningProgress() {
    double progress = 0.0;

    if (_miningActive &&
        _miningDurationMs > 0) {
      progress =
          1.0 -
          (_miningRemainingMs /
              _miningDurationMs);

      progress =
          progress
              .clamp(
                0.0,
                1.0,
              )
              .toDouble();
    }

    return Container(
      padding:
          const EdgeInsets.all(
        20,
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
              accentColor.withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child:
                    Text(
                  _localization.get(
                    'stellaMiningProgress',
                  ),
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style:
                    const TextStyle(
                  color:
                      goldColor,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            child:
                LinearProgressIndicator(
              value:
                  progress,
              minHeight:
                  12,
              backgroundColor:
                  backgroundColor,
              valueColor:
                  const AlwaysStoppedAnimation<
                      Color>(
                accentColor,
              ),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            '${_miningPerHour.toStringAsFixed(4)} STL / hour',
            style:
                const TextStyle(
              color:
                  secondaryTextColor,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Row(
            children: [
              Text(
                'Daily HR: '
                '${_hashRate.toStringAsFixed(1)} HR',
                style:
                    const TextStyle(
                  color:
                      pinkColor,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              if (_adBoostActive) ...[
                const SizedBox(
                  width: 10,
                ),

                Text(
                  '+${_adHashRateBonus.toStringAsFixed(4)} HR',
                  style:
                      const TextStyle(
                    color:
                        goldColor,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),

          if (_adBoostActive) ...[
            const SizedBox(
              height: 8,
            ),

            Text(
              '⚡ Effective HR: '
              '${_effectiveHashRate.toStringAsFixed(4)} HR',
              style:
                  const TextStyle(
                color:
                    goldColor,
                fontSize: 12,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
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
  // 📺 POWER BOOST
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
          '🐱 ${_localization.get(
            'dailyLimitReached',
          )}';
    } else if (boostActive) {
      subtitle =
          '⚡ ${_formatDuration(
            _adBoostRemainingMs,
          )}';
    } else if (_cooldownRemainingMs > 0) {
      subtitle =
          '⏳ ${_formatDuration(
            _cooldownRemainingMs,
          )}';
    } else if (!_adReady) {
      subtitle =
          _localization.get(
            'adLoading',
          );
    } else {
      subtitle =
          '+${_adHashRateBonus.toStringAsFixed(4)} HR '
          '• 4 hours';
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
                        'stellaPowerBoost',
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
                          ? 'Power Boost active ⚡'
                          : '+${_adHashRateBonus.toStringAsFixed(4)} HR '
                              'for 4 hours',
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

          // ----------------------------------------------------
          // ACTIVE BOOST
          // ----------------------------------------------------

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
                  const Text(
                    '⚡ STELLA POWER BOOST ACTIVE',
                    textAlign:
                        TextAlign.center,
                    style:
                        TextStyle(
                      color:
                          goldColor,
                      fontWeight:
                          FontWeight.bold,
                      fontSize:
                          12,
                      letterSpacing:
                          0.7,
                    ),
                  ),

                  const SizedBox(
                    height: 7,
                  ),

                  Text(
                    '${_formatDuration(
                      _adBoostRemainingMs,
                    )} remaining',
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
                    '+${_adHashRateBonus.toStringAsFixed(4)} HR',
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
                    'Effective HR: '
                    '${_effectiveHashRate.toStringAsFixed(4)} HR',
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
                    'Next ad available when this boost ends.',
                    textAlign:
                        TextAlign.center,
                    style:
                        TextStyle(
                      color:
                          Colors.white
                              .withValues(
                        alpha:
                            0.50,
                      ),
                      fontSize:
                          11,
                    ),
                  ),
                ],
              ),
            )
          else
            // --------------------------------------------------
            // WATCH AD BUTTON
            // --------------------------------------------------
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
                      Colors.white
                          .withValues(
                    alpha:
                        0.35,
                  ),
                  side:
                      const BorderSide(
                    color:
                        pinkColor,
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    vertical:
                        15,
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
                  '${_localization.get(
                    'watchAd',
                  )} • $subtitle',
                  textAlign:
                      TextAlign.center,
                  maxLines:
                      2,
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

          const Text(
            'Max 6 boosts/day • 4 hours each',
            style:
                TextStyle(
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
  // 🎁 DAILY BONUS
  // ============================================================

  Widget _buildDailyBonusCard() {
    final double displayedRate =
        _dailyHashRateBonus > 0
            ? _dailyHashRateBonus
            : _calculateDailyHashRate(
                _streak,
              );

    return Container(
      padding:
          const EdgeInsets.all(
        20,
      ),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF3A1D5A),
            Color(0xFF25113F),
          ],
        ),
        border:
            Border.all(
          color:
              goldColor.withValues(
            alpha: 0.16,
          ),
        ),
      ),
      child:
          Column(
        children: [
          const Text(
            '🐱🎁',
            style:
                TextStyle(
              fontSize: 40,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            _localization.get(
              'stellaDailyBonus',
            ),
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  Colors.white,
              fontSize:
                  17,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            'Day $_streak • '
            'Daily Hash Rate '
            '${displayedRate.toStringAsFixed(1)} HR',
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  Color(0xFFCFC2E8),
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            'Day 7+ reaches the maximum '
            'Daily Hash Rate of 3.5 HR.',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color:
                  Colors.white.withValues(
                alpha: 0.45,
              ),
              fontSize:
                  11,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          SizedBox(
            width:
                double.infinity,
            child:
                ElevatedButton(
              onPressed:
                  _dailyClaimed ||
                          _actionLoading
                      ? null
                      : _dailyCheckIn,
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    goldColor,
                foregroundColor:
                    const Color(
                      0xFF24132F,
                    ),
                disabledBackgroundColor:
                    const Color(
                      0xFF5A4A64,
                    ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(
                  vertical:
                      14,
                ),
              ),
              child:
                  Text(
                _dailyClaimed
                    ? _localization.get(
                        'bonusClaimedToday',
                      )
                    : _localization.get(
                        'claimDailyBonus',
                      ),
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
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