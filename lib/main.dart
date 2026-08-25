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

  // Lisää oikea Stelluriinin mint address tähän myöhemmin.
  static const String stelluriiniMint = '';

  // ============================================================
  // ADMOB TEST MAINOKSET
  // ============================================================

  static const String rewardedAdId =
      'ca-app-pub-3940256099942544/5224354917';

  static const String interstitialAdId =
      'ca-app-pub-3940256099942544/1033173712';

  // ============================================================
  // TALLENNUKSEN AVAIMET
  // ============================================================

  static const String stlKey = 'stl';
  static const String streakKey = 'dailyStreak';
  static const String lastDailyKey = 'lastDaily';
  static const String adsTodayKey = 'adsToday';
  static const String lastAdKey = 'lastAd';
  static const String factDayKey = 'factDay';
  static const String currentDayKey = 'currentDay';

  SharedPreferences? prefs;

  RewardedAd? rewardedAd;
  InterstitialAd? interstitialAd;

  Timer? timer;

  int stl = 0;

  // 0 = seuraavaksi päivä 1
  // 1 = seuraavaksi päivä 2
  // ...
  // 6 = seuraavaksi päivä 7
  // 7 = 7 STL joka päivä
  int streak = 0;

  int adsToday = 0;

  // Kissafaktan päivä.
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
    'Kissat nukkuvat usein noin 12–16 tuntia vuorokaudessa.',
    'Kissan viikset ovat erittäin herkkiä tuntoelimiä.',
    'Kissan nenän kuvio on yksilöllinen.',
    'Kissat käyttävät häntäänsä tasapainon apuna.',
    'Kissan kynnet ovat sisäänvedettävät.',
    'Kissat voivat kuulla erittäin korkeita ääniä.',
    'Kissan korvat voivat liikkua eri suuntiin.',
    'Kissan kielessä on pieniä koukkumaisia nystyjä.',
    'Kissat ovat luonnostaan uteliaita eläimiä.',
    'Kissat voivat hypätä erittäin ketterästi.',
    'Kissan silmät auttavat sitä näkemään hämärässä.',
    'Kissat käyttävät hajuaistiaan ympäristön tutkimiseen.',
    'Kissat voivat oppia tunnistamaan oman nimensä.',
    'Hidas silmien räpytys voi olla kissan ystävällinen tervehdys.',
    'Kissat voivat muodostaa vahvan siteen ihmiseen.',
    'Kissan tassujen anturat ovat herkkiä.',
    'Kissat käyttävät raapimista myös ympäristön merkitsemiseen.',
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
    'Kissa voi ilmaista turvallisuutta rentoutuneella vartalolla.',
    'Kissat voivat pitää tutuista ja ennakoitavista rutiineista.',
    'Kissan tassut auttavat sitä pysähtymään ja muuttamaan suuntaa.',
    'Kissat voivat oppia, missä niiden ruoka yleensä tarjoillaan.',
    'Kissa voi osoittaa uteliaisuutta seuraamalla liikettä.',
    'Kissat voivat käyttää viiksiään myös ympäristön tunnusteluun.',
    'Kissa voi tunnistaa tutun ihmisen tuoksun.',
    'Kissat voivat viettää paljon aikaa tarkkaillen ympäristöään.',
    'Kissan kuuloalue on laaja.',
    'Kissat voivat reagoida hyvin korkeisiin ääniin.',
    'Kissa voi tutkia uuden esineen ensin haistamalla sitä.',
    'Kissat voivat oppia toistuvista palkinnoista.',
    'Kissa voi yhdistää tietyn äänen ruokaan.',
    'Kissat voivat käyttää leikkiä luonnollisten taitojen harjoitteluun.',
    'Kissa voi harjoitella hyppyjä leikin aikana.',
    'Kissat voivat olla erittäin ketteriä pienessäkin tilassa.',
    'Kissa voi tehdä nopean suunnanmuutoksen kesken juoksun.',
    'Kissat voivat käyttää kynsiään tarttumiseen.',
    'Kissa voi käyttää tassujaan tasapainon säätelyyn.',
    'Kissat voivat oppia, missä turvalliset lepopaikat sijaitsevat.',
    'Kissa voi osoittaa tyytyväisyyttä venyttelemällä.',
    'Kissat voivat nukkua monissa erilaisissa asennoissa.',
    'Kissa voi vaihtaa nukkumapaikkaa ympäristön lämpötilan mukaan.',
    'Kissat voivat käyttää turkkiaan lämmön säätelyyn.',
    'Kissa voi pörröttää turkkiaan kylmässä.',
    'Kissat nuolevat turkkiaan sen puhdistamiseksi.',
    'Kissa voi käyttää nuolemista myös rauhoittavana käyttäytymisenä.',
    'Kissat viettävät paljon aikaa itsensä hoitamiseen.',
    'Kissa voi tunnistaa oman tutun lepopaikkansa.',
    'Kissat voivat oppia, missä niiden vesipaikka sijaitsee.',
    'Kissa voi ilmaista mieltymystä tiettyyn ruokailupaikkaan.',
    'Kissat voivat pitää rutiineista, koska ne tekevät ympäristöstä ennakoitavan.',
    'Kissa voi tarkkailla ympäristöään ennen kuin lähtee liikkeelle.',
    'Kissat voivat reagoida nopeasti äkilliseen liikkeeseen.',
    'Kissa voi käyttää kuuloaan ympäristön tarkkailuun silmien lisäksi.',
  ];

  // ============================================================
  // INIT
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
    final loadedPrefs =
        await SharedPreferences.getInstance();

    prefs = loadedPrefs;

    stl = loadedPrefs.getInt(stlKey) ?? 0;
    streak = loadedPrefs.getInt(streakKey) ?? 0;
    adsToday = loadedPrefs.getInt(adsTodayKey) ?? 0;
    factDay = loadedPrefs.getInt(factDayKey) ?? 1;

    final dailyMilliseconds =
        loadedPrefs.getInt(lastDailyKey);

    if (dailyMilliseconds != null) {
      lastDaily =
          DateTime.fromMillisecondsSinceEpoch(
        dailyMilliseconds,
        isUtc: true,
      );
    }

    final adMilliseconds =
        loadedPrefs.getInt(lastAdKey);

    if (adMilliseconds != null) {
      lastAd =
          DateTime.fromMillisecondsSinceEpoch(
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

    final year =
        now.year.toString().padLeft(4, '0');

    final month =
        now.month.toString().padLeft(2, '0');

    final day =
        now.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Future<void> _checkNewDay() async {
    if (prefs == null) {
      return;
    }

    final today = _todayKey();

    final savedDay =
        prefs!.getString(currentDayKey);

    if (savedDay == null) {
      await prefs!.setString(
        currentDayKey,
        today,
      );

      return;
    }

    if (savedDay == today) {
      return;
    }

    await prefs!.setString(
      currentDayKey,
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
  // TIMERIT
  // ============================================================

  void _updateTimers() {
    final now = DateTime.now().toUtc();

    Duration daily = Duration.zero;

    if (lastDaily != null) {
      final nextDaily =
          lastDaily!.add(
        const Duration(hours: 24),
      );

      if (now.isBefore(nextDaily)) {
        daily =
            nextDaily.difference(now);
      }
    }

    Duration ad = Duration.zero;

    if (lastAd != null) {
      final nextAd =
          lastAd!.add(
        const Duration(hours: 1),
      );

      if (now.isBefore(nextAd)) {
        ad =
            nextAd.difference(now);
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

  String _formatDuration(
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
  // DAILY CLAIM
  // ============================================================

  Future<void> _claimDaily() async {
    if (!canDailyClaim ||
        dailyClaimPending ||
        prefs == null) {
      return;
    }

    final now = DateTime.now().toUtc();

    // Jos viimeisestä claimista on vähintään 48 tuntia,
    // putki aloitetaan uudestaan.
    if (lastDaily != null) {
      final difference =
          now.difference(lastDaily!).inHours;

      if (difference >= 48) {
        streak = 0;
      }
    }

    if (streak < 7) {
      streak++;
    }

    final reward =
        streak >= 7 ? 7 : streak;

    dailyClaimPending = true;

    if (mounted) {
      setState(() {});
    }

    stl += reward;

    lastDaily = now;

    // Seuraavan päivän fakta.
    factDay++;

    await prefs!.setInt(
      stlKey,
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

    if (mounted) {
      setState(() {
        dailyClaimPending = false;
      });
    }

    _showMessage(
      '🐾 Daily Claim +$reward STL!',
    );

    // Daily Claimin jälkeen interstitial-mainos.
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

      onAdDismissedFullScreenContent:
          (ad) {
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
          (
            AdWithoutView ad,
            RewardItem reward,
          ) {
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

    final now =
        DateTime.now().toUtc();

    stl += 3;
    adsToday++;
    lastAd = now;

    await prefs!.setInt(
      stlKey,
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

    _showMessage(
      '+3 STL! 🐱',
    );
  }

  // ============================================================
  // REWARDED AD
  // ============================================================

  void _loadRewardedAd() {
    if (loadingRewarded ||
        rewardedAd != null) {
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
  // INTERSTITIAL AD
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

  void _showInterstitial