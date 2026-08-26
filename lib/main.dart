import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'cat_facts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await MobileAds.instance.initialize();

  runApp(const StelluriiniApp());
}

// ==========================================================
// APP
// ==========================================================

class StelluriiniApp extends StatelessWidget {
  const StelluriiniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stelluriini',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0B1112),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF35D0A0),
          brightness: Brightness.dark,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// ==========================================================
// AUTH GATE
// ==========================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        if (snapshot.hasData) {
          return const HomePage();
        }

        return const LoginScreen();
      },
    );
  }
}

// ==========================================================
// LOADING
// ==========================================================

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// ==========================================================
// LOGIN
// ==========================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool hidePassword = true;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _message('Täytä sähköposti ja salasana.');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          message = 'Virheellinen sähköposti tai salasana.';
          break;

        case 'invalid-email':
          message = 'Sähköpostiosoite ei ole kelvollinen.';
          break;

        case 'too-many-requests':
          message = 'Liian monta yritystä. Yritä myöhemmin uudelleen.';
          break;

        default:
          message = 'Kirjautuminen epäonnistui.';
      }

      _message(message);
    } catch (_) {
      _message('Kirjautuminen epäonnistui.');
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
        ),
      );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                ClipOval(
                  child: Image.asset(
                    'stella.jpg',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return const CircleAvatar(
                        radius: 60,
                        child: Icon(
                          Icons.pets,
                          size: 55,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'STELLURIINI',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Tervetuloa takaisin',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 40),

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Sähköposti',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  decoration: InputDecoration(
                    labelText: 'Salasana',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        hidePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          hidePassword = !hidePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: loading ? null : login,
                    child: loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'KIRJAUDU',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: loading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const RegisterScreen(),
                              ),
                            );
                          },
                    child: const Text(
                      'LUO UUSI TILI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// REGISTER
// ==========================================================

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool loading = false;
  bool hidePassword = true;
  bool hideConfirm = true;

  Future<void> register() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmController.text.trim();

    if (email.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty) {
      _message('Täytä kaikki kentät.');
      return;
    }

    if (password.length < 6) {
      _message(
        'Salasanan pitää olla vähintään 6 merkkiä.',
      );
      return;
    }

    if (password != confirm) {
      _message('Salasanat eivät täsmää.');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message = 'Tällä sähköpostilla on jo tili.';
          break;

        case 'invalid-email':
          message = 'Sähköpostiosoite ei ole kelvollinen.';
          break;

        case 'weak-password':
          message = 'Salasana on liian heikko.';
          break;

        default:
          message = 'Tilin luominen epäonnistui.';
      }

      _message(message);
    } catch (_) {
      _message('Tilin luominen epäonnistui.');
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
        ),
      );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Luo tili'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const SizedBox(height: 20),

              const Icon(
                Icons.person_add_alt_1,
                size: 80,
              ),

              const SizedBox(height: 20),

              const Text(
                'Luo Stelluriini-tili',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 32),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Sähköposti',
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: hidePassword,
                decoration: InputDecoration(
                  labelText: 'Salasana',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      hidePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        hidePassword = !hidePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: confirmController,
                obscureText: hideConfirm,
                decoration: InputDecoration(
                  labelText: 'Vahvista salasana',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      hideConfirm
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        hideConfirm = !hideConfirm;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: loading ? null : register,
                  child: loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'LUO TILI',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// HOME
// ==========================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String rewardedAdId =
      'ca-app-pub-3940256099942544/5224354917';

  static const String interstitialAdId =
      'ca-app-pub-3940256099942544/1033173712';

  static const int weeklyLimit = 100;

  FirebaseFirestore get firestore =>
      FirebaseFirestore.instance;

  RewardedAd? rewardedAd;
  InterstitialAd? interstitialAd;

  Timer? timer;

  bool loading = true;
  bool loadingRewarded = false;
  bool loadingInterstitial = false;
  bool showingAd = false;

  int stl = 0;
  int streak = 0;
  int weeklyPoints = 0;
  int adsToday = 0;
  int factDay = 1;

  bool dailyClaimed = false;

  String weekKey = '';

  DateTime? lastDaily;
  DateTime? lastAd;

  Duration dailyTimer = Duration.zero;
  Duration adTimer = Duration.zero;

  DocumentReference<Map<String, dynamic>>
      get userDocument {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Käyttäjää ei löytynyt.');
    }

    return firestore
        .collection('users')
        .doc(user.uid);
  }

  @override
  void initState() {
    super.initState();

    weekKey = _getWeekKey();

    _loadData();

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        _updateTimers();
        _checkNewDay();
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    rewardedAd?.dispose();
    interstitialAd?.dispose();
    super.dispose();
  }

  // ========================================================
  // WEEK
  // ========================================================

  String _getWeekKey() {
    final now = DateTime.now();

    final monday = now.subtract(
      Duration(days: now.weekday - 1),
    );

    return '${monday.year}-'
        '${monday.month.toString().padLeft(2, '0')}-'
        '${monday.day.toString().padLeft(2, '0')}';
  }

  // ========================================================
  // TODAY
  // ========================================================

  String _today() {
    final now = DateTime.now();

    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  // ========================================================
  // LOAD DATA
  // ========================================================

  Future<void> _loadData() async {
    try {
      final snapshot = await userDocument.get();

      if (!snapshot.exists) {
        await userDocument.set({
          'email':
              FirebaseAuth.instance.currentUser?.email ?? '',
          'points': 0,
          'weeklyPoints': 0,
          'weekKey': weekKey,
          'streak': 0,
          'dailyClaimed': false,
          'adsToday': 0,
          'factDay': 1,
          'createdAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        });
      }

      final data =
          (await userDocument.get()).data() ?? {};

      final storedWeek =
          data['weekKey'] as String? ?? '';

      if (storedWeek != weekKey) {
        weeklyPoints = 0;
        dailyClaimed = false;

        await userDocument.update({
          'weeklyPoints': 0,
          'weekKey': weekKey,
          'dailyClaimed': false,
          'updatedAt':
              FieldValue.serverTimestamp(),
        });
      } else {
        weeklyPoints =
            (data['weeklyPoints'] as num?)?.toInt() ?? 0;

        dailyClaimed =
            data['dailyClaimed'] == true;
      }

      stl =
          (data['points'] as num?)?.toInt() ?? 0;

      streak =
          (data['streak'] as num?)?.toInt() ?? 0;

      adsToday =
          (data['adsToday'] as num?)?.toInt() ?? 0;

      factDay =
          (data['factDay'] as num?)?.toInt() ?? 1;

      if (factDay < 1) {
        factDay = 1;
      }

      final lastDailyValue =
          data['lastDaily'];

      if (lastDailyValue is Timestamp) {
        lastDaily =
            lastDailyValue.toDate().toUtc();
      }

      final lastAdValue =
          data['lastAd'];

      if (lastAdValue is Timestamp) {
        lastAd =
            lastAdValue.toDate().toUtc();
      }

      await _checkNewDay();

      if (mounted) {
        setState(() {
          loading = false;
        });
      }

      _updateTimers();
      _loadRewardedAd();
      _loadInterstitialAd();
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }

      _message(
        'Tietojen lataaminen epäonnistui.',
      );
    }
  }

  // ========================================================
  // NEW DAY
  // ========================================================

  Future<void> _checkNewDay() async {
    try {
      final snapshot = await userDocument.get();

      if (!snapshot.exists) return;

      final data = snapshot.data() ?? {};

      final savedDate =
          data['currentDate'] as String?;

      final today = _today();

      if (savedDate == today) {
        return;
      }

      adsToday = 0;

      await userDocument.update({
        'currentDate': today,
        'adsToday': 0,
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {});
      }
    } catch (_) {}
  }

  // ========================================================
  // TIMERS
  // ========================================================

  void _updateTimers() {
    final now = DateTime.now().toUtc();

    Duration daily = Duration.zero;

    if (lastDaily != null) {
      final next =
          lastDaily!.add(const Duration(hours: 24));

      if (now.isBefore(next)) {
        daily = next.difference(now);
      }
    }

    Duration ad = Duration.zero;

    if (lastAd != null) {
      final next =
          lastAd!.add(const Duration(hours: 1));

      if (now.isBefore(next)) {
        ad = next.difference(now);
      }
    }

    if (!mounted) return;

    setState(() {
      dailyTimer = daily;
      adTimer = ad;
    });
  }

  bool get canDaily =>
      dailyTimer == Duration.zero &&
      !dailyClaimed &&
      weeklyPoints < weeklyLimit;

  bool get canAd =>
      adsToday < 5 &&
      adTimer == Duration.zero &&
      weeklyPoints < weeklyLimit;

  // ========================================================
  // DAILY REWARD
  // ========================================================

  int get dailyReward {
    final nextDay =
        streak >= 7 ? 7 : streak + 1;

    return nextDay;
  }

  // ========================================================
  // CAT FACT
  // ========================================================

  String get currentFact {
    if (catFacts.isEmpty) {
      return 'Stella on ihana kissa! 🐱';
    }

    final index =
        (factDay - 1) % catFacts.length;

    return catFacts[index];
  }

  // ========================================================
  // TIME
  // ========================================================

  String _time(Duration duration) {
    final hours = duration.inHours
        .toString()
        .padLeft(2, '0');

    final minutes =
        (duration.inMinutes % 60)
            .toString()
            .padLeft(2, '0');

    final seconds =
        (duration.inSeconds % 60)
            .toString()
            .padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  // ========================================================
  // DAILY CLAIM
  // ========================================================

  Future<void> _claimDaily() async {
    if (!canDaily) return;

    final now = DateTime.now().toUtc();

    if (lastDaily != null) {
      final difference =
          now.difference(lastDaily!);

      if (difference.inHours >= 48) {
        streak = 0;
      }
    }

    if (streak < 7) {
      streak++;
    }

    final reward =
        streak >= 7 ? 7 : streak;

    stl += reward;
    weeklyPoints += reward;

    if (weeklyPoints > weeklyLimit) {
      weeklyPoints = weeklyLimit;
    }

    dailyClaimed = true;
    lastDaily = now;

    factDay++;

    try {
      await userDocument.update({
        'points': stl,
        'weeklyPoints': weeklyPoints,
        'streak': streak,
        'dailyClaimed': true,
        'factDay': factDay,
        'lastDaily':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      _updateTimers();

      if (mounted) {
        setState(() {});
      }

      _message(
        '🎁 Daily Claim +$reward STL!',
      );

      _showInterstitial();
    } catch (_) {
      _message(
        'Daily Claimin tallennus epäonnistui.',
      );
    }
  }

  // ========================================================
  // WATCH AD
  // ========================================================

  Future<void> _watchAd() async {
    if (showingAd) return;

    await _checkNewDay();

    if (adsToday >= 5) {
      _message(
        'Päivän mainosraja 5/5 on täynnä.',
      );
      return;
    }

    if (weeklyPoints >= weeklyLimit) {
      _message(
        'Viikon 100 STL pistekatto on täynnä.',
      );
      return;
    }

    if (!canAd) {
      _message(
        'Odota ${_time(adTimer)}.',
      );
      return;
    }

    final ad = rewardedAd;

    if (ad == null) {
      _message(
        'Mainos latautuu. Odota hetki.',
      );

      _loadRewardedAd();
      return;
    }

    rewardedAd = null;
    showingAd = true;

    if (mounted) {
      setState(() {});
    }

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();

        if (mounted) {
          setState(() {
            showingAd = false;
          });
        }

        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent:
          (ad, error) {
        ad.dispose();

        if (mounted) {
          setState(() {
            showingAd = false;
          });
        }

        _message(
          'Mainosta ei voitu näyttää.',
        );

        _loadRewardedAd();
      },
    );

    ad.show(
      onUserEarnedReward: (
        AdWithoutView ad,
        RewardItem reward,
      ) {
        _giveThreeStl();
      },
    );
  }

  // ========================================================
  // GIVE STL
  // ========================================================

  Future<void> _giveThreeStl() async {
    if (adsToday >= 5) return;

    if (weeklyPoints >= weeklyLimit) {
      return;
    }

    final now = DateTime.now().toUtc();

    stl += 3;
    adsToday++;
    weeklyPoints += 3;

    if (weeklyPoints > weeklyLimit) {
      weeklyPoints = weeklyLimit;
    }

    lastAd = now;

    try {
      await userDocument.update({
        'points': stl,
        'weeklyPoints': weeklyPoints,
        'adsToday': adsToday,
        'lastAd':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      _updateTimers();

      if (mounted) {
        setState(() {});
      }

      _message('+3 STL! 🐱');
    } catch (_) {
      _message(
        'Pisteiden tallennus epäonnistui.',
      );
    }
  }

  // ========================================================
  // REWARDED AD
  // ========================================================

  void _loadRewardedAd() {
    if (loadingRewarded ||
        rewardedAd != null) {
      return;
    }

    loadingRewarded = true;

    if (mounted) {
      setState(() {});
    }

    RewardedAd.load(
      adUnitId: rewardedAdId,
      request: const AdRequest(),
      rewardedAdLoadCallback:
          RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          loadingRewarded = false;
          rewardedAd = ad;

          if (mounted) {
            setState(() {});
          }
        },
        onAdFailedToLoad: (error) {
          loadingRewarded = false;
          rewardedAd = null;

          if (mounted) {
            setState(() {});
          }

          Future.delayed(
            const Duration(seconds: 5),
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

  // ========================================================
  // INTERSTITIAL
  // ========================================================

  void _loadInterstitialAd() {
    if (loadingInterstitial ||
        interstitialAd != null) {
      return;
    }

    loadingInterstitial = true;

    InterstitialAd.load(
      adUnitId: interstitialAdId,
      request: const AdRequest(),
      adLoadCallback:
          InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          loadingInterstitial = false;
          interstitialAd = ad;

          if (mounted) {
            setState(() {});
          }
        },
        onAdFailedToLoad: (error) {
          loadingInterstitial = false;
          interstitialAd = null;

          Future.delayed(
            const Duration(seconds: 5),
            () {
              if (mounted) {
                _loadInterstitialAd();
              }
            },
          );
        },
      ),
    );
  }

  void _showInterstitial() {
    final ad = interstitialAd;

    if (ad == null) {
      _loadInterstitialAd();
      return;
    }

    interstitialAd = null;

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent:
          (ad, error) {
        ad.dispose();
        _loadInterstitialAd();
      },
    );

    ad.show();
  }

  // ========================================================
  // MESSAGE
  // ========================================================

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration:
              const Duration(seconds: 2),
        ),
      );
  }

  // ========================================================
  // BUILD
  // ========================================================

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const LoadingScreen();
    }

    final progress =
        (weeklyPoints / weeklyLimit)
            .clamp(0.0, 1.0);

    final limitReached =
        weeklyPoints >= weeklyLimit;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'STELLURIINI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Kirjaudu ulos',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _stellaCard(),

            const SizedBox(height: 14),

            _balanceCard(),

            const SizedBox(height: 14),

            _weeklyCard(progress, limitReached),

            const SizedBox(height: 14),

            _dailyCard(),

            const SizedBox(height: 14),

            _adCard(),

            const SizedBox(height: 14),

            _factCard(),

            const SizedBox(height: 14),

            _statsCard(),

            const SizedBox(height: 14),

            _infoCard(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ========================================================
  // STELLA CARD
  // ========================================================

  Widget _stellaCard() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ClipOval(
              child: Image.asset(
                'stella.jpg',
                width: 150,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return const CircleAvatar(
                    radius: 75,
                    child: Icon(
                      Icons.pets,
                      size: 65,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'STELLURIINI',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'STL',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              '🐱 Stella',
              style: TextStyle(
                color: Color(0xFF35D0A0),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================
  // BALANCE
  // ========================================================

  Widget _balanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'YOUR BALANCE',
              style: TextStyle(
                color: Colors.white60,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '$stl',
              style: const TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Color(0xFF35D0A0),
              ),
            ),

            const Text(
              'STL',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================
  // WEEKLY
  // ========================================================

  Widget _weeklyCard(
    double progress,
    bool limitReached,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_month,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Viikon aktiivisuus',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '$weeklyPoints / $weeklyLimit',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              borderRadius:
                  BorderRadius.circular(10),
            ),

            const SizedBox(height: 12),

            Text(
              limitReached
                  ? 'Viikon 100 STL pistekatto on täynnä.'
                  : 'Voit ansaita vielä '
                      '${weeklyLimit - weeklyPoints} STL tällä viikolla.',
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================
  // DAILY CARD
  // ========================================================

  Widget _dailyCard() {
    final currentDay =
        streak >= 7 ? 7 : streak + 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.card_giftcard,
                  color: Color(0xFF35D0A0),
                  size: 30,
                ),
                SizedBox(width: 10),
                Text(
                  'DAILY CLAIM',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              streak >= 7
                  ? '🔥 7 päivän putki saavutettu!'
                  : 'Päivä $currentDay / 7',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: List.generate(
                7,
                (index) {
                  final day = index + 1;

                  final completed =
                      streak >= day;

                  final today =
                      !completed &&
                      day == currentDay;

                  return Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 2,
                      ),
                      child: Container(
                        height: 78,
                        decoration:
                            BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                          border: Border.all(
                            color:
                                today || completed
                                    ? const Color(
                                        0xFF35D0A0,
                                      )
                                    : Colors.white12,
                            width:
                                today ? 2 : 1,
                          ),
                          color: today
                              ? const Color(
                                  0xFF35D0A0,
                                ).withValues(
                                  alpha: 0.18,
                                )
                              : completed
                                  ? const Color(
                                      0xFF35D0A0,
                                    ).withValues(
                                      alpha: 0.10,
                                    )
                                  : Colors.white
                                      .withValues(
                                      alpha: 0.04,
                                    ),
                        ),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Text(
                              completed
                                  ? '✓'
                                  : today
                                      ? '🎁'
                                      : '🔒',
                              style:
                                  const TextStyle(
                                fontSize: 19,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              'Päivä $day',
                              style:
                                  const TextStyle(
                                fontSize: 10,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            Text(
                              '$day STL',
                              style:
                                  const TextStyle(
                                fontSize: 9,
                                color:
                                    Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding:
                  const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(14),
                color: const Color(0xFF35D0A0)
                    .withValues(alpha: 0.10),
              ),
              child: Column(
                children: [
                  Text(
                    streak >= 7
                        ? '🔥 7+ PÄIVÄN PUTKI'
                        : '🎁 TÄMÄN PÄIVÄN PALKINTO',
                    style: const TextStyle(
                      color:
                          Color(0xFF35D0A0),
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '$dailyReward STL',
                    style:
                        const TextStyle(
                      fontSize: 26,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            if (!canDaily &&
                dailyTimer != Duration.zero) ...[
              const Text(
                'NEXT CLAIM IN',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                _time(dailyTimer),
                textAlign:
                    TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),
            ],

            SizedBox(
              height: 58,
              child: ElevatedButton.icon(
                onPressed:
                    canDaily
                        ? _claimDaily
                        : null,
                icon: const Icon(
                  Icons.card_giftcard,
                  size: 27,
                ),
                label: Text(
                  canDaily
                      ? 'DAILY CLAIM +$dailyReward STL'
                      : dailyClaimed
                          ? 'CLAIMED'
                          : 'WAIT',
                ),
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              '🎁 Päivä 1 → 1 STL\n'
              '🎁 Päivä 2 → 2 STL\n'
              '🎁 Päivä 3 → 3 STL\n'
              '🎁 Päivä 4 → 4 STL\n'
              '🎁 Päivä 5 → 5 STL\n'
              '🎁 Päivä 6 → 6 STL\n'
              '🎁 Päivä 7 → 7 STL',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              '🔥 Kun 7 päivän putki on täynnä, '
              'saat 7 STL joka päivä.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF35D0A0),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              '⚠️ Jos yksi päivä jää väliin, '
              'putki alkaa uudelleen päivästä 1.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              '📺 Daily Claim näyttää mainoksen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================
  // AD CARD
  // ========================================================

  Widget _adCard() {
    String buttonText;

    if (adsToday >= 5) {
      buttonText = 'DAILY LIMIT';
    } else if (weeklyPoints >= weeklyLimit) {
      buttonText = 'WEEKLY LIMIT';
    } else if (!canAd) {
      buttonText =
          'WAIT ${_time(adTimer)}';
    } else if (rewardedAd == null) {
      buttonText = 'LOADING AD...';
    } else {
      buttonText = 'WATCH AD +3 STL';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.ondemand_video,
                  color: Color(0xFF35D0A0),
                ),
                SizedBox(width: 10),
                Text(
                  'WATCH & EARN',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            const Text(
              'Katso mainos ja saat +3 STL.',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Today: $adsToday / 5',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed:
                    canAd &&
                            rewardedAd != null &&
                            !showingAd
                        ? _watchAd
                        : null,
                icon: const Icon(
                  Icons.play_arrow,
                ),
                label: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================
  // FACT CARD
  // ========================================================

  Widget _factCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.pets,
                  color: Color(0xFF35D0A0),
                ),
                SizedBox(width: 10),
                Text(
                  'STELLAN KISSAFAKTA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              'Päivä $factDay / ${catFacts.length}',
              style: const TextStyle(
                color: Color(0xFF35D0A0),
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              currentFact,
              style: const TextStyle(
                fontSize: 17,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================
  // STATS
  // ========================================================

  Widget _statsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'STL',
                    style: TextStyle(
                      color: Colors.white54,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '$stl',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Column(
                children: [
                  const Text(
                    'STREAK',
                    style: TextStyle(
                      color: Colors.white54,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    streak >= 7
                        ? '7+'
                        : '$streak / 7',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Column(
                children: [
                  const Text(
                    'ADS',
                    style: TextStyle(
                      color: Colors.white54,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '$adsToday / 5',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================
  // INFO
  // ========================================================

  Widget _infoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'STELLURIINI',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Stelluriini on Solana-verkkoon '
              'liittyvä yhteisöprojekti.',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              '🐱 Stella pitää sinulle seuraa '
              'Stelluriini-sovelluksessa!',
              style: TextStyle(
                color: Color(0xFF35D0A0),
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              '⭐ Päivittäinen aktiivisuus\n'
              '🐱 Kissafaktat\n'
              '🎁 Daily Claim\n'
              '📺 Katso mainoksia ja ansaitse STL-pisteitä',
              style: TextStyle(
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}