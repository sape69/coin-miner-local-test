import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Käynnistetään sovellus ensin.
  // AdMob ei saa estää sovelluksen käynnistymistä.
  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    debugPrint('AdMob initialization error: $e');
  }

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

  String lastMineDate = '';

  bool minedToday = false;
  bool loading = true;

  // ----------------------------------------------------------
  // REWARDED AD
  // ----------------------------------------------------------

  RewardedAd? rewardedAd;
  bool rewardedAdReady = false;
  bool loadingAd = false;

  // Googlen virallinen TEST rewarded ad.
  static const String rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    loadData();

    // Odotetaan hieman ennen mainoksen lataamista.
    // Näin AdMob ei estä käyttöliittymän avautumista.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        loadRewardedAd();
      }
    });
  }

  // ==========================================================
  // LOAD DATA
  // ==========================================================

  Future<void> loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedBalance =
          prefs.getDouble('balance') ?? 0.0;

      final savedStreak =
          prefs.getInt('streak') ?? 0;

      final savedDate =
          prefs.getString('lastMineDate') ?? '';

      final today = dateKey(DateTime.now());

      if (!mounted) return;

      setState(() {
        balance = savedBalance;
        streak = savedStreak;
        lastMineDate = savedDate;
        minedToday = savedDate == today;
        loading = false;
      });
    } catch (e) {
      debugPrint('Load data error: $e');

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  // ==========================================================
  // SAVE DATA
  // ==========================================================

  Future<void> saveData() async {
    try {
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
        'lastMineDate',
        lastMineDate,
      );
    } catch (e) {
      debugPrint('Save data error: $e');
    }
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
  // MINE COINS
  // ==========================================================

  Future<void> mineCoins() async {
    if (minedToday) {
      showMessage(
        'You have already mined today.',
        Icons.lock_clock,
      );
      return;
    }

    final today = DateTime.now();

    final yesterday = today.subtract(
      const Duration(days: 1),
    );

    final yesterdayKey = dateKey(yesterday);

    // Streak
    if (lastMineDate == yesterdayKey) {
      streak++;
    } else {
      streak = 1;
    }

    // Daily reward
    const double dailyReward = 10.0;

    balance += dailyReward;

    lastMineDate = dateKey(today);
    minedToday = true;

    await saveData();

    if (!mounted) return;

    setState(() {});

    showMessage(
      '+10 COINS mined!',
      Icons.bolt,
    );
  }

  // ==========================================================
  // LOAD REWARDED AD
  // ==========================================================

  void loadRewardedAd() {
    if (loadingAd || rewardedAdReady) {
      return;
    }

    loadingAd = true;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(

        // ----------------------------------------------------
        // AD LOADED
        // ----------------------------------------------------

        onAdLoaded: (RewardedAd ad) {
          debugPrint('Rewarded ad loaded.');

          loadingAd = false;

          rewardedAd = ad;
          rewardedAdReady = true;

          ad.fullScreenContentCallback =
              FullScreenContentCallback(

            // ------------------------------------------------
            // AD DISMISSED
            // ------------------------------------------------

            onAdDismissedFullScreenContent:
                (RewardedAd ad) {
              debugPrint('Rewarded ad dismissed.');

              ad.dispose();

              rewardedAd = null;
              rewardedAdReady = false;

              if (mounted) {
                setState(() {});
              }

              // Ladataan seuraava mainos.
              loadRewardedAd();
            },

            // ------------------------------------------------
            // AD FAILED TO SHOW
            // ------------------------------------------------

            onAdFailedToShowFullScreenContent:
                (RewardedAd ad, AdError error) {
              debugPrint(
                'Rewarded ad failed to show: $error',
              );

              ad.dispose();

              rewardedAd = null;
              rewardedAdReady = false;

              if (mounted) {
                setState(() {});
              }

              loadRewardedAd();
            },
          );

          if (mounted) {
            setState(() {});
          }
        },

        // ----------------------------------------------------
        // AD FAILED TO LOAD
        // ----------------------------------------------------

        onAdFailedToLoad: (LoadAdError error) {
          debugPrint(
            'Rewarded ad failed to load: $error',
          );

          loadingAd = false;

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

    if (mounted) {
      setState(() {});
    }

    ad.show(
      onUserEarnedReward:
          (AdWithoutView ad, RewardItem reward) async {
        // Test reward
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
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('balance');
      await prefs.remove('streak');
      await prefs.remove('lastMineDate');

      if (!mounted) return;

      setState(() {
        balance = 0.0;
        streak
