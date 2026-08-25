import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();

  runApp(const StelluriiniMinerApp());
}

class StelluriiniMinerApp extends StatelessWidget {
  const StelluriiniMinerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stelluriini Miner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF35D0A0),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B1112),
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
  // Google AdMob TEST IDs.
  static const String rewardedAdId =
      'ca-app-pub-3940256099942544/5224354917';

  static const String interstitialAdId =
      'ca-app-pub-3940256099942544/1033173712';

  SharedPreferences? _prefs;

  final TextEditingController _nameController =
      TextEditingController();

  Timer? _timer;
  Timer? _rewardRetryTimer;
  Timer? _interstitialRetryTimer;

  String _name = '';
  String _error = '';

  // Stelluriini-saldo.
  int _stl = 0;

  // Daily Login -putki.
  //
  // 0 = ensimmäinen claim antaa 1 STL
  // 1 = seuraava antaa 2 STL
  // 2 = seuraava antaa 3 STL
  // ...
  // 6 = seuraava antaa 7 STL
  // 7 = seuraava antaa edelleen 7 STL
  int _dailyStreak = 0;

  // Tänään katsotut mainokset.
  int _adsToday = 0;

  DateTime? _lastDailyClaim;
  DateTime? _lastAdReward;

  Duration _dailyTimer = Duration.zero;
  Duration _adTimer = Duration.zero;

  bool _loading = true;
  bool _savingName = false;
  bool _claiming = false;
  bool _showingAd = false;

  bool _loadingRewarded = false;
  bool _loadingInterstitial = false;

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;

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
    _rewardRetryTimer?.cancel();
    _interstitialRetryTimer?.cancel();

    _nameController.dispose();

    _rewardedAd?.dispose();
    _interstitialAd?.dispose();

    super.dispose();
  }

  // ============================================================
  // DATA
  // ============================================================

  Future<void> _loadData() async {
    final prefs =
        await SharedPreferences.getInstance();

    _prefs = prefs;

    _name =
        prefs.getString('name') ?? '';

    _stl =
        prefs.getInt('stl') ?? 0;

    _dailyStreak =
        prefs.getInt('dailyStreak') ?? 0;

    _adsToday =
        prefs.getInt('adsToday') ?? 0;

    final dailyClaimTime =
        prefs.getInt('dailyClaimTime');

    if (dailyClaimTime != null) {
      _lastDailyClaim =
          DateTime.fromMillisecondsSinceEpoch(
        dailyClaimTime,
        isUtc: true,
      );
    }

    final adRewardTime =
        prefs.getInt('adRewardTime');

    if (adRewardTime != null) {
      _lastAdReward =
          DateTime.fromMillisecondsSinceEpoch(
        adRewardTime,
        isUtc: true,
      );
    }

    await _checkNewDay();

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
    });

    _updateTimers();

    _loadRewardedAd();
    _loadInterstitialAd();
  }

  String _today() {
    final now =
        DateTime.now().toUtc();

    final year =
        now.year.toString().padLeft(4, '0');

    final month =
        now.month.toString().padLeft(2, '0');

    final day =
        now.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Future<void> _checkNewDay() async {
    if (_prefs == null) {
      return;
    }

    final today = _today();

    final savedDay =
        _prefs!.getString('savedDay');

    if (savedDay == today) {
      return;
    }

    // Uusi päivä:
    // mainosten päiväkohtainen määrä nollataan.
    _adsToday = 0;

    await _prefs!.setString(
      'savedDay',
      today,
    );

    await _prefs!.setInt(
      'adsToday',
      0,
    );

    // Jos viimeisestä Daily Claimistä
    // on vähintään 48 tuntia,
    // yksi kokonainen päivä on jäänyt väliin.
    if (_lastDailyClaim != null) {
      final difference =
          DateTime.now()
              .toUtc()
              .difference(
                _lastDailyClaim!,
              );

      if (difference.inHours >= 48) {
        _dailyStreak = 0;

        await _prefs!.setInt(
          'dailyStreak',
          0,
        );
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // DAILY LOGIN
  // ============================================================

  int get nextDailyReward {
    if (_dailyStreak >= 7) {
      return 7;
    }

    return _dailyStreak + 1;
  }

  bool get canDailyClaim {
    return _dailyTimer == Duration.zero;
  }

  Future<void> _claimDaily() async {
    if (_claiming ||
        !canDailyClaim) {
      return;
    }

    await _checkNewDay();

    final now =
        DateTime.now().toUtc();

    // Jos käyttäjä jätti kokonaisen päivän väliin,
    // putki alkaa uudelleen päivästä 1.
    if (_lastDailyClaim != null) {
      final difference =
          now.difference(
        _lastDailyClaim!,
      );

      if (difference.inHours >= 48) {
        _dailyStreak = 0;
      }
    }

    final reward =
        nextDailyReward;

    setState(() {
      _claiming = true;
    });

    _stl += reward;

    // Maksimi on 7.
    if (_dailyStreak < 7) {
      _dailyStreak++;
    }

    _lastDailyClaim = now;

    await _prefs?.setInt(
      'stl',
      _stl,
    );

    await _prefs?.setInt(
      'dailyStreak',
      _dailyStreak,
    );

    await _prefs?.setInt(
      'dailyClaimTime',
      now.millisecondsSinceEpoch,
    );

    _updateTimers();

    if (!mounted) {
      return;
    }

    setState(() {
      _claiming = false;
    });

    _showMessage(
      'Miau! +$reward STL 🐾',
      Icons.pets,
    );

    _showInterstitial();
  }

  // ============================================================
  // TIMERS
  // ============================================================

  void _updateTimers() {
    final now =
        DateTime.now().toUtc();

    Duration daily =
        Duration.zero;

    Duration ad =
        Duration.zero;

    if (_lastDailyClaim != null) {
      final nextClaim =
          _lastDailyClaim!.add(
        const Duration(hours: 24),
      );

      if (now.isBefore(nextClaim)) {
        daily =
            nextClaim.difference(now);
      }
    }

    if (_lastAdReward != null) {
      final nextAd =
          _lastAdReward!.add(
        const Duration(hours: 1),
      );

      if (now.isBefore(nextAd)) {
        ad =
            nextAd.difference(now);
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _dailyTimer = daily;
      _adTimer = ad;
    });
  }

  bool get canWatchAd {
    return _adsToday < 5 &&
        _adTimer == Duration.zero;
  }

  String _formatTime(
    Duration time,
  ) {
    final hours =
        time.inHours
            .toString()
            .padLeft(2, '0');

    final minutes =
        (time.inMinutes % 60)
            .toString()
            .padLeft(2, '0');

    final seconds =
        (time.inSeconds % 60)
            .toString()
            .padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  // ============================================================
  // NAME
  // ============================================================

  Future<void> _continue() async {
    final name =
        _nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _error =
            'Kirjoita nimesi';
      });

      return;
    }

    setState(() {
      _savingName = true;
      _error = '';
    });

    await _prefs?.setString(
      'name',
      name,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _name = name;
      _savingName = false;
    });
  }

  // ============================================================
  // REWARDED AD
  // ============================================================

  Future<void> _watchAd() async {
    if (_showingAd) {
      return;
    }

    await _checkNewDay();

    if (_adsToday >= 5) {
      _showMessage(
        'Päivän 5 mainoksen raja on täynnä.',
        Icons.pets,
      );

      return;
    }

    if (!canWatchAd) {
      _showMessage(
        'Odota ${_formatTime(_adTimer)}.',
        Icons.timer,
      );

      return;
    }

    final ad =
        _rewardedAd;

    if (ad == null) {
      _showMessage(
        'Mainos latautuu vielä.',
        Icons.hourglass_empty,
      );

      _loadRewardedAd();

      return;
    }

    _rewardedAd = null;

    setState(() {
      _showingAd = true;
    });

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent:
          (ad) {
        ad.dispose();

        if (mounted) {
          setState(() {
            _showingAd = false;
          });
        }

        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent:
          (ad, error) {
        ad.dispose();

        if (mounted) {
          setState(() {
            _showingAd = false;
          });

          _showMessage(
            'Mainoksen näyttäminen epäonnistui.',
            Icons.error,
          );
        }

        _loadRewardedAd();
      },
    );

    ad.show(
      onUserEarnedReward:
          (
        AdWithoutView ad,
        RewardItem reward,
      ) {
        _giveThreeStl();
      },
    );
  }