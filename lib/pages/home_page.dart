import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../widgets/home_drawer.dart';

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
  // 🐱 FIREBASE
  // ============================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  // ============================================================
  // 📺 ADMOB TEST AD
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

  double _hashRate = 1;
  double _miningBalance = 0;
  double _unclaimedMining = 0;
  double _estimatedTotal = 0;
  double _miningPerHour = 0;

  int _miningRemainingMs = 0;

  int _miningDurationMs = 24 * 60 * 60 * 1000;

  // ============================================================
  // 🎁 DAILY BONUS
  // ============================================================

  bool _dailyClaimed = false;
  int _streak = 0;

  double _dailyHashRateBonus = 1;

  // ============================================================
  // 📺 STELLA POWER BOOST
  // ============================================================

  int _adsToday = 0;
  int _maxAdsPerDay = 5;

  double _adHashRateBonus = 5;

  bool _canWatchAd = false;

  int _cooldownRemainingMs = 0;

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

      _loadRewardedAd();

      _startTimers();
    } catch (error) {
      debugPrint(
        'Initialize error: $error',
      );

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }

      _showMessage(
        '🐱 Stella ei saanut yhteyttä palvelimeen.',
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
          if (_miningActive && _miningRemainingMs > 0) {
            _miningRemainingMs -= 1000;

            if (_miningRemainingMs <= 0) {
              _miningRemainingMs = 0;
              _miningActive = false;
            }
          }

          if (_cooldownRemainingMs > 0) {
            _cooldownRemainingMs -= 1000;

            if (_cooldownRemainingMs <= 0) {
              _cooldownRemainingMs = 0;

              _canWatchAd = _adsToday < _maxAdsPerDay;
            }
          }

          _updateLiveMiningAmount();
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
  // LIVE MINING
  // ============================================================

  void _updateLiveMiningAmount() {
    if (!_miningActive) {
      return;
    }

    final double perSecond = _miningPerHour / 3600;

    _unclaimedMining += perSecond;

    _estimatedTotal = _miningBalance + _unclaimedMining;
  }

  // ============================================================
  // LOAD MINING STATUS
  // ============================================================

  Future<void> _loadMiningStatus() async {
    try {
      final callable = _functions.httpsCallable(
        'getMiningStatus',
      );

      final result = await callable.call();

      final data = Map<String, dynamic>.from(
        result.data as Map,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _hashRate = _toDouble(
          data['hashRate'],
        );

        if (_hashRate <= 0) {
          _hashRate = 1;
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

        _miningActive = data['miningActive'] == true;

        _miningRemainingMs = _toInt(
          data['miningRemainingMs'],
        );

        _miningDurationMs = _toInt(
          data['miningDurationMs'],
        );

        if (_miningDurationMs <= 0) {
          _miningDurationMs = 24 * 60 * 60 * 1000;
        }

        // 🎁 DAILY BONUS

        _dailyClaimed = data['dailyClaimed'] == true;

        _streak = _toInt(
          data['streak'],
        );

        _dailyHashRateBonus = _toDouble(
          data['dailyHashRateBonus'],
        );

        if (_dailyHashRateBonus <= 0) {
          _dailyHashRateBonus = 1;
        }

        // 📺 POWER BOOST

        _adsToday = _toInt(
          data['adsToday'],
        );

        _maxAdsPerDay = _toInt(
          data['maxAdsPerDay'],
        );

        if (_maxAdsPerDay <= 0) {
          _maxAdsPerDay = 5;
        }

        _adHashRateBonus = _toDouble(
          data['adHashRateBonus'],
        );

        if (_adHashRateBonus <= 0) {
          _adHashRateBonus = 5;
        }

        _canWatchAd = data['canWatchAd'] == true;

        _cooldownRemainingMs = _toInt(
          data['cooldownRemainingMs'],
        );

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
  // ⛏️ START MINING
  // ============================================================

  Future<void> _startMining() async {
    if (_actionLoading) {
      return;
    }

    if (_miningActive) {
      _showMessage(
        '🐱⛏️ Stella louhii jo STL:ää!',
      );

      return;
    }

    if (_rewardedAd == null || !_adReady) {
      _showMessage(
        '📺 Stella valmistelee mainosta...',
      );

      _loadRewardedAd();

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

    setState(() {
      _actionLoading = true;
    });

    try {
      final callable = _functions.httpsCallable(
        'claimMining',
      );

      final result = await callable.call();

      final data = Map<String, dynamic>.from(
        result.data as Map,
      );

      if (!mounted) {
        return;
      }

      final bool started = data['started'] == true;

      final bool alreadyMining =
          data['miningActive'] == true && started == false;

      final double collected = _toDouble(
        data['collected'],
      );

      if (alreadyMining) {
        _showMessage(
          '🐱⛏️ Stella louhii jo STL:ää!',
        );
      } else if (collected > 0) {
        _showMessage(
          '🐱✨ Stella keräsi '
          '${_formatStl(collected)} STL '
          'ja aloitti uuden 24h louhinnan! ⛏️',
        );
      } else if (started) {
        _showMessage(
          '🐱⛏️📺 Mainos katsottu! '
          'Stella aloitti 24 tunnin louhinnan!',
        );
      } else {
        _showMessage(
          '🐱 Louhinnan käynnistäminen epäonnistui.',
        );
      }

      await _loadMiningStatus();
    } catch (error) {
      debugPrint(
        'Start mining after ad error: $error',
      );

      _showMessage(
        '🐱 Louhinnan käynnistäminen epäonnistui.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _actionLoading = false;
        });
      }

      _loadRewardedAd();
    }
  }

  // ============================================================
  // 🎁 DAILY CHECK-IN
  // ============================================================

  Future<void> _dailyCheckIn() async {
    if (_actionLoading) {
      return;
    }

    setState(() {
      _actionLoading = true;
    });

    try {
      final callable = _functions.httpsCallable(
        'dailyCheckIn',
      );

      final result = await callable.call();

      final data = Map<String, dynamic>.from(
        result.data as Map,
      );

      final bool alreadyClaimed =
          data['alreadyClaimed'] == true;

      if (!mounted) {
        return;
      }

      if (alreadyClaimed) {
        _showMessage(
          '🐱 Stella Daily Bonus on jo kerätty tänään!',
        );
      } else {
        final double bonus = _toDouble(
          data['bonus'],
        );

        final int streak = _toInt(
          data['streak'],
        );

        _showMessage(
          '🐱🎁 +${bonus.toStringAsFixed(0)} Hash Rate! '
          'Streak: $streak 🔥',
        );
      }

      await _loadMiningStatus();
    } catch (error) {
      debugPrint(
        'Daily error: $error',
      );

      _showMessage(
        '🐱 Daily Bonus epäonnistui.',
      );
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
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (
          RewardedAd ad,
        ) {
          _rewardedAd = ad;

          _adReady = true;
          _adLoading = false;

          ad.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (
              RewardedAd ad,
            ) {
              ad.dispose();

              _rewardedAd = null;
              _adReady = false;

              _loadRewardedAd();

              if (mounted) {
                setState(() {});
              }
            },
            onAdFailedToShowFullScreenContent: (
              RewardedAd ad,
              AdError error,
            ) {
              debugPrint(
                'Ad failed to show: $error',
              );

              ad.dispose();

              _rewardedAd = null;
              _adReady = false;

              _loadRewardedAd();

              if (mounted) {
                setState(() {});
              }
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

    if (!_canWatchAd) {
      if (_cooldownRemainingMs > 0) {
        _showMessage(
          '🐱 Stella lepää vielä '
          '${_formatDuration(_cooldownRemainingMs)}.',
        );
      } else {
        _showMessage(
          '🐱 Päivän mainosraja on saavutettu.',
        );
      }

      return;
    }

    if (_rewardedAd == null || !_adReady) {
      _showMessage(
        '📺 Stella valmistelee mainosta...',
      );

      _loadRewardedAd();

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

    setState(() {
      _actionLoading = true;
    });

    try {
      final callable = _functions.httpsCallable(
        'testAdReward',
      );

      final result = await callable.call();

      final data = Map<String, dynamic>.from(
        result.data as Map,
      );

      if (!mounted) {
        return;
      }

      final bool rewarded = data['rewarded'] == true;

      final bool duplicate = data['duplicate'] == true;

      final double bonus = _toDouble(
        data['bonus'],
      );

      if (rewarded) {
        _showMessage(
          '🐱⚡ Stella sai '
          '+${bonus.toStringAsFixed(0)} '
          'Hash Rate Power Boostin!',
        );
      } else if (duplicate) {
        _showMessage(
          '🐱📺 Mainospalkinto on jo käsitelty.',
        );
      } else {
        _showMessage(
          data['message']?.toString() ??
              '🐱 Power Boost epäonnistui.',
        );
      }

      await _loadMiningStatus();
    } catch (error) {
      debugPrint(
        'Test ad reward error: $error',
      );

      _showMessage(
        '🐱 Mainospalkinnon tallentaminen epäonnistui.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _actionLoading = false;
        });
      }

      _loadRewardedAd();
    }
  }

  // ============================================================
  // 🌍 LANGUAGE
  // ============================================================

  Future<void> _showLanguageDialog() async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF21113B),
          title: const Text(
            '🐱 Choose Language',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _languageButton(
                context: dialogContext,
                code: 'fi',
                title: '🇫🇮 Suomi',
              ),
              const SizedBox(height: 10),
              _languageButton(
                context: dialogContext,
                code: 'en',
                title: '🇬🇧 English',
              ),
            ],
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
    final bool selected = widget.languageCode == code;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          Navigator.pop(context);

          await widget.changeLanguage(code);

          if (mounted) {
            _showMessage(
              '🐱 Stella vaihtoi kielen!',
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: selected
              ? const Color(0xFFB58CFF)
              : const Color(0xFF35204F),
          foregroundColor: Colors.white,
        ),
        child: Text(title),
      ),
    );
  }

  // ============================================================
  // 🐱 DRAWER PAGES
  // ============================================================

  void _showStellaPageMessage(
    String title,
  ) {
    _showMessage(
      '🐱✨ $title tulee Stella-teemalla pian!',
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
        0;
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

  String _formatStl(double value) {
    return value.toStringAsFixed(4);
  }

  String _formatDuration(int milliseconds) {
    final Duration duration = Duration(
      milliseconds: milliseconds < 0 ? 0 : milliseconds,
    );

    final String hours = duration.inHours
        .toString()
        .padLeft(2, '0');

    final String minutes = (duration.inMinutes % 60)
        .toString()
        .padLeft(2, '0');

    final String seconds = (duration.inSeconds % 60)
        .toString()
        .padLeft(2, '0');

    return '$hours:$minutes:$seconds';
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
          behavior: SnackBarBehavior.floating,
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
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFF120B24),

      // ========================================================
      // 🐱 STELLA DRAWER
      // ========================================================

      drawer: HomeDrawer(
        onLanguagePressed: _showLanguageDialog,

        onAboutPressed: () {
          _showStellaPageMessage(
            'About Stelluriini',
          );
        },

        onWhitePaperPressed: () {
          _showStellaPageMessage(
            'White Paper',
          );
        },

        onTokenPressed: () {
          _showStellaPageMessage(
            'STL Token',
          );
        },

        onTokenomicsPressed: () {
          _showStellaPageMessage(
            'Tokenomics',
          );
        },

        onRoadmapPressed: () {
          _showStellaPageMessage(
            'Roadmap',
          );
        },

        onTransactionHistoryPressed: () {
          _showStellaPageMessage(
            'Transaction History',
          );
        },
      ),

      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFB58CFF),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadMiningStatus,
                child: ListView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildHeader(),

                    const SizedBox(height: 24),

                    _buildStellaMiningCard(),

                    const SizedBox(height: 20),

                    _buildStatsRow(),

                    const SizedBox(height: 20),

                    _buildMiningProgress(),

                    const SizedBox(height: 24),

                    _buildMiningButton(),

                    const SizedBox(height: 16),

                    _buildAdButton(),

                    const SizedBox(height: 24),

                    _buildDailyBonusCard(),

                    const SizedBox(height: 24),

                    _buildStellaFooter(),

                    const SizedBox(height: 30),
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
              decoration: BoxDecoration(
                color: const Color(0xFF21113B),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: const Color(0xFFB58CFF)
                      .withValues(alpha: 0.45),
                ),
              ),
              child: IconButton(
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                icon: const Icon(
                  Icons.menu_rounded,
                  color: Color(0xFFFFB7E8),
                  size: 29,
                ),
                tooltip: 'Stella Menu',
              ),
            );
          },
        ),

        const SizedBox(width: 12),

        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFB7E8),
                Color(0xFFB58CFF),
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x663C1B63),
                blurRadius: 20,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '🐱',
              style: TextStyle(
                fontSize: 30,
              ),
            ),
          ),
        ),

        const SizedBox(width: 14),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STELLURIINI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Stella Mining ⛏️✨',
                style: TextStyle(
                  color: Color(0xFFFFB7E8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        IconButton(
          onPressed: _loadMiningStatus,
          icon: const Icon(
            Icons.refresh_rounded,
            color: Colors.white,
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
        !_miningActive && _unclaimedMining > 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2D174D),
            Color(0xFF1B1033),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFB58CFF)
              .withValues(alpha: 0.4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 25,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _catAnimation,
            builder: (
              context,
              child,
            ) {
              return Transform.translate(
                offset: Offset(
                  0,
                  -_catAnimation.value,
                ),
                child: child,
              );
            },
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFB58CFF)
                    .withValues(alpha: 0.15),
              ),
              child: const Center(
                child: Text(
                  '🐱⛏️',
                  style: TextStyle(
                    fontSize: 55,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          Text(
            _miningActive
                ? 'STELLA IS MINING'
                : completed
                    ? 'MINING COMPLETE!'
                    : 'STELLA IS RESTING',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _miningActive
                ? '🐾 Stella louhii STL:ää juuri nyt'
                : completed
                    ? '🐱✨ STL on valmis kerättäväksi!'
                    : '🐱 Stella odottaa seuraavaa louhintaa',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFCFC2E8),
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            _formatStl(
              _unclaimedMining,
            ),
            style: const TextStyle(
              color: Color(0xFFFFD166),
              fontSize: 38,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'STL MINED',
            style: TextStyle(
              color: Color(0xFFBFAEDB),
              letterSpacing: 2,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 20,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(
                alpha: 0.2,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Text(
                  _miningActive
                      ? _formatDuration(
                          _miningRemainingMs,
                        )
                      : completed
                          ? '00:00:00'
                          : 'READY',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  _miningActive
                      ? 'TIME REMAINING'
                      : completed
                          ? 'MINING FINISHED'
                          : 'WAITING FOR STELLA',
                  style: const TextStyle(
                    color: Color(0xFFBFAEDB),
                    fontSize: 11,
                    letterSpacing: 1.5,
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
          child: _buildStatCard(
            icon: Icons.bolt_rounded,
            title: 'HASH RATE',
            value:
                '${_hashRate.toStringAsFixed(0)} H/s',
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _buildStatCard(
            icon: Icons.currency_bitcoin_rounded,
            title: 'TOTAL STL',
            value:
                '${_formatStl(_estimatedTotal)} STL',
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF21113B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.06,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFFFFB7E8),
          ),

          const SizedBox(height: 12),

          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFBFAEDB),
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
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
    double progress = 0;

    if (_miningActive && _miningDurationMs > 0) {
      progress = 1 -
          (_miningRemainingMs / _miningDurationMs);

      progress = progress
          .clamp(0.0, 1.0)
          .toDouble();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF21113B),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '⛏️ STELLA MINING PROGRESS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Spacer(),

              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Color(0xFFFFD166),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor:
                  const Color(0xFF120B24),
              valueColor:
                  const AlwaysStoppedAnimation(
                Color(0xFFB58CFF),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            '⚡ ${_miningPerHour.toStringAsFixed(2)} STL / hour',
            style: const TextStyle(
              color: Color(0xFFBFAEDB),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ⛏️ MINING BUTTON
  // ============================================================

  Widget _buildMiningButton() {
    final bool completed =
        !_miningActive && _unclaimedMining > 0;

    String text;
    IconData icon;
    VoidCallback? onPressed;

    if (_actionLoading) {
      text = 'STELLA IS WORKING...';
      icon = Icons.hourglass_top_rounded;
      onPressed = null;
    } else if (_miningActive) {
      text = '🐱 STELLA IS MINING';
      icon = Icons.lock_rounded;

      onPressed = () {
        _showMessage(
          '🐱⛏️ Stella louhii jo STL:ää!',
        );
      };
    } else if (completed) {
      text = '📺 WATCH AD • COLLECT & RESTART';
      icon = Icons.inventory_2_rounded;
      onPressed = _startMining;
    } else {
      text = '📺 WATCH AD • START MINING';
      icon = Icons.play_arrow_rounded;
      onPressed = _startMining;
    }

    return SizedBox(
      width: double.infinity,
      height: 62,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFFB58CFF),
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              const Color(0xFF4A315F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 📺 POWER BOOST
  // ============================================================

  Widget _buildAdButton() {
    final bool canUse =
        _canWatchAd &&
            _adReady &&
            !_actionLoading;

    String subtitle;

    if (_adsToday >= _maxAdsPerDay) {
      subtitle =
          '🐱 Päivän mainosraja saavutettu';
    } else if (_cooldownRemainingMs > 0) {
      subtitle =
          '⏳ ${_formatDuration(_cooldownRemainingMs)}';
    } else if (!_adReady) {
      subtitle =
          '📺 Stella lataa mainosta...';
    } else {
      subtitle =
          '+${_adHashRateBonus.toStringAsFixed(0)} Hash Rate';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF21113B),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFFFB7E8)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                '📺',
                style: TextStyle(
                  fontSize: 28,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STELLA POWER BOOST',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Katso mainos ja auta Stellaa ⚡',
                      style: TextStyle(
                        color: Color(0xFFBFAEDB),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed:
                  canUse ? _watchAd : null,
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    const Color(0xFFFFB7E8),
                side: const BorderSide(
                  color: Color(0xFFFFB7E8),
                ),
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'WATCH AD • $subtitle',
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            '$_adsToday / $_maxAdsPerDay Power Boosts today',
            style: const TextStyle(
              color: Color(0xFF8D7BA8),
              fontSize: 11,
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF3A1D5A),
            Color(0xFF25113F),
          ],
        ),
      ),
      child: Column(
        children: [
          const Text(
            '🐱🎁',
            style: TextStyle(
              fontSize: 40,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'STELLA DAILY BONUS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            '+${_dailyHashRateBonus.toStringAsFixed(0)} Hash Rate • 🔥 $_streak day streak',
            style: const TextStyle(
              color: Color(0xFFCFC2E8),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _dailyClaimed ||
                          _actionLoading
                      ? null
                      : _dailyCheckIn,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFFFD166),
                foregroundColor:
                    const Color(0xFF24132F),
                disabledBackgroundColor:
                    const Color(0xFF5A4A64),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 14,
                ),
              ),
              child: Text(
                _dailyClaimed
                    ? '🐱 BONUS CLAIMED TODAY'
                    : '🎁 CLAIM DAILY BONUS',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
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
    return const Center(
      child: Column(
        children: [
          Text(
            '🐱💜⛏️',
            style: TextStyle(
              fontSize: 28,
            ),
          ),

          SizedBox(height: 8),

          Text(
            'Stella is mining the future.',
            style: TextStyle(
              color: Color(0xFF8D7BA8),
              fontStyle: FontStyle.italic,
            ),
          ),

          SizedBox(height: 4),

          Text(
            'STELLURIINI • STL',
            style: TextStyle(
              color: Color(0xFF5F4D70),
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}