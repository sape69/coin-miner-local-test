import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cat_facts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MobileAds.instance.initialize();

  runApp(const StelluriiniApp());
}

class StelluriiniApp extends StatelessWidget {
  const StelluriiniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stelluriini',
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
  // ============================================================
  // ADMOB
  // ============================================================

  static const String rewardedAdId =
      'ca-app-pub-3940256099942544/5224354917';

  static const String interstitialAdId =
      'ca-app-pub-3940256099942544/1033173712';

  // ============================================================
  // STELLURIINI
  // ============================================================

  static const String stelluriiniMint = '';

  // ============================================================
  // STORAGE KEYS
  // ============================================================

  static const String stlKey = 'stl';
  static const String streakKey = 'streak';
  static const String lastDailyKey = 'lastDaily';
  static const String adsKey = 'adsToday';
  static const String lastAdKey = 'lastAd';
  static const String factKey = 'factDay';
  static const String dateKey = 'currentDate';

  SharedPreferences? prefs;

  RewardedAd? rewardedAd;
  InterstitialAd? interstitialAd;

  Timer? timer;

  int stl = 0;
  int streak = 0;
  int adsToday = 0;

  // 1 = ensimmäinen fakta
  // 2 = toinen fakta
  // jne.
  int factDay = 1;

  DateTime? lastDaily;
  DateTime? lastAd;

  Duration dailyTimer = Duration.zero;
  Duration adTimer = Duration.zero;

  bool loading = true;
  bool loadingRewarded = false;
  bool loadingInterstitial = false;
  bool showingAd = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadData();

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        _updateTimers();
        _checkNewDay();
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    rewardedAd?.dispose();
    interstitialAd?.dispose();

