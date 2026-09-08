import 'package:flutter/material.dart';

class WhitePaperParagraph extends StatelessWidget {
  final String text;

  const WhitePaperParagraph({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
        height: 1.65,
      ),
    );
  }
}