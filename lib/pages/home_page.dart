import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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

// Googlen virallinen Rewarded Ad TEST-ID.
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

  String today = '';
  String adStatus = '';

  DateTime? lastAdTime;

  RewardedAd? rewardedAd;

  Timer? cooldownTimer;
  Timer? adRetryTimer;

  AppLocalizations get t =>
      AppLocalizations(widget.languageCode);

  CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection('users');

  User? get _user =>
      FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _users.doc(_user!.uid);

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
    adRetryTimer?.cancel();

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
    final currentToday = _dateKey();

    // Jos käyttäjää ei ole, käytetään paikallista dataa.
    if (_user == null) {
      await _loadLocalCache();
      return;
    }

    try {
      final snapshot = await _userDoc.get();

      Map<String, dynamic> data;

      if (!snapshot.exists) {
        data = {
          'stlBalance': 0,
          'streak': 0,
          'lastDaily': '',
          'adsToday': 0,
          'adDate': currentToday,
          'lastAdTime': '',
        };

        await _userDoc.set(data);
      } else {
        data = snapshot.data() ?? {};
      }

      int loadedStl =
          (data['stlBalance'] as num?)?.toInt() ?? 0;

      int loadedStreak =
          (data['streak'] as num?)?.toInt() ?? 0;

      int loadedAds =
          (data['adsToday'] as num?)?.toInt() ?? 0;

      final lastDaily =
          data['lastDaily'] as String? ?? '';

      var adDate =
          data['adDate'] as String? ?? '';

      final lastAdString =
          data['lastAdTime'] as String? ?? '';

      DateTime? loadedLastAdTime;

      if (lastAdString.isNotEmpty) {
        loadedLastAdTime =
            DateTime.tryParse(lastAdString);
      }

      // Uusi päivä -> mainoslaskuri nollataan.
      if (adDate != currentToday) {
        loadedAds = 0;
        adDate = currentToday;

        await _userDoc.set(
          {
            'adsToday': 0,
            'adDate': currentToday,
          },
          SetOptions(merge: true),
        );
      }

      await _saveLocalCache(
        stlValue: loadedStl,
        streakValue: loadedStreak,
        adsValue: loadedAds,
        lastDailyValue: lastDaily,
        adDateValue: adDate,
        lastAdTimeValue: lastAdString,
      );

      if (!mounted) return;

      setState(() {
        today = currentToday;
        stl = loadedStl;
        streak = loadedStreak;
        adsToday = loadedAds;
        dailyClaimed = lastDaily == currentToday;
        lastAdTime = loadedLastAdTime;
        loading = false;
      });
    } catch (_) {
      await _loadLocalCache();
    }
  }

  // ==========================================================
  // LOCAL CACHE SAVE
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
  // LOCAL CACHE LOAD
  // ==========================================================

  Future<void> _loadLocalCache() async {
    final prefs =
        await SharedPreferences.getInstance();

    final currentToday = _dateKey();

    int loadedAds =
        prefs.getInt('ads_today') ?? 0;

    final savedAdDate =
        prefs.getString('ad_date') ?? '';

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
        prefs.getString('last_ad_time') ?? '';

    DateTime? loadedLastAdTime;

    if (lastAdString.isNotEmpty) {
      loadedLastAdTime =
          DateTime.tryParse(lastAdString);
    }

    if (!mounted) return;

    setState(() {
      today = currentToday;

      stl =
          prefs.getInt('stl_balance') ?? 0;

      streak =
          prefs.getInt('streak') ?? 0;

      adsToday = loadedAds;

      dailyClaimed =
          prefs.getString('last_daily') ==
              currentToday;

      lastAdTime = loadedLastAdTime;

      loading = false;
    });
  }

  // ==========================================================
  // DAILY REWARD
  // ==========================================================

  Future<void> _dailyClaim() async {
    if (dailyClaimed) {
      _message(t.get('claimed'));
      return;
    }

    final currentToday = _dateKey();

    final yesterday =
        DateTime.now().subtract(
      const Duration(days: 1),
    );

    final yesterdayKey =
        '${yesterday.year}-'
        '${yesterday.month.toString().padLeft(2, '0')}-'
        '${yesterday.day.toString().padLeft(2, '0')}';

    // Jos Firebase-käyttäjää ei ole,
    // käytetään paikallista tallennusta.
    if (_user == null) {
      await _dailyClaimLocal(
        currentToday,
        yesterdayKey,
      );
      return;
    }

    try {
      bool rewardClaimed = false;
      int rewardAmount = 0;

      await FirebaseFirestore.instance
          .runTransaction(
        (transaction) async {
          final snapshot =
              await transaction.get(_userDoc);

          final data =
              snapshot.data() ?? {};

          final oldBalance =
              (data['stlBalance'] as num?)
                      ?.toInt() ??
                  0;

          final oldStreak =
              (data['streak'] as num?)
                      ?.toInt() ??
                  0;

          final lastDaily =
              data['lastDaily'] as String? ?? '';

          // Palkinto on jo haettu tänään.
          if (lastDaily == currentToday) {
            return;
          }

          int newStreak;

          if (lastDaily == yesterdayKey) {
            newStreak = oldStreak + 1;
          } else {
            newStreak = 1;
          }

          if (newStreak > 7) {
            newStreak = 7;
          }

          rewardAmount =
              newStreak >= 7 ? 7 : 3;

          final newBalance =
              oldBalance + rewardAmount;

          transaction.set(
            _userDoc,
            {
              'stlBalance': newBalance,
              'streak': newStreak,
              'lastDaily': currentToday,
            },
            SetOptions(merge: true),
          );

          rewardClaimed = true;
        },
      );

      if (!rewardClaimed) {
        await _loadData();
        _message(t.get('claimed'));
        return;
      }

      final snapshot =
          await _userDoc.get();

      final data =
          snapshot.data() ?? {};

      final newBalance =
          (data['stlBalance'] as num?)
                  ?.toInt() ??
              stl;

      final newStreak =
          (data['streak'] as num?)
                  ?.toInt() ??
              streak;

      await _saveLocalCache(
        stlValue: newBalance,
        streakValue: newStreak,
        adsValue: adsToday,
        lastDailyValue: currentToday,
        adDateValue: _dateKey(),
        lastAdTimeValue:
            lastAdTime?.toIso8601String() ?? '',
      );

      if (!mounted) return;

      setState(() {
        stl = newBalance;
        streak = newStreak;
        dailyClaimed = true;
      });

      _message('+$rewardAmount STL! 🐱');
    } catch (_) {
      _message(
        'Päivittäisen palkinnon tallennus epäonnistui.',
      );
    }
  }

  Future<void> _dailyClaimLocal(
    String currentToday,
    String yesterdayKey,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final lastDaily =
        prefs.getString('last_daily') ?? '';

    if (lastDaily == currentToday) {
      _message(t.get('claimed'));
      return;
    }

    int newStreak;

    if (lastDaily == yesterdayKey) {
      newStreak = streak + 1;
    } else {
      newStreak = 1;
    }

    if (newStreak > 7) {
      newStreak = 7;
    }

    final reward =
        newStreak >= 7 ? 7 : 3;

    final newBalance =
        stl + reward;

    await prefs.setInt(
      'stl_balance',
      newBalance,
    );

    await prefs.setInt(
      'streak',
      newStreak,
    );

    await prefs.setString(
      'last_daily',
      currentToday,
    );

    if (!mounted) return;

    setState(() {
      stl = newBalance;
      streak = newStreak;
      dailyClaimed = true;
    });

    _message('+$reward STL! 🐱');
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

    return !DateTime.now()
        .isBefore(nextAdTime);
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
        remaining.inMinutes.remainder(60);

    final seconds =
        remaining.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours h $minutes min';
    }

    if (minutes > 0) {
      return '$minutes min';
    }

    return '$seconds s';
  }

  void _startCooldownTimer() {
    cooldownTimer = Timer.periodic(
      const Duration(seconds: 10),
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

    if (!mounted) return;

    setState(() {
      adLoading = true;
      adStatus = 'Mainosta ladataan...';
    });

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

          adRetryTimer?.cancel();

          setState(() {
            rewardedAd = ad;
            adLoading = false;
            adStatus = 'Mainos valmis!';
          });
        },

        onAdFailedToLoad:
            (LoadAdError error) {
          if (!mounted) return;

          setState(() {
            rewardedAd = null;
            adLoading = false;
            adStatus =
                'Mainosta ei saatu ladattua. '
                'Yritetään uudelleen...';
          });

          _scheduleAdRetry();
        },
      ),
    );
  }

  // ==========================================================
  // AUTOMATIC AD RETRY
  // ==========================================================

  void _scheduleAdRetry() {
    adRetryTimer?.cancel();

    adRetryTimer = Timer(
      const Duration(seconds: 15),
      () {
        if (!mounted) return;

        if (rewardedAd == null &&
            !adLoading) {
          _loadRewardedAd();
        }
      },
    );
  }

  // ==========================================================
  // WATCH AD
  // ==========================================================

  Future<void> _watchAd() async {
    if (adsToday >= 5) {
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

    // Mainosta ei ole vielä ladattu.
    if (rewardedAd == null) {
      _message(
        'Mainosta ladataan. Odota hetki.',
      );

      _loadRewardedAd();
      return;
    }

    final ad = rewardedAd!;

    setState(() {
      rewardedAd = null;
      adStatus = '';
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

        _message(
          'Mainosta ei voitu näyttää.',
        );

        _loadRewardedAd();
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
    final now = DateTime.now();
    final currentToday = _dateKey();

    if (_user == null) {
      await _addAdRewardLocal(
        now,
        currentToday,
      );
      return;
    }

    try {
      bool rewardAdded = false;

      await FirebaseFirestore.instance
          .runTransaction(
        (transaction) async {
          final snapshot =
              await transaction.get(_userDoc);

          final data =
              snapshot.data() ?? {};

          int currentAds =
              (data['adsToday'] as num?)
                      ?.toInt() ??
                  0;

          final adDate =
              data['adDate'] as String? ?? '';

          if (adDate != currentToday) {
            currentAds = 0;
          }

          if (currentAds >= 5) {
            return;
          }

          final balance =
              (data['stlBalance'] as num?)
                      ?.toInt() ??
                  0;

          final newBalance =
              balance + 3;

          final newAds =
              currentAds + 1;

          transaction.set(
            _userDoc,
            {
              'stlBalance': newBalance,
              'adsToday': newAds,
              'adDate': currentToday,
              'lastAdTime':
                  now.toIso8601String(),
            },
            SetOptions(merge: true),
          );

          rewardAdded = true;
        },
      );

      if (!rewardAdded) {
        await _loadData();
        _message(
          t.get('dailyLimitReached'),
        );
        return;
      }

      final snapshot =
          await _userDoc.get();

      final data =
          snapshot.data() ?? {};

      final newBalance =
          (data['stlBalance'] as num?)
                  ?.toInt() ??
              stl;

      final newAds =
          (data['adsToday'] as num?)
                  ?.toInt() ??
              adsToday;

      final newLastAdString =
          data['lastAdTime'] as String? ?? '';

      final newLastAdTime =
          DateTime.tryParse(
        newLastAdString,
      );

      await _saveLocalCache(
        stlValue: newBalance,
        streakValue: streak,
        adsValue: newAds,
        lastDailyValue:
            dailyClaimed ? today : '',
        adDateValue: currentToday,
        lastAdTimeValue:
            newLastAdString,
      );

      if (!mounted) return;

      setState(() {
        stl = newBalance;
        adsToday = newAds;
        lastAdTime =
            newLastAdTime ?? now;
        today = currentToday;
      });

      _message('+3 STL! 🐱');
    } catch (_) {
      _message(
        'Mainospalkinnon tallennus epäonnistui.',
      );
    }
  }

  Future<void> _addAdRewardLocal(
    DateTime now,
    String currentToday,
  ) async {
    if (adsToday >= 5) {
      return;
    }

    final prefs =
        await SharedPreferences.getInstance();

    final newBalance =
        stl + 3;

    final newAds =
        adsToday + 1;

    await prefs.setInt(
      'stl_balance',
      newBalance,
    );

    await prefs.setInt(
      'ads_today',
      newAds,
    );

    await prefs.setString(
      'ad_date',
      currentToday,
    );

    await prefs.setString(
      'last_ad_time',
      now.toIso8601String(),
    );

    if (!mounted) return;

    setState(() {
      stl = newBalance;
      adsToday = newAds;
      lastAdTime = now;
    });

    _message('+3 STL! 🐱');
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
          title: Text(
            t.get('selectLanguage'),
          ),
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
                    title: Text(
                      entry.value,
                    ),
                    trailing:
                        widget.languageCode ==
                                entry.key
                            ? const Icon(
                                Icons.check,
                                color: accentColor,
                              )
                            : null,
                    onTap: () async {
                      await widget.changeLanguage(
                        entry.key,
                      );

                      if (dialogContext.mounted) {
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

    final user = FirebaseAuth.instance.currentUser;

    final factIndex =
        DateTime.now().day %
            catFacts.length;

    final fact =
        catFacts[factIndex]
            .text(widget.languageCode);

    final canWatch = _canWatchAd();

    final remainingText =
        _remainingAdText();

    // Painiketta ei lukita silloin, kun mainos puuttuu.
    // Käyttäjä voi painaa sitä ja käynnistää latauksen uudelleen.
    final adButtonEnabled =
        adsToday < 5 &&
            canWatch &&
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

              // ============================================
              // USER
              // ============================================

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const CatAvatar(
                        size: 110,
                      ),

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

              // ============================================
              // BALANCE
              // ============================================

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

              // ============================================
              // DAILY REWARD
              // ============================================

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
                              dailyClaimed
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

              // ============================================
              // WATCH AD
              // ============================================

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
                            color:
                                Colors.orangeAccent,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                      if (adsToday < 5 &&
                          canWatch &&
                          adStatus.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.only(
                            top: 8,
                          ),
                          child: Text(
                            adStatus,
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              color: rewardedAd != null
                                  ? accentColor
                                  : Colors.orangeAccent,
                              fontWeight:
                                  FontWeight.bold,
                            ),
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
                                  ),
                                )
                              : Icon(
                                  rewardedAd != null
                                      ? Icons.play_arrow
                                      : Icons.refresh,
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
                                            ? 'LATAA MAINOS'
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

              // ============================================
              // CAT FACT
              // ============================================

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

              // ============================================
              // INFORMATION
              // ============================================

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