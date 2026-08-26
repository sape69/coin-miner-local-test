import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B1112),
          centerTitle: true,
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
        // LADATAAN
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // KÄYTTÄJÄ ON KIRJAUTUNUT
        if (snapshot.hasData) {
          return const HomePage();
        }

        // EI OLE KIRJAUTUNUT
        return const LoginPage();
      },
    );
  }
}

// ==========================================================
// LOGIN PAGE
// ==========================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

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

  // ========================================================
  // LOGIN
  // ========================================================

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty) {
      _showMessage('Anna sähköpostiosoite.');
      return;
    }

    if (password.isEmpty) {
      _showMessage('Anna salasana.');
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
      _showMessage(_firebaseError(e.code));
    } catch (_) {
      _showMessage('Kirjautuminen epäonnistui.');
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  // ========================================================
  // FIREBASE ERRORS
  // ========================================================

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

  // ========================================================
  // MESSAGE
  // ========================================================

  void _showMessage(String message) {
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
  // BUILD
  // ========================================================

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
                    // LOGO
                    ClipOval(
                      child: Image.asset(
                        'stella.jpg',
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) {
                          return const CircleAvatar(
                            radius: 55,
                            backgroundColor:
                                Color(0xFF151B1C),
                            child: Icon(
                              Icons.pets,
                              size: 55,
                              color: Color(0xFF35D0A0),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'STELLURIINI',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Kirjaudu Stelluriiniin',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // EMAIL
                    TextField(
                      controller: emailController,
                      keyboardType:
                          TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Sähköposti',
                        prefixIcon:
                            Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // PASSWORD
                    TextField(
                      controller: passwordController,
                      obscureText: !showPassword,
                      onSubmitted: (_) {
                        _login();
                      },
                      decoration: InputDecoration(
                        labelText: 'Salasana',
                        prefixIcon:
                            const Icon(Icons.lock_outline),
                        border:
                            const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              showPassword =
                                  !showPassword;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // FORGOT PASSWORD
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

                    // LOGIN BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed:
                            loading ? null : _login,
                        icon: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
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

                    const SizedBox(height: 14),

                    // REGISTER
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
  State<RegisterPage> createState() =>
      _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool loading = false;
  bool showPassword = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // ========================================================
  // REGISTER
  // ========================================================

  Future<void> _register() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword =
        confirmPasswordController.text;

    if (email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('Täytä kaikki kentät.');
      return;
    }

    if (password.length < 6) {
      _showMessage(
        'Salasanassa pitää olla vähintään 6 merkkiä.',
      );
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Salasanat eivät ole samat.');
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
      _showMessage(_firebaseError(e.code));
    } catch (_) {
      _showMessage('Tilin luominen epäonnistui.');
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_add_alt_1,
                      size: 65,
                      color: Color(0xFF35D0A0),
                    ),

                    const SizedBox(height: 18),

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
                      keyboardType:
                          TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Sähköposti',
                        prefixIcon:
                            Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: passwordController,
                      obscureText: !showPassword,
                      decoration: InputDecoration(
                        labelText: 'Salasana',
                        prefixIcon:
                            const Icon(Icons.lock_outline),
                        border:
                            const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              showPassword =
                                  !showPassword;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller:
                          confirmPasswordController,
                      obscureText: !showPassword,
                      decoration: const InputDecoration(
                        labelText: 'Vahvista salasana',
                        prefixIcon:
                            Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 26),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed:
                            loading ? null : _register,
                        icon: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.person_add,
                              ),
                        label: Text(
                          loading
                              ? 'LUODAAN TILIÄ...'
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
// FORGOT PASSWORD PAGE
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

  Future<void> _resetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showMessage('Anna sähköpostiosoitteesi.');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(
        email: email,
      );

      _showMessage(
        'Salasanan palautusviesti lähetettiin sähköpostiisi.',
      );
    } on FirebaseAuthException catch (e) {
      _showMessage('Virhe: ${e.code}');
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PALAUTA SALASANA'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 30),

            const Icon(
              Icons.lock_reset,
              size: 70,
              color: Color(0xFF35D0A0),
            ),

            const SizedBox(height: 20),

            const Text(
              'Anna sähköpostiosoitteesi, niin lähetämme salasanan palautuslinkin.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            TextField(
              controller: emailController,
              keyboardType:
                  TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Sähköposti',
                prefixIcon:
                    Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed:
                    loading ? null : _resetPassword,
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
    );
  }
}

// ==========================================================
// HOME PAGE
// ==========================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() =>
      _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String stlKey = 'stl_balance';

  int stl = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  // ========================================================
  // LOAD BALANCE
  // ========================================================

  Future<void> _loadBalance() async {
    final prefs =
        await SharedPreferences.getInstance();

    final savedBalance =
        prefs.getInt(stlKey) ?? 0;

    if (!mounted) return;

    setState(() {
      stl = savedBalance;
      loading = false;
    });
  }

  // ========================================================
  // LOGOUT
  // ========================================================

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  // ========================================================
  // BUILD
  // ========================================================

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'STELLURIINI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
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

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // STELLA
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    ClipOval(
                      child: Image.asset(
                        'stella.jpg',
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) {
                          return const CircleAvatar(
                            radius: 60,
                            child: Icon(
                              Icons.pets,
                              size: 60,
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      '🐱 STELLURIINI',
                      style: TextStyle(
                        fontSize: 27,
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

            const SizedBox(height: 16),

            // BALANCE
            Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    const Text(
                      'SALDOSI',
                      style: TextStyle(
                        color: Colors.white60,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      '$stl',
                      style: const TextStyle(
                        fontSize: 55,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF35D0A0),
                      ),
                    ),

                    const Text(
                      'STL',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // INFO
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 35,
                      color: Color(0xFF35D0A0),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'STELLURIINI',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Tervetuloa Stelluriini-sovellukseen! 🐱',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}