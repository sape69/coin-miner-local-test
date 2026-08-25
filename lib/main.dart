import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const StelluriiniApp());
}

class StelluriiniApp extends StatelessWidget {
  const StelluriiniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stelluriini Miner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF35D0A0),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0B1112),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Google AdMob test rewarded ad.
  static const String rewardedAdId =
      'ca-app-pub-3940256099942544/5224354917';

  SharedPreferences? prefs;

  RewardedAd? rewardedAd;

  Timer? timer;

  int stl = 0;

  // Daily Login -putki.
  // 0 = päivä 1 seuraavaksi
  // 1 = päivä 2 seuraavaksi
  // ...
  // 6 = päivä 7 seuraavaksi
  // 7 = aina 7 STL
  int streak = 0;

  // Tavallisten Watch Ad -mainosten määrä tänään.
  int adsToday = 0;

  // Kissafaktan päivä.
  // Tämä jatkaa eteenpäin riippumatta siitä,
  // katkeaako Daily Login -putki.
  int factDay = 0;

  DateTime? lastDaily;
  DateTime? lastAd;

  Duration dailyTimer = Duration.zero;
  Duration adTimer = Duration.zero;

  bool loading = true;
  bool loadingAd = false;
  bool showingAd = false;

  // Kertoo, odotetaanko Daily Login -mainoksen palkintoa.
  bool dailyClaimPending = false;

  // ============================================================
  // KISSAFAKTAT
  // ============================================================

  static const List<String> catFacts = [
    'Kissat nukkuvat usein noin 12–16 tuntia vuorokaudessa.',
    'Kissan viikset auttavat sitä hahmottamaan ympäristöään.',
    'Kissan nenän kuvio on yksilöllinen aivan kuten sormenjälki.',
    'Kissat voivat käyttää kehräystä myös rauhoittuakseen.',
    'Kissan korvat voivat liikkua eri suuntiin toisistaan riippumatta.',
    'Kissat käyttävät häntäänsä tasapainon apuna.',
    'Kissat pystyvät hyppäämään korkealle suhteessa kehon kokoonsa.',
    'Kissan kynnet ovat sisäänvedettävät.',
    'Kissat käyttävät hajuaistiaan tärkeänä osana ympäristön tutkimista.',
    'Kissan kielessä on pieniä koukkumaisia nystyjä.',
    'Kissat voivat tunnistaa tutun ihmisen äänen.',
    'Kissan kehräys voi kuulua myös silloin, kun kissa on stressaantunut.',
    'Kissat kommunikoivat paljon kehonkielellä.',
    'Hidas silmien räpytys voi olla kissalle ystävällinen viesti.',
    'Kissat voivat oppia oman nimensä.',
    'Kissan tasapainoaisti auttaa sitä liikkumaan ketterästi.',
    'Kissat käyttävät viiksiään myös silloin, kun ne tutkivat esineitä.',
    'Kissan korvan ulompi osa auttaa suuntaamaan ääniä.',
    'Kissat ovat luonnostaan uteliaita eläimiä.',
    'Kissat voivat tunnistaa tuttuja paikkoja hajujen perusteella.',
    'Kissan häntä voi ilmaista sen mielialaa.',
    'Kissat voivat venytellä herätessään valmistautuakseen liikkumaan.',
    'Kissan tassuissa on herkkiä tuntoalueita.',
    'Monet kissat pitävät korkeista tarkkailupaikoista.',
    'Kissat voivat käyttää erilaisia ääniä eri tilanteissa.',
    'Kissan silmät heijastavat valoa hämärässä.',
    'Kissan oppiminen perustuu usein palkitsemiseen ja toistoon.',
    'Kissat voivat muodostaa vahvan siteen ihmiseen.',
    'Kissat käyttävät kynsiään myös kiipeilyssä.',
    'Kissan viiksien tyvet ovat erittäin herkkiä.',
    'Kissat puhdistavat turkkiaan nuolemalla sitä.',
    'Kissan hajuaisti on huomattavasti ihmisen hajuaistia tarkempi.',
    'Kissat voivat seurata liikkuvaa kohdetta erittäin tarkasti.',
    'Kissan pennut syntyvät silmät suljettuina.',
    'Kissan pennut oppivat paljon tarkkailemalla emoaan.',
    'Kissat voivat käyttää kehon asentoa viestintään.',
    'Kissa voi venyttää kehoaan hyvin pitkäksi.',
    'Kissan tassut auttavat sitä liikkumaan hiljaisesti.',
    'Kissat voivat oppia avaamaan joitakin ovia ja laatikoita.',
    'Kissat käyttävät paljon aikaa turkkinsa hoitamiseen.',
    'Kissan häntä auttaa sitä säilyttämään tasapainon hypyissä.',
    'Kissat voivat tunnistaa tuttujen ihmisten hajun.',
    'Kissan viikset ovat yleensä suunnilleen kehon leveyden mittaiset.',
    'Kissat voivat käyttää erilaisia kehräyksen sävyjä.',
    'Kissat voivat nähdä hämärässä paremmin kuin ihmiset.',
    'Kissoilla on hyvä lähietäisyyden liikkeen havaitsemiskyky.',
    'Kissat voivat nukkua useita lyhyitä jaksoja päivän aikana.',
    'Kissan tassujen alla olevat pehmeät anturat vaimentavat askeleita.',
    'Kissat käyttävät korviaan nopeasti paikantaakseen äänen suunnan.',
    'Kissat voivat oppia rutiineja hyvin nopeasti.',
    'Kissan häntä voi olla pystyssä silloin, kun se on rento ja ystävällinen.',
    'Kissat voivat osoittaa luottamusta makaamalla selällään.',
    'Kissat pitävät usein rauhallisista ja turvallisista paikoista.',
    'Kissan turkki suojaa ihoa ja auttaa lämmön säätelyssä.',
    'Kissat käyttävät kynsiään myös venyttelyn yhteydessä.',
    'Kissa voi käyttää tassuaan esineen koskettamiseen ennen kuin lähestyy sitä.',
    'Kissan kuuloalue on laaja.',
    'Kissat voivat reagoida hyvin korkeisiin ääniin.',
    'Kissan nenä auttaa sitä tutkimaan uusia ympäristöjä.',
    'Kissat voivat oppia yhdistämään äänen tiettyyn tapahtumaan.',
    'Kissat käyttävät paljon aikaa lepäämiseen energian säästämiseksi.',
    'Kissat voivat pitää erilaisista leluista yksilöllisten mieltymystensä mukaan.',
    'Kissan silmien pupillit muuttuvat valaistuksen mukaan.',
    'Kissat voivat käyttää kehräystä sosiaalisena viestinä.',
    'Kissa voi ilmaista tyytyväisyyttä rentouttamalla koko kehonsa.',
    'Kissat voivat oppia tunnistamaan ruokailuajan rutiinin.',
    'Kissan tassut ovat tärkeitä sekä liikkumisessa että tutkimisessa.',
    'Kissat voivat seurata ihmisen liikkeitä tarkasti.',
    'Kissat voivat oppia käyttämään raapimispaikkaa.',
    'Kissa voi käyttää raapimista myös merkitsemiseen.',
    'Kissat voivat muodostaa omia päivittäisiä rutiinejaan.',
    'Kissat tarvitsevat sekä lepoa että leikkiä.',
    'Kissa voi ilmaista kiinnostusta kallistamalla päätään.',
    'Kissan keho on erittäin joustava.',
    'Kissat voivat käyttää viiksiään arvioidessaan aukkojen kokoa.',
    'Kissat voivat muistaa tuttuja ympäristöjä pitkään.',
    'Kissa voi ilmaista rentoutta silmien ollessa puoliksi kiinni.',
    'Kissat voivat oppia pieniä temppuja palkkioiden avulla.',
    'Kissat käyttävät hajumerkkejä kommunikointiin.',
    'Kissat voivat hieroa päätään tuttuihin ihmisiin.',
    'Pään hierominen voi olla kissalle sosiaalinen tervehdys.',
    'Kissat voivat tunnistaa tutun ihmisen askeleet.',
    'Kissan turkin väri ja kuvio voivat vaihdella suuresti.',
    'Kissat voivat käyttää erilaisia ääniä tervehtiessään.',
    'Kissat voivat leikkiessään harjoitella saalistamiseen liittyviä liikkeitä.',
    'Kissan nopea suunnanmuutos perustuu sen ketteryyteen.',
    'Kissat voivat piiloutua, kun ne haluavat rauhaa.',
    'Kissat voivat käyttää korkeita paikkoja ympäristön tarkkailuun.',
    'Kissat voivat oppia ennakoimaan tuttuja päivittäisiä tapahtumia.',
    'Kissa voi venyttää etujalkojaan pitkälle eteen.',
    'Kissan kehräys voi olla ihmiselle rauhoittavan kuuloinen.',
    'Kissat voivat pitää pehmeistä nukkumapaikoista.',
    'Kissat voivat käyttää erilaisia kehon asentoja ilmaistakseen tunnetilaansa.',
    'Kissan häntä voi heilua eri tavoin eri tilanteissa.',
    'Kissat ovat taitavia tasapainoilijoita.',
    'Kissan kynnet kasvavat jatkuvasti.',
    'Kissat tarvitsevat raapimismahdollisuuksia kynsiensä luonnolliseen käyttöön.',
    'Kissat voivat käyttää leikkiä liikunnan muotona.',
    'Kissan tassunjälki on yksilöllinen.',
    'Kissat voivat oppia odottamaan ruokaa tiettyyn aikaan.',
    'Kissan viikset voivat liikkua hieman eri asentoihin tunnetilan mukaan.',
    'Kissat voivat tarkkailla ympäristöä pitkään täysin paikallaan.',
    'Kissa voi osoittaa luottamusta tulemalla lähelle lepäämään.',
    'Kissat voivat käyttää ääntelyä erityisesti ihmisten kanssa kommunikointiin.',
    'Kissa voi tunnistaa tutun ihmisen tuoksun.',
    'Kissat ovat erittäin puhtautta ylläpitäviä eläimiä.',
    'Kissa voi käyttää häntäänsä tasapainottamaan kehoa nopeassa liikkeessä.',
    'Kissat voivat oppia, missä niiden lempipaikat ovat.',
    'Kissan silmien rakenne auttaa sitä toimimaan hämärässä.',
    'Kissat voivat tarkkailla pieniäkin liikkeitä.',
    'Kissa voi tehdä pieniä hyppyjä erittäin tarkasti.',
    'Kissat voivat käyttää etutassujaan esineiden tutkimiseen.',
    'Kissat voivat oppia tunnistamaan kodin tuttuja ääniä.',
    'Kissan keho pystyy tekemään nopeita suunnanmuutoksia.',
    'Kissat voivat viettää suuren osan päivästä leväten.',
    'Kissa voi osoittaa ystävällisyyttä hitaalla räpytyksellä.',
    'Kissat voivat muodostaa vahvoja sosiaalisia suhteita.',
    'Kissa voi käyttää raapimista myös ympäristön merkitsemiseen.',
    'Kissat voivat muistaa tuttuja ihmisiä.',
    'Kissa voi ilmaista jännitystä korvien asennolla.',
    'Kissat käyttävät nenäänsä paljon ympäristön tutkimiseen.',
    'Kissat voivat oppia toistuvia käyttäytymismalleja.',
    'Kissa voi löytää suosikkipaikan kodista nopeasti.',
    'Kissat voivat leikkiessään harjoitella hyppyjä ja nopeita liikkeitä.',
    'Kissan häntä toimii tasapainon apuna myös käännöksissä.',
    'Kissat voivat tunnistaa tuttuja ääniä monien muiden äänien joukosta.',
    'Kissa voi käyttää tassujaan hellästi koskettaessaan ihmistä.',
    'Kissat voivat osoittaa tyytyväisyyttä rentoutuneella asennolla.',
    'Kissat voivat oppia uusia asioita koko elämänsä ajan.',
    'Kissan viikset ovat tärkeä osa sen aistijärjestelmää.',
    'Kissat voivat viettää paljon aikaa tarkkaillen ympäristöään.',
    'Kissa voi osoittaa uteliaisuutta lähestymällä uutta esinettä hitaasti.',
    'Kissat voivat mukautua erilaisiin päivittäisiin rutiineihin.',
    'Kissan tassujen anturat auttavat sitä liikkumaan hiljaisesti.',
    'Kissat voivat oppia, mistä kodin ovista pääsee eri tiloihin.',
    'Kissa voi ilmaista rentoutta venyttelemällä.',
    'Kissat ovat luonnostaan hyviä kiipeilijöitä.',
    'Kissan kynnet auttavat sitä tarttumaan pintoihin.',
    'Kissat voivat tarkkailla ympäristöään myös levätessään.',
    'Kissa voi tunnistaa tutun ruokailupaikan.',
    'Kissat voivat käyttää ääntelyä saadakseen ihmisen huomion.',
    'Kissa voi ilmaista kiinnostusta korvien suunnalla.',
    'Kissat voivat oppia oman kotinsa hajumaailman.',
    'Kissa voi olla aktiivinen erityisesti aamulla tai illalla.',
    'Kissat ovat usein aktiivisempia hämärän aikaan.',
    'Kissan silmät voivat näyttää kirkkailta valossa niiden heijastavan rakenteen vuoksi.',
    'Kissat voivat käyttää leikkiä sekä harjoitteluun että viihteeseen.',
    'Kissa voi osoittaa luottamusta nukkumalla lähellä ihmistä.',
    'Kissat voivat oppia tunnistamaan omistajansa päivittäisiä rutiineja.',
    'Kissa voi käyttää häntäänsä viestinnässä.',
    'Kissat voivat säätää pupilliensa kokoa valaistuksen mukaan.',
    'Kissan kuulo auttaa sitä havaitsemaan pieniäkin ääniä.',
    'Kissat voivat käyttää nenäänsä uuden paikan tutkimiseen.',
    'Kissa voi pitää omasta rauhallisesta lepopaikastaan.',
    'Kissat voivat muodostaa erilaisia persoonallisuuksia.',
    'Jokaisella kissalla voi olla omat yksilölliset mieltymyksensä.',
    'Kissa voi osoittaa kiintymystä tulemalla vapaaehtoisesti lähelle.',
    'Kissat voivat oppia yhdistämään tietyn äänen palkintoon.',
    'Kissan ketteryys auttaa sitä liikkumaan pienissäkin tiloissa.',
    'Kissat voivat käyttää tassujaan myös lelujen käsittelyyn.',
    'Kissa voi oppia odottamaan tuttua päivittäistä tapahtumaa.',
    'Kissat voivat ilmaista rauhallisuutta hitailla liikkeillä.',
    'Kissa voi tutkia uutta paikkaa ensin hajun avulla.',
    'Kissat voivat pitää erilaisista korkeista paikoista.',
    'Kissan häntä voi auttaa tasapainottamaan vartaloa hypyn aikana.',
    'Kissat voivat oppia ihmisen käyttäytymisestä rutiinien kautta.',
    'Kissa voi osoittaa uteliaisuutta seuraamalla liikettä.',
    'Kissat voivat levätä hyvin monissa erilaisissa asennoissa.',
    'Kissan viikset voivat auttaa arvioimaan ympäröivää tilaa.',
    'Kissat voivat olla hyvin taitavia piiloutujia.',
    'Kissa voi käyttää raapimispaikkaa säännöllisesti.',
    'Kissat voivat oppia uusia nimiä ja ääniä.',
    'Kissan keho on rakennettu ketterään liikkumiseen.',
    'Kissat voivat käyttää sekä näköä että kuuloa saalistamiseen liittyvissä liikkeissä.',
    'Kissa voi ilmaista turvallisuuden tunnetta rentoutuneella vartalolla.',
    'Kissat voivat pitää tutuista ja ennakoitavista rutiineista.',
    'Kissa voi osoittaa kiinnostusta uudella äänellä tai liikkeellä.',
    'Kissat voivat tarkkailla ihmisiä oppiakseen heidän rutiinejaan.',
    'Kissa voi oppia, missä sen ruoka yleensä tarjoillaan.',
    'Kissat voivat käyttää viiksiään myös pimeässä liikkumisen apuna.',
    'Kissa voi tunnistaa tutun kodin äänimaailman.',
    'Kissat voivat käyttää häntäänsä tunnetilan viestimiseen.',
    'Kissa voi osoittaa luottamusta rentoutumalla ihmisen lähellä.',
    'Kissat voivat oppia nopeasti toistuvia päivittäisiä tapahtumia.',
    'Kissan tassut auttavat sitä pysähtymään ja muuttamaan suuntaa.',
    'Kissat voivat olla hyvin tarkkoja liikkeiden seuraamisessa.',
    'Kissa voi oppia, milloin on leikkiaika.',
    'Kissat voivat nauttia erilaisista raapimis- ja kiipeilypaikoista.',
    'Kissa voi käyttää kehräystä monissa erilaisissa tilanteissa.',
    'Kissat voivat olla sekä itsenäisiä että hyvin seurallisia.',
    'Kissan persoonallisuus kehittyy kokemusten ja ympäristön vaikutuksesta.',
    'Kissat voivat oppia luottamaan ihmiseen vähitellen.',
    'Kissa voi osoittaa ystävällisyyttä tulemalla tervehtimään.',
    'Kissat voivat käyttää ääntelyä eri tarkoituksiin.',
    'Kissa voi osoittaa kiinnostusta pienellä pään liikkeellä.',
    'Kissat voivat oppia uusia rutiineja muutosten jälkeen.',
    'Kissa voi käyttää tassujaan leikkiessä hyvin tarkasti.',
    'Kissat voivat viettää aikaa tarkkaillen ikkunasta ulos.',
    'Kissa voi oppia tunnistamaan tutun auton äänen.',
    'Kissat voivat muistaa tutun ihmisen äänen.',
    'Kissa voi osoittaa rentoutta makaamalla kyljellään.',
    'Kissat voivat olla erittäin uteliaita uusista laatikoista.',
    'Kissa voi tutkia laatikon ennen kuin päättää mennä sisään.',
    'Kissat voivat pitää piilopaikoista, joissa ne tuntevat olonsa turvalliseksi.',
    'Kissa voi käyttää korkeaa paikkaa ympäristön tarkkailuun.',
    'Kissat voivat oppia erilaisia pieniä temppuja.',
    'Kissa voi yhdistää nimen tiettyyn henkilöön.',
    'Kissat voivat tunnistaa toistuvia ääniä.',
    'Kissa voi oppia, milloin omistaja yleensä tulee kotiin.',
    'Kissat voivat muodostaa vahvan siteen tuttuun ympäristöön.',
    'Kissa voi käyttää kehon asentoa viestiessään toiselle kissalle.',
    'Kissat voivat käyttää häntää tasapainon lisäksi viestintään.',
    'Kissa voi osoittaa uteliaisuutta nostamalla korvansa kohti ääntä.',
    'Kissat voivat kuulla ääniä, joita ihmiset eivät kuule.',
    'Kissa voi käyttää viiksiään ympäristön tunnusteluun.',
    'Kissat voivat oppia, mistä lempilelu löytyy.',
    'Kissa voi muistaa lempipaikkansa pitkään.',
    'Kissat voivat pitää tutuista tuoksuista.',
    'Kissa voi tutkia uuden esineen ensin haistamalla sitä.',
    'Kissat voivat oppia toistuvista palkinnoista.',
    'Kissa voi yhdistää tietyn äänen ruokaan.',
    'Kissat voivat käyttää leikkiä luonnollisten taitojen harjoitteluun.',
    'Kissa voi harjoitella hyppyjä leikin aikana.',
    'Kissat voivat olla erittäin ketteriä pienessäkin tilassa.',
    'Kissa voi tehdä nopean suunnanmuutoksen kesken juoksun.',
    'Kissat voivat käyttää kynsiään tarttumiseen.',
    'Kissa voi käyttää tassujaan tasapainon säätelyyn.',
    'Kissat voivat oppia, missä turvalliset lepopaikat sijaitsevat.',
    'Kissa voi osoittaa tyytyväisyyttä venyttelemällä.',
    'Kissat voivat nukkua eri asennoissa päivän aikana.',
    'Kissa voi vaihtaa nukkumapaikkaa ympäristön lämpötilan mukaan.',
    'Kissat voivat käyttää turkkiaan lämmön säätelyyn.',
    'Kissa voi pörröttää turkkiaan kylmässä.',
    'Kissat voivat nuolla turkkiaan sen puhdistamiseksi.',
    'Kissa voi käyttää nuolemista myös rauhoittavana käyttäytymisenä.',
    'Kissat voivat viettää paljon aikaa itsensä hoitamiseen.',
    'Kissa voi tunnistaa oman tutun lepopaikkansa.',
    'Kissat voivat oppia, missä niiden vesipaikka sijaitsee.',
    'Kissa voi ilmaista mieltymystä tiettyyn ruokailupaikkaan.',
    'Kissat voivat pitää rutiineista, koska ne tekevät ympäristöstä ennakoitavan.',
    'Kissa voi tarkkailla ympäristöään ennen kuin lähtee liikkeelle.',
    'Kissat voivat reagoida nopeasti äkilliseen liikkeeseen.',
    'Kissa voi käyttää kuuloaan ympäristön tarkkailuun silmien lisäksi