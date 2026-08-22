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
      home: const StartPage(),
    );
  }
}

// ============================================================
// START PAGE
// IMPORTANT:
// We do NOT use AlertDialog for the username.
// This avoids the Flutter _dependents.isEmpty error.
// ============================================================

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  final TextEditingController controller = TextEditingController();

  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    checkUsername();
  }

  Future<void> checkUsername() async {
    final prefs = await SharedPreferences.getInstance();

    final savedUsername =
        prefs.getString('username')?.trim() ?? '';

    if (!mounted) return;

    if (savedUsername.isNotEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );
      return;
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> continueToApp() async {
    if (saving) return;

    final name = controller.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a username.'),
        ),
      );
      return;
    }

    if (name.length > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username can contain maximum 20 characters.'),
        ),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    final prefs = await SharedPreferences.getInstance();

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
  void dispose() {
    controller.dispose();
    super.dispose();
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

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amber.withValues(
                      alpha: 0.12,
                    ),
                    border: Border.all(
                      color: Colors.amber.withValues(
                        alpha: 0.4,
                      ),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '₿',
                      style: TextStyle(
                        fontSize: 70,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  'COIN MINER',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Welcome!',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 35),

                TextField(
                  controller: controller,
                  maxLength: 20,
                  textCapitalization:
                      TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    hintText: 'Enter your name',
                    prefixIcon: const Icon(
                      Icons.person,
                    ),
                    filled: true,
                    fillColor: const Color(
                      0xFF1B1F29,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed:
                        saving ? null : continueToApp,
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(30),
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
  // ----------------------------------------------------------
  // ACCOUNT
  // ----------------------------------------------------------

  String username = '';

  double balance = 0.0;

  DateTime? lastClaimTime;

  bool loading = true;

  // ----------------------------------------------------------
  // REWARDED AD
  // ----------------------------------------------------------

  RewardedAd? rewardedAd;

  bool rewardedAdReady = false;

  // Google official rewarded test ad.
  static const String rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // ----------------------------------------------------------
  // AD LIMITS
  // ----------------------------------------------------------

  static const int maxAdsPerDay = 5;

  static const Duration adCooldown =
      Duration(hours: 1);

  List<int> adWatchTimes = [];

  Timer? timer;

  DateTime now = DateTime.now();

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    loadData();

    loadRewardedAd();

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        setState(() {
          now = DateTime.now();
          cleanOldAdTimes();
        });
      },
    );
  }

  // ==========================================================
  // LOAD DATA
  // ==========================================================

  Future<void> loadData() async {
    final prefs =
        await SharedPreferences.getInstance();

    final savedUsername =
        prefs.getString('username') ?? '';

    final savedBalance =
        prefs.getDouble('balance') ?? 0.0;

    final savedLastClaim =
        prefs.getString('lastClaimTime') ?? '';

    final savedAdTimes =
        prefs.getStringList('adWatchTimes') ?? [];

    DateTime? parsedClaim;

    if (savedLastClaim.isNotEmpty) {
      parsedClaim =
          DateTime.tryParse(savedLastClaim);
    }

    final parsedAds = <int>[];

    for (final value in savedAdTimes) {
      final timestamp = int.tryParse(value);

      if (timestamp != null) {
        parsedAds.add(timestamp);
      }
    }

    if (!mounted) return;

    setState(() {
      username = savedUsername;
      balance = savedBalance;
      lastClaimTime = parsedClaim;
      adWatchTimes = parsedAds;
      loading = false;
      now = DateTime.now();
    });

    cleanOldAdTimes();
  }

  // ==========================================================
  // SAVE DATA
  // ==========================================================

  Future<void> saveData() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      'username',
      username,
    );

    await prefs.setDouble(
      'balance',
      balance,
    );

    if (lastClaimTime != null) {
      await prefs.setString(
        'lastClaimTime',
        lastClaimTime!.toIso8601String(),
      );
    } else {
      await prefs.remove('lastClaimTime');
    }

    await prefs.setStringList(
      'adWatchTimes',
      adWatchTimes
          .map((e) => e.toString())
          .toList(),
    );
  }

  // ==========================================================
  // CLAIM READY
  // ==========================================================

  bool get claimReady {
    if (lastClaimTime == null) {
      return true;
    }

    final difference =
        DateTime.now().difference(lastClaimTime!);

    return difference >=
        const Duration(hours: 24);
  }

  // ==========================================================
  // CLAIM TIME LEFT
  // ==========================================================

  Duration get claimTimeLeft {
    if (lastClaimTime == null) {
      return Duration.zero;
    }

    final nextClaim =
        lastClaimTime!.add(
      const Duration(hours: 24),
    );

    final difference =
        nextClaim.difference(DateTime.now());

    if (difference.isNegative) {
      return Duration.zero;
    }

    return difference;
  }

  // ==========================================================
  // CLAIM TIMER TEXT
  // ==========================================================

  String get claimTimerText {
    if (claimReady) {
      return 'READY TO CLAIM';
    }

    final duration = claimTimeLeft;

    final hours =
        duration.inHours.toString().padLeft(2, '0');

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

  // ==========================================================
  // CLEAN OLD AD TIMES
  // ==========================================================

  void cleanOldAdTimes() {
    final cutoff =
        DateTime.now()
            .subtract(const Duration(hours: 24))
            .millisecondsSinceEpoch;

    final before = adWatchTimes.length;

    adWatchTimes.removeWhere(
      (time) => time < cutoff,
    );

    if (before != adWatchTimes.length) {
      saveData();
    }
  }

  // ==========================================================
  // ADS WATCHED TODAY
  // ==========================================================

  int get adsWatchedToday {
    cleanOldAdTimes();

    final now = DateTime.now();

    return adWatchTimes.where((timestamp) {
      final date =
          DateTime.fromMillisecondsSinceEpoch(
        timestamp,
      );

      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;
  }

  // ==========================================================
  // AD AVAILABLE
  // ==========================================================

  bool get adLimitReached {
    return adsWatchedToday >= maxAdsPerDay;
  }

  // ==========================================================
  // AD COOLDOWN
  // ==========================================================

  Duration get adCooldownLeft {
    if (adWatchTimes.isEmpty) {
      return Duration.zero;
    }

    final latest =
        adWatchTimes.reduce(
      (a, b) => a > b ? a : b,
    );

    final next =
        DateTime.fromMillisecondsSinceEpoch(
      latest,
    ).add(adCooldown);

    final difference =
        next.difference(DateTime.now());

    if (difference.isNegative) {
      return Duration.zero;
    }

    return difference;
  }

  // ==========================================================
  // AD READY TO WATCH
  // ==========================================================

  bool get canWatchAd {
    if (!rewardedAdReady) {
      return false;
    }

    if (adLimitReached) {
      return false;
    }

    return adCooldownLeft == Duration.zero;
  }

  // ==========================================================
  // AD TIMER TEXT
  // ==========================================================

  String get adTimerText {
    if (adLimitReached) {
      return '5 / 5 TODAY';
    }

    final left = adCooldownLeft;

    if (left == Duration.zero) {
      return 'READY';
    }

    final minutes =
        left.inMinutes
            .toString()
            .padLeft(2, '0');

    final seconds =
        (left.inSeconds % 60)
            .toString()
            .padLeft(2, '0');

    return '$minutes:$seconds';
  }

  // ==========================================================
  // CLAIM 10 COINS
  // ==========================================================

  Future<void> claimCoins() async {
    if (!claimReady) {
      showMessage(
        'Next claim in ${claimTimerText}',
        Icons.lock_clock,
      );
      return;
    }

    // Give the daily reward.
    balance += 10.0;

    lastClaimTime = DateTime.now();

    await saveData();

    if (!mounted) return;

    setState(() {});

    showMessage(
      '+10 COINS CLAIMED!',
      Icons.bolt,
    );

    // --------------------------------------------------------
    // SHOW REWARDED AD AFTER CLAIM
    // --------------------------------------------------------

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) return;

    showRewardedAd();
  }

  // ==========================================================
  // LOAD REWARDED AD
  // ==========================================================

  void loadRewardedAd() {
    if (rewardedAdReady) {
      return;
    }

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
    if (adLimitReached) {
      showMessage(
        'You have watched 5 ads today.',
        Icons.block,
      );
      return;
    }

    if (adCooldownLeft != Duration.zero) {
      showMessage(
        'Next ad available in $adTimerText',
        Icons.timer,
      );
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

    ad.show(
      onUserEarnedReward:
          (AdWithoutView ad, RewardItem reward) async {
        // ----------------------------------------------------
        // +5 COINS
        // ----------------------------------------------------

        balance += 5.0;

        adWatchTimes.add(
          DateTime.now()
              .millisecondsSinceEpoch,
        );

        await saveData();

        if (!mounted) return;

        setState(() {});

        showMessage(
          '+5 COINS AD REWARD!',
          Icons.card_giftcard,
        );

        loadRewardedAd();
      },
    );
  }

  // ==========================================================
  // RESET ACCOUNT
  // ==========================================================

  Future<void> resetAccount() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove('username');
    await prefs.remove('balance');
    await prefs.remove('lastClaimTime');
    await prefs.remove('adWatchTimes');

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const StartPage(),
      ),
      (route) => false,
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
  // FORMAT COINS
  // ==========================================================

  String get balanceText {
    return balance.toStringAsFixed(1);
  }

  // ==========================================================
  // FORMAT DATE
  // ==========================================================

  String formatLastClaim() {
    if (lastClaimTime == null) {
      return 'Never';
    }

    final time = lastClaimTime!;

    final hour =
        time.hour.toString().padLeft(2, '0');

    final minute =
        time.minute.toString().padLeft(2, '0');

    return '${time.day}.${time.month}.${time.year} '
        '$hour:$minute';
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

              // =================================================
              // USER
              // =================================================

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
                            CrossAxisAlignment.start,
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
                          const SizedBox(height: 3),
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

              // =================================================
              // COIN
              // =================================================

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

              const SizedBox(height: 25),

              const Text(
                'YOUR BALANCE',
                style: TextStyle(
                  fontSize: 19,
                  color: Colors.white70,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                balanceText,
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

              const SizedBox(height: 25),

              // =================================================
              // CLAIM CARD
              // =================================================

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
                        .withValues(
                      alpha: 0.15,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.bolt,
                      color: Colors.amber,
                      size: 48,
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'DAILY CLAIM',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Claim 10 coins once every 24 hours.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color:
                            Colors.white60,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration:
                          BoxDecoration(
                        color: Colors.black26,
                        borderRadius:
                            BorderRadius
                                .circular(20),
                      ),
                      child: Text(
                        claimTimerText,
                        style:
                            const TextStyle(
                          color:
                              Colors.amber,
                          fontSize: 22,
                          fontWeight:
                              FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child:
                          ElevatedButton.icon(
                        onPressed:
                            claimReady
                                ? claimCoins
                                : null,
                        icon: const Icon(
                          Icons.bolt,
                        ),
                        label: Text(
                          claimReady
                              ? 'CLAIM 10 COINS'
                              : 'WAIT $claimTimerText',
                          style:
                              const TextStyle(
                            fontSize: 17,
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
                                  0xFF27232A),
                          disabledForegroundColor:
                              Colors.white38,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                                        30),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Last claim: ${formatLastClaim()}',
                      style:
                          const TextStyle(
                        color:
                            Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // =================================================
              // AD CARD
              // =================================================

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
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.ondemand_video,
                      color: Colors.amber,
                      size: 45,
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'WATCH AD',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'Watch a video and receive +5 coins.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color:
                            Colors.white60,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        const Icon(
                          Icons.timer,
                          size: 18,
                          color:
                              Colors.amber,
                        ),
                        const SizedBox(
                          width: 6,
                        ),
                        Text(
                          adTimerText,
                          style:
                              const TextStyle(
                            color:
                                Colors.amber,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    Text(
                      '$adsWatchedToday / $maxAdsPerDay ads today',
                      style:
                          const TextStyle(
                        color:
                            Colors.white54,
                      ),
                    ),

                    const SizedBox(height: 15),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child:
                          OutlinedButton.icon(
                        onPressed:
                            canWatchAd
                                ? showRewardedAd
                                : null,
                        icon: const Icon(
                          Icons.play_arrow,
                        ),
                        label: Text(
                          adLimitReached
                              ? 'DAILY LIMIT REACHED'
                              : adCooldownLeft !=
                                      Duration
                                          .zero
                                  ? 'WAIT $adTimerText'
                                  : rewardedAdReady
                                      ? 'WATCH & EARN +5'
                                      : 'LOADING AD...',
                        ),
                        style:
                            OutlinedButton
                                .styleFrom(
                          foregroundColor:
                              Colors.amber,
                          disabledForegroundColor:
                              Colors.white30,
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
                                        28),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // =================================================
              // STATS
              // =================================================

              Row(
                children: [
                  Expanded(
                    child: statCard(
                      Icons.bolt,
                      'CLAIM',
                      '+10',
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: statCard(
                      Icons.card_giftcard,
                      'AD',
                      '+5',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // =================================================
              // INFO
              // =================================================

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
                      color:
                          Colors.white54,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'COIN MINER is currently a local test version. '
                      'Coins are virtual in-app points and are not real cryptocurrency.',
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
  // RESET DIALOG
  // This one is safe because it is opened from the main page,
  // not automatically during the first screen.
  // ==========================================================

  void showResetDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
              const Text('Reset account?'),
          content:
              const Text(
            'This will delete the local test balance, '
            'claim timer, ad limits and username.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child:
                  const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();

                resetAccount();
              },
              child:
                  const Text('RESET'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    timer?.cancel();
    rewardedAd?.dispose();

    super.dispose();
  }
}