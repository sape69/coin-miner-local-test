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
// 🐱 STELLA COLORS
// ============================================================

const Color backgroundColor = Color(0xFF0B1112);
const Color accentColor = Color(0xFF35D0A0);
const Color stellaGoldColor = Color(0xFFFFC857);
const Color cardColor = Color(0xFF151B1C);

// ============================================================
// 📺 ADMOB TEST REWARDED AD
// ============================================================
//
// Google TEST Rewarded Ad Unit ID.
//
// Pidetään testimainokset käytössä kehityksen aikana.
// Oikea AdMob ID lisätään myöhemmin.
//
const String rewardedAdUnitId =
    'ca-app-pub-3940256099942544/5224354917';

// ============================================================
// 🐱 HOME PAGE
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
// 🐱 HOME PAGE STATE
// ============================================================

class _HomePageState extends State<HomePage> {
  // ==========================================================
  // ⛏️ MINING DATA
  // ==========================================================

  double miningBalance = 0;

  double unclaimedMining = 0;

  double estimatedTotal = 0;

  double hashRate = 1;

  double miningPerHour = 0;

  // ==========================================================
  // 🐱 24H MINING SESSION
  // ==========================================================

  bool miningActive = false;

  DateTime? miningStartedAt;

  DateTime? miningEndsAt;

  Duration miningRemaining = Duration.zero;

  // ==========================================================
  // 🎁 DAILY DATA
  // ==========================================================

  int streak = 0;

  bool dailyClaimed = false;

  // ==========================================================
  // 📺 AD DATA
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
  // 🔒 LOAD DATA PROTECTION
  // ==========================================================
  //
  // Estää tilanteen, jossa useampi Firebase-kutsu
  // on käynnissä samanaikaisesti.
  //
  bool _loadingData = false;

  // ==========================================================
  // 📺 ADMOB
  // ==========================================================

  RewardedAd? rewardedAd;

  bool rewardedAdLoading = false;

  // ==========================================================
  // ⏱️ TIMERS
  // ==========================================================

  Timer? refreshTimer;

  Timer? liveMiningTimer;

  // ==========================================================
  // 🐱 LOCALIZATION
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

    _startLiveMiningTimer();
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    refreshTimer?.cancel();

    liveMiningTimer?.cancel();

    rewardedAd?.dispose();

