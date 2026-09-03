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
// COLORS
// ============================================================

const Color backgroundColor = Color(0xFF0B1112);
const Color accentColor = Color(0xFF35D0A0);

// ============================================================
// ADMOB
// ============================================================

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

  bool dailyClaimed = false;

  // ==========================================================
  // AD DATA
  // ==========================================================

  int adsToday = 0;
  int maxAdsPerDay = 5;

  bool canWatchAd = false;

  Duration cooldownRemaining = Duration.zero;

  // ==========================================================
  // UI STATES
  // ==========================================================

  bool loading = true;
  bool dailyLoading = false;
  bool miningLoading = false;
  bool adClaimLoading = false;

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

        dailyClaimed =
            data['dailyClaimed'] == true;

        adsToday =
            (data['adsToday'] as num?)
                    ?.toInt() ??
                0;

        maxAdsPerDay =
            (data['maxAdsPerDay'] as num?)
                    ?.toInt() ??
                5;

        canWatchAd =
            data['canWatchAd'] == true;

        cooldownRemaining = Duration(
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
            'STELLA-yhteys epäonnistui.',
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      _message(
        'STELLA-yhteys epäonnistui.',
      );
    }
  }

  // ==========================================================
  // AUTO REFRESH
  // ==========================================================

  void _startRefreshTimer() {
    refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted && !loading) {
          _loadData();
        }
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

      if (!mounted) return;

      if (claimed > 0) {
        _message(
          '⛏️ +${claimed.toStringAsFixed(2)} STL louhittu! 🐱',
        );
      } else {
        _message(
          data['message'] ??
              'Stella Mining käynnistyi! 🐱⛏️',
        );
      }

      await _loadData();
    } on FirebaseFunctionsException catch (error) {
      _message(
        error.message ??
            'Louhinnan hakeminen epäonnistui.',
      );
    } catch (_) {
      _message(
        'Louhinnan hakeminen epäonnistui.',
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

      if (!mounted) return;

      if (alreadyClaimed) {
        _message(t.get('claimed'));
      } else {
        _message(
          '🐱 +${bonus.toStringAsFixed(0)} Hash Rate! ⚡',
        );
      }

      await _loadData();
    } on FirebaseFunctionsException catch (error) {
      _message(
        error.message ??
            'Päivittäinen bonus epäonnistui.',
      );
    } catch (_) {
      _message(
        'Päivittäinen bonus epäonnistui.',
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
      _message(t.get('adLoading'));

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
  // CLAIM AD HASH RATE BONUS
  // ==========================================================

  Future<void> _claimAdReward() async {
    if (adClaimLoading) return;

    setState(() {
      adClaimLoading = true;
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

      if (!mounted) return;

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
          adClaimLoading = false;
        });
      }
    }
  }

  // ==========================================================
  // REMAINING AD TIME
  // ==========================================================

  String _remainingAdText() {
    if (cooldownRemaining <= Duration.zero) {
      return '';
    }

    final hours =
        cooldownRemaining.inHours;

    final minutes =
        cooldownRemaining.inMinutes
            .remainder(60);

    if (hours > 0) {
      return '$hours h $minutes min';
    }

    if (minutes > 0) {
      return '$minutes min';
    }

    return 'alle 1 min';
  }

  // ==========================================================
  // DAILY TEXT
  // ==========================================================

  String _dailyRewardText() {
    if (dailyClaimed) {
      return '🎁 ${t.get('claimed')}';
    }

    return '🎁 +1 Hash Rate';
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
            !adClaimLoading;

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
              ProfileCard(
                title: t.get('stella'),
              ),

              const SizedBox(height: 14),

              // ==============================================
              // MINING BALANCE
              // ==============================================

              BalanceCard(
                stl: estimatedTotal.round(),
                title: t.get('yourBalance'),
                subtitle:
                    '⛏️ ${unclaimedMining.toStringAsFixed(2)} STL valmiina louhittavaksi\n'
                    '⚡ ${hashRate.toStringAsFixed(0)} Hash Rate\n'
                    '📈 ${miningPerHour.toStringAsFixed(2)} STL / tunti',
              ),

              const SizedBox(height: 12),

              // ==============================================
              // CLAIM MINING
              // ==============================================

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      miningLoading
                          ? null
                          : _claimMining,
                  icon: miningLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.precision_manufacturing,
                        ),
                  label: Text(
                    miningLoading
                        ? 'LOUHITAAN...'
                        : '⛏️ CLAIM MINING',
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ==============================================
              // DAILY HASH RATE BONUS
              // ==============================================

              DailyRewardCard(
                title: t.get('dailyClaim'),
                rewardText: _dailyRewardText(),
                streakText: _dailyStreakText(),
                dailyLoading: dailyLoading,
                dailyAdLoading: false,
                dailyClaimed: dailyClaimed,
                adReady: true,
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
                title: t.get('watchEarn'),
                dailyLimitText: t.get('dailyLimit'),
                adsToday: adsToday,
                maxAdsPerDay: maxAdsPerDay,
                canWatch: canWatchAd,
                nextAdText: nextAdText,
                adLoading:
                    adClaimLoading ||
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

              CatFactCard(
                title: t.get('stellaFacts'),
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