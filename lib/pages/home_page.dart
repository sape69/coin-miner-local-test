import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cat_facts.dart';
import '../localization.dart';

import 'home/balance_card.dart';
import 'home/cat_fact_card.dart';
import 'home/coming_soon.dart';
import 'home/daily_reward_card.dart';
import 'home/home_drawer.dart';
import 'home/information_card.dart';
import 'home/language_dialog.dart';
import 'home/profile_card.dart';
import 'home/watch_ad_card.dart';

const int maxAdsPerDay = 5;

const Duration adCooldown = Duration(hours: 1);

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
  bool dailyLoading = false;
  bool dailyAdLoading = false;

  String today = '';

  DateTime? lastAdTime;

  RewardedAd? rewardedAd;
  RewardedAd? dailyRewardedAd;

  Timer? cooldownTimer;

  AppLocalizations get t =>
      AppLocalizations(widget.languageCode);

  CollectionReference<Map<String, dynamic>>
      get _users =>
          FirebaseFirestore.instance.collection(
            'users',
          );

  String? get _uid =>
      FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>
      get _userDoc {
    final uid = _uid;

    if (uid == null) {
      throw StateError(
        'Käyttäjä ei ole kirjautunut.',
      );
    }

    return _users.doc(uid);
  }

  @override
  void initState() {
    super.initState();

    _loadData();
    _loadRewardedAd();
    _loadDailyRewardedAd();
    _startCooldownTimer();
  }

  @override
  void dispose() {
    rewardedAd?.dispose();
    dailyRewardedAd?.dispose();
    cooldownTimer?.cancel();

    super.dispose();
  }

  // ==========================================================
  // DATE
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
    final currentToday = _dateKey();

    try {
      final snapshot = await _userDoc.get();

      Map<String, dynamic> data;

      if (!snapshot.exists) {
        data = {
          'stlBalance': 0,
          'streak': 0,
          'lastDaily': '',
          'adsToday': 0,
          'adDate': currentToday,
        };

        await _userDoc.set(
          data,
          SetOptions(merge: true),
        );
      } else {
        data =
            snapshot.data() ??
                <String, dynamic>{};
      }

      final loadedStl =
          (data['stlBalance'] as num?)
                  ?.toInt() ??
              0;

      final loadedStreak =
          (data['streak'] as num?)
                  ?.toInt() ??
              0;

      int loadedAds =
          (data['adsToday'] as num?)
                  ?.toInt() ??
              0;

      final lastDaily =
          data['lastDaily'] as String? ?? '';

      String adDate =
          data['adDate'] as String? ?? '';

      DateTime? loadedLastAdTime;

      final timestamp =
          data['lastAdTimestamp'];

      if (timestamp is Timestamp) {
        loadedLastAdTime =
            timestamp.toDate();
      }

      final oldLastAdTime =
          data['lastAdTime'];

      if (loadedLastAdTime == null &&
          oldLastAdTime is String &&
          oldLastAdTime.isNotEmpty) {
        loadedLastAdTime =
            DateTime.tryParse(oldLastAdTime);
      }

      if (adDate != currentToday) {
        loadedAds = 0;
        adDate = currentToday;
      }

      await _saveLocalCache(
        stlValue: loadedStl,
        streakValue: loadedStreak,
        adsValue: loadedAds,
        lastDailyValue: lastDaily,
        adDateValue: adDate,
        lastAdTimeValue:
            loadedLastAdTime
                    ?.toIso8601String() ??
                '',
      );

      if (!mounted) return;

      setState(() {
        today = currentToday;
        stl = loadedStl;
        streak = loadedStreak;
        adsToday = loadedAds;
        dailyClaimed =
            lastDaily == currentToday;
        lastAdTime =
            loadedLastAdTime;
        loading = false;
      });
    } catch (_) {
      await _loadLocalCache();
    }
  }

  // ==========================================================
  // LOCAL CACHE SAVE
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
  // LOCAL CACHE LOAD
  // ==========================================================

  Future<void> _loadLocalCache() async {
    final prefs =
        await SharedPreferences.getInstance();

    final currentToday =
        _dateKey();

    int loadedAds =
        prefs.getInt('ads_today') ?? 0;

    final savedAdDate =
        prefs.getString('ad_date') ?? '';

    if (savedAdDate != currentToday) {
      loadedAds = 0;

      await prefs.setInt(
        'ads_today',
        0,
      );

      await prefs.setString(
        'ad_date',
        currentToday,
      );
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

      stl =
          prefs.getInt('stl_balance') ?? 0;

      streak =
          prefs.getInt('streak') ?? 0;

      adsToday = loadedAds;

      dailyClaimed =
          prefs.getString('last_daily') ==
              currentToday;

      lastAdTime =
          loadedLastAdTime;

      loading = false;
    });
  }

  // ==========================================================
  // DAILY CLAIM
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
          FirebaseFunctions.instance
              .httpsCallable(
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
          (data['balance'] as num?)
                  ?.toInt() ??
              stl;

      final newStreak =
          (data['streak'] as num?)
                  ?.toInt() ??
              streak;

      final reward =
          (data['reward'] as num?)
                  ?.toInt() ??
              0;

      final currentToday =
          _dateKey();

      await _saveLocalCache(
        stlValue: newBalance,
        streakValue: newStreak,
        adsValue: adsToday,
        lastDailyValue: currentToday,
        adDateValue: today,
        lastAdTimeValue:
            lastAdTime
                    ?.toIso8601String() ??
                '',
      );

      if (!mounted) return;

      setState(() {
        stl = newBalance;
        streak = newStreak;
        dailyClaimed = true;
      });

      if (alreadyClaimed) {
        _message(t.get('claimed'));
      } else {
        _message('+$reward STL! 🐱');
      }
    } on FirebaseFunctionsException catch (
      error
    ) {
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
  // LOAD DAILY AD
  // ==========================================================

  void _loadDailyRewardedAd() {
    if (dailyAdLoading ||
        dailyRewardedAd != null) {
      return;
    }

    setState(() {
      dailyAdLoading = true;
    });

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded:
            (RewardedAd ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }

          setState(() {
            dailyRewardedAd = ad;
            dailyAdLoading = false;
          });
        },
        onAdFailedToLoad:
            (LoadAdError error) {
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
  // SHOW DAILY AD
  // ==========================================================

  Future<void> _showDailyRewardAd() async {
    if (dailyClaimed) {
      _message(t.get('claimed'));
      return;
    }

    if (dailyLoading ||
        dailyAdLoading) {
      return;
    }

    if (dailyRewardedAd == null) {
      _message(
        'Mainosta ladataan. Yritä hetken kuluttua.',
      );

      _loadDailyRewardedAd();
      return;
    }

    final ad =
        dailyRewardedAd!;

    setState(() {
      dailyRewardedAd = null;
      dailyAdLoading = true;
    });

    bool earnedReward = false;

    ad.fullScreenContentCallback =
        FullScreenContentCallback<
            RewardedAd>(
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
            'Katso mainos loppuun saadaksesi päivittäisen palkinnon.',
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
  // AD COOLDOWN
  // ==========================================================

  bool _canWatchAd() {
    if (lastAdTime == null) {
      return true;
    }

    return !DateTime.now().isBefore(
      lastAdTime!.add(adCooldown),
    );
  }

  Duration _remainingAdTime() {
    if (lastAdTime == null) {
      return Duration.zero;
    }

    final remaining =
        lastAdTime!
            .add(adCooldown)
            .difference(
              DateTime.now(),
            );

    return remaining.isNegative
        ? Duration.zero
        : remaining;
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
        remaining.inMinutes.remainder(
      60,
    );

    if (hours > 0) {
      return '$hours h $minutes min';
    }

    if (minutes > 0) {
      return '$minutes min';
    }

    return 'alle 1 min';
  }

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
  // LOAD REWARDED AD
  // ==========================================================

  void _loadRewardedAd() {
    if (adLoading ||
        rewardedAd != null) {
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
        onAdLoaded:
            (RewardedAd ad) {
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
  // CLAIM TEST AD REWARD
  // ==========================================================

  Future<void> _claimTestAdReward() async {
    try {
      final callable =
          FirebaseFunctions.instance
              .httpsCallable(
        'testAdReward',
      );

      final result =
          await callable.call();

      final data =
          Map<String, dynamic>.from(
        result.data as Map,
      );

      final newBalance =
          (data['balance'] as num?)
                  ?.toInt() ??
              stl;

      final newAdsToday =
          (data['adsToday'] as num?)
                  ?.toInt() ??
              adsToday;

      final reward =
          (data['reward'] as num?)
                  ?.toInt() ??
              0;

      final now =
          DateTime.now();

      await _saveLocalCache(
        stlValue: newBalance,
        streakValue: streak,
        adsValue: newAdsToday,
        lastDailyValue:
            dailyClaimed ? today : '',
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

      _message('+$reward STL! 🐱');
    } on FirebaseFunctionsException catch (
      error
    ) {
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
        'Mainosta ladataan. Yritä hetken kuluttua.',
      );

      _loadRewardedAd();
      return;
    }

    final ad =
        rewardedAd!;

    setState(() {
      rewardedAd = null;
    });

    bool earnedReward = false;

    ad.fullScreenContentCallback =
        FullScreenContentCallback<
            RewardedAd>(
      onAdDismissedFullScreenContent:
          (RewardedAd dismissedAd) async {
        dismissedAd.dispose();

        if (earnedReward) {
          await _claimTestAdReward();
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
  // LANGUAGE DIALOG
  // ==========================================================

  void _openLanguageDialog() {
    showDialog(
      context: context,
      builder: (_) {
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
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(
            color: Color(0xFF35D0A0),
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

    final canWatch =
        _canWatchAd();

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

    return Scaffold(
      drawer: HomeDrawer(
        onHome: () {
          Navigator.pop(context);
        },
        onAbout: () {
          showComingSoon(
            context,
            'About Stelluriini',
          );
        },
        onWhitePaper: () {
          showComingSoon(
            context,
            'White Paper',
          );
        },
        onStlToken: () {
          showComingSoon(
            context,
            'STL Token',
          );
        },
        onRoadmap: () {
          showComingSoon(
            context,
            'Roadmap',
          );
        },
      ),

      appBar: AppBar(
        title: const Text(
          'STELLURIINI',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Vaihda kieli',
            icon:
                const Icon(Icons.language),
            onPressed:
                _openLanguageDialog,
          ),
          IconButton(
            tooltip: 'Kirjaudu ulos',
            icon:
                const Icon(Icons.logout),
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
              ProfileCard(
                email:
                    user?.email ?? '',
                title:
                    t.get('stella'),
              ),

              const SizedBox(height: 14),

              BalanceCard(
                balance: stl,
                title:
                    t.get('yourBalance'),
                virtualPointsText:
                    t.get('virtualPoints'),
              ),

              const SizedBox(height: 14),

              DailyRewardCard(
                streak: streak,
                title:
                    t.get('dailyClaim'),
                streakText:
                    t.get('streak'),
                buttonEnabled:
                    dailyButtonEnabled,
                dailyLoading:
                    dailyLoading,
                dailyAdLoading:
                    dailyAdLoading,
                dailyClaimed:
                    dailyClaimed,
                adReady:
                    dailyRewardedAd != null,
                claimedText:
                    t.get('claimed'),
                onPressed:
                    _showDailyRewardAd,
              ),

              const SizedBox(height: 14),

              WatchAdCard(
                adsToday: adsToday,
                maxAdsPerDay:
                    maxAdsPerDay,
                canWatch:
                    canWatch,
                remainingText:
                    remainingText,
                buttonEnabled:
                    adButtonEnabled,
                adLoading:
                    adLoading,
                adReady:
                    rewardedAd != null,
                title:
                    t.get('watchEarn'),
                dailyLimitText:
                    t.get('dailyLimit'),
                nextAdText:
                    t.get('nextAd'),
                dailyLimitReachedText:
                    t.get(
                      'dailyLimitReached',
                    ),
                adLoadingText:
                    t.get('adLoading'),
                adUnavailableText:
                    t.get(
                      'adUnavailable',
                    ),
                watchAdText:
                    t.get('watchAd'),
                onPressed:
                    _watchAd,
              ),

              const SizedBox(height: 14),

              CatFactCard(
                title:
                    t.get('stellaFacts'),
                fact: fact,
              ),

              const SizedBox(height: 14),

              InformationCard(
                title:
                    t.get('info'),
                solanaTokenText:
                    t.get('solanaToken'),
                companyText:
                    t.get('stellaCompany'),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}