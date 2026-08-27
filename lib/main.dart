import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ==========================================================
// MAIN
// ==========================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await MobileAds.instance.initialize();

  runApp(const StelluriiniApp());
}

// ==========================================================
// COLORS
// ==========================================================

const Color backgroundColor = Color(0xFF0B1112);
const Color cardColor = Color(0xFF151B1C);
const Color accentColor = Color(0xFF35D0A0);

// Googlen virallinen TEST Rewarded Ad -ID.
// Älä käytä tätä tuotantoversiossa.
const String rewardedAdUnitId =
    'ca-app-pub-3940256099942544/5224354917';

// ==========================================================
// APP
// ==========================================================

class StelluriiniApp extends StatefulWidget {
  const StelluriiniApp({super.key});

  @override
  State<StelluriiniApp> createState() => _StelluriiniAppState();
}

class _StelluriiniAppState extends State<StelluriiniApp> {
  String languageCode = 'fi';
  bool languageLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      languageCode = prefs.getString('language') ?? 'fi';
      languageLoaded = true;
    });
  }

  Future<void> changeLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('language', language);

    if (!mounted) return;

    setState(() {
      languageCode = language;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stelluriini',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: Brightness.dark,
        ),
        cardTheme: const CardThemeData(
          color: cardColor,
          elevation: 2,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.black,
          ),
        ),
      ),
      home: languageLoaded
          ? AuthGate(
              languageCode: languageCode,
              changeLanguage: changeLanguage,
            )
          : const LoadingPage(),
    );
  }
}

// ==========================================================
// AUTH GATE
// ==========================================================

class AuthGate extends StatelessWidget {
  final String languageCode;
  final Future<void> Function(String) changeLanguage;

  const AuthGate({
    super.key,
    required this.languageCode,
    required this.changeLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingPage();
        }

        if (snapshot.hasData) {
          return HomePage(
            languageCode: languageCode,
            changeLanguage: changeLanguage,
          );
        }

        return LoginPage(
          languageCode: languageCode,
          changeLanguage: changeLanguage,
        );
      },
    );
  }
}

// ==========================================================
// LOADING PAGE
// ==========================================================

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: accentColor,
        ),
      ),
    );
  }
}

// ==========================================================
// LOGIN PAGE
// ==========================================================

class LoginPage extends StatefulWidget {
  final String languageCode;
  final Future<void> Function(String) changeLanguage;

