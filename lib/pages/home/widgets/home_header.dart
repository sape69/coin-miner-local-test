import 'package:flutter/material.dart';

import '../../../widgets/stelluriini_logo.dart';

class HomeHeader extends StatelessWidget {
  final Color primaryTextColor;

  const HomeHeader({
    super.key,
    required this.primaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Row(
        children: [
          Builder(
            builder: (context) {
              return IconButton(
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                icon: Icon(
                  Icons.menu_rounded,
                  color: primaryTextColor,
                  size: 30,
                ),
                tooltip: 'Menu',
              );
            },
          ),

          const SizedBox(width: 8),

          const Expanded(
            child: Center(
              child: StelluriiniLogo(
                size: 48,
              ),
            ),
          ),

          const SizedBox(width: 54),
        ],
      ),
    );
  }
}