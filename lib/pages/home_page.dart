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

// ============================================================
// 📺 ADMOB TEST ID
// ============================================================
//
// Stella käyttää vielä testimainoksia kehityksen aikana.
// ÄLÄ vaihda tätä oikeaan AdMob ID:hen vielä.
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

  bool miningActive = false;

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
  // 🖥️ UI STATES
  // ==========================================================

  bool loading = true;

  bool dailyLoading = false;

  bool miningLoading = false;

  bool adClaimLoading = false;

  // ==========================================================
  // 🔒 FIREBASE REQUEST PROTECTION
  // ==========================================================
  //
  // Estää _loadData()-funktion käynnistymisen uudelleen,
  // jos edellinen Firebase-kutsu on vielä käynnissä.
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

  Timer? cooldownTimer;

  Timer? miningTimer;

  // ==========================================================
  // ⏱️ REALTIME MINING
  // ==========================================================

  DateTime? lastMiningUpdate;

  // ==========================================================
  // 🌍 LOCALIZATION
  // ==========================================================

  AppLocalizations get t =>
      AppLocalizations(widget.languageCode);

  // ==========================================================
  // 🔥 FIREBASE
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

    _startMiningTimer();
  }

  // ==========================================================
  // 🗑️ DISPOSE
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
      // USER CHECK
      // ======================================================

      if (uid == null) {
        if (!mounted) {
          return;
        }

        setState(() {
          loading = false;
        });

        return;
      }

      // ======================================================
      // FIREBASE CALL
      // ======================================================

      final result = await functions
          .httpsCallable('getMiningStatus')
          .call();

      final data = Map<String, dynamic>.from(
        result.data as Map,
      );

      if (!mounted) {
        return;
      }

      // ======================================================
      // COOLDOWN
      // ======================================================

      final cooldownMs =
          (data['cooldownRemainingMs'] as num?)
                  ?.toInt() ??
              0;

      // ======================================================
      // MINING REMAINING
      // ======================================================

      final miningRemainingMs =
          (data['miningRemainingMs'] as num?)
                  ?.toInt() ??
              0;

      // ======================================================
      // UPDATE STATE
      // ======================================================

      setState(() {
        // ----------------------------------------------------
        // ⛏️ MINING
        // ----------------------------------------------------

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

        miningActive =
            data['miningActive'] == true;

        miningRemaining = Duration(
          milliseconds: miningRemainingMs,
        );

        lastMiningUpdate = DateTime.now();

        // ----------------------------------------------------
        // 🎁 DAILY
        // ----------------------------------------------------

        streak =
            (data['streak'] as num?)
                    ?.toInt() ??
                0;

        dailyClaimed =
            data['dailyClaimed'] == true;

        // ----------------------------------------------------
        // 📺 ADS
        // ----------------------------------------------------

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
      // 🔓 ALWAYS RELEASE LOCK
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
        if (!mounted) {
          return;
        }

        if (!loading && !_loadingData) {
          _loadData();
        }
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
        if (!mounted) {
          return;
        }

        if (cooldownRemaining <= Duration.zero) {
          return;
        }

        setState(() {
          cooldownRemaining -=
              const Duration(seconds: 1);

          if (cooldownRemaining <= Duration.zero) {
            cooldownRemaining =
                Duration.zero;

            if (adsToday < maxAdsPerDay) {
              canWatchAd = true;
            }
          }
        });
      },
    );
  }

  // ==========================================================
  // 🐱 REALTIME STELLA MINING TIMER
  // ==========================================================
  //
  // STL-määrä liikkuu näytöllä reaaliajassa.
  //
  // Firebase ei tarvitse kutsua joka sekunti.
  // Palvelin pysyy totuuden lähteenä.
  //

  void _startMiningTimer() {
    miningTimer?.cancel();

    miningTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) {
          return;
        }

        if (!miningActive) {
          return;
        }

        if (miningRemaining <= Duration.zero) {
          setState(() {
            miningRemaining = Duration.zero;
            miningActive = false;
          });

          _loadData();

          return;
        }

        final earnedPerSecond =
            miningPerHour / 3600;

        setState(() {
          // --------------------------------------------------
          // REALTIME STL
          // --------------------------------------------------

          unclaimedMining += earnedPerSecond;

          estimatedTotal =
              miningBalance +
                  unclaimedMining;

          // --------------------------------------------------
          // COUNTDOWN
          // --------------------------------------------------

          miningRemaining -=
              const Duration(seconds: 1);

          if (miningRemaining <= Duration.zero) {
            miningRemaining =
                Duration.zero;

            miningActive = false;
          }
        });
      },
    );
  }

  // ==========================================================
  // ⛏️ CLAIM / START MINING
  // ==========================================================

  Future<void> _claimMining() async {
    if (miningLoading) {
      return;
    }

    setState(() {
      miningLoading = true;
    });

    try {
      final result = await functions
          .httpsCallable('claimMining')
          .call();

      final data = Map<String, dynamic>.from(
        result.data as Map,
      );

      if (!mounted) {
        return;
      }

      final claimed =
          (data['claimed'] as num?)
                  ?.toDouble() ??
              0;

      final started =
          data['started'] == true;

      final message =
          data['message']?.toString();

      if (started) {
        _message(
          '🐱⛏️ Stella Mining käynnistyi! '
          'STL alkaa juosta seuraavat 24 tuntia ✨',
        );
      } else if (claimed > 0) {
        _message(
          '🐱✨ '
          '+${claimed.toStringAsFixed(4)} STL '
          'lisätty Stella Balanceen!',
        );
      } else {
        _message(
          message ??
              '🐱⛏️ Stella Mining käynnistyi!',
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
      final result = await functions
          .httpsCallable('dailyCheckIn')
          .call();

      final data = Map<String, dynamic>.from(
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
          '🐱 ${t.get('claimed')}',
        );
      } else {
        _message(
          '🐱⚡ +${bonus.toStringAsFixed(0)} '
          'Stella Hash Rate!',
        );
      }

      await _loadData();
    } on FirebaseFunctionsException catch (error) {
      _message(
        error.message ??
            '🐱 Päivittäinen Stella Bonus epäonnistui.',
      );
    } catch (_) {
      _message(
        '🐱 Päivittäinen Stella Bonus epäonnistui.',
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
    if (!canWatchAd) {
      if (cooldownRemaining > Duration.zero) {
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
  // 📺 TEST AD REWARD
  // ==========================================================
  //
  // Käytetään kehityksen aikana.
  //

  Future<void> _claimAdReward() async {
    if (adClaimLoading) {
      return;
    }

    setState(() {
      adClaimLoading = true;
    });

    try {
      final result = await functions
          .httpsCallable('testAdReward')
          .call();

      final data = Map<String, dynamic>.from(
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
        '🐱📺⚡ '
        '+${bonus.toStringAsFixed(0)} '
        'Stella Power Boost!',
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
  // ⛏️ MINING TIME TEXT
  // ==========================================================

  String _miningTimeText() {
    if (!miningActive) {
      return '🐱 Stella odottaa louhinnan käynnistystä';
    }

    final hours =
        miningRemaining.inHours;

    final minutes =
        miningRemaining.inMinutes
            .remainder(60);

    final seconds =
        miningRemaining.inSeconds
            .remainder(60);

    return '🐱⛏️ Stella louhii vielä '
        '$hours h '
        '$minutes min '
        '$seconds s';
  }

  // ==========================================================
  // 🎁 DAILY REWARD TEXT
  // ==========================================================

  String _dailyRewardText() {
    if (dailyClaimed) {
      return '🐱🎁 ${t.get('claimed')}';
    }

    return '🐱🎁 +1 Stella Hash Rate';
  }

  // ==========================================================
  // 🔥 STREAK TEXT
  // ==========================================================

  String _dailyStreakText() {
    return '${t.get('streak')}: '
        '🔥 Stella Day $streak';
  }

  // ==========================================================
  // 💬 MESSAGE
  // ==========================================================

  void _message(String message) {
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
              // ⛏️ STELLA MINING DASHBOARD
              // ==============================================

              BalanceCard(
                title: t.get('yourBalance'),

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

              const SizedBox(height: 10),

              // ==============================================
              // 🐱 REALTIME MINING STATUS
              // ==============================================

              Container(
                width: double.infinity,

                padding:
                    const EdgeInsets.all(14),

                decoration:
                    BoxDecoration(
                  color:
                      accentColor.withValues(
                    alpha: 0.08,
                  ),

                  borderRadius:
                      BorderRadius.circular(18),

                  border: Border.all(
                    color:
                        accentColor.withValues(
                      alpha: 0.35,
                    ),
                  ),
                ),

                child: Text(
                  _miningTimeText(),

                  textAlign:
                      TextAlign.center,

                  style: const TextStyle(
                    color: accentColor,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ==============================================
              // ⛏️ START / CLAIM MINING
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
                            color: Colors.black,
                          ),
                        )
                      : Icon(
                          miningActive
                              ? Icons
                                  .savings
                              : Icons
                                  .precision_manufacturing,
                        ),

                  label: Text(
                    miningLoading
                        ? '🐱 STELLA WORKING...'
                        : miningActive
                            ? '🐱⛏️ COLLECT STELLA MINING'
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
              // 🎁 DAILY STELLA BONUS
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
              // 📺 STELLA POWER BOOST
              // ==============================================

              WatchAdCard(
                title:
                    '🐱⚡ Stella Power Boost',

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
                    t.get('adLoading'),

                limitReachedText:
                    t.get(
                      'dailyLimitReached',
                    ),

                unavailableText:
                    t.get('adUnavailable'),

                watchButtonText:
                    '📺 WATCH & BOOST STELLA',

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