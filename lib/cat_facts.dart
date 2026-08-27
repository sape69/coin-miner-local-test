class CatFact {
  final Map<String, String> translations;

  const CatFact(this.translations);

  String text(String languageCode) {
    return translations[languageCode] ??
        translations['en'] ??
        translations['fi'] ??
        '';
  }
}

const List<CatFact> catFacts = [
  CatFact({
    'fi': 'Kissat nukkuvat usein noin 12–16 tuntia vuorokaudessa.',
    'en': 'Cats often sleep around 12–16 hours a day.',
  }),
  CatFact({
    'fi': 'Kissan viikset ovat erittäin herkkiä tuntoelimiä.',
    'en': 'A cat’s whiskers are very sensitive sensory organs.',
  }),
  CatFact({
    'fi': 'Kissan nenän kuvio on yksilöllinen.',
    'en': 'Every cat has a unique nose pattern.',
  }),
  CatFact({
    'fi': 'Kissat voivat kuulla erittäin korkeita ääniä.',
    'en': 'Cats can hear very high-frequency sounds.',
  }),
  CatFact({
    'fi': 'Kissan kynnet ovat sisäänvedettävät.',
    'en': 'Cats have retractable claws.',
  }),
  CatFact({
    'fi': 'Kissat käyttävät häntäänsä tasapainon apuna.',
    'en': 'Cats use their tails to help with balance.',
  }),
  CatFact({
    'fi': 'Hidas silmien räpytys voi olla kissan ystävällinen tervehdys.',
    'en': 'A slow blink can be a friendly greeting from a cat.',
  }),
  CatFact({
    'fi': 'Kissat ovat luonnostaan uteliaita eläimiä.',
    'en': 'Cats are naturally curious animals.',
  }),
];