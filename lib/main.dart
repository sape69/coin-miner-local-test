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
  static const String rewardedAdId =
      'ca-app-pub-3940256099942544/5224354917';

  static const String interstitialAdId =
      'ca-app-pub-3940256099942544/1033173712';

  static const String stelluriiniMint = '';

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
  int factDay = 1;

  DateTime? lastDaily;
  DateTime? lastAd;

  Duration dailyTimer = Duration.zero;
  Duration adTimer = Duration.zero;

  bool loading = true;
  bool loadingRewarded = false;
  bool loadingInterstitial = false;
  bool showingAd = false;

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

  Future<void> _loadData() async {
    prefs = await SharedPreferences.getInstance();

    stl = prefs!.getInt(stlKey) ?? 0;
    streak = prefs!.getInt(streakKey) ?? 0;
    adsToday = prefs!.getInt(adsKey) ?? 0;
    factDay = prefs!.getInt(factKey) ?? 1;

    if (factDay < 1) {
      factDay = 1;
    }

    final dailyMilliseconds = prefs!.getInt(lastDailyKey);

    if (dailyMilliseconds != null) {
      lastDaily = DateTime.fromMillisecondsSinceEpoch(
        dailyMilliseconds,
        isUtc: true,
      );
    }

    final adMilliseconds = prefs!.getInt(lastAdKey);

    if (adMilliseconds != null) {
      lastAd = DateTime.fromMillisecondsSinceEpoch(
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

    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Future<void> _checkNewDay() async {
    if (prefs == null) return;

    final today = _today();
    final saved = prefs!.getString(dateKey);

    if (saved == null) {
      await prefs!.setString(dateKey, today);
      return;
    }

    if (saved == today) {
      return;
    }

    adsToday = 0;

    await prefs!.setString(dateKey, today);
    await prefs!.setInt(adsKey, 0);

    if (mounted) {
      setState(() {});
    }
  }

  void _updateTimers() {
    final now = DateTime.now().toUtc();

    Duration daily = Duration.zero;

    if (lastDaily != null) {
      final nextDaily = lastDaily!.add(
        const Duration(hours: 24),
      );

      if (now.isBefore(nextDaily)) {
        daily = nextDaily.difference(now);
      }
    }

    Duration ad = Duration.zero;

    if (lastAd != null) {
      final nextAd = lastAd!.add(
        const Duration(hours: 1),
      );

      if (now.isBefore(nextAd)) {
        ad = nextAd.difference(now);
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
    return adsToday < 5 && adTimer == Duration.zero;
  }

  int get dailyReward {
    if (streak >= 7) {
      return 7;
    }

    return streak + 1;
  }

  String get currentFact {
    if (catFacts.isEmpty) {
      return 'Stella on ihana kissa! 🐱';
    }

    final index = (factDay - 1) % catFacts.length;

    return catFacts[index];
  }

  String _time(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');

    final minutes = (duration.inMinutes % 60)
        .toString()
        .padLeft(2, '0');

    final seconds = (duration.inSeconds % 60)
        .toString()
        .padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  Future<void> _claimDaily() async {
    if (!canDaily || prefs == null) {
      return;
    }

    final now = DateTime.now().toUtc();

    if (lastDaily != null) {
      final hours = now.difference(lastDaily!).inHours;

      if (hours >= 48) {
        streak = 0;
      }
    }

    if (streak < 7) {
      streak++;
    }

    final reward = dailyReward;

    stl += reward;
    lastDaily = now;

    factDay++;

    if (factDay < 1) {
      factDay = 1;
    }

    await prefs!.setInt(stlKey, stl);
    await prefs!.setInt(streakKey, streak);

    await prefs!.setInt(
      lastDailyKey,
      now.millisecondsSinceEpoch,
    );

    await prefs!.setInt(factKey, factDay);

    _updateTimers();

    if (mounted) {
      setState(() {});
    }

    _showMessage(
      '🐾 Daily Claim +$reward STL!',
    );

    _showInterstitial();
  }

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
      onAdDismissedFullScreenContent: (ad) {
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
      onUserEarnedReward: (
        AdWithoutView ad,
        RewardItem reward,
      ) {
        _giveThreeStl();
      },
    );
  }

  Future<void> _giveThreeStl() async {
    if (prefs == null) {
      return;
    }

    if (adsToday >= 5) {
      return;
    }

    final now = DateTime.now().toUtc();

    stl += 3;
    adsToday++;
    lastAd = now;

    await prefs!.setInt(stlKey, stl);
    await prefs!.setInt(adsKey, adsToday);

    await prefs!.setInt(
      lastAdKey,
      now.millisecondsSinceEpoch,
    );

    _updateTimers();

    if (mounted) {
      setState(() {});
    }

    _showMessage('+3 STL! 🐱');
  }

  void _loadRewardedAd() {
    if (loadingRewarded || rewardedAd != null) {
      return;
    }

    loadingRewarded = true;

    if (mounted) {
      setState(() {});
    }

    RewardedAd.load(
      adUnitId: rewardedAdId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
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

  void _loadInterstitialAd() {
    if (loadingInterstitial || interstitialAd != null) {
      return;
    }

    loadingInterstitial = true;

    if (mounted) {
      setState(() {});
    }

    InterstitialAd.load(
      adUnitId: interstitialAdId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
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
      onAdDismissedFullScreenContent: (ad) {
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

  void _showMessage(String text) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(seconds: 2),
        ),
      );
  }

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
          padding: const EdgeInsets.all(16),
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

  Widget _stellaCard() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ClipOval(
              child: Image.asset(
                'stella.jpg',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (
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
                fontWeight: FontWeight.bold,
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
                color: Color(0xFF35D0A0),
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
                fontWeight: FontWeight.bold,
                color: Color(0xFF35D0A0),
              ),
            ),
            const Text(
              'STL',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dailyCard() {
    final int currentDay =
        streak >= 7 ? 7 : streak + 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.card_giftcard,
                  color: Color(0xFF35D0A0),
                  size: 30,
                ),
                SizedBox(width: 10),
                Text(
                  'DAILY CLAIM',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              streak >= 7
                  ? '🔥 7 päivän putki saavutettu!'
                  : 'Päivä $currentDay / 7',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: List.generate(7, (index) {
                final int day = index + 1;

                final bool completed =
                    streak >= day;

                final bool today =
                    !completed &&
                    day == currentDay;

                return Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 2,
                    ),
                    child: Container(
                      height: 82,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                          color: today || completed
                              ? const Color(0xFF35D0A0)
                              : Colors.white12,
                          width: today ? 2 : 1,
                        ),
                        color: today
                            ? const Color(0xFF35D0A0)
                                .withValues(alpha: 0.18)
                            : completed
                                ? const Color(0xFF35D0A0)
                                    .withValues(alpha: 0.10)
                                : Colors.white
                                    .withValues(alpha: 0.04),
                      ),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Text(
                            completed
                                ? '✓'
                                : today
                                    ? '🎁'
                                    : '🔒',
                            style: const TextStyle(
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Päivä $day',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  today || completed
                                      ? const Color(
                                          0xFF35D0A0,
                                        )
                                      : Colors.white54,
                            ),
                          ),
                          Text(
                            '$day STL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  FontWeight.bold,
                              color: today
                                  ? Colors.white
                                  : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(14),
                color: const Color(0xFF35D0A0)
                    .withValues(alpha: 0.10),
              ),
              child: Column(
                children: [
                  Text(
                    streak >= 7
                        ? '🔥 7+ PÄIVÄN PUTKI'
                        : '🎁 TÄMÄN PÄIVÄN PALKINTO',
                    style: const TextStyle(
                      color: Color(0xFF35D0A0),
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$dailyReward STL',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (streak >= 7)
                    const Text(
                      'Saat 7 STL joka päivä, kunnes päivä jää väliin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            if (!canDaily) ...[
              const Text(
                'NEXT CLAIM IN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _time(dailyTimer),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              height: 58,
              child: ElevatedButton.icon(
                onPressed:
                    canDaily ? _claimDaily : null,
                icon: const Icon(
                  Icons.card_giftcard,
                  size: 27,
                ),
                label: Text(
                  canDaily
                      ? 'DAILY CLAIM +$dailyReward STL'
                      : 'CLAIMED',
                ),
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              '🎁 Päivä 1 → 1 STL\n'
              '🎁 Päivä 2 → 2 STL\n'
              '🎁 Päivä 3 → 3 STL\n'
              '🎁 Päivä 4 → 4 STL\n'
              '🎁 Päivä 5 → 5 STL\n'
              '🎁 Päivä 6 → 6 STL\n'
              '🎁 Päivä 7 → 7 STL',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              '🔥 Kun 7 päivän putki on täynnä, '
              'saat 7 STL joka päivä.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF35D0A0),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              '⚠️ Jos yksi päivä jää väliin, '
              'putki alkaa uudelleen päivästä 1.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              '📺 Daily Claim näyttää mainoksen.',
              textAlign: TextAlign.center,
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

  Widget _adCard() {
    String buttonText;

    if (adsToday >= 5) {
      buttonText = 'DAILY LIMIT';
    } else if (!canAd) {
      buttonText = 'WAIT ${_time(adTimer)}';
    } else if (rewardedAd == null) {
      buttonText = 'LOADING AD...';
    } else {
      buttonText = 'WATCH AD +3 STL';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.ondemand_video,
                  color: Color(0xFF35D0A0),
                ),
                SizedBox(width: 10),
                Text(
                  'WATCH & EARN',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
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
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed:
                    canAd &&
                            rewardedAd != null &&
                            !showingAd
                        ? _watchAd
                        : null,
                icon: const Icon(
                  Icons.play_arrow,
                ),
                label: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _factCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.pets,
                  color: Color(0xFF35D0A0),
                ),
                SizedBox(width: 10),
                Text(
                  'STELLAN KISSAFAKTA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              'Päivä $factDay / 365',
              style: const TextStyle(
                color: Color(0xFF35D0A0),
                fontWeight: FontWeight.bold,
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

  Widget _statsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'STL',
                    style: TextStyle(
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$stl',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
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
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    streak >= 7
                        ? '7+'
                        : '$streak / 7',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
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
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$adsToday / 5',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
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

  Widget _infoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'STELLURIINI',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
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
                color: Color(0xFF35D0A0),
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