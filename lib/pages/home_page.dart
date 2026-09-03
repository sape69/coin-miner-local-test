import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../cat_facts.dart';
import '../localization.dart';

import 'about/about_page.dart';
import 'history/transaction_history_page.dart';
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
// STELLURIINI THEME
// ============================================================

const Color backgroundColor = Color(0xFF0B1112);
const Color accentColor = Color(0xFF35D0A0);

// ============================================================
// ADMOB
// ============================================================

/// Google Rewarded Ad TEST ID.
///
/// Vaihda tuotannossa omaan AdMob Rewarded Ad Unit ID:hen.
const String rewardedAdUnitId =
    'ca-app-pub-3940256099942544/5224354917';

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
  // MINING DATA
  // ==========================================================

  double miningBalance = 0;

  double unclaimedMining = 0;

  double estimatedTotal = 0;

  double hashRate = 1;

  double miningPerHour = 0;

  int streak = 0;

  int adsToday = 0;

  int maxAdsPerDay = 5;

  int dailyHashRateBonus = 1;

  int adHashRateBonus = 5;

  bool dailyClaimed = false;

  bool canWatchAd = false;

  Duration cooldownRemaining = Duration.zero;

  // ==========================================================
  // UI STATES
  // ==========================================================

  bool loading = true;

  bool dailyLoading = false;

  bool adLoading = false;

  bool miningLoading = false;

  // ==========================================================
  // ADMOB
  // ==========================================================

  RewardedAd? rewardedAd;

  bool rewardedAdLoading = false;

  // ==========================================================
  // TIMER
  // ==========================================================

  Timer? refreshTimer;

  // ==========================================================
  // LOCALIZATION
  // ==========================================================

  AppLocalizations get t =>
      AppLocalizations(widget.languageCode);

  // ==========================================================
  // FIREBASE
  // ==========================================================

  FirebaseFunctions get functions =>
      FirebaseFunctions.instance;

  String? get uid =>
      FirebaseAuth.instance.currentUser?.uid;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _loadData();
    _loadRewardedAd();
    _startRefreshTimer();
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    refreshTimer?.cancel();
    rewardedAd?.dispose();

    super.dispose();
  }

  // ==========================================================
  // LOAD MINING STATUS
  // ==========================================================

  Future<void> _loadData() async {
    if (uid == null) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      return;
    }

    try {
      final result =
          await functions
              .httpsCallable('getMiningStatus')
              .call();

      final data =
          Map<String, dynamic>.from(
        result.data as Map,
      );

      final cooldownMs =
          (data['cooldownRemainingMs'] as num?)
                  ?.toInt() ??
              0;

      if (!mounted) return;

      setState(() {
        hashRate =
            (data['hashRate'] as num?)
                    ?.toDouble() ??
                1;

        miningBalance =
            (data['miningBalance'] as num?)
                    ?.toDouble() ??
                0;

        unclaimedMining =
            (data['unclaimedMining'] as num?)
                    ?.toDouble() ??
                0;

        estimatedTotal =
            (data['estimatedTotal'] as num?)
                    ?.toDouble() ??
                miningBalance;

        miningPerHour =
            (data['miningPerHour'] as num?)
                    ?.toDouble() ??
                0;

        streak =
            (data['streak'] as num?)
                    ?.toInt() ??
                0;

        adsToday =
            (data['adsToday'] as num?)
                    ?.toInt() ??
                0;

        maxAdsPerDay =
            (data['maxAdsPerDay'] as num?)
                    ?.toInt() ??
                5;

        dailyHashRateBonus =
            (data['dailyHashRateBonus'] as num?)
                    ?.toInt() ??
                1;

        adHashRateBonus =
            (data['adHashRateBonus'] as num?)
                    ?.toInt() ??
                5;

        dailyClaimed =
            data['dailyClaimed'] == true;

        canWatchAd =
            data['canWatchAd'] == true;

        cooldownRemaining =
            Duration(
          milliseconds: cooldownMs,
        );

        loading = false;
      });
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      _message(
        error.message ??
            'STELLA Mining -yhteys epäonnistui.',
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      _message(
        'STELLA Mining -yhteys epäonnistui.',
      );
    }
  }

  // ==========================================================
  // REFRESH TIMER
  //
  // Päivittää louhittavan määrän ja cooldownin.
  // ==========================================================

  void _startRefreshTimer() {
    refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (!mounted) return;

        _loadData();
      },
    );
  }

  // ==========================================================
  // CLAIM MINING
  // ==========================================================

  Future<void> _claimMining() async {
    if (miningLoading) return;

    setState(() {
      miningLoading = true;
    });

    try {
      final result =
          await functions
              .httpsCallable('claimMining')
              .call();

      final data =
          Map<String, dynamic>.from(
        result.data as Map,
      );

      final claimed =
          (data['claimed'] as num?)
                  ?.toDouble() ??
              0;

      final newBalance =
          (data['balance'] as num?)
                  ?.toDouble() ??
              miningBalance;

      final newHashRate =
          (data['hashRate'] as num?)
                  ?.toDouble() ??
              hashRate;

      if (!mounted) return;

      setState(() {
        miningBalance = newBalance;

        estimatedTotal = newBalance;

        unclaimedMining = 0;

        hashRate = newHashRate;
      });

      if (claimed > 0) {
        _message(
          '⛏️ +${claimed.toStringAsFixed(4)} STL louhittu! 🐱',
        );
      } else {
        _message(
          '⛏️ Stella Mining käynnistyi! 🐱',
        );
      }

      await _loadData();
    } on FirebaseFunctionsException catch (error) {
      _message(
        error.message ??
            'Mining-palkinnon hakeminen epäonnistui.',
      );
    } catch (_) {
      _message(
        'Mining-palkinnon hakeminen epäonnistui.',
      );
    } finally {
      if (mounted) {
        setState(() {
          miningLoading = false;
        });
      }
    }
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
      final result =
          await functions
              .httpsCallable('dailyCheckIn')
              .call();

      final data =
          Map<String, dynamic>.from(
        result.data as Map,
      );

      final alreadyClaimed =
          data['alreadyClaimed'] == true;

      final bonus =
          (data['bonus'] as num?)
                  ?.toDouble() ??
              0;

      final newHashRate =
          (data['hashRate'] as num?)
                  ?.toDouble() ??
              hashRate;

      final newStreak =
          (data['streak'] as num?)
                  ?.toInt() ??
              streak;

      if (!mounted) return;

      setState(() {
        hashRate = newHashRate;

        streak = newStreak;

        dailyClaimed = true;
      });

      if (alreadyClaimed) {
        _message(t.get('claimed'));
      } else {
        _message(
          '🎁 +${bonus.toStringAsFixed(0)} Hash Rate! 🐱⚡',
        );
      }

      await _loadData();
    } on FirebaseFunctionsException catch (error) {
      _message(
        error.message ??
            'Päivittäisen Stella-bonuksen hakeminen epäonnistui.',
      );
    } catch (_) {
      _message(
        'Päivittäisen Stella-bonuksen hakeminen epäonnistui.',
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
  // LOAD REWARDED AD
  // ==========================================================

  void _loadRewardedAd() {
    if (rewardedAdLoading ||
        rewardedAd != null) {
      return;
    }

    rewardedAdLoading = true;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          rewardedAdLoading = false;

          if (!mounted) {
            ad.dispose();
            return;
          }

          setState(() {
            rewardedAd = ad;
          });
        },
        onAdFailedToLoad: (error) {
          rewardedAdLoading = false;

          if (!mounted) return;

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
  // WATCH AD
  // ==========================================================

  Future<void> _watchAd() async {
    if (!canWatchAd) {
      if (cooldownRemaining > Duration.zero) {
        _message(
          '${t.get('nextAd')}: '
          '${_remainingAdText()}',
        );
      } else {
        _message(
          t.get('dailyLimitReached'),
        );
      }

      return;
    }

    if (rewardedAd == null) {
      _message(
        t.get('adLoading'),
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
          (dismissedAd) async {
        dismissedAd.dispose();

        if (earnedReward) {
          await _claimAdReward();
        }

        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent:
          (failedAd, error) {
        failedAd.dispose();

        _message(
          'Mainosta ei voitu näyttää.',
        );

        _loadRewardedAd();
      },
    );

    ad.show(
      onUserEarnedReward:
          (ad, reward) {
        earnedReward = true;
      },
    );
  }

  // ==========================================================
  // CLAIM AD REWARD
  // ==========================================================

  Future<void> _claimAdReward() async {
    if (adLoading) return;

    setState(() {
      adLoading = true;
    });

    try {
      final result =
          await functions
              .httpsCallable('testAdReward')
              .call();

      final data =
          Map<String, dynamic>.from(
        result.data as Map,
      );

      final bonus =
          (data['bonus'] as num?)
                  ?.toDouble() ??
              0;

      final newHashRate =
          (data['hashRate'] as num?)
                  ?.toDouble() ??
              hashRate;

      final newAdsToday =
          (data['adsToday'] as num?)
                  ?.toInt() ??
              adsToday;

      if (!mounted) return;

      setState(() {
        hashRate = newHashRate;

        adsToday = newAdsToday;
      });

      _message(
        '📺 +${bonus.toStringAsFixed(0)} Hash Rate! 🐱⚡',
      );

      await _loadData();
    } on FirebaseFunctionsException catch (error) {
      _message(
        error.message ??
            'Mainospalkinnon hakeminen epäonnistui.',
      );

      await _loadData();
    } catch (_) {
      _message(
        'Mainospalkinnon hakeminen epäonnistui.',
      );

      await _loadData();
    } finally {
      if (mounted) {
        setState(() {
          adLoading = false;
        });
      }
    }
  }

  // ==========================================================
  // REMAINING AD TEXT
  // ==========================================================

  String _remainingAdText() {
    if (cooldownRemaining <= Duration.zero) {
      return '';
    }

    final hours =
        cooldownRemaining.inHours;

    final minutes =
        cooldownRemaining.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours h $minutes min';
    }

    if (minutes > 0) {
      return '$minutes min';
    }

    return 'alle 1 min';
  }

  // ==========================================================
  // DAILY REWARD TEXT
  // ==========================================================

  String _dailyRewardText() {
    if (dailyClaimed) {
      return '🎁 ${t.get('claimed')}';
    }

    return '🎁 +$dailyHashRateBonus Hash Rate';
  }

  // ==========================================================
  // DAILY STREAK TEXT
  // ==========================================================

  String _dailyStreakText() {
    return '${t.get('streak')}: '
        '🔥 Päivä $streak';
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
  // NAVIGATION
  // ==========================================================

  void _openTransactionHistoryPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const TransactionHistoryPage(),
      ),
    );
  }

  void _openAboutPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const AboutPage(),
      ),
    );
  }

  void _openWhitePaperPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const WhitePaperPage(),
      ),
    );
  }

  void _openTokenPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const StlTokenPage(),
      ),
    );
  }

  void _openTokenomicsPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const TokenomicsPage(),
      ),
    );
  }

  void _openRoadmapPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
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

    final adButtonEnabled =
        canWatchAd &&
            rewardedAd != null &&
            !adLoading &&
            !rewardedAdLoading;

    final dailyButtonEnabled =
        !dailyClaimed &&
            !dailyLoading;

    final nextAdText =
        cooldownRemaining > Duration.zero
            ? '${t.get('nextAd')}: '
                '${_remainingAdText()}'
            : '';

    return Scaffold(
      backgroundColor: backgroundColor,

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

        onTransactionHistoryPressed:
            _openTransactionHistoryPage,
      ),

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
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          color: accentColor,
          onRefresh: _loadData,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
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
              // MINING BALANCE
              //
              // Näytetään arvioitu kokonaismäärä.
              // ==============================================

              BalanceCard(
                stl: estimatedTotal,
                title: '⛏️ Stella Mining Balance',
                subtitle:
                    'Hash Rate: '
                    '${hashRate.toStringAsFixed(0)} '
                    '⚡  •  '
                    '${miningPerHour.toStringAsFixed(2)} STL/h',
              ),

              const SizedBox(height: 10),

              // ==============================================
              // CLAIM MINING BUTTON
              // ==============================================

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '⛏️ Louhittavana',
                        style:
                            Theme.of(context)
                                .textTheme
                                .titleMedium,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        '${unclaimedMining.toStringAsFixed(4)} STL',
                        style:
                            const TextStyle(
                          fontSize: 24,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      ElevatedButton.icon(
                        onPressed:
                            miningLoading
                                ? null
                                : _claimMining,
                        icon:
                            const Icon(
                          Icons.download,
                        ),
                        label: Text(
                          miningLoading
                              ? 'Louhitaan...'
                              : 'KERÄÄ LOUHITUT STL',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ==============================================
              // DAILY HASH RATE BONUS
              // ==============================================

              DailyRewardCard(
                title: '🐱 Päivittäinen Stella Bonus',
                rewardText:
                    _dailyRewardText(),
                streakText:
                    _dailyStreakText(),
                dailyLoading:
                    dailyLoading,
                dailyAdLoading:
                    false,
                dailyClaimed:
                    dailyClaimed,
                adReady:
                    true,
                onPressed:
                    dailyButtonEnabled
                        ? _dailyClaim
                        : null,
              ),

              const SizedBox(height: 14),

              // ==============================================
              // WATCH AD
              // ==============================================

              WatchAdCard(
                title:
                    '📺 Katso & Boostaa +$adHashRateBonus Hash Rate',

                dailyLimitText:
                    t.get('dailyLimit'),

                adsToday:
                    adsToday,

                maxAdsPerDay:
                    maxAdsPerDay,

                canWatch:
                    canWatchAd,

                nextAdText:
                    nextAdText,

                adLoading:
                    adLoading ||
                        rewardedAdLoading,

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