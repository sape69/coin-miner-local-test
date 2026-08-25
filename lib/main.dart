import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MobileAds.instance.initialize();

  runApp(const StelluriiniApp());
}

class StelluriiniApp extends StatelessWidget {
  const StelluriiniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stelluriini',
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
  // ============================================================
  // STELLURIINI
  // ============================================================

  static const String tokenName = 'Stelluriini';
  static const String tokenSymbol = 'STL';

  // Stelluriinin mint-osoite.
  // Vaihda tähän oikea mint-osoite, jos haluat näyttää sen sovelluksessa.
  static const String stelluriiniMint = '';

  // ============================================================
  // ADMOB TEST ID
  // ============================================================

  static const String rewardedAdId =
      'ca-app-pub-3940256099942544/5224354917';

  static const String interstitialAdId =
      'ca-app-pub-3940256099942544/1033173712';

  // ============================================================
  // TALLENNUKSEN AVAIMET
  // ============================================================

  static const String coinsKey = 'stl';
  static const String streakKey = 'dailyStreak';
  static const String lastDailyKey = 'lastDaily';
  static const String adsTodayKey = 'adsToday';
  static const String lastAdKey = 'lastAd';
  static const String factDayKey = 'factDay';
  static const String nameKey = 'name';

  SharedPreferences? prefs;

  RewardedAd? rewardedAd;
  InterstitialAd? interstitialAd;

  Timer? timer;

  String name = '';

  int stl = 0;

  // 0 = päivä 1
  // 1 = päivä 2
  // ...
  // 6 = päivä 7
  // 7 = 7 STL joka päivä
  int streak = 0;

  int adsToday = 0;

  // Kasvaa joka Daily Claimin jälkeen.
  // Näin fakta vaihtuu joka päivä.
  int factDay = 1;

  DateTime? lastDaily;
  DateTime? lastAd;

  Duration dailyTimer = Duration.zero;
  Duration adTimer = Duration.zero;

  bool loading = true;
  bool loadingRewarded = false;
  bool loadingInterstitial = false;
  bool showingAd = false;
  bool dailyClaimPending = false;

  // ============================================================
  // KISSAFAKTAT
  // ============================================================

  static const List<String> catFacts = [
    'Kissat nukkuvat suuren osan päivästä.',
    'Kissan viikset ovat erittäin herkkiä tuntoelimiä.',
    'Kissan nenän kuvio on yksilöllinen.',
    'Kissat käyttävät häntäänsä tasapainon apuna.',
    'Kissan kynnet ovat sisäänvedettävät.',
    'Kissat voivat kuulla erittäin korkeita ääniä.',
    'Kissan korvat voivat liikkua lähes itsenäisesti.',
    'Kissan kielessä on pieniä koukkumaisia nystyjä.',
    'Kissat ovat luonnostaan uteliaita.',
    'Kissat voivat hypätä erittäin ketterästi.',
    'Kissan silmät auttavat sitä näkemään hämärässä.',
    'Kissat käyttävät hajuaistiaan ympäristön tutkimiseen.',
    'Kissat voivat oppia tunnistamaan oman nimensä.',
    'Hidas silmien räpytys voi olla kissan ystävällinen tervehdys.',
    'Kissat voivat muodostaa vahvan siteen ihmiseen.',
    'Kissan tassujen anturat ovat herkkiä.',
    'Kissat käyttävät raapimista myös merkitsemiseen.',
    'Kissat voivat oppia erilaisia päivittäisiä rutiineja.',
    'Kissat pitävät usein korkeista tarkkailupaikoista.',
    'Kissan häntä auttaa tasapainossa hypyn aikana.',
    'Kissat käyttävät paljon aikaa turkkinsa hoitamiseen.',
    'Kissat voivat nukkua useita lyhyitä jaksoja päivän aikana.',
    'Kissan kuulo auttaa sitä paikantamaan ääniä.',
    'Kissat voivat tunnistaa tuttuja ihmisiä hajun perusteella.',
    'Kissat voivat käyttää kehräystä viestintään.',
    'Kissa voi ilmaista luottamusta rentoutumalla ihmisen lähellä.',
    'Kissat voivat oppia palkitsemisen avulla uusia asioita.',
    'Kissan keho on erittäin joustava.',
    'Kissat ovat taitavia kiipeilijöitä.',
    'Kissat voivat seurata pieniäkin liikkeitä tarkasti.',
    'Kissan viikset auttavat sitä hahmottamaan ympäristöä.',
    'Kissat voivat käyttää tassujaan lelujen käsittelyyn.',
    'Kissat voivat oppia, missä niiden lempipaikat ovat.',
    'Kissa voi osoittaa tyytyväisyyttä venyttelemällä.',
    'Kissat voivat käyttää leikkiä liikunnan muotona.',
    'Kissat voivat oppia tunnistamaan tuttuja ääniä.',
    'Kissan pupillit muuttuvat valaistuksen mukaan.',
    'Kissat voivat käyttää korkeita paikkoja ympäristön tarkkailuun.',
    'Kissat voivat olla sekä itsenäisiä että seurallisia.',
    'Jokaisella kissalla voi olla oma persoonallisuutensa.',
    'Kissat voivat käyttää kehon asentoa viestintään.',
    'Kissan tassut auttavat sitä liikkumaan hiljaisesti.',
    'Kissat voivat oppia pieniä temppuja palkkioiden avulla.',
    'Kissa voi hieroa päätään tuttuun ihmiseen tervehtiäkseen.',
    'Kissat voivat muistaa tuttuja ympäristöjä.',
    'Kissat voivat tarkkailla ympäristöä pitkään paikallaan.',
    'Kissa voi käyttää kynsiään kiipeilyssä.',
    'Kissat voivat käyttää hajumerkkejä kommunikointiin.',
    'Kissan turkki auttaa suojaamaan ihoa.',
    'Kissat voivat oppia yhdistämään äänen tiettyyn tapahtumaan.',
  ];

