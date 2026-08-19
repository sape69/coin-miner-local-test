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
  // ============================================================
  // ACCOUNT DATA
  // ============================================================

  double balance = 0.0;
  int streak = 0;

  String lastMineDate = '';
  String username = '';

  int totalDailyClaims = 0;
  int totalAdRewards = 0;

  // ============================================================
  // 24 H TIMER
  // ============================================================

  int? lastMineAtMillis;

  Duration timeUntilNextMine = Duration.zero;

  Timer? countdownTimer;

  bool minedToday = false;
  bool loading = true;

  // ============================================================
  // REWARDED AD
  // ============================================================

  RewardedAd? rewardedAd;
  bool rewardedAdReady = false;

  // Google official TEST rewarded ad.
  static const String rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    loadData();
    loadRewardedAd();
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

    final savedDailyClaims =
        prefs.getInt('totalDailyClaims') ?? 0;

    final savedAdRewards =
        prefs.getInt('totalAdRewards') ?? 0;

    final savedLastMineAt =
        prefs.getInt('lastMineAtMillis');

    if (!mounted) return;

    setState(() {
      balance = savedBalance;
      streak = savedStreak;
      lastMineDate = savedDate;
      username = savedUsername;

      totalDailyClaims = savedDailyClaims;
      totalAdRewards = savedAdRewards;

      lastMineAtMillis = savedLastMineAt;

      loading = false;
    });

    // ------------------------------------------------------------
    // OLD VERSION COMPATIBILITY
    // ------------------------------------------------------------
    //
    // Jos vanhassa versiossa on lastMineDate mutta ei vielä
    // lastMineAtMillis-arvoa, käytetään tämän päivän alkua
    // vain kerran. Uusi järjestelmä tallentaa jatkossa tarkan ajan.
    //

    if (lastMineAtMillis == null &&
        lastMineDate.isNotEmpty) {
      final now = DateTime.now();

      final oldDate = DateTime(
        now.year,
        now.month,
        now.day,
      );

      if (lastMineDate == dateKey(now)) {
        lastMineAtMillis =
            oldDate.millisecondsSinceEpoch;

        await prefs.setInt(
          'lastMineAtMillis',
          lastMineAtMillis!,
        );
      }
    }

    updateMineTimer();

    startCountdownTimer();

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

    await prefs.setInt(
      'totalDailyClaims',
      totalDailyClaims,
    );

    await prefs.setInt(
      'totalAdRewards',
      totalAdRewards,
    );

    if (lastMineAtMillis != null) {
      await prefs.setInt(
        'lastMineAtMillis',
        lastMineAtMillis!,
      );
    } else {
      await prefs.remove(
        'lastMineAtMillis',
      );
    }
  }

  // ============================================================
  // USERNAME
  // ============================================================

  Future<void> showUsernameDialog() async {
    final controller = TextEditingController();

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
                textCapitalization:
                    TextCapitalization.words,
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

                if (dialogContext.mounted) {
                  Navigator.of(
                    dialogContext,
                  ).pop();
                }

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

    // ------------------------------------------------------------
    // IMPORTANT:
    // Do NOT immediately call controller.dispose() here.
    //
    // This avoids the Flutter '_dependents.isEmpty' assertion
    // that appeared on your phone.
    // ------------------------------------------------------------
  }

  // ============================================================
  // DATE KEY
  // ============================================================

  String dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // 24 H TIMER
  // ============================================================

  void startCountdownTimer() {
    countdownTimer?.cancel();

    countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        updateMineTimer();
      },
    );
  }

  void updateMineTimer() {
    if (lastMineAtMillis == null) {
      if (mounted) {
        setState(() {
          minedToday = false;
          timeUntilNextMine = Duration.zero;
        });
      }

      return;
    }

    final lastMine =
        DateTime.fromMillisecondsSinceEpoch(
      lastMineAtMillis!,
    );

    final nextMine =
        lastMine.add(const Duration(hours: 24));

    final now = DateTime.now();

    final remaining =
        nextMine.difference(now);

    if (remaining <= Duration.zero) {
      if (mounted) {
        setState(() {
          minedToday = false;
          timeUntilNextMine =
              Duration.zero;
        });
      }

      return;
    }

    if (mounted) {
      setState(() {
        minedToday = true;
        timeUntilNextMine = remaining;
      });
    }
  }

  // ============================================================
  // TIMER TEXT
  // ============================================================

  String timerText() {
    if (!minedToday ||
        timeUntilNextMine <= Duration.zero) {
      return 'READY TO CLAIM';
    }

    final hours =
        timeUntilNextMine.inHours
            .toString()
            .padLeft(2, '0');

    final minutes =
        (timeUntilNextMine.inMinutes % 60)
            .toString()
            .padLeft(2, '0');

    final seconds =
        (timeUntilNextMine.inSeconds % 60)
            .toString()
            .padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  // ============================================================
  // MINE / CLAIM COINS
  // ============================================================

  Future<void> mineCoins() async {
    updateMineTimer();

    if (minedToday) {
      showMessage(
        'Next claim in ${timerText()}',
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

    // ------------------------------------------------------------
    // STREAK
    // ------------------------------------------------------------

    if (lastMineDate == yesterdayKey) {
      streak++;
    } else {
      streak = 1;
    }

    // ------------------------------------------------------------
    // DAILY REWARD
    // ------------------------------------------------------------

    const double dailyReward = 10.0;

    balance += dailyReward;

    totalDailyClaims++;

    // ------------------------------------------------------------
    // SAVE EXACT CLAIM TIME
    // ------------------------------------------------------------

    lastMineAtMillis =
        now.millisecondsSinceEpoch;

    lastMineDate =
        dateKey(now);

    minedToday = true;

    timeUntilNextMine =
        const Duration(hours: 24);

    await saveData();

    if (!mounted) return;

    setState(() {});

    showMessage(
      '+10 COINS claimed!',
      Icons.bolt,
    );
  }

  // ============================================================
  // LOAD REWARDED AD
  // ============================================================

  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (
          RewardedAd ad,
        ) {
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
                (
              RewardedAd ad,
              AdError error,
            ) {
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

    ad.show(
      onUserEarnedReward:
          (
        AdWithoutView ad,
        RewardItem reward,
      ) async {
        const double bonus = 25.0;

        balance += bonus;

        totalAdRewards++;

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
    await prefs.remove('totalDailyClaims');
    await prefs.remove('totalAdRewards');
    await prefs.remove('lastMineAtMillis');

    if (!mounted) return;

    setState(() {
      balance = 0.0;
      streak = 0;

      lastMineDate = '';
      username = '';

      totalDailyClaims = 0;
      totalAdRewards = 0;

      lastMineAtMillis = null;

      minedToday = false;

      timeUntilNextMine =
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
  Widget build(
    BuildContext context,
  ) {
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
            fontWeight:
                FontWeight.bold,
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

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ==================================================
              // USERNAME
              // ==================================================

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
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
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const Text(
                            'MINER',
                            style:
                                TextStyle(
                              color:
                                  Colors.white54,
                              fontSize: 12,
                              letterSpacing:
                                  1,
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

              const SizedBox(
                height: 25,
              ),

              // ==================================================
              // COIN ICON
              // ==================================================

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
                    color: Colors.amber
                        .withValues(
                      alpha: 0.35,
                    ),
                    width: 2,
                  ),
                ),
                child:
                    const Center(
                  child: Text(
                    '₿',
                    style: TextStyle(
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
                height: 30,
              ),

              // ==================================================
              // BALANCE
              // ==================================================

              const Text(
                'YOUR BALANCE',
                style: TextStyle(
                  fontSize: 20,
                  color:
                      Colors.white70,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                balance
                    .toStringAsFixed(
                  1,
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
                style: TextStyle(
                  fontSize: 21,
                  color:
                      Colors.white70,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              // ==================================================
              // STREAK
              // ==================================================

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 15,
                  horizontal: 20,
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
                          fontSize: 16,
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
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              // ==================================================
              // 24 H TIMER CARD
              // ==================================================

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
                    0xFF171C27,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    22,
                  ),
                  border:
                      Border.all(
                    color: Colors.amber
                        .withValues(
                      alpha: 0.15,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color:
                          Colors.amber,
                      size: 42,
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    const Text(
                      'NEXT CLAIM',
                      style:
                          TextStyle(
                        color:
                            Colors.white60,
                        fontSize: 14,
                        letterSpacing:
                            1.5,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      timerText(),
                      style:
                          TextStyle(
                        color: minedToday
                            ? Colors.orange
                            : Colors.amber,
                        fontSize: 34,
                        fontWeight:
                            FontWeight.bold,
                        letterSpacing:
                            2,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      minedToday
                          ? '24-hour cooldown'
                          : 'You can claim now!',
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color:
                            Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              // ==================================================
              // CLAIM BUTTON
              // ==================================================

              SizedBox(
                width:
                    double.infinity,
                height: 64,
                child:
                    ElevatedButton.icon(
                  onPressed:
                      minedToday
                          ? null
                          : mineCoins,
                  icon: Icon(
                    minedToday
                        ? Icons
                            .check_circle
                        : Icons.bolt,
                    size: 28,
                  ),
                  label: Text(
                    minedToday
                        ? 'CLAIMED'
                        : 'CLAIM +10 COINS',
                    style:
                        const TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  style:
                      ElevatedButton
                          .styleFrom(
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
                          BorderRadius
                              .circular(
                        32,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              Text(
                minedToday
                    ? 'Come back when the 24 h timer reaches 00:00:00.'
                    : 'Claim your daily +10 COINS.',
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize: 16,
                  color:
                      Colors.white60,
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              // ==================================================
              // REWARDED AD
              // ==================================================

              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(
                  22,
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
                  border:
                      Border.all(
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
                      color:
                          Colors.amber,
                      size: 48,
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    const Text(
                      'WATCH AD TO EARN MORE',
                      textAlign:
                          TextAlign.center,
                      style:
                          TextStyle(
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
                      style:
                          TextStyle(
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
                          OutlinedButton
                              .icon(
                        onPressed:
                            showRewardedAd,
                        icon:
                            const Icon(
                          Icons
                              .play_arrow,
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

              const SizedBox(
                height: 30,
              ),

              // ==================================================
              // STATS
              // ==================================================

              Row(
                children: [
                  Expanded(
                    child:
                        statCard(
                      Icons.bolt,
                      'DAILY',
                      '+10',
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child:
                        statCard(
                      Icons
                          .card_giftcard,
                      'AD BONUS',
                      '+25',
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 15,
              ),

              Row(
                children: [
                  Expanded(
                    child:
                        statCard(
                      Icons
                          .calendar_today,
                      'CLAIMS',
                      '$totalDailyClaims',
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child:
                        statCard(
                      Icons
                          .ondemand_video,
                      'AD REWARDS',
                      '$totalAdRewards',
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 30,
              ),

              // ==================================================
              // INFO
              // ==================================================

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
                    0xFF171B24,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),
                child:
                    const Column(
                  children: [
                    Icon(
                      Icons
                          .info_outline,
                      color:
                          Colors.white54,
                    ),

                    SizedBox(
                      height: 10,
                    ),

                    Text(
                      'COIN MINER is a reward simulation app. '
                      'The coins shown here are virtual in-app '
                      'points and are not real cryptocurrency.',
                      textAlign:
                          TextAlign.center,
                      style:
                          TextStyle(
                        color:
                            Colors.white54,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              const Text(
                'COIN MINER v3',
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
      child: Column(
        children: [
          Icon(
            icon,
            color:
                Colors.amber,
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
              fontSize: 12,
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
              fontSize: 
