import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF35D0A0),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B1112),
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
  // Google AdMob test ID.
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

  // Daily Login:
  // 0 = ei vielä claimattu
  // 1 = seuraava claim on päivä 1
  // ...
  // 6 = seuraava claim on päivä 7
  // 7 = seuraava claim antaa edelleen 7 STL
  int _dailyStreak = 0;

  // Kuinka monta mainosta katsottu tänään.
  int _adsToday = 0;

  DateTime? _lastDailyClaim;
  DateTime? _lastAdReward;

  Duration _dailyTimer = Duration.zero;
  Duration _adTimer = Duration.zero;

  bool _loading = true;
  bool _savingName = false;
  bool _claiming = false;
  bool _showingAd = false;

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
        if (!mounted) return;

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
    final prefs = await SharedPreferences.getInstance();

    _prefs = prefs;

    _name = prefs.getString('name') ?? '';
    _stl = prefs.getInt('stl') ?? 0;
    _dailyStreak = prefs.getInt('dailyStreak') ?? 0;
    _adsToday = prefs.getInt('adsToday') ?? 0;

    final dailyTime = prefs.getInt('dailyClaimTime');

    if (dailyTime != null) {
      _lastDailyClaim =
          DateTime.fromMillisecondsSinceEpoch(
        dailyTime,
        isUtc: true,
      );
    }

    final adTime = prefs.getInt('adRewardTime');

    if (adTime != null) {
      _lastAdReward =
          DateTime.fromMillisecondsSinceEpoch(
        adTime,
        isUtc: true,
      );
    }

    await _checkNewDay();

    if (!mounted) return;

    setState(() {
      _loading = false;
    });

    _updateTimers();

    _loadRewardedAd();
    _loadInterstitialAd();
  }

  String _today() {
    final now = DateTime.now().toUtc();

    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _checkNewDay() async {
    if (_prefs == null) return;

    final today = _today();
    final savedDay = _prefs!.getString('savedDay');

    if (savedDay == today) {
      return;
    }

    // Uusi päivä:
    // mainosten päivittäinen määrä nollataan.
    _adsToday = 0;

    await _prefs!.setString(
      'savedDay',
      today,
    );

    await _prefs!.setInt(
      'adsToday',
      0,
    );

    // Jos viimeisestä Daily Claimistä on vähintään 48 h,
    // käyttäjä jätti kokonaisen päivän väliin.
    if (_lastDailyClaim != null) {
      final difference = DateTime.now()
          .toUtc()
          .difference(_lastDailyClaim!);

      if (difference.inHours >= 48) {
        _dailyStreak = 0;

        await _prefs!.setInt(
          'dailyStreak',
          0,
        );
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // DAILY LOGIN
  // ============================================================

  int get nextDailyReward {
    if (_dailyStreak >= 7) {
      return 7;
    }

    return _dailyStreak + 1;
  }

  int get shownStreak {
    if (_dailyStreak >= 7) {
      return 7;
    }

    return _dailyStreak;
  }

  bool get canDailyClaim {
    return _dailyTimer == Duration.zero;
  }

  Future<void> _claimDaily() async {
    if (_claiming || !canDailyClaim) {
      return;
    }

    await _checkNewDay();

    final now = DateTime.now().toUtc();

    // Jos viimeisestä claimistä on vähintään 48 h,
    // putki alkaa uudestaan päivästä 1.
    if (_lastDailyClaim != null) {
      final difference =
          now.difference(_lastDailyClaim!);

      if (difference.inHours >= 48) {
        _dailyStreak = 0;
      }
    }

    final reward = nextDailyReward;

    setState(() {
      _claiming = true;
    });

    _stl += reward;

    if (_dailyStreak < 7) {
      _dailyStreak++;
    }

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
      now.millisecondsSinceEpoch,
    );

    _updateTimers();

    if (!mounted) return;

    setState(() {
      _claiming = false;
    });

    _showMessage(
      'Miau! +$reward STL 🐾',
      Icons.pets,
    );

    _showInterstitial();
  }

  // ============================================================
  // TIMERS
  // ============================================================

  void _updateTimers() {
    final now = DateTime.now().toUtc();

    Duration daily = Duration.zero;
    Duration ad = Duration.zero;

    if (_lastDailyClaim != null) {
      final next =
          _lastDailyClaim!.add(
        const Duration(hours: 24),
      );

      if (now.isBefore(next)) {
        daily = next.difference(now);
      }
    }

    if (_lastAdReward != null) {
      final next =
          _lastAdReward!.add(
        const Duration(hours: 1),
      );

      if (now.isBefore(next)) {
        ad = next.difference(now);
      }
    }

    if (!mounted) return;

    setState(() {
      _dailyTimer = daily;
      _adTimer = ad;
    });
  }

  bool get canWatchAd {
    return _adsToday < 5 &&
        _adTimer == Duration.zero;
  }

  String _formatTime(Duration time) {
    final hours = time.inHours
        .toString()
        .padLeft(2, '0');

    final minutes = (time.inMinutes % 60)
        .toString()
        .padLeft(2, '0');

    final seconds = (time.inSeconds % 60)
        .toString()
        .padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  // ============================================================
  // NAME
  // ============================================================

  Future<void> _continue() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _error = 'Kirjoita nimesi';
      });

      return;
    }

    setState(() {
      _savingName = true;
      _error = '';
    });

    await _prefs?.setString(
      'name',
      name,
    );

    if (!mounted) return;

    setState(() {
      _name = name;
      _savingName = false;
    });
  }

  // ============================================================
  // REWARDED AD
  // ============================================================

  Future<void> _watchAd() async {
    if (_showingAd) return;

    await _checkNewDay();

    if (_adsToday >= 5) {
      _showMessage(
        'Päivän 5 mainoksen raja on täynnä.',
        Icons.pets,
      );
      return;
    }

    if (!canWatchAd) {
      _showMessage(
        'Odota ${_formatTime(_adTimer)}.',
        Icons.timer,
      );
      return;
    }

    final ad = _rewardedAd;

    if (ad == null) {
      _showMessage(
        'Mainos latautuu vielä.',
        Icons.hourglass_empty,
      );

      _loadRewardedAd();
      return;
    }

    _rewardedAd = null;

    setState(() {
      _showingAd = true;
    });

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();

        if (mounted) {
          setState(() {
            _showingAd = false;
          });
        }

        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent:
          (ad, error) {
        ad.dispose();

        if (mounted) {
          setState(() {
            _showingAd = false;
          });

          _showMessage(
            'Mainoksen näyttäminen epäonnistui.',
            Icons.error,
          );
        }

        _loadRewardedAd();
      },
    );

    ad.show(
      onUserEarnedReward:
          (AdWithoutView ad, RewardItem reward) {
        _giveThreeStl();
      },
    );
  }

  Future<void> _giveThreeStl() async {
    await _checkNewDay();

    if (_adsToday >= 5) return;

    _stl += 3;
    _adsToday++;

    _lastAdReward =
        DateTime.now().toUtc();

    await _prefs?.setInt(
      'stl',
      _stl,
    );

    await _prefs?.setInt(
      'adsToday',
      _adsToday,
    );

    await _prefs?.setInt(
      'adRewardTime',
      _lastAdReward!.millisecondsSinceEpoch,
    );

    _updateTimers();

    if (!mounted) return;

    setState(() {});

    _showMessage(
      'Miau! +3 STL 🐾',
      Icons.pets,
    );
  }

  // ============================================================
  // AD LOADING
  // ============================================================

  void _loadRewardedAd() {
    if (_loadingRewarded ||
        _rewardedAd != null) {
      return;
    }

    _loadingRewarded = true;

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

          _rewardRetryTimer?.cancel();

          _rewardRetryTimer = Timer(
            const Duration(seconds: 5),
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

          _interstitialRetryTimer?.cancel();

          _interstitialRetryTimer = Timer(
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

    if (!mounted) return;

    setState(() {
      _name = '';
      _stl = 0;
      _dailyStreak = 0;
      _adsToday = 0;

      _lastDailyClaim = null;
      _lastAdReward = null;

      _dailyTimer = Duration.zero;
      _adTimer = Duration.zero;

      _nameController.clear();
      _error = '';
    });

    _loadRewardedAd();
    _loadInterstitialAd();
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String text,
    IconData icon,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF35D0A0),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ============================================================
  // STELLA
  // ============================================================

  Widget _stella(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF35D0A0),
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
              (context, error, stackTrace) {
            return Container(
              color: const Color(0xFF35D0A0),
              child: Icon(
                Icons.pets,
                size: size * 0.5,
                color: Colors.white,
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

  // ============================================================
  // NAME PAGE
  // ============================================================

  Widget _namePage() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _stella(150),

                const SizedBox(height: 20),

                const Text(
                  'STELLURIINI',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF35D0A0),
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'STL MINER',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Louhi Stelluriinia Stellan kanssa 🐱',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 30),

                TextField(
                  controller: _nameController,
                  maxLength: 20,
                  decoration: InputDecoration(
                    labelText: 'Nimesi',
                    hintText: 'Kirjoita nimi',
                    errorText:
                        _error.isEmpty ? null : _error,
                    prefixIcon:
                        const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed:
                        _savingName ? null : _continue,
                    icon: _savingName
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.pets),
                    label: Text(
                      _savingName
                          ? 'TALLENNETAAN...'
                          : 'ALOITA LOUHINTA',
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

  // ============================================================
  // HOME
  // ============================================================

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
            tooltip: 'Nollaa testitiedot',
            onPressed: _resetData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _welcomeCard(),

            const SizedBox(height: 14),

            _balanceCard(),

            const SizedBox(height: 14),

            _dailyCard(),

            const SizedBox(height: 14),

            _adCard(),

            const SizedBox(height: 14),

            _statsCard(),

            const SizedBox(height: 20),

            const Text(
              'Stelluriini Miner on tällä hetkellä '
              'palkintosimulaatio. STL-saldo tallennetaan '
              'laitteelle.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
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
      color: const Color(0xFF101B1D),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _stella(68),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TERVETULOA',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Stelluriini Miner 🐾',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _name,
                    style: const TextStyle(
                      color: Color(0xFF35D0A0),
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

  // ============================================================
  // BALANCE
  // ============================================================

  Widget _balanceCard() {
    return Card(
      color: const Color(0xFF101B1D),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            _stella(90),

            const SizedBox(height: 10),

            const Text(
              'STELLA BALANCE',
              style: TextStyle(
                color: Colors.white54,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              '$_stl',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFF35D0A0),
              ),
            ),

            const Text(
              'STL',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DAILY LOGIN
  // ============================================================

  Widget _dailyCard() {
    final available = canDailyClaim;

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
                  Icons.pets,
                  color: Color(0xFF35D0A0),
                  size: 30,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'STELLA DAILY LOGIN',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Text(
              _dailyStreak >= 7
                  ? '🔥 7 PÄIVÄN PUTKI'
                  : '🐾 PÄIVÄ $displayedStreak / 7',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF35D0A0),
              ),
            ),

            const SizedBox(height: 5),

            Text(
              '+$nextDailyReward STL',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Paina kerran päivässä. '
              'Jos yksi päivä jää väliin, '
              'putki alkaa uudelleen päivästä 1.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 15),

            if (!available) ...[
              const Text(
                'SEURAAVA CLAIM',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                _formatTime(_dailyTimer),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),
            ],

            SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                onPressed:
                    available && !_claiming
                        ? _claimDaily
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
                      ? 'CLAIM +$nextDailyReward STL'
                      : 'TULE HUOMENNA',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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

  Widget _adCard() {
    final available = canWatchAd;

    final loading =
        _loadingRewarded ||
        _rewardedAd == null;

    String buttonText;

    if (_adsToday >= 5) {
      buttonText = 'PÄIVÄN RAJA';
    } else if (!canWatchAd) {
      buttonText =
          'ODOTA ${_formatTime(_adTimer)}';
    } else if (loading) {
      buttonText = 'LADATAAN MAINOSTA...';
    } else {
      buttonText = 'KATSO MAINOS +3 STL';
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
                  color: Color(0xFF35D0A0),
                ),
                SizedBox(width: 10),
                Text(
                  'WATCH & EARN STL',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            const Text(
              'Katso mainos ja Stella antaa '
              'sinulle 3 STL.',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Tänään: $_adsToday / 5 mainosta',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            if (!available && _adsToday < 5) ...[
              Text(
                _formatTime(_adTimer),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
            ],

            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed:
                    available &&
                            !loading &&
                            !_showingAd &&
                            _adsToday < 5
                        ? _watchAd
                        : null,
                icon: _showingAd
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : loading && available
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
                label: Text(
                  buttonText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
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
  // STATS
  // ============================================================

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
                    'STL',
                    style: TextStyle(
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$_stl',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF35D0A0),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Column(
                children: [
                  const Text(
                    'STREAK',
                    style: TextStyle(
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _dailyStreak >= 7
                        ? '7 🔥'
                        : '$_dailyStreak / 7',
                    style: const TextStyle(
                      fontSize: 23,
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
                    'ADS',
                    style: TextStyle(
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$_adsToday / 5',
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
}