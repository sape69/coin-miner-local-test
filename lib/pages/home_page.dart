import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cat_facts.dart';
import '../localization.dart';
import '../widgets/cat_avatar.dart';

const Color backgroundColor = Color(0xFF0B1112);
const Color cardColor = Color(0xFF151B1C);
const Color accentColor = Color(0xFF35D0A0);

// Googlen virallinen testimainos.
// Vaihda tuotantoversiossa omaan AdMob Rewarded Ad Unit ID:hen.
const String rewardedAdUnitId =
    'ca-app-pub-3940256099942544/5224354917';

class HomePage extends StatefulWidget {
  final String languageCode;
  final Future<void> Function(String) changeLanguage;

  const HomePage({
    super.key,
    required this.languageCode,
    required this.changeLanguage,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int stl = 0;
  int streak = 0;
  int adsToday = 0;

  bool dailyClaimed = false;
  bool loading = true;
  bool adLoading = false;

  String today = '';

  DateTime? lastAdTime;

  RewardedAd? rewardedAd;

  Timer? cooldownTimer;

  AppLocalizations get t =>
      AppLocalizations(widget.languageCode);

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadRewardedAd();
    _startCooldownTimer();
  }

  @override
  void dispose() {
    rewardedAd?.dispose();
    cooldownTimer?.cancel();
    super.dispose();
  }

  String _dateKey() {
    final now = DateTime.now();

    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  // ==========================================================
  // LOAD DATA
  // ==========================================================

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final currentToday = _dateKey();

    final savedDailyDate =
        prefs.getString('last_daily') ?? '';

    final savedAdDate =
        prefs.getString('ad_date') ?? '';

    int currentAds =
        prefs.getInt('ads_today') ?? 0;

    // Nollataan päivän mainosmäärä uuden päivän alkaessa.
    if (savedAdDate != currentToday) {
      currentAds = 0;

      await prefs.setString(
        'ad_date',
        currentToday,
      );

      await prefs.setInt(
        'ads_today',
        0,
      );
    }

    final lastAdString =
        prefs.getString('last_ad_time');

    DateTime? savedLastAdTime;

    if (lastAdString != null) {
      savedLastAdTime =
          DateTime.tryParse(lastAdString);
    }

    if (!mounted) return;

    setState(() {
      today = currentToday;
      stl = prefs.getInt('stl_balance') ?? 0;
      streak = prefs.getInt('streak') ?? 0;
      adsToday = currentAds;

      dailyClaimed =
          savedDailyDate == currentToday;

      lastAdTime = savedLastAdTime;

      loading = false;
    });
  }

  // ==========================================================
  // DAILY REWARD
  // ==========================================================

  Future<void> _dailyClaim() async {
    if (dailyClaimed) {
      _message(t.get('claimed'));
      return;
    }

    final prefs =
        await SharedPreferences.getInstance();

    final lastDate =
        prefs.getString('last_daily') ?? '';

    int newStreak;

    if (lastDate.isEmpty) {
      newStreak = 1;
    } else {
      final yesterday =
          DateTime.now().subtract(
        const Duration(days: 1),
      );

      final yesterdayKey =
          '${yesterday.year}-'
          '${yesterday.month.toString().padLeft(2, '0')}-'
          '${yesterday.day.toString().padLeft(2, '0')}';

      if (lastDate == yesterdayKey) {
        newStreak = streak + 1;
      } else {
        newStreak = 1;
      }
    }

    // Streak jatkuu, mutta 7 päivän jälkeen
    // näytetään edelleen maksimi 7.
    final displayStreak =
        newStreak > 7 ? 7 : newStreak;

    // Päivittäinen palkinto.
    final reward =
        displayStreak >= 7 ? 7 : 3;

    final newBalance =
        stl + reward;

    await prefs.setInt(
      'stl_balance',
      newBalance,
    );

    await prefs.setInt(
      'streak',
      displayStreak,
    );

    await prefs.setString(
      'last_daily',
      today,
    );

    if (!mounted) return;

    setState(() {
      stl = newBalance;
      streak = displayStreak;
      dailyClaimed = true;
    });

    _message('+$reward STL! 🐱');
  }

  // ==========================================================
  // AD COOLDOWN
  // ==========================================================

  bool _canWatchAd() {
    if (lastAdTime == null) {
      return true;
    }

    final nextAdTime =
        lastAdTime!.add(
      const Duration(hours: 1),
    );

    return !DateTime.now().isBefore(nextAdTime);
  }

  Duration _remainingAdTime() {
    if (lastAdTime == null) {
      return Duration.zero;
    }

    final nextAdTime =
        lastAdTime!.add(
      const Duration(hours: 1),
    );

    final remaining =
        nextAdTime.difference(DateTime.now());

    if (remaining.isNegative) {
      return Duration.zero;
    }

    return remaining;
  }

  String _remainingAdText() {
    final remaining =
        _remainingAdTime();

    if (remaining == Duration.zero) {
      return '';
    }

    final hours =
        remaining.inHours;

    final minutes =
        remaining.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours} h ${minutes} min';
    }