  // ============================================================
  // ELINKAARI
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadData();

    timer = Timer.periodic(
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
    timer?.cancel();

    rewardedAd?.dispose();
    interstitialAd?.dispose();

    super.dispose();
  }

  // ============================================================
  // DATA
  // ============================================================

  Future<void> _loadData() async {
    final loadedPrefs = await SharedPreferences.getInstance();

    prefs = loadedPrefs;

    stl = loadedPrefs.getInt(coinsKey) ?? 0;
    streak = loadedPrefs.getInt(streakKey) ?? 0;
    adsToday = loadedPrefs.getInt(adsTodayKey) ?? 0;
    factDay = loadedPrefs.getInt(factDayKey) ?? 1;
    name = loadedPrefs.getString(nameKey) ?? '';

    final dailyMilliseconds =
        loadedPrefs.getInt(lastDailyKey);

    if (dailyMilliseconds != null) {
      lastDaily = DateTime.fromMillisecondsSinceEpoch(
        dailyMilliseconds,
        isUtc: true,
      );
    }

    final adMilliseconds =
        loadedPrefs.getInt(lastAdKey);

    if (adMilliseconds != null) {
      lastAd = DateTime.fromMillisecondsSinceEpoch(
        adMilliseconds,
        isUtc: true,
      );
    }

    await _checkNewDay();

    if (!mounted) {
      return;
    }

    setState(() {
      loading = false;
    });

    _updateTimers();
    _loadRewardedAd();
    _loadInterstitialAd();
  }

