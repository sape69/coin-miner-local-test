import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cat_facts.dart';
import '../localization.dart';

import 'about/about_page.dart';
import 'home/balance_card.dart';
import 'home/cat_fact_card.dart';
import 'home/daily_reward_card.dart';
import 'home/home_drawer.dart';
import 'home/language_dialog.dart';
import 'home/profile_card.dart';
import 'home/watch_ad_card.dart';
import 'roadmap/roadmap_page.dart';
import 'token/stl_token_page.dart';
import 'whitepaper/whitepaper_page.dart';

// ============================================================
// COLORS
// ============================================================

const Color backgroundColor = Color(0xFF0B1112);
const Color cardColor = Color(0xFF151B1C);
const Color accentColor = Color(0xFF35D0A0);

// ============================================================
// ADMOB
// ============================================================

/// Googlen virallinen Rewarded Ad TEST-ID.
/// Vaihda myöhemmin oikeaan AdMob Rewarded Ad Unit ID:hen.
const String rewardedAdUnitId =
    'ca-app-pub-3940256099942544/5224354917';

// ============================================================
// REWARD SETTINGS
// ============================================================

/// Maksimimäärä mainoksia päivässä.
const int maxAdsPerDay = 5;

/// Päivittäisen palkinnon maksimi.
const int maxDailyReward = 7;

/// Mainosten välinen odotusaika.
const Duration adCooldown = Duration(hours: 1);

// ============================================================
// HOME PAGE
// ============================================================

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

// ============================================================
// HOME PAGE STATE
// ============================================================

class _HomePageState extends State<HomePage> {
  // ==========================================================
  // USER DATA
  // ==========================================================

  int stl = 0;
  int streak = 0;
  int adsToday = 0;

  bool dailyClaimed = false;
  bool loading = true;

  // ==========================================================
  // LOADING STATES
  // ==========================================================

  bool adLoading = false;
  bool dailyLoading = false;
  bool dailyAdLoading = false;

  // ==========================================================
  // DATE
  // ==========================================================

  String today = '';
  String lastDaily = '';

  // ==========================================================
  // AD STATUS
  // ==========================================================

  DateTime? lastAdTime;

  // ==========================================================
  // ADMOB
  // ==========================================================

  RewardedAd? rewardedAd;
  RewardedAd? dailyRewardedAd;

  // ==========================================================
  // TIMER
  // ==========================================================

  Timer? cooldownTimer;

  // ==========================================================
  // LOCALIZATION
  // ==========================================================

  AppLocalizations get t =>
      AppLocalizations(widget.languageCode);

  // ==========================================================
  // FIREBASE FUNCTIONS
  // ==========================================================

  FirebaseFunctions get functions =>
      FirebaseFunctions.instance;

  // ==========================================================
  // USER ID
  // ==========================================================

  String? get _uid =>
      FirebaseAuth.instance.currentUser?.uid;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _loadData();
    _loadRewardedAd();
    _loadDailyRewardedAd();
    _startCooldownTimer();
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    rewardedAd?.dispose();
    dailyRewardedAd?.dispose();
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
  // DATE ONLY
  // ==========================================================

  DateTime _dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  // ==========================================================
  // NEXT DAILY REWARD
  // ==========================================================

  int _nextDailyReward() {
    if (dailyClaimed) {
      if (streak >= maxDailyReward) {
        return maxDailyReward;
      }

      return streak;
    }

    final nextDay = streak + 1;

    if (nextDay >= maxDailyReward) {
      return maxDailyReward;
    }

    return nextDay;
  }

  // ==========================================================
  // DAILY REWARD TEXT
  // ==========================================================

  String _dailyRewardText() {
    final reward = _nextDailyReward();

    return '🎁 Tänään saat $reward STL';
  }

  // ==========================================================
  // DAILY STREAK TEXT
  // ==========================================================

  String _dailyStreakText() {
    final nextDay =
        dailyClaimed ? streak : streak + 1;

    final displayDay =
        nextDay > maxDailyReward
            ? maxDailyReward
            : nextDay;

    return '${t.get('streak')}: 🔥 '
        'Päivä $displayDay / 7';
  }

  // ==========================================================
  // LOAD DATA
  // ==========================================================

  Future<void> _loadData() async {
    if (_uid == null) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      return;
    }

