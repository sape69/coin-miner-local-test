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
          seedColor: const Color(0xFF35D0A0),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B1112),
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
  // Google AdMob TEST IDs.
  static const String rewardedAdId =
      'ca-app-pub-3940256099942544/5224354917';

  static const String interstitialAdId =
      'ca-app-pub-3940256099942544/1033173712';

  SharedPreferences? _prefs;

  final TextEditingController _nameController =
      TextEditingController();

  Timer? _timer;
  Timer? _rewardRetryTimer;
  Timer? _interstitialRetryTimer;

  String _name = '';
  String _error = '';

  int _stl = 0;

  // Mainosmäärä tänään.
  int _rewardCount = 0;

  // Daily Login -putken päivä.
  // 1 = +1 STL
  // 2 = +2 STL
  // ...
  // 7 = +7 STL
  // 8+ = aina +7 STL
  int _dailyStreak = 0;

  // Viimeisin Daily Login.
  DateTime? _lastDailyClaim;

  // Viimeisin mainospalkinto.
  DateTime? _lastReward;

  Duration _claimTimer = Duration.zero;
  Duration _rewardTimer = Duration.zero;

  bool _loading = true;
  bool _savingName = false;
  bool _claiming = false;
  bool _showingReward = false;

  bool _loadingRewarded = false;
  bool _loadingInterstitial = false;

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;

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
    _rewardRetryTimer?.cancel();
    _interstitialRetryTimer?.cancel();

    _nameController.dispose();

    _rewardedAd?.dispose();
    _interstitialAd?.dispose();

    super.dispose();
  }

  // ============================================================
  // DATA
  // ============================================================

  Future<void> _loadData() async {
    final prefs =
        await SharedPreferences.getInstance();

    _prefs = prefs;

    _name =
        prefs.getString('name') ?? '';

    _stl =
        prefs.getInt('stl') ?? 0;

    _rewardCount =
        prefs.getInt('rewardCount') ?? 0;

    _dailyStreak =
        prefs.getInt('dailyStreak') ?? 0;

    final dailyClaimMilliseconds =
        prefs.getInt('dailyClaimTime');

    if (dailyClaimMilliseconds != null) {
      _lastDailyClaim =
          DateTime.fromMillisecondsSinceEpoch(
        dailyClaimMilliseconds,
        isUtc: true,
      );
    }

    final rewardMilliseconds =
        prefs.getInt('rewardTime');

    if (rewardMilliseconds != null) {
      _lastReward =
          DateTime.fromMillisecondsSinceEpoch(
        rewardMilliseconds,
        isUtc: true,
      );
    }

    final today = _today();

    final savedDay =
        prefs.getString('rewardDay');

    if (savedDay != today) {
      _rewardCount = 0;

      await prefs.setInt(
        'rewardCount',
        0,
      );

      await prefs.setString(
        'rewardDay',
        today,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
    });

    _updateTimers();

    _loadRewardedAd();
    _loadInterstitialAd();
  }

  String _today() {
    final now =
        DateTime.now().toUtc();

    final year =
        now.year.toString().padLeft(4, '0');

    final month =
        now.month.toString().padLeft(2, '0');

    final day =
        now.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // ============================================================
  // NEW DAY
  // ============================================================

  Future<void> _checkNewDay() async {
    if (_prefs == null) {
      return;
    }

    final today = _today();

    final savedDay =
        _prefs!.getString('rewardDay');

    if (savedDay == today) {
      return;
    }

    _rewardCount = 0;

    await _prefs!.setString(
      'rewardDay',
      today,
    );

    await _prefs!.setInt(
      'rewardCount',
      0,
    );

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // DAILY LOGIN
  // ============================================================

  int get dailyReward {
    if (_dailyStreak <= 0) {
      return 1;
    }

    if (_dailyStreak >= 7) {
      return 7;
    }

    return _dailyStreak + 1;
  }

  int get displayedDay {
    if (_dailyStreak >= 7) {
      return 7;
    }

    return _dailyStreak + 1;
  }

  bool get canClaim {
    return _claimTimer == Duration.zero;
  }

  Future<void> _claimDailyLogin() async {
    if (_claiming || !canClaim) {
      return;
    }

    final now =
        DateTime.now().toUtc();

    // Jos edellinen claim oli olemassa,
    // tarkistetaan jäikö kokonainen päivä väliin.
    if (_lastDailyClaim != null) {
      final difference =
          now.difference(
        _lastDailyClaim!,
      );

      if (difference.inHours >= 48) {
        // Vähintään yksi kokonainen päivä väliin.
        _dailyStreak = 0;
      }
    }

    final reward = dailyReward;

    setState(() {
      _claiming = true;
    });

    // Kasvatetaan putkea ennen seuraavaa claimia.
    if (_dailyStreak < 7) {
      _dailyStreak++;
    }

    _stl += reward;

    _lastDailyClaim = now;

    await _prefs?.setInt(
      'stl',
      _stl,
    );

    await _prefs?.setInt(
      'dailyStreak',
      _dailyStreak,
    );

    await _prefs?.setInt(
      'dailyClaimTime',
      _lastDailyClaim!
          .millisecondsSinceEpoch,
    );

    _updateTimers();

    if (mounted) {
      setState(() {
        _claiming = false;
      });
    }

    _message(
      'Miau! +$reward STL 🐾',
      Icons.pets,
    );

    _showInterstitial();
  }

  // ============================================================
  // TIMERS
  // ============================================================

  void _updateTimers() {
    final now =
        DateTime.now().toUtc();

    Duration claim =
        Duration.zero;

    Duration reward =
        Duration.zero;

    if (_lastDailyClaim != null) {
      final nextClaim =
          _lastDailyClaim!.add(
        const Duration(hours: 24),
      );

      if (now.isBefore(nextClaim)) {
        claim =
            nextClaim.difference(now);
      }
    }

    if (_lastReward != null) {
      final nextReward =
          _lastReward!.add(
        const Duration(hours: 1),
      );

      if (now.isBefore(nextReward)) {
        reward =
            nextReward.difference(now);
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

  bool get canReward {
    return _rewardCount < 5 &&
        _rewardTimer ==
            Duration.zero;
  }

  String _formatTime(
    Duration duration,
  ) {
    final hours =
        duration.inHours
            .toString()
            .padLeft(2, '0');

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

  // ============================================================
  // NAME
  // ============================================================

  Future<void> _continue() async {
    final name =
        _nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _error =
            'Kirjoita nimesi';
      });

      return;
    }

    setState(() {
      _savingName = true;
      _error = '';
    });

    try {
      await _prefs?.setString(
        'name',
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
            'Nimen tallentaminen epäonnistui.';
      });
    }
  }

  // ============================================================
  // REWARDED AD
  // ============================================================

  Future<void> _watchRewardAd() async {
    if (_showingReward) {
      return;
    }

    await _checkNewDay();

    if (_rewardCount >= 5) {
      _message(
        'Päivän 5 mainoksen raja on täynnä.',
        Icons.pets,
      );

      return;
    }

    if (!canReward) {
      _message(
        'Odota yhden tunnin ajastimen loppuun.',
        Icons.timer,
      );

      return;
    }

    final ad = _rewardedAd;

    if (ad == null) {
      _message(
        'Mainos latautuu vielä.',
        Icons.hourglass_empty,
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
      onAdShowedFullScreenContent:
          (ad) {},

      onAdDismissedFullScreenContent:
          (ad) {
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
            'Mainoksen näyttäminen epäonnistui.',
            Icons.error,
          );
        }

        _loadRewardedAd();
      },
    );

    ad.show(
      onUserEarnedReward:
          (
        AdWithoutView ad,
        RewardItem reward,
      ) {
        _giveThreeStl();
      },
    );
  }

  Future<void> _giveThreeStl() async {
    await _checkNewDay();

    if (_rewardCount >= 5) {
      return;
    }

    // Mainoksesta +3 STL.
    _stl += 3;

    _rewardCount++;

    _lastReward =
        DateTime.now().toUtc();

    await _prefs?.setInt(
      'stl',
      _stl,
    );

    await _prefs?.setInt(
      'rewardCount',
      _rewardCount,
    );

    await _prefs?.setInt(
      'rewardTime',
      _lastReward!
          .millisecondsSinceEpoch,
    );

    if (!mounted) {
      return;
    }

    setState(() {});

    _updateTimers();

    _message(
      'Miau! +3 STL 🐾',
      Icons.pets,
    );
  }

  // ============================================================
  // REWARDED AD LOAD
  // ============================================================

  void _loadRewardedAd() {
    if (_loadingRewarded ||
        _rewardedAd != null) {
      return;
    }

    _loadingRewarded = true;

    if (mounted) {
      setState(() {});
    }

    RewardedAd.load(
      adUnitId:
          rewardedAdId,
      request:
          const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingRewarded =
              false;

          _rewardedAd = ad;

          if (mounted) {
            setState(() {});
          }
        },

        onAdFailedToLoad:
            (error) {
          _loadingRewarded =
              false;

          _rewardedAd =
              null;

          if (mounted) {
            setState(() {});
          }

          _rewardRetryTimer?.cancel();

          _rewardRetryTimer =
              Timer(
            const Duration(
              seconds: 5,
            ),
            () {
              if (mounted) {
                _loadRewardedAd();
              }
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // INTERSTITIAL AD
  // ============================================================

  void _loadInterstitialAd() {
    if (_loadingInterstitial ||
        _interstitialAd != null) {
      return;
    }

    _loadingInterstitial = true;

    InterstitialAd.load(
      adUnitId:
          interstitialAdId,
      request:
          const AdRequest(),
      adLoadCallback:
          InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial =
              false;

          _interstitialAd = ad;

          if (mounted) {
            setState(() {});
          }
        },

        onAdFailedToLoad:
            (error) {
          _loadingInterstitial =
              false;

          _interstitialAd =
              null;

          if (mounted) {
            setState(() {});
          }

          _interstitialRetryTimer
              ?.cancel();

          _interstitialRetryTimer =
              Timer(
            const Duration(
              seconds: 5,
            ),
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
    final ad =
        _interstitialAd;

    if (ad == null) {
      _loadInterstitialAd();
      return;
    }

    _interstitialAd = null;

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent:
          (ad) {
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

  // ============================================================
  // RESET
  // ============================================================

  Future<void> _resetData() async {
    await _prefs?.clear();

    _rewardedAd?.dispose();
    _rewardedAd = null;

    _interstitialAd?.dispose();
    _interstitialAd = null;

    if (!mounted) {
      return;
    }

    setState(() {
      _name = '';

      _stl = 0;

      _rewardCount = 0;

      _dailyStreak = 0;

      _lastDailyClaim = null;

      _lastReward = null;

      _claimTimer =
          Duration.zero;

      _rewardTimer =
          Duration.zero;

      _error = '';

      _nameController.clear();
    });

    _loadRewardedAd();
    _loadInterstitialAd();

    _message(
      'Testitiedot nollattu.',
      Icons.refresh,
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _message(
    String text,
    IconData icon,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                icon,
                color:
                    const Color(
                  0xFF35D0A0,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child:
                    Text(text),
              ),
            ],
          ),
          duration:
              const Duration(
            seconds: 2,
          ),
        ),
      );
  }

  // ============================================================
  // STELLA IMAGE
  // ============================================================

  Widget _stella({
    double size = 80,
  }) {
    return Container(
      width: size,
      height: size,
      decoration:
          BoxDecoration(
        shape:
            BoxShape.circle,
        border:
            Border.all(
          color:
              const Color(
            0xFF35D0A0,
          ),
          width: 3,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          'stella.jpg',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder:
              (
            context,
            error,
            stackTrace,
          ) {
            return Container(
              color:
                  const Color(
                0xFF35D0A0,
              ),
              child: Icon(
                Icons.pets,
                size:
                    size * 0.5,
                color:
                    Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    if (_name.isEmpty) {
      return _namePage();
    }

    return _homePage();
  }

  // ============================================================
  // NAME PAGE
  // ============================================================

  Widget _namePage() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.all(
              24,
            ),
            child: Column(
              children: [
                _stella(
                  size: 150,
                ),

                const SizedBox(
                  height: 18,
                ),

                const Text(
                  'STELLURIINI',
                  style:
                      TextStyle(
                    fontSize: 34,
                    fontWeight:
                        FontWeight.bold,
                    letterSpacing: 1,
                    color:
                        Color(
                      0xFF35D0A0,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                const Text(
                  'STL MINER',
                  style:
                      TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                const Text(
                  'Louhi Stelluriinia '
                  'Stellan kanssa 🐱',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        Colors.white70,
                  ),
                ),

                const SizedBox(
                  height: 28,
                ),

                TextField(
                  controller:
                      _nameController,
                  maxLength: 20,
                  textInputAction:
                      TextInputAction.done,
                  decoration:
                      InputDecoration(
                    labelText:
                        'Nimesi',
                    hintText:
                        'Kirjoita nimi',
                    errorText:
                        _error.isEmpty
                            ? null
                            : _error,
                    prefixIcon:
                        const Icon(
                      Icons.person,
                    ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        16,
                      ),
                    ),
                  ),
                  onSubmitted:
                      (_) {
                    if (!_savingName) {
                      _continue();
                    }
                  },
                ),

                const SizedBox(
                  height: 8,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height: 56,
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        _savingName
                            ? null
                            : _continue,
                    icon: _savingName
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                            ),
                          )
                        : const Icon(
                            Icons.pets,
                          ),
                    label: Text(
                      _savingName
                          ? 'TALLENNETAAN...'
                          : 'ALOITA LOUHINTA',
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 30,
                ),

                const Text(
                  'Stelluriini Miner',
                  style:
                      TextStyle(
                    color:
                        Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HOME
  // ============================================================

  Widget _homePage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'STELLURIINI',
          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip:
                'Nollaa testitiedot',
            onPressed:
                _resetData,
            icon:
                const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding:
              const EdgeInsets.all(
            16,
          ),
          children: [
            _welcomeCard(),

            const SizedBox(
              height: 14,
            ),

            _balanceCard(),

            const SizedBox(
              height: 14,
            ),

            _dailyLoginCard(),

            const SizedBox(
              height: 14,
            ),

            _rewardCard(),

            const SizedBox(
              height: 14,
            ),

            _statsCard(),

            const SizedBox(
              height: 18,
            ),

            const Text(
              'Stelluriini Miner on tällä '
              'hetkellä palkintosimulaatio. '
              'STL-saldo tallennetaan '
              'laitteelle.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    Colors.white38,
                fontSize: 12,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'Stelluriini • STL 🐾',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    Color(
                  0xFF35D0A0,
                ),
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WELCOME
  // ============================================================

  Widget _welcomeCard() {
    return Card(
      color:
          const Color(0xFF101B1D),
      child: Padding(
        padding:
            const EdgeInsets.all(
          16,
        ),
        child: Row(
          children: [
            _stella(
              size: 68,
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
                    'TERVETULOA',
                    style:
                        TextStyle(
                      color:
                          Colors.white54,
                      letterSpacing:
                          1.5,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  const Text(
                    'Stelluriini Miner 🐾',
                    style:
                        TextStyle(
                      fontSize: 21,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    _name,
                    style:
                        const TextStyle(
                      color:
                          Color(
                        0xFF35D0A0,
                      ),
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
    );
  }

  // ============================================================
  // BALANCE
  // ============================================================

  Widget _balanceCard() {
    return Card(
      color:
          const Color(0xFF101B1D),
      child: Padding(
        padding:
            const EdgeInsets.all(
          22,
        ),
        child: Column(
          children: [
            _stella(
              size: 96,
            ),

            const SizedBox(
              height: 10,
            ),

            const Text(
              'STELLA BALANCE',
              style:
                  TextStyle(
                color:
                    Colors.white54,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              '$_stl',
              style:
                  const TextStyle(
                fontSize: 46,
                fontWeight:
                    FontWeight.bold,
                color:
                    Color(
                  0xFF35D0A0,
                ),
              ),
            ),

            const Text(
              'STL',
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DAILY LOGIN CARD
  // ============================================================

  Widget _dailyLoginCard() {
    final available =
        canClaim;

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(
          20,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.pets,
                  color:
                      Color(
                    0xFF35D0A0,
                  ),
                  size: 30,
                ),

                const SizedBox(
                  width: 10,
                ),

                const Expanded(
                  child: Text(
                    'STELLA DAILY LOGIN',
                    style:
                        TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              _dailyStreak >= 7
                  ? '🔥 7 päivän putki täynnä!'
                  : 'Päivä $displayedDay / 7',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
                color:
                    Color(
                  0xFF35D0A0,
                ),
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              '+$dailyReward STL',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 32,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            const Text(
              'Paina Daily Claim joka päivä. '
              'Jos yksi päivä jää väliin, '
              'putki alkaa uudelleen päivästä 1.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    Colors.white70,
                fontSize: 13,
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            if (!available) ...[
              const Text(
                'SEURAAVA CLAIM',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  color:
                      Colors.white54,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              Text(
                _formatTime(
                  _claimTimer,
                ),
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 12,
              ),
            ],

            SizedBox(
              height: 62,
              child:
                  ElevatedButton.icon(
                onPressed:
                    available &&
                            !_claiming
                        ? _claimDailyLogin
                        : null,

                icon: _claiming
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.pets,
                        size: 28,
                      ),

                label: Text(
                  available
                      ? '🐾 CLAIM +$dailyReward STL'
                      : '🐾 TULE MYÖHEMMIN',
                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WATCH AD
  // ============================================================

  Widget _rewardCard() {
    final available =
        canReward;

    final loading =
        _loadingRewarded ||
        _rewardedAd == null;

    String buttonText;

    if (_rewardCount >= 5) {
      buttonText =
          'PÄIVÄN RAJA';
    } else if (!canReward) {
      buttonText =
          'ODOTA ${_formatTime(_rewardTimer)}';
    } else if (loading) {
      buttonText =
          'LADATAAN MAINOSTA...';
    } else {
      buttonText =
          'KATSO MAINOS +3 STL 🐾';
    }

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(
          20,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .stretch,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.ondemand_video,
                  color:
                      Color(
                    0xFF35D0A0,
                  ),
                ),

                SizedBox(
                  width: 10,
                ),

                Text(
                  'WATCH & EARN STL',
                  style:
                      TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 10,
            ),

            const Text(
              'Katso mainos ja Stella '
              'antaa sinulle 3 STL.',
              style:
                  TextStyle(
                color:
                    Colors.white70,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              'Tänään: $_rewardCount / 5 mainosta',
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            if (!available &&
                _rewardCount < 5) ...[
              const Text(
                'SEURAAVA MAINOS',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  color:
                      Colors.white54,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              Text(
                _formatTime(
                  _rewardTimer,
                ),
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize: 27,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 10,
              ),
            ],

            if (_rewardCount >= 5)
              const Padding(
                padding:
                    EdgeInsets.only(
                  bottom: 10,
                ),
                child: Text(
                  'Stella lepää tänään 🐱',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        Color(
                      0xFF35D0A0,
                    ),
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

            SizedBox(
              height: 55,
              child:
                  ElevatedButton.icon(
                onPressed:
                    available &&
                            !loading &&
                            !_showingReward &&
                            _rewardCount < 5
                        ? _watchRewardAd
                        : null,

                icon: _showingReward
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
                            width: