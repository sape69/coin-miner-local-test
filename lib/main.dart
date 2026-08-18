import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  MobileAds.instance.initialize();

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
        scaffoldBackgroundColor: const Color(0xFF0E1119),
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
  double coins = 0.0;
  bool minedToday = false;
  bool loading = true;
  bool adLoading = false;

  RewardedAd? rewardedAd;

  static const double dailyReward = 10.0;
  static const double adReward = 5.0;

  // Googlen virallinen Android Rewarded testimainos.
  static const String rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  @override
  void initState() {
    super.initState();

    loadData();
    loadRewardedAd();
  }

  @override
  void dispose() {
    rewardedAd?.dispose();
    super.dispose();
  }

  String dateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedCoins = prefs.getDouble('coins') ?? 0.0;
    final lastMineDate = prefs.getString('lastMineDate');

    final today = dateKey(DateTime.now());

    if (!mounted) return;

    setState(() {
      coins = savedCoins;
      minedToday = lastMineDate == today;
      loading = false;
    });
  }

  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          rewardedAd = ad;
          adLoading = false;

          debugPrint('Rewarded Ad loaded.');
        },
        onAdFailedToLoad: (LoadAdError error) {
          rewardedAd = null;
          adLoading = false;

          debugPrint(
            'Rewarded Ad failed to load: $error',
          );
        },
      ),
    );

    adLoading = true;
  }

  Future<void> mineCoins() async {
    if (minedToday) {
      showMessage('Olet jo louhinut tänään.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    final newBalance = coins + dailyReward;
    final today = dateKey(DateTime.now());

    await prefs.setDouble('coins', newBalance);
    await prefs.setString('lastMineDate', today);

    if (!mounted) return;

    setState(() {
      coins = newBalance;
      minedToday = true;
    });

    showMessage('+10 COINS lisätty!');
  }

  void watchAd() {
    if (rewardedAd == null) {
      showMessage(
        'Mainos ei ole vielä valmis. Yritä hetken päästä uudelleen.',
      );

      if (!adLoading) {
        loadRewardedAd();
      }

      return;
    }

    final ad = rewardedAd!;

    rewardedAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) {
        debugPrint('Rewarded Ad shown.');
      },
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        debugPrint('Rewarded Ad dismissed.');

        ad.dispose();
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent:
          (RewardedAd ad, AdError error) {
        debugPrint(
          'Rewarded Ad failed to show: $error',
        );

        ad.dispose();
        loadRewardedAd();

        showMessage('Mainoksen näyttäminen epäonnistui.');
      },
    );

    ad.show(
      onUserEarnedReward:
          (AdWithoutView ad, RewardItem reward) {
        addAdReward();
      },
    );
  }

  Future<void> addAdReward() async {
    final prefs = await SharedPreferences.getInstance();

    final newBalance = coins + adReward;

    await prefs.setDouble('coins', newBalance);

    if (!mounted) return;

    setState(() {
      coins = newBalance;
    });

    showMessage('+5 COINS palkkiona!');
  }

  Future<void> resetDemo() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('coins');
    await prefs.remove('lastMineDate');

    if (!mounted) return;

    setState(() {
      coins = 0.0;
      minedToday = false;
    });

    showMessage('Demo nollattu.');
  }

  void showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
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
          'COIN MINER',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF17131C),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 25),

                const Icon(
                  Icons.currency_bitcoin,
                  size: 95,
                  color: Colors.amber,
                ),

                const SizedBox(height: 25),

                const Text(
                  'YOUR BALANCE',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  coins.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),

                const Text(
                  'COINS',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 45),

                SizedBox(
                  width: double.infinity,
                  height: 62,
                  child: ElevatedButton.icon(
                    onPressed:
                        minedToday ? null : mineCoins,
                    icon: Icon(
                      minedToday
                          ? Icons.check_circle
                          : Icons.bolt,
                    ),
                    label: Text(
                      minedToday
                          ? 'MINED TODAY'
                          : 'MINE +10 COINS',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  minedToday
                      ? 'Come back tomorrow to mine again!'
                      : 'Mine once every day!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white54,
                  ),
                ),

                const SizedBox(height: 40),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1F29),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.ondemand_video,
                        size: 55,
                        color: Colors.amber,
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        'WATCH AD TO EARN MORE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Watch a rewarded ad and get +5 COINS.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white54,
                        ),
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              adLoading ? null : watchAd,
                          icon: const Icon(
                            Icons.play_arrow,
                          ),
                          label: Text(
                            adLoading
                                ? 'LOADING AD...'
                                : 'WATCH AD +5',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF171B24),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        minedToday
                            ? Icons.check_circle
                            : Icons.access_time,
                        color: minedToday
                            ? Colors.greenAccent
                            : Colors.amber,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          minedToday
                              ? 'Daily mining completed'
                              : 'Daily mining available',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                TextButton(
                  onPressed: resetDemo,
                  child: const Text(
                    'Reset demo',
                    style: TextStyle(
                      color: Colors.white38,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
