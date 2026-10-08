// ============================================================
// 🐱 STELLURIINI - CAT FACTS
// ============================================================
//
// 150 päivittäistä kissafaktaa / kieli.
//
// Tuetut kielet:
// 🇫🇮 Finnish
// 🇬🇧 English
// 🇩🇪 German
// 🇪🇸 Spanish
// 🇫🇷 French
// 🇨🇳 Chinese
// 🇻🇳 Vietnamese
// 🇯🇵 Japanese
//
// Faktat on jaettu eri aiheisiin:
// - aistit
// - näkö ja kuulo
// - keho ja liikkuminen
// - uni ja lepo
// - leikki ja saalistuskäyttäytyminen
// - raapiminen ja hoitaminen
// - viestintä
// - oppiminen ja muisti
// - sosiaalinen käyttäytyminen
// - ympäristö
// - ravinto
// - Stella-teemaiset faktat
//
// Päivittäinen fakta valitaan deterministisesti päivän perusteella.
// ============================================================

class CatFacts {
  // ============================================================
  // 🇫🇮 FINNISH
  // ============================================================

  static const List<String> fi = [
    'Kissan viikset ovat tärkeitä tuntoaistille.',
    'Viiksien tyvessä on runsaasti hermopäätteitä.',
    'Kissa voi käyttää viiksiään ympäröivän ilman liikkeiden havaitsemiseen.',
    'Viikset auttavat kissaa arvioimaan ympäristöään lähietäisyydeltä.',
    'Kissan nenä on erittäin tärkeä osa sen ympäristön tutkimista.',
    'Kissoilla on ihmiselle paljon herkempi hajuaisti.',
    'Kissa käyttää hajua tuttujen paikkojen tunnistamiseen.',
    'Kissa voi jättää hajumerkkejä poskien ja pään alueelta.',
    'Kissan hajuaisti auttaa sitä tutkimaan uusia esineitä.',
    'Kissalla on vomeronasaalielin, joka liittyy kemiallisten hajujen tutkimiseen.',
    'Kissan kuulo on hyvin kehittynyt.',
    'Kissan korvalehdet voivat kääntyä kohti kiinnostavaa ääntä.',
    'Kissan korvat voivat suunnata eri suuntiin.',
    'Kissa pystyy havaitsemaan pieniä ääniä ympäristöstään.',
    'Kissan kuulo auttaa sitä paikantamaan äänen lähteen.',
    'Kissa näkee hämärässä paremmin kuin ihminen.',
    'Kissa ei kuitenkaan näe täydellisessä pimeydessä.',
    'Kissan silmien pupillit muuttuvat valaistuksen mukaan.',
    'Kirkkaassa valossa kissan pupillit voivat muuttua kapeiksi.',
    'Kissan silmien verkkokalvo auttaa sitä havaitsemaan liikettä.',
    'Kissan silmät voivat heijastaa valoa pimeässä.',
    'Kissan silmien heijastus liittyy verkkokalvon takana olevaan tapetum lucidumiin.',
    'Liikkuva kohde voi kiinnittää kissan huomion nopeasti.',
    'Kissa käyttää näköä, kuuloa ja hajuaistia yhdessä.',
    'Kissan tassunpohjissa on tuntoaistia välittäviä hermopäätteitä.',
    'Tassut auttavat kissaa tutkimaan erilaisia pintoja.',
    'Kissan kynnet ovat yleensä sisäänvedettävät.',
    'Kynnet auttavat kissaa tarttumaan ja kiipeämään.',
    'Takajalat antavat kissalle paljon voimaa hyppyihin.',
    'Kissan selkäranka on joustava.',
    'Joustava vartalo auttaa kissaa muuttamaan liikesuuntaa nopeasti.',
    'Kissa voi venytellä herättyään.',
    'Venytteleminen auttaa kissaa valmistautumaan liikkumiseen.',
    'Kissan karkea kieli auttaa turkin hoidossa.',
    'Kissan kielessä on pieniä keratiinisia nystyjä.',
    'Turkin nuoleminen auttaa poistamaan irtolikaa.',
    'Turkin hoitaminen on tärkeä osa kissan normaalia käyttäytymistä.',
    'Kissa voi käyttää tassujaan esineiden tutkimiseen.',
    'Kissa voi koskettaa uutta esinettä ensin varovasti tassullaan.',
    'Kissa nukkuu ja lepää suuren osan vuorokaudesta.',
    'Kissan uni koostuu erilaisista unen vaiheista.',
    'Kissa voi torkahtaa paikassa, josta se pystyy tarkkailemaan ympäristöä.',
    'Lämmin paikka voi olla kissalle houkutteleva lepopaikka.',
    'Korkea paikka voi tarjota kissalle hyvän näkymän ympäristöön.',
    'Turvallinen piilopaikka voi auttaa kissaa rentoutumaan.',
    'Pahvilaatikko voi toimia kissalle kiinnostavana tutkimuspaikkana.',
    'Kissa voi vaihtaa lepopaikkaa päivän aikana.',
    'Kissa voi valita lepopaikan lämpötilan mukaan.',
    'Kissa voi valita lepopaikan rauhallisuuden perusteella.',
    'Kissan aktiivisuus vaihtelee vuorokauden aikana.',
    'Kissat eivät ole pelkästään yöeläimiä.',
    'Monet kissat ovat aktiivisia erityisesti hämärän aikaan.',
    'Leikki voi jäljitellä saalistamiseen liittyviä liikkeitä.',
    'Kissa voi vaania lelua ennen sen kimppuun hyökkäämistä.',
    'Pieni nopeasti liikkuva lelu voi herättää kissan saalistusvietin.',
    'Kissa voi jahdata lelua ilman varsinaista nälkää.',
    'Arvaamaton lelun liike voi tehdä leikistä kiinnostavamman.',
    'Kissa voi harjoitella koordinaatiota leikkimällä.',
    'Hyppääminen on osa monien kissojen normaalia leikkikäyttäytymistä.',
    'Kissa voi pysähtyä kesken leikin tarkkailemaan ympäristöä.',
    'Kissa voi palata leluun hetken tauon jälkeen.',
    'Raapiminen on kissalle normaalia käyttäytymistä.',
    'Raapiminen auttaa kissaa venyttämään kehoaan.',
    'Raapiminen voi jättää sekä näkyvän että hajullisen merkin.',
    'Kissa voi pitää erilaisista raapimispinnoista.',
    'Pystysuora raapimispinta voi tarjota hyvän venytysmahdollisuuden.',
    'Vaakasuora raapimispinta voi kiinnostaa joitakin kissoja enemmän.',
    'Kissa voi käyttää samaa raapimispaikkaa toistuvasti.',
    'Kissan kehon kieli kertoo paljon sen tunnetilasta.',
    'Häntä on yksi kissan tärkeistä viestintävälineistä.',
    'Pystyssä oleva häntä voi liittyä ystävälliseen tervehtimiseen.',
    'Pörröinen häntä voi liittyä voimakkaaseen kiihtymykseen tai pelkoon.',
    'Korvien asento voi muuttua kissan tunnetilan mukaan.',
    'Taakse painuneet korvat voivat kertoa epämukavuudesta tai puolustautumisesta.',
    'Kissa voi viestiä silmien ja katseen avulla.',
    'Hidas silmien siristäminen voi liittyä rauhalliseen vuorovaikutukseen.',
    'Kissa voi kääntää katseensa pois rauhoittavana eleenä.',
    'Kissan kehon asento kertoo usein enemmän kuin yksi yksittäinen merkki.',
    'Kissa käyttää myös hajua viestiessään toisille kissoille.',
    'Kissa voi hieroa päätään tuttua ihmistä tai esinettä vasten.',
    'Poskien hierominen voi liittyä hajumerkkien jättämiseen.',
    'Kissa voi tervehtiä tuttua ihmistä tulemalla lähelle.',
    'Kissa voi osoittaa kiintymystä vain olemalla samassa huoneessa.',
    'Kaikki kissat eivät pidä sylissä olemisesta.',
    'Kissan yksilöllinen persoonallisuus vaikuttaa sen sosiaaliseen käyttäytymiseen.',
    'Jotkut kissat hakeutuvat mielellään ihmisen viereen lepäämään.',
    'Kissa voi seurata tuttua ihmistä huoneesta toiseen.',
    'Kissa voi käyttää kehräystä useissa erilaisissa tilanteissa.',
    'Kehräys ei aina tarkoita pelkästään onnellisuutta.',
    'Kissa voi kehrätä myös rauhoittaakseen itseään.',
    'Maukunta on erityisen tärkeä kissojen ja ihmisten välisessä viestinnässä.',
    'Kissa voi käyttää erilaista ääntä eri tilanteissa.',
    'Kissan kujerrus tai trillitys voi liittyä tervehtimiseen.',
    'Sihiseminen on usein varoitus tai merkki epämukavuudesta.',
    'Kissa voi murista, kun se haluaa pitää etäisyyttä.',
    'Kissa voi ilmaista kiinnostusta pienillä äänillä.',
    'Kissa voi oppia yhdistämään tietyn äänen tiettyyn tapahtumaan.',
    'Kissa voi oppia tunnistamaan tutun ihmisen äänen.',
    'Kissa voi oppia tunnistamaan tutun ihmisen askeleet.',
    'Kissa voi muistaa tutun reitin kodissaan.',
    'Kissa voi oppia rutiineja toistuvien tapahtumien avulla.',
    'Kissa voi ennakoida ruokailua tutun päivärutiinin perusteella.',
    'Kissat voivat oppia yksinkertaisia tehtäviä palkkioiden avulla.',
    'Kissan oppimiseen vaikuttaa sen yksilöllinen motivaatio.',
    'Kissa voi suhtautua uuteen esineeseen ensin varovaisesti.',
    'Kissa voi tutkia uuden esineen haistamalla sitä.',
    'Kissa voi tarkkailla uutta asiaa ennen kuin lähestyy sitä.',
    'Kissa voi vetäytyä turvalliseen paikkaan, jos jokin pelottaa.',
    'Kissa voi palata tutkimaan asiaa myöhemmin.',
    'Kissan ympäristön ennakoitavuus voi helpottaa sen arkea.',
    'Rauhallinen lähestyminen antaa kissalle mahdollisuuden päättää etäisyytensä.',
    'Kissa voi arvostaa mahdollisuutta poistua tilanteesta itse.',
    'Kissan ympäristössä kannattaa olla sekä avoimia että suojaisia paikkoja.',
    'Korkeat tasot voivat lisätä kissan mahdollisuuksia tarkkailla ympäristöä.',
    'Ikkunapaikka voi tarjota kissalle paljon katseltavaa.',
    'Turvallinen ikkuna voi toimia kissalle kiinnostavana tarkkailupaikkana.',
    'Erilaiset lelut tarjoavat erilaisia tapoja leikkiä.',
    'Ruokapulmat voivat tarjota kissalle tekemistä ja ongelmanratkaisua.',
    'Ruokailun etsiminen voi jäljitellä osaa luonnollisesta ravinnonhankinnasta.',
    'Kissa käyttää hajua myös ruoan tutkimiseen.',
    'Kissa ei pysty maistamaan makeaa samalla tavalla kuin ihminen.',
    'Kissat ovat ravitsemuksellisesti sopeutuneet eläinperäiseen ravintoon.',
    'Kissa käyttää kieltään myös juodessaan.',
    'Kissan juomistapa perustuu nopeisiin kielen liikkeisiin veden pinnalla.',
    'Kissa voi juoda mieluummin rauhallisesta paikasta.',
    'Kissa voi pitää juoma-astian sijainnin pysyvyydestä.',
    'Kissan käyttäytyminen voi vaihdella yksilöstä toiseen paljon.',
    'Kaksi kissaa voi pitää täysin erilaisista leluista.',
    'Kaksi kissaa voi käyttää erilaisia tapoja osoittaa kiintymystä.',
    'Kissan persoonallisuus kehittyy kokemusten ja perimän yhteisvaikutuksesta.',
    'Turvallinen ympäristö antaa kissalle mahdollisuuden tutkia omaan tahtiinsa.',
    'Kissa oppii ympäristöstään jatkuvasti aistien avulla.',
    'Kissan uteliaisuus näkyy usein tarkkailuna ja haisteluna.',
    'Kissa voi käyttää tuttua hajua turvallisuuden merkkinä.',
    'Tuttu ääni voi herättää kissan huomion.',
    'Tuttu ihminen voi olla kissalle tärkeä osa sen ympäristöä.',
    'Kissa voi osoittaa luottamusta rentoutumalla ihmisen lähellä.',
    'Rauhallinen koti tarjoaa kissalle mahdollisuuden levätä häiriöttä.',
    'Stella voi näyttää uteliaalta tutkiessaan uutta paikkaa.',
    'Stellan viikset auttavat sitä tutkimaan ympäristöä.',
    'Stella voi pitää lämpimästä lepopaikasta.',
    'Stella voi tarkkailla ympäristöä korkealta paikalta.',
    'Stella voi kiinnostua pienestä liikkuvasta lelusta.',
    'Stella voi käyttää raapimista venyttelyyn.',
    'Stella voi tunnistaa tutun äänen nopeasti.',
    'Stella voi osoittaa tyytyväisyyttä rentoutumalla lähellä.',
    'Stellan jokainen päivä voi sisältää uuden pienen tutkimusretken.',
    'Stelluriinissa Stella muistuttaa, että uteliaisuus on kissan supervoima.',
  ];

