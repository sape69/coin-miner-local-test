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
import 'tokenomics/tokenomics_page.dart';
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

const String rewardedAdUnitId =
    'ca-app-pub-3940256099942544/5224354917';

// ============================================================
// REWARD SETTINGS
// ============================================================

const int maxAdsPerDay = 5;

const int maxDailyReward = 7;

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
        _message('+$reward STL! 🐱🐾');
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

    final hours = remaining.inHours;

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
        '+$reward STL! 🐱🐾',
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
  // TRANSACTION HISTORY
  // ==========================================================

  Future<void> _openTransactionHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const TransactionHistoryPage(),
      ),
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
  // TOKENOMICS PAGE
  // ==========================================================

  void _openTokenomicsPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            const TokenomicsPage(),
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

        onTokenomicsPressed:
            _openTokenomicsPage,

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
            tooltip: 'Transaction History',
            icon: const Icon(
              Icons.receipt_long_outlined,
            ),
            onPressed:
                _openTransactionHistory,
          ),
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
              // TRANSACTION HISTORY BUTTON
              // ==============================================

              _TransactionHistoryCard(
                onPressed:
                    _openTransactionHistory,
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

// ============================================================
// TRANSACTION HISTORY CARD
// ============================================================

class _TransactionHistoryCard
    extends StatelessWidget {
  final VoidCallback onPressed;

  const _TransactionHistoryCard({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cardColor,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(16),
        onTap: onPressed,
        child: Padding(
          padding:
              const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accentColor.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: accentColor,
                  size: 28,
                ),
              ),

              const SizedBox(width: 16),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaction History',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Katso Stella STL -tapahtumasi 🐱🐾',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: accentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TRANSACTION HISTORY PAGE
// ============================================================

class TransactionHistoryPage
    extends StatefulWidget {
  const TransactionHistoryPage({
    super.key,
  });

  @override
  State<TransactionHistoryPage>
      createState() =>
          _TransactionHistoryPageState();
}

// ============================================================
// TRANSACTION HISTORY STATE
// ============================================================

class _TransactionHistoryPageState
    extends State<TransactionHistoryPage> {
  final FirebaseFunctions functions =
      FirebaseFunctions.instance;

  bool loading = true;

  String? errorMessage;

  List<Map<String, dynamic>>
      transactions = [];

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _loadTransactions();
  }

  // ==========================================================
  // LOAD TRANSACTIONS
  // ==========================================================

  Future<void> _loadTransactions() async {
    if (mounted) {
      setState(() {
        loading = true;
        errorMessage = null;
      });
    }

    try {
      final callable =
          functions.httpsCallable(
        'getTransactionHistory',
      );

      final result =
          await callable.call();

      final data =
          Map<String, dynamic>.from(
        result.data as Map,
      );

      final rawTransactions =
          data['transactions'];

      final List<Map<String, dynamic>>
          loadedTransactions = [];

      if (rawTransactions is List) {
        for (final item
            in rawTransactions) {
          if (item is Map) {
            loadedTransactions.add(
              Map<String, dynamic>.from(
                item,
              ),
            );
          }
        }
      }

      if (!mounted) return;

      setState(() {
        transactions =
            loadedTransactions;
        loading = false;
      });
    } on FirebaseFunctionsException
        catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            error.message ??
                'Tapahtumahistorian lataaminen epäonnistui.';
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Tapahtumahistorian lataaminen epäonnistui.';
        loading = false;
      });
    }
  }

  // ==========================================================
  // FORMAT DATE
  // ==========================================================

  String _formatDate(
    Map<String, dynamic> transaction,
  ) {
    final createdAt =
        transaction['createdAt'];

    if (createdAt is String &&
        createdAt.isNotEmpty) {
      final date =
          DateTime.tryParse(createdAt);

      if (date != null) {
        final local =
            date.toLocal();

        return '${local.day.toString().padLeft(2, '0')}.'
            '${local.month.toString().padLeft(2, '0')}.'
            '${local.year} '
            '${local.hour.toString().padLeft(2, '0')}:'
            '${local.minute.toString().padLeft(2, '0')}';
      }
    }

    final date =
        transaction['date'];

    if (date is String &&
        date.isNotEmpty) {
      return date;
    }

    return 'Unknown date';
  }

  // ==========================================================
  // TRANSACTION ICON
  // ==========================================================

  IconData _transactionIcon(
    String type,
  ) {
    switch (type) {
      case 'daily_reward':
        return Icons.card_giftcard_rounded;

      case 'ad_reward':
        return Icons.play_circle_outline_rounded;

      default:
        return Icons.receipt_long_rounded;
    }
  }

  // ==========================================================
  // TRANSACTION TITLE
  // ==========================================================

  String _transactionTitle(
    Map<String, dynamic> transaction,
  ) {
    final title =
        String(
      transaction['title'] ?? '',
    );

    if (title.isNotEmpty) {
      return title;
    }

    final type =
        String(
      transaction['type'] ?? '',
    );

    switch (type) {
      case 'daily_reward':
        return 'Daily Reward';

      case 'ad_reward':
        return 'Ad Reward';

      default:
        return 'STL Transaction';
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        title: const Text(
          'TRANSACTION HISTORY',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.4,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            onPressed:
                loading
                    ? null
                    : _loadTransactions,
          ),
        ],
      ),

      body: _buildBody(),
    );
  }

  // ==========================================================
  // BODY
  // ==========================================================

  Widget _buildBody() {
    if (loading) {
      return const Center(
        child:
            CircularProgressIndicator(
          color: accentColor,
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Colors.white54,
                size: 56,
              ),

              const SizedBox(height: 16),

              Text(
                errorMessage!,
                textAlign:
                    TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed:
                    _loadTransactions,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'Yritä uudelleen',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: accentColor.withValues(
                    alpha: 0.10,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  color: accentColor,
                  size: 45,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Ei vielä tapahtumia',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Stella odottaa ensimmäistä '
                'STL-tapahtumaasi 🐱🐾',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh:
          _loadTransactions,
      child: ListView.builder(
        padding:
            const EdgeInsets.all(16),

        itemCount:
            transactions.length,

        itemBuilder:
            (context, index) {
          final transaction =
              transactions[index];

          return _TransactionItem(
            transaction: transaction,
            icon: _transactionIcon(
              String(
                transaction['type'] ?? '',
              ),
            ),
            title:
                _transactionTitle(
              transaction,
            ),
            date:
                _formatDate(
              transaction,
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// TRANSACTION ITEM
// ============================================================

class _TransactionItem
    extends StatelessWidget {
  final Map<String, dynamic>
      transaction;

  final IconData icon;
  final String title;
  final String date;

  const _TransactionItem({
    required this.transaction,
    required this.icon,
    required this.title,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final amount =
        (transaction['amount'] as num?)
                ?.toInt() ??
            0;

    final balanceAfter =
        (transaction['balanceAfter']
                    as num?)
                ?.toInt() ??
            0;

    final type =
        String(
      transaction['type'] ?? '',
    );

    final isDaily =
        type == 'daily_reward';

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      color: cardColor,
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Row(
          children: [
            // ==================================================
            // ICON
            // ==================================================

            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: accentColor.withValues(
                  alpha: 0.12,
                ),
                borderRadius:
                    BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: 26,
              ),
            ),

            const SizedBox(width: 14),

            // ==================================================
            // DETAILS
            // ==================================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    isDaily
                        ? '🎁 $title'
                        : '🐾 $title',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    date,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Balance: $balanceAfter STL',
                    style: TextStyle(
                      color: accentColor.withValues(
                        alpha: 0.75,
                      ),
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // AMOUNT
            // ==================================================

            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Text(
                  '+$amount STL',
                  style: const TextStyle(
                    color: accentColor,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'STELLA 🐱',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                    fontWeight:
                        FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}