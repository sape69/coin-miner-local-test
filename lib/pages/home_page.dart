import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cat_facts.dart';
import '../localization.dart';
import '../widgets/cat_avatar.dart';

const Color backgroundColor = Color(0xFF0B1112);
const Color cardColor = Color(0xFF151B1C);
const Color accentColor = Color(0xFF35D0A0);

/// AdMob Rewarded Ad Unit ID.
///
/// TEST-ID:
/// ca-app-pub-3940256099942544/5224354917
///
/// Vaihda myöhemmin omaan oikeaan AdMob Rewarded Ad Unit ID:hen.
const String rewardedAdUnitId =
    'ca-app-pub-3940256099942544/5224354917';

/// Tavallisten mainosten päivittäinen maksimi.
const int maxAdsPerDay = 5;

/// Mainosten välinen odotusaika.
const Duration adCooldown =
    Duration(hours: 1);

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

  /// True, kun AdMob SSV -palkintoa odotetaan palvelimelta.
  bool waitingForServerReward = false;

  String today = '';

  DateTime? lastAdTime;

  // ==========================================================
  // ADMOB ADS
  // ==========================================================

  RewardedAd? rewardedAd;

  RewardedAd? dailyRewardedAd;

  // ==========================================================
  // TIMERS
  // ==========================================================

  Timer? cooldownTimer;
  Timer? rewardRefreshTimer;

  // ==========================================================
  // LOCALIZATION
  // ==========================================================

  AppLocalizations get t =>
      AppLocalizations(
        widget.languageCode,
      );

  // ==========================================================
  // FIRESTORE
  // ==========================================================

  CollectionReference<Map<String, dynamic>>
      get _users =>
          FirebaseFirestore.instance
              .collection('users');

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

    rewardRefreshTimer?.cancel();

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
  // LOAD DATA FROM FIRESTORE
  // ==========================================================

  Future<void> _loadData() async {
    final currentToday = _dateKey();

    try {
      final snapshot =
          await _userDoc.get();

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
          data['lastDaily'] as String? ??
              '';

      String adDate =
          data['adDate'] as String? ??
              '';

      DateTime? loadedLastAdTime;

      final timestamp =
          data['lastAdTimestamp'];

      if (timestamp is Timestamp) {
        loadedLastAdTime =
            timestamp.toDate();
      }

      // Yhteensopivuus vanhan String-muodon kanssa.
      final oldLastAdTime =
          data['lastAdTime'];

      if (loadedLastAdTime == null &&
          oldLastAdTime is String &&
          oldLastAdTime.isNotEmpty) {
        loadedLastAdTime =
            DateTime.tryParse(
          oldLastAdTime,
        );
      }

      // Uusi päivä -> mainoslaskuri nollaan.
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

    final currentToday =
        _dateKey();

    int loadedAds =
        prefs.getInt('ads_today') ??
            0;

    final savedAdDate =
        prefs.getString('ad_date') ??
            '';

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
        prefs.getString('last_ad_time') ??
            '';

    DateTime? loadedLastAdTime;

    if (lastAdString.isNotEmpty) {
      loadedLastAdTime =
          DateTime.tryParse(
        lastAdString,
      );
    }

    if (!mounted) return;

    setState(() {
      today = currentToday;

      stl =
          prefs.getInt('stl_balance') ??
              0;

      streak =
          prefs.getInt('streak') ??
              0;

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
  // DAILY CHECK-IN
  // ==========================================================

  Future<void> _dailyClaim() async {
    if (dailyLoading) return;

    if (dailyClaimed) {
      _message(
        t.get('claimed'),
      );

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

      final rawData =
          result.data;

      final data =
          Map<String, dynamic>.from(
        rawData as Map,
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
        adDateValue: currentToday,
        lastAdTimeValue:
            lastAdTime
                    ?.toIso8601String() ??
                '',
      );

      if (!mounted) return;

      setState(() {
        stl = newBalance;
        streak = newStreak;

        dailyClaimed =
            alreadyClaimed ||
                data['lastDaily'] ==
                    currentToday ||
                true;
      });

      if (alreadyClaimed) {
        _message(
          t.get('claimed'),
        );
      } else {
        _message(
          '+$reward STL! 🐱',
        );
      }
    } on FirebaseFunctionsException catch (error) {
      _message(
        error.message ??
            'Päivittäisen palkinnon '
                'hakeminen epäonnistui.',
      );
    } catch (_) {
      _message(
        'Päivittäisen palkinnon '
        'hakeminen epäonnistui.',
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
  // LOAD DAILY REWARD AD
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
        onAdLoaded: (
          RewardedAd ad,
        ) {
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
      _message(
        t.get('claimed'),
      );

      return;
    }

    if (dailyLoading ||
        dailyAdLoading) {
      return;
    }

    if (dailyRewardedAd == null) {
      _message(
        'Mainosta ladataan. '
        'Yritä hetken kuluttua.',
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
        FullScreenContentCallback<
            RewardedAd>(
      onAdDismissedFullScreenContent:
          (
        RewardedAd dismissedAd,
      ) async {
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
  // AD COOLDOWN
  // ==========================================================

  bool _canWatchAd() {
    if (lastAdTime == null) {
      return true;
    }

    final nextAdTime =
        lastAdTime!.add(
      adCooldown,
    );

    return !DateTime.now()
        .isBefore(nextAdTime);
  }

  Duration _remainingAdTime() {
    if (lastAdTime == null) {
      return Duration.zero;
    }

    final nextAdTime =
        lastAdTime!.add(
      adCooldown,
    );

    final remaining =
        nextAdTime.difference(
      DateTime.now(),
    );

    if (remaining.isNegative) {
      return Duration.zero;
    }

    return remaining;
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
        remaining.inMinutes
            .remainder(60);

    if (hours > 0) {
      return '$hours h $minutes min';
    }

    if (minutes > 0) {
      return '$minutes min';
    }

    return 'alle 1 min';
  }

  void _startCooldownTimer() {
    cooldownTimer =
        Timer.periodic(
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
  // ADMOB SERVER-SIDE VERIFICATION
  // ==========================================================

  void _configureServerSideVerification(
    RewardedAd ad,
  ) {
    final uid = _uid;

    if (uid == null) {
      return;
    }

    ad.setServerSideOptions(
      ServerSideVerificationOptions(
        userId: uid,
        customData: 'stelluriini',
      ),
    );
  }

  // ==========================================================
  // WATCH AD
  // ==========================================================

  Future<void> _watchAd() async {
    if (waitingForServerReward) {
      _message(
        'Edellisen mainoksen palkintoa '
        'vahvistetaan vielä.',
      );

      return;
    }

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

    // TÄRKEÄ:
    // Firebase saa käyttäjän UID:n AdMob SSV -callbackissa.
    _configureServerSideVerification(
      ad,
    );

    bool earnedReward = false;

    ad.fullScreenContentCallback =
        FullScreenContentCallback<
            RewardedAd>(
      onAdDismissedFullScreenContent:
          (
        RewardedAd dismissedAd,
      ) async {
        dismissedAd.dispose();

        if (earnedReward) {
          if (mounted) {
            setState(() {
              waitingForServerReward = true;
            });
          }

          _message(
            'Mainos katsottu! '
            'Palkinto vahvistetaan palvelimella...',
          );

          await _waitForServerReward();
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
        // Tämä EI lisää STL:ää.
        //
        // Se kertoo vain, että käyttäjä ansaitsi
        // palkinnon mainoksen näkökulmasta.
        //
        // Oikea STL lisätään Firebase Functionsissa
        // AdMob SSV -callbackin jälkeen.
        earnedReward = true;
      },
    );
  }

  // ==========================================================
  // WAIT FOR ADMOB SERVER REWARD
  // ==========================================================

  Future<void> _waitForServerReward() async {
    final oldBalance = stl;
    final oldAdsToday = adsToday;

    int attempts = 0;

    const maxAttempts = 12;

    rewardRefreshTimer?.cancel();

    final completer =
        Completer<void>();

    rewardRefreshTimer =
        Timer.periodic(
      const Duration(seconds: 5),
      (timer) async {
        attempts++;

        await _loadData();

        if (!mounted) {
          timer.cancel();

          if (!completer.isCompleted) {
            completer.complete();
          }

          return;
        }

        // ======================================================
        // SERVER REWARD FOUND
        // ======================================================

        if (stl > oldBalance ||
            adsToday > oldAdsToday) {
          timer.cancel();

          if (mounted) {
            setState(() {
              waitingForServerReward =
                  false;
            });
          }

          final earnedAmount =
              stl - oldBalance;

          if (earnedAmount > 0) {
            _message(
              '+$earnedAmount STL! 🐱',
            );
          } else {
            _message(
              'Palkinto vahvistettu! 🐱',
            );
          }

          if (!completer.isCompleted) {
            completer.complete();
          }

          return;
        }

        // ======================================================
        // TIMEOUT
        // ======================================================

        if (attempts >= maxAttempts) {
          timer.cancel();

          if (mounted) {
            setState(() {
              waitingForServerReward =
                  false;
            });
          }

          _message(
            'Palkinnon vahvistus voi kestää '
            'hetken. Päivitä sivu myöhemmin.',
          );

          if (!completer.isCompleted) {
            completer.complete();
          }
        }
      },
    );

    await completer.future;
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _message(
    String message,
  ) {
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
    await FirebaseAuth.instance
        .signOut();
  }

  // ==========================================================
  // LANGUAGE
  // ==========================================================

  void _openLanguageDialog() {
    showDialog(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          title: Text(
            t.get(
              'selectLanguage',
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children:
                  AppLocalizations
                      .supportedLanguages
                      .entries
                      .map(
                (entry) {
                  return ListTile(
                    title: Text(
                      entry.value,
                    ),
                    trailing:
                        widget.languageCode ==
                                entry.key
                            ? const Icon(
                                Icons.check,
                                color:
                                    accentColor,
                              )
                            : null,
                    onTap: () async {
                      await widget
                          .changeLanguage(
                        entry.key,
                      );

                      if (dialogContext
                          .mounted) {
                        Navigator.pop(
                          dialogContext,
                        );
                      }
                    },
                  );
                },
              ).toList(),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(
            color: accentColor,
          ),
        ),
      );
    }

    final user =
        FirebaseAuth.instance
            .currentUser;

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
            !adLoading &&
            !waitingForServerReward;

    final dailyButtonEnabled =
        !dailyClaimed &&
            !dailyLoading &&
            !dailyAdLoading &&
            dailyRewardedAd != null;

    return Scaffold(
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
            icon: const Icon(
              Icons.language,
            ),
            onPressed:
                _openLanguageDialog,
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding:
                const EdgeInsets.all(
              16,
            ),
            children: [
              // =================================================
              // PROFILE
              // =================================================

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),
                  child: Column(
                    children: [
                      const CatAvatar(
                        size: 110,
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Text(
                        t.get('stella'),
                        style:
                            const TextStyle(
                          fontSize: 24,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        user?.email ?? '',
                        style:
                            const TextStyle(
                          color:
                              Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              // =================================================
              // BALANCE
              // =================================================

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    28,
                  ),
                  child: Column(
                    children: [
                      Text(
                        t.get(
                          'yourBalance',
                        ),
                        style:
                            const TextStyle(
                          color:
                              Colors.white60,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        '$stl',
                        style:
                            const TextStyle(
                          fontSize: 56,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              accentColor,
                        ),
                      ),
                      const Text(
                        'STL',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        t.get(
                          'virtualPoints',
                        ),
                        style:
                            const TextStyle(
                          color:
                              Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              // =================================================
              // DAILY REWARD
              // =================================================

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.card_giftcard,
                        size: 42,
                        color: accentColor,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        t.get(
                          'dailyClaim',
                        ),
                        style:
                            const TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        '${t.get('streak')}: '
                        '🔥 $streak / 7',
                        style:
                            const TextStyle(
                          color:
                              Colors.white70,
                        ),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      SizedBox(
                        width:
                            double.infinity,
                        height: 52,
                        child:
                            ElevatedButton.icon(
                          onPressed:
                              dailyButtonEnabled
                                  ? _showDailyRewardAd
                                  : null,
                          icon:
                              dailyLoading ||
                                      dailyAdLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2,
                                        color:
                                            Colors.black,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.play_arrow,
                                    ),
                          label: Text(
                            dailyLoading
                                ? 'PALKKIOTA HAETAAN...'
                                : dailyAdLoading
                                    ? 'MAINOSTA LADATAAN...'
                                    : dailyClaimed
                                        ? t.get(
                                            'claimed',
                                          )
                                        : dailyRewardedAd ==
                                                null
                                            ? 'MAINOSTA LADATAAN...'
                                            : 'KATSO MAINOS JA LUNASTA',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              // =================================================
              // WATCH AD
              // =================================================

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.play_circle_outline,
                        size: 42,
                        color: accentColor,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        t.get(
                          'watchEarn',
                        ),
                        style:
                            const TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        '${t.get('dailyLimit')}: '
                        '$adsToday / $maxAdsPerDay',
                        style:
                            const TextStyle(
                          color:
                              Colors.white70,
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),

                      if (waitingForServerReward)
                        const Text(
                          'Palkintoa vahvistetaan '
                          'palvelimella...',
                          style: TextStyle(
                            color:
                                Colors.orangeAccent,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                      if (!waitingForServerReward &&
                          adsToday <
                              maxAdsPerDay &&
                          !canWatch)
                        Text(
                          '${t.get('nextAd')}: '
                          '$remainingText',
                          style:
                              const TextStyle(
                            color:
                                Colors.orangeAccent,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                      const SizedBox(
                        height: 15,
                      ),

                      SizedBox(
                        width:
                            double.infinity,
                        height: 52,
                        child:
                            ElevatedButton.icon(
                          onPressed:
                              adButtonEnabled
                                  ? _watchAd
                                  : null,
                          icon:
                              adLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2,
                                        color:
                                            Colors.black,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.play_arrow,
                                    ),
                          label: Text(
                            waitingForServerReward
                                ? 'VAHVISTETAAN...'
                                : adLoading
                                    ? t.get(
                                        'adLoading',
                                      )
                                    : adsToday >=
                                            maxAdsPerDay
                                        ? t.get(
                                            'dailyLimitReached',
                                          )
                                        : !canWatch
                                            ? '${t.get('nextAd')}: '
                                                '$remainingText'
                                            : rewardedAd ==
                                                    null
                                                ? t.get(
                                                    'adUnavailable',
                                                  )
                                                : t.get(
                                                    'watchAd',
                                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              // =================================================
              // CAT FACT
              // =================================================

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    22,
                  ),
                  child: Column(
                    children: [
                      Text(
                        t.get(
                          'stellaFacts',
                        ),
                        style:
                            const TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 14,
                      ),
                      const Icon(
                        Icons.pets,
                        size: 45,
                        color: accentColor,
                      ),
                      const SizedBox(
                        height: 14,
                      ),
                      Text(
                        fact,
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          fontSize: 16,
                          color:
                              Colors.white70,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              // =================================================
              // INFORMATION
              // =================================================

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 38,
                        color: accentColor,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        t.get('info'),
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 19,
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Text(
                        t.get(
                          'solanaToken',
                        ),
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          color:
                              Colors.white70,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        t.get(
                          'stellaCompany',
                        ),
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          color:
                              Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
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