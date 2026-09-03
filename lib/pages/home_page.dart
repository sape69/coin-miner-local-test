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
const Color stellaCardColor = Color(0xFF151B1C);

// ============================================================
// 📺 ADMOB TEST REWARDED AD
// ============================================================

/// Google test Rewarded Ad ID.
///
/// PIDETÄÄN TESTIMAINOKSENA KEHITYKSEN AIKANA.
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
  // 🔒 LOAD DATA PROTECTION
  // ==========================================================

  bool _loadDataInProgress = false;

  // ==========================================================
  // ⛏️ MINING DATA
  // ==========================================================

  double miningBalance = 0;

  /// Palvelimelta saatu louhimaton STL.
  double unclaimedMining = 0;

  /// Näytöllä reaaliaikaisesti kasvava kokonaismäärä.
  double estimatedTotal = 0;

  double hashRate = 1;

  double miningPerHour = 0;

  int streak = 0;

  bool dailyClaimed = false;

  // ==========================================================
  // ⏳ 24H MINING
  // ==========================================================

  bool miningActive = false;

  Duration miningRemaining = Duration.zero;

  DateTime? miningStartedAt;

  DateTime? miningEndsAt;

  /// Palvelimelta saadun STL-laskurin lähtöarvo.
  double _liveMiningStartValue = 0;

  /// Milloin paikallinen live-laskuri aloitettiin.
  DateTime? _liveMiningLocalStart;

  // ==========================================================
  // 📺 AD DATA
  // ==========================================================

  int adsToday = 0;

  int maxAdsPerDay = 5;

  bool canWatchAd = false;

  Duration cooldownRemaining = Duration.zero;

  // ==========================================================
  // 🎁 DAILY
  // ==========================================================

  bool dailyLoading = false;

  // ==========================================================
  // ⛏️ UI STATES
  // ==========================================================

  bool loading = true;

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

  Timer? cooldownTimer;

  Timer? liveMiningTimer;

  // ==========================================================
  // 🌍 LOCALIZATION
  // ==========================================================

  AppLocalizations get t =>
      AppLocalizations(widget.languageCode);

  // ==========================================================
  // ☁️ FIREBASE
  // ==========================================================

  FirebaseFunctions get functions =>
      FirebaseFunctions.instance;

  String? get uid =>
      FirebaseAuth.instance.currentUser?.uid;

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

    _startLiveMiningTimer();
  }

  // ==========================================================
  // 🗑️ DISPOSE
  // ==========================================================

  @override
  void dispose() {
    refreshTimer?.cancel();

    cooldownTimer?.cancel();

    liveMiningTimer?.cancel();

    rewardedAd?.dispose();

    super.dispose();
  }

  // ==========================================================
  // 🔄 LOAD DATA
  // ==========================================================

  Future<void> _loadData() async {
    // ========================================================
    // 🔒 PREVENT OVERLAPPING FIREBASE CALLS
    // ========================================================

    if (_loadDataInProgress) {
      return;
    }

    if (uid == null) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      return;
    }

    _loadDataInProgress = true;

    try {
      final result =
          await functions
              .httpsCallable('getMiningStatus')
              .call();

      final rawData = result.data;

      final data = Map<String, dynamic>.from(
        rawData as Map,
      );

      if (!mounted) return;

      final cooldownMs =
          (data['cooldownRemainingMs'] as num?)
                  ?.toInt() ??
              0;

      // ======================================================
      // ⏳ 24H MINING DATA
      // ======================================================

      final active =
          data['miningActive'] == true;

      final remainingMs =
          (data['miningRemainingMs'] as num?)
                  ?.toInt() ??
              0;

      DateTime? endsAt;

      final miningEndsAtValue =
          data['miningEndsAt'];

      if (miningEndsAtValue != null) {
        try {
          endsAt = DateTime.parse(
            miningEndsAtValue.toString(),
          ).toLocal();
        } catch (_) {
          endsAt = null;
        }
      }

      // ======================================================
      // 💰 MINING VALUES
      // ======================================================

      final serverMiningBalance =
          (data['miningBalance'] as num?)
                  ?.toDouble() ??
              0;

      final serverUnclaimedMining =
          (data['unclaimedMining'] as num?)
                  ?.toDouble() ??
              0;

      final serverEstimatedTotal =
          (data['estimatedTotal'] as num?)
                  ?.toDouble() ??
              serverMiningBalance +
                  serverUnclaimedMining;

      setState(() {
        // ====================================================
        // ⛏️ MINING
        // ====================================================

        hashRate =
            (data['hashRate'] as num?)
                    ?.toDouble() ??
                1;

        miningBalance = serverMiningBalance;

        unclaimedMining =
            serverUnclaimedMining;

        estimatedTotal =
            serverEstimatedTotal;

        miningPerHour =
            (data['miningPerHour'] as num?)
                    ?.toDouble() ??
                0;

        // ====================================================
        // ⏳ 24H STATUS
        // ====================================================

        miningActive = active;

        miningRemaining = Duration(
          milliseconds: remainingMs,
        );

        miningEndsAt = endsAt;

        if (active) {
          _liveMiningStartValue =
              serverUnclaimedMining;

          _liveMiningLocalStart =
              DateTime.now();
        } else {
          _liveMiningStartValue = 0;

          _liveMiningLocalStart = null;
        }

        // ====================================================
        // 🔥 DAILY
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
      _loadDataInProgress = false;
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
        if (
            mounted &&
            !_loadDataInProgress &&
            !loading) {
          _loadData();
        }
      },
    );
  }

  // ==========================================================
  // 💰 LIVE MINING TIMER
  // ==========================================================

  void _startLiveMiningTimer() {
    liveMiningTimer?.cancel();

    liveMiningTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        if (!miningActive) return;

        if (_liveMiningLocalStart == null) {
          return;
        }

        // ====================================================
        // ⏳ UPDATE REMAINING TIME
        // ====================================================

        if (miningRemaining > Duration.zero) {
          setState(() {
            miningRemaining -=
                const Duration(seconds: 1);

            if (miningRemaining <= Duration.zero) {
              miningRemaining = Duration.zero;

              miningActive = false;
            }
          });
        }

        if (!miningActive) {
          _loadData();
          return;
        }

        // ====================================================
        // 💰 REAL-TIME STL CALCULATION
        // ====================================================

        final elapsed =
            DateTime.now()
                .difference(
                  _liveMiningLocalStart!,
                );

        final seconds =
            elapsed.inMilliseconds /
                1000.0;

        final perSecond =
            miningPerHour / 3600.0;

        final liveAmount =
            _liveMiningStartValue +
                (perSecond * seconds);

        setState(() {
          unclaimedMining =
              liveAmount;

          estimatedTotal =
              miningBalance +
                  liveAmount;
        });
      },
    );
  }

  // ==========================================================
  // ⏱️ COOLDOWN TIMER
  // ==========================================================

  void _startCooldownTimer() {
    cooldownTimer?.cancel();

    cooldownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        if (cooldownRemaining <= Duration.zero) {
          return;
        }

        setState(() {
          cooldownRemaining -=
              const Duration(seconds: 1);

          if (cooldownRemaining <= Duration.zero) {
            cooldownRemaining =
                Duration.zero;

            if (
                adsToday <
                    maxAdsPerDay) {
              canWatchAd = true;
            }
          }
        });
      },
    );
  }

  // ==========================================================
  // ⛏️ START MINING
  // ==========================================================

  Future<void> _startMining() async {
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

      if (!mounted) return;

      final message =
          data['message']?.toString();

      _message(
        message ??
            '🐱⛏️ Stella Mining käynnistyi!',
      );

      await _loadData();
    } on FirebaseFunctionsException catch (error) {
      _message(
        error.message ??
            '🐱 Louhinnan käynnistys epäonnistui.',
      );
    } catch (_) {
      _message(
        '🐱 Louhinnan käynnistys epäonnistui.',
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
    if (dailyLoading) return;

    if (dailyClaimed) {
      _message(
        '🐱 Päivän Stella-bonus on jo haettu!',
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
          '🎁 Päivän Stella-bonus on jo haettu!',
        );
      } else {
        _message(
          '🐱⚡ +${bonus.toStringAsFixed(0)} Hash Rate!',
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

        onAdFailedToLoad: (_) {
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
  // 📺 WATCH AD
  // ==========================================================

  Future<void> _watchAd() async {
    if (adClaimLoading) return;

    if (!canWatchAd) {
      if (cooldownRemaining > Duration.zero) {
        _message(
          '🐱 Stella lepää vielä '
          '${_remainingAdText()}',
        );
      } else {
        _message(
          '📺 Päivän Stella-mainosraja saavutettu.',
        );
      }

      return;
    }

    if (rewardedAd == null) {
      _message(
        '🐱📺 Stella-mainosta valmistellaan...',
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
          (_, __) {
        earnedReward = true;
      },
    );
  }

  // ==========================================================
  // 📺 CLAIM TEST AD REWARD
  // ==========================================================

  Future<void> _claimTestAdReward() async {
    if (adClaimLoading) return;

    setState(() {
      adClaimLoading = true;
    });

    try {
      // ======================================================
      // DEVELOPMENT MODE
      //
      // Käytetään testAdReward Cloud Functionia.
      // Kun oikeat AdMob-mainokset + SSV otetaan käyttöön,
      // tämä voidaan poistaa.
      // ======================================================

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
        '📺🐱⚡ Stella Power Boost! '
        '+${bonus.toStringAsFixed(0)} Hash Rate',
      );

      await _loadData();
    } on FirebaseFunctionsException catch (error) {
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
  // ⏱️ REMAINING AD TIME
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
  // ⏳ MINING TIME TEXT
  // ==========================================================

  String _miningRemainingText() {
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
  // 🎁 DAILY REWARD TEXT
  // ==========================================================

  String _dailyRewardText() {
    if (dailyClaimed) {
      return '🐱 🎁 BONUS HAETTU';
    }

    return '🐱⚡ +1 HASH RATE';
  }

  // ==========================================================
  // 🔥 DAILY STREAK TEXT
  // ==========================================================

  String _dailyStreakText() {
    return '🔥 Stella Streak: Päivä $streak';
  }

  // ==========================================================
  // 💬 MESSAGE
  // ==========================================================

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: stellaCardColor,
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
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
  // 🧭 NAVIGATION
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
            ? '🐱 Seuraava Stella-mainos: '
                '${_remainingAdText()}'
            : '';

    return Scaffold(
      backgroundColor: backgroundColor,

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
              // 🐱 PROFILE
              // ==============================================

              ProfileCard(
                title: t.get('stella'),
              ),

              const SizedBox(height: 14),

              // ==============================================
              // ⛏️ BALANCE
              // ==============================================

              BalanceCard(
                title: miningActive
                    ? '🐱 STELLA MINING ACTIVE'
                    : t.get('yourBalance'),

                estimatedTotal: estimatedTotal,

                miningBalance: miningBalance,

                unclaimedMining:
                    unclaimedMining,

                hashRate: hashRate,

                miningPerHour:
                    miningPerHour,
              ),

              const SizedBox(height: 14),

              // ==============================================
              // ⏳ MINING STATUS CARD
              // ==============================================

              if (miningActive)
                Container(
                  padding:
                      const EdgeInsets.all(18),

                  decoration:
                      BoxDecoration(
                    color: stellaCardColor,

                    borderRadius:
                        BorderRadius.circular(20),

                    border: Border.all(
                      color:
                          accentColor.withValues(
                        alpha: 0.35,
                      ),
                    ),
                  ),

                  child: Column(
                    children: [
                      const Text(
                        '🐱⛏️ STELLA LOUHII',
                        style: TextStyle(
                          color: accentColor,
                          fontWeight:
                              FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        _miningRemainingText(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight:
                              FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        '💚 STL kasvaa reaaliajassa!',
                        style: TextStyle(
                          color:
                              Colors.white.withValues(
                            alpha: 0.65,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (miningActive)
                const SizedBox(height: 14),

              // ==============================================
              // ⛏️ START MINING
              // ==============================================

              SizedBox(
                width: double.infinity,

                child: ElevatedButton.icon(
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
                            color: Colors.black,
                          ),
                        )
                      : const Icon(
                          Icons.precision_manufacturing,
                        ),

                  label: Text(
                    miningLoading
                        ? '🐱 STELLA VALMISTELEE...'
                        : miningActive
                            ? '🐱⛏️ STELLA LOUHII...'
                            : '🐱⛏️ ALOITA 24H LOUHINTA',
                  ),

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        accentColor,

                    foregroundColor:
                        Colors.black,

                    disabledBackgroundColor:
                        stellaCardColor,

                    disabledForegroundColor:
                        Colors.white54,

                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 18,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(18),
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

              const SizedBox(height: 14),

              // ==============================================
              // 🎁 DAILY BONUS
              // ==============================================

              DailyRewardCard(
                title: t.get('dailyClaim'),

                rewardText:
                    _dailyRewardText(),

                streakText:
                    _dailyStreakText(),

                dailyLoading:
                    dailyLoading,

                dailyAdLoading: false,

                dailyClaimed:
                    dailyClaimed,

                adReady: true,

                onPressed:
                    dailyButtonEnabled
                        ? _dailyClaim
                        : null,
              ),

              const SizedBox(height: 14),

              // ==============================================
              // 📺 TEST AD
              // ==============================================

              WatchAdCard(
                title:
                    '📺🐱 STELLA POWER BOOST',

                dailyLimitText:
                    t.get('dailyLimit'),

                adsToday: adsToday,

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
                    '🐱📺 Stella-mainosta ladataan...',

                limitReachedText:
                    t.get(
                      'dailyLimitReached',
                    ),

                unavailableText:
                    t.get('adUnavailable'),

                watchButtonText:
                    '📺 KATSO & AUTA STELLAA ⚡',

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
                    '🐱 STELLA FACTS',

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