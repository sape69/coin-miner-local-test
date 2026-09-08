import 'package:flutter/material.dart';

import '../../localization.dart';
import '../../widgets/cat_avatar.dart';
import '../../widgets/stelluriini_logo.dart';

const Color aboutBackgroundColor = Color(0xFF120B24);
const Color aboutCardColor = Color(0xFF21113B);
const Color aboutAccentColor = Color(0xFFB58CFF);
const Color aboutPinkColor = Color(0xFFFFB7E8);
const Color aboutGoldColor = Color(0xFFFFD166);

class AboutPage extends StatelessWidget {
  const AboutPage({
    super.key,
  });

  String _text(
    BuildContext context,
    String key, {
    String fallback = '',
  }) {
    final value = AppLocalizations.of(context).get(key);

    if (value.isEmpty || value == key) {
      return fallback;
    }

    return value;
  }

  @override
  Widget build(BuildContext context) {
    final aboutTitle = _text(
      context,
      'aboutStelluriini',
      fallback: 'About Stelluriini',
    );

    final welcomeTitle = _text(
      context,
      'aboutWelcome',
      fallback: 'Welcome to Stelluriini',
    );

    final welcomeDescription = _text(
      context,
      'aboutWelcomeDescription',
      fallback:
          'A community-driven project inspired by a curious cat named Stella.',
    );

    final aboutDescription = _text(
      context,
      'aboutDescription',
      fallback:
          'Stelluriini is a community-driven project built around Stella, '
          'a curious cat with a big personality. The project combines a '
          'playful cat theme with the Solana ecosystem and the STL token.',
    );

    final meetStella = _text(
      context,
      'meetStella',
      fallback: 'Meet Stella',
    );

    final stellaIntro = _text(
      context,
      'aboutStellaIntro',
      fallback: '🐱 Stella is the heart of Stelluriini.',
    );

    final stellaDescription = _text(
      context,
      'aboutStellaDescription',
      fallback:
          'She represents curiosity, community and the fun side of the '
          'project. Stella accompanies you through the app while you mine, '
          'collect rewards and explore the Stelluriini ecosystem.',
    );

    final community = _text(
      context,
      'community',
      fallback: 'Community',
    );

    final communityDescription = _text(
      context,
      'aboutCommunityDescription',
      fallback:
          'Stelluriini is designed to grow together with its community. '
          'The goal is to create an enjoyable ecosystem where the community '
          'can participate, share ideas and help shape the future of STL.',
    );

    final builtOnSolana = _text(
      context,
      'builtOnSolana',
      fallback: 'Built on Solana',
    );

    final solanaDescription = _text(
      context,
      'aboutSolanaDescription',
      fallback:
          'Stelluriini is built around the Solana ecosystem. Solana provides '
          'the blockchain foundation for the STL token and future '
          'Stelluriini ecosystem features.',
    );

    final stlToken = _text(
      context,
      'stlToken',
      fallback: 'Stelluriini Token',
    );

    final importantInformation = _text(
      context,
      'importantInformation',
      fallback: 'Important Information',
    );

    final importantDescription = _text(
      context,
      'aboutImportantDescription',
      fallback:
          'STL shown inside this application currently represents virtual '
          'in-app points. The balance shown in the app is not automatically '
          'a withdrawable cryptocurrency balance.',
    );

    final footerTagline = _text(
      context,
      'footerTagline',
      fallback:
          'Stella is watching over the Stelluriini community',
    );

    return Scaffold(
      backgroundColor: aboutBackgroundColor,
      appBar: AppBar(
        backgroundColor: aboutBackgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          aboutTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            32,
          ),
          children: [
            // ==================================================
            // STELLA HEADER
            // ==================================================

            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF21113B),
                    Color(0xFF2A1648),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: aboutAccentColor.withValues(
                    alpha: 0.35,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: aboutAccentColor.withValues(
                      alpha: 0.12,
                    ),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  28,
                  24,
                  26,
                ),
                child: Column(
                  children: [
                    const CatAvatar(
                      size: 120,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'STELLURIINI',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                        color: aboutPinkColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: aboutAccentColor.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: aboutAccentColor.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: const Text(
                        '🐾 STL • SOLANA 🐾',
                        style: TextStyle(
                          color: aboutAccentColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      welcomeTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      welcomeDescription,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // ABOUT STELLURIINI
            // ==================================================

            _AboutCard(
              icon: Icons.pets_rounded,
              title: aboutTitle,
              accentColor: aboutAccentColor,
              child: Text(
                aboutDescription,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // STELLA
            // ==================================================

            _AboutCard(
              icon: Icons.favorite_rounded,
              title: meetStella,
              accentColor: aboutPinkColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stellaIntro,
                    style: const TextStyle(
                      color: aboutPinkColor,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    stellaDescription,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // COMMUNITY
            // ==================================================

            _AboutCard(
              icon: Icons.groups_rounded,
              title: community,
              accentColor: aboutAccentColor,
              child: Text(
                communityDescription,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // SOLANA
            // ==================================================

            _AboutCard(
              icon: Icons.bolt_rounded,
              title: builtOnSolana,
              accentColor: aboutGoldColor,
              child: Text(
                solanaDescription,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // STL TOKEN
            // ==================================================

            Container(
              decoration: BoxDecoration(
                color: aboutCardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: aboutPinkColor.withValues(
                    alpha: 0.22,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const StelluriiniLogo(
                      size: 70,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'STL',
                      style: TextStyle(
                        color: aboutPinkColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stlToken,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '17 602 539 062 STL',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: aboutGoldColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Solana • Community-driven',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // IMPORTANT INFORMATION
            // ==================================================

            _AboutCard(
              icon: Icons.info_outline_rounded,
              title: importantInformation,
              accentColor: aboutGoldColor,
              child: Text(
                importantDescription,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // STELLA FOOTER
            // ==================================================

            Text(
              '🐾 $footerTagline 🐾',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: aboutPinkColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'STELLURIINI • STL • SOLANA',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// REUSABLE ABOUT CARD
// ============================================================

class _AboutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accentColor;
  final Widget child;

  const _AboutCard({
    required this.icon,
    required this.title,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: aboutCardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(
                      alpha: 0.12,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}