import 'package:flutter/material.dart';

class TextInputTestPage extends StatefulWidget {
  const TextInputTestPage({
    super.key,
  });

  @override
  State<TextInputTestPage> createState() =>
      _TextInputTestPageState();
}

class _TextInputTestPageState
    extends State<TextInputTestPage> {
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF120B24),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF120B24),
        foregroundColor:
            const Color(0xFFF8F4FF),
        title: const Text(
          'Text Input Test',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                height: 30,
              ),

              const Icon(
                Icons.edit,
                size: 70,
                color: Color(0xFFB58CFF),
              ),

              const SizedBox(
                height: 24,
              ),

              const Text(
                'Tekstikenttien testi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFF8F4FF),
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              const Text(
                'Testaa, toimivatko tekstikentät tällä laitteella.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFBDB4D1),
                  fontSize: 16,
                ),
              ),

              const SizedBox(
                height: 40,
              ),

              TextField(
                controller: emailController,
                keyboardType:
                    TextInputType.emailAddress,
                textInputAction:
                    TextInputAction.next,
                cursorColor:
                    const Color(0xFFB58CFF),
                style: const TextStyle(
                  color: Color(0xFFF8F4FF),
                  fontSize: 16,
                ),
                decoration:
                    InputDecoration(
                  labelText: 'Sähköposti',
                  labelStyle:
                      const TextStyle(
                    color: Color(0xFFBDB4D1),
                  ),
                  hintText:
                      'kirjoita tähän',
                  hintStyle:
                      const TextStyle(
                    color: Color(0xFF766B89),
                  ),
                  filled: true,
                  fillColor:
                      const Color(0xFF18102D),
                  prefixIcon:
                      const Icon(
                    Icons.email_outlined,
                    color: Color(0xFFB58CFF),
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                    borderSide:
                        const BorderSide(
                      color: Color(0xFF352653),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                    borderSide:
                        const BorderSide(
                      color: Color(0xFFB58CFF),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              TextField(
                controller:
                    passwordController,
                obscureText: true,
                textInputAction:
                    TextInputAction.done,
                cursorColor:
                    const Color(0xFFB58CFF),
                style: const TextStyle(
                  color: Color(0xFFF8F4FF),
                  fontSize: 16,
                ),
                decoration:
                    InputDecoration(
                  labelText: 'Salasana',
                  labelStyle:
                      const TextStyle(
                    color: Color(0xFFBDB4D1),
                  ),
                  hintText:
                      'kirjoita tähän',
                  hintStyle:
                      const TextStyle(
                    color: Color(0xFF766B89),
                  ),
                  filled: true,
                  fillColor:
                      const Color(0xFF18102D),
                  prefixIcon:
                      const Icon(
                    Icons.lock_outline,
                    color: Color(0xFFB58CFF),
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                    borderSide:
                        const BorderSide(
                      color: Color(0xFF352653),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                    borderSide:
                        const BorderSide(
                      color: Color(0xFFB58CFF),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 32,
              ),

              ElevatedButton(
                onPressed: () {
                  FocusScope.of(context)
                      .unfocus();

                  final email =
                      emailController.text;

                  final password =
                      passwordController.text;

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Sähköposti: $email\n'
                        'Salasana: '
                        '${password.isEmpty ? "(tyhjä)" : "syötetty"}',
                      ),
                    ),
                  );
                },
                child: const Text(
                  'TESTAA KENTÄT',
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              const Text(
                'Jos pystyt kirjoittamaan molempiin kenttiin, '
                'itse Flutterin tekstinsyöttö toimii laitteella.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFBDB4D1),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}