    super.dispose();
  }

  // ==========================================================
  // 🔒 LOAD DATA
  // ==========================================================

  Future<void> _loadData() async {
    // ========================================================
    // PREVENT OVERLAPPING REQUESTS
    // ========================================================

    if (_loadingData) {
      return;
    }

    _loadingData = true;

    try {
      // ======================================================
      // AUTH CHECK
      // ======================================================

      if (uid == null) {
        if (!mounted) return;

        setState(() {
          loading = false;
        });

        return;
      }

      // ======================================================
      // FIREBASE CALL
      // ======================================================

      final result =
          await functions
              .httpsCallable('getMiningStatus')
              .call();

      final rawData =
          Map<String, dynamic>.from(
        result.data as Map,
      );

      if (!mounted) return;

      // ======================================================
      // PARSE MINING SESSION
      // ======================================================

      DateTime? parsedStartedAt;

      DateTime? parsedEndsAt;

      final startedAtValue =
          rawData['miningStartedAt'];

      final endsAtValue =
          rawData['miningEndsAt'];

      if (startedAtValue is String &&
          startedAtValue.isNotEmpty) {
        parsedStartedAt =
            DateTime.tryParse(startedAtValue);
      }

      if (endsAtValue is String &&
          endsAtValue.isNotEmpty) {
        parsedEndsAt =
            DateTime.tryParse(endsAtValue);
      }

      // ======================================================
      // MINING REMAINING
      // ======================================================

      final remainingMs =
          (rawData['miningRemainingMs'] as num?)
                  ?.toInt() ??
              0;

      // ======================================================
      // AD COOLDOWN
      // ======================================================

      final cooldownMs =
          (rawData['cooldownRemainingMs'] as num?)
                  ?.toInt() ??
              0;

      // ======================================================
      // UPDATE STATE
      // ======================================================

      setState(() {
        // ====================================================
        // ⛏️ MINING
        // ====================================================

        hashRate =
            (rawData['hashRate'] as num?)
                    ?.toDouble() ??
                1;

        miningBalance =
            (rawData['miningBalance'] as num?)
                    ?.toDouble() ??
                0;

        unclaimedMining =
            (rawData['unclaimedMining'] as num?)
                    ?.toDouble() ??
                0;

        estimatedTotal =
            (rawData['estimatedTotal'] as num?)
                    ?.toDouble() ??
                miningBalance;

        miningPerHour =
            (rawData['miningPerHour'] as num?)
                    ?.toDouble() ??
                0;

        // ====================================================
        // 🐱 SESSION
        // ====================================================

        miningActive =
            rawData['miningActive'] == true;

        miningStartedAt =
            parsedStartedAt;

        miningEndsAt =
            parsedEndsAt;

        miningRemaining = Duration(
          milliseconds: remainingMs,
        );

        // ====================================================
        // 🎁 DAILY
        // ====================================================

        streak =
            (rawData['streak'] as num?)
                    ?.toInt() ??
                0;

        dailyClaimed =
            rawData['dailyClaimed'] == true;

        // ====================================================
        // 📺 ADS
        // ====================================================

        adsToday =
            (rawData['adsToday'] as num?)
                    ?.toInt() ??
                0;

        maxAdsPerDay =
            (rawData['maxAdsPerDay'] as num?)
                    ?.toInt() ??
                5;

        canWatchAd =
            rawData['canWatchAd'] == true;

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
            '🐱 Stella-yhteys epäonnistui.',
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      _message(
        '🐱 Stella-yhteys epäonnistui.',
      );
    } finally {
      // ======================================================
      // 🔓 RELEASE REQUEST LOCK
      // ======================================================

      _loadingData = false;
    }
  }

  // ==========================================================
  // 🔄 AUTO REFRESH
  // ==========================================================

  void _startRefreshTimer() {
    refreshTimer?.cancel();

    refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (!mounted) return;

        _loadData();
      },
    );
  }

  // ==========================================================
  // ⏱️ LIVE MINING TIMER
  // ==========================================================
  //
  // Päivittää:
  //
  // 📈 STL juoksevan määrän
  // ⏳ Mining countdownin
  // 📺 Ad cooldownin
  //
  void _startLiveMiningTimer() {
    liveMiningTimer?.cancel();

    liveMiningTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        bool changed = false;

        // ====================================================
        // 🐱 MINING COUNTDOWN
        // ====================================================

        if (miningActive) {
          if (miningRemaining >
              Duration.zero) {
            miningRemaining -=
                const Duration(seconds: 1);

            changed = true;

            // ================================================
            // 📈 LIVE STL COUNTER
            // ================================================

            final miningPerSecond =
                miningPerHour / 3600;

            if (miningPerSecond > 0) {
              unclaimedMining +=
                  miningPerSecond;

              estimatedTotal =
                  miningBalance +
                      unclaimedMining;

              changed = true;
            }
          } else {
            miningRemaining = Duration.zero;

            miningActive = false;

            changed = true;
          }
        }

        // ====================================================
        // 📺 AD COOLDOWN
        // ====================================================

        if (cooldownRemaining >
            Duration.zero) {
          cooldownRemaining -=
              const Duration(seconds: 1);

          changed = true;

          if (cooldownRemaining <=
              Duration.zero) {
            cooldownRemaining =
                Duration.zero;

            if (adsToday <
                maxAdsPerDay) {
              canWatchAd = true;
            }
          }
        }

        // ====================================================
        // UPDATE UI
        // ====================================================

        if (changed && mounted) {
          setState(() {});
        }
      },
    );
  }

  // ==========================================================
  // ⛏️ START / CLAIM MINING
  // ==========================================================

  Future<void> _claimMining() async {
    if (miningLoading) {
      return;
    }

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

      if (!mounted) return;

      final message =
          data['message'];

      final claimed =
          (data['claimed'] as num?)
                  ?.toDouble() ??
              0;

      // ======================================================
      // 🐱 MESSAGE
      // ======================================================

      if (message is String &&
          message.isNotEmpty) {
        _message('🐱 $message');
      } else if (claimed > 0) {
        _message(
          '🐱⛏️ ${claimed.toStringAsFixed(4)} STL lisätty!',
        );
      } else {
        _message(
          '🐱⛏️ Stella aloitti louhinnan!',
        );
      }

      await _loadData();
    } on FirebaseFunctionsException catch (error) {
      _message(
        error.message ??
            '🐱 Louhinta epäonnistui.',
      );
    } catch (_) {
      _message(
        '🐱 Louhinta epäonnistui.',
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
  // 🎁 DAILY CHECK-IN
  // ==========================================================

  Future<void> _dailyClaim() async {
    if (dailyLoading) {
      return;
    }

    if (dailyClaimed) {
      _message(
        '🐱 ${t.get('claimed')}',
      );

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
        _message(
          '🐱 ${t.get('claimed')}',
        );
      } else {
        _message(
          '🐱🎁 +${bonus.toStringAsFixed(0)} '
          'Hash Rate! ⚡',
        );
      }

      await _loadData();
    } on FirebaseFunctionsException catch (error) {
      _message(
        error.message ??
            '🐱 Päivittäinen bonus epäonnistui.',
      );
    } catch (_) {
      _message(
        '🐱 Päivittäinen bonus epäonnistui.',
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
  // 📺 LOAD REWARDED AD
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

          if (!mounted) {
            return;
          }

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
  // 📺 WATCH AD
  // ==========================================================

  Future<void> _watchAd() async {
    // ========================================================
    // CHECK AD LIMIT
    // ========================================================

    if (!canWatchAd) {
      if (cooldownRemaining >
          Duration.zero) {
        _message(
          '🐱 ${t.get('nextAd')}: '
          '${_remainingAdText()}',
        );
      } else {
        _message(
          '🐱 ${t.get('dailyLimitReached')}',
        );
      }

      return;
    }

    // ========================================================
    // CHECK LOADED AD
    // ========================================================

    if (rewardedAd == null) {
      _message(
        '🐱 ${t.get('adLoading')}',
      );

      _loadRewardedAd();

      return;
    }

    final ad = rewardedAd!;

    setState(() {
      rewardedAd = null;
    });

    bool earnedReward = false;

    // ========================================================
    // FULL SCREEN CALLBACK
    // ========================================================

    ad.fullScreenContentCallback =
        FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent:
          (dismissedAd) async {
        dismissedAd.dispose();

        // ================================================
        // 🐱 STELLA POWER BOOST
        // ================================================

        if (earnedReward) {
          await _claimAdReward();
        }

        _loadRewardedAd();
      },

      onAdFailedToShowFullScreenContent:
          (failedAd, error) {
        failedAd.dispose();

        _message(
          '🐱 Mainosta ei voitu näyttää.',
        );

        _loadRewardedAd();
      },
    );

    // ========================================================
    // SHOW AD
    // ========================================================

    ad.show(
      onUserEarnedReward:
          (ad, reward) {
        earnedReward = true;
      },
    );
  }

  // ==========================================================
  // ⚡ CLAIM TEST AD REWARD
  // ==========================================================

  Future<void> _claimAdReward() async {
    if (adClaimLoading) {
      return;
    }

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
        '🐱⚡ Stella Power Boost! '
        '+${bonus.toStringAsFixed(0)} Hash Rate!',
      );

      await _loadData();
    } on FirebaseFunctionsException catch (error) {
      _message(
        error.message ??
            '🐱 Stella Power Boost epäonnistui.',
      );

      await _loadData();
    } catch (_) {
      _message(
        '🐱 Stella Power Boost epäonnistui.',
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
  // ⏳ FORMAT MINING TIME
  // ==========================================================

  String _remainingMiningText() {
    if (miningRemaining <=
        Duration.zero) {
      return '00:00:00';
    }

    final hours =
        miningRemaining.inHours;

    final minutes =
        miningRemaining.inMinutes
            .remainder(60);

    final seconds =
        miningRemaining.inSeconds
            .remainder(60);

    String twoDigits(int value) =>
        value.toString().padLeft(2, '0');

    return '${twoDigits(hours)}:'
        '${twoDigits(minutes)}:'
        '${twoDigits(seconds)}';
  }

  // ==========================================================
  // ⏳ FORMAT AD TIME
  // ==========================================================

  String _remainingAdText() {
    if (cooldownRemaining <=
        Duration.zero) {
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
  // 🎁 DAILY REWARD TEXT
  // ==========================================================

  String _dailyRewardText() {
    if (dailyClaimed) {
      return '🎁 ${t.get('claimed')}';
    }

    return '🐱🎁 +1 Hash Rate';
  }

  // ==========================================================
  // 🔥 DAILY STREAK TEXT
  // ==========================================================

  String _dailyStreakText() {
    return '${t.get('streak')}: '
        '🔥 Stella Day $streak';
  }

  // ==========================================================
  // 🐱 MESSAGE
  // ==========================================================

  void _message(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,

          backgroundColor:
              const Color(0xFF1A2425),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),

          content: Text(message),
        ),
      );
  }

  // ==========================================================
  // 🚪 LOGOUT
  // ==========================================================

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  // ==========================================================
  // 🌍 LANGUAGE
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
  // 📜 NAVIGATION
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
  // 🐱 BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    // ========================================================
    // LOADING
    // ========================================================

    if (loading) {
      return const Scaffold(
        backgroundColor:
            backgroundColor,

        body: Center(
          child:
              CircularProgressIndicator(
            color: accentColor,
          ),
        ),
      );
    }

    // ========================================================
    // 🐱 DAILY CAT FACT
    // ========================================================

    final factIndex =
        DateTime.now().day %
            catFacts.length;

    final fact =
        catFacts[factIndex].text(
      widget.languageCode,
    );

    // ========================================================
    // 📺 AD BUTTON
    // ========================================================

    final adButtonEnabled =
        canWatchAd &&
            rewardedAd != null &&
            !adClaimLoading;

    // ========================================================
    // 🎁 DAILY BUTTON
    // ========================================================

    final dailyButtonEnabled =
        !dailyClaimed &&
            !dailyLoading;

    // ========================================================
    // 📺 NEXT AD TEXT
    // ========================================================

    final nextAdText =
        cooldownRemaining >
                Duration.zero
            ? '${t.get('nextAd')}: '
                '${_remainingAdText()}'
            : '';

    // ========================================================
    // 🐱 SCAFFOLD
    // ========================================================

    return Scaffold(
      backgroundColor:
          backgroundColor,

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
        backgroundColor:
            backgroundColor,

        elevation: 0,

        title: const Row(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            Text(
              '🐱',
              style:
                  TextStyle(fontSize: 22),
            ),

            SizedBox(width: 8),

            Text(
              'STELLURIINI',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,

                letterSpacing: 2,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip:
                'Kirjaudu ulos',

            icon:
                const Icon(Icons.logout),

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

          onRefresh: _loadData,

          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),

            padding:
                const EdgeInsets.all(16),

            children: [
              // ==============================================
              // 🐱 STELLA PROFILE
              // ==============================================

              ProfileCard(
                title: t.get('stella'),
              ),

              const SizedBox(height: 14),

              // ==============================================
              // ⛏️ STELLA MINING SESSION
              // ==============================================

              _MiningSessionCard(
                miningActive:
                    miningActive,

                remainingText:
                    _remainingMiningText(),

                hashRate:
                    hashRate,

                miningPerHour:
                    miningPerHour,
              ),

              const SizedBox(height: 14),

              // ==============================================
              // 💰 BALANCE
              // ==============================================

              BalanceCard(
                title:
                    t.get('yourBalance'),

                estimatedTotal:
                    estimatedTotal,

                miningBalance:
                    miningBalance,

                unclaimedMining:
                    unclaimedMining,

                hashRate:
                    hashRate,

                miningPerHour:
                    miningPerHour,
              ),

              const SizedBox(height: 14),

              // ==============================================
              // ⛏️ START / MINING BUTTON
              // ==============================================

              SizedBox(
                width: double.infinity,

                child:
                    ElevatedButton.icon(
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
                            color: Colors.black,
                          ),
                        )
                      : Icon(
                          miningActive
                              ? Icons.pets
                              : Icons
                                  .precision_manufacturing,
                        ),

                  label: Text(
                    miningLoading
                        ? '🐱 STELLA VALMISTAUTUU...'
                        : miningActive
                            ? '🐱⛏️ STELLA IS MINING'
                            : '🐱⛏️ START STELLA MINING',
                  ),

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        accentColor,

                    foregroundColor:
                        Colors.black,

                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 18,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                    ),

                    textStyle:
                        const TextStyle(
                      fontSize: 14,

                      fontWeight:
                          FontWeight.bold,

                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ==============================================
              // 🎁 DAILY BONUS
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
              // 📺 STELLA POWER BOOST
              // ==============================================

              WatchAdCard(
                title:
                    '🐱⚡ STELLA POWER BOOST',

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
                    adClaimLoading ||
                        rewardedAdLoading,

                adReady:
                    rewardedAd != null,

                loadingText:
                    '🐱 Stella hakee mainosta...',

                limitReachedText:
                    '🐱 Stella on saanut '
                    'päivän kaikki boostit!',

                unavailableText:
                    '🐱 Power Boost ei ole '
                    'vielä saatavilla.',

                watchButtonText:
                    '📺 WATCH & BOOST STELLA ⚡',

                onPressed:
                    adButtonEnabled
                        ? _watchAd
                        : null,
              ),

              const SizedBox(height: 14),

              // ==============================================
              // 🐱 STELLA FACT
              // ==============================================

              CatFactCard(
                title:
                    '🐱 ${t.get('stellaFacts')}',

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
// 🐱 STELLA MINING SESSION CARD
// ============================================================

class _MiningSessionCard
    extends StatelessWidget {
  final bool miningActive;

  final String remainingText;

  final double hashRate;

  final double miningPerHour;

  const _MiningSessionCard({
    required this.miningActive,
    required this.remainingText,
    required this.hashRate,
    required this.miningPerHour,
  });

  String _format(double value) {
    if (value >= 1000) {
      return value.toStringAsFixed(0);
    }

    if (value >= 10) {
      return value.toStringAsFixed(1);
    }

    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor =
        miningActive
            ? accentColor
            : Colors.white54;

    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: cardColor,

        borderRadius:
            BorderRadius.circular(24),

        border: Border.all(
          color:
              accentColor.withValues(
            alpha: miningActive
                ? 0.45
                : 0.15,
          ),
        ),

        boxShadow: miningActive
            ? [
                BoxShadow(
                  color:
                      accentColor.withValues(
                    alpha: 0.08,
                  ),

                  blurRadius: 24,

                  spreadRadius: 1,
                ),
              ]
            : [],
      ),

      child: Column(
        children: [
          const Text(
            '🐱⛏️',
            style: TextStyle(
              fontSize: 38,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            miningActive
                ? 'STELLA IS MINING'
                : 'STELLA IS RESTING',
            style: TextStyle(
              color: statusColor,

              fontWeight:
                  FontWeight.bold,

              letterSpacing: 2,

              fontSize: 14,
            ),
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,

            padding:
                const EdgeInsets.symmetric(
              vertical: 16,
            ),

            decoration: BoxDecoration(
              color:
                  accentColor.withValues(
                alpha: 0.08,
              ),

              borderRadius:
                  BorderRadius.circular(18),
            ),

            child: Column(
              children: [
                const Text(
                  '⏳ MINING TIME REMAINING',
                  style: TextStyle(
                    color: Colors.white54,

                    fontSize: 11,

                    fontWeight:
                        FontWeight.bold,

                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  miningActive
                      ? remainingText
                      : 'READY',

                  style: TextStyle(
                    color: statusColor,

                    fontSize: 30,

                    fontWeight:
                        FontWeight.bold,

                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child:
                    _SessionStat(
                  icon: Icons.bolt,

                  label: 'HASH RATE',

                  value:
                      '${_format(hashRate)} HR',
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child:
                    _SessionStat(
                  icon:
                      Icons.trending_up,

                  label: 'MINING SPEED',

                  value:
                      '${_format(miningPerHour)} STL/h',
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            miningActive
                ? '🐱 Stella louhii STL:ää juuri nyt... ⛏️✨'
                : '🐱 Paina START ja anna Stellan aloittaa!',
            textAlign:
                TextAlign.center,

            style: TextStyle(
              color:
                  Colors.white.withValues(
                alpha: 0.55,
              ),

              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 📊 SESSION STAT
// ============================================================

class _SessionStat
    extends StatelessWidget {
  final IconData icon;

  final String label;

  final String value;

  const _SessionStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color:
            Colors.white.withValues(
          alpha: 0.04,
        ),

        borderRadius:
            BorderRadius.circular(16),
      ),

      child: Column(
        children: [
          Icon(
            icon,

            color: accentColor,

            size: 20,
          ),

          const SizedBox(height: 7),

          Text(
            label,

            textAlign:
                TextAlign.center,

            style: const TextStyle(
              color: Colors.white54,

              fontSize: 10,

              fontWeight:
                  FontWeight.bold,

              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            value,

            textAlign:
                TextAlign.center,

            style: const TextStyle(
              color: Colors.white,

              fontSize: 13,

              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}