    try {
      final callable = functions.httpsCallable(
        'getRewardStatus',
      );

      final result = await callable.call();

      final data = Map<String, dynamic>.from(
        result.data as Map,
      );

      final loadedBalance =
          (data['balance'] as num?)?.toInt() ?? 0;

      final loadedStreak =
          (data['streak'] as num?)?.toInt() ?? 0;

      final loadedAds =
          (data['adsToday'] as num?)?.toInt() ?? 0;

      final loadedDailyClaimed =
          data['dailyClaimed'] == true;

      final cooldownRemainingMs =
          (data['cooldownRemainingMs'] as num?)
                  ?.toInt() ??
              0;

      DateTime? loadedLastAdTime;

      if (cooldownRemainingMs > 0) {
        final elapsed =
            adCooldown.inMilliseconds -
                cooldownRemainingMs;

        loadedLastAdTime =
            DateTime.now().subtract(
          Duration(
            milliseconds: elapsed.clamp(
              0,
              adCooldown.inMilliseconds,
            ),
          ),
        );
      }

      final currentToday = _dateKey();

      String loadedLastDaily = '';

      if (loadedDailyClaimed) {
        loadedLastDaily = currentToday;
      } else {
        final prefs =
            await SharedPreferences.getInstance();

        loadedLastDaily =
            prefs.getString('last_daily') ?? '';
      }

      await _saveLocalCache(
        stlValue: loadedBalance,
        streakValue: loadedStreak,
        adsValue: loadedAds,
        lastDailyValue: loadedLastDaily,
        adDateValue: currentToday,
        lastAdTimeValue:
            loadedLastAdTime?.toIso8601String() ?? '',
      );

      if (!mounted) return;

      setState(() {
        today = currentToday;
        stl = loadedBalance;
        streak = loadedStreak;
        adsToday = loadedAds;
        dailyClaimed = loadedDailyClaimed;
        lastDaily = loadedLastDaily;
        lastAdTime = loadedLastAdTime;
        loading = false;
      });
    } on FirebaseFunctionsException {
      await _loadLocalCache();
    } catch (_) {
      await _loadLocalCache();
    }
  }

  // ==========================================================
  // SAVE LOCAL CACHE
  // ==========================================================

  Future<void> _saveLocalCache({
    required int stlValue,
    required int streakValue,
    required int adsValue,
    required String lastDailyValue,
    required String adDateValue,
    required String lastAdTimeValue,
  }) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setInt(
      'stl_balance',
      stlValue,
    );

    await prefs.setInt(
      'streak',
      streakValue,
    );

    await prefs.setInt(
      'ads_today',
      adsValue,
    );

    await prefs.setString(
      'last_daily',
      lastDailyValue,
    );

    await prefs.setString(
      'ad_date',
      adDateValue,
    );

    await prefs.setString(
      'last_ad_time',
      lastAdTimeValue,
    );
  }

  // ==========================================================
  // LOAD LOCAL CACHE
  // ==========================================================

  Future<void> _loadLocalCache() async {
    final prefs =
        await SharedPreferences.getInstance();

    final currentToday = _dateKey();

    int loadedAds =
        prefs.getInt('ads_today') ?? 0;

    int loadedStreak =
        prefs.getInt('streak') ?? 0;

    final loadedLastDaily =
        prefs.getString('last_daily') ?? '';

    final savedAdDate =
        prefs.getString('ad_date') ?? '';

    if (savedAdDate != currentToday) {
      loadedAds = 0;
    }

    if (loadedLastDaily.isNotEmpty) {
      final lastDailyDate =
          DateTime.tryParse(
        loadedLastDaily,
      );

      if (lastDailyDate != null) {
        final difference =
            _dateOnly(DateTime.now())
                .difference(
          _dateOnly(lastDailyDate),
        )
                .inDays;

        if (difference > 1) {
          loadedStreak = 0;
        }
      }
    }

    final lastAdString =
        prefs.getString('last_ad_time') ?? '';

    DateTime? loadedLastAdTime;

    if (lastAdString.isNotEmpty) {
      loadedLastAdTime =
          DateTime.tryParse(lastAdString);
    }

    if (!mounted) return;

    setState(() {
      today = currentToday;
      stl = prefs.getInt('stl_balance') ?? 0;
      streak = loadedStreak;
      adsToday = loadedAds;

      dailyClaimed =
          loadedLastDaily == currentToday;

      lastDaily = loadedLastDaily;
      lastAdTime = loadedLastAdTime;

      loading = false;
    });
  }

  // ==========================================================
  // DAILY CHECK-IN
  // ==========================================================

  Future<void> _dailyClaim() async {
    if (dailyLoading) return;

    if (dailyClaimed) {
      _message(t.get('claimed'));
      return;
    }

    setState(() {
      dailyLoading = true;
    });

    try {
      final callable =
          functions.httpsCallable(
        'dailyCheckIn',
      );

      final result =
          await callable.call();

      final data =
          Map<String, dynamic>.from(
        result.data as Map,
      );

      final alreadyClaimed =
          data['alreadyClaimed'] == true;

      final newBalance =
          (data['balance'] as num?)?.toInt() ??
              stl;

      final newStreak =
          (data['streak'] as num?)?.toInt() ??
              streak;

      final reward =
          (data['reward'] as num?)?.toInt() ?? 0;

      final currentToday = _dateKey();

      final newLastDaily =
          alreadyClaimed
              ? lastDaily
              : currentToday;

      await _saveLocalCache(
        stlValue: newBalance,
        streakValue: newStreak,
        adsValue: adsToday,
        lastDailyValue: newLastDaily,
        adDateValue: currentToday,
        lastAdTimeValue:
            lastAdTime?.toIso8601String() ?? '',
      );

      if (!mounted) return;

      setState(() {
        stl = newBalance;
        streak = newStreak;
        dailyClaimed = true;
        lastDaily = newLastDaily;
      });

      if (alreadyClaimed) {
        _message(t.get('claimed'));
      } else {
        _message('+$reward STL! 🐱');
      }
    } on FirebaseFunctionsException catch (error) {
      _message(
        error.message ??
            'Päivittäisen palkinnon hakeminen epäonnistui.',
      );
    } catch (_) {
      _message(
        'Päivittäisen palkinnon hakeminen epäonnistui.',
      );
    } finally {
      if (mounted) {
        setState(() {
          dailyLoading = false;
        });
      }
    }
  }

  // ==========================================================
  // LOAD DAILY REWARDED AD
  // ==========================================================

  void _loadDailyRewardedAd() {
    if (dailyAdLoading ||
        dailyRewardedAd != null) {
      return;
    }

    if (!mounted) return;

    setState(() {
      dailyAdLoading = true;
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
            dailyRewardedAd = ad;
            dailyAdLoading = false;
          });
        },
        onAdFailedToLoad: (
          LoadAdError error,
        ) {
          if (!mounted) return;

          setState(() {
            dailyRewardedAd = null;
            dailyAdLoading = false;
          });

          Future.delayed(
            const Duration(seconds: 15),
            () {
              if (mounted) {
                _loadDailyRewardedAd();
              }
            },
          );
        },
      ),
    );
  }

  // ==========================================================
  // SHOW DAILY REWARD AD
  // ==========================================================

  Future<void> _showDailyRewardAd() async {
    if (dailyClaimed) {
      _message(t.get('claimed'));
      return;
    }

    if (dailyLoading || dailyAdLoading) {
      return;
    }

    if (dailyRewardedAd == null) {
      _message(
        'Mainosta ladataan. Yritä hetken kuluttua.',
      );

      _loadDailyRewardedAd();
      return;
    }

    final ad = dailyRewardedAd!;

    setState(() {
      dailyRewardedAd = null;
      dailyAdLoading = true;
    });

    bool earnedReward = false;

    ad.fullScreenContentCallback =
        FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent:
          (RewardedAd dismissedAd) async {
        dismissedAd.dispose();

        if (mounted) {
          setState(() {
            dailyAdLoading = false;
          });
        }

        if (earnedReward) {
          await _dailyClaim();
        } else {
          _message(
            'Katso mainos loppuun saadaksesi '
            'päivittäisen palkinnon.',
          );
        }

        _loadDailyRewardedAd();
      },

      onAdFailedToShowFullScreenContent:
          (
        RewardedAd failedAd,
        AdError error,
      ) {
        failedAd.dispose();

        if (!mounted) return;

        setState(() {
          dailyAdLoading = false;
        });

        _message(
          'Mainosta ei voitu näyttää.',
        );

        _loadDailyRewardedAd();
      },
    );

    ad.show(
      onUserEarnedReward:
          (
        AdWithoutView ad,
        RewardItem reward,
      ) {
        earnedReward = true;
      },
    );
  }

  // ==========================================================
  // CAN WATCH AD
  // ==========================================================

  bool _canWatchAd() {
    if (lastAdTime == null) {
      return true;
    }

    final nextAdTime =
        lastAdTime!.add(adCooldown);

    return !DateTime.now()
        .isBefore(nextAdTime);
  }

  // ==========================================================
  // REMAINING AD TIME
  // ==========================================================

  Duration _remainingAdTime() {
    if (lastAdTime == null) {
      return Duration.zero;
    }

    final nextAdTime =
        lastAdTime!.add(adCooldown);

    final remaining =
        nextAdTime.difference(
      DateTime.now(),
    );

    if (remaining.isNegative) {
      return Duration.zero;
    }

    return remaining;
  }

  // ==========================================================
  // REMAINING AD TEXT
  // ==========================================================

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
      return '$hours h $minutes min';
    }

    if (minutes > 0) {
      return '$minutes min';
    }

    return 'alle 1 min';
  }

  // ==========================================================
  // COOLDOWN TIMER
  // ==========================================================

  void _startCooldownTimer() {
    cooldownTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  // ==========================================================
  // LOAD NORMAL REWARDED AD
  // ==========================================================

  void _loadRewardedAd() {
    if (adLoading ||
        rewardedAd != null) {
      return;
    }

    if (!mounted) return;

    setState(() {
      adLoading = true;
    });

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (
          RewardedAd ad,
        ) {
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
          if (!mounted) return;

          setState(() {
            rewardedAd = null;
            adLoading = false;
          });

          Future.delayed(
            const Duration(seconds: 15),
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

  // ==========================================================
  // CLAIM AD REWARD
  // ==========================================================

  Future<void> _claimAdReward() async {
    try {
      final callable =
          functions.httpsCallable(
        'testAdReward',
      );

      final result =
          await callable.call();

      final data =
          Map<String, dynamic>.from(
        result.data as Map,
      );

      final newBalance =
          (data['balance'] as num?)?.toInt() ??
              stl;

      final newAdsToday =
          (data['adsToday'] as num?)?.toInt() ??
              adsToday;

      final reward =
          (data['reward'] as num?)?.toInt() ?? 0;

      final now = DateTime.now();

      await _saveLocalCache(
        stlValue: newBalance,
        streakValue: streak,
        adsValue: newAdsToday,
        lastDailyValue: lastDaily,
        adDateValue: _dateKey(),
        lastAdTimeValue:
            now.toIso8601String(),
      );

      if (!mounted) return;

      setState(() {
        stl = newBalance;
        adsToday = newAdsToday;
        lastAdTime = now;
      });

      _message(
        '+$reward STL! 🐱',
      );
    } on FirebaseFunctionsException catch (error) {
      _message(
        error.message ??
            'Palkinnon hakeminen epäonnistui.',
      );

      await _loadData();
    } catch (_) {
      _message(
        'Palkinnon hakeminen epäonnistui.',
      );

      await _loadData();
    }
  }

  // ==========================================================
  // WATCH AD
  // ==========================================================

  Future<void> _watchAd() async {
    if (adsToday >= maxAdsPerDay) {
      _message(
        t.get('dailyLimitReached'),
      );

      return;
    }

    if (!_canWatchAd()) {
      _message(
        '${t.get('nextAd')}: '
        '${_remainingAdText()}',
      );

      return;
    }

    if (rewardedAd == null) {
      _message(
        'Mainosta ladataan. '
        'Yritä hetken kuluttua.',
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
          (
        RewardedAd dismissedAd,
      ) async {
        dismissedAd.dispose();

        if (earnedReward) {
          await _claimAdReward();
        }

        _loadRewardedAd();
      },

      onAdFailedToShowFullScreenContent:
          (
        RewardedAd failedAd,
        AdError error,
      ) {
        failedAd.dispose();

        if (!mounted) return;

        _message(
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
        earnedReward = true;
      },
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
  // LANGUAGE
  // ==========================================================

  void _openLanguageDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return LanguageDialog(
          currentLanguageCode:
              widget.languageCode,
          changeLanguage:
              widget.changeLanguage,
        );
      },
    );
  }

  // ==========================================================
  // ABOUT PAGE
  // ==========================================================

  void _openAboutPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const AboutPage(),
      ),
    );
  }

  // ==========================================================
  // WHITE PAPER PAGE
  // ==========================================================

  void _openWhitePaperPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const WhitePaperPage(),
      ),
    );
  }

  // ==========================================================
  // STL TOKEN PAGE
  // ==========================================================

  void _openTokenPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const StlTokenPage(),
      ),
    );
  }

  // ==========================================================
  // ROADMAP PAGE
  // ==========================================================

  void _openRoadmapPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const RoadmapPage(),
      ),
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

    final factIndex =
        DateTime.now().day %
            catFacts.length;

    final fact =
        catFacts[factIndex].text(
      widget.languageCode,
    );

    final canWatch = _canWatchAd();

    final remainingText =
        _remainingAdText();

    final adButtonEnabled =
        adsToday < maxAdsPerDay &&
            canWatch &&
            rewardedAd != null &&
            !adLoading;

    final dailyButtonEnabled =
        !dailyClaimed &&
            !dailyLoading &&
            !dailyAdLoading &&
            dailyRewardedAd != null;

    final nextAdText =
        canWatch
            ? ''
            : '${t.get('nextAd')}: '
                '$remainingText';

    return Scaffold(
      backgroundColor: backgroundColor,

      // ======================================================
      // DRAWER
      // ======================================================

      drawer: HomeDrawer(
        onLanguagePressed:
            _openLanguageDialog,

        onAboutPressed:
            _openAboutPage,

        onWhitePaperPressed:
            _openWhitePaperPage,

        onTokenPressed:
            _openTokenPage,

        onRoadmapPressed:
            _openRoadmapPage,
      ),

      // ======================================================
      // APP BAR
      // ======================================================

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
            tooltip: 'Kirjaudu ulos',
            icon: const Icon(
              Icons.logout,
            ),
            onPressed: _logout,
          ),
        ],
      ),

      // ======================================================
      // BODY
      // ======================================================

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding:
                const EdgeInsets.all(16),
            children: [
              // ==============================================
              // PROFILE
              // ==============================================

              ProfileCard(
                title: t.get('stella'),
              ),

              const SizedBox(height: 14),

              // ==============================================
              // BALANCE
              // ==============================================

              BalanceCard(
                stl: stl,
                title:
                    t.get('yourBalance'),
                subtitle:
                    t.get('virtualPoints'),
              ),

              const SizedBox(height: 14),

              // ==============================================
              // DAILY REWARD
              // ==============================================

              DailyRewardCard(
                title:
                    t.get('dailyClaim'),

                rewardText:
                    _dailyRewardText(),

                streakText:
                    _dailyStreakText(),

                dailyLoading:
                    dailyLoading,

                dailyAdLoading:
                    dailyAdLoading,

                dailyClaimed:
                    dailyClaimed,

                adReady:
                    dailyRewardedAd != null,

                onPressed:
                    dailyButtonEnabled
                        ? _showDailyRewardAd
                        : null,
              ),

              const SizedBox(height: 14),

              // ==============================================
              // WATCH AD
              // ==============================================

              WatchAdCard(
                title:
                    t.get('watchEarn'),

                dailyLimitText:
                    t.get('dailyLimit'),

                adsToday:
                    adsToday,

                maxAdsPerDay:
                    maxAdsPerDay,

                canWatch:
                    canWatch,

                nextAdText:
                    nextAdText,

                adLoading:
                    adLoading,

                adReady:
                    rewardedAd != null,

                loadingText:
                    t.get('adLoading'),

                limitReachedText:
                    t.get(
                      'dailyLimitReached',
                    ),

                unavailableText:
                    t.get('adUnavailable'),

                watchButtonText:
                    t.get('watchAd'),

                onPressed:
                    adButtonEnabled
                        ? _watchAd
                        : null,
              ),

              const SizedBox(height: 14),

              // ==============================================
              // CAT FACT
              // ==============================================

              CatFactCard(
                title:
                    t.get('stellaFacts'),
                fact: fact,
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}