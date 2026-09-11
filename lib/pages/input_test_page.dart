import 'package:flutter/material.dart';

class InputTestPage extends StatefulWidget {
  const InputTestPage({
    super.key,
  });

  @override
  State<InputTestPage> createState() =>
      _InputTestPageState();
}

class _InputTestPageState
    extends State<InputTestPage> {
  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF120B24),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                height: 40,
              ),

              const Text(
                'STELLURIINI TEST',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color:
                      Color(0xFFF8F4FF),
                  fontSize: 28,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 40,
              ),

              Container(
                padding:
                    const EdgeInsets.all(20),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFF21113B),
                  borderRadius:
                      BorderRadius.circular(24),
                  border:
                      Border.all(
                    color:
                        const Color(0xFFB58CFF),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Tekstikenttätesti',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color:
                            Color(0xFFF8F4FF),
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    TextField(
                      controller:
                          _emailController,
                      keyboardType:
                          TextInputType.emailAddress,
                      style:
                          const TextStyle(
                        color:
                            Color(0xFFF8F4FF),
                        fontSize: 18,
                      ),
                      cursorColor:
                          const Color(
                        0xFFB58CFF,
                      ),
                      decoration:
                          InputDecoration(
                        hintText:
                            'Kirjoita tähän',
                        hintStyle:
                            const TextStyle(
                          color:
                              Color(0xFF766B89),
                        ),
                        filled: true,
                        fillColor:
                            const Color(
                          0xFF18102D,
                        ),
                        prefixIcon:
                            const Icon(
                          Icons.email_outlined,
                          color:
                              Color(0xFFB58CFF),
                        ),
                        enabledBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
                          borderSide:
                              const BorderSide(
                            color:
                                Color(
                              0xFF352653,
                            ),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
                          borderSide:
                              const BorderSide(
                            color:
                                Color(
                              0xFFB58CFF,
                            ),
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    TextField(
                      controller:
                          _passwordController,
                      obscureText:
                          _obscurePassword,
                      style:
                          const TextStyle(
                        color:
                            Color(0xFFF8F4FF),
                        fontSize: 18,
                      ),
                      cursorColor:
                          const Color(
                        0xFFB58CFF,
                      ),
                      decoration:
                          InputDecoration(
                        hintText:
                            'Salasana',
                        hintStyle:
                            const TextStyle(
                          color:
                              Color(0xFF766B89),
                        ),
                        filled: true,
                        fillColor:
                            const Color(
                          0xFF18102D,
                        ),
                        prefixIcon:
                            const Icon(
                          Icons.lock_outline,
                          color:
                              Color(0xFFB58CFF),
                        ),
                        suffixIcon:
                            IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword =
                                  !_obscurePassword;
                            });
                          },
                          icon:
                              Icon(
                            _obscurePassword
                                ? Icons
                                    .visibility_outlined
                                : Icons
                                    .visibility_off_outlined,
                            color:
                                const Color(
                              0xFFB58CFF,
                            ),
                          ),
                        ),
                        enabledBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
                          borderSide:
                              const BorderSide(
                            color:
                                Color(
                              0xFF352653,
                            ),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
                          borderSide:
                              const BorderSide(
                            color:
                                Color(
                              0xFFB58CFF,
                            ),
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    ElevatedButton(
                      onPressed: () {
                        FocusScope.of(
                          context,
                        ).unfocus();
                      },
                      child: const Text(
                        'TESTAA KENTÄT',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}