  String _todayKey() {
    final now = DateTime.now();

    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Future<void> _checkNewDay() async {
    if (prefs == null) {
      return;
    }

    final today = _todayKey();
    final savedDay = prefs!.getString('currentDay');

    if (savedDay == null) {
      await prefs!.setString('currentDay', today);
      return;
    }

    if (savedDay == today) {
      return;
    }

    // Uusi päivä.
    await prefs!.setString(
      'currentDay',
      today,
    );

    adsToday = 0;

    await prefs!.setInt(
      adsTodayKey,
      0,
    );

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // AJASTIMET
  // ============================================================

  void _updateTimers() {
    final now = DateTime.now().toUtc();

    Duration daily = Duration.zero;

    if (lastDaily != null) {
      final nextDaily = lastDaily!.add(
        const Duration(hours: 24),
      );

      if (now.isBefore(nextDaily)) {
        daily = nextDaily.difference(now);
      }
    }

    Duration ad = Duration.zero;

    if (lastAd != null) {
      final nextAd = lastAd!.add(
        const Duration(hours: 1),
      );

      if (now.isBefore(nextAd)) {
        ad = nextAd.difference(now);
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      dailyTimer = daily;
      adTimer = ad;
    });
  }

  bool get canDailyClaim {
    return dailyTimer == Duration.zero;
  }

  bool get canWatchAd {
    if (adsToday >= 5) {
      return false;
    }

    return adTimer == Duration.zero;
  }

  int get dailyReward {
    if (streak >= 7) {
      return 7;
    }

    return streak + 1;
  }

  String get currentFact {
    final index =
        (factDay - 1) % catFacts.length;

    return catFacts[index];
  }

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

  // ============================================================
  // DAILY CLAIM
  // ============================================================

  Future<void> _claimDaily() async {
    if (!canDailyClaim || dailyClaimPending) {
      return;
    }

    if (prefs == null) {
      return;
    }

    final now = DateTime.now().toUtc();

    // Tarkistetaan, jäikö edellinen päivä väliin.
    if (lastDaily != null) {
      final difference =
          now.difference(lastDaily!).inHours;

      if (difference >= 48) {
        streak = 0;
      }
    }

    if (streak >= 7) {
      streak = 7;
    } else {
      streak++;
    }

    final reward =
        streak >= 7 ? 7 : streak;

    dailyClaimPending = true;

    if (mounted) {
      setState(() {});
    }

    // Päivitetään päivittäinen tieto heti,
    // jotta samaa palkintoa ei voi hakea uudelleen.
    lastDaily = now;

    stl += reward;

    factDay++;

    await prefs!.setInt(
      coinsKey,
      stl,
    );

    await prefs!.setInt(
      streakKey,
      streak,
    );

    await prefs!.setInt(
      factDayKey,
      factDay,
    );

    await prefs!.setInt(
      lastDailyKey,
      now.millisecondsSinceEpoch,
    );

    _updateTimers();

    if (!mounted) {
      return;
    }

    setState(() {
      dailyClaimPending = false;
    });

    _showMessage(
      '🐾 Daily Claim +$reward STL!',
    );

    // Daily Claim näyttää interstitial-mainoksen.
    _showInterstitial();
  }

  // ============================================================
  // WATCH AD +3 STL
  // ============================================================

  Future<void> _watchAd() async {
    if (showingAd) {
      return;
    }

    await _checkNewDay();

    if (adsToday >= 5) {
      _showMessage(
        'Päivän mainosraja 5/5 on täynnä.',
      );
      return;
    }

    if (!canWatchAd) {
      _showMessage(
        'Odota ${_formatDuration(adTimer)}.',
      );
      return;
    }

    final ad = rewardedAd;

    if (ad == null) {
      _showMessage(
        'Mainos latautuu. Yritä hetken päästä uudelleen.',
      );

      _loadRewardedAd();
      return;
    }

    rewardedAd = null;
    showingAd = true;

    if (mounted) {
      setState(() {});
    }

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {},
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();

        if (mounted) {
          setState(() {
            showingAd = false;
          });
        }

        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent:
          (ad, error) {
        ad.dispose();

        if (mounted) {
          setState(() {
            showingAd = false;
          });
        }

        _showMessage(
          'Mainosta ei voitu näyttää.',
        );

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
    if (prefs == null) {
      return;
    }

    await _checkNewDay();

    if (adsToday >= 5) {
      return;
    }

    final now = DateTime.now().toUtc();

    stl += 3;
    adsToday++;
    lastAd = now;

    await prefs!.setInt(
      coinsKey,
      stl,
    );

    await prefs!.setInt(
      adsTodayKey,
      adsToday,
    );

    await prefs!.setInt(
      lastAdKey,
      now.millisecondsSinceEpoch,
    );

    _updateTimers();

    if (mounted) {
      setState(() {});
    }

    _showMessage('+3 STL! 🐱');
  }

  // ============================================================
  // REWARDED AD
  // ============================================================

  void _loadRewardedAd() {
    if (loadingRewarded || rewardedAd != null) {
      return;
    }

    loadingRewarded = true;

    if (mounted) {
      setState(() {});
    }

    RewardedAd.load(
      adUnitId: rewardedAdId,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          loadingRewarded = false;
          rewardedAd = ad;

          if (mounted) {
            setState(() {});
          }
        },
        onAdFailedToLoad: (error) {
          loadingRewarded = false;
          rewardedAd = null;

          if (mounted) {
            setState(() {});
          }

          Future.delayed(
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

  // ============================================================
  // INTERSTITIAL
  // ============================================================

  void _loadInterstitialAd() {
    if (loadingInterstitial ||
        interstitialAd != null) {
      return;
    }

    loadingInterstitial = true;

    InterstitialAd.load(
      adUnitId: interstitialAdId,
      request: const AdRequest(),
      adLoadCallback:
          InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          loadingInterstitial = false;
          interstitialAd = ad;

          if (mounted) {
            setState(() {});
          }
        },
        onAdFailedToLoad: (error) {
          loadingInterstitial = false;
          interstitialAd = null;

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
      onAdFailedToShowFullScreenContent:
          (ad, error) {
        ad.dispose();
        _loadInterstitialAd();
      },
    );

    ad.show();
  }

  // ============================================================
  // VIESTIT
  // ============================================================

  void _showMessage(String text) {
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

  // ============================================================
  // BUILD
  // ============================================================

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
          'STELLURIINI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _checkNewDay();
            _updateTimers();
            _loadRewardedAd();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _headerCard(),
              const SizedBox(height: 14),
              _balanceCard(),
              const SizedBox(height: 14),
              _dailyClaimCard(),
              const SizedBox(height: 14),
              _watchAdCard(),
              const SizedBox(height: 14),
              _catFactCard(),
              const SizedBox(height: 14),
              _statsCard(),
              const SizedBox(height: 14),
              _aboutCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _headerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.pets,
              size: 58,
              color: Color(0xFF35D0A0),
            ),
            const SizedBox(height: 10),
            const Text(
              'STELLURIINI',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$tokenSymbol • $tokenName',
              style: const TextStyle(
                color: Colors.white60,
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'YOUR BALANCE',
              style: TextStyle(
                color: Colors.white60,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$stl',
              style: const TextStyle(
                fontSize: 50,
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
  // DAILY CLAIM
  // ============================================================

  Widget _dailyClaimCard() {
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
                Text(
                  'DAILY CLAIM',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              streak >= 7
                  ? '7 päivän putki on täynnä!'
                  : 'Päivä ${streak + 1} / 7',
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Tämän päivän palkinto: $dailyReward STL',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 14),
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
                _formatDuration(dailyTimer),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              height: 58,
              child: ElevatedButton.icon(
                onPressed:
                    available && !dailyClaimPending
                        ? _claimDaily
                        : null,
                icon: dailyClaimPending
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.pets,
                        size: 27,
                      ),
                label: Text(
                  available
                      ? 'DAILY CLAIM +$dailyReward STL'
                      : 'CLAIMED',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '📺 Daily Claim näyttää mainoksen.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
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

  Widget _watchAdCard() {
    final available = canWatchAd;
    final adReady = rewardedAd != null;

    String buttonText;

    if (adsToday >= 5) {
      buttonText = 'DAILY LIMIT';
    } else if (!available) {
      buttonText =
          'WAIT ${_formatDuration(adTimer)}';
    } else if (!adReady) {
      buttonText = 'LOADING AD...';
    } else {
      buttonText = 'WATCH AD +3 STL';
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
                  'WATCH & EARN',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Katso mainos ja saat +3 STL.',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Today: $adsToday / 5',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed:
                    available &&
                            adReady &&
                            !showingAd &&
                            adsToday < 5
                        ? _watchAd
                        : null,
                icon: showingAd
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
          ],
        ),
      ),
    );
  }

  // ============================================================
  // KISSAFAKTA
  // ============================================================

  Widget _catFactCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.pets,
                  color: Color(0xFF35D0A0),
                ),
                SizedBox(width: 10),
                Text(
                  'STELLAN KISSAFAKTA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Päivä $factDay',
              style: const TextStyle(
                color: Color(0xFF35D0A0),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currentFact,
              style: const TextStyle(
                fontSize: 17,
                height: 1.45,
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
                    '$stl',
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
                    'STREAK',
                    style: TextStyle(
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    streak >= 7
                        ? '7+'
                        : '$streak / 7',
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
                    '$adsToday / 5',
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

  // ============================================================
  // ABOUT
  // ============================================================

  Widget _aboutCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'STELLURIINI',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Stelluriini on Solana-verkossa oleva yhteisötokeni.',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '🐱 Stella pitää sinulle seuraa louhinnan aikana!',
              style: TextStyle(
                color: Color(0xFF35D0A0),
              ),
            ),
            if (stelluriiniMint.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'Mint Address',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                stelluriiniMint,
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}