    return '$minutes min';
  }

  void _startCooldownTimer() {
    cooldownTimer =
        Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (!mounted) return;

        setState(() {});
      },
    );
  }

  // ==========================================================
  // LOAD REWARDED AD
  // ==========================================================

  void _loadRewardedAd() {
    if (adLoading) {
      return;
    }

    setState(() {
      adLoading = true;
    });

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }

          setState(() {
            rewardedAd = ad;
            adLoading = false;
          });
        },
        onAdFailedToLoad:
            (LoadAdError error) {
          if (!mounted) return;

          setState(() {
            rewardedAd = null;
            adLoading = false;
          });
        },
      ),
    );
  }

  // ==========================================================
  // WATCH AD
  // ==========================================================

  Future<void> _watchAd() async {
    if (adsToday >= 5) {
      _message(
        t.get('dailyLimitReached'),
      );
      return;
    }

    if (!_canWatchAd()) {
      _message(
        'Seuraava mainos: '
        '${_remainingAdText()}',
      );
      return;
    }

    if (rewardedAd == null) {
      _message(
        'Mainosta ladataan. Yritä hetken kuluttua.',
      );

      _loadRewardedAd();

      return;
    }

    final ad = rewardedAd!;

    setState(() {
      rewardedAd = null;
    });

    bool earnedReward = false;

    ad.fullScreenContentCallback =
        FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent:
          (RewardedAd ad) async {
        ad.dispose();

        if (earnedReward) {
          await _addAdReward();
        }

        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent:
          (RewardedAd ad, AdError error) {
        ad.dispose();

        _loadRewardedAd();

        _message(
          'Mainosta ei voitu näyttää.',
        );
      },
    );

    ad.show(
      onUserEarnedReward:
          (AdWithoutView ad, RewardItem reward) {
        earnedReward = true;
      },
    );
  }

  // ==========================================================
  // ADD AD REWARD
  // ==========================================================

  Future<void> _addAdReward() async {
    if (adsToday >= 5) {
      return;
    }

    final prefs =
        await SharedPreferences.getInstance();

    final now =
        DateTime.now();

    final newBalance =
        stl + 3;

    final newAdsToday =
        adsToday + 1;

    await prefs.setInt(
      'stl_balance',
      newBalance,
    );

    await prefs.setInt(
      'ads_today',
      newAdsToday,
    );

    await prefs.setString(
      'ad_date',
      _dateKey(),
    );

    await prefs.setString(
      'last_ad_time',
      now.toIso8601String(),
    );

    if (!mounted) return;

    setState(() {
      stl = newBalance;
      adsToday = newAdsToday;
      lastAdTime = now;
      today = _dateKey();
    });

    _message(t.get('pointsAdded'));
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  // ==========================================================
  // LOGOUT
  // ==========================================================

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  // ==========================================================
  // LANGUAGE
  // ==========================================================

  void _openLanguageDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            t.get('selectLanguage'),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: AppLocalizations
                  .supportedLanguages
                  .entries
                  .map(
                (entry) {
                  return ListTile(
                    title: Text(
                      entry.value,
                    ),
                    trailing:
                        widget.languageCode ==
                                entry.key
                            ? const Icon(
                                Icons.check,
                                color: accentColor,
                              )
                            : null,
                    onTap: () async {
                      await widget.changeLanguage(
                        entry.key,
                      );

                      if (!mounted) return;

                      if (dialogContext.mounted) {
                        Navigator.pop(
                          dialogContext,
                        );
                      }
                    },
                  );
                },
              ).toList(),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: accentColor,
          ),
        ),
      );
    }

    final user =
        FirebaseAuth.instance.currentUser;

    final factIndex =
        DateTime.now().day %
            catFacts.length;

    final fact =
        catFacts[factIndex]
            .text(widget.languageCode);

    final canWatch =
        _canWatchAd();

    final remainingText =
        _remainingAdText();

    final adButtonEnabled =
        adsToday < 5 &&
            canWatch &&
            rewardedAd != null &&
            !adLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'STELLURIINI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Vaihda kieli',
            icon: const Icon(Icons.language),
            onPressed: _openLanguageDialog,
          ),
          IconButton(
            tooltip: 'Kirjaudu ulos',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ============================================
              // USER
              // ============================================

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const CatAvatar(
                        size: 110,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      Text(
                        t.get('stella'),
                        style:
                            const TextStyle(
                          fontSize: 24,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        user?.email ?? '',
                        style:
                            const TextStyle(
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ============================================
              // BALANCE
              // ============================================

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      Text(
                        t.get('yourBalance'),
                        style:
                            const TextStyle(
                          color: Colors.white60,
                          letterSpacing: 2,
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Text(
                        '$stl',
                        style:
                            const TextStyle(
                          fontSize: 56,
                          fontWeight:
                              FontWeight.bold,
                          color: accentColor,
                        ),
                      ),

                      const Text(
                        'STL',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Text(
                        t.get('virtualPoints'),
                        style:
                            const TextStyle(
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ============================================
              // DAILY REWARD
              // ============================================

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.card_giftcard,
                        size: 42,
                        color: accentColor,
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Text(
                        t.get('dailyClaim'),
                        style:
                            const TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        '${t.get('streak')}: 🔥 $streak / 7',
                        style:
                            const TextStyle(
                          color: Colors.white70,
                        ),
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child:
                            ElevatedButton.icon(
                          onPressed:
                              dailyClaimed
                                  ? null
                                  : _dailyClaim,
                          icon: const Icon(
                            Icons.redeem,
                          ),
                          label: Text(
                            dailyClaimed
                                ? t.get('claimed')
                                : t.get(
                                    'dailyReward',
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ============================================
              // WATCH AD
              // ============================================

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.play_circle_outline,
                        size: 42,
                        color: accentColor,
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Text(
                        t.get('watchEarn'),
                        style:
                            const TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        '${t.get('dailyLimit')}: '
                        '$adsToday / 5',
                        style:
                            const TextStyle(
                          color: Colors.white70,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      if (adsToday < 5 &&
                          !canWatch)
                        Text(
                          '${t.get('nextAd')}: '
                          '$remainingText',
                          style:
                              const TextStyle(
                            color: Colors.orangeAccent,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                      const SizedBox(
                        height: 15,
                      ),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child:
                            ElevatedButton.icon(
                          onPressed:
                              adButtonEnabled
                                  ? _watchAd
                                  : null,
                          icon: adLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        Colors.black,
                                  ),
                                )
                              : const Icon(
                                  Icons.play_arrow,
                                ),
                          label: Text(
                            adLoading
                                ? t.get(
                                    'adLoading',
                                  )
                                : adsToday >= 5
                                    ? t.get(
                                        'dailyLimitReached',
                                      )
                                    : !canWatch
                                        ? '${t.get('nextAd')}: '
                                            '$remainingText'
                                        : rewardedAd ==
                                                null
                                            ? t.get(
                                                'adUnavailable',
                                              )
                                            : t.get(
                                                'watchAd',
                                              ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ============================================
              // CAT FACT
              // ============================================

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      Text(
                        t.get('stellaFacts'),
                        style:
                            const TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      const Icon(
                        Icons.pets,
                        size: 45,
                        color: accentColor,
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      Text(
                        fact,
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ============================================
              // INFORMATION
              // ============================================

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 38,
                        color: accentColor,
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Text(
                        t.get('info'),
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 19,
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      Text(
                        t.get('solanaToken'),
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          color: Colors.white70,
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Text(
                        t.get('stellaCompany'),
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}