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

const Color cardColor = Color(0xFF151B1C);

const Color stellaGold = Color(0xFFFFD166);

// ============================================================
// 📺 ADMOB TEST REWARDED AD
// ============================================================

/// Google test Rewarded Ad.
///
/// Pidämme tämän käytössä kehityksen aikana.
/// Vaihdetaan myöhemmin oikeaan AdMob Ad Unit ID:hen.
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
  State<HomePage> createState() =>
      _HomePageState();
}

// ============================================================
// 🐱 HOME PAGE STATE
// ============================================================

class _HomePageState
    extends State<HomePage>
    with WidgetsBindingObserver {
  // ==========================================================
  // 🐱 MINING DATA
  // ==========================================================

  double miningBalance = 0;

  double unclaimedMining = 0;

  double estimatedTotal = 0;

  double hashRate = 1;

  double miningPerHour = 0;

  int streak = 0;

  bool miningActive = false;

  int miningRemainingMs = 0;

  int miningDurationMs =
      const Duration(hours: 24).inMilliseconds;

  DateTime? lastMiningServerTime;

  DateTime? miningEndTime;

  // ==========================================================
  // 🎁 DAILY DATA
  // ==========================================================

  bool dailyClaimed = false;

  // ==========================================================
  // 📺 AD DATA
  // ==========================================================

  int adsToday = 0;

  int maxAdsPerDay = 5;

  bool canWatchAd = false;

  Duration cooldownRemaining =
      Duration.zero;

  // ==========================================================
  // 🔄 LOADING STATES
  // ==========================================================

  bool loading = true;

  bool loadDataRunning = false;

  bool dailyLoading = false;

  bool miningLoading = false;

  bool adClaimLoading = false;

  // ==========================================================
  // 📺 ADMOB
  // ==========================================================

  RewardedAd? rewardedAd;

  bool rewardedAdLoading = false;

  // ==========================================================
  // ⏱️ TIMERS
  // ==========================================================

  Timer? refreshTimer;

  Timer? realtimeTimer;

  Timer? cooldownTimer;

  // ==========================================================
  // 🌍 LOCALIZATION
  // ==========================================================

  AppLocalizations get t =>
      AppLocalizations(
        widget.languageCode,
      );

  // ==========================================================
  // 🔥 FIREBASE
  // ==========================================================

  FirebaseFunctions get functions =>
      FirebaseFunctions.instance;

  String? get uid =>
      FirebaseAuth
          .instance
          .currentUser
          ?.uid;

  // ==========================================================
  // 🚀 INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addObserver(this);

    _loadData();

    _loadRewardedAd();

    _startRefreshTimer();

    _startRealtimeTimer();

    _startCooldownTimer();
  }

  // ==========================================================
  // 📱 APP LIFECYCLE
  // ==========================================================

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state ==
        AppLifecycleState.resumed) {
      _loadData();
    }
  }

  // ==========================================================
  // 🗑️ DISPOSE
  // ==========================================================

  @override
  void dispose() {
    WidgetsBinding.instance
        .removeObserver(this);

    refreshTimer?.cancel();

    realtimeTimer?.cancel();

    cooldownTimer?.cancel();

    rewardedAd?.dispose();

    super.dispose();
  }

  // ==========================================================
  // 🔒 LOAD DATA
  //
  // Tämä suojaa päällekkäisiltä Firebase-kutsuilta.
  // ==========================================================

  Future<void> _loadData() async {
    if (loadDataRunning) {
      return;
    }

    if (uid == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        loading = false;
      });

      return;
    }

    loadDataRunning = true;

    try {
      final result =
          await functions
              .httpsCallable(
                'getMiningStatus',
              )
              .call();

      final data =
          Map<String, dynamic>.from(
        result.data as Map,
      );

      if (!mounted) {
        return;
      }

      final cooldownMs =
          (data['cooldownRemainingMs']
                      as num?)
                  ?.toInt() ??
              0;

      final serverRemainingMs =
          (data['miningRemainingMs']
                      as num?)
                  ?.toInt() ??
              0;

      final serverDurationMs =
          (data['miningDurationMs']
                      as num?)
                  ?.toInt() ??
              const Duration(hours: 24)
                  .inMilliseconds;

      final active =
          data['miningActive'] == true;

      final now = DateTime.now();

      setState(() {
        // ====================================================
        // ⛏️ MINING
        // ====================================================

        hashRate =
            (data['hashRate'] as num?)
                    ?.toDouble() ??
                1;

        miningBalance =
            (data['miningBalance'] as num?)
                    ?.toDouble() ??
                0;

        unclaimedMining =
            (data['unclaimedMining']
                        as num?)
                    ?.toDouble() ??
                0;

        estimatedTotal =
            (data['estimatedTotal']
                        as num?)
                    ?.toDouble() ??
                miningBalance +
                    unclaimedMining;

        miningPerHour =
            (data['miningPerHour']
                        as num?)
                    ?.toDouble() ??
                0;

        miningActive = active;

        miningRemainingMs =
            serverRemainingMs;

        miningDurationMs =
            serverDurationMs;

        if (
            miningActive &&
            miningRemainingMs > 0) {
          miningEndTime =
              now.add(
            Duration(
              milliseconds:
                  miningRemainingMs,
            ),
          );
        } else {
          miningEndTime = null;
        }

        lastMiningServerTime = now;

        // ====================================================
        // 🎁 DAILY
        // ====================================================

        streak =
            (data['streak'] as num?)
                    ?.toInt() ??
                0;

        dailyClaimed =
            data['dailyClaimed'] == true;

        // ====================================================
        // 📺 ADS
        // ====================================================

        adsToday =
            (data['adsToday'] as num?)
                    ?.toInt() ??
                0;

        maxAdsPerDay =
            (data['maxAdsPerDay']
                        as num?)
                    ?.toInt() ??
                5;

        canWatchAd =
            data['canWatchAd'] == true;

        cooldownRemaining =
            Duration(
          milliseconds:
              cooldownMs,
        );

        loading = false;
      });
    } on FirebaseFunctionsException catch (
      error,
    ) {
      if (!mounted) {
        return;
      }

      setState(() {
        loading = false;
      });

      _message(
        error.message ??
            '🐱 Stella-yhteys epäonnistui.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        loading = false;
      });

      _message(
        '🐱 Stella-yhteys epäonnistui.',
      );
    } finally {
      loadDataRunning = false;
    }
  }

  // ==========================================================
  // 🔄 AUTO REFRESH
  // ==========================================================

  void _startRefreshTimer() {
    refreshTimer?.cancel();

    refreshTimer =
        Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (
            mounted &&
            !loading &&
            !loadDataRunning) {
          _loadData();
        }
      },
    );
  }

  // ==========================================================
  // ⚡ REALTIME STL TIMER
  //
  // Päivittää näytöllä juoksevan STL-määrän.
  // ==========================================================

  void _startRealtimeTimer() {
    realtimeTimer?.cancel();

    realtimeTimer =
        Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) {
          return;
        }

        if (
            !miningActive ||
            miningEndTime == null) {
          return;
        }

        final now =
            DateTime.now();

        final remaining =
            miningEndTime!
                .difference(now);

        if (
            remaining <= Duration.zero) {
          setState(() {
            miningRemainingMs = 0;

            miningActive = false;

            miningEndTime = null;
          });

          _loadData();

          return;
        }

        // ====================================================
        // REALTIME MINING
        // ====================================================

        final elapsedSinceServer =
            lastMiningServerTime == null
                ? Duration.zero
                : now.difference(
                    lastMiningServerTime!,
                  );

        final additionalMining =
            miningPerHour *
                elapsedSinceServer
                    .inMilliseconds /
                const Duration(hours: 1)
                    .inMilliseconds;

        setState(() {
          miningRemainingMs =
              remaining.inMilliseconds;

          estimatedTotal =
              miningBalance +
                  unclaimedMining +
                  additionalMining;
        });
      },
    );
  }

  // ==========================================================
  // ⏱️ COOLDOWN TIMER
  // ==========================================================

  void _startCooldownTimer() {
    cooldownTimer?.cancel();

    cooldownTimer =
        Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) {
          return;
        }

        if (
            cooldownRemaining >
                Duration.zero) {
          setState(() {
            cooldownRemaining -=
                const Duration(seconds: 1);

            if (
                cooldownRemaining <=
                    Duration.zero) {
              cooldownRemaining =
                  Duration.zero;

              if (
                  adsToday <
                      maxAdsPerDay) {
                canWatchAd = true;
              }
            }
          });
        }
      },
    );
  }

  // ==========================================================
  // ⛏️ START MINING
  // ==========================================================

  Future<void> _startMining() async {
    if (miningLoading) {
      return;
    }

    if (miningActive) {
      _message(
        '🐱⛏️ Stella Mining on jo käynnissä!',
      );

      return;
    }

    setState(() {
      miningLoading = true;
    });

    try {
      final result =
          await functions
              .httpsCallable(
                'startMining',
              )
              .call();

      final data =
          Map<String, dynamic>.from(
        result.data as Map,
      );

      if (!mounted) {
        return;
      }

      final alreadyActive =
          data['alreadyActive'] == true;

      if (alreadyActive) {
        _message(
          '🐱⛏️ Stella Mining on jo käynnissä!',
        );
      } else {
        _message(
          '🐱✨ Stella Mining käynnistyi! '
          'STL juoksee seuraavat 24 tuntia ⛏️⚡',
        );
      }

      await _loadData();
    } on FirebaseFunctionsException catch (
      error,
    ) {
      _message(
        error.message ??
            '🐱 Louhinnan käynnistäminen epäonnistui.',
      );
    } catch (_) {
      _message(
        '🐱 Louhinnan käynnistäminen epäonnistui.',
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
        '🐱 Stella-bonus on jo kerätty tänään!',
      );

      return;
    }

    setState(() {
      dailyLoading = true;
    });

    try {
      final result =
          await functions
              .httpsCallable(
                'dailyCheckIn',
              )
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

      if (!mounted) {
        return;
      }

      if (alreadyClaimed) {
        _message(
          '🎁 Stella-bonus on jo kerätty!',
        );
      } else {
        _message(
          '🐱⚡ Stella antoi +${bonus.toStringAsFixed(0)} Hash Rate!',
        );
      }

      await _loadData();
    } on FirebaseFunctionsException catch (
      error,
    ) {
      _message(
        error.message ??
            '🐱 Päivittäinen Stella-bonus epäonnistui.',
      );
    } catch (_) {
      _message(
        '🐱 Päivittäinen Stella-bonus epäonnistui.',
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
    if (
        rewardedAdLoading ||
        rewardedAd != null) {
      return;
    }

    rewardedAdLoading = true;

    RewardedAd.load(
      adUnitId:
          rewardedAdUnitId,
      request:
          const AdRequest(),
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
        onAdFailedToLoad: (
          error,
        ) {
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
    if (adClaimLoading) {
      return;
    }

    if (!canWatchAd) {
      if (
          cooldownRemaining >
              Duration.zero) {
        _message(
          '🐱 Stella lepää vielä '
          '${_remainingAdText()}',
        );
      } else {
        _message(
          '📺 Päivän Stella-mainosraja on saavutettu.',
        );
      }

      return;
    }

    if (rewardedAd == null) {
      _message(
        '🐱📺 Stella valmistaa mainosta...',
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
          (dismissedAd) async {
        dismissedAd.dispose();

        if (earnedReward) {
          await _claimTestAdReward();
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

    ad.show(
      onUserEarnedReward:
          (ad, reward) {
        earnedReward = true;
      },
    );
  }

  // ==========================================================
  // 🧪 TEST AD REWARD
  //
  // Käytössä kehityksen aikana.
  // ==========================================================

  Future<void> _claimTestAdReward() async {
    if (adClaimLoading) {
      return;
    }

    setState(() {
      adClaimLoading = true;
    });

    try {
      final result =
          await functions
              .httpsCallable(
                'testAdReward',
              )
              .call();

      final data =
          Map<String, dynamic>.from(
        result.data as Map,
      );

      final bonus =
          (data['bonus'] as num?)
                  ?.toDouble() ??
              0;

      if (!mounted) {
        return;
      }

      _message(
        '📺🐱⚡ Stella Power Boost! '
        '+${bonus.toStringAsFixed(0)} Hash Rate!',
      );

      await _loadData();
    } on FirebaseFunctionsException catch (
      error,
    ) {
      _message(
        error.message ??
            '🐱 Mainospalkinnon hakeminen epäonnistui.',
      );

      await _loadData();
    } catch (_) {
      _message(
        '🐱 Mainospalkinnon hakeminen epäonnistui.',
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
  // ⏱️ REMAINING AD TEXT
  // ==========================================================

  String _remainingAdText() {
    if (
        cooldownRemaining <=
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
  // ⛏️ MINING TIME TEXT
  // ==========================================================

  String _miningTimeText() {
    if (!miningActive) {
      return 'VALMIS ALOITTAMAAN';
    }

    final duration =
        Duration(
      milliseconds:
          miningRemainingMs,
    );

    final hours =
        duration.inHours;

    final minutes =
        duration.inMinutes
            .remainder(60);

    final seconds =
        duration.inSeconds
            .remainder(60);

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // ==========================================================
  // 🎁 DAILY REWARD TEXT
  // ==========================================================

  String _dailyRewardText() {
    if (dailyClaimed) {
      return '🎁 KERÄTTY TÄNÄÄN';
    }

    return '🎁 +1 HASH RATE';
  }

  // ==========================================================
  // 🔥 DAILY STREAK TEXT
  // ==========================================================

  String _dailyStreakText() {
    return '🔥 Stella Streak: '
        '$streak päivää';
  }

  // ==========================================================
  // 💬 MESSAGE
  // ==========================================================

  void _message(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(message),
          backgroundColor:
              cardColor,
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  // ==========================================================
  // 🚪 LOGOUT
  // ==========================================================

  Future<void> _logout() async {
    await FirebaseAuth.instance
        .signOut();
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
  Widget build(
    BuildContext context,
  ) {
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
        cooldownRemaining >
                Duration.zero
            ? '🐱 Seuraava Stella-mainos: '
                '${_remainingAdText()}'
            : '';

    return Scaffold(
      backgroundColor:
          backgroundColor,

      // ======================================================
      // 🐱 DRAWER
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
      // 🐱 APP BAR
      // ======================================================

      appBar: AppBar(
        title: const Text(
          '🐱 STELLURIINI',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            tooltip:
                'Kirjaudu ulos',
            icon: const Icon(
              Icons.logout,
            ),
            onPressed:
                _logout,
          ),
        ],
      ),

      // ======================================================
      // BODY
      // ======================================================

      body: SafeArea(
        child: RefreshIndicator(
          color:
              accentColor,
          onRefresh:
              _loadData,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.all(16),
            children: [
              // ==============================================
              // 🐱 PROFILE
              // ==============================================

              ProfileCard(
                title:
                    t.get('stella'),
              ),

              const SizedBox(
                height: 14,
              ),

              // ==============================================
              // ⛏️ BALANCE
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

              const SizedBox(
                height: 14,
              ),

              // ==============================================
              // ⏱️ 24H STELLA MINING STATUS
              // ==============================================

              Container(
                padding:
                    const EdgeInsets.all(18),
                decoration:
                    BoxDecoration(
                  color:
                      cardColor,
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                  border:
                      Border.all(
                    color: miningActive
                        ? accentColor
                            .withValues(
                            alpha: 0.45,
                          )
                        : Colors.white
                            .withValues(
                            alpha: 0.08,
                          ),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      miningActive
                          ? '🐱⛏️ STELLA MINING ACTIVE'
                          : '🐱⛏️ STELLA MINING READY',
                      style: TextStyle(
                        color: miningActive
                            ? accentColor
                            : Colors.white
                                .withValues(
                                alpha: 0.75,
                              ),
                        fontWeight:
                            FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Text(
                      _miningTimeText(),
                      style: TextStyle(
                        color: miningActive
                            ? accentColor
                            : stellaGold,
                        fontSize: 30,
                        fontWeight:
                            FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      miningActive
                          ? 'STL juoksee reaaliajassa ⚡🐱'
                          : 'Aloita uusi 24h Stella Mining ⛏️',
                      style: TextStyle(
                        color: Colors.white
                            .withValues(
                          alpha: 0.60,
                        ),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              // ==============================================
              // ⛏️ START MINING
              // ==============================================

              SizedBox(
                width:
                    double.infinity,
                child:
                    ElevatedButton.icon(
                  onPressed:
                      miningLoading ||
                              miningActive
                          ? null
                          : _startMining,
                  icon: miningLoading
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
                      : Icon(
                          miningActive
                              ? Icons
                                  .bolt
                              : Icons
                                  .precision_manufacturing,
                        ),
                  label: Text(
                    miningLoading
                        ? '🐱 STELLA VALMISTELEE...'
                        : miningActive
                            ? '⚡ STELLA MINING ACTIVE'
                            : '🐱⛏️ START 24H MINING',
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        accentColor,
                    foregroundColor:
                        Colors.black,
                    disabledBackgroundColor:
                        accentColor
                            .withValues(
                      alpha: 0.25,
                    ),
                    disabledForegroundColor:
                        Colors.white
                            .withValues(
                      alpha: 0.45,
                    ),
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
                      fontSize: 15,
                      fontWeight:
                          FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              // ==============================================
              // 🎁 DAILY STELLA BONUS
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

              const SizedBox(
                height: 14,
              ),

              // ==============================================
              // 📺 WATCH AD
              // ==============================================

              WatchAdCard(
                title:
                    '🐱⚡ STELLA POWER BOOST',
                dailyLimitText:
                    'Päivän Stella-mainokset',
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
                    '🐱📺 Stella valmistaa mainosta...',
                limitReachedText:
                    '🐱 Päivän Stella-mainosraja saavutettu.',
                unavailableText:
                    '📺 Mainos ei ole vielä valmis.',
                watchButtonText:
                    '📺 WATCH & POWER UP ⚡',
                onPressed:
                    adButtonEnabled
                        ? _watchAd
                        : null,
              ),

              const SizedBox(
                height: 14,
              ),

              // ==============================================
              // 🐱 STELLA FACT
              // ==============================================

              CatFactCard(
                title:
                    '🐱 ${t.get('stellaFacts')}',
                fact:
                    fact,
              ),

              const SizedBox(
                height: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}