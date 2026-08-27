import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cat_facts.dart';
import '../localization.dart';

const Color backgroundColor = Color(0xFF0B1112);
const Color cardColor = Color(0xFF151B1C);
const Color accentColor = Color(0xFF35D0A0);

// Googlen virallinen TEST Rewarded Ad -ID.
// Vaihda omaan tuotanto-ID:hen ennen julkaisemista.
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

    cooldownTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    rewardedAd?.dispose();
    cooldownTimer?.cancel();

    super.dispose();
  }

  // ==========================================================
  // DATE KEY
  // ==========================================================

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
    final prefs =
        await SharedPreferences.getInstance();

    final currentToday = _dateKey();

    final savedDailyDate =
        prefs.getString('last_daily') ?? '';

    final savedAdDate =
        prefs.getString('ad_date') ?? '';

    final lastAdString =
        prefs.getString('last_ad_time');

    DateTime? savedLastAdTime;

    if (lastAdString != null) {
      savedLastAdTime =
          DateTime.tryParse(lastAdString);
    }

    int currentAds =
        prefs.getInt('ads_today') ?? 0;

    // Uusi päivä -> mainoslaskuri nollataan.
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

    if (!mounted) return;

    setState(() {
      today = currentToday;

      stl =
          prefs.getInt('stl_balance') ?? 0;

      streak =
          prefs.getInt('streak') ?? 0;

      adsToday = currentAds;

      dailyClaimed =
          savedDailyDate == currentToday;

      lastAdTime = savedLastAdTime;

      loading = false;
    });
  }

  // ==========================================================
  // DAILY CLAIM
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

    // Päivä 1-6 = +3 STL
    // Päivä 7 tai enemmän = +7 STL
    final reward =
        newStreak >= 7 ? 7 : 3;

    final newBalance =
        stl + reward;

    await prefs.setInt(
      'stl_balance',
      newBalance,
    );

    await prefs.setInt(
      'streak',
      newStreak,
    );

    await prefs.setString(
      'last_daily',
      today,
    );

    if (!mounted) return;

    setState(() {
      stl = newBalance;
      streak = newStreak;
      dailyClaimed = true;
    });

    _message('+$reward STL! 🐱');
  }

  // ==========================================================
  // AD COOLDOWN
  // ==========================================================

  bool canWatchAd() {
    if (lastAdTime == null) {
      return true;
    }

    final nextAdTime =
        lastAdTime!.add(
      const Duration(hours: 1),
    );

    return !DateTime.now()
        .isBefore(nextAdTime);
  }

  Duration? remainingAdTime() {
    if (lastAdTime == null) {
      return null;
    }

    final nextAdTime =
        lastAdTime!.add(
      const Duration(hours: 1),
    );

    final remaining =
        nextAdTime.difference(DateTime.now());

    if (remaining <= Duration.zero) {
      return null;
    }

    return remaining;
  }

  String adCooldownText() {
    final remaining =
        remainingAdTime();

    if (remaining == null) {
      return '';
    }

    final hours =
        remaining.inHours;

    final minutes =
        remaining.inMinutes % 60;

    if (hours > 0) {
      return 'Seuraava mainos: '
          '$hours h $minutes min';
    }

    return 'Seuraava mainos: '
        '$minutes min';
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
        onAdFailedToLoad: (
          LoadAdError error,
        ) {
          if (!mounted) {
            return;
          }

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
    // Päiväraja.
    if (adsToday >= 5) {
      _message(
        t.get('dailyLimitReached'),
      );
      return;
    }

    // 1 tunnin jäähdytys.
    if (!canWatchAd()) {
      final remaining =
          remainingAdTime();

      if (remaining != null) {
        _message(
          'Seuraava mainos on saatavilla '
          '${remaining.inMinutes} minuutin kuluttua.',
        );
      }

      return;
    }

    // Mainosta ei ole vielä ladattu.
    if (rewardedAd == null) {
      _message(
        'Mainosta ladataan. '
        'Yritä hetken kuluttua.',
      );

      _loadRewardedAd();

      return;
    }

    final ad = rewardedAd!;

    rewardedAd = null;

    bool earnedReward = false;

    ad.fullScreenContentCallback =
        FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent:
          (RewardedAd ad) {
        ad.dispose();

        if (earnedReward) {
          _addAdReward();
        }

        _loadRewardedAd();
      },

      onAdFailedToShowFullScreenContent:
          (
        RewardedAd ad,
        AdError error,
      ) {
        ad.dispose();

        _loadRewardedAd();
      },
    );

    ad.show(
      onUserEarnedReward: (
        AdWithoutView ad,
        RewardItem reward,
      ) {
        earnedReward = true;
      },
    );
  }

  // ==========================================================
  // ADD AD REWARD
  // ==========================================================

  Future<void> _addAdReward() async {
    // Turvatarkistus.
    if (adsToday >= 5) {
      return;
    }

    final prefs =
        await SharedPreferences.getInstance();

    final newBalance =
        stl + 3;

    final newAdsToday =
        adsToday + 1;

    // TÄRKEÄÄ:
    // Jäähdytysaika alkaa vasta,
    // kun käyttäjä todella ansaitsee palkinnon.
    final now = DateTime.now();

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
      today,
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
    });

    _message(
      t.get('pointsAdded'),
    );
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
  // LANGUAGE DIALOG
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

                      if (!mounted) {
                        return;
                      }

                      Navigator.pop(
                        dialogContext,
                      );
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
        backgroundColor: backgroundColor,
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
        catFacts[factIndex].text(
      widget.languageCode,
    );

    final adAvailable =
        adsToday < 5 &&
            canWatchAd() &&
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
            tooltip: t.get('language'),
            icon: const Icon(
              Icons.language,
            ),
            onPressed:
                _openLanguageDialog,
          ),

          IconButton(
            tooltip: t.get('logout'),
            icon: const Icon(
              Icons.logout,
            ),
            onPressed: _logout,
          ),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,

          child: ListView(
            padding:
                const EdgeInsets.all(16),

            children: [
              // ============================================
              // USER
              // ============================================

              Card(
                color: cardColor,
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
                        style: const TextStyle(
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
                        style: const TextStyle(
                          color:
                              Colors.white60,
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
                color: cardColor,
                child: Padding(
                  padding:
                      const EdgeInsets.all(28),

                  child: Column(
                    children: [
                      Text(
                        t.get('yourBalance'),
                        style: const TextStyle(
                          color:
                              Colors.white60,
                          letterSpacing: 2,
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Text(
                        '$stl',
                        style: const TextStyle(
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
                        t.get(
                          'virtualPoints',
                        ),
                        style: const TextStyle(
                          color:
                              Colors.white54,
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
                color: cardColor,
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
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        '${t.get('streak')}: 🔥 $streak',
                        style: const TextStyle(
                          color:
                              Colors.white70,
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
                                ? t.get(
                                    'claimed',
                                  )
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
              // WATCH & EARN
              // ============================================

              Card(
                color: cardColor,
                child: Padding(
                  padding:
                      const EdgeInsets.all(20),

                  child: Column(
                    children: [
                      const Icon(
                        Icons
                            .play_circle_outline,
                        size: 42,
                        color: accentColor,
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Text(
                        t.get('watchEarn'),
                        style: const TextStyle(
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

                        style: const TextStyle(
                          color:
                              Colors.white70,
                        ),
                      ),

                      // ======================================
                      // COOLDOWN TEXT
                      // ======================================

                      if (!canWatchAd()) ...[
                        const SizedBox(
                          height: 8,
                        ),

                        Text(
                          adCooldownText(),
                          style: const TextStyle(
                            color:
                                Colors.orangeAccent,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],

                      const SizedBox(
                        height: 15,
                      ),

                      SizedBox(
                        width: double.infinity,
                        height: 52,

                        child:
                            ElevatedButton.icon(
                          onPressed:
                              adAvailable
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
                                    : !canWatchAd()
                                        ? adCooldownText()
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
                color: cardColor,
                child: Padding(
                  padding:
                      const EdgeInsets.all(22),

                  child: Column(
                    children: [
                      Text(
                        t.get('stellaFacts'),
                        style: const TextStyle(
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
                        style: const TextStyle(
                          fontSize: 16,
                          color:
                              Colors.white70,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ============================================
              // INFO
              // ============================================

              Card(
                color: cardColor,
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
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 19,
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      Text(
                        t.get(
                          'solanaToken',
                        ),
                        textAlign:
                            TextAlign.center,
                        style: const TextStyle(
                          color:
                              Colors.white70,
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Text(
                        t.get(
                          'stellaCompany',
                        ),
                        textAlign:
                            TextAlign.center,
                        style: const TextStyle(
                          color:
                              Colors.white60,
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

// ==========================================================
// CAT AVATAR
// ==========================================================

class CatAvatar extends StatelessWidget {
  final double size;

  const CatAvatar({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'stella.jpg',
        width: size,
        height: size,
        fit: BoxFit.cover,

        errorBuilder: (
          _,
          __,
          ___,
        ) {
          return Container(
            width: size,
            height: size,
            color: cardColor,
            alignment: Alignment.center,

            child: Icon(
              Icons.pets,
              size: size * 0.5,
              color: accentColor,
            ),
          );
        },
      ),
    );
  }
}