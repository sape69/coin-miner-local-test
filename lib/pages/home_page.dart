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

  DateTime? lastAdTime;

  RewardedAd? rewardedAd;
  Timer? cooldownTimer;

  AppLocalizations get t =>
      AppLocalizations(widget.languageCode);

  CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection('users');

  String get _uid =>
      FirebaseAuth.instance.currentUser?.uid ?? '';

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _users.doc(_uid);

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
    final currentToday = _dateKey();

    if (_uid.isEmpty) {
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

      String adDate =
          data['adDate'] as String? ?? '';

      final lastAdString =
          data['lastAdTime'] as String? ?? '';

      DateTime? loadedLastAdTime;

      if (lastAdString.isNotEmpty) {
        loadedLastAdTime =
            DateTime.tryParse(lastAdString);
      }

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
  // LOCAL CACHE
  // ==========================================================

  Future<void> _saveLocalCache({
    required int stlValue,
    required int streakValue,
    required int adsValue,
    required String lastDailyValue,
    required String adDateValue,
    required String lastAdTimeValue,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('stl_balance', stlValue);
    await prefs.setInt('streak', streakValue);
    await prefs.setInt('ads_today', adsValue);

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

  Future<void> _loadLocalCache() async {
    final prefs = await SharedPreferences.getInstance();

    final currentToday = _dateKey();

    int loadedAds =
        prefs.getInt('ads_today') ?? 0;

    final adDate =
        prefs.getString('ad_date') ?? '';

    if (adDate != currentToday) {
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
      stl = prefs.getInt('stl_balance') ?? 0;
      streak = prefs.getInt('streak') ?? 0;
      adsToday = loadedAds;

      dailyClaimed =
          prefs.getString('last_daily') == currentToday;

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

    if (_uid.isEmpty) {
      _message('Kirjaudu sisään ensin.');
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

    try {
      await FirebaseFirestore.instance
          .runTransaction((transaction) async {
        final snapshot =
            await transaction.get(_userDoc);

        final data =
            snapshot.data() ?? {};

        final oldBalance =
            (data['stlBalance'] as num?)?.toInt() ?? 0;

        final oldStreak =
            (data['streak'] as num?)?.toInt() ?? 0;

        final lastDaily =
            data['lastDaily'] as String? ?? '';

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

        final reward =
            newStreak >= 7 ? 7 : 3;

        final newBalance =
            oldBalance + reward;

        transaction.set(
          _userDoc,
          {
            'stlBalance': newBalance,
            'streak': newStreak,
            'lastDaily': currentToday,
          },
          SetOptions(merge: true),
        );
      });

      await _loadData();

      final reward =
          streak >= 7 ? 7 : 3;

      _message('+$reward STL! 🐱');
    } catch (_) {
      _message(
        'Päivittäisen palkinnon tallennus epäonnistui.',
      );
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

    setState(() {
      adLoading = true;
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
        '${t.get('nextAd')}: ${_remainingAdText()}',
      );
      return;
    }

    if (rewardedAd == null) {
      _message('Mainosta ladataan...');

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

        _message('Mainosta ei voitu näyttää.');

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
    if (_uid.isEmpty) return;

    final now = DateTime.now();
    final currentToday = _dateKey();

    try {
      await FirebaseFirestore.instance
          .runTransaction((transaction) async {
        final snapshot =
            await transaction.get(_userDoc);

        final data =
            snapshot.data() ?? {};

        int currentAds =
            (data['adsToday'] as num?)?.toInt() ?? 0;

        final adDate =
            data['adDate'] as String? ?? '';

        if (adDate != currentToday) {
          currentAds = 0;
        }

        if (currentAds >= 5) {
          return;
        }

        final balance =
            (data['stlBalance'] as num?)?.toInt() ?? 0;

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
            'lastAdTime': now.toIso8601String(),
          },
          SetOptions(merge: true),
        );
      });

      await _loadData();

      _message(t.get('pointsAdded'));
    } catch (_) {
      _message(
        'Mainospalkinnon tallennus epäonnistui.',
      );
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
          behavior: SnackBarBehavior.floating,
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
                    leading: const Icon(Icons.language),
                    title: Text(entry.value),
                    trailing:
                        widget.languageCode == entry.key
                            ? const Icon(
                                Icons.check_circle,
                                color: accentColor,
                              )
                            : null,
                    onTap: () async {
                      await widget.changeLanguage(entry.key);

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
  // STELLA HEADER
  // ==========================================================

  Widget _buildStellaHeader(User? user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF182524),
            Color(0xFF0E1516),
          ],
        ),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          const CatAvatar(size: 130),

          const SizedBox(height: 14),

          Text(
            t.get('stella'),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            '🐾 STELLURIINI CAT 🐾',
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),

          if ((user?.email ?? '').isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              user!.email!,
              style: const TextStyle(
                color: Colors.white60,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================
  // BALANCE CARD
  // ==========================================================

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: const Color(0xFF121C1C),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_wallet_rounded,
            size: 38,
            color: accentColor,
          ),

          const SizedBox(height: 12),

          Text(
            t.get('yourBalance'),
            style: const TextStyle(
              color: Colors.white60,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '$stl',
            style: const TextStyle(
              fontSize: 58,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),

          const Text(
            'STL',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 5,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            t.get('virtualPoints'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
            ),
          ),
        ],
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

    final remainingText =
        _remainingAdText();

    final adButtonEnabled =
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
            letterSpacing: 3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _openLanguageDialog,
          ),
          IconButton(
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
            padding: const EdgeInsets.all(16),
            children: [
              _buildStellaHeader(user),

              const SizedBox(height: 18),

              _buildBalanceCard(),

              const SizedBox(height: 18),

              // DAILY REWARD

              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    const Text(
                      '🎁',
                      style: TextStyle(fontSize: 42),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      t.get('dailyClaim'),
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      '🔥 ${t.get('streak')}: $streak / 7',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed:
                            dailyClaimed ? null : _dailyClaim,
                        icon: const Icon(Icons.redeem),
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

              const SizedBox(height: 16),

              // AD REWARD

              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    const Text(
                      '🐱 ▶️ 🪙',
                      style: TextStyle(fontSize: 34),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      t.get('watchEarn'),
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      '${t.get('dailyLimit')}: $adsToday / 5',
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),

                    if (adsToday < 5 &&
                        !canWatch) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${t.get('nextAd')}: $remainingText',
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed:
                            adButtonEnabled ? _watchAd : null,
                        icon: adLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(
                                Icons.play_circle_fill,
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

              const SizedBox(height: 16),

              // CAT FACT

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color:
                        accentColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      '🐾',
                      style: TextStyle(fontSize: 42),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      t.get('stellaFacts'),
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      fact,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // INFORMATION

              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: accentColor,
                      size: 40,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      t.get('info'),
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      t.get('solanaToken'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      t.get('stellaCompany'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              const Center(
                child: Text(
                  '🐱 Made with love for Stella 🐾',
                  style: TextStyle(
                    color: Colors.white38,
                  ),
                ),
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}