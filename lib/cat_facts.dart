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

// 365 kissafaktaa – yksi vuoden jokaiselle päivälle.
const List<CatFact> catFacts = [
  CatFact({
    'fi': 'Kissat nukkuvat usein noin 12–16 tuntia vuorokaudessa.',
    'en': 'Cats often sleep around 12–16 hours a day.',
  }),
  CatFact({
    'fi': 'Kissan viikset ovat erittäin herkkiä tuntoelimiä.',
    'en': 'A cat’s whiskers are highly sensitive sensory organs.',
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
    'fi': 'Kissan kynnet ovat useimmiten sisäänvedettävät.',
    'en': 'A cat’s claws are usually retractable.',
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
  CatFact({
    'fi': 'Kissat käyttävät hajuaistiaan tutkiessaan ympäristöään.',
    'en': 'Cats use their sense of smell to explore their surroundings.',
  }),
  CatFact({
    'fi': 'Kissan kielessä on pieniä, taaksepäin suuntautuvia papilleja.',
    'en': 'A cat’s tongue has tiny backward-facing papillae.',
  }),
  CatFact({
    'fi': 'Kissat pesevät itseään paljon pitääkseen turkkinsa puhtaana.',
    'en': 'Cats groom themselves frequently to keep their fur clean.',
  }),
  CatFact({
    'fi': 'Kissan pupillit voivat muuttua hyvin kapeiksi tai suuriksi.',
    'en': 'A cat’s pupils can become very narrow or very large.',
  }),
  CatFact({
    'fi': 'Kissat ovat yleensä aktiivisimmillaan aamun ja illan hämärässä.',
    'en': 'Cats are generally most active around dawn and dusk.',
  }),
  CatFact({
    'fi': 'Kissat voivat hypätä monta kertaa oman pituutensa verran.',
    'en': 'Cats can jump several times their own body length.',
  }),
  CatFact({
    'fi': 'Kissan häntä voi kertoa paljon sen mielialasta.',
    'en': 'A cat’s tail can communicate a lot about its mood.',
  }),
  CatFact({
    'fi': 'Kissat käyttävät tassujensa pehmeitä anturoita hiljaiseen liikkumiseen.',
    'en': 'Cats use the soft pads of their paws for quiet movement.',
  }),
  CatFact({
    'fi': 'Kissan kehräys voi tuntua matalana värinänä.',
    'en': 'A cat’s purr can feel like a low vibration.',
  }),
  CatFact({
    'fi': 'Kissat oppivat tunnistamaan tuttuja ääniä.',
    'en': 'Cats can learn to recognize familiar sounds.',
  }),
  CatFact({
    'fi': 'Kissan hajuaisti on paljon ihmisen hajuaistia vahvempi.',
    'en': 'A cat’s sense of smell is much stronger than a human’s.',
  }),
  CatFact({
    'fi': 'Kissat voivat ilmaista itseään monilla erilaisilla äänillä.',
    'en': 'Cats can communicate using many different sounds.',
  }),
  CatFact({
    'fi': 'Aikuinen kissa maukuu usein ihmisille enemmän kuin toisille kissoille.',
    'en': 'Adult cats often meow to humans more than to other cats.',
  }),
  CatFact({
    'fi': 'Kissat voivat käyttää viiksiään arvioidakseen kapeita tiloja.',
    'en': 'Cats can use their whiskers to judge narrow spaces.',
  }),
  CatFact({
    'fi': 'Kissan etutassuissa on yleensä viisi varvasta.',
    'en': 'A cat usually has five toes on each front paw.',
  }),
  CatFact({
    'fi': 'Kissan takatassuissa on yleensä neljä varvasta.',
    'en': 'A cat usually has four toes on each back paw.',
  }),
  CatFact({
    'fi': 'Joillakin kissoilla on tavallista enemmän varpaita.',
    'en': 'Some cats have more toes than usual.',
  }),
  CatFact({
    'fi': 'Kissat voivat nähdä hämärässä paremmin kuin ihmiset.',
    'en': 'Cats can see better than humans in dim light.',
  }),
  CatFact({
    'fi': 'Kissat eivät kuitenkaan näe täydellisessä pimeydessä.',
    'en': 'Cats still cannot see in complete darkness.',
  }),
  CatFact({
    'fi': 'Kissan silmät ovat suuret suhteessa sen pään kokoon.',
    'en': 'A cat’s eyes are large relative to the size of its head.',
  }),
  CatFact({
    'fi': 'Kissat reagoivat usein nopeasti liikkuviin kohteisiin.',
    'en': 'Cats often react quickly to moving objects.',
  }),
  CatFact({
    'fi': 'Kissan korvat voivat kääntyä äänen suuntaan.',
    'en': 'A cat’s ears can rotate toward a sound.',
  }),
  CatFact({
    'fi': 'Kissat voivat oppia päivittäisiä rutiineja hyvin nopeasti.',
    'en': 'Cats can learn daily routines very quickly.',
  }),
  CatFact({
    'fi': 'Monet kissat pitävät lämpimistä nukkumapaikoista.',
    'en': 'Many cats enjoy warm places to sleep.',
  }),
  CatFact({
    'fi': 'Kissat etsivät usein korkeita paikkoja tarkkaillakseen ympäristöään.',
    'en': 'Cats often seek high places to observe their surroundings.',
  }),
  CatFact({
    'fi': 'Raapiminen auttaa kissaa hoitamaan kynsiään.',
    'en': 'Scratching helps a cat maintain its claws.',
  }),
  CatFact({
    'fi': 'Raapiminen voi myös olla tapa merkitä aluetta.',
    'en': 'Scratching can also be a way to mark territory.',
  }),
  CatFact({
    'fi': 'Kissan tassuissa on tuoksurauhasia.',
    'en': 'Cats have scent glands in their paws.',
  }),
  CatFact({
    'fi': 'Kissat voivat hieroa päätään ihmistä vasten jättääkseen tuttua tuoksua.',
    'en': 'Cats may rub their heads against people to leave a familiar scent.',
  }),
  CatFact({
    'fi': 'Kissan kehon kieli on tärkeä osa sen viestintää.',
    'en': 'A cat’s body language is an important part of its communication.',
  }),
  CatFact({
    'fi': 'Kissat venyttelevät usein levon jälkeen.',
    'en': 'Cats often stretch after resting.',
  }),
  CatFact({
    'fi': 'Kissan turkki auttaa säätelemään sen ruumiinlämpöä.',
    'en': 'A cat’s fur helps regulate its body temperature.',
  }),
  CatFact({
    'fi': 'Kissat voivat vaihtaa turkkiaan vuodenaikojen mukaan.',
    'en': 'Cats can shed and renew their coats with the seasons.',
  }),
  CatFact({
    'fi': 'Säännöllinen harjaus voi vähentää irtokarvoja.',
    'en': 'Regular brushing can reduce loose fur.',
  }),
  CatFact({
    'fi': 'Kissat ovat erittäin taitavia tasapainoilijoita.',
    'en': 'Cats are highly skilled at balancing.',
  }),
  CatFact({
    'fi': 'Kissan sisäkorva auttaa tasapainon ylläpitämisessä.',
    'en': 'A cat’s inner ear helps maintain balance.',
  }),
  CatFact({
    'fi': 'Kissat voivat kääntää vartaloaan ilmassa laskeutuakseen paremmin.',
    'en': 'Cats can twist their bodies in the air to improve landing.',
  }),
  CatFact({
    'fi': 'Kissan refleksit ovat yleensä erittäin nopeat.',
    'en': 'A cat’s reflexes are generally very fast.',
  }),
  CatFact({
    'fi': 'Leikki auttaa kissaa harjoittamaan metsästyskäyttäytymistä.',
    'en': 'Play helps a cat practice hunting behavior.',
  }),
  CatFact({
    'fi': 'Monet kissat pitävät leluista, jotka liikkuvat kuin pieni saalis.',
    'en': 'Many cats enjoy toys that move like small prey.',
  }),
  CatFact({
    'fi': 'Kissat voivat kyllästyä, jos ympäristössä ei ole tarpeeksi virikkeitä.',
    'en': 'Cats can become bored if their environment lacks enough stimulation.',
  }),
  CatFact({
    'fi': 'Raapimapuu voi tarjota kissalle liikuntaa ja virikkeitä.',
    'en': 'A scratching tree can provide exercise and enrichment for a cat.',
  }),
];