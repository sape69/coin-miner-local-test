import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MobileAds.instance.initialize();

  runApp(const StelluriiniMinerApp());
}

class StelluriiniMinerApp extends StatelessWidget {
  const StelluriiniMinerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stelluriini Miner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF101114),
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
  // Google test ad IDs.
  // Replace these with your own AdMob IDs before publishing.
  static const String rewardedAdId =
      'ca-app-pub-3940256099942544/5224354917';

  static const String interstitialAdId =
      'ca-app-pub-3940256099942544/1033173712';

  static const String nameKey = 'name';
  static const String stlKey = 'stlBalance';
  static const String claimKey = 'claimTime';
  static const String rewardTimeKey = 'rewardTime';
  static const String rewardCountKey = 'rewardCount';
  static const String rewardDayKey = 'rewardDay';

  SharedPreferences? _prefs;

  final TextEditingController _nameController =
      TextEditingController();

  Timer? _timer;
  Timer? _rewardAdRetryTimer;

  String _name = '';
  String _error = '';

  int _stl = 0;
  int _rewardCount = 0;

  DateTime? _lastClaim;
  DateTime? _lastReward;

  Duration _claimTimer = Duration.zero;
  Duration _rewardTimer = Duration.zero;

  bool _loading = true;
  bool _savingName = false;
  bool _claiming = false;
  bool _showingReward = false;

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;

  bool _loadingRewarded = false;
  bool _loadingInterstitial = false;

  @override
  void initState() {
    super.initState();

    _loadData();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) {
          return;
        }

        _updateTimers();
        _checkNewDay();
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rewardAdRetryTimer?.cancel();

    _nameController.dispose();

    _rewardedAd?.dispose();
    _interstitialAd?.dispose();

    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    _prefs = prefs;

    _name = prefs.getString(nameKey) ?? '';
    _stl = prefs.getInt(stlKey) ?? 0;
    _rewardCount = prefs.getInt(rewardCountKey) ?? 0;

    final claimMilliseconds = prefs.getInt(claimKey);

    if (claimMilliseconds != null) {
      _lastClaim = DateTime.fromMillisecondsSinceEpoch(
        claimMilliseconds,
        isUtc: true,
      );
    }

    final rewardMilliseconds = prefs.getInt(rewardTimeKey);

    if (rewardMilliseconds != null) {
      _lastReward = DateTime.fromMillisecondsSinceEpoch(
        rewardMilliseconds,
        isUtc: true,
      );
    }

    final savedDay = prefs.getString(rewardDayKey);
    final today = _today();

    if (savedDay != today) {
      _rewardCount = 0;

      await prefs.setInt(
        rewardCountKey,
        0,
      );

      await prefs.setString(
        rewardDayKey,
        today,
      );
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }

    _updateTimers();

    _loadRewardedAd();
    _loadInterstitialAd();
  }

  String _today() {
    final now = DateTime.now().toUtc();

    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Future<void> _checkNewDay() async {
    if (_prefs == null) {
      return;
    }

    final today = _today();

    final savedDay =
        _prefs!.getString(rewardDayKey);

    if (savedDay == today) {
      return;
    }

    _rewardCount = 0;

    await _prefs!.setString(
      rewardDayKey,
      today,
    );

    await _prefs!.setInt(
      rewardCountKey,
      0,
    );

    if (mounted) {
      setState(() {});
    }
  }

  void _updateTimers() {
    final now = DateTime.now().toUtc();

    Duration claim = Duration.zero;

    if (_lastClaim != null) {
      final nextClaim = _lastClaim!.add(
        const Duration(hours: 24),
      );

      if (now.isBefore(nextClaim)) {
        claim = nextClaim.difference(now);
      }
    }

    Duration reward = Duration.zero;

    if (_lastReward != null) {
      final nextReward = _lastReward!.add(
        const Duration(hours: 1),
      );

      if (now.isBefore(nextReward)) {
        reward = nextReward.difference(now);
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _claimTimer = claim;
      _rewardTimer = reward;
    });
  }

  bool get canClaim {
    return _claimTimer == Duration.zero;
  }

  bool get canReward {
    if (_rewardCount >= 5) {
      return false;
    }

    return _rewardTimer == Duration.zero;
  }

  Future<void> _continue() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _error = 'Enter your name';
      });

      return;
    }

    setState(() {
      _savingName = true;
      _error = '';
    });

    try {
      await _prefs?.setString(
        nameKey,
        name,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _name = name;
        _savingName = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _savingName = false;
        _error =
            'Could not save name. Please try again.';
      });
    }
  }

  Future<void> _claimStelluriini() async {
    if (_claiming || !canClaim) {
      return;
    }

    setState(() {
      _claiming = true;
    });

    // App-internal STL balance.
    _stl += 10;

    _lastClaim = DateTime.now().toUtc();

    await _prefs?.setInt(
      stlKey,
      _stl,
    );

    await _prefs?.setInt(
      claimKey,
      _lastClaim!.millisecondsSinceEpoch,
    );

    _updateTimers();

    if (mounted) {
      setState(() {
        _claiming = false;
      });
    }

    _message('+10 STL!');

    // Show interstitial after claiming.
    _showInterstitial();
  }

  Future<void> _watchRewardAd() async {
    if (_showingReward) {
      return;
    }

    await _checkNewDay();

    if (_rewardCount >= 5) {
      _message(
        'Daily limit reached: 5 ads.',
      );

      return;
    }

    if (!canReward) {
      _message(
        'Please wait for the 1 hour timer.',
      );

      return;
    }

    final ad = _rewardedAd;

    if (ad == null) {
      _message(
        'Advertisement is still loading. Please wait.',
      );

      _loadRewardedAd();

      return;
    }

    _rewardedAd = null;

    setState(() {
      _showingReward = true;
    });

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {},
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();

        if (mounted) {
          setState(() {
            _showingReward = false;
          });
        }

        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent:
          (ad, error) {
        ad.dispose();

        if (mounted) {
          setState(() {
            _showingReward = false;
          });

          _message(
            'Advertisement could not be shown. Please try again.',
          );
        }

        _loadRewardedAd();
      },
    );

    ad.show(
      onUserEarnedReward:
          (AdWithoutView ad, RewardItem reward) {
        _giveFiveStelluriini();
      },
    );
  }

  Future<void> _giveFiveStelluriini() async {
    await _checkNewDay();

    if (_rewardCount >= 5) {
      return;
    }

    _stl += 5;
    _rewardCount++;

    _lastReward = DateTime.now().toUtc();

    await _prefs?.setInt(
      stlKey,
      _stl,
    );

    await _prefs?.setInt(
      rewardCountKey,
      _rewardCount,
    );

    await _prefs?.setInt(
      rewardTimeKey,
      _lastReward!.millisecondsSinceEpoch,
    );

    if (!mounted) {
      return;
    }

    setState(() {});

    _updateTimers();

    _message('+5 STL!');
  }

  void _loadRewardedAd() {
    if (_loadingRewarded ||
        _rewardedAd != null) {
      return;
    }

    _rewardAdRetryTimer?.cancel();
    _rewardAdRetryTimer = null;

    _loadingRewarded = true;

    if (mounted) {
      setState(() {});
    }

    RewardedAd.load(
      adUnitId: rewardedAdId,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingRewarded = false;
          _rewardedAd = ad;

          if (mounted) {
            setState(() {});
          }
        },
        onAdFailedToLoad: (error) {
          _loadingRewarded = false;
          _rewardedAd = null;

          if (mounted) {
            setState(() {});
          }

          _rewardAdRetryTimer = Timer(
            const Duration(seconds: 5),
            () {
              if (!mounted) {
                return;
              }

              _loadRewardedAd();
            },
          );
        },
      ),
    );
  }

  void _loadInterstitialAd() {
    if (_loadingInterstitial ||
        _interstitialAd != null) {
      return;
    }

    _loadingInterstitial = true;

    InterstitialAd.load(
      adUnitId: interstitialAdId,
      request: const AdRequest(),
      adLoadCallback:
          InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          _interstitialAd = ad;

          if (mounted) {
            setState(() {});
          }
        },
        onAdFailedToLoad: (error) {
          _loadingInterstitial = false;
          _interstitialAd = null;

          if (mounted) {
            setState(() {});
          }

          Future.delayed(
            const Duration(seconds: 5),
            () {
              if (mounted) {
                _loadInterstitialAd();
              }
            },
          );
        },
      ),
    );
  }

  void _showInterstitial() {
    final ad = _interstitialAd;

    if (ad == null) {
      _loadInterstitialAd();
      return;
    }

    _interstitialAd = null;

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent:
          (ad, error) {
        ad.dispose();
        _loadInterstitialAd();
      },
    );

    ad.show();
  }

  Future<void> _resetData() async {
    await _prefs?.clear();

    _rewardedAd?.dispose();
    _rewardedAd = null;

    if (!mounted) {
      return;
    }

    setState(() {
      _name = '';
      _stl = 0;
      _rewardCount = 0;

      _lastClaim = null;
      _lastReward = null;

      _claimTimer = Duration.zero;
      _rewardTimer = Duration.zero;

      _error = '';

      _nameController.clear();
    });

    _loadRewardedAd();
    _loadInterstitialAd();

    _message('Test data reset');
  }

  void _message(String text) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  String _time(Duration duration) {
    final hours = duration.inHours
        .toString()
        .padLeft(2, '0');

    final minutes = (duration.inMinutes % 60)
        .toString()
        .padLeft(2, '0');

    final seconds = (duration.inSeconds % 60)
        .toString()
        .padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_name.isEmpty) {
      return _namePage();
    }

    return _homePage();
  }

  Widget _namePage() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                const Text(
                  '🐱',
                  style: TextStyle(
                    fontSize: 80,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'STELLURIINI',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'MINER',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Enter your name to start mining',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 35),
                TextField(
                  controller: _nameController,
                  maxLength: 20,
                  textInputAction:
                      TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Your name',
                    hintText: 'Name',
                    errorText:
                        _error.isEmpty
                            ? null
                            : _error,
                    prefixIcon:
                        const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                  onSubmitted: (_) {
                    if (!_savingName) {
                      _continue();
                    }
                  },
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed:
                        _savingName
                            ? null
                            : _continue,
                    child:
                        _savingName
                            ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'START MINING',
                              style: TextStyle(
                                fontSize: 17,
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

  Widget _homePage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'STELLURIINI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Reset test data',
            onPressed: _resetData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _welcomeCard(),
            const SizedBox(height: 15),
            _balanceCard(),
            const SizedBox(height: 15),
            _claimCard(),
            const SizedBox(height: 15),
            _rewardCard(),
            const SizedBox(height: 15),
            _statsCard(),
            const SizedBox(height: 15),
            _infoCard(),
          ],
        ),
      ),
    );
  }

  Widget _welcomeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Text(
              '🐱',
              style: TextStyle(
                fontSize: 42,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome',
                    style: TextStyle(
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _name,
                    style: const TextStyle(
                      fontSize: 23,
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

  Widget _balanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              '🐾',
              style: TextStyle(
                fontSize: 42,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'YOUR STELLURIINI',
              style: TextStyle(
                color: Colors.white60,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_stl',
              style: const TextStyle(
                fontSize: 45,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
            const Text(
              'STL',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _claimCard() {
    final available = canClaim;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Text(
                  '🐾',
                  style: TextStyle(
                    fontSize: 25,
                  ),
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
              'Claim 10 STL once every 24 hours.',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 15),
            if (!available) ...[
              const Text(
                'NEXT CLAIM IN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _time(_claimTimer),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 31,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed:
                    available && !_claiming
                        ? _claimStelluriini
                        : null,
                icon:
                    _claiming
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          '🐾',
                          style: TextStyle(
                            fontSize: 24,
                          ),
                        ),
                label: Text(
                  available
                      ? 'CLAIM +10 STL'
                      : 'CLAIMED',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rewardCard() {
    final available = canReward;
    final loading =
        _loadingRewarded ||
        _rewardedAd == null;

    String buttonText;

    if (_rewardCount >= 5) {
      buttonText = 'DAILY LIMIT';
    } else if (!canReward) {
      buttonText =
          'WAIT ${_time(_rewardTimer)}';
    } else if (loading) {
      buttonText = 'LOADING AD...';
    } else {
      buttonText = 'WATCH AD +5 STL';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.ondemand_video,
                  color: Colors.amber,
                ),
                SizedBox(width: 10),
                Text(
                  'WATCH & EARN',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Watch an advertisement and earn 5 STL.',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Today: $_rewardCount / 5',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (!available &&
                _rewardCount < 5) ...[
              const Text(
                'NEXT AD IN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _time(_rewardTimer),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (_rewardCount >= 5)
              const Padding(
                padding: EdgeInsets.only(
                  bottom: 10,
                ),
                child: Text(
                  'Daily limit reached.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.amber,
                  ),
                ),
              ),
            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed:
                    available &&
                            !loading &&
                            !_showingReward &&
                            _rewardCount < 5
                        ? _watchRewardAd
                        : null,
                icon:
                    _showingReward
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                        : loading &&
                                available
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                            : const Icon(
                              Icons.play_arrow,
                            ),
                label: Text(buttonText),
              ),
            ),
            if (available && loading)
              const Padding(
                padding: EdgeInsets.only(
                  top: 10,
                ),
                child: Text(
                  'The advertisement is loading. The button will activate automatically.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'STL BALANCE',
                    style: TextStyle(
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$_stl STL',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'ADS TODAY',
                    style: TextStyle(
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$_rewardCount / 5',
                    style: const TextStyle(
                      fontSize: 22,
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

  Widget _infoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: const [
            Text(
              '🐱',
              style: TextStyle(
                fontSize: 32,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'STELLURIINI MINER',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'STL shown in this app is currently '
              'an in-app mining balance. It is not '
              'yet automatically transferred to a '
              'Solana wallet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}