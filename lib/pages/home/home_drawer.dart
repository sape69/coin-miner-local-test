import 'package:flutter/material.dart';

import '../../widgets/cat_avatar.dart';

const Color backgroundColor = Color(0xFF0B1112);
const Color cardColor = Color(0xFF151B1C);
const Color accentColor = Color(0xFF35D0A0);

class HomeDrawer extends StatelessWidget {
  final VoidCallback onLanguagePressed;
  final VoidCallback onAboutPressed;
  final VoidCallback onWhitePaperPressed;
  final VoidCallback onTokenPressed;
  final VoidCallback onRoadmapPressed;

  const HomeDrawer({
    super.key,
    required this.onLanguagePressed,
    required this.onAboutPressed,
    required this.onWhitePaperPressed,
    required this.onTokenPressed,
    required this.onRoadmapPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 28,
              ),
              decoration: const BoxDecoration(
                color: cardColor,
              ),
              child: const Column(
                children: [
                  CatAvatar(
                    size: 85,
                  ),
                  SizedBox(height: 14),
                  Text(
                    'STELLURIINI',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: accentColor,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'STL • Solana',
                    style: TextStyle(
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // HOME
            // ==================================================

            ListTile(
              leading: const Icon(
                Icons.home_outlined,
                color: accentColor,
              ),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            // ==================================================
            // ABOUT STELLURIINI
            // ==================================================

            ListTile(
              leading: const Icon(
                Icons.pets_outlined,
                color: accentColor,
              ),
              title: const Text(
                'About Stelluriini',
              ),
              onTap: () {
                Navigator.pop(context);
                onAboutPressed();
              },
            ),

            // ==================================================
            // WHITE PAPER
            // ==================================================

            ListTile(
              leading: const Icon(
                Icons.description_outlined,
                color: accentColor,
              ),
              title: const Text(
                'White Paper',
              ),
              trailing: const Text(
                'SOON',
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onWhitePaperPressed();
              },
            ),

            // ==================================================
            // STL TOKEN
            // ==================================================

            ListTile(
              leading: const Icon(
                Icons.monetization_on_outlined,
                color: accentColor,
              ),
              title: const Text(
                'STL Token',
              ),
              onTap: () {
                Navigator.pop(context);
                onTokenPressed();
              },
            ),

            // ==================================================
            // ROADMAP
            // ==================================================

            ListTile(
              leading: const Icon(
                Icons.map_outlined,
                color: accentColor,
              ),
              title: const Text(
                'Roadmap',
              ),
              trailing: const Text(
                'SOON',
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onRoadmapPressed();
              },
            ),

            const Spacer(),

            const Divider(
              color: Colors.white24,
            ),

            // ==================================================
            // LANGUAGE
            // ==================================================

            ListTile(
              leading: const Icon(
                Icons.language,
                color: accentColor,
              ),
              title: const Text(
                'Language',
              ),
              onTap: () {
                Navigator.pop(context);
                onLanguagePressed();
              },
            ),

            // ==================================================
            // FOOTER
            // ==================================================

            const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'STELLURIINI • STL',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Community-driven • Solana',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
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
}