import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';
import 'cat_facts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MobileAds.instance.initialize();

  runApp(const StelluriiniApp());
}

// ==========================================================
// APP
// ==========================================================

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
        scaffoldBackgroundColor: const Color(0xFF0B1112),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF35D0A0),
          brightness: Brightness.dark,
        ),
      ),
      home: const HomePage(),
    );
  }
}

// ==========================================================
// HOME
// ==========================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ========================================================
  // TEST ADS
  // ========================================================

  static const String rewardedAdId =
      'ca-app-pub-3940256099942544/5224354917';

  static const String interstitialAdId =
      'ca-app-pub-3940256099942544/1033173712';

  // Lisää oikea mint address tähän myöhemmin.
  static const String stelluriiniMint = '';

  // ========================================================
  // STORAGE KEYS
  // ========================================================

  static const String stlKey = 'stl';
  static const String streakKey = 'streak';
  static const String lastDailyKey = 'lastDaily';
  static const String adsKey = 'adsToday';
  static const String lastAdKey = 'lastAd';
  static const String factKey = 'factDay';
  static const String dateKey = 'currentDate';
  static const String languageKey = 'language';

  SharedPreferences? prefs;

  RewardedAd? rewardedAd;
  InterstitialAd? interstitialAd;

  Timer? timer;

  int stl = 0;
  int streak = 0;
  int adsToday = 0;
  int factDay = 1;

  String selectedLanguage = 'fi';

  DateTime? lastDaily;
  DateTime? lastAd;

  Duration dailyTimer = Duration.zero;
  Duration adTimer = Duration.zero;

  bool loading = true;
  bool loadingRewarded = false;
  bool loadingInterstitial = false;
  bool showingAd = false;

  // ========================================================
  // LOCALIZATION
  // ========================================================

  AppLocalizations get t =>
      AppLocalizations(selectedLanguage);

  // ========================================================
  // INIT
  // ========================================================

  @override
  void initState() {
    super.initState();

    _loadData();

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        _updateTimers();
        _checkNewDay();
      },
    );
  }

  // ========================================================
  // DISPOSE
  // ========================================================

  @override
  void dispose() {
    timer?.cancel();
    rewardedAd?.dispose();
    interstitialAd?.dispose();
    super.dispose();
  }

  // ========================================================
  // LOAD DATA
  // ========================================================

  Future<void> _loadData() async {
    prefs = await SharedPreferences.getInstance();

    stl = prefs!.getInt(stlKey) ?? 0;
    streak = prefs!.getInt(streakKey) ?? 0;
    adsToday = prefs!.getInt(adsKey) ?? 0;
    factDay = prefs!.getInt(factKey) ?? 1;

    selectedLanguage =
        prefs!.getString(languageKey) ?? 'fi';

    if (!AppLocalizations.supportedLanguages
        .containsKey(selectedLanguage)) {
      selectedLanguage = 'fi';
    }

    if (factDay < 1) {
      factDay = 1;
    }

    // ------------------------------------------------------
    // LAST DAILY
    // ------------------------------------------------------

    final dailyMilliseconds =
        prefs!.getInt(lastDailyKey);

    if (dailyMilliseconds != null) {
      lastDaily = DateTime.fromMillisecondsSinceEpoch(
        dailyMilliseconds,
        isUtc: true,
      );
    }

    // ------------------------------------------------------
    // LAST AD
    // ------------------------------------------------------

    final adMilliseconds =
        prefs!.getInt(lastAdKey);

    if (adMilliseconds != null) {
      lastAd = DateTime.fromMillisecondsSinceEpoch(
        adMilliseconds,
        isUtc: true,
      );
    }

    await _checkNewDay();

    if (!mounted) return;

    setState(() {
      loading = false;
    });

    _updateTimers();

    _loadRewardedAd();
    _loadInterstitialAd();
  }

  // ========================================================
  // DATE
  // ========================================================

  String _today() {
    final now = DateTime.now();

    final year =
        now.year.toString().padLeft(4, '0');

    final month =
        now.month.toString().padLeft(2, '0');

    final day =
        now.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // ========================================================
  // NEW DAY
  // ========================================================

  Future<void> _checkNewDay() async {
    if (prefs == null) return;

    final today = _today();

    final saved =
        prefs!.getString(dateKey);

    if (saved == null) {
      await prefs!.setString(
        dateKey,
        today,
      );
      return;
    }

    if (saved == today) {
      return;
    }

    adsToday = 0;

    await prefs!.setString(
      dateKey,
      today,
    );

    await prefs!.setInt(
      adsKey,
      0,
    );

    if (mounted) {
      setState(() {});
    }
  }

  // ========================================================
  // TIMERS
  // ========================================================

  void _updateTimers() {
    final now = DateTime.now().toUtc();

    // ------------------------------------------------------
    // DAILY TIMER
    // ------------------------------------------------------

    Duration daily = Duration.zero;

    if (lastDaily != null) {
      final nextDaily = lastDaily!.add(
        const Duration(hours: 24),
      );

      if (now.isBefore(nextDaily)) {
        daily = nextDaily.difference(now);
      }
    }

    // ------------------------------------------------------
    // AD TIMER
    // ------------------------------------------------------

    Duration ad = Duration.zero;

    if (lastAd != null) {
      final nextAd = lastAd!.add(
        const Duration(hours: 1),
      );

      if (now.isBefore(nextAd)) {
        ad = nextAd.difference(now);
      }
    }

    if (!mounted) return;

    setState(() {
      dailyTimer = daily;
      adTimer = ad;
    });
  }

  // ========================================================
  // CAN DAILY
  // ========================================================

  bool get canDaily {
    return dailyTimer == Duration.zero;
  }

  // ========================================================
  // CAN AD
  // ========================================================

  bool get canAd {
    return adsToday < 5 &&
        adTimer == Duration.zero;
  }

  // ========================================================
  // DAILY REWARD
  // ========================================================

  int get dailyReward {
    if (streak >= 7) {
      return 7;
    }

    return streak + 1;
  }

  // ========================================================
  // CURRENT FACT
  // ========================================================

  String get currentFact {
    if (catFacts.isEmpty) {
      return '🐱 Stella';
    }

    final index =
        (factDay - 1) % catFacts.length;

    return catFacts[index].text(
      selectedLanguage,
    );
  }

  // ========================================================
  // TIME
  // ========================================================

  String _time(Duration duration) {
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

  // ========================================================
  // CHANGE LANGUAGE
  // ========================================================

  Future<void> _changeLanguage(
    String language,
  ) async {
    if (prefs == null) return;

    await prefs!.setString(
      languageKey,
      language,
    );

    if (!mounted) return;

    setState(() {
      selectedLanguage = language;
    });

    _showMessage(
      t.get('languageChanged'),
    );
  }

  // ========================================================
  // SETTINGS
  // ========================================================

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151B1C),
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              10,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  t.get('settings'),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  t.get('selectLanguage'),
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 18),

                ...AppLocalizations
                    .supportedLanguages
                    .entries
                    .map(
                  (entry) {
                    final isSelected =
                        entry.key ==
                            selectedLanguage;

                    return ListTile(
                      contentPadding:
                          EdgeInsets.zero,

                      leading: Text(
                        entry.value
                            .substring(0, 2),
                        style:
                            const TextStyle(
                          fontSize: 25,
                        ),
                      ),

                      title: Text(
                        entry.value
                            .substring(3),
                      ),

                      trailing: isSelected
                          ? const Icon(
                              Icons
                                  .check_circle,
                              color:
                                  Color(
                                0xFF35D0A0,
                              ),
                            )
                          : null,

                      onTap: () {
                        Navigator.pop(
                          sheetContext,
                        );

                        _changeLanguage(
                          entry.key,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ========================================================
  // DAILY CLAIM
  // ========================================================

  Future<void> _claimDaily() async {
    if (!canDaily || prefs == null) {
      return;
    }

    final now = DateTime.now().toUtc();

    // ------------------------------------------------------
    // RESET STREAK IF MORE THAN 48 HOURS
    // ------------------------------------------------------

    if (lastDaily != null) {
      final hours =
          now.difference(lastDaily!).inHours;

      if (hours >= 48) {
        streak = 0;
      }
    }

    // ------------------------------------------------------
    // INCREASE STREAK
    // ------------------------------------------------------

    if (streak < 7) {
      streak++;
    }

    final reward = dailyReward;

    stl += reward;

    lastDaily = now;

    factDay++;

    if (factDay < 1) {
      factDay = 1;
    }

    // ------------------------------------------------------
    // SAVE
    // ------------------------------------------------------

    await prefs!.setInt(
      stlKey,
      stl,
    );

    await prefs!.setInt(
      streakKey,
      streak,
    );

    await prefs!.setInt(
      lastDailyKey,
      now.millisecondsSinceEpoch,
    );

    await prefs!.setInt(
      factKey,
      factDay,
    );

    _updateTimers();

    if (mounted) {
      setState(() {});
    }

    _showMessage(
      '🐾 +$reward STL!',
    );

    // Näytetään interstitial vain jos se on valmis.
    _showInterstitial();
  }

  // ========================================================
  // WATCH AD
  // ========================================================

  Future<void> _watchAd() async {
    if (showingAd) {
      return;
    }

    await _checkNewDay();

    if (adsToday >= 5) {
      _showMessage(
        t.get('dailyLimitReached'),
      );
      return;
    }

    if (!canAd) {
      _showMessage(
        '${t.get('waitMessage')} ${_time(adTimer)}',
      );
      return;
    }

    final ad = rewardedAd;

    if (ad == null) {
      _showMessage(
        t.get('adLoading'),
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
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();

        showingAd = false;

        if (mounted) {
          setState(() {});
        }

        _loadRewardedAd();
      },

      onAdFailedToShowFullScreenContent:
          (ad, error) {
        ad.dispose();

        showingAd = false;

        if (mounted) {
          setState(() {});
        }

        _showMessage(
          t.get('adFailed'),
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

  // ========================================================
  // GIVE STL
  // ========================================================

  Future<void> _giveThreeStl() async {
    if (prefs == null) {
      return;
    }

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
      adsKey,
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
      t.get('pointsAdded'),
    );
  }

  // ========================================================
  // LOAD REWARDED
  // ========================================================

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

  // ========================================================
  // LOAD INTERSTITIAL
  // ========================================================

  void _loadInterstitialAd() {
    if (loadingInterstitial ||
        interstitialAd != null) {
      return;
    }

    loadingInterstitial = true;

    if (mounted) {
      setState(() {});
    }

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

  // ========================================================
  // SHOW INTERSTITIAL
  // ========================================================

  void _showInterstitial() {
    final ad = interstitialAd;

    if (ad == null) {
      _loadInterstitialAd();
      return;
    }

    interstitialAd = null;

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

  // ========================================================
  // MESSAGE
  // ========================================================

  void _showMessage(String text) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration:
              const Duration(seconds: 2),
        ),
      );
  }

  // ========================================================
  // BUILD
  // ========================================================

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
        title: Text(
          t.get('appTitle').toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),

        centerTitle: true,

        actions: [
          IconButton(
            tooltip: t.get('settings'),
            icon: const Icon(
              Icons.settings,
            ),
            onPressed: _openSettings,
          ),
        ],
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _stellaCard(),

            const SizedBox(height: 14),

            _balanceCard(),

            const SizedBox(height: 14),

            _dailyCard(),

            const SizedBox(height: 14),

            _adCard(),

            const SizedBox(height: 14),

            _factCard(),

            const SizedBox(height: 14),

            _statsCard(),

            const SizedBox(height: 14),

            _infoCard(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ========================================================
  // STELLA CARD
  // ========================================================

  Widget _stellaCard() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/stella.jpg',
                width: 120,
                height: 120,
                fit: BoxFit.cover,

                errorBuilder:
                    (context, error, stackTrace) {
                  return const CircleAvatar(
                    radius: 60,
                    child: Icon(
                      Icons.pets,
                      size: 55,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'STELLURIINI',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'STL',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              t.get('stella'),
              style: const TextStyle(
                color: Color(0xFF35D0A0),
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================
  // BALANCE
  // ========================================================

  Widget _balanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              t.get('yourBalance'),
              style: const TextStyle(
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

  // ========================================================
  // DAILY CARD
  // ========================================================

  Widget _dailyCard() {
    final int currentDay =
        streak >= 7 ? 7 : streak + 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.card_giftcard,
                  color: Color(0xFF35D0A0),
                  size: 30,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    t.get('dailyClaim'),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              streak >= 7
                  ? t.get('sevenDayStreak')
                  : '${t.get('day')} $currentDay / 7',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children:
                  List.generate(7, (index) {
                final int day = index + 1;

                final bool completed =
                    streak >= day;

                final bool today =
                    !completed &&
                        day == currentDay;

                return Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 2,
                    ),
                    child: Container(
                      height: 82,

                      decoration:
                          BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),

                        border: Border.all(
                          color: today ||
                                  completed
                              ? const Color(
                                  0xFF35D0A0,
                                )
                              : Colors.white12,

                          width:
                              today ? 2 : 1,
                        ),

                        color: today
                            ? const Color(
                                0xFF35D0A0,
                              ).withValues(
                                alpha: 0.18,
                              )
                            : completed
                                ? const Color(
                                    0xFF35D0A0,
                                  ).withValues(
                                    alpha: 0.10,
                                  )
                                : Colors.white
                                    .withValues(
                                    alpha: 0.04,
                                  ),
                      ),

                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Text(
                            completed
                                ? '✓'
                                : today
                                    ? '🎁'
                                    : '🔒',
                            style:
                                const TextStyle(
                              fontSize: 20,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            '${t.get('day')} $day',
                            style:
                                TextStyle(
                              fontSize: 9,
                              fontWeight:
                                  FontWeight.bold,
                              color: today
                                  ? Colors.white
                                  : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            Container(
              padding:
                  const EdgeInsets.all(14),

              decoration:
                  BoxDecoration(
                borderRadius:
                    BorderRadius.circular(14),

                color:
                    const Color(0xFF35D0A0)
                        .withValues(
                  alpha: 0.10,
                ),
              ),

              child: Column(
                children: [
                  Text(
                    streak >= 7
                        ? '🔥 7+ ${t.get('streak')}'
                        : t.get('dailyReward'),
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF35D0A0),
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '$dailyReward STL',
                    style:
                        const TextStyle(
                      fontSize: 26,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  if (streak >= 7)
                    Text(
                      t.get(
                        'sevenDayReward',
                      ),
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color:
                            Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

            if (!canDaily) ...[
              const SizedBox(height: 14),

              Text(
                t.get('nextClaim'),
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color: Colors.white54,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                _time(dailyTimer),
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),
            ],

            const SizedBox(height: 14),

            SizedBox(
              height: 58,
              child: ElevatedButton.icon(
                onPressed:
                    canDaily
                        ? _claimDaily
                        : null,

                icon: const Icon(
                  Icons.card_giftcard,
                  size: 27,
                ),

                label: Text(
                  canDaily
                      ? '${t.get('dailyClaim')} +$dailyReward STL'
                      : t.get('claimed'),
                ),
              ),
            ),

            const SizedBox(height: 14),

            Text(
              '🎁 ${t.get('day')} 1 → 1 STL\n'
              '🎁 ${t.get('day')} 2 → 2 STL\n'
              '🎁 ${t.get('day')} 3 → 3 STL\n'
              '🎁 ${t.get('day')} 4 → 4 STL\n'
              '🎁 ${t.get('day')} 5 → 5 STL\n'
              '🎁 ${t.get('day')} 6 → 6 STL\n'
              '🎁 ${t.get('day')} 7 → 7 STL',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              t.get('sevenDayReward'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF35D0A0),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              t.get('dailyAd'),
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

  // ========================================================
  // AD CARD
  // ========================================================

  Widget _adCard() {
    String buttonText;

    if (adsToday >= 5) {
      buttonText =
          t.get('dailyLimit');
    } else if (!canAd) {
      buttonText =
          '${t.get('wait')} ${_time(adTimer)}';
    } else if (rewardedAd == null) {
      buttonText =
          t.get('loadingAd');
    } else {
      buttonText =
          'WATCH AD +3 STL';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.ondemand_video,
                  color: Color(0xFF35D0A0),
                ),

                const SizedBox(width: 10),

                Text(
                  t.get('watchEarn'),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              t.get('watchAdReward'),
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '${t.get('today')}: $adsToday / 5',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed:
                    canAd &&
                            rewardedAd != null &&
                            !showingAd
                        ? _watchAd
                        : null,

                icon: const Icon(
                  Icons.play_arrow,
                ),

                label: Text(
                  buttonText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================
  // FACT CARD
  // ========================================================

  Widget _factCard() {
    final factNumber =
        ((factDay - 1) % catFacts.length) + 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.pets,
                  color: Color(0xFF35D0A0),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    t.get('stellaFacts'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              '${t.get('day')} $factNumber / ${catFacts.length}',
              style: const TextStyle(
                color: Color(0xFF35D0A0),
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

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

  // ========================================================
  // STATS
  // ========================================================

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
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Column(
                children: [
                  Text(
                    t.get('streak'),
                    style: const TextStyle(
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
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Column(
                children: [
                  Text(
                    t.get('ads'),
                    style: const TextStyle(
                      color: Colors.white54,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '$adsToday / 5',
                    style: const TextStyle(
                      fontSize: 23,
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

  // ========================================================
  // INFO
  // ========================================================

  Widget _infoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              t.get('info'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              t.get('solanaToken'),
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              t.get('stellaCompany'),
              style: const TextStyle(
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
              ),
            ],
          ],
        ),
      ),
    );
  }
}