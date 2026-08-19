import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  // ==========================================================
  // DATA
  // ==========================================================

  double balance = 0.0;

  int streak = 0;

  int totalDailyClaims = 0;

  int totalAdRewards = 0;

  String username = '';

  // Timestamp of the last successful daily claim.
  int lastClaimMillis = 0;

  bool loading = true;

  bool rewardedAdReady = false;

  RewardedAd? rewardedAd;

  Timer? countdownTimer;

  Duration remainingTime = Duration.zero;

  // ==========================================================
  // GOOGLE TEST REWARDED AD
  // ==========================================================

  static const String rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // ==========================================================
  // CONSTANTS
  // ==========================================================

  static const double dailyReward = 10.0;

  static const double adReward = 25.0;

  static const Duration claimCooldown =
      Duration(hours: 24);

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    loadData();

    loadRewardedAd();

    startCountdownTimer();
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

    final savedLastClaim =
        prefs.getInt('lastClaimMillis') ?? 0;

    final savedDailyClaims =
        prefs.getInt('totalDailyClaims') ?? 0;

    final savedAdRewards =
        prefs.getInt('totalAdRewards') ?? 0;

    if (!mounted) {
      return;
    }

    setState(() {
      balance = savedBalance;
      streak = savedStreak;
      username = savedUsername;
      lastClaimMillis = savedLastClaim;
      totalDailyClaims = savedDailyClaims;
      totalAdRewards = savedAdRewards;
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
      'lastClaimMillis',
      lastClaimMillis,
    );

    await prefs.setInt(
      'totalDailyClaims',
      totalDailyClaims,
    );

    await prefs.setInt(
      'totalAdRewards',
      totalAdRewards,
    );
  }

  // ============================================================
  // USERNAME
  // ============================================================

  Future<void> showUsernameDialog() async {
    final controller =
        TextEditingController(text: username);

    await showDialog<void>(
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
                decoration: const InputDecoration(
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
                  Navigator.of(dialogContext).pop();
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

    controller.dispose();
  }

  // ============================================================
  // 24 HOUR COUNTDOWN
  // ============================================================

  void startCountdownTimer() {
    countdownTimer?.cancel();

    countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        updateCountdown();
      },
    );
  }

  void updateCountdown() {
    if (lastClaimMillis <= 0) {
      if (mounted) {
        setState(() {
          remainingTime = Duration.zero;
        });
      }

      return;
    }

    final lastClaim =
        DateTime.fromMillisecondsSinceEpoch(
      lastClaimMillis,
    );

    final nextClaim =
        lastClaim.add(claimCooldown);

    final now = DateTime.now();

    Duration remaining =
        nextClaim.difference(now);

    if (remaining.isNegative) {
      remaining = Duration.zero;
    }

    if (mounted) {
      setState(() {
        remaining