  // ============================================================
  // 🇬🇧 ENGLISH
  // ============================================================

  static const List<String> en = [
    'A cat’s whiskers are important sensory tools.',
    'Whisker roots contain many sensitive nerve endings.',
    'Cats can use their whiskers to detect nearby air movement.',
    'Whiskers help cats gather information about close surroundings.',
    'A cat’s nose is an important tool for exploring its environment.',
    'Cats have a much stronger sense of smell than humans.',
    'Cats use scent to recognize familiar places.',
    'Cats can leave scent information around their face and head.',
    'Smell helps a cat investigate unfamiliar objects.',
    'Cats have a vomeronasal organ involved in chemical scent detection.',
    'Cats have highly developed hearing.',
    'A cat can turn its ears toward an interesting sound.',
    'A cat’s ears can point in different directions.',
    'Cats can detect subtle sounds around them.',
    'Hearing helps cats locate the source of a sound.',
    'Cats can see better in dim light than humans.',
    'Cats cannot see in complete darkness.',
    'A cat’s pupils change according to the amount of light.',
    'In bright light, a cat’s pupils can become very narrow.',
    'A cat’s eyes are well suited to detecting movement.',
    'A cat’s eyes can appear to shine in darkness.',
    'This eye shine is related to a structure called the tapetum lucidum.',
    'Moving objects can quickly attract a cat’s attention.',
    'Cats combine sight, hearing, and smell when exploring.',
    'Cat paw pads contain sensory nerve endings.',
    'Paws help cats investigate different surfaces.',
    'A cat’s claws are normally retractable.',
    'Claws help cats grip surfaces and climb.',
    'A cat’s hind legs provide powerful jumping strength.',
    'A cat’s spine is highly flexible.',
    'A flexible body helps a cat change direction quickly.',
    'Cats often stretch after resting.',
    'Stretching helps prepare the body for movement.',
    'A cat’s rough tongue helps with grooming.',
    'A cat’s tongue contains tiny keratin structures called papillae.',
    'Grooming helps remove loose material from the coat.',
    'Grooming is a normal part of feline behavior.',
    'Cats can use their paws to investigate objects.',
    'A cat may cautiously touch a new object with a paw.',
    'Cats spend a large part of their day resting or sleeping.',
    'Cat sleep includes different stages.',
    'A cat may rest where it can still observe its surroundings.',
    'Warm places can be attractive resting spots for cats.',
    'High places can give cats a useful view of their surroundings.',
    'A safe hiding place can help a cat relax.',
    'A cardboard box can become an interesting investigation spot.',
    'A cat may change its favorite resting place during the day.',
    'Cats can choose resting places according to temperature.',
    'Cats can choose resting places according to how quiet they are.',
    'Cat activity changes throughout the day.',
    'Cats are not strictly nocturnal animals.',
    'Many cats are especially active around dawn and dusk.',
    'Play can imitate parts of hunting behavior.',
    'A cat may stalk a toy before pouncing.',
    'A small moving toy can trigger hunting behavior.',
    'Cats can chase toys without being hungry.',
    'Unpredictable toy movement can make play more interesting.',
    'Play can help cats practice coordination.',
    'Jumping is a normal part of play for many cats.',
    'A cat may stop during play to observe its surroundings.',
    'A cat may return to a toy after a short break.',
    'Scratching is normal feline behavior.',
    'Scratching allows cats to stretch their bodies.',
    'Scratching can leave both visible and scent information.',
    'Cats may prefer different scratching surfaces.',
    'A vertical scratching surface can provide a useful stretch.',
    'Some cats prefer horizontal scratching surfaces.',
    'A cat may repeatedly use the same scratching area.',
    'Body language is an important part of feline communication.',
    'The tail is one of a cat’s important communication tools.',
    'An upright tail can be associated with a friendly greeting.',
    'A puffed-up tail can accompany strong arousal or fear.',
    'Ear position can change with a cat’s emotional state.',
    'Flattened ears can signal discomfort or defensiveness.',
    'Cats can communicate through their eyes and gaze.',
    'Slow blinking can be part of relaxed interaction.',
    'A cat may look away as a calming signal.',
    'A cat’s overall posture often tells more than one isolated signal.',
    'Cats also communicate through scent.',
    'A cat may rub its head against a familiar person or object.',
    'Cheek rubbing can help leave scent information.',
    'A cat may greet a familiar person by approaching them.',
    'A cat can show affection simply by staying nearby.',
    'Not every cat enjoys being held.',
    'Individual personality strongly influences feline social behavior.',
    'Some cats enjoy resting close to their humans.',
    'A cat may follow a familiar person from room to room.',
    'Cats can purr in several different situations.',
    'Purring does not always mean simple happiness.',
    'A cat may also purr as a way of self-soothing.',
    'Meowing is especially important in cat-human communication.',
    'Cats can use different vocal sounds in different situations.',
    'Trilling can be associated with greeting or attention.',
    'Hissing is commonly a warning or sign of discomfort.',
    'Growling can communicate a desire for more distance.',
    'Cats can express interest with small vocal sounds.',
    'Cats can learn to associate a sound with a particular event.',
    'Cats can learn to recognize familiar human voices.',
    'Cats can learn familiar footsteps and household sounds.',
    'Cats can remember familiar routes around their home.',
    'Cats can learn routines through repeated experiences.',
    'A cat may anticipate feeding time from a familiar routine.',
    'Cats can learn simple behaviors through reward-based training.',
    'Learning motivation differs between individual cats.',
    'A cat may initially approach a new object cautiously.',
    'A cat may investigate a new object by smelling it.',
    'A cat may watch something unfamiliar before approaching.',
    'A frightened cat may retreat to a safe place.',
    'A cat may return to investigate something later.',
    'Predictable surroundings can make daily life easier for a cat.',
    'A calm approach lets a cat control its distance.',
    'Cats often benefit from having the option to leave a situation.',
    'A good cat environment includes both open and sheltered spaces.',
    'Vertical spaces can give cats more opportunities to observe.',
    'A window perch can provide interesting visual stimulation.',
    'A secure window can become an excellent observation point.',
    'Different toys provide different forms of play.',
    'Food puzzles can provide mental stimulation.',
    'Searching for food can imitate part of natural foraging behavior.',
    'Cats use smell when investigating food.',
    'Cats cannot taste sweetness in the same way humans do.',
    'Cats are nutritionally adapted to animal-based foods.',
    'Cats use their tongues when drinking.',
    'A cat drinks by making rapid tongue movements at the water surface.',
    'Some cats prefer to drink in quiet locations.',
    'Cats can benefit from consistent access to their water.',
    'Feline behavior can vary greatly between individuals.',
    'Two cats may prefer completely different toys.',
    'Two cats may show affection in completely different ways.',
    'A cat’s personality reflects both genetics and experience.',
    'A safe environment allows a cat to explore at its own pace.',
    'Cats continuously learn about their surroundings through their senses.',
    'Curiosity often appears as careful watching and sniffing.',
    'Familiar scents can provide useful information about safety.',
    'A familiar sound can quickly attract a cat’s attention.',
    'A familiar person can become an important part of a cat’s environment.',
    'A relaxed cat may show trust by resting near someone.',
    'A calm home gives cats opportunities to rest without disturbance.',
    'Stella may look curious when exploring a new place.',
    'Stella’s whiskers help her investigate nearby surroundings.',
    'Stella may enjoy a warm and comfortable resting place.',
    'Stella may observe her surroundings from a high position.',
    'Stella may become interested in a small moving toy.',
    'Stella can use scratching as part of a full-body stretch.',
    'Stella may quickly recognize a familiar sound.',
    'Stella may show contentment by relaxing nearby.',
    'Every day can bring Stella a new little investigation.',
    'In Stelluriini, Stella reminds us that curiosity is a cat superpower.',
  ];

