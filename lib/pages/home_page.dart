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
// THEME
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
  double hashRate = 1;
  double miningPerHour = 0;

  // ==========================================================
  // DAILY DATA
  // ==========================================================

  int streak = 0;

  bool dailyClaimed = false;

  double dailyHashRateBonus = 1;

  // ==========================================================
  // AD DATA
  // ==========================================================

  int adsToday = 0;
  int maxAdsPerDay = 5;

  double adHashRateBonus = 5;

  bool canWatchAd = false;

  Duration cooldownRemaining = Duration.zero;

  // ==========================================================
  // UI STATES
  // ==========================================================

  bool loading = true;

  bool miningClaimLoading = false;
  bool dailyLoading = false;
  bool adRewardLoading = false;

  // ==========================================================
  // ADMOB
  // ==========================================================

  RewardedAd? rewardedAd;

  bool rewardedAdLoading = false;

  // ==========================================================
  // TIMER
  // ==========================================================

  Timer? refreshTimer;
  Timer? cooldownTimer;

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

    _loadMiningStatus();
    _loadRewardedAd();

    _startTimers();
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    refreshTimer?.cancel();
    cooldownTimer?.cancel();

    rewardedAd?.dispose();

    super.dispose();
  }

  // ==========================================================
  // START TIMERS
  // ==========================================================

  void _startTimers() {
    // Päivittää louhinnan palvelimelta minuutin välein.
    refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        if (mounted) {
          _loadMiningStatus(silent: true);
        }
      },
    );

    // Päivittää cooldown-näytön.
    cooldownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        if (cooldownRemaining > Duration.zero) {
          setState(() {
            cooldownRemaining -=
                const Duration(seconds: 1);

            if (cooldownRemaining <= Duration.zero) {
              cooldownRemaining = Duration.zero;

              if (adsToday < maxAdsPerDay) {
                canWatchAd = true;
              }
            }
          });
        }
      },
    );
  }

  // ==========================================================
  // LOAD MINING STATUS
  // ==========================================================

  Future<void> _loadMiningStatus({
    bool silent = false,
  }) async {
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
        miningBalance =
            (data['miningBalance'] as num?)
                    ?.toDouble() ??
                0;

        unclaimedMining =
            (data['unclaimedMining'] as num?)
                    ?.toDouble() ??
                0;

        hashRate =
            (data['hashRate'] as num?)
                    ?.toDouble() ??
                1;

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

        dailyHashRateBonus =
            (data['dailyHashRateBonus'] as num?)
                    ?.toDouble() ??
                1;

        adsToday =
            (data['adsToday'] as num?)
                    ?.toInt() ??
                0;

        maxAdsPerDay =
            (data['maxAdsPerDay'] as num?)
                    ?.toInt() ??
                5;

        adHashRateBonus =
            (data['adHashRateBonus'] as num?)
                    ?.toDouble() ??
                5;

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

      if (!silent) {
        _message(
          error.message ??
              'STELLA-yhteys epäonnistui.',
        );
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      if (!silent) {
        _message(
          'STELLA-yhteys epäonnistui.',
        );
      }
    }
  }

  // ==========================================================
  // CLAIM MINING
  // ==========================================================

  Future<void> _claimMining() async {
    if (miningClaimLoading) return;

    setState(() {
      miningClaimLoading = true;
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

        unclaimedMining = 0;

        hashRate = newHashRate;

        miningPerHour =
            hashRate * 0.10;
      });

      if (claimed <= 0) {
        _message(
          '⛏️ Stella Mining on nyt käynnissä! 🐱',
        );
      } else {
        _message(
          '⛏️ +${claimed.toStringAsFixed(2)} STL '
          'louhittu! 🐱✨',
        );
      }
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
          miningClaimLoading = false;
        });
      }
    }
  }

  // ==========================================================
  // DAILY CHECK-IN
  // ==========================================================

  Future<void> _dailyCheckIn() async {
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

      final newHashRate =
          (data['hashRate'] as num?)
                  ?.toDouble() ??
              hashRate;

      final newStreak =
          (data['streak'] as num?)
                  ?.toInt() ??
              streak;

      final bonus =
          (data['bonus'] as num?)
                  ?.toDouble() ??
              dailyHashRateBonus;

      if (!mounted) return;

      setState(() {
        hashRate = newHashRate;

        streak = newStreak;

        dailyClaimed = true;

        miningPerHour =
            hashRate * 0.10;
      });

      if (alreadyClaimed) {
        _message(t.get('claimed'));
      } else {
        _message(
          '🎁 +${bonus.toStringAsFixed(0)} Hash Rate! '
          'Stella kiittää! 🐱⚡',
        );
      }
    } on FirebaseFunctionsException catch (error) {
      _message(
        error.message ??
            'Päivittäinen Stella Bonus epäonnistui.',
      );
    } catch (_) {
      _message(
        'Päivittäinen Stella Bonus epäonnistui.',
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
    if (adRewardLoading) return;

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

        if (!mounted) return;

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
    if (adRewardLoading) return;

    setState(() {
      adRewardLoading = true;
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
              adHashRateBonus;

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

        miningPerHour =
            hashRate * 0.10;
      });

      _message(
        '📺 +${bonus.toStringAsFixed(0)} '
        'Hash Rate! 🐱⚡',
      );

      await _loadMiningStatus(
        silent: true,
      );
    } on FirebaseFunctionsException catch (error) {
      _message(
        error.message ??
            'Mainospalkinnon hakeminen epäonnistui.',
      );

      await _loadMiningStatus(
        silent: true,
      );
    } catch (_) {
      _message(
        'Mainospalkinnon hakeminen epäonnistui.',
      );

      await _loadMiningStatus(
        silent: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          adRewardLoading = false;
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
        cooldownRemaining.inMinutes
            .remainder(60);

    final seconds =
        cooldownRemaining.inSeconds
            .remainder(60);

    if (hours > 0) {
      return '$hours h $minutes min';
    }

    if (minutes > 0) {
      return '$minutes min';
    }

    return '$seconds s';
  }

  // ==========================================================
  // DAILY REWARD TEXT
  // ==========================================================

  String _dailyRewardText() {
    if (dailyClaimed) {
      return '🎁 ${t.get('claimed')}';
    }

    return '🎁 +${dailyHashRateBonus.toStringAsFixed(0)} '
        'Hash Rate';
  }

  // ==========================================================
  // DAILY STREAK TEXT
  // ==========================================================

  String _dailyStreakText() {
    return '${t.get('streak')}: '
        '🔥 $streak päivää';
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
        DateTime.now().day % catFacts.length;

    final fact =
        catFacts[factIndex].text(
      widget.languageCode,
    );

    final adButtonEnabled =
        canWatchAd &&
            rewardedAd != null &&
            !rewardedAdLoading &&
            !adRewardLoading;

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

        onTransactionHistoryPressed:
            _openTransactionHistoryPage,
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
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),

      // ======================================================
      // BODY
      // ======================================================

      body: SafeArea(
        child: RefreshIndicator(
          color: accentColor,

          onRefresh: () =>
              _loadMiningStatus(),

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
              // ==============================================

              BalanceCard(
                miningBalance:
                    miningBalance,

                unclaimedMining:
                    unclaimedMining,

                hashRate:
                    hashRate,

                miningPerHour:
                    miningPerHour,

                title:
                    'Stella Mining',

                subtitle:
                    'Virtual mining progress',

                claimLoading:
                    miningClaimLoading,

                onClaimPressed:
                    miningClaimLoading
                        ? null
                        : _claimMining,
              ),

              const SizedBox(height: 14),

              // ==============================================
              // DAILY HASH RATE BONUS
              // ==============================================

              DailyRewardCard(
                title:
                    'Daily Stella Bonus',

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
                        ? _dailyCheckIn
                        : null,
              ),

              const SizedBox(height: 14),

              // ==============================================
              // WATCH AD
              // ==============================================

              WatchAdCard(
                title:
                    'Watch & Power Up',

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
                    adRewardLoading ||
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
                    'WATCH +${adHashRateBonus.toStringAsFixed(0)} HASH',

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

                fact:
                    fact,
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}