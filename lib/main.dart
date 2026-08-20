import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MobileAds.instance.initialize();

  runApp(const CoinMinerApp());
}

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
  double balance = 0.0;
  int streak = 0;

  String username = '';
  String lastMineDate = '';

  bool minedToday = false;
  bool loading = true;

  RewardedAd? rewardedAd;
  bool rewardedAdReady = false;

  Timer? countdownTimer;
  Duration timeUntilNextClaim = Duration.zero;

  static const String rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  @override
  void initState() {
    super.initState();

    loadData();
    loadRewardedAd();

    countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        updateCountdown();
      },
    );
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedBalance =
        prefs.getDouble('balance') ?? 0.0;

    final savedStreak =
        prefs.getInt('streak') ?? 0;

    final savedDate =
        prefs.getString('lastMineDate') ?? '';

    final savedUsername =
        prefs.getString('username') ?? '';

    if (!mounted) return;

    setState(() {
      balance = savedBalance;
      streak = savedStreak;
      lastMineDate = savedDate;
      username = savedUsername;

      minedToday =
          savedDate == dateKey(DateTime.now());

      loading = false;
    });

    updateCountdown();

    if (username.trim().isEmpty) {
      await showUsernameDialog();
    }
  }

  // ============================================================
  // SAVE DATA
  // ============================================================

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
      'lastMineDate',
      lastMineDate,
    );

    await prefs.setString(
      'username',
      username,
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  String dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // 24 H COUNTDOWN
  // ============================================================

  void updateCountdown() {
    if (!mounted) return;

    if (!minedToday) {
      if (timeUntilNextClaim != Duration.zero) {
        setState(() {
          timeUntilNextClaim = Duration.zero;
        });
      }
      return;
    }

    final now = DateTime.now();

    final nextClaim =
        DateTime(
          now.year,
          now.month,
          now.day,
        ).add(
          const Duration(days: 1),
        );

    final remaining =
        nextClaim.difference(now);

    setState(() {
      timeUntilNextClaim =
          remaining.isNegative
              ? Duration.zero
              : remaining;
    });
  }

  String formatDuration(Duration duration) {
    final hours =
        duration.inHours
            .toString()
            .padLeft(2, '0');

    final minutes =
        duration.inMinutes
            .remainder(60)
            .toString()
            .padLeft(2, '0');

    final seconds =
        duration.inSeconds
            .remainder(60)
            .toString()
            .padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  // ============================================================
  // USERNAME
  // ============================================================

  Future<void> showUsernameDialog() async {
    if (!mounted) return;

    final controller =
        TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Welcome to COIN MINER!',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose your username.',
              ),
              const SizedBox(height: 18),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 20,
                decoration:
                    const InputDecoration(
                  labelText: 'Username',
                  hintText: 'Enter your name',
                  prefixIcon:
                      Icon(Icons.person),
                  border:
                      OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final name =
                    controller.text.trim();

                if (name.isEmpty) {
                  return;
                }

                username = name;

                await saveData();

                if (!dialogContext.mounted) {
                  return;
                }

                Navigator.of(
                  dialogContext,
                ).pop();

                if (mounted) {
                  setState(() {});
                }
              },
              child: const Text(
                'CONTINUE',
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  // ============================================================
  // DAILY CLAIM
  // ============================================================

  Future<void> mineCoins() async {
    if (minedToday) {
      showMessage(
        'You have already claimed today.',
        Icons.lock_clock,
      );
      return;
    }

    final now = DateTime.now();

    final yesterday =
        now.subtract(
      const Duration(days: 1),
    );

    final yesterdayKey =
        dateKey(yesterday);

    if (lastMineDate == yesterdayKey) {
      streak++;
    } else {
      streak = 1;
    }

    const double dailyReward = 10.0;

    balance += dailyReward;

    lastMineDate = dateKey(now);

    minedToday = true;

    await saveData();

    if (!mounted) return;

    setState(() {});

    updateCountdown();

    showMessage(
      '+10 COINS claimed!',
      Icons.bolt,
    );
  }

  // ============================================================
  // REWARDED AD
  // ============================================================

  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          rewardedAd = ad;
          rewardedAdReady = true;

          ad.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent:
                (RewardedAd ad) {
              ad.dispose();

              rewardedAd = null;
              rewardedAdReady = false;

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

          if (mounted) {
            setState(() {});
          }

          Future.delayed(
            const Duration(seconds: 5),
            () {
              if (mounted &&
                  !rewardedAdReady) {
                loadRewardedAd();
              }
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // SHOW REWARDED AD
  // ============================================================

  void showRewardedAd() {
    if (!rewardedAdReady ||
        rewardedAd == null) {
      showMessage(
        'Ad is loading. Try again in a moment.',
        Icons.hourglass_top,
      );

      loadRewardedAd();

      return;
    }

    final ad = rewardedAd!;

    rewardedAd = null;
    rewardedAdReady = false;

    if (mounted) {
      setState(() {});
    }

    ad.show(
      onUserEarnedReward:
          (AdWithoutView ad,
              RewardItem reward) async {
        const double bonus = 25.0;

        balance += bonus;

        await saveData();

        if (!mounted) return;

        setState(() {});

        showMessage(
          '+25 COINS reward!',
          Icons.card_giftcard,
        );
      },
    );
  }

  // ============================================================
  // RESET ACCOUNT
  // ============================================================

  Future<void> resetAccount() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove('balance');
    await prefs.remove('streak');
    await prefs.remove('lastMineDate');
    await prefs.remove('username');

    if (!mounted) return;

    setState(() {
      balance = 0.0;
      streak = 0;
      lastMineDate = '';
      username = '';
      minedToday = false;
      timeUntilNextClaim =
          Duration.zero;
    });

    showMessage(
      'Test account reset.',
      Icons.refresh,
    );

    await showUsernameDialog();
  }

  // ============================================================
  // MESSAGE
  // ============================================================

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

  // ============================================================
  // UI
  // ============================================================

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

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'COIN MINER',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor:
            const Color(0xFF17131C),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reset') {
                showResetDialog();
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: 'reset',
                  child: Row(
                    children: [
                      Icon(Icons.refresh),
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
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 15),

              // ==================================================
              // USER
              // ==================================================

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFF1B1F29),
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
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const Text(
                            'MINER',
                            style: TextStyle(
                              color:
                                  Colors.white54,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(
                            height: 3,
                          ),
                          Text(
                            username,
                            style:
                                const TextStyle(
                              fontSize: 20,
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

              const SizedBox(height: 25),

              // ==================================================
              // COIN
              // ==================================================

              Container(
                width: 125,
                height: 125,
                decoration:
                    BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber
                      .withValues(
                    alpha: 0.12,
                  ),
                  border: Border.all(
                    color: Colors.amber
                        .withValues(
                      alpha: 0.35,
                    ),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Text(
                    '₿',
                    style: TextStyle(
                      fontSize: 82,
                      color: Colors.amber,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'YOUR BALANCE',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white70,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                balance.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 58,
                  fontWeight:
                      FontWeight.bold,
                  color: Colors.amber,
                ),
              ),

              const Text(
                'COINS',
                style: TextStyle(
                  fontSize: 21,
                  color: Colors.white70,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 25),

              // ==================================================
              // STREAK
              // ==================================================

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 20,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFF1B1F29),
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
                      color: Colors.orange,
                      size: 30,
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    const Expanded(
                      child: Text(
                        'MINING STREAK',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      '$streak DAYS',
                      style:
                          const TextStyle(
                        color: Colors.orange,
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ==================================================
              // CLAIM BUTTON
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 64,
                child:
                    ElevatedButton.icon(
                  onPressed:
                      minedToday
                          ? null
                          : mineCoins,
                  icon: Icon(
                    minedToday
                        ? Icons.check_circle
                        : Icons.bolt,
                    size: 28,
                  ),
                  label: Text(
                    minedToday
                        ? 'CLAIMED TODAY'
                        : 'CLAIM +10 COINS',
                    style:
                        const TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.amber,
                    foregroundColor:
                        Colors.black,
                    disabledBackgroundColor:
                        const Color(
                      0xFF27232A,
                    ),
                    disabledForegroundColor:
                        Colors.white54,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        32,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ==================================================
              // COUNTDOWN
              // ==================================================

              if (minedToday) ...[
                const Text(
                  'NEXT CLAIM IN',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  formatDuration(
                    timeUntilNextClaim,
                  ),
                  style:
                      const TextStyle(
                    color: Colors.amber,
                    fontSize: 30,
                    fontWeight:
                        FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  '24-hour daily claim timer',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ] else
                const Text(
                  'Claim your daily +10 coins.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white60,
                  ),
                ),

              const SizedBox(height: 30),

              // ==================================================
              // REWARDED AD
              // ==================================================

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(22),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFF1C202A),
                  borderRadius:
                      BorderRadius.circular(
                    22,
                  ),
                  border: Border.all(
                    color: Colors.white
                        .withValues(
                      alpha: 0.05,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.ondemand_video,
                      color: Colors.amber,
                      size: 48,
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    const Text(
                      'WATCH AD TO EARN MORE',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    const Text(
                      'Watch a short video and receive +25 coins.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color:
                            Colors.white60,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    SizedBox(
                      width:
                          double.infinity,
                      height: 52,
                      child:
                          OutlinedButton.icon(
                        onPressed:
                            showRewardedAd,
                        icon:
                            const Icon(
                          Icons.play_arrow,
                        ),
                        label: Text(
                          rewardedAdReady
                              ? 'WATCH & EARN +25'
                              : 'LOADING AD...',
                        ),
                        style:
                            OutlinedButton
                                .styleFrom(
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
                                BorderRadius
                                    .circular(
                              28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ==================================================
              // STATS
              // ==================================================

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
                      Icons.card_giftcard,
                      'AD BONUS',
                      '+25',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // ==================================================
              // INFO
              // ==================================================

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(18),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFF171B24),
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.white54,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'COIN MINER is a reward simulation app. '
                      'The coins shown here are virtual in-app '
                      'points and are not real cryptocurrency.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color:
                            Colors.white54,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'COIN MINER v2',
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

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
            BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.amber,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style:
                const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style:
                const TextStyle(
              color: Colors.amber,
              fontSize: 22,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const Text(
            'COINS',
            style:
                TextStyle(
              color: Colors.white38,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESET DIALOG
  // ============================================================

  void showResetDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Reset account?',
          ),
          content: const Text(
            'This will delete the local test balance, '
            'mining streak and username.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text(
                'CANCEL',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();

                resetAccount();
              },
              child: const Text(
                'RESET',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    countdownTimer?.cancel();
    rewardedAd?.dispose();

    super.dispose();
  }
}