  // ============================================================
  // Muut kielet käyttävät samoja 150 faktapaikkoja.
  //
  // Näin tiedoston rakenne ja päivittäinen faktavalinta pysyvät
  // täysin yhteensopivina nykyisen HomePage-koodin kanssa.
  //
  // Kielikohtaiset listat voidaan seuraavassa kielipäivityksessä
  // lokalisoida täydellisesti ilman että HomePageen tarvitsee
  // tehdä mitään muutoksia.
  // ============================================================

  static const List<String> de = en;
  static const List<String> es = en;
  static const List<String> fr = en;
  static const List<String> zh = en;
  static const List<String> vi = en;
  static const List<String> ja = en;

  // ============================================================
  // DAILY FACT
  // ============================================================

  static String getDailyFact({
    required String languageCode,
    DateTime? date,
  }) {
    final selectedDate = date ?? DateTime.now();

    final utcDate = DateTime.utc(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    final startDate = DateTime.utc(2026, 1, 1);

    final dayIndex = utcDate.difference(startDate).inDays;

    final facts = _factsForLanguage(languageCode);

    if (facts.isEmpty) {
      return en.first;
    }

    final safeDayIndex = dayIndex < 0 ? 0 : dayIndex;

    // Deterministinen sekoitus.
    // Kerroin 37 on suhteellisen alkuluku 150:n kanssa,
    // joten kaikki 150 paikkaa käydään läpi ennen kierroksen
    // alkamista uudelleen.
    final index = (safeDayIndex * 37 + 17) % facts.length;

    return facts[index];
  }

  // ============================================================
  // LANGUAGE SELECTION
  // ============================================================

  static List<String> _factsForLanguage(String languageCode) {
    final normalizedCode = languageCode
        .trim()
        .toLowerCase()
        .split('-')
        .first;

    switch (normalizedCode) {
      case 'fi':
        return fi;

      case 'en':
        return en;

      case 'de':
        return de;

      case 'es':
        return es;

      case 'fr':
        return fr;

      case 'zh':
        return zh;

      case 'vi':
        return vi;

      case 'ja':
        return ja;

      default:
        return en;
    }
  }
}