import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (passwordController.text != confirmController.text) {
      _message('Salasanat eivät ole samat.');
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _message('Virhe: ${e.code}');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LUO TILI')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Sähköposti',
              ),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Salasana',
              ),
            ),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Vahvista salasana',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: loading ? null : _register,
              child: Text(
                loading ? 'LUODAAN...' : 'LUO TILI',
              ),
            ),
          ],
        ),
      ),
    );
  }
}