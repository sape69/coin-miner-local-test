import 'package:flutter/material.dart';

import '../main.dart';

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