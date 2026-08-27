import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_localizations.dart';
import '../cat_facts.dart';
import '../main.dart';
import '../widgets/cat_avatar.dart';

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

    cooldownTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    cooldownTimer?.cancel();
    rewardedAd?.dispose();
    super.dispose();
  }

  String _dateKey() {
    final now = DateTime.now();

    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey();

    int savedAds = prefs.getInt('ads_today') ?? 0;
    final savedAdDate = prefs.getString('ad_date') ?? '';

    if (savedAdDate != today) {
      savedAds = 0;
      await prefs.setInt('ads_today', 0);
      await prefs.setString('ad_date', today);
    }

    final lastAdString = prefs.getString('last_ad_time');

    if (!mounted) return;

    setState(() {
      stl = prefs.getInt('stl_balance') ?? 0;
      streak = prefs.getInt('streak') ?? 0;
      adsToday = savedAds;
      dailyClaimed =
          prefs.getString('last_daily') == today;

      if (lastAdString != null) {
        lastAdTime = DateTime.tryParse(lastAdString);
      }

      loading = false;
    });
  }

  bool get canWatchAd {
    if (adsToday >= 5) return false;

    if (lastAdTime == null) return true;

    final nextTime =
        lastAdTime!.add(const Duration(hours: 1));

    return DateTime.now().isAfter(nextTime);
  }

  String get remainingTime {
    if (lastAdTime == null) return '';

    final nextTime =
        lastAdTime!.add(const Duration(hours: 1));

    final remaining =
        nextTime.difference(DateTime.now());

    if (remaining.isNegative) return '';

    final minutes = remaining.inMinutes + 1;

    return '$minutes min';
  }

  Future<void> _dailyClaim() async {
    if (dailyClaimed) return;

    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey();

    final lastDate =
        prefs.getString('last_daily') ?? '';

    int newStreak = 1;

    final yesterday =
        DateTime.now().subtract(const Duration(days: 1));

    final yesterdayKey =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    if (lastDate == yesterdayKey) {
      newStreak = streak + 1;
    }

    final reward = newStreak >= 7 ? 7 : 3;
    final newBalance = stl + reward;

    await prefs.setInt('stl_balance', newBalance);
    await prefs.setInt('streak', newStreak);
    await prefs.setString('last_daily', today);

    if (!mounted) return;

    setState(() {
      stl = newBalance;
      streak = newStreak;
      dailyClaimed = true;
    });

    _message('+$reward STL! 🐱');
  }

  void _loadRewardedAd() {
    if (adLoading) return;

    setState(() => adLoading = true);

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }

          setState(() {
            rewardedAd = ad;
            adLoading = false;
          });
        },
        onAdFailedToLoad: (_) {
          if (!mounted) return;

          setState(() {
            rewardedAd = null;
            adLoading = false;
          });
        },
      ),
    );
  }

  Future<void> _watchAd() async {
    if (adsToday >= 5) {
      _message(t.get('dailyLimitReached'));
      return;
    }

    if (!canWatchAd) {
      _message(
        'Seuraava mainos: $remainingTime',
      );
      return;
    }

    if (rewardedAd == null) {
      _message('Mainosta ladataan...');
      _loadRewardedAd();
      return;
    }

    final ad = rewardedAd!;
    rewardedAd = null;

    var earnedReward = false;

    ad.fullScreenContentCallback =
        FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (ad) async {
        ad.dispose();

        if (earnedReward) {
          await _addAdReward();
        }

        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewardedAd();
      },
    );

    ad.show(
      onUserEarnedReward: (_, __) {
        earnedReward = true;
      },
    );
  }

  Future<void> _addAdReward() async {
    if (adsToday >= 5) return;

    final prefs = await SharedPreferences.getInstance();

    final now = DateTime.now();
    final newBalance = stl + 3;
    final newAdsToday = adsToday + 1;

    await prefs.setInt('stl_balance', newBalance);
    await prefs.setInt('ads_today', newAdsToday);
    await prefs.setString('ad_date', _dateKey());
    await prefs.setString(
      'last_ad_time',
      now.toIso8601String(),
    );

    if (!mounted) return;

    setState(() {
      stl = newBalance;
      adsToday = newAdsToday;
      lastAdTime = now;
    });

    _message(t.get('pointsAdded'));
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  void _openLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t.get('selectLanguage')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppLocalizations.supportedLanguages.entries
                .map(
                  (entry) => ListTile(
                    title: Text(entry.value),
                    trailing:
                        widget.languageCode == entry.key
                            ? const Icon(
                                Icons.check,
                                color: accentColor,
                              )
                            : null,
                    onTap: () async {
                      await widget.changeLanguage(entry.key);

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final factIndex =
        DateTime.now().day % catFacts.length;

    final fact =
        catFacts[factIndex].text(widget.languageCode);

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('STELLURIINI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _openLanguageDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const CatAvatar(size: 100),
                    const SizedBox(height: 10),
                    const Text(
                      '🐱 Stella',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

            Card(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    Text(
                      t.get('yourBalance'),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$stl STL',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
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

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      t.get('dailyClaim'),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('🔥 $streak / 7'),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed:
                          dailyClaimed ? null : _dailyClaim,
                      child: Text(
                        dailyClaimed
                            ? t.get('claimed')
                            : t.get('dailyReward'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      t.get('watchEarn'),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Text('📺 $adsToday / 5'),

                    if (!canWatchAd && adsToday < 5)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '⏳ Seuraava mainos: $remainingTime',
                          style: const TextStyle(
                            color: Colors.orange,
                          ),
                        ),
                      ),

                    const SizedBox(height: 15),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            canWatchAd &&
                                    rewardedAd != null &&
                                    !adLoading
                                ? _watchAd
                                : null,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(
                          adLoading
                              ? t.get('loadingAd')
                              : adsToday >= 5
                                  ? 'PÄIVÄRAJA TÄYNNÄ'
                                  : !canWatchAd
                                      ? 'ODOTA $remainingTime'
                                      : rewardedAd == null
                                          ? t.get('adUnavailable')
                                          : t.get('watchAd'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      t.get('stellaFacts'),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Icon(
                      Icons.pets,
                      size: 42,
                      color: accentColor,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      fact,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
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
    );
  }
}