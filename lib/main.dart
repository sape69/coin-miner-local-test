import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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
      debugShowCheckedModeBanner: false,
      title: 'Stelluriini',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1112),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
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
          return const HomeScreen();
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
      showMessage('Täytä sähköposti ja salasana.');
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

      showMessage(message);
    } catch (_) {
      showMessage('Kirjautuminen epäonnistui.');
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    'stella.jpg',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
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
                    hintText: 'nimi@example.com',
                    prefixIcon: const Icon(Icons.email_outlined),
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
                    prefixIcon: const Icon(Icons.lock_outline),
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
                                builder: (_) => const RegisterScreen(),
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
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool loading = false;
  bool hidePassword = true;
  bool hideConfirmPassword = true;

  Future<void> register() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      showMessage('Täytä kaikki kentät.');
      return;
    }

    if (password.length < 6) {
      showMessage('Salasanan pitää olla vähintään 6 merkkiä.');
      return;
    }

    if (password != confirmPassword) {
      showMessage('Salasanat eivät täsmää.');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
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

      showMessage(message);
    } catch (_) {
      showMessage('Tilin luominen epäonnistui.');
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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
                  prefixIcon: const Icon(Icons.email_outlined),
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
                  prefixIcon: const Icon(Icons.lock_outline),
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
                controller: confirmPasswordController,
                obscureText: hideConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Vahvista salasana',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      hideConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        hideConfirmPassword =
                            !hideConfirmPassword;
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  RewardedAd? rewardedAd;

  bool adLoading = false;
  bool dataLoading = true;

  int points = 0;
  int weeklyPoints = 0;

  bool dailyLoginClaimed = false;

  String weekKey = '';

  static const int weeklyLimit = 100;

  // Google test Rewarded Ad ID.
  //
  // Tämä on TESTITUNNUS.
  // Vaihdetaan myöhemmin omaan AdMob-tunnukseen.
  static const String rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  @override
  void initState() {
    super.initState();

    weekKey = _getWeekKey();

    _loadUserData();
    _loadRewardedAd();
  }

  // ========================================================
  // WEEK KEY
  // ========================================================

  String _getWeekKey() {
    final now = DateTime.now();

    final monday =
        now.subtract(Duration(days: now.weekday - 1));

    return '${monday.year}-'
        '${monday.month.toString().padLeft(2, '0')}-'
        '${monday.day.toString().padLeft(2, '0')}';
  }

  // ========================================================
  // USER DOCUMENT
  // ========================================================

  DocumentReference<Map<String, dynamic>>
      get userDocument {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Käyttäjää ei löytynyt.');
    }

    return firestore.collection('users').doc(user.uid);
  }

  // ========================================================
  // LOAD USER DATA
  // ========================================================

  Future<void> _loadUserData() async {
    try {
      final snapshot = await userDocument.get();

      if (!snapshot.exists) {
        await userDocument.set({
          'email':
              FirebaseAuth.instance.currentUser?.email ?? '',
          'points': 0,
          'weeklyPoints': 0,
          'weekKey': weekKey,
          'dailyLoginClaimed': false,
          'tasksCompleted': 0,
          'adsWatched': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        points = 0;
        weeklyPoints = 0;
        dailyLoginClaimed = false;
      } else {
        final data = snapshot.data()!;

        final storedWeekKey =
            data['weekKey'] as String? ?? '';

        if (storedWeekKey != weekKey) {
          await userDocument.update({
            'weeklyPoints': 0,
            'weekKey': weekKey,
            'dailyLoginClaimed': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          points =
              (data['points'] as num?)?.toInt() ?? 0;

          weeklyPoints = 0;
          dailyLoginClaimed = false;
        } else {
          points =
              (data['points'] as num?)?.toInt() ?? 0;

          weeklyPoints =
              (data['weeklyPoints'] as num?)?.toInt() ?? 0;

          dailyLoginClaimed =
              data['dailyLoginClaimed'] == true;
        }
      }
    } catch (e) {
      _showMessage(
        'Tietojen lataaminen epäonnistui.',
      );
    }

    if (mounted) {
      setState(() {
        dataLoading = false;
      });
    }
  }

  // ========================================================
  // LOAD REWARDED AD
  // ========================================================

  void _loadRewardedAd() {
    if (adLoading || rewardedAd != null) {
      return;
    }

    adLoading = true;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          rewardedAd = ad;
          adLoading = false;

          ad.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              rewardedAd = null;

              _loadRewardedAd();

              if (mounted) {
                setState(() {});
              }
            },
            onAdFailedToShowFullScreenContent:
                (ad, error) {
              ad.dispose();
              rewardedAd = null;

              _loadRewardedAd();

              _showMessage(
                'Mainosta ei voitu näyttää.',
              );
            },
          );

          if (mounted) {
            setState(() {});
          }
        },
        onAdFailedToLoad: (error) {
          rewardedAd = null;
          adLoading = false;

          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }

  // ========================================================
  // SHOW REWARDED AD
  // ========================================================

  void _showRewardedAd({
    required Future<void> Function() onReward,
  }) {
    final ad = rewardedAd;

    if (ad == null) {
      _showMessage(
        'Mainos ei ole vielä valmis. Yritä hetken päästä uudelleen.',
      );

      _loadRewardedAd();
      return;
    }

    rewardedAd = null;

    ad.show(
      onUserEarnedReward: (ad, reward) async {
        await onReward();
      },
    );
  }

  // ========================================================
  // ADD POINTS
  // ========================================================

  Future<bool> _addPoints(int amount) async {
    try {
      final result =
          await firestore.runTransaction<Map<String, dynamic>>(
        (transaction) async {
          final snapshot =
              await transaction.get(userDocument);

          if (!snapshot.exists) {
            throw Exception(
              'Käyttäjätietoja ei löytynyt.',
            );
          }

          final data = snapshot.data()!;

          int currentPoints =
              (data['points'] as num?)?.toInt() ?? 0;

          int currentWeekly =
              (data['weeklyPoints'] as num?)?.toInt() ?? 0;

          String storedWeekKey =
              data['weekKey'] as String? ?? '';

          if (storedWeekKey != weekKey) {
            currentWeekly = 0;
            storedWeekKey = weekKey;
          }

          final remaining =
              weeklyLimit - currentWeekly;

          if (remaining <= 0) {
            return {
              'success': false,
              'currentPoints': currentPoints,
              'currentWeekly': currentWeekly,
            };
          }

          final actualAmount =
              amount > remaining ? remaining : amount;

          currentPoints += actualAmount;
          currentWeekly += actualAmount;

          transaction.update(
            userDocument,
            {
              'points': currentPoints,
              'weeklyPoints': currentWeekly,
              'weekKey': storedWeekKey,
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );

          return {
            'success': true,
            'currentPoints': currentPoints,
            'currentWeekly': currentWeekly,
          };
        },
      );

      points =
          result['currentPoints'] as int? ?? points;

      weeklyPoints =
          result['currentWeekly'] as int? ?? weeklyPoints;

      return result['success'] == true;
    } catch (e) {
      _showMessage(
        'Pisteiden tallentaminen epäonnistui.',
      );

      return false;
    }
  }

  // ========================================================
  // DAILY LOGIN
  // ========================================================

  void _dailyLoginAd() {
    if (dailyLoginClaimed) {
      _showMessage(
        'Daily Login on jo käytetty tällä viikolla.',
      );
      return;
    }

    if (weeklyPoints >= weeklyLimit) {
      _showMessage(
        'Viikon 100 pisteen raja on täynnä.',
      );
      return;
    }

    _showRewardedAd(
      onReward: () async {
        final success = await _addPoints(10);

        if (!success) {
          return;
        }

        await userDocument.update({
          'dailyLoginClaimed': true,
          'adsWatched': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          setState(() {
            dailyLoginClaimed = true;
          });
        }

        _showMessage(
          '+10 pistettä! Daily Login suoritettu.',
        );
      },
    );
  }

  // ========================================================
  // TASK
  // ========================================================

  void _watchTaskAd() {
    if (weeklyPoints >= weeklyLimit) {
      _showMessage(
        'Viikon 100 pisteen raja on täynnä.',
      );
      return;
    }

    _showRewardedAd(
      onReward: () async {
        final success = await _addPoints(10);

        if (!success) {
          return;
        }

        await userDocument.update({
          'tasksCompleted': FieldValue.increment(1),
          'adsWatched': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        _showMessage(
          '+10 pistettä! Tehtävä suoritettu.',
        );

        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  // ========================================================
  // LOGOUT
  // ========================================================

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  // ========================================================
  // MESSAGE
  // ========================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ========================================================
  // BUILD
  // ========================================================

  @override
  Widget build(BuildContext context) {
    if (dataLoading) {
      return const LoadingScreen();
    }

    final user =
        FirebaseAuth.instance.currentUser;

    final progress =
        (weeklyPoints / weeklyLimit).clamp(0.0, 1.0);

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
        actions: [
          IconButton(
            tooltip: 'Kirjaudu ulos',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            // ==========================================
            // WELCOME
            // ==========================================

            Text(
              'Tervetuloa!',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 6),

            Text(
              user?.email ?? '',
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 24),

            // ==========================================
            // POINTS CARD
            // ==========================================

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF33205F),
                    Color(0xFF16121F),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    size: 50,
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'PISTEET',
                    style: TextStyle(
                      fontSize: 15,
                      letterSpacing: 2,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '$points',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Sovelluksen pisteitä',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==========================================
            // WEEKLY PROGRESS
            // ==========================================

            Card(
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
                          ? 'Viikon pistekatto on täynnä.'
                          : 'Voit ansaita vielä '
                              '${weeklyLimit - weeklyPoints} pistettä tällä viikolla.',
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==========================================
            // DAILY LOGIN
            // ==========================================

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.login_rounded,
                          size: 30,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'DAILY LOGIN',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Kirjaudu päivittäin ja pidä aktiivisuutesi yllä.',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed:
                            dailyLoginClaimed ||
                                    limitReached
                                ? null
                                : _dailyLoginAd,
                        icon: const Icon(
                          Icons.play_circle_outline,
                        ),
                        label: Text(
                          dailyLoginClaimed
                              ? 'KÄYTETTY'
                              : 'KATSO MAINOS +10',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==========================================
            // TASKS
            // ==========================================

            const Text(
              'TEHTÄVÄT',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.all(16),
                leading: const CircleAvatar(
                  radius: 28,
                  child: Icon(
                    Icons.ondemand_video,
                  ),
                ),
                title: const Text(
                  'Katso mainos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  '+10 pistettä',
                ),
                trailing: FilledButton(
                  onPressed:
                      limitReached
                          ? null
                          : _watchTaskAd,
                  child: const Text(
                    'TEE',
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.all(16),
                leading: const CircleAvatar(
                  radius: 28,
                  child: Icon(
                    Icons.task_alt,
                  ),
                ),
                title: const Text(
                  'Viikon aktiivisuus',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '$weeklyPoints / $weeklyLimit pistettä',
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ==========================================
            // INFORMATION
            // ==========================================

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(16),

                // KORJATTU:
                // withOpacity() -> withValues(alpha:)
                color: Colors.white.withValues(
                  alpha: 0.05,
                ),
              ),
              child: const Text(
                'Stelluriini-pisteet ovat tällä hetkellä '
                'sovelluksen sisäisiä pisteitä. Niitä ei '
                'pidä tässä vaiheessa käsittää oikeina '
                'STL-tokeneina tai rahana.',
                style: TextStyle(
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 30),

            Center(
              child: Text(
                'STELLURIINI • $weekKey',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    rewardedAd?.dispose();
    super.dispose();
  }
}