    super.dispose();
  }

  // ============================================================
  // DATA
  // ============================================================

  Future<void> _loadData() async {
    prefs = await SharedPreferences.getInstance();

    stl = prefs!.getInt(stlKey) ?? 0;
    streak = prefs!.getInt(streakKey) ?? 0;
    adsToday = prefs!.getInt(adsKey) ?? 0;

    factDay = prefs!.getInt(factKey) ?? 1;

    if (factDay < 1) {
      factDay = 1;
    }

    final dailyMilliseconds =
        prefs!.getInt(lastDailyKey);

    if (dailyMilliseconds != null) {
      lastDaily =
          DateTime.fromMillisecondsSinceEpoch(
        dailyMilliseconds,
        isUtc: true,
      );
    }

    final adMilliseconds =
        prefs!.getInt(lastAdKey);

    if (adMilliseconds != null) {
      lastAd =
          DateTime.fromMillisecondsSinceEpoch(
        adMilliseconds,
        isUtc: true,
      );
    }

    await _checkNewDay();

    if (!mounted) return;

    setState(() {
      loading = false;
    });

    _updateTimers();

    _loadRewardedAd();
    _loadInterstitialAd();
  }

  String _today() {
    final now = DateTime.now();

    final year =
        now.year.toString().padLeft(4, '0');

    final month =
        now.month.toString().padLeft(2, '0');

    final day =
        now.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Future<void> _checkNewDay() async {
    if (prefs == null) return;

    final today = _today();

    final saved =
        prefs!.getString(dateKey);

    if (saved == null) {
      await prefs!.setString(
        dateKey,
        today,
      );

      return;
    }

    if (saved == today) {
      return;
    }

    adsToday = 0;

    await prefs!.setString(
      dateKey,
      today,
    );

    await prefs!.setInt(
      adsKey,
      0,
    );

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // TIMERIT
  // ============================================================

  void _updateTimers() {
    final now = DateTime.now().toUtc();

    Duration daily = Duration.zero;

    if (lastDaily != null) {
      final nextDaily =
          lastDaily!.add(
        const Duration(hours: 24),
      );

      if (now.isBefore(nextDaily)) {
        daily =
            nextDaily.difference(now);
      }
    }

    Duration ad = Duration.zero;

    if (lastAd != null) {
      final nextAd =
          lastAd!.add(
        const Duration(hours: 1),
      );

      if (now.isBefore(nextAd)) {
        ad =
            nextAd.difference(now);
      }
    }

    if (!mounted) return;

    setState(() {
      dailyTimer = daily;
      adTimer = ad;
    });
  }

  bool get canDaily {
    return dailyTimer == Duration.zero;
  }

  bool get canAd {
    return adsToday < 5 &&
        adTimer == Duration.zero;
  }

  // ============================================================
  // DAILY REWARD
  // ============================================================

  int get dailyReward {
    if (streak >= 7) {
      return 7;
    }

    return streak + 1;
  }

  // ============================================================
  // CAT FACT
  // ============================================================

  String get currentFact {
    if (catFacts.isEmpty) {
      return 'Stella on ihana kissa! 🐱';
    }

    final index =
        (factDay - 1) % catFacts.length;

    return catFacts[index];
  }

  // ============================================================
  // TIME FORMAT
  // ============================================================

  String _time(Duration duration) {
    final hours =
        duration.inHours
            .toString()
            .padLeft(2, '0');

    final minutes =
        (duration.inMinutes % 60)
            .toString()
            .padLeft(2, '0');

    final seconds =
        (duration.inSeconds % 60)
            .toString()
            .padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  // ============================================================
  // DAILY CLAIM
  // ============================================================

  Future<void> _claimDaily() async {
    if (!canDaily || prefs == null) {
      return;
    }

    final now =
        DateTime.now().toUtc();

    // Jos kaksi päivää tai enemmän on
    // kulunut edellisestä claimista,
    // putki alkaa alusta.
    if (lastDaily != null) {
      final hours =
          now.difference(lastDaily!).inHours;

      if (hours >= 48) {
        streak = 0;
      }
    }

    // Päivitä putki.
    if (streak < 7) {
      streak++;
    }

    final reward = dailyReward;

    stl += reward;

    lastDaily = now;

    // Seuraava kissafakta.
    factDay++;

    if (factDay < 1) {
      factDay = 1;
    }

    await prefs!.setInt(
      stlKey,
      stl,
    );

    await prefs!.setInt(
      streakKey,
      streak,
    );

    await prefs!.setInt(
      lastDailyKey,
      now.millisecondsSinceEpoch,
    );

    await prefs!.setInt(
      factKey,
      factDay,
    );

    _updateTimers();

    if (mounted) {
      setState(() {});
    }

    _showMessage(
      '🐾 Daily Claim +$reward STL!',
    );

    // Näytetään interstitial Daily Claimin jälkeen.
    _showInterstitial();
  }

  // ============================================================
  // WATCH AD +3 STL
  // ============================================================

  Future<void> _watchAd() async {
    if (showingAd) {
      return;
    }

    await _checkNewDay();

    if (adsToday >= 5) {
      _showMessage(
        'Päivän mainosraja 5/5 on täynnä.',
      );

      return;
    }

    if (!canAd) {
      _showMessage(
        'Odota ${_time(adTimer)}.',
      );

      return;
    }

    final ad = rewardedAd;

    if (ad == null) {
      _showMessage(
        'Mainos latautuu. Odota hetki.',
      );

      _loadRewardedAd();

      return;
    }

    rewardedAd = null;
    showingAd = true;

    if (mounted) {
      setState(() {});
    }

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent:
          (ad) {
        ad.dispose();

        if (mounted) {
          setState(() {
            showingAd = false;
          });
        }

        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent:
          (ad, error) {
        ad.dispose();

        if (mounted) {
          setState(() {
            showingAd = false;
          });
        }

        _showMessage(
          'Mainosta ei voitu näyttää.',
        );

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

  // ============================================================
  // +3 STL
  // ============================================================

  Future<void> _giveThreeStl() async {
    if (prefs == null) {
      return;
    }

    if (adsToday >= 5) {
      return;
    }

    final now =
        DateTime.now().toUtc();

    stl += 3;

    adsToday++;

    lastAd = now;

    await prefs!.setInt(
      stlKey,
      stl,
    );

    await prefs!.setInt(
      adsKey,
      adsToday,
    );

    await prefs!.setInt(
      lastAdKey,
      now.millisecondsSinceEpoch,
    );

    _updateTimers();

    if (mounted) {
      setState(() {});
    }

    _showMessage(
      '+3 STL! 🐱',
    );
  }

  // ============================================================
  // REWARDED AD
  // ============================================================

  void _loadRewardedAd() {
    if (loadingRewarded ||
        rewardedAd != null) {
      return;
    }

    loadingRewarded = true;

    if (mounted) {
      setState(() {});
    }

    RewardedAd.load(
      adUnitId: rewardedAdId,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          loadingRewarded = false;
          rewardedAd = ad;

          if (mounted) {
            setState(() {});
          }
        },
        onAdFailedToLoad: (error) {
          loadingRewarded = false;
          rewardedAd = null;

          if (mounted) {
            setState(() {});
          }

          Future.delayed(
            const Duration(seconds: 5),
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
  // INTERSTITIAL
  // ============================================================

  void _loadInterstitialAd() {
    if (loadingInterstitial ||
        interstitialAd != null) {
      return;
    }

    loadingInterstitial = true;

    if (mounted) {
      setState(() {});
    }

    InterstitialAd.load(
      adUnitId: interstitialAdId,
      request: const AdRequest(),
      adLoadCallback:
          InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          loadingInterstitial = false;
          interstitialAd = ad;

          if (mounted) {
            setState(() {});
          }
        },
        onAdFailedToLoad: (error) {
          loadingInterstitial = false;
          interstitialAd = null;

          if (mounted) {
            setState(() {});
          }

          Future.delayed(
            const Duration(seconds: 5),
            () {
              if (mounted) {
                _loadInterstitialAd();
              }
            },
          );
        },
      ),
    );
  }

  void _showInterstitial() {
    final ad = interstitialAd;

    if (ad == null) {
      _loadInterstitialAd();
      return;
    }

    interstitialAd = null;

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent:
          (ad) {
        ad.dispose();
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent:
          (ad, error) {
        ad.dispose();
        _loadInterstitialAd();
      },
    );

    ad.show();
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String text) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration:
              const Duration(seconds: 2),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'STELLURIINI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding:
              const EdgeInsets.all(16),
          children: [
            _stellaCard(),

            const SizedBox(height: 14),

            _balanceCard(),

            const SizedBox(height: 14),

            _dailyCard(),

            const SizedBox(height: 14),

            _adCard(),

            const SizedBox(height: 14),

            _factCard(),

            const SizedBox(height: 14),

            _statsCard(),

            const SizedBox(height: 14),

            _infoCard(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STELLA CARD
  // ============================================================

  Widget _stellaCard() {
    return Card(
      clipBehavior:
          Clip.antiAlias,
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [
            ClipOval(
              child: Image.asset(
                'stella.jpg',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder:
                    (
                      context,
                      error,
                      stackTrace,
                    ) {
                  return const CircleAvatar(
                    radius: 60,
                    child: Icon(
                      Icons.pets,
                      size: 55,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'STELLURIINI',
              style: TextStyle(
                fontSize: 30,
                fontWeight:
                    FontWeight.bold,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'STL',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              '🐱 Stella',
              style: TextStyle(
                color:
                    Color(0xFF35D0A0),
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BALANCE
  // ============================================================

  Widget _balanceCard() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'YOUR BALANCE',
              style: TextStyle(
                color: Colors.white60,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '$stl',
              style: const TextStyle(
                fontSize: 50,
                fontWeight:
                    FontWeight.bold,
                color:
                    Color(0xFF35D0A0),
              ),
            ),

            const Text(
              'STL',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DAILY CLAIM
  // ============================================================

  Widget _dailyCard() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.pets,
                  color:
                      Color(0xFF35D0A0),
                  size: 30,
                ),

                SizedBox(width: 10),

                Text(
                  'DAILY CLAIM',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              streak >= 7
                  ? '7 päivän putki on täynnä!'
                  : 'Päivä ${streak + 1} / 7',
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Palkinto: $dailyReward STL',
              style: const TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            if (!canDaily) ...[
              const Text(
                'NEXT CLAIM IN',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                _time(dailyTimer),
                textAlign:
                    TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),
            ],

            SizedBox(
              height: 58,
              child:
                  ElevatedButton.icon(
                onPressed:
                    canDaily
                        ? _claimDaily
                        : null,

                icon: const Icon(
                  Icons.pets,
                  size: 27,
                ),

                label: Text(
                  canDaily
                      ? 'DAILY CLAIM +'
                          '$dailyReward STL'
                      : 'CLAIMED',
                ),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              '📺 Daily Claim näyttää mainoksen.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WATCH AD
  // ============================================================

  Widget _adCard() {
    String buttonText;

    if (adsToday >= 5) {
      buttonText = 'DAILY LIMIT';
    } else if (!canAd) {
      buttonText =
          'WAIT ${_time(adTimer)}';
    } else if (rewardedAd == null) {
      buttonText = 'LOADING AD...';
    } else {
      buttonText = 'WATCH AD +3 STL';
    }

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.ondemand_video,
                  color:
                      Color(0xFF35D0A0),
                ),

                SizedBox(width: 10),

                Text(
                  'WATCH & EARN',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            const Text(
              'Katso mainos ja saat +3 STL.',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Today: $adsToday / 5',
              style: const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            SizedBox(
              height: 55,
              child:
                  ElevatedButton.icon(
                onPressed:
                    canAd &&
                            rewardedAd != null &&
                            !showingAd
                        ? _watchAd
                        : null,

                icon: const Icon(
                  Icons.play_arrow,
                ),

                label:
                    Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // KISSAFAKTA
  // ============================================================

  Widget _factCard() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.pets,
                  color:
                      Color(0xFF35D0A0),
                ),

                SizedBox(width: 10),

                Text(
                  'STELLAN KISSAFAKTA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              'Päivä $factDay / 365',
              style: const TextStyle(
                color:
                    Color(0xFF35D0A0),
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              currentFact,
              style: const TextStyle(
                fontSize: 17,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATS
  // ============================================================

  Widget _statsCard() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'STL',
                    style: TextStyle(
                      color:
                          Colors.white54,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '$stl',
                    style:
                        const TextStyle(
                      fontSize: 23,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Column(
                children: [
                  const Text(
                    'STREAK',
                    style: TextStyle(
                      color:
                          Colors.white54,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    streak >= 7
                        ? '7+'
                        : '$streak / 7',
                    style:
                        const TextStyle(
                      fontSize: 23,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Column(
                children: [
                  const Text(
                    'ADS',
                    style: TextStyle(
                      color:
                          Colors.white54,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '$adsToday / 5',
                    style:
                        const TextStyle(
                      fontSize: 23,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFO
  // ============================================================

  Widget _infoCard() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'STELLURIINI',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Stelluriini on Solana-verkossa '
              'oleva yhteisötokeni.',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              '🐱 Stella pitää sinulle seuraa '
              'louhinnan aikana!',
              style: TextStyle(
                color:
                    Color(0xFF35D0A0),
              ),
            ),

            if (stelluriiniMint.isNotEmpty) ...[
              const SizedBox(height: 12),

              const Text(
                'Mint Address',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 4),

              SelectableText(
                stelluriiniMint,
              ),
            ],
          ],
        ),
      ),
    );
  }
}