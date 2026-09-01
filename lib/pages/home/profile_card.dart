import 'package:flutter/material.dart';

import '../../widgets/cat_avatar.dart';

class ProfileCard extends StatelessWidget {
  final String title;

  const ProfileCard({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CatAvatar(
              size: 110,
            ),

            const SizedBox(height: 12),

            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}