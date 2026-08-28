import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cat_facts.dart';
import '../localization.dart';
import '../services/user_service.dart';
import '../widgets/cat_avatar.dart';

const Color backgroundColor = Color(0xFF0B1112);
const Color cardColor = Color(0xFF151B1C);
const Color accentColor = Color(0xFF35D0A0);

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
  bool saving = false;

  String today = '';

  DateTime? lastAdTime;

  RewardedAd? rewardedAd;
  Timer? cooldownTimer;

  AppLocalizations get t =>
      AppLocalizations(widget.languageCode);

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadRewardedAd();
    _startCooldownTimer();
  }

  @override
  void dispose() {
    rewardedAd?.dispose();
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
    final prefs = await SharedPreferences.getInstance();
    final currentToday = _dateKey();

    try {
      // ------------------------------------------------------
      // FIRESTORE
      // ------------------------------------------------------

      final userData =
          await UserService.loadUserData();

      int currentAds = userData.adsToday;

      // Nollataan mainoslaskuri uuden päivän alkaessa.
      if (userData.adDate != currentToday) {
        currentAds = 0;

        await UserService.saveUserData(
          userData.copyWith(
            adsToday: 0,
            adDate: currentToday,
          ),
        );
      }

      // Tallennetaan myös paikalliseen välimuistiin.
      await prefs.setInt(
        'stl_balance',
        userData.stlBalance,
      );

      await prefs.setInt(
        'streak',
        userData.streak,
      );

      await prefs.setString(
        'last_daily',
        userData.lastDaily,
      );

      await prefs.setInt(
        'ads_today',
        currentAds,
      );

      await prefs.setString(
        'ad_date',
        currentToday,
      );

      if (userData.lastAdTime != null) {
        await prefs.setString(
          'last_ad_time',
          userData.lastAdTime!
              .toIso8601String(),
        );
      }

      if (!mounted) return;

      setState(() {
        today = currentToday;
        stl = userData.stlBalance;
        streak = userData.streak;
        adsToday = currentAds;

        dailyClaimed =
            userData.lastDaily == currentToday;

        lastAdTime = userData.lastAdTime;

        loading = false;
      });
    } catch (_) {
      // ------------------------------------------------------
      // FALLBACK: SHAREDPREFERENCES
      // ------------------------------------------------------

      final savedAdDate =
          prefs.getString('ad_date') ?? '';

      int currentAds =
          prefs.getInt('ads_today') ?? 0;

      if (savedAdDate != currentToday) {
        currentAds = 0;

        await prefs.setString(
          'ad_date',
          currentToday,
        );

        await prefs.setInt(
          'ads_today',
          0,
        );
      }

      final lastAdString =
          prefs.getString('last_ad_time');

      DateTime? savedLastAdTime;

      if (lastAdString != null) {
        savedLastAdTime =
            DateTime.tryParse(lastAdString);
      }

      if (!mounted) return;

      setState(() {
        today = currentToday;
        stl = prefs.getInt('stl_balance') ?? 0;
        streak = prefs.getInt('streak') ?? 0;
        adsToday = currentAds;

        dailyClaimed =
            (prefs.getString('last_daily') ?? '') ==
                currentToday;

        lastAdTime = savedLastAdTime;

        loading = false;
      });
    }
  }

  // ==========================================================
  // SAVE LOCAL CACHE
  // ==========================================================

  Future<void> _saveLocalData({
    required int balance,
    required int newStreak,
    required String lastDaily,
    required int newAdsToday,
    required String adDate,
    DateTime? newLastAdTime,
  }) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setInt(
      'stl_balance',
      balance,
    );

    await prefs.setInt(
      'streak',
      newStreak,
    );

    await prefs.setString(
      'last_daily',
      lastDaily,
    );

    await prefs.setInt(
      'ads_today',
      newAdsToday,
    );

    await prefs.setString(
      'ad_date',
      adDate,
    );

    if (newLastAdTime != null) {
      await prefs.setString(
        'last_ad_time',
        newLastAdTime.toIso8601String(),
      );
    }
  }

  // ==========================================================
  // DAILY REWARD
  // ==========================================================

  Future<void> _dailyClaim() async {
    if (dailyClaimed || saving) {
      _message(t.get('claimed'));
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      final currentToday = _dateKey();

      final userData =
          await UserService.loadUserData();

      // Tarkistetaan uudelleen Firestoresta,
      // ettei palkintoa voi saada kahdesti.
      if (userData.lastDaily == currentToday) {
        if (!mounted) return;

        setState(() {
          dailyClaimed = true;
          saving = false;
        });

        _message(t.get('claimed'));
        return;
      }

      int newStreak;

      if (userData.lastDaily.isEmpty) {
        newStreak = 1;
      } else {
        final yesterday =
            DateTime.now().subtract(
          const Duration(days: 1),
        );

        final yesterdayKey =
            '${yesterday.year}-'
            '${yesterday.month.toString().padLeft(2, '0')}-'
            '${yesterday.day.toString().padLeft(2, '0')}';

        if (userData.lastDaily == yesterdayKey) {
          newStreak = userData.streak + 1;
        } else {
          newStreak = 1;
        }
      }

      // Maksimi näytettävä streak on 7.
      final displayStreak =
          newStreak > 7 ? 7 : newStreak;

      final reward =
          displayStreak >= 7 ? 7 : 3;

      final newBalance =
          userData.stlBalance + reward;

      // Firestore.
      await UserService.saveDailyReward(
        stlBalance: newBalance,
        streak: displayStreak,
        lastDaily: currentToday,
      );

      // Paikallinen varmuuskopio.
      await _saveLocalData(
        balance: newBalance,
        newStreak: displayStreak,
        lastDaily: currentToday,
        newAdsToday: adsToday,
        adDate: _dateKey(),
        newLastAdTime: lastAdTime,
      );

      if (!mounted) return;

      setState(() {
        stl = newBalance;
        streak = displayStreak;
        dailyClaimed = true;
        today = currentToday;
        saving = false;
      });

      _message('+$reward STL! 🐱');
    } catch (_) {
      if (!mounted) return;

      setState(() {
        saving = false;
      });

      _message('Palkinnon tallennus epäonnistui.');
    }
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
      const Duration(hours: 1),
    );

    return !DateTime.now().isBefore(nextAdTime);
  }

  Duration _remainingAdTime() {
    if (lastAdTime == null) {
      return Duration.zero;
    }

    final nextAdTime =
        lastAdTime!.add(
      const Duration(hours: 1),
    );

    final remaining =
        nextAdTime.difference(DateTime.now());

    if (remaining.isNegative) {
      return Duration.zero;
    }

    return remaining;
  }

  String _remainingAdText() {
    final remaining = _remainingAdTime();

    if (remaining == Duration.zero) {
      return '';
    }

    final hours = remaining.inHours;
    final minutes =
        remaining.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours h $minutes min';
    }

    return '$minutes min';
  }

  void _startCooldownTimer() {
    cooldownTimer = Timer.periodic(
      const Duration(seconds: 30),
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
    if (adLoading || rewardedAd != null) {
      return;
    }

    if (mounted) {
      setState(() {
        adLoading = true;
      });
    }

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
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
        },
      ),
    );
  }

  // ==========================================================
  // WATCH AD
  // ==========================================================

  Future<void> _watchAd() async {
    if (adsToday >= 5) {
      _message(t.get('dailyLimitReached'));
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
      _message(t.get('adUnavailable'));
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
          (RewardedAd ad) async {
        ad.dispose();

        if (earnedReward) {
          await _addAdReward();
        }

        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent:
          (RewardedAd ad, AdError error) {
        ad.dispose();

        _loadRewardedAd();

        _message('Mainosta ei voitu näyttää.');
      },
    );

    ad.show(
      onUserEarnedReward:
          (AdWithoutView ad, RewardItem reward) {
        earnedReward = true;
      },
    );
  }

  // ==========================================================
  // ADD AD REWARD
  // ==========================================================

  Future<void> _addAdReward() async {
    if (saving) return;

    setState(() {
      saving = true;
    });

    try {
      final userData =
          await UserService.loadUserData();

      final currentToday = _dateKey();

      // Nollataan päivän laskuri tarvittaessa.
      int currentAds =
          userData.adDate == currentToday
              ? userData.adsToday
              : 0;

      if (currentAds >= 5) {
        if (!mounted) return;

        setState(() {
          saving = false;
        });

        _message(t.get('dailyLimitReached'));
        return;
      }

      // Tarkistetaan cooldown myös Firestoresta.
      if (userData.lastAdTime != null) {
        final nextAdTime =
            userData.lastAdTime!.add(
          const Duration(hours: 1),
        );

        if (DateTime.now().isBefore(nextAdTime)) {
          if (!mounted) return;

          setState(() {
            saving = false;
            lastAdTime =
                userData.lastAdTime;
          });

          _message(
            '${t.get('nextAd')}: '
            '${_remainingAdText()}',
          );

          return;
        }
      }

      final now = DateTime.now();

      final newBalance =
          userData.stlBalance + 3;

      final newAdsToday =
          currentAds + 1;

      // Firestore.
      await UserService.saveAdReward(
        stlBalance: newBalance,
        adsToday: newAdsToday,
        adDate: currentToday,
        lastAdTime: now,
      );

      // Paikallinen varmuuskopio.
      await _saveLocalData(
        balance: newBalance,
        newStreak: userData.streak,
        lastDaily: userData.lastDaily,
        newAdsToday: newAdsToday,
        adDate: currentToday,
        newLastAdTime: now,
      );

      if (!mounted) return;

      setState(() {
        stl = newBalance;
        streak = userData.streak;
        adsToday = newAdsToday;
        lastAdTime = now;
        today = currentToday;
        saving = false;
      });

      _message(t.get('pointsAdded'));
    } catch (_) {
      if (!mounted) return;

      setState(() {
        saving = false;
      });

      _message('Mainospalkinnon tallennus epäonnistui.');
    }
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
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(t.get('selectLanguage')),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: AppLocalizations
                  .supportedLanguages
                  .entries
                  .map(
                (entry) {
                  return ListTile(
                    title: Text(entry.value),
                    trailing:
                        widget.languageCode == entry.key
                            ? const Icon(
                                Icons.check,
                                color: accentColor,
                              )
                            : null,
                    onTap: () async {
                      await widget.changeLanguage(
                        entry.key,
                      );

                      if (!mounted) return;

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
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
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: accentColor,
          ),
        ),
      );
    }

    final user =
        FirebaseAuth.instance.currentUser;

    final factIndex =
        DateTime.now().day % catFacts.length;

    final fact =
        catFacts[factIndex]
            .text(widget.languageCode);

    final canWatch = _canWatchAd();
    final remainingText = _remainingAdText();

    final adButtonEnabled =
        !saving &&
        adsToday < 5 &&
        canWatch &&
        rewardedAd != null &&
        !adLoading;

    return Scaffold(
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
            tooltip: 'Vaihda kieli',
            icon: const Icon(Icons.language),
            onPressed: _openLanguageDialog,
          ),
          IconButton(
            tooltip: 'Kirjaudu ulos',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // USER

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const CatAvatar(size: 110),

                      const SizedBox(height: 12),

                      Text(
                        t.get('stella'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        user?.email ?? '',
                        style: const TextStyle(
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // BALANCE

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      Text(
                        t.get('yourBalance'),
                        style: const TextStyle(
                          color: Colors.white60,
                          letterSpacing: 2,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        '$stl',
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight:
                              FontWeight.bold,
                          color: accentColor,
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

                      const SizedBox(height: 10),

                      Text(
                        t.get('virtualPoints'),
                        style: const TextStyle(
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // DAILY REWARD

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.card_giftcard,
                        size: 42,
                        color: accentColor,
                      ),

                      const SizedBox(height: 10),

                      Text(
                        t.get('dailyClaim'),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        '${t.get('streak')}: '
                        '🔥 $streak / 7',
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed:
                              dailyClaimed || saving
                                  ? null
                                  : _dailyClaim,
                          icon: const Icon(
                            Icons.redeem,
                          ),
                          label: Text(
                            dailyClaimed
                                ? t.get('claimed')
                                : t.get('dailyReward'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // WATCH AD

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.play_circle_outline,
                        size: 42,
                        color: accentColor,
                      ),

                      const SizedBox(height: 10),

                      Text(
                        t.get('watchEarn'),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        '${t.get('dailyLimit')}: '
                        '$adsToday / 5',
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),

                      const SizedBox(height: 8),

                      if (adsToday < 5 &&
                          !canWatch)
                        Text(
                          '${t.get('nextAd')}: '
                          '$remainingText',
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                      const SizedBox(height: 15),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed:
                              adButtonEnabled
                                  ? _watchAd
                                  : null,
                          icon: adLoading
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
                              : const Icon(
                                  Icons.play_arrow,
                                ),
                          label: Text(
                            adLoading
                                ? t.get('adLoading')
                                : adsToday >= 5
                                    ? t.get(
                                        'dailyLimitReached',
                                      )
                                    : !canWatch
                                        ? '${t.get('nextAd')}: '
                                            '$remainingText'
                                        : rewardedAd == null
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

              const SizedBox(height: 14),

              // CAT FACT

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      Text(
                        t.get('stellaFacts'),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Icon(
                        Icons.pets,
                        size: 45,
                        color: accentColor,
                      ),

                      const SizedBox(height: 14),

                      Text(
                        fact,
                        textAlign:
                            TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // INFORMATION

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 38,
                        color: accentColor,
                      ),

                      const SizedBox(height: 10),

                      Text(
                        t.get('info'),
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 19,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        t.get('solanaToken'),
                        textAlign:
                            TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        t.get('stellaCompany'),
                        textAlign:
                            TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}