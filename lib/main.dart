import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      title: 'Stelluriini Miner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF35D0A0),
          brightness: Brightness.dark,
        ),
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
  // Google test rewarded ad.
  static const String rewardedAdId =
      'ca-app-pub-3940256099942544/5224354917';

  SharedPreferences? prefs;

  RewardedAd? rewardedAd;

  Timer? timer;

  int stl = 0;
  int streak = 0;
  int adsToday = 0;

  DateTime? lastDaily;
  DateTime? lastAd;

  Duration dailyTimer = Duration.zero;
  Duration adTimer = Duration.zero;

  bool loading = true;
  bool loadingAd = false;
  bool showingAd = false;

  // Estää Daily Claimin ja Watch Adin
  // käyttämästä samaa mainosta samaan aikaan.
  bool dailyClaimPending = false;

  @override
  void initState() {
    super.initState();

    loadData();

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) {
          updateTimers();
          checkNewDay();
        }
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    rewardedAd?.dispose();
    super.dispose();
  }

  // ============================================================
  // DATA
  // ============================================================

  Future<void> loadData() async {
    prefs = await SharedPreferences.getInstance();

    stl = prefs!.getInt('stl') ?? 0;
    streak = prefs!.getInt('streak') ?? 0;
    adsToday = prefs!.getInt('adsToday') ?? 0;

    final dailyMilliseconds =
        prefs!.getInt('lastDaily');

    if (dailyMilliseconds != null) {
      lastDaily =
          DateTime.fromMillisecondsSinceEpoch(
        dailyMilliseconds,
        isUtc: true,
      );
    }

    final adMilliseconds =
        prefs!.getInt('lastAd');

    if (adMilliseconds != null) {
      lastAd =
          DateTime.fromMillisecondsSinceEpoch(
        adMilliseconds,
        isUtc: true,
      );
    }

    await checkNewDay();

    if (!mounted) return;

    setState(() {
      loading = false;
    });

    updateTimers();
    loadRewardedAd();
  }

  String today() {
    final now = DateTime.now();

    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> checkNewDay() async {
    if (prefs == null) return;

    final currentDay = today();

    final savedDay =
        prefs!.getString('day');

    if (savedDay == currentDay) {
      return;
    }

    // Uusi päivä.
    adsToday = 0;

    await prefs!.setString(
      'day',
      currentDay,
    );

    await prefs!.setInt(
      'adsToday',
      0,
    );

    // Jos Daily Claim on ollut yli 48 h sitten,
    // putki alkaa alusta.
    if (lastDaily != null) {
      final difference =
          DateTime.now()
              .toUtc()
              .difference(lastDaily!);

      if (difference.inHours >= 48) {
        streak = 0;

        await prefs!.setInt(
          'streak',
          0,
        );
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // TIMERS
  // ============================================================

  void updateTimers() {
    final now =
        DateTime.now().toUtc();

    Duration daily =
        Duration.zero;

    Duration ad =
        Duration.zero;

    if (lastDaily != null) {
      final next =
          lastDaily!.add(
        const Duration(hours: 24),
      );

      if (now.isBefore(next)) {
        daily =
            next.difference(now);
      }
    }

    if (lastAd != null) {
      final next =
          lastAd!.add(
        const Duration(hours: 1),
      );

      if (now.isBefore(next)) {
        ad =
            next.difference(now);
      }
    }

    if (!mounted) return;

    setState(() {
      dailyTimer = daily;
      adTimer = ad;
    });
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
  // DAILY CLAIM + REWARDED AD
  // ============================================================

  Future<void> claimDaily() async {
    if (dailyTimer != Duration.zero) {
      return;
    }

    if (showingAd ||
        dailyClaimPending) {
      return;
    }

    final ad = rewardedAd;

    if (ad == null) {
      message(
        'Daily-mainos latautuu vielä.',
      );

      loadRewardedAd();
      return;
    }

    // Tallennetaan tämän claimin palkinto
    // ennen mainoksen avaamista.
    final reward = dailyReward;

    dailyClaimPending = true;
    showingAd = true;

    rewardedAd = null;

    if (mounted) {
      setState(() {});
    }

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent:
          (ad) {
        ad.dispose();

        showingAd = false;

        // Jos käyttäjä sulkee mainoksen
        // ennen palkinnon saamista,
        // Daily Claimia ei merkitä käytetyksi.
        if (dailyClaimPending) {
          dailyClaimPending = false;
        }

        if (mounted) {
          setState(() {});
        }

        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent:
          (ad, error) {
        ad.dispose();

        showingAd = false;
        dailyClaimPending = false;

        if (mounted) {
          setState(() {});

          message(
            'Daily-mainosta ei voitu näyttää.',
          );
        }

        loadRewardedAd();
      },
    );

    ad.show(
      onUserEarnedReward:
          (
        AdWithoutView ad,
        RewardItem rewardItem,
      ) {
        giveDailyReward(reward);
      },
    );
  }

  Future<void> giveDailyReward(
    int reward,
  ) async {
    if (!dailyClaimPending) {
      return;
    }

    dailyClaimPending = false;

    final now =
        DateTime.now().toUtc();

    // Tarkistetaan mahdollinen väliin jäänyt päivä.
    if (lastDaily != null) {
      final difference =
          now.difference(lastDaily!);

      if (difference.inHours >= 48) {
        streak = 0;
      }
    }

    stl += reward;

    if (streak < 7) {
      streak++;
    }

    lastDaily = now;

    await prefs!.setInt(
      'stl',
      stl,
    );

    await prefs!.setInt(
      'streak',
      streak,
    );

    await prefs!.setInt(
      'lastDaily',
      now.millisecondsSinceEpoch,
    );

    updateTimers();

    if (mounted) {
      setState(() {});

      message(
        'Miau! Daily Login +$reward STL 🐾',
      );
    }
  }

  // ============================================================
  // REWARDED AD
  // ============================================================

  void loadRewardedAd() {
    if (loadingAd ||
        rewardedAd != null) {
      return;
    }

    loadingAd = true;

    if (mounted) {
      setState(() {});
    }

    RewardedAd.load(
      adUnitId: rewardedAdId,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          loadingAd = false;
          rewardedAd = ad;

          if (mounted) {
            setState(() {});
          }
        },
        onAdFailedToLoad: (error) {
          loadingAd = false;
          rewardedAd = null;

          if (mounted) {
            setState(() {});
          }

          Future.delayed(
            const Duration(seconds: 5),
            () {
              if (mounted) {
                loadRewardedAd();
              }
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // WATCH AD +3 STL
  // ============================================================

  Future<void> watchAd() async {
    if (showingAd) {
      return;
    }

    if (adsToday >= 5) {
      message(
        'Päivän mainosraja on täynnä.',
      );
      return;
    }

    if (adTimer != Duration.zero) {
      message(
        'Odota ${formatTime(adTimer)}.',
      );
      return;
    }

    final ad = rewardedAd;

    if (ad == null) {
      message(
        'Mainos latautuu vielä.',
      );

      loadRewardedAd();
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

        showingAd = false;

        if (mounted) {
          setState(() {});
        }

        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent:
          (ad, error) {
        ad.dispose();

        showingAd = false;

        if (mounted) {
          setState(() {});
        }

        loadRewardedAd();
      },
    );

    ad.show(
      onUserEarnedReward:
          (
        AdWithoutView ad,
        RewardItem reward,
      ) {
        giveThreeStl();
      },
    );
  }

  Future<void> giveThreeStl() async {
    if (adsToday >= 5) {
      return;
    }

    stl += 3;
    adsToday++;

    lastAd =
        DateTime.now().toUtc();

    await prefs!.setInt(
      'stl',
      stl,
    );

    await prefs!.setInt(
      'adsToday',
      adsToday,
    );

    await prefs!.setInt(
      'lastAd',
      lastAd!.millisecondsSinceEpoch,
    );

    updateTimers();

    if (mounted) {
      setState(() {});

      message(
        'Miau! +3 STL 🐾',
      );
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String formatTime(
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

  void message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
        ),
      );
  }

  Widget stella(
    double size,
  ) {
    return ClipOval(
      child: Image.asset(
        'stella.jpg',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            color:
                const Color(0xFF35D0A0),
            child: Icon(
              Icons.pets,
              size: size * 0.5,
            ),
          );
        },
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
    if (loading) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'STELLURIINI 🐱',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(16),
        children: [
          stella(130),

          const SizedBox(
            height: 15,
          ),

          const Text(
            'STELLURIINI MINER',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight:
                  FontWeight.bold,
              color:
                  Color(0xFF35D0A0),
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          const Text(
            'Stellan kanssa 🐾',
            textAlign:
                TextAlign.center,
          ),

          const SizedBox(
            height: 20,
          ),

          // BALANCE
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(22),
              child: Column(
                children: [
                  const Text(
                    'STL BALANCE',
                    style: TextStyle(
                      color:
                          Colors.white54,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Text(
                    '$stl STL',
                    style:
                        const TextStyle(
                      fontSize: 42,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Color(
                        0xFF35D0A0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          // DAILY LOGIN
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.pets,
                        color:
                            Color(
                          0xFF35D0A0,
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'DAILY LOGIN',
                        style:
                            TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  Text(
                    streak >= 7
                        ? '🔥 7 PÄIVÄN PUTKI'
                        : '🐾 PÄIVÄ ${streak + 1} / 7',
                    style:
                        const TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Color(
                        0xFF35D0A0,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    '+$dailyReward STL',
                    style:
                        const TextStyle(
                      fontSize: 32,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  const Text(
                    'Katso ensin lyhyt mainos. '
                    'Sen jälkeen Stella antaa '
                    'päivän STL-palkinnon.',
                    textAlign:
                        TextAlign.center,
                    style:
                        TextStyle(
                      color:
                          Colors.white70,
                    ),
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  if (dailyTimer !=
                      Duration.zero) ...[
                    Text(
                      formatTime(
                        dailyTimer,
                      ),
                      style:
                          const TextStyle(
                        fontSize: 25,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),
                  ],

                  SizedBox(
                    width:
                        double.infinity,
                    height: 58,
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          dailyTimer ==
                                      Duration.zero &&
                                  !showingAd &&
                                  rewardedAd !=
                                      null
                              ? claimDaily
                              : null,
                      icon:
                          const Icon(
                        Icons.pets,
                        size: 27,
                      ),
                      label:
                          Text(
                        dailyTimer ==
                                    Duration.zero
                            ? 'WATCH AD + CLAIM +$dailyReward STL'
                            : 'TULE HUOMENNA',
                        textAlign:
                            TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          // WATCH AD +3
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.play_circle,
                        color:
                            Color(
                          0xFF35D0A0,
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'WATCH & EARN',
                        style:
                            TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  const Text(
                    'Katso mainos ja saat +3 STL.',
                    style:
                        TextStyle(
                      color:
                          Colors.white70,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Text(
                    'Tänään: $adsToday / 5',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  if (adTimer !=
                      Duration.zero) ...[
                    Text(
                      formatTime(
                        adTimer,
                      ),
                      style:
                          const TextStyle(
                        fontSize: 25,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),
                  ],

                  SizedBox(
                    width:
                        double.infinity,
                    height: 56,
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          adTimer ==
                                      Duration.zero &&
                                  adsToday < 5 &&
                                  rewardedAd !=
                                      null &&
                                  !showingAd
                              ? watchAd
                              : null,
                      icon:
                          const Icon(
                        Icons.play_arrow,
                      ),
                      label:
                          Text(
                        adsToday >= 5
                            ? 'PÄIVÄN RAJA'
                            : rewardedAd ==
                                    null
                                ? 'LADATAAN MAINOSTA...'
                                : 'KATSO MAINOS +3 STL',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          // STATS
          Card(
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
                          style:
                              TextStyle(
                            color:
                                Colors.white54,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          '$stl',
                          style:
                              const TextStyle(
                            fontSize: 22,
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
                          style:
                              TextStyle(
                            color:
                                Colors.white54,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          '$streak / 7',
                          style:
                              const TextStyle(
                            fontSize: 22,
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
                          style:
                              TextStyle(
                            color:
                                Colors.white54,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          '$adsToday / 5',
                          style:
                              const TextStyle(
                            fontSize: 22,
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
          ),
        ],
      ),
    );
  }
}