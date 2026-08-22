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
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF101116),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
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
  // ------------------------------------------------------------
  // TEST AD IDS
  // ------------------------------------------------------------

  static const String rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  static const String interstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  // ------------------------------------------------------------
  // STORAGE KEYS
  // ------------------------------------------------------------

  static const String keyName = 'user_name';
  static const String keyBalance = 'balance';

  static const String keyClaimTime = 'claim_time';

  static const String keyRewardCount = 'reward_count';
  static const String keyRewardDay = 'reward_day';
  static const String keyLastRewardTime = 'last_reward_time';

  // ------------------------------------------------------------
  // APP STATE
  // ------------------------------------------------------------

  SharedPreferences? prefs;

  String userName = '';

  double balance = 0;

  DateTime? lastClaimTime;

  DateTime? lastRewardTime;

  int rewardCountToday = 0;

  String rewardDay = '';

  bool loading = true;
  bool savingName = false;
  bool claiming = false;
  bool watchingReward = false;

  Duration claimRemaining = Duration.zero;
  Duration rewardRemaining = Duration.zero;

  Timer? timer;

  // ------------------------------------------------------------
  // ADS
  // ------------------------------------------------------------

  RewardedAd? rewardedAd;
  bool rewardedAdLoading = false;

  InterstitialAd? interstitialAd;
  bool interstitialAdLoading = false;

  // ------------------------------------------------------------
  // LIFECYCLE
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _loadData();

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        _updateTimers();
        _checkRewardDay();
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();

    rewardedAd?.dispose();
    interstitialAd?.dispose();

    super.dispose();
  }

  // ------------------------------------------------------------
  // LOAD DATA
  // ------------------------------------------------------------

  Future<void> _loadData() async {
    final storage = await SharedPreferences.getInstance();

    prefs = storage;

    final savedName = storage.getString(keyName);

    final savedBalance = storage.getDouble(keyBalance);

    final savedClaim = storage.getInt(keyClaimTime);

    final savedRewardTime = storage.getInt(keyLastRewardTime);

    final savedRewardCount = storage.getInt(keyRewardCount);

    final savedRewardDay = storage.getString(keyRewardDay);

    if (!mounted) return;

    setState(() {
      userName = savedName ?? '';

      balance = savedBalance ?? 0;

      if (savedClaim != null) {
        lastClaimTime =
            DateTime.fromMillisecondsSinceEpoch(savedClaim).toUtc();
      }

      if (savedRewardTime != null) {
        lastRewardTime =
            DateTime.fromMillisecondsSinceEpoch(savedRewardTime).toUtc();
      }

      rewardCountToday = savedRewardCount ?? 0;

      rewardDay = savedRewardDay ?? '';

      loading = false;
    });

    _checkRewardDay();
    _updateTimers();

    _loadRewardedAd();
    _loadInterstitialAd();
  }

  // ------------------------------------------------------------
  // SAVE
  // ------------------------------------------------------------

  Future<void> _saveBalance() async {
    await prefs?.setDouble(keyBalance, balance);
  }

  Future<void> _saveClaimTime() async {
    if (lastClaimTime == null) return;

    await prefs?.setInt(
      keyClaimTime,
      lastClaimTime!.millisecondsSinceEpoch,
    );
  }

  // ------------------------------------------------------------
  // NAME
  // ------------------------------------------------------------

  Future<void> _continueWithName() async {
    final controller = _nameController;

    final name = controller.text.trim();

    if (name.isEmpty) {
      setState(() {
        _nameError = 'Enter your name';
      });

      return;
    }

    setState(() {
      savingName = true;
      _nameError = '';
    });

    await prefs?.setString(keyName, name);

    if (!mounted) return;

    setState(() {
      userName = name;
      savingName = false;
    });

    // IMPORTANT:
    // No Navigator.
    // No showDialog.
    // No route change.
    //
    // The page simply changes its own state.
  }

  final TextEditingController _nameController =
      TextEditingController();

  String _nameError = '';

  // ------------------------------------------------------------
  // CLAIM TIMER
  // ------------------------------------------------------------

  bool get canClaim {
    if (lastClaimTime == null) {
      return true;
    }

    final now = DateTime.now().toUtc();

    final nextClaim =
        lastClaimTime!.add(const Duration(hours: 24));

    return !now.isBefore(nextClaim);
  }

  void _updateTimers() {
    final now = DateTime.now().toUtc();

    Duration newClaimRemaining = Duration.zero;

    if (lastClaimTime != null) {
      final nextClaim =
          lastClaimTime!.add(const Duration(hours: 24));

      if (now.isBefore(nextClaim)) {
        newClaimRemaining = nextClaim.difference(now);
      }
    }

    Duration newRewardRemaining = Duration.zero;

    if (lastRewardTime != null) {
      final nextReward =
          lastRewardTime!.add(const Duration(hours: 1));

      if (now.isBefore(nextReward)) {
        newRewardRemaining = nextReward.difference(now);
      }
    }

    if (!mounted) return;

    setState(() {
      claimRemaining = newClaimRemaining;
      rewardRemaining = newRewardRemaining;
    });
  }

  // ------------------------------------------------------------
  // DAILY REWARD COUNTER
  // ------------------------------------------------------------

  String _todayUtc() {
    final now = DateTime.now().toUtc();

    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Future<void> _checkRewardDay() async {
    final today = _todayUtc();

    if (rewardDay == today) {
      return;
    }

    rewardDay = today;
    rewardCountToday = 0;

    await prefs?.setString(keyRewardDay, today);
    await prefs?.setInt(keyRewardCount, 0);

    if (!mounted) return;

    setState(() {});
  }

  // ------------------------------------------------------------
  // CLAIM 10 COINS
  // ------------------------------------------------------------

  Future<void> _claimCoins() async {
    if (claiming) return;

    if (!canClaim) {
      _showMessage(
        'You can claim again when the 24 hour timer reaches zero.',
      );

      return;
    }

    setState(() {
      claiming = true;
    });

    balance += 10;

    lastClaimTime = DateTime.now().toUtc();

    await _saveBalance();
    await _saveClaimTime();

    if (!mounted) return;

    setState(() {
      claiming = false;
      claimRemaining = const Duration(hours: 24);
    });

    _showMessage('+10 coins added!');

    // Show an interstitial advertisement after Claim.
    _showInterstitialAfterClaim();
  }

  // ------------------------------------------------------------
  // REWARDED AD +5
  // ------------------------------------------------------------

  bool get canWatchReward {
    if (rewardCountToday >= 5) {
      return false;
    }

    if (lastRewardTime == null) {
      return true;
    }

    final now = DateTime.now().toUtc();

    final nextReward =
        lastRewardTime!.add(const Duration(hours: 1));

    return !now.isBefore(nextReward);
  }

  Future<void> _watchRewardAd() async {
    if (watchingReward) return;

    await _checkRewardDay();

    if (rewardCountToday >= 5) {
      _showMessage(
        'Daily limit reached. You can watch up to 5 ads per day.',
      );

      return;
    }

    if (!canWatchReward) {
      _showMessage(
        'Please wait until the 1 hour timer reaches zero.',
      );

      return;
    }

    if (rewardedAd == null) {
      _showMessage(
        'The ad is still loading. Please try again.',
      );

      _loadRewardedAd();

      return;
    }

    setState(() {
      watchingReward = true;
    });

    final ad = rewardedAd;

    rewardedAd = null;

    ad!.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();

        if (mounted) {
          setState(() {
            watchingReward = false;
          });
        }

        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();

        if (mounted) {
          setState(() {
            watchingReward = false;
          });

          _showMessage(
            'The advertisement could not be shown.',
          );
        }

        _loadRewardedAd();
      },
    );

    ad.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
        await _giveRewardCoins();
      },
    );
  }

  Future<void> _giveRewardCoins() async {
    await _checkRewardDay();

    balance += 5;

    rewardCountToday++;

    lastRewardTime = DateTime.now().toUtc();

    await _saveBalance();

    await prefs?.setInt(
      keyRewardCount,
      rewardCountToday,
    );

    await prefs?.setInt(
      keyLastRewardTime,
      lastRewardTime!.millisecondsSinceEpoch,
    );

    if (!mounted) return;

    setState(() {
      rewardRemaining = const Duration(hours: 1);
    });

    _showMessage('+5 coins added!');
  }

  // ------------------------------------------------------------
  // REWARDED AD LOAD
  // ------------------------------------------------------------

  void _loadRewardedAd() {
    if (rewardedAdLoading) return;

    if (rewardedAd != null) return;

    rewardedAdLoading = true;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          rewardedAdLoading = false;

          rewardedAd = ad;

          if (mounted) {
            setState(() {});
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          rewardedAdLoading = false;
          rewardedAd = null;

          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }

  // ------------------------------------------------------------
  // INTERSTITIAL AD
  // ------------------------------------------------------------

  void _loadInterstitialAd() {
    if (interstitialAdLoading) return;

    if (interstitialAd != null) return;

    interstitialAdLoading = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          interstitialAdLoading = false;

          interstitialAd = ad;

          if (mounted) {
            setState(() {});
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          interstitialAdLoading = false;
          interstitialAd = null;

          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }

  void _showInterstitialAfterClaim() {
    final ad = interstitialAd;

    if (ad == null) {
      _loadInterstitialAd();
      return;
    }

    interstitialAd = null;

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();

        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();

        _loadInterstitialAd();
      },
    );

    ad.show();
  }

  // ------------------------------------------------------------
  // RESET TEST DATA
  // ------------------------------------------------------------

  Future<void> _resetTestData() async {
    await prefs?.remove(keyName);
    await prefs?.remove(keyBalance);
    await prefs?.remove(keyClaimTime);
    await prefs?.remove(keyRewardCount);
    await prefs?.remove(keyRewardDay);
    await prefs?.remove(keyLastRewardTime);

    if (!mounted) return;

    setState(() {
      userName = '';
      balance = 0;

      lastClaimTime = null;
      lastRewardTime = null;

      rewardCountToday = 0;
      rewardDay = '';

      claimRemaining = Duration.zero;
      rewardRemaining = Duration.zero;

      _nameController.clear();
    });

    _showMessage('Test data reset.');
  }

  // ------------------------------------------------------------
  // MESSAGE
  // ------------------------------------------------------------

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ------------------------------------------------------------
  // TIME FORMAT
  // ------------------------------------------------------------

  String _formatDuration(Duration duration) {
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

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (userName.isEmpty) {
      return _buildNamePage();
    }

    return _buildHomePage();
  }

  // ------------------------------------------------------------
  // NAME PAGE
  // ------------------------------------------------------------

  Widget _buildNamePage() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.currency_bitcoin,
                  size: 90,
                  color: Colors.amber,
                ),

                const SizedBox(height: 20),

                const Text(
                  'COIN MINER',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Welcome!',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 40),

                TextField(
                  controller: _nameController,
                  textInputAction: TextInputAction.done,
                  maxLength: 20,
                  decoration: InputDecoration(
                    labelText: 'Your name',
                    hintText: 'Enter your name',
                    errorText:
                        _nameError.isEmpty
                            ? null
                            : _nameError,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                    prefixIcon:
                        const Icon(Icons.person),
                  ),
                  onSubmitted: (_) {
                    if (!savingName) {
                      _continueWithName();
                    }
                  },
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        savingName
                            ? null
                            : _continueWithName,
                    child:
                        savingName
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'CONTINUE',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  'Coins in this app are virtual points.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // HOME PAGE
  // ------------------------------------------------------------

  Widget _buildHomePage() {
    final claimAvailable = canClaim;

    final rewardAvailable = canWatchReward;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'COIN MINER',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Reset test data',
            icon: const Icon(Icons.refresh),
            onPressed: _resetTestData,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _updateTimers();
            await _checkRewardDay();
          },
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              _buildWelcomeCard(),

              const SizedBox(height: 16),

              _buildBalanceCard(),

              const SizedBox(height: 16),

              _buildDailyClaimCard(
                claimAvailable,
              ),

              const SizedBox(height: 16),

              _buildRewardCard(
                rewardAvailable,
              ),

              const SizedBox(height: 16),

              _buildStatsCard(),

              const SizedBox(height: 20),

              const Text(
                'How it works',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              _buildInfoCard(),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // WELCOME
  // ------------------------------------------------------------

  Widget _buildWelcomeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              child: Icon(Icons.person),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      color: Colors.white60,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BALANCE
  // ------------------------------------------------------------

  Widget _buildBalanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'YOUR BALANCE',
              style: TextStyle(
                color: Colors.white60,
                letterSpacing: 2,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              balance.toStringAsFixed(0),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),

            const Text(
              'COINS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // DAILY CLAIM CARD
  // ------------------------------------------------------------

  Widget _buildDailyClaimCard(
    bool claimAvailable,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.calendar_today,
                  color: Colors.amber,
                ),

                SizedBox(width: 10),

                Text(
                  'DAILY CLAIM',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            const Text(
              'Claim 10 coins once every 24 hours.',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 18),

            if (!claimAvailable) ...[
              const Text(
                'NEXT CLAIM IN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                _formatDuration(claimRemaining),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),
            ],

            SizedBox(
              height: 58