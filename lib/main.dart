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
  // ==========================================================
  // ACCOUNT DATA
  // ==========================================================

  double balance = 0.0;

  int streak = 0;

  String username = '';

  DateTime? lastClaimTime;

  // ==========================================================
  // HOURLY AD BONUS
  // ==========================================================

  DateTime? lastBonusTime;

  int bonusCountToday = 0;

  String bonusDay = '';

  // ==========================================================
  // UI STATE
  // ==========================================================

  bool loading = true;

  Timer? timer;

  // ==========================================================
  // REWARDED AD
  // ==========================================================

  RewardedAd? rewardedAd;

  bool rewardedAdReady = false;

  bool showingAd = false;

  // Google test rewarded ad.
  //
  // IMPORTANT:
  // Use this test ID while developing.
  // Replace it with your real AdMob Rewarded Ad Unit ID
  // before publishing.
  static const String rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

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
    final prefs = await SharedPreferences.getInstance();

    final savedBalance = prefs.getDouble('balance') ?? 0.0;

    final savedStreak = prefs.getInt('streak') ?? 0;

    final savedUsername = prefs.getString('username') ?? '';

    final savedClaimMs = prefs.getInt('lastClaimTime');

    final savedBonusMs = prefs.getInt('lastBonusTime');

    final savedBonusCount = prefs.getInt('bonusCountToday') ?? 0;

    final savedBonusDay = prefs.getString('bonusDay') ?? '';

    DateTime? claimTime;

    if (savedClaimMs != null) {
      claimTime = DateTime.fromMillisecondsSinceEpoch(
        savedClaimMs,
      );
    }

    DateTime? bonusTime;

    if (savedBonusMs != null) {
      bonusTime = DateTime.fromMillisecondsSinceEpoch(
        savedBonusMs,
      );
    }

    final today = dateKey(DateTime.now());

    int fixedBonusCount = savedBonusCount;

    if (savedBonusDay != today) {
      fixedBonusCount = 0;
    }

    if (!mounted) return;

    setState(() {
      balance = savedBalance;
      streak = savedStreak;
      username = savedUsername;

      lastClaimTime = claimTime;

      lastBonusTime = bonusTime;

      bonusCountToday = fixedBonusCount;

      bonusDay = today;

      loading = false;
    });

    // Ask for username AFTER the current build has finished.
    if (username.trim().isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showUsernameDialog();
        }
      });
    }
  }

  // ============================================================
  // SAVE DATA
  // ============================================================

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

    if (lastClaimTime != null) {
      await prefs.setInt(
        'lastClaimTime',
        lastClaimTime!.millisecondsSinceEpoch,
      );
    } else {
      await prefs.remove('lastClaimTime');
    }

    if (lastBonusTime != null) {
      await prefs.setInt(
        'lastBonusTime',
        lastBonusTime!.millisecondsSinceEpoch,
      );
    } else {
      await prefs.remove('lastBonusTime');
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

  // ============================================================
  // DATE KEY
  // ============================================================

  String dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // USERNAME
  // ============================================================

  Future<void> showUsernameDialog() async {
    if (!mounted) return;

    final controller = TextEditingController();

    final name = await showDialog<String>(
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
                decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'Enter your name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('CONTINUE'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (!mounted) return;

    if (name != null && name.trim().isNotEmpty) {
      setState(() {
        username = name.trim();
      });

      await saveData();
    }
  }

  // ============================================================
  // DAILY CLAIM STATUS
  // ============================================================

  bool get canClaim {
    if (lastClaimTime == null) {
      return true;
    }

    final difference = DateTime.now().difference(
      lastClaimTime!,
    );

    return difference >= const Duration(hours: 24);
  }

  Duration get claimRemaining {
    if (lastClaimTime == null) {
      return Duration.zero;
    }

    final nextClaim = lastClaimTime!.add(
      const Duration(hours: 24),
    );

    final remaining = nextClaim.difference(
      DateTime.now(),
    );

    if (remaining.isNegative) {
      return Duration.zero;
    }

    return remaining;
  }

  // ============================================================
  // HOURLY BONUS STATUS
  // ============================================================

  bool get canWatchBonus {
    resetBonusDayIfNeeded();

    if (bonusCountToday >= 5) {
      return false;
    }

    if (lastBonusTime == null) {
      return true;
    }

    final difference = DateTime.now().difference(
      lastBonusTime!,
    );

    return difference >= const Duration(hours: 1);
  }

  Duration get bonusRemaining {
    if (lastBonusTime == null) {
      return Duration.zero;
    }

    final nextBonus = lastBonusTime!.add(
      const Duration(hours: 1),
    );

    final remaining = nextBonus.difference(
      DateTime.now(),
    );

    if (remaining.isNegative) {
      return Duration.zero;
    }

    return remaining;
  }

  // ============================================================
  // RESET DAILY BONUS COUNTER
  // ============================================================

  void resetBonusDayIfNeeded() {
    final today = dateKey(DateTime.now());

    if (bonusDay != today) {
      bonusDay = today;
      bonusCountToday = 0;
      lastBonusTime = null;
    }
  }

  // ============================================================
  // CLAIM 10 COINS
  // ============================================================

  Future<void> claimCoins() async {
    if (!canClaim) {
      showMessage(
        'Next claim in ${formatDuration(claimRemaining)}',
        Icons.timer,
      );

      return;
    }

    final now = DateTime.now();

    // ========================================================
    // STREAK
    // ========================================================

    if (lastClaimTime != null) {
      final previousDate = dateKey(
        lastClaimTime!,
      );

      final yesterday = dateKey(
        now.subtract(
          const Duration(days: 1),
        ),
      );

      if (previousDate == yesterday) {
        streak++;
      } else {
        streak = 1;
      }
    } else {
      streak = 1;
    }

    // ========================================================
    // ADD 10 COINS
    // ========================================================

    balance += 10.0;

    lastClaimTime = now;

    await saveData();

    if (!mounted) return;

    setState(() {});

    showMessage(
      '+10 COINS claimed!',
      Icons.bolt,
    );

    // ========================================================
    // SHOW AD AFTER CLAIM
    // ========================================================

    await Future.delayed(
      const Duration(milliseconds: 400),
    );

    if (!mounted) return;

    showRewardedAd(
      rewardType: RewardType.afterClaim,
    );
  }

  // ============================================================
  // LOAD REWARDED AD
  // ============================================================

  void loadRewardedAd() {
    if (rewardedAdReady || rewardedAd != null) {
      return;
    }

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
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

              showingAd = false;

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
        onAdFailedToLoad: (LoadAdError error) {
          rewardedAd = null;

          rewardedAdReady = false;

          if (mounted) {
            setState(() {});
          }

          // Try again later.
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

  // ============================================================
  // REWARDED AD
  // ============================================================

  void showRewardedAd({
    required RewardType rewardType,
  }) {
    if (showingAd) {
      return;
    }

    if (!rewardedAdReady || rewardedAd == null) {
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

    showingAd = true;

    if (mounted) {
      setState(() {});
    }

    ad.show(
      onUserEarnedReward:
          (AdWithoutView ad, RewardItem reward) async {
        if (rewardType == RewardType.hourlyBonus) {
          await giveHourlyBonus();
        }

        // No additional coins after daily claim.
        // The +10 daily claim has already been given.
      },
    );
  }

  // ============================================================
  // HOURLY +5 BONUS
  // ============================================================

  Future<void> watchHourlyBonus() async {
    resetBonusDayIfNeeded();

    if (bonusCountToday >= 5) {
      showMessage(
        'Daily limit reached: 5/5 bonuses.',
        Icons.lock,
      );

      return;
    }

    if (!canWatchBonus) {
      showMessage(
        'Next +5 bonus in ${formatDuration(bonusRemaining)}',
        Icons.timer,
      );

      return;
    }

    if (!rewardedAdReady || rewardedAd == null) {
      showMessage(
        'Ad is loading. Try again in a moment.',
        Icons.hourglass_top,
      );

      loadRewardedAd();

      return;
    }

    showRewardedAd(
      rewardType: RewardType.hourlyBonus,
    );
  }

  // ============================================================
  // GIVE +5 BONUS
  // ============================================================

  Future<void> giveHourlyBonus() async {
    resetBonusDayIfNeeded();

    if (bonusCountToday >= 5) {
      return;
    }

    balance += 5.0;

    bonusCountToday++;

    lastBonusTime = DateTime.now();

    bonusDay = dateKey(
      DateTime.now(),
    );

    await saveData();

    if (!mounted) return;

    setState(() {});

    showMessage(
      '+5 COINS bonus!',
      Icons.card_giftcard,
    );
  }

  // ============================================================
  // FORMAT TIME
  // ============================================================

  String formatDuration(Duration duration) {
    if (duration.isNegative || duration == Duration.zero) {
      return '00:00:00';
    }

    final hours = duration.inHours;

    final minutes = duration.inMinutes.remainder(60);

    final seconds = duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
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
  // RESET ACCOUNT
  // ============================================================

  Future<void> resetAccount() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove('balance');
    await prefs.remove('streak');
    await prefs.remove('username');
    await prefs.remove('lastClaimTime');
    await prefs.remove('lastBonusTime');
    await prefs.remove('bonusCountToday');
    await prefs.remove('bonusDay');

    if (!mounted) return;

    setState(() {
      balance = 0.0;

      streak = 0;

      username = '';

      lastClaimTime = null;

      lastBonusTime = null;

      bonusCountToday = 0;

      bonusDay = dateKey(
        DateTime.now(),
      );
    });

    showMessage(
      'Test account reset.',
      Icons.refresh,
    );

    await Future.delayed(
      const Duration(milliseconds: 300),
    );

    if (mounted) {
      await showUsernameDialog();
    }
  }

  // ============================================================
  // RESET DIALOG
  // ============================================================

  Future<void> showResetDialog() async {
    if (!mounted) return;

    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Reset account?',
          ),
          content: const Text(
            'This will delete your local test balance, '
            'streak, username and timers.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('RESET'),
            ),
          ],
        );
      },
    );

    if (shouldReset == true && mounted) {
      await resetAccount();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

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

    resetBonusDayIfNeeded();

    final claimTimeText = canClaim
        ? 'READY'
        : formatDuration(claimRemaining);

    final bonusTimeText = canWatchBonus
        ? 'READY'
        : formatDuration(bonusRemaining);

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
        backgroundColor: const Color(0xFF17131C),
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
                      Text('Reset test account'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 15),

              // ==================================================
              // USER
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1F29),
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.amber,
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
                              color: Colors.white54,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            username,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
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
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      Colors.amber.withValues(alpha: 0.12),
                  border: Border.all(
                    color: Colors.amber.withValues(
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'YOUR BALANCE',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white70,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                balance.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 58,
                  fontWeight: FontWeight.bold,
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

              const SizedBox(height: 20),

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
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1F29),
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'MINING STREAK',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      '$streak DAYS',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ==================================================
              // DAILY CLAIM
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C202A),
                  borderRadius:
                      BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.amber.withValues(
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
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Claim 10 coins once every 24 hours.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white60,
                      ),
                    ),

                    const SizedBox(height: 15),

                    if (!canClaim)
                      Text(
                        claimTimeText,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),

                    if (!canClaim)
                      const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton.icon(
                        onPressed:
                            canClaim && !showingAd
                                ? claimCoins
                                : null,
                        icon: Icon(
                          canClaim
                              ? Icons.bolt
                              : Icons.lock_clock,
                        ),
                        label: Text(
                          canClaim
                              ? 'CLAIM 10 COINS'
                              : 'NEXT CLAIM $claimTimeText',
                          textAlign: TextAlign.center,
                        ),
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.amber,
                          foregroundColor:
                              Colors.black,
                          disabledBackgroundColor:
                              const Color(0xFF29262D),
                          disabledForegroundColor:
                              Colors.white38,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              30,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // HOURLY +5 AD BONUS
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C202A),
                  borderRadius:
                      BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.amber.withValues(
                      alpha: 0.15,
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

                    const SizedBox(height: 12),

                    const Text(
                      'WATCH AD +5 COINS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'Watch a rewarded ad and receive 5 coins.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      '$bonusCountToday / 5 TODAY',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(height: 8),

                    if (!canWatchBonus &&
                        bonusCountToday < 5)
                      Text(
                        'NEXT BONUS $bonusTimeText',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                    if (bonusCountToday >= 5)
                      const Text(
                        'DAILY BONUS LIMIT REACHED',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                    const SizedBox(height: 15),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed:
                            canWatchBonus &&
                                    !showingAd
                                ? watchHourlyBonus
                                : null,
                        icon: const Icon(
                          Icons.play_arrow,
                        ),
                        label: Text(
                          bonusCountToday >= 5
                              ? '5 / 5 COMPLETED'
                              : canWatchBonus
                                  ? 'WATCH & EARN +5'
                                  : 'WAIT $bonusTimeText',
                        ),
                        style:
                            OutlinedButton.styleFrom(
                          foregroundColor:
                              Colors.amber,
                          disabledForegroundColor:
                              Colors.white38,
                          side:
                              const BorderSide(
                            color: Colors.amber,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
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

              // ==================================================
              // STATS
              // ==================================================

              Row(
                children: [
                  Expanded(
                    child: statCard(
                      Icons.bolt,
                      'DAILY CLAIM',
                      '+10',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: statCard(
                      Icons.card_giftcard,
                      'AD BONUS',
                      '+5',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // ==================================================
              // INFO
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF171B24),
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
                      'COIN MINER is currently a reward '
                      'simulation app. The coins shown here '
                      'are virtual in-app points and are not '
                      'real cryptocurrency.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54,
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

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget statCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F29),
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
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'COINS',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

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