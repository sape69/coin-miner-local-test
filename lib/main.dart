import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<void> main() async {
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
      home: const HomePage(),
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
  // ----------------------------------------------------------
  // DATA
  // ----------------------------------------------------------

  double balance = 0.0;
  int streak = 0;

  String username = '';

  int lastMineTimestamp = 0;

  bool loading = true;

  // ----------------------------------------------------------
  // TIMER
  // ----------------------------------------------------------

  Timer? countdownTimer;

  Duration remaining = Duration.zero;

  // ----------------------------------------------------------
  // ADS
  // ----------------------------------------------------------

  RewardedAd? rewardedAd;
  bool rewardedAdReady = false;

  // Google test rewarded ad ID.
  // Vaihdetaan myöhemmin omaan AdMob ID:hen.
  static const String rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // ----------------------------------------------------------
  // INIT
  // ----------------------------------------------------------

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

  // ==========================================================
  // LOAD DATA
  // ==========================================================

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedBalance =
        prefs.getDouble('balance') ?? 0.0;

    final savedStreak =
        prefs.getInt('streak') ?? 0;

    final savedUsername =
        prefs.getString('username') ?? '';

    final savedTimestamp =
        prefs.getInt('lastMineTimestamp') ?? 0;

    if (!mounted) return;

    setState(() {
      balance = savedBalance;
      streak = savedStreak;
      username = savedUsername;
      lastMineTimestamp = savedTimestamp;
      loading = false;
    });

    updateCountdown();
  }

  // ==========================================================
  // SAVE DATA
  // ==========================================================

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();

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

    await prefs.setInt(
      'lastMineTimestamp',
      lastMineTimestamp,
    );
  }

  // ==========================================================
  // USERNAME
  // ==========================================================

  Future<void> saveUsername() async {
    final name = usernameController.text.trim();

    if (name.isEmpty) {
      showMessage(
        'Enter a username first.',
        Icons.person,
      );
      return;
    }

    if (name.length < 2) {
      showMessage(
        'Username must be at least 2 characters.',
        Icons.warning,
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      username = name;
    });

    await saveData();
  }

  final TextEditingController usernameController =
      TextEditingController();

  // ==========================================================
  // 24 HOUR TIMER
  // ==========================================================

  void updateCountdown() {
    if (!mounted) return;

    if (lastMineTimestamp == 0) {
      setState(() {
        remaining = Duration.zero;
      });
      return;
    }

    final lastMine =
        DateTime.fromMillisecondsSinceEpoch(
      lastMineTimestamp,
    );

    final nextMine =
        lastMine.add(const Duration(hours: 24));

    final now = DateTime.now();

    final difference = nextMine.difference(now);

    if (difference.isNegative) {
      setState(() {
        remaining = Duration.zero;
      });
    } else {
      setState(() {
        remaining = difference;
      });
    }
  }

  // ==========================================================
  // CAN MINE?
  // ==========================================================

  bool get canMine {
    if (lastMineTimestamp == 0) {
      return true;
    }

    final lastMine =
        DateTime.fromMillisecondsSinceEpoch(
      lastMineTimestamp,
    );

    final nextMine =
        lastMine.add(const Duration(hours: 24));

    return DateTime.now().isAfter(nextMine) ||
        DateTime.now().isAtSameMomentAs(nextMine);
  }

  // ==========================================================
  // FORMAT TIMER
  // ==========================================================

  String formatDuration(Duration duration) {
    final hours = duration.inHours;

    final minutes =
        duration.inMinutes.remainder(60);

    final seconds =
        duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // ==========================================================
  // MINE / CLAIM
  // ==========================================================

  Future<void> mineCoins() async {
    if (!canMine) {
      showMessage(
        'You must wait until the timer reaches 00:00:00.',
        Icons.lock_clock,
      );
      return;
    }

    const double dailyReward = 10.0;

    balance += dailyReward;

    // --------------------------------------------------------
    // STREAK
    // --------------------------------------------------------

    if (lastMineTimestamp != 0) {
      final previous =
          DateTime.fromMillisecondsSinceEpoch(
        lastMineTimestamp,
      );

      final difference =
          DateTime.now().difference(previous);

      if (difference.inHours <= 48) {
        streak++;
      } else {
        streak = 1;
      }
    } else {
      streak = 1;
    }

    // --------------------------------------------------------
    // SAVE CLAIM TIME
    // --------------------------------------------------------

    lastMineTimestamp =
        DateTime.now().millisecondsSinceEpoch;

    if (!mounted) return;

    setState(() {
      remaining = const Duration(hours: 24);
    });

    await saveData();

    if (!mounted) return;

    showMessage(
      '+10 COINS claimed!',
      Icons.bolt,
    );
  }

  // ==========================================================
  // REWARDED AD
  // ==========================================================

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
                (RewardedAd ad, AdError error) {
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

  // ==========================================================
  // SHOW REWARDED AD
  // ==========================================================

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
          (AdWithoutView ad, RewardItem reward) async {
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

  // ==========================================================
  // RESET ACCOUNT
  // ==========================================================

  Future<void> resetAccount() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove('balance');
    await prefs.remove('streak');
    await prefs.remove('username');
    await prefs.remove('lastMineTimestamp');

    usernameController.clear();

    if (!mounted) return;

    setState(() {
      balance = 0.0;
      streak = 0;
      username = '';
      lastMineTimestamp = 0;
      remaining = Duration.zero;
    });

    showMessage(
      'Test account reset.',
      Icons.refresh,
    );
  }

  // ==========================================================
  // RESET DIALOG
  // ==========================================================

  void showResetDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Reset account?',
          ),
          content: const Text(
            'This will delete the local test balance, '
            'streak, username and 24-hour timer.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                await resetAccount();
              },
              child: const Text('RESET'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void showMessage(
    String text,
    IconData icon,
  ) {
    if (!mounted) return;

    final messenger =
        ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
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
  // BUILD
  // ==========================================================

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

    // --------------------------------------------------------
    // FIRST SCREEN: USERNAME
    // --------------------------------------------------------

    if (username.trim().isEmpty) {
      return buildUsernameScreen();
    }

    // --------------------------------------------------------
    // MAIN SCREEN
    // --------------------------------------------------------

    return buildMainScreen();
  }

  // ==========================================================
  // USERNAME SCREEN
  // ==========================================================

  Widget buildUsernameScreen() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),

                Container(
                  width: 120,
                  height: 120,
                  decoration:
                      BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amber
                        .withOpacity(0.12),
                    border: Border.all(
                      color: Colors.amber
                          .withOpacity(0.35),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '₿',
                      style: TextStyle(
                        fontSize: 78,
                        color: Colors.amber,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                const Text(
                  'COIN MINER',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight:
                        FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Welcome to COIN MINER!',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Choose your miner name to continue.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 30),

                TextField(
                  controller:
                      usernameController,
                  maxLength: 20,
                  textCapitalization:
                      TextCapitalization.words,
                  decoration:
                      const InputDecoration(
                    labelText: 'Username',
                    hintText:
                        'Enter your name',
                    prefixIcon:
                        Icon(Icons.person),
                    border:
                        OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 15),

                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed:
                        saveUsername,
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.amber,
                      foregroundColor:
                          Colors.black,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(30),
                      ),
                    ),
                    child: const Text(
                      'CONTINUE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  'Your coins are virtual in-app points.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // MAIN SCREEN
  // ==========================================================

  Widget buildMainScreen() {
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
              const SizedBox(height: 10),

              // ------------------------------------------------
              // USER
              // ------------------------------------------------

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
                      BorderRadius.circular(18),
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
                              height: 3),
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

              // ------------------------------------------------
              // COIN
              // ------------------------------------------------

              Container(
                width: 125,
                height: 125,
                decoration:
                    BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber
                      .withOpacity(0.12),
                  border: Border.all(
                    color: Colors.amber
                        .withOpacity(0.35),
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

              const SizedBox(height: 25),

              const Text(
                'YOUR BALANCE',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                balance.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight:
                      FontWeight.bold,
                  color: Colors.amber,
                ),
              ),

              const Text(
                'COINS',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white70,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 20),

              // ------------------------------------------------
              // STREAK
              // ------------------------------------------------

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
                      BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons
                          .local_fire_department,
                      color: Colors.orange,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
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

              // ------------------------------------------------
              // TIMER
              // ------------------------------------------------

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(22),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFF1C202A),
                  borderRadius:
                      BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.amber
                        .withOpacity(0.15),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.timer,
                      color: Colors.amber,
                      size: 42,
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'NEXT CLAIM',
                      style: TextStyle(
                        color:
                            Colors.white70,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      canMine
                          ? '00:00:00'
                          : formatDuration(
                              remaining,
                            ),
                      style:
                          const TextStyle(
                        color: Colors.amber,
                        fontSize: 38,
                        fontWeight:
                            FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      canMine
                          ? 'CLAIM AVAILABLE'
                          : 'HOURS : MINUTES : SECONDS',
                      style:
                          const TextStyle(
                        color:
                            Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ------------------------------------------------
              // CLAIM BUTTON
              // ------------------------------------------------

              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton.icon(
                  onPressed:
                      canMine
                          ? mineCoins
                          : null,
                  icon: Icon(
                    canMine
                        ? Icons.bolt
                        : Icons.lock_clock,
                    size: 28,
                  ),
                  label: Text(
                    canMine
                        ? 'CLAIM 10 COINS'
                        : 'CLAIM LOCKED',
                    style:
                        const TextStyle(
                      fontSize: 19,
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
                            0xFF27232A),
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

              const SizedBox(height: 12),

              Text(
                canMine
                    ? 'Your daily claim is ready.'
                    : 'Come back when the 24-hour timer reaches zero.',
                textAlign:
                    TextAlign.center,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 30),

              // ------------------------------------------------
              // REWARDED AD
              // ------------------------------------------------

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(22),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFF1C202A),
                  borderRadius:
                      BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white
                        .withOpacity(0.05),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.ondemand_video,
                      color: Colors.amber,
                      size: 48,
                    ),

                    const SizedBox(height: 14),

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

                    const SizedBox(height: 8),

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

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child:
                          OutlinedButton.icon(
                        onPressed:
                            showRewardedAd,
                        icon: const Icon(
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

              const SizedBox(height: 25),

              // ------------------------------------------------
              // STATS
              // ------------------------------------------------

              Row(
                children: [
                  Expanded(
                    child: statCard(
                      Icons.bolt,
                      'DAILY',
                      '+10',
                    ),
                  ),
                  const SizedBox(width: 12),
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

              // ------------------------------------------------
              // INFO
              // ------------------------------------------------

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(18),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFF171B24),
                  borderRadius:
                      BorderRadius.circular(18),
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

              const SizedBox(height: 25),

              const Text(
                'COIN MINER v3',
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

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    countdownTimer?.cancel();
    rewardedAd?.dispose();
    usernameController.dispose();

    super.dispose();
  }
}