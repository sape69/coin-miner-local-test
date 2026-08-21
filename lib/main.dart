import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MobileAds.instance.initialize();

  runApp(const CoinMinerApp());
}

// ============================================================
// APP
// ============================================================

class CoinMinerApp extends StatelessWidget {
  const CoinMinerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'COIN MINER',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0E1118),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const StartupPage(),
    );
  }
}

// ============================================================
// STARTUP PAGE
// ============================================================

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  bool loading = true;
  String username = '';

  @override
  void initState() {
    super.initState();
    checkAccount();
  }

  Future<void> checkAccount() async {
    final prefs = await SharedPreferences.getInstance();

    final savedUsername =
        prefs.getString('username') ?? '';

    if (!mounted) return;

    if (savedUsername.trim().isEmpty) {
      setState(() {
        loading = false;
        username = '';
      });
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.amber,
          ),
        ),
      );
    }

    return const UsernamePage();
  }
}

// ============================================================
// USERNAME PAGE
// ============================================================

class UsernamePage extends StatefulWidget {
  const UsernamePage({super.key});

  @override
  State<UsernamePage> createState() => _UsernamePageState();
}

class _UsernamePageState extends State<UsernamePage> {
  final TextEditingController controller =
      TextEditingController();

  bool saving = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> continueToGame() async {
    final name = controller.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a username.',
          ),
        ),
      );
      return;
    }

    if (saving) return;

    setState(() {
      saving = true;
    });

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      'username',
      name,
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const HomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amber.withValues(
                      alpha: 0.12,
                    ),
                    border: Border.all(
                      color: Colors.amber,
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '₿',
                      style: TextStyle(
                        fontSize: 75,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                const Text(
                  'COIN MINER',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Welcome!',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Choose your username to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                  ),
                ),

                const SizedBox(height: 30),

                TextField(
                  controller: controller,
                  maxLength: 20,
                  textInputAction:
                      TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'Enter your name',
                    prefixIcon: Icon(
                      Icons.person,
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed:
                        saving ? null : continueToGame,
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.amber,
                      foregroundColor:
                          Colors.black,
                      disabledBackgroundColor:
                          Colors.grey.shade800,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          30,
                        ),
                      ),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'CONTINUE',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HOME PAGE
// ============================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double balance = 0.0;

  int streak = 0;

  String username = '';

  DateTime? lastClaimTime;

  DateTime? lastBonusTime;

  int bonusCountToday = 0;

  String bonusDay = '';

  bool loading = true;

  Timer? timer;

  RewardedAd? rewardedAd;

  bool rewardedAdReady = false;

  bool showingAd = false;

  static const String rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  @override
  void initState() {
    super.initState();

    loadData();

    loadRewardedAd();

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  // ==========================================================
  // LOAD DATA
  // ==========================================================

  Future<void> loadData() async {
    final prefs =
        await SharedPreferences.getInstance();

    final savedBalance =
        prefs.getDouble('balance') ?? 0.0;

    final savedStreak =
        prefs.getInt('streak') ?? 0;

    final savedUsername =
        prefs.getString('username') ?? '';

    final claimMs =
        prefs.getInt('lastClaimTime');

    final bonusMs =
        prefs.getInt('lastBonusTime');

    final savedBonusCount =
        prefs.getInt('bonusCountToday') ?? 0;

    final savedBonusDay =
        prefs.getString('bonusDay') ?? '';

    DateTime? claimTime;

    if (claimMs != null) {
      claimTime =
          DateTime.fromMillisecondsSinceEpoch(
        claimMs,
      );
    }

    DateTime? bonusTime;

    if (bonusMs != null) {
      bonusTime =
          DateTime.fromMillisecondsSinceEpoch(
        bonusMs,
      );
    }

    final today =
        dateKey(DateTime.now());

    int bonusCount = savedBonusCount;

    if (savedBonusDay != today) {
      bonusCount = 0;
    }

    if (!mounted) return;

    setState(() {
      balance = savedBalance;
      streak = savedStreak;
      username = savedUsername;

      lastClaimTime = claimTime;
      lastBonusTime = bonusTime;

      bonusCountToday = bonusCount;
      bonusDay = today;

      loading = false;
    });
  }

  // ==========================================================
  // SAVE
  // ==========================================================

  Future<void> saveData() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setDouble(
      'balance',
      balance,
    );

    await prefs.setInt(
      'streak',
      streak,
    );

    await prefs.setString(
      'username',
      username,
    );

    if (lastClaimTime != null) {
      await prefs.setInt(
        'lastClaimTime',
        lastClaimTime!
            .millisecondsSinceEpoch,
      );
    }

    if (lastBonusTime != null) {
      await prefs.setInt(
        'lastBonusTime',
        lastBonusTime!
            .millisecondsSinceEpoch,
      );
    }

    await prefs.setInt(
      'bonusCountToday',
      bonusCountToday,
    );

    await prefs.setString(
      'bonusDay',
      bonusDay,
    );
  }

  // ==========================================================
  // DATE
  // ==========================================================

  String dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // ==========================================================
  // CLAIM
  // ==========================================================

  bool get canClaim {
    if (lastClaimTime == null) {
      return true;
    }

    return DateTime.now()
            .difference(lastClaimTime!) >=
        const Duration(hours: 24);
  }

  Duration get claimRemaining {
    if (lastClaimTime == null) {
      return Duration.zero;
    }

    final next =
        lastClaimTime!.add(
      const Duration(hours: 24),
    );

    final remaining =
        next.difference(DateTime.now());

    if (remaining.isNegative) {
      return Duration.zero;
    }

    return remaining;
  }

  // ==========================================================
  // BONUS
  // ==========================================================

  void checkBonusDay() {
    final today =
        dateKey(DateTime.now());

    if (bonusDay != today) {
      bonusDay = today;
      bonusCountToday = 0;
      lastBonusTime = null;
    }
  }

  bool get canBonus {
    checkBonusDay();

    if (bonusCountToday >= 5) {
      return false;
    }

    if (lastBonusTime == null) {
      return true;
    }

    return DateTime.now()
            .difference(lastBonusTime!) >=
        const Duration(hours: 1);
  }

  Duration get bonusRemaining {
    if (lastBonusTime == null) {
      return Duration.zero;
    }

    final next =
        lastBonusTime!.add(
      const Duration(hours: 1),
    );

    final remaining =
        next.difference(DateTime.now());

    if (remaining.isNegative) {
      return Duration.zero;
    }

    return remaining;
  }

  // ==========================================================
  // CLAIM 10
  // ==========================================================

  Future<void> claimCoins() async {
    if (!canClaim) {
      showMessage(
        'Next claim in ${formatDuration(claimRemaining)}',
        Icons.timer,
      );
      return;
    }

    final now = DateTime.now();

    if (lastClaimTime == null) {
      streak = 1;
    } else {
      final yesterday =
          dateKey(
        now.subtract(
          const Duration(days: 1),
        ),
      );

      if (dateKey(lastClaimTime!) ==
          yesterday) {
        streak++;
      } else {
        streak = 1;
      }
    }

    balance += 10;

    lastClaimTime = now;

    await saveData();

    if (!mounted) return;

    setState(() {});

    showMessage(
      '+10 COINS claimed!',
      Icons.bolt,
    );

    await Future.delayed(
      const Duration(milliseconds: 400),
    );

    if (mounted) {
      showRewardedAd(
        RewardType.afterClaim,
      );
    }
  }

  // ==========================================================
  // LOAD AD
  // ==========================================================

  void loadRewardedAd() {
    if (rewardedAd != null ||
        rewardedAdReady) {
      return;
    }

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded:
            (RewardedAd ad) {
          rewardedAd = ad;

          rewardedAdReady = true;

          ad.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent:
                (RewardedAd ad) {
              ad.dispose();

              rewardedAd = null;
              rewardedAdReady = false;
              showingAd = false;

              loadRewardedAd();

              if (mounted) {
                setState(() {});
              }
            },
            onAdFailedToShowFullScreenContent:
                (RewardedAd ad,
                    AdError error) {
              ad.dispose();

              rewardedAd = null;
              rewardedAdReady = false;
              showingAd = false;

              loadRewardedAd();

              if (mounted) {
                setState(() {});
              }
            },
          );

          if (mounted) {
            setState(() {});
          }
        },
        onAdFailedToLoad:
            (LoadAdError error) {
          rewardedAd = null;
          rewardedAdReady = false;

          Future.delayed(
            const Duration(seconds: 10),
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

  // ==========================================================
  // SHOW AD
  // ==========================================================

  void showRewardedAd(
    RewardType type,
  ) {
    if (showingAd) {
      return;
    }

    if (!rewardedAdReady ||
        rewardedAd == null) {
      showMessage(
        'Ad is loading. Try again soon.',
        Icons.hourglass_top,
      );

      loadRewardedAd();
      return;
    }

    final ad = rewardedAd!;

    rewardedAd = null;
    rewardedAdReady = false;
    showingAd = true;

    ad.show(
      onUserEarnedReward:
          (AdWithoutView ad,
              RewardItem reward) async {
        if (type ==
            RewardType.hourlyBonus) {
          await giveBonus();
        }
      },
    );
  }

  // ==========================================================
  // +5 BONUS
  // ==========================================================

  Future<void> watchBonus() async {
    checkBonusDay();

    if (bonusCountToday >= 5) {
      showMessage(
        'You have reached 5/5 bonuses today.',
        Icons.lock,
      );
      return;
    }

    if (!canBonus) {
      showMessage(
        'Next bonus in ${formatDuration(bonusRemaining)}',
        Icons.timer,
      );
      return;
    }

    showRewardedAd(
      RewardType.hourlyBonus,
    );
  }

  // ==========================================================
  // GIVE BONUS
  // ==========================================================

  Future<void> giveBonus() async {
    checkBonusDay();

    if (bonusCountToday >= 5) {
      return;
    }

    balance += 5;

    bonusCountToday++;

    lastBonusTime = DateTime.now();

    await saveData();

    if (!mounted) return;

    setState(() {});

    showMessage(
      '+5 COINS!',
      Icons.card_giftcard,
    );
  }

  // ==========================================================
  // FORMAT TIME
  // ==========================================================

  String formatDuration(
    Duration d,
  ) {
    if (d.isNegative ||
        d == Duration.zero) {
      return '00:00:00';
    }

    final h = d.inHours;

    final m =
        d.inMinutes.remainder(60);

    final s =
        d.inSeconds.remainder(60);

    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void showMessage(
    String text,
    IconData icon,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.amber,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // RESET
  // ==========================================================

  Future<void> resetAccount() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.clear();

    if (!mounted) return;

    Navigator.of(context)
        .pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            const UsernamePage(),
      ),
      (route) => false,
    );
  }

  // ==========================================================
  // RESET CONFIRMATION
  // ==========================================================

  Future<void> confirmReset() async {
    final result =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Reset account?',
          ),
          content: const Text(
            'All local test data will be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
                  const Text('RESET'),
            ),
          ],
        );
      },
    );

    if (result == true &&
        mounted) {
      await resetAccount();
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(
            color: Colors.amber,
          ),
        ),
      );
    }

    checkBonusDay();

    final claimText =
        canClaim
            ? 'CLAIM 10 COINS'
            : 'NEXT CLAIM\n${formatDuration(claimRemaining)}';

    final bonusText =
        canBonus
            ? 'WATCH & EARN +5'
            : bonusCountToday >= 5
                ? '5 / 5 COMPLETED'
                : 'WAIT ${formatDuration(bonusRemaining)}';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'COIN MINER',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reset') {
                confirmReset();
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: 'reset',
                  child: Row(
                    children: [
                      Icon(
                        Icons.refresh,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Reset test account',
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),

      body: SafeArea(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(
                height: 10,
              ),

              // USER
              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(16),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFF1B1F29,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor:
                          Colors.amber,
                      child: Icon(
                        Icons.person,
                        color:
                            Colors.black,
                      ),
                    ),
                    const SizedBox(
                      width: 14,
                    ),
                    Expanded(
                      child: Text(
                        username,
                        style:
                            const TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              // COIN
              Container(
                width: 125,
                height: 125,
                decoration:
                    BoxDecoration(
                  shape:
                      BoxShape.circle,
                  color: Colors.amber
                      .withValues(
                    alpha: 0.12,
                  ),
                  border:
                      Border.all(
                    color:
                        Colors.amber,
                    width: 2,
                  ),
                ),
                child:
                    const Center(
                  child: Text(
                    '₿',
                    style:
                        TextStyle(
                      fontSize: 82,
                      color:
                          Colors.amber,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              const Text(
                'YOUR BALANCE',
                style:
                    TextStyle(
                  fontSize: 20,
                  color:
                      Colors.white70,
                ),
              ),

              Text(
                balance
                    .toStringAsFixed(
                  0,
                ),
                style:
                    const TextStyle(
                  fontSize: 58,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Colors.amber,
                ),
              ),

              const Text(
                'COINS',
                style:
                    TextStyle(
                  fontSize: 20,
                  color:
                      Colors.white70,
                  letterSpacing:
                      2,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // STREAK
              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(
                  18,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFF1B1F29,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons
                          .local_fire_department,
                      color:
                          Colors.orange,
                      size: 30,
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    const Expanded(
                      child: Text(
                        'MINING STREAK',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '$streak DAYS',
                      style:
                          const TextStyle(
                        color:
                            Colors.orange,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // DAILY CLAIM
              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(
                  20,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFF1C202A,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    22,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.bolt,
                      color:
                          Colors.amber,
                      size: 45,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const Text(
                      'DAILY CLAIM',
                      style:
                          TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    const Text(
                      '10 coins every 24 hours',
                      style:
                          TextStyle(
                        color:
                            Colors.white60,
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    SizedBox(
                      width:
                          double.infinity,
                      height: 60,
                      child:
                          ElevatedButton(
                        onPressed:
                            canClaim &&
                                    !showingAd
                                ? claimCoins
                                : null,
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.amber,
                          foregroundColor:
                              Colors.black,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              30,
                            ),
                          ),
                        ),
                        child: Text(
                          claimText,
                          textAlign:
                              TextAlign.center,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // +5 BONUS
              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(
                  20,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFF1C202A,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    22,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons
                          .ondemand_video,
                      color:
                          Colors.amber,
                      size: 45,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const Text(
                      'WATCH AD +5 COINS',
                      style:
                          TextStyle(
                        fontSize: 19,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    const Text(
                      'Once every hour, maximum 5 times per day.',
                      textAlign:
                          TextAlign.center,
                      style:
                          TextStyle(
                        color:
                            Colors.white60,
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Text(
                      '$bonusCountToday / 5 TODAY',
                      style:
                          const TextStyle(
                        color:
                            Colors.amber,
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    SizedBox(
                      width:
                          double.infinity,
                      height: 52,
                      child:
                          OutlinedButton(
                        onPressed:
                            canBonus &&
                                    !showingAd
                                ? watchBonus
                                : null,
                        style:
                            OutlinedButton.styleFrom(
                          foregroundColor:
                              Colors.amber,
                          side:
                              const BorderSide(
                            color:
                                Colors.amber,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              28,
                            ),
                          ),
                        ),
                        child: Text(
                          bonusText,
                          textAlign:
                              TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // STATS
              Row(
                children: [
                  Expanded(
                    child: statCard(
                      Icons.bolt,
                      'DAILY',
                      '+10',
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: statCard(
                      Icons
                          .card_giftcard,
                      'AD',
                      '+5',
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 25,
              ),

              const Text(
                'COIN MINER v4',
                style:
                    TextStyle(
                  color:
                      Colors.white30,
                  fontSize: 12,
                ),
              ),

              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // STAT CARD
  // ==========================================================

  Widget statCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFF1B1F29),
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.amber,
            size: 28,
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            title,
            style:
                const TextStyle(
              color:
                  Colors.white54,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            value,
            style:
                const TextStyle(
              color:
                  Colors.amber,
              fontSize: 22,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const Text(
            'COINS',
            style:
                TextStyle(
              color:
                  Colors.white38,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();

    rewardedAd?.dispose();

    super.dispose();
  }
}

// ============================================================
// REWARD TYPE
// ============================================================

enum RewardType {
  afterClaim,
  hourlyBonus,
}