  const LoginPage({
    super.key,
    required this.languageCode,
    required this.changeLanguage,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool loading = false;
  bool showPassword = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _message('Anna sähköposti ja salasana.');
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
      _message(_firebaseError(e.code));
    } catch (_) {
      _message('Kirjautuminen epäonnistui.');
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  String _firebaseError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Sähköpostiosoite ei ole kelvollinen.';

      case 'user-not-found':
        return 'Käyttäjää ei löytynyt.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'Väärä sähköposti tai salasana.';

      case 'user-disabled':
        return 'Käyttäjätili on poistettu käytöstä.';

      case 'too-many-requests':
        return 'Liian monta yritystä. Odota hetki.';

      case 'network-request-failed':
        return 'Internet-yhteyttä ei löytynyt.';

      default:
        return 'Virhe: $code';
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CatAvatar(size: 120),

                    const SizedBox(height: 20),

                    const Text(
                      'STELLURIINI',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Kirjaudu Stelluriiniin 🐱',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 28),

                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Sähköposti',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: passwordController,
                      obscureText: !showPassword,
                      onSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: 'Salasana',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              showPassword = !showPassword;
                            });
                          },
                        ),
                      ),
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: loading
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordPage(),
                                  ),
                                );
                              },
                        child: const Text(
                          'Unohditko salasanan?',
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: loading ? null : _login,
                        icon: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.login),
                        label: Text(
                          loading
                              ? 'KIRJAUDUTAAN...'
                              : 'KIRJAUDU SISÄÄN',
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextButton(
                      onPressed: loading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const RegisterPage(),
                                ),
                              );
                            },
                      child: const Text(
                        'Ei vielä tiliä? Luo uusi tili',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// REGISTER PAGE
// ==========================================================

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController confirmController =
      TextEditingController();

  bool loading = false;
  bool showPassword = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirm = confirmController.text;

    if (email.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty) {
      _message('Täytä kaikki kentät.');
      return;
    }

    if (password.length < 6) {
      _message(
        'Salasanassa pitää olla vähintään 6 merkkiä.',
      );
      return;
    }

    if (password != confirm) {
      _message('Salasanat eivät ole samat.');
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

      if (!mounted) return;

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _message(_firebaseError(e.code));
    } catch (_) {
      _message('Tilin luominen epäonnistui.');
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  String _firebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Tämä sähköpostiosoite on jo käytössä.';

      case 'invalid-email':
        return 'Sähköpostiosoite ei ole kelvollinen.';

      case 'weak-password':
        return 'Salasana on liian heikko.';

      case 'network-request-failed':
        return 'Internet-yhteyttä ei löytynyt.';

      default:
        return 'Virhe: $code';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LUO TILI'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.person_add,
                      size: 70,
                      color: accentColor,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'LUO STELLURIINI-TILI',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 28),

                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Sähköposti',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: passwordController,
                      obscureText: !showPassword,
                      decoration: InputDecoration(
                        labelText: 'Salasana',
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              showPassword = !showPassword;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: confirmController,
                      obscureText: !showPassword,
                      decoration: const InputDecoration(
                        labelText: 'Vahvista salasana',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed:
                            loading ? null : _register,
                        icon: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.person_add),
                        label: Text(
                          loading
                              ? 'LUODAAN...'
                              : 'LUO TILI',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// FORGOT PASSWORD
// ==========================================================

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();
}

class _ForgotPasswordPageState
    extends State<ForgotPasswordPage> {
  final TextEditingController emailController =
      TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _message('Anna sähköpostiosoitteesi.');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      _message(
        'Palautuslinkki lähetettiin sähköpostiin.',
      );
    } on FirebaseAuthException catch (e) {
      _message('Virhe: ${e.code}');
    } catch (_) {
      _message('Palautuslinkin lähetys epäonnistui.');
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PALAUTA SALASANA'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 30),

              const Icon(
                Icons.lock_reset,
                size: 70,
                color: accentColor,
              ),

              const SizedBox(height: 25),

              const Text(
                'Anna sähköpostiosoitteesi. Lähetämme sinulle salasanan palautuslinkin.',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 25),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Sähköposti',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : _reset,
                  child: Text(
                    loading
                        ? 'LÄHETETÄÄN...'
                        : 'LÄHETÄ PALAUTUSLINKKI',
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
// HOME PAGE
// ==========================================================

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

  RewardedAd? rewardedAd;

  AppLocalizations get t =>
      AppLocalizations(widget.languageCode);

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadRewardedAd();
  }

  @override
  void dispose() {
    rewardedAd?.dispose();
    super.dispose();
  }

  String _dateKey() {
    final now = DateTime.now();

    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ========================================================
  // LOAD DATA
  // ========================================================

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final currentToday = _dateKey();

    final savedDate =
        prefs.getString('last_daily') ?? '';

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

    if (!mounted) return;

    setState(() {
      today = currentToday;
      stl = prefs.getInt('stl_balance') ?? 0;
      streak = prefs.getInt('streak') ?? 0;
      adsToday = currentAds;
      dailyClaimed = savedDate == currentToday;
      loading = false;
    });
  }

  // ========================================================
  // DAILY CLAIM
  // ========================================================

  Future<void> _dailyClaim() async {
    if (dailyClaimed) {
      _message(t.get('claimed'));
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    final lastDate =
        prefs.getString('last_daily') ?? '';

    int newStreak;

    if (lastDate.isEmpty) {
      newStreak = 1;
    } else {
      final yesterday = DateTime.now()
          .subtract(const Duration(days: 1));

      final yesterdayKey =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      if (lastDate == yesterdayKey) {
        newStreak = streak + 1;
      } else {
        newStreak = 1;
      }
    }

    final reward =
        newStreak >= 7 ? 7 : 3;

    final newBalance = stl + reward;

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
      today,
    );

    if (!mounted) return;

    setState(() {
      stl = newBalance;
      streak = newStreak;
      dailyClaimed = true;
    });

    _message('+$reward STL! 🐱');
  }

  // ========================================================
  // REWARDED AD
  // ========================================================

  void _loadRewardedAd() {
    setState(() {
      adLoading = true;
    });

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
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
        onAdFailedToLoad: (LoadAdError error) {
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

    if (rewardedAd == null) {
      _message('Mainosta ladataan. Yritä hetken kuluttua.');
      _loadRewardedAd();
      return;
    }

    final ad = rewardedAd!;

    rewardedAd = null;

    bool earnedReward = false;

    ad.fullScreenContentCallback =
        FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();

        if (earnedReward) {
          _addAdReward();
        }

        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent:
          (RewardedAd ad, AdError error) {
        ad.dispose();
        _loadRewardedAd();
      },
    );

    ad.show(
      onUserEarnedReward: (
        AdWithoutView ad,
        RewardItem reward,
      ) {
        earnedReward = true;
      },
    );
  }

  Future<void> _addAdReward() async {
    if (adsToday >= 5) return;

    final prefs = await SharedPreferences.getInstance();

    final newBalance = stl + 3;
    final newAdsToday = adsToday + 1;

    await prefs.setInt(
      'stl_balance',
      newBalance,
    );

    await prefs.setInt(
      'ads_today',
      newAdsToday,
    );

    await prefs.setString(
      'ad_date',
      today,
    );

    if (!mounted) return;

    setState(() {
      stl = newBalance;
      adsToday = newAdsToday;
    });

    _message(t.get('pointsAdded'));
  }

  // ========================================================
  // MESSAGE
  // ========================================================

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

  // ========================================================
  // LOGOUT
  // ========================================================

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  // ========================================================
  // LANGUAGE DIALOG
  // ========================================================

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
                  .supportedLanguages.entries
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

                      Navigator.pop(dialogContext);
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

  // ========================================================
  // BUILD
  // ========================================================

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const LoadingPage();
    }

    final user =
        FirebaseAuth.instance.currentUser;

    final factIndex =
        DateTime.now().day % catFacts.length;

    final fact =
        catFacts[factIndex].text(widget.languageCode);

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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const CatAvatar(size: 110),

                      const SizedBox(height: 12),

                      Text(
                        t.get('stella'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
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
                  padding: const EdgeInsets.all(28),
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
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),

                      const Text(
                        'STL',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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

              // DAILY CLAIM
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        '${t.get('streak')}: 🔥 $streak',
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
              ),

              const SizedBox(height: 14),

              // WATCH & EARN
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        '${t.get('dailyLimit')}: $adsToday / 5',
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: adsToday >= 5 ||
                                  rewardedAd == null ||
                                  adLoading
                              ? null
                              : _watchAd,
                          icon: adLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(Icons.play_arrow),
                          label: Text(
                            adLoading
                                ? 'MAINOSTA LADATAAN...'
                                : rewardedAd == null
                                    ? 'MAINOS EI SAATAVILLA'
                                    : t.get('watchAd'),
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
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      Text(
                        t.get('stellaFacts'),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
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
                        textAlign: TextAlign.center,
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

              // INFO
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
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
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        t.get('solanaToken'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        t.get('stellaCompany'),
                        textAlign: TextAlign.center,
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

// ==========================================================
// CAT AVATAR
// ==========================================================

class CatAvatar extends StatelessWidget {
  final double size;

  const CatAvatar({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'stella.jpg',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: size,
            height: size,
            color: cardColor,
            alignment: Alignment.center,
            child: Icon(
              Icons.pets,
              size: size * 0.5,
              color: accentColor,
            ),
          );
        },
      ),
    );
  }
}

// ==========================================================
// LOCALIZATIONS
// ==========================================================

class AppLocalizations {
  final String languageCode;

  const AppLocalizations(this.languageCode);

  static const Map<String, String> supportedLanguages = {
    'fi': '🇫🇮 Suomi',
    'en': '🇬🇧 English',
  };

  String get(String key) {
    final language =
        _translations[languageCode] ?? _translations['fi']!;

    return language[key] ??
        _translations['fi']![key] ??
        key;
  }

  static const Map<String, Map<String, String>>
      _translations = {
    'fi': {
      'selectLanguage': 'Valitse kieli',
      'yourBalance': 'SALDOSI',
      'dailyClaim': 'PÄIVITTÄINEN PALKINTO',
      'watchEarn': 'KATSO JA ANSAITSE',
      'watchAd': 'Katso mainos +3 STL',
      'dailyLimit': 'PÄIVÄRAJA',
      'stella': '🐱 Stella',
      'stellaFacts': 'STELLAN KISSAFAKTA',
      'streak': 'PUTKI',
      'info': 'TIETOJA',
      'solanaToken':
          'Stelluriini on Solana-verkossa oleva yhteisötokeni.',
      'stellaCompany':
          '🐱 Stella pitää sinulle seuraa Stelluriinin parissa!',
      'claimed': 'KÄYTETTY',
      'dailyReward': 'HAE PÄIVÄN PALKINTO',
      'dailyLimitReached':
          'Päivän mainosraja 5/5 on täynnä.',
      'pointsAdded': '+3 STL! 🐱',
      'virtualPoints': 'Virtuaalisia sovelluspisteitä',
    },
    'en': {
      'selectLanguage': 'Select language',
      'yourBalance': 'YOUR BALANCE',
      'dailyClaim': 'DAILY CLAIM',
      'watchEarn': 'WATCH & EARN',
      'watchAd': 'Watch ad +3 STL',
      'dailyLimit': 'DAILY LIMIT',
      'stella': '🐱 Stella',
      'stellaFacts': "STELLA'S CAT FACT",
      'streak': 'STREAK',
      'info': 'INFORMATION',
      'solanaToken':
          'Stelluriini is a community token on the Solana network.',
      'stellaCompany':
          '🐱 Stella keeps you company while using Stelluriini!',
      'claimed': 'CLAIMED',
      'dailyReward': 'CLAIM DAILY REWARD',
      'dailyLimitReached':
          'The daily ad limit of 5/5 has been reached.',
      'pointsAdded': '+3 STL! 🐱',
      'virtualPoints': 'Virtual in-app points',
    },
  };
}

// ==========================================================
// CAT FACT
// ==========================================================

class CatFact {
  final Map<String, String> translations;

  const CatFact(this.translations);

  String text(String languageCode) {
    return translations[languageCode] ??
        translations['en'] ??
        translations['fi'] ??
        '';
  }
}

const List<CatFact> catFacts = [
  CatFact({
    'fi':
        'Kissat nukkuvat usein noin 12–16 tuntia vuorokaudessa.',
    'en':
        'Cats often sleep around 12–16 hours a day.',
  }),
  CatFact({
    'fi':
        'Kissan viikset ovat erittäin herkkiä tuntoelimiä.',
    'en':
        'A cat’s whiskers are very sensitive sensory organs.',
  }),
  CatFact({
    'fi':
        'Kissan nenän kuvio on yksilöllinen.',
    'en':
        'Every cat has a unique nose pattern.',
  }),
  CatFact({
    'fi':
        'Kissat voivat kuulla erittäin korkeita ääniä.',
    'en':
        'Cats can hear very high-frequency sounds.',
  }),
  CatFact({
    'fi':
        'Kissan kynnet ovat sisäänvedettävät.',
    'en':
        'Cats have retractable claws.',
  }),
  CatFact({
    'fi':
        'Kissat käyttävät häntäänsä myös tasapainon apuna.',
    'en':
        'Cats also use their tails to help with balance.',
  }),
  CatFact({
    'fi':
        'Hidas silmien räpytys voi olla kissan ystävällinen tervehdys.',
    'en':
        'A slow blink can be a friendly greeting from a cat.',
  }),
  CatFact({
    'fi':
        'Kissat pitävät usein korkeista tarkkailupaikoista.',
    'en':
        'Cats often enjoy high places where they can observe their surroundings.',
  }),
  CatFact({
    'fi':
        'Kissat käyttävät paljon aikaa turkkinsa hoitamiseen.',
    'en':
        'Cats spend a lot of time grooming their fur.',
  }),
  CatFact({
    'fi':
        'Kissat ovat luonnostaan uteliaita eläimiä.',
    'en':
        'Cats are naturally curious animals.',
  }),
];