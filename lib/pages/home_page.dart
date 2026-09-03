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

const Color stellaGreen = Color(0xFF35D0A0);

const Color stellaCardColor = Color(0xFF151B1C);

// ============================================================
// 📺 ADMOB
// ============================================================

/// Google Rewarded Ad TEST ID.
///
/// Pidetään testimainokset käytössä niin kauan kuin
/// Stelluriini-sovellus on kehitysvaiheessa.
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
    extends State<HomePage> {
  // ==========================================================
  // ⛏️ STELLA MINING DATA
  // ==========================================================

  double miningBalance = 0;

  double unclaimedMining = 0;

  double estimatedTotal = 0;

  double hashRate = 1;

  double miningPerHour = 0;

  // ==========================================================
  // ⏱️ 24H MINING SESSION
  // ==========================================================

  bool miningActive = false;

  int miningStartMs = 0;

  int miningEndMs = 0;

  int sessionDurationMs =
      24 * 60 * 60 * 1000;

  // Paikallinen reaaliaikainen STL-arvo.
  double realtimeMining = 0;

  Duration miningRemaining =
      Duration.zero;

  // ==========================================================
  // 🐱 DAILY STELLA BONUS
  // ==========================================================

  int streak = 0;

  bool dailyClaimed = false;

  // ==========================================================
  // 📺 ADMOB DATA
  // ==========================================================

  int adsToday = 0;

  int maxAdsPerDay = 5;

  bool canWatchAd = false;

  Duration cooldownRemaining =
      Duration.zero;

  // ==========================================================
  // 🎨 UI STATES
  // ==========================================================

  bool loading = true;

  bool miningLoading = false;

  bool dailyLoading = false;

  bool adClaimLoading = false;

  // ==========================================================
  // 🔒 FIREBASE LOAD PROTECTION
  // ==========================================================

  /// Estää päällekkäiset getMiningStatus-kutsut.
  ///
  /// Esimerkiksi:
  /// - sivun avaus
  /// - pull-to-refresh
  /// - 30 sekunnin refresh
  ///
  /// eivät voi käynnistää samaa Firebase-kutsua
  /// samanaikaisesti.
  bool _isLoadingData = false;

  // ==========================================================
  // 📺 ADMOB
  // ==========================================================

  RewardedAd? rewardedAd;

  bool rewardedAdLoading = false;

  // ==========================================================
  // ⏱️ TIMERS
  // ==========================================================

  Timer? refreshTimer;

  Timer? cooldownTimer;

  Timer? miningTimer;

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
      FirebaseAuth.instance
          .currentUser
          ?.uid;

  // ==========================================================
  // 🚀 INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _loadData();

    _loadRewardedAd();

    _startRefreshTimer();

    _startCooldownTimer();

    _startMiningTimer();
  }

  // ==========================================================
  // 🧹 DISPOSE
  // ==========================================================

  @override
  void dispose() {
    refreshTimer?.cancel();

    cooldownTimer?.cancel();

    miningTimer?.cancel();

    rewardedAd?.dispose();

    super.dispose();
  }

  // ==========================================================
  // 🐱 LOAD STELLA MINING DATA
  // ==========================================================

  Future<void> _loadData() async {
    // ========================================================
    // 🔒 PREVENT OVERLAPPING REQUESTS
    // ========================================================

    if (_isLoadingData) {
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

    _isLoadingData = true;

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

      // ======================================================
      // ⏱️ SESSION DATA
      // ======================================================

      final newMiningActive =
          data['miningActive'] == true;

      final newMiningStartMs =
          (data['miningStartMs'] as num?)
                  ?.toInt() ??
              0;

      final newMiningEndMs =
          (data['miningEndMs'] as num?)
                  ?.toInt() ??
              0;

      final newSessionDurationMs =
          (data['sessionDurationMs'] as num?)
                  ?.toInt() ??
              24 * 60 * 60 * 1000;

      // ======================================================
      // 📺 COOLDOWN
      // ======================================================

      final cooldownMs =
          (data['cooldownRemainingMs'] as num?)
                  ?.toInt() ??
              0;

      if (!mounted) {
        return;
      }

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

        // ====================================================
        // ⏱️ MINING SESSION
        // ====================================================

        miningActive =
            newMiningActive;

        miningStartMs =
            newMiningStartMs;

        miningEndMs =
            newMiningEndMs;

        sessionDurationMs =
            newSessionDurationMs;

        // ====================================================
        // 🐱 DAILY
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

      // Päivitä Stella-louhinta heti.
      _updateRealtimeMining();
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
      // ======================================================
      // 🔓 RELEASE LOAD LOCK
      // ======================================================

      _isLoadingData = false;
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
        if (!mounted) {
          return;
        }

        if (!loading) {
          _loadData();
        }
      },
    );
  }

  // ==========================================================
  // ⏱️ MINING REALTIME TIMER
  // ==========================================================

  void _startMiningTimer() {
    miningTimer?.cancel();

    miningTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) {
          return;
        }

        _updateRealtimeMining();
      },
    );
  }

  // ==========================================================
  // 📈 UPDATE REALTIME MINING
  // ==========================================================

  void _updateRealtimeMining() {
    if (!mounted) {
      return;
    }

    if (!miningActive) {
      if (miningRemaining != Duration.zero) {
        setState(() {
          miningRemaining =
              Duration.zero;

          realtimeMining =
              unclaimedMining;
        });
      }

      return;
    }

    if (miningEndMs <= 0) {
      return;
    }

    final nowMs =
        DateTime.now()
            .millisecondsSinceEpoch;

    // ========================================================
    // ⏰ SESSION FINISHED
    // ========================================================

    if (nowMs >= miningEndMs) {
      setState(() {
        miningActive = false;

        miningRemaining =
            Duration.zero;

        realtimeMining =
            unclaimedMining;
      });

      _message(
        '🐱✨ Stella Mining Session valmis! '
        'Paina LOUHI aloittaaksesi uuden 24h louhinnan. ⛏️',
      );

      _loadData();

      return;
    }

    // ========================================================
    // ⏱️ REMAINING TIME
    // ========================================================

    final remainingMs =
        miningEndMs - nowMs;

    // ========================================================
    // 📈 REALTIME STL
    // ========================================================

    final sessionElapsedMs =
        nowMs - miningStartMs;

    final safeElapsedMs =
        sessionElapsedMs.clamp(
          0,
          sessionDurationMs,
        );

    final hours =
        safeElapsedMs /
            (1000 * 60 * 60);

    final realtimeAmount =
        hashRate *
            0.10 *
            hours;

    setState(() {
      miningRemaining = Duration(
        milliseconds: remainingMs,
      );

      realtimeMining =
          realtimeAmount;

      unclaimedMining =
          realtimeAmount;

      estimatedTotal =
          miningBalance +
              realtimeAmount;
    });
  }

  // ==========================================================
  // ⏱️ COOLDOWN TIMER
  // ==========================================================

  void _startCooldownTimer() {
    cooldownTimer?.cancel();

    cooldownTimer = Timer.periodic(
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
                const Duration(
                  seconds: 1,
                );

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
  // ⛏️ START 24H STELLA MINING
  // ==========================================================

  Future<void> _startMining() async {
    if (miningLoading) {
      return;
    }

    if (miningActive) {
      _message(
        '🐱⛏️ Stella louhii jo! '
        '${_miningRemainingText()} jäljellä.',
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

      _message(
        data['message'] ??
            '🐱⛏️ Stella Mining käynnistyi! '
                'Louhinta jatkuu seuraavat 24 tuntia. ✨',
      );

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
  // 🐱 DAILY STELLA CHECK-IN
  // ==========================================================

  Future<void> _dailyClaim() async {
    if (dailyLoading) {
      return;
    }

    if (dailyClaimed) {
      _message(
        '🐱 Stella on jo saanut päivän bonuksen!',
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
          '🐱 Päivän Stella-bonus on jo haettu!',
        );
      } else {
        _message(
          '🐱⚡ Stella sai '
          '+${bonus.toStringAsFixed(0)} Hash Rate!',
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
  // 📺 LOAD TEST REWARDED AD
  // ==========================================================

  void _loadRewardedAd() {
    if (
        rewardedAdLoading ||
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
            const Duration(
              seconds: 15,
            ),
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
    if (!canWatchAd) {
      if (
          cooldownRemaining >
              Duration.zero) {
        _message(
          '🐱 Stella Power Boost seuraavan kerran: '
          '${_remainingAdText()}',
        );
      } else {
        _message(
          '🐱 Päivän Stella-mainosraja on saavutettu.',
        );
      }

      return;
    }

    if (rewardedAd == null) {
      _message(
        '📺 Stella etsii mainosta...',
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
        FullScreenContentCallback<
            RewardedAd>(
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
        '🐱⚡ Stella Power Boost! '
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
  // ⏱️ MINING REMAINING TEXT
  // ==========================================================

  String _miningRemainingText() {
    if (
        miningRemaining <=
            Duration.zero) {
      return 'Valmis!';
    }

    final hours =
        miningRemaining.inHours;

    final minutes =
        miningRemaining.inMinutes
            .remainder(60);

    final seconds =
        miningRemaining.inSeconds
            .remainder(60);

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // ==========================================================
  // 📺 AD REMAINING TEXT
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
  // 🎁 DAILY REWARD TEXT
  // ==========================================================

  String _dailyRewardText() {
    if (dailyClaimed) {
      return '🐱 Päivän Stella-bonus haettu';
    }

    return '🐱⚡ +1 Hash Rate';
  }

  // ==========================================================
  // 🔥 DAILY STREAK
  // ==========================================================

  String _dailyStreakText() {
    return '🔥 Stella Streak: päivä $streak';
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
          content: Text(message),
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
            ? '🐱 ${t.get('nextAd')}: '
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
            tooltip: 'Kirjaudu ulos',
            icon: const Icon(
              Icons.logout,
            ),
            onPressed: _logout,
          ),
        ],
      ),

      // ======================================================
      // 🐱 BODY
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

              const SizedBox(
                height: 14,
              ),

              // ==============================================
              // ⛏️ STELLA MINING DASHBOARD
              // ==============================================

              BalanceCard(
                title:
                    miningActive
                        ? '🐱 STELLA LOUHII'
                        : '🐱 STELLA MINING',

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
              // ⏱️ 24H MINING STATUS
              // ==============================================

              Container(
                width: double.infinity,

                padding:
                    const EdgeInsets.all(
                  18,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      stellaCardColor,

                  borderRadius:
                      BorderRadius.circular(
                    22,
                  ),

                  border:
                      Border.all(
                    color:
                        stellaGreen
                            .withValues(
                      alpha:
                          miningActive
                              ? 0.55
                              : 0.20,
                    ),
                  ),
                ),

                child: Column(
                  children: [
                    Text(
                      miningActive
                          ? '🐱⛏️ STELLA MINING ACTIVE'
                          : '🐱💤 STELLA RESTING',
                      style:
                          TextStyle(
                        color:
                            miningActive
                                ? stellaGreen
                                : Colors.white
                                    .withValues(
                            alpha: 0.65,
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
                      miningActive
                          ? _miningRemainingText()
                          : '24:00:00',
                      style:
                          TextStyle(
                        fontSize: 34,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            miningActive
                                ? stellaGreen
                                : Colors.white
                                    .withValues(
                            alpha: 0.70,
                          ),
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      miningActive
                          ? '✨ STL kasvaa reaaliajassa'
                          : '⛏️ Aloita uusi 24h Stella Mining Session',
                      textAlign:
                          TextAlign.center,
                      style:
                          TextStyle(
                        color:
                            Colors.white
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
              // ⛏️ START MINING BUTTON
              // ==============================================

              SizedBox(
                width: double.infinity,

                child:
                    ElevatedButton.icon(
                  onPressed:
                      miningLoading
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
                                  .precision_manufacturing
                              : Icons
                                  .play_arrow_rounded,
                        ),

                  label: Text(
                    miningLoading
                        ? '🐱 STELLA VALMISTELEE...'
                        : miningActive
                            ? '🐱⛏️ STELLA LOUHII'
                            : '🐱⛏️ ALOITA 24H LOUHINTA',
                  ),

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        miningActive
                            ? stellaGreen
                                .withValues(
                                alpha: 0.65,
                              )
                            : stellaGreen,

                    foregroundColor:
                        Colors.black,

                    padding:
                        const EdgeInsets
                            .symmetric(
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

              const SizedBox(
                height: 14,
              ),

              // ==============================================
              // 🐱 DAILY STELLA BONUS
              // ==============================================

              DailyRewardCard(
                title: t.get(
                  'dailyClaim',
                ),

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
              // 📺 STELLA POWER BOOST
              // ==============================================

              WatchAdCard(
                title:
                    '🐱⚡ STELLA POWER BOOST',

                dailyLimitText:
                    t.get(
                  'dailyLimit',
                ),

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
                    '🐱 Stella etsii mainosta...',

                limitReachedText:
                    t.get(
                  'dailyLimitReached',
                ),

                unavailableText:
                    t.get(
                  'adUnavailable',
                ),

                watchButtonText:
                    '📺⚡ POWER BOOST',
                    
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
                    t.get(
                  'stellaFacts',
                ),

                fact: fact,
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