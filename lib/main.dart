import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MobileAds.instance.initialize();

  runApp(const CoinMinerApp());
}

class CoinMinerApp extends StatelessWidget {
  const CoinMinerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coin Miner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF101114),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String rewardedAdId =
      'ca-app-pub-3940256099942544/5224354917';

  static const String interstitialAdId =
      'ca-app-pub-3940256099942544/1033173712';

  static const String nameKey = 'name';
  static const String coinsKey = 'coins';
  static const String claimKey = 'claimTime';
  static const String rewardTimeKey = 'rewardTime';
  static const String rewardCountKey = 'rewardCount';
  static const String rewardDayKey = 'rewardDay';

  SharedPreferences? _prefs;

  final TextEditingController _nameController =
      TextEditingController();

  Timer? _timer;

  String _name = '';
  String _error = '';

  int _coins = 0;
  int _rewardCount = 0;

  DateTime? _lastClaim;
  DateTime? _lastReward;

  Duration _claimTimer = Duration.zero;
  Duration _rewardTimer = Duration.zero;

  bool _loading = true;
  bool _savingName = false;
  bool _claiming = false;
  bool _showingReward = false;

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;

  bool _loadingRewarded = false;
  bool _loadingInterstitial = false;

  @override
  void initState() {
    super.initState();

    _loadData();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) {
          return;
        }

        _updateTimers();
        _checkNewDay();
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();

    _nameController.dispose();

    _rewardedAd?.dispose();
    _interstitialAd?.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    _prefs = prefs;

    _name = prefs.getString(nameKey) ?? '';
    _coins = prefs.getInt(coinsKey) ?? 0;
    _rewardCount = prefs.getInt(rewardCountKey) ?? 0;

    final claimMilliseconds = prefs.getInt(claimKey);

    if (claimMilliseconds != null) {
      _lastClaim = DateTime.fromMillisecondsSinceEpoch(
        claimMilliseconds,
        isUtc: true,
      );
    }

    final rewardMilliseconds = prefs.getInt(rewardTimeKey);

    if (rewardMilliseconds != null) {
      _lastReward = DateTime.fromMillisecondsSinceEpoch(
        rewardMilliseconds,
        isUtc: true,
      );
    }

    final savedDay = prefs.getString(rewardDayKey);
    final today = _today();

    if (savedDay != today) {
      _rewardCount = 0;

      await prefs.setInt(
        rewardCountKey,
        0,
      );

      await prefs.setString(
        rewardDayKey,
        today,
      );
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }

    _updateTimers();
    _loadRewardedAd();
    _loadInterstitialAd();
  }

  // ============================================================
  // DATE
  // ============================================================

  String _today() {
    final now = DateTime.now().toUtc();

    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // ============================================================
  // NEW DAY
  // ============================================================

  Future<void> _checkNewDay() async {
    if (_prefs == null) {
      return;
    }

    final today = _today();

    final savedDay = _prefs!.getString(rewardDayKey);

    if (savedDay == today) {
      return;
    }

    _rewardCount = 0;

    await _prefs!.setString(
      rewardDayKey,
      today,
    );

    await _prefs!.setInt(
      rewardCountKey,
      0,
    );

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // TIMERS
  // ============================================================

  void _updateTimers() {
    final now = DateTime.now().toUtc();

    Duration claim = Duration.zero;

    if (_lastClaim != null) {
      final nextClaim = _lastClaim!.add(
        const Duration(hours: 24),
      );

      if (now.isBefore(nextClaim)) {
        claim = nextClaim.difference(now);
      }
    }

    Duration reward = Duration.zero;

    if (_lastReward != null) {
      final nextReward = _lastReward!.add(
        const Duration(hours: 1),
      );

      if (now.isBefore(nextReward)) {
        reward = nextReward.difference(now);
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _claimTimer = claim;
      _rewardTimer = reward;
    });
  }

  bool get canClaim {
    return _claimTimer == Duration.zero;
  }

  bool get canReward {
    if (_rewardCount >= 5) {
      return false;
    }

    return _rewardTimer == Duration.zero;
  }

  // ============================================================
  // USERNAME
  // ============================================================

  Future<void> _continue() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _error = 'Enter your name';
      });

      return;
    }

    setState(() {
      _savingName = true;
      _error = '';
    });

    try {
      await _prefs?.setString(
        nameKey,
        name,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _name = name;
        _savingName = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _savingName = false;
        _error = 'Could not save your name';
      });
    }
  }

  // ============================================================
  // DAILY CLAIM
  // ============================================================

  Future<void> _claimCoins() async {
    if (_claiming || !canClaim) {
      return;
    }

    setState(() {
      _claiming = true;
    });

    _coins += 10;

    _lastClaim = DateTime.now().toUtc();

    await _prefs?.setInt(
      coinsKey,
      _coins,
    );

    await _prefs?.setInt(
      claimKey,
      _lastClaim!.millisecondsSinceEpoch,
    );

    _updateTimers();

    if (mounted) {
      setState(() {
        _claiming = false;
      });
    }

    _message('+10 coins!');

    // Interstitial after daily claim.
    _showInterstitial();
  }

  // ============================================================
  // REWARDED AD
  // ============================================================

  Future<void> _watchRewardAd() async {
    if (_showingReward) {
      return;
    }

    await _checkNewDay();

    if (_rewardCount >= 5) {
      _message(
        'Daily limit reached: 5 ads.',
      );

      return;
    }

    if (!canReward) {
      _message(
        'Please wait for the 1 hour timer.',
      );

      return;
    }

    final ad = _rewardedAd;

    if (ad == null) {
      _message(
        'Advertisement is loading. Try again shortly.',
      );

      _loadRewardedAd();

      return;
    }

    _rewardedAd = null;

    setState(() {
      _showingReward = true;
    });

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();

        if (mounted) {
          setState(() {
            _showingReward = false;
          });
        }

        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent:
          (ad, error) {
        ad.dispose();

        if (mounted) {
          setState(() {
            _showingReward = false;
          });

          _message(
            'Advertisement could not be shown.',
          );
        }

        _loadRewardedAd();
      },
    );

    ad.show(
      onUserEarnedReward:
          (AdWithoutView ad, RewardItem reward) {
        _giveFiveCoins();
      },
    );
  }

  Future<void> _giveFiveCoins() async {
    await _checkNewDay();

    _coins += 5;
    _rewardCount++;

    _lastReward = DateTime.now().toUtc();

    await _prefs?.setInt(
      coinsKey,
      _coins,
    );

    await _prefs?.setInt(
      rewardCountKey,
      _rewardCount,
    );

    await _prefs?.setInt(
      rewardTimeKey,
      _lastReward!.millisecondsSinceEpoch,
    );

    if (!mounted) {
      return;
    }

    setState(() {});

    _updateTimers();

    _message('+5 coins!');
  }

  // ============================================================
  // LOAD REWARDED AD
  // ============================================================

  void _loadRewardedAd() {
    if (_loadingRewarded || _rewardedAd != null) {
      return;
    }

    _loadingRewarded = true;

    RewardedAd.load(
      adUnitId: rewardedAdId,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingRewarded = false;
          _rewardedAd = ad;

          if (mounted) {
            setState(() {});
          }
        },
        onAdFailedToLoad: (error) {
          _loading