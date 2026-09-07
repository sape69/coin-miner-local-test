import 'package:flutter/material.dart';

import '../../data/cat_facts.dart';
import '../../localization.dart';
import 'cat_fact_card.dart';

class DailyCatFactSection extends StatelessWidget {
  final String languageCode;

  const DailyCatFactSection({
    super.key,
    required this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations localization =
        AppLocalizations(languageCode);

    final String fact = CatFacts.getDailyFact(
      languageCode: languageCode,
    );

    return CatFactCard(
      title: '🐱 ${localization.get(
        'stellaFacts',
      )}',
      fact: fact,
    );
  }
}