import 'package:flutter/material.dart';

class StelluriiniLogo extends StatelessWidget {
  final double size;

  const StelluriiniLogo({
    super.key,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset(
          'assets/images/stelluriini_logo.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}