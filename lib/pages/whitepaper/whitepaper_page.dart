import 'package:flutter/material.dart';

import '../../localization.dart';
import '../../widgets/cat_avatar.dart';
import '../../widgets/stelluriini_logo.dart';

// ============================================================
// STELLA THEME COLORS
// ============================================================

const Color whitePaperBackgroundColor = Color(0xFF120B24);
const Color whitePaperCardColor = Color(0xFF21113B);
const Color whitePaperAccentColor = Color(0xFFB58CFF);
const Color whitePaperPinkColor = Color(0xFFFFB7E8);
const Color whitePaperGoldColor = Color(0xFFFFD166);

// ============================================================
// WHITE PAPER TRANSLATIONS
// ============================================================

const Map<String, Map<String, String>> _whitePaperTranslations = {
  // ==========================================================
  // FINNISH
  // ==========================================================

  'fi': {
    'pageTitle': 'VALKOINEN KIRJA',
    'communityToken': '🐾 SOLANA-YHTEISÖTOKEN 🐾',
    'whitePaper': 'VALKOINEN KIRJA',
    'version': 'Versio 1.0',

    '01_title': 'Tiivistelmä',
    '01_text':
        'Stelluriini on yhteisölähtöinen digitaalinen projekti, joka rakentuu uteliaan Stella-kissan ympärille. Stella edustaa luovuutta, yhteisöllisyyttä ja tutkimista. STL on projektin token Solana-lohkoketjussa. Stelluriini-sovellus yhdistää Stellan brändin, louhintatyyliset palkkiomekaniikat, päivittäiset aktiviteetit ja STL-ekosysteemiä koskevan tiedon.',

    '02_title': 'Visio',
    '02_text':
        'Stelluriinin visiona on luoda tunnistettava ja yhteisökeskeinen digitaalinen ekosysteemi, jossa Stella on kokemuksen keskiössä.',
    '02_b1': 'Rakentaa vahva ja tunnistettava Stella-identiteetti.',
    '02_b2':
        'Luoda mukaansatempaavia sovelluksia ja digitaalisia kokemuksia.',
    '02_b3': 'Kasvattaa aktiivista ja tervetullutta yhteisöä.',
    '02_b4':
        'Kehittää hyödyllisiä ja viihdyttäviä STL-ekosysteemin ominaisuuksia.',
    '02_b5':
        'Tutkia pelejä, sovelluksia ja tulevia Solana-integraatioita.',

    '03_title': 'Mikä Stelluriini on?',
    '03_text':
        'Stelluriini on enemmän kuin tokenin nimi. Se on Stella-kissan ympärille rakennettu projektin identiteetti ja yhteisölähtöinen digitaalinen kokemus.',
    '03_f1_title': 'Stella',
    '03_f1_desc':
        'Projektin visuaalinen maskotti ja tunnistettava identiteetti.',
    '03_f2_title': 'STL',
    '03_f2_desc':
        'Stelluriini-token, joka liittyy Solana-ekosysteemiin.',
    '03_f3_title': 'Sovellus',
    '03_f3_desc':
        'Mobiilikokemus, joka sisältää louhintatyylisiä palkintoja, päivittäisiä aktiviteetteja ja projektitietoa.',
    '03_f4_title': 'Yhteisö',
    '03_f4_desc':
        'Yhteisökeskeinen ympäristö, jossa tulevia ominaisuuksia voidaan kehittää yhdessä.',

    '04_title': 'Stella',
    '04_heading': 'Stella on Stelluriinin sydän.',
    '04_text':
        'Stella edustaa uteliaisuutta, ystävällisyyttä ja tutkimista. Hänen tehtävänsä on tehdä Stelluriini-kokemuksesta tunnistettava ja tarjota yhtenäinen identiteetti sovellukselle, yhteisölle ja tulevalle ekosysteemille.',

    '05_title': 'STL Token',
    '05_name': 'Tokenin nimi',
    '05_symbol': 'Symboli',
    '05_blockchain': 'Lohkoketju',
    '05_supply': 'Kokonaistarjonta',
    '05_decimals': 'Desimaalit',
    '05_mint': 'Mint-osoite',

    '06_title': 'Tokenomiikka',
    '06_text':
        'Suunniteltu STL-allokaatio on tarkoitettu tukemaan yhteisöpalkintoja, likviditeettiä, ekosysteemin kasvua, kehitystä ja markkinointia.',
    '06_a1': 'Yhteisö & palkinnot',
    '06_a2': 'Likviditeetti',
    '06_a3': 'Ekosysteemi',
    '06_a4': 'Kehitys',
    '06_a5': 'Markkinointi',
    '06_total': 'Allokaatio yhteensä: 17 602 539 062 STL',

    '07_title': 'Stella Mining',
    '07_text':
        'Stelluriini-sovellus sisältää louhintatyylisen palkintojärjestelmän. Järjestelmä on suunniteltu sovelluksen sisäiseksi etenemismekaniikaksi, jossa käyttäjät keräävät virtuaalisia STL-pisteitä louhintajakson aikana.',
    '07_f1_title': 'Hash Rate',
    '07_f1_desc':
        'Käyttäjän hash rate määrittää nopeuden, jolla virtuaalisia louhintapisteitä kertyy.',
    '07_f2_title': 'Louhintajakso',
    '07_f2_desc':
        'Louhintajakso kestää määritellyn ajan, minkä jälkeen kertynyt palkinto voidaan kerätä.',
    '07_f3_title': 'Palkinnon laskenta',
    '07_f3_desc':
        'Virtuaalinen palkinto lasketaan hash raten ja kuluneen louhinta-ajan perusteella.',
    '07_f4_title': 'Lukittu louhintanopeus',
    '07_f4_desc':
        'Aktiivisen louhintajakson käyttämä hash rate pysyy vakaana kyseisen jakson ajan.',

    '08_title': 'Päivittäinen bonus',
    '08_text':
        'Päivittäinen bonus kannustaa säännölliseen osallistumiseen Stelluriini-sovelluksessa. Onnistunut päivittäinen kirjautuminen voi kasvattaa käyttäjän hash ratea ja ylläpitää peräkkäisten päivien putkea.',
    '08_b1':
        'Päivittäisen bonuksen voi lunastaa onnistuneesti kerran päivässä.',
    '08_b2':
        'Peräkkäisten päivien putkea voidaan ylläpitää palaamalla seuraavina päivinä.',
    '08_b3':
        'Bonus vaikuttaa käyttäjän hash rateen, jota käytetään tulevissa louhintajaksoissa.',

    '09_title': 'Stella Power Boost',
    '09_text':
        'Stella Power Boost -järjestelmän avulla käyttäjät voivat saada ylimääräisen hash rate -bonuksen katsomalla palkintomainoksen. Järjestelmässä on rajoituksia ja jäähdytysaikoja väärinkäytösten vähentämiseksi.',
    '09_f1_title': 'Palkintomainokset',
    '09_f1_desc':
        'Käyttäjä voi saada sovelluksen sisäisen hash rate -bonuksen hyväksytyn palkintomainoksen jälkeen.',
    '09_f2_title': 'Jäähdytysaika',
    '09_f2_desc':
        'Jäähdytysaika rajoittaa sitä, kuinka usein mainospalkinnon voi lunastaa.',
    '09_f3_title': 'Päivittäinen raja',
    '09_f3_desc':
        'Päivässä voidaan laskea mukaan enintään määritelty määrä palkintomainoksia.',

    '10_title': 'Sovellusarkkitehtuuri',
    '10_text':
        'Stelluriini-sovellus on suunniteltu mobiiliasiakkaan ja palvelinpuolen palveluiden ympärille. Palvelinpalvelut käsittelevät tunnistettuja palkintotoimintoja ja tapahtumahistoriaa.',
    '10_b1_title': 'Flutter-sovellus',
    '10_b1_desc':
        'Käyttöliittymä, Stella-kokemus, louhintanäkymä ja projektitiedot.',
    '10_b2_title': 'Firebase-palvelut',
    '10_b2_desc':
        'Autentikointi, Firestore-tiedot ja palvelinpuolen Cloud Functions -toiminnot.',
    '10_b3_title': 'Palvelinpuolen validointi',
    '10_b3_desc':
        'Palkintorajat, jäähdytysajat, kaksoiskäsittelyn esto ja tunnistetut toiminnot.',
    '10_b4_title': 'Solana / STL',
    '10_b4_desc':
        'Stelluriini-token on Solana-lohkoketjussa oleva digitaalinen omaisuuserä.',

    '11_title': 'Tapahtumahistoria',
    '11_text':
        'Sovellus tarjoaa tapahtumahistorianäkymän, jossa käyttäjälle voidaan näyttää tallennettua palkintoihin liittyvää toimintaa.',
    '11_b1': 'Louhintapalkintojen tapahtumat.',
    '11_b2': 'Päivittäisten palkintojen tapahtumat.',
    '11_b3': 'Palkintomainosten tapahtumat.',
    '11_b4': 'Saldo tallennetun palkinnon jälkeen.',
    '11_b5': 'Tapahtuman päivämäärä ja tyyppi.',

    '12_title': 'Turvallisuus & väärinkäytösten esto',
    '12_text':
        'Stelluriini-sovellus käyttää palvelinpuolen validointia palkintotoimintojen manipuloinnin vähentämiseksi. Turvamekanismien tarkoituksena on suojata sovelluksen ja palkintojärjestelmän eheyttä.',
    '12_f1_title': 'Autentikointi',
    '12_f1_desc':
        'Palkintotoiminnot edellyttävät tunnistettua käyttäjäistuntoa.',
    '12_f2_title': 'Kaksoiskäsittelyn esto',
    '12_f2_desc':
        'Palkintotapahtumat voidaan suojata toistuvaa käsittelyä vastaan.',
    '12_f3_title': 'Käyttörajoitukset',
    '12_f3_desc':
        'Päivittäiset rajat ja jäähdytysajat auttavat vähentämään automatisoitua väärinkäyttöä.',
    '12_f4_title': 'Palkintojen validointi',
    '12_f4_desc':
        'Palvelinpuolen logiikka tarkistaa tärkeät palkintoehdot ennen niiden tallentamista.',

    '13_title': 'Yhteisö',
    '13_text':
        'Yhteisön osallistuminen on tärkeä osa Stelluriinin visiota. Projektin tavoitteena on kehittää ympäristöä, jossa käyttäjät voivat seurata kehitystä, antaa palautetta ja osallistua tuleviin ekosysteemin aktiviteetteihin.',
    '13_b1':
        'Yhteisön palaute voi vaikuttaa tulevaan kehitykseen.',
    '13_b2':
        'Tulevat yhteisöominaisuudet voivat laajentaa STL:n roolia.',
    '13_b3':
        'Läpinäkyvyys on tarkoitus pitää tärkeänä projektin periaatteena.',

    '14_title': 'Tuleva ekosysteemi',
    '14_text':
        'Tuleva Stelluriini-ekosysteemi voi laajentua nykyisen sovelluksen ulkopuolelle. Mahdollisia suuntia ovat uudet Stella-kokemukset, pelit, sovellukset, yhteisöominaisuudet ja lisäintegraatiot Solanan kanssa.',
    '14_f1_title': 'Stella-pelit',
    '14_f1_desc':
        'Tutkitaan pelejä ja interaktiivisia kokemuksia, joissa Stella esiintyy.',
    '14_f2_title': 'Uudet sovellukset',
    '14_f2_desc':
        'Kehitetään uusia digitaalisia tuotteita ja palveluita Stelluriini-identiteetin ympärille.',
    '14_f3_title': 'STL-integraatiot',
    '14_f3_desc':
        'Tutkitaan hyödyllisiä STL:n ja Solana-ekosysteemin integraatioita.',
    '14_f4_title': 'Yhteisöaktiviteetit',
    '14_f4_desc':
        'Mahdollisia tapahtumia, haasteita ja yhteisökeskeisiä palkintokokemuksia.',

    '15_title': 'Tiekartta',
    '15_p1_title': 'Alku',
    '15_p1_status': 'KÄYNNISSÄ',
    '15_p1_desc':
        'Stelluriini-identiteetin luominen, Stella-brändin kehittäminen, sovelluksen rakentaminen ja STL-tietojen valmistelu.',
    '15_p2_title': 'Yhteisö',
    '15_p2_status': 'SUUNNITELTU',
    '15_p2_desc':
        'Yhteisön kasvattaminen, kielituen parantaminen, päivittäisten aktiviteettien ja yhteisöominaisuuksien kehittäminen.',
    '15_p3_title': 'STL-ekosysteemi',
    '15_p3_status': 'TULEVAISUUS',
    '15_p3_desc':
        'STL-ekosysteemin toiminnallisuuden, lohkoketjutietojen, tilastojen ja muiden Stelluriini-ominaisuuksien laajentaminen.',
    '15_p4_title': 'Tulevaisuus',
    '15_p4_status': 'TULEVAISUUS',
    '15_p4_desc':
        'Ekosysteemin jatkuva kehittäminen, uusien Stella-kokemusten tuominen ja STL:n uusien mahdollisuuksien tutkiminen.',

    '16_title': 'Läpinäkyvyys',
    '16_text':
        'Stelluriinin tavoitteena on erottaa selkeästi olemassa oleva toiminnallisuus tulevaisuuden suunnitelmista. Projektidokumentaation tarkoituksena on kuvata projektin nykytila ja suunniteltu suunta mahdollisimman tarkasti.',
    '16_b1': 'STL:n kokonaistarjonta on dokumentoitu.',
    '16_b2': 'Token-allokaation rakenne on dokumentoitu.',
    '16_b3':
        'Nykyinen sovellustoiminnallisuus kuvataan erillään tulevaisuuden suunnitelmista.',
    '16_b4':
        'Tiekartan painopisteet voivat muuttua kehityksen edetessä.',

    '17_title': 'Riskit & rajoitukset',
    '17_text':
        'Digitaaliset omaisuuserät ja ohjelmistoprojektit sisältävät teknisiä, markkina-, sääntely- ja toiminnallisia riskejä. Käyttäjien tulee ymmärtää nämä riskit ennen lohkoketjupohjaisen omaisuuserän tai sovelluksen käyttöä.',
    '17_b1': 'Kryptovaluuttamarkkinat voivat olla erittäin epävakaita.',
    '17_b2':
        'Lohkoketjutapahtumat voivat sisältää peruuttamattomia toimintoja.',
    '17_b3':
        'Ohjelmistoissa voi olla virheitä tai teknisiä rajoituksia.',
    '17_b4':
        'Lohkoketju- ja sääntely-ympäristöt voivat muuttua.',
    '17_b5': 'Tulevia tiekartan tavoitteita ei taata.',
    '17_b6':
        'Sovelluksen virtuaalisia palkintoja ei tule tulkita taatuiksi taloudellisiksi tuotoiksi.',

    '18_title': '18 • VASTUUVAPAUSLAUSEKE',
    '18_text':
        'Stelluriini ja STL esitellään yhteisölähtöisenä digitaalisena projektina. Tämän asiakirjan tiedot on tarkoitettu ainoastaan informatiivisiin tarkoituksiin eivätkä ne muodosta taloudellista, sijoitus-, oikeudellista tai veroneuvontaa.',
    '18_text2':
        'Sovelluksessa näkyviä virtuaalisia pisteitä ei tule tulkita taatuksi kryptovaluutan arvoksi tai taatuksi taloudelliseksi tuotoksi.',

    '19_title': 'Viralliset tiedot',
    '19_text':
        'Virallista Stelluriini-sovellusta tulee käyttää yhdessä varmennettujen projektitietojen kanssa. Tarkista token-osoitteet aina ennen lohkoketjuomaisuuserien kanssa toimimista.',
    '19_mint': 'STELLURIINI MINT',

    'closing': '🐱 Stella on vasta aloittamassa.',
    'closingSub': 'Yhteisö • Uteliaisuus • Luovuus • Solana',
    'footer': '🐾 STELLA • STELLURIINI • STL • SOLANA 🐾',
    'footerSupply': '17 602 539 062 STL',
    'footerVersion': 'VALKOINEN KIRJA v1.0',
  },

  // ==========================================================
  // ENGLISH
  // ==========================================================

  'en': {
    'pageTitle': 'WHITE PAPER',
    'communityToken': '🐾 SOLANA COMMUNITY TOKEN 🐾',
    'whitePaper': 'WHITE PAPER',
    'version': 'Version 1.0',

    '01_title': 'Executive Summary',
    '01_text':
        'Stelluriini is a community-driven digital project built around Stella, a curious cat representing creativity, community and exploration. STL is the project token on the Solana blockchain. The Stelluriini application combines Stella branding, mining-style reward mechanics, daily activities and information about the STL ecosystem.',

    '02_title': 'Vision',
    '02_text':
        'The vision of Stelluriini is to create a recognizable and community-focused digital ecosystem where Stella is at the center of the experience.',
    '02_b1': 'Build a strong and recognizable Stella identity.',
    '02_b2': 'Create engaging applications and digital experiences.',
    '02_b3': 'Grow an active and welcoming community.',
    '02_b4':
        'Develop useful and entertaining STL ecosystem features.',
    '02_b5':
        'Explore games, applications and future Solana integrations.',

    '03_title': 'What is Stelluriini?',
    '03_text':
        'Stelluriini is more than a token name. It is a project identity built around Stella and a community-oriented digital experience.',
    '03_f1_title': 'Stella',
    '03_f1_desc':
        'The visual mascot and recognizable identity of the project.',
    '03_f2_title': 'STL',
    '03_f2_desc':
        'The Stelluriini token associated with the Solana ecosystem.',
    '03_f3_title': 'Application',
    '03_f3_desc':
        'A mobile experience containing mining-style rewards, daily activities and project information.',
    '03_f4_title': 'Community',
    '03_f4_desc':
        'A community-focused environment where future features can be developed together.',

    '04_title': 'Stella',
    '04_heading': 'Stella is the heart of Stelluriini.',
    '04_text':
        'Stella represents curiosity, friendliness and exploration. Her role is to make the Stelluriini experience recognizable while providing a consistent identity for the application, community and future ecosystem.',

    '05_title': 'STL Token',
    '05_name': 'Token Name',
    '05_symbol': 'Symbol',
    '05_blockchain': 'Blockchain',
    '05_supply': 'Total Supply',
    '05_decimals': 'Decimals',
    '05_mint': 'Mint Address',

    '06_title': 'Tokenomics',
    '06_text':
        'The planned STL allocation is designed to support community rewards, liquidity, ecosystem growth, development and marketing.',
    '06_a1': 'Community & Rewards',
    '06_a2': 'Liquidity',
    '06_a3': 'Ecosystem',
    '06_a4': 'Development',
    '06_a5': 'Marketing',
    '06_total': 'Total allocation: 17 602 539 062 STL',

    '07_title': 'Stella Mining',
    '07_text':
        'The Stelluriini application includes a mining-style reward system. The system is designed as an in-app progression mechanic where users accumulate virtual STL points over a mining cycle.',
    '07_f1_title': 'Hash Rate',
    '07_f1_desc':
        'A user hash rate determines the rate at which virtual mining points accumulate.',
    '07_f2_title': 'Mining Cycle',
    '07_f2_desc':
        'A mining cycle runs for a defined period before its accumulated reward can be claimed.',
    '07_f3_title': 'Reward Calculation',
    '07_f3_desc':
        'The virtual reward is calculated from hash rate and elapsed mining time.',
    '07_f4_title': 'Locked Mining Rate',
    '07_f4_desc':
        'The hash rate used by an active mining cycle is kept stable during that cycle.',

    '08_title': 'Daily Bonus',
    '08_text':
        'The Daily Bonus encourages regular participation in the Stelluriini application. A successful daily check-in can increase the user hash rate and contribute to a consecutive daily streak.',
    '08_b1':
        'Daily check-in is limited to one successful claim per day.',
    '08_b2':
        'A consecutive streak can be maintained by returning on following days.',
    '08_b3':
        'The bonus affects the user hash rate used for future mining cycles.',

    '09_title': 'Stella Power Boost',
    '09_text':
        'The Stella Power Boost system allows users to receive an additional hash-rate bonus through rewarded advertising. The system contains limits and cooldown rules to help prevent abuse.',
    '09_f1_title': 'Rewarded Ads',
    '09_f1_desc':
        'Users can receive an in-app hash-rate bonus after a qualifying rewarded advertisement.',
    '09_f2_title': 'Cooldown',
    '09_f2_desc':
        'A cooldown period limits how frequently an ad reward can be claimed.',
    '09_f3_title': 'Daily Limit',
    '09_f3_desc':
        'A maximum number of rewarded advertisements can be counted per day.',

    '10_title': 'Application Architecture',
    '10_text':
        'The Stelluriini application is designed around a mobile client and server-side services that handle authenticated reward operations and transaction history.',
    '10_b1_title': 'Flutter Application',
    '10_b1_desc':
        'User interface, Stella experience, mining dashboard and project information.',
    '10_b2_title': 'Firebase Services',
    '10_b2_desc':
        'Authentication, Firestore data and server-side Cloud Functions.',
    '10_b3_title': 'Server-Side Validation',
    '10_b3_desc':
        'Reward limits, cooldowns, duplicate protection and authenticated operations.',
    '10_b4_title': 'Solana / STL',
    '10_b4_desc':
        'The Stelluriini token exists as an asset on the Solana blockchain.',

    '11_title': 'Transaction History',
    '11_text':
        'The application provides a transaction history view where recorded reward activity can be displayed to the user.',
    '11_b1': 'Mining reward activity.',
    '11_b2': 'Daily reward activity.',
    '11_b3': 'Rewarded advertisement activity.',
    '11_b4': 'Balance after a recorded reward.',
    '11_b5': 'Transaction date and activity type.',

    '12_title': 'Security & Anti-Abuse',
    '12_text':
        'The Stelluriini application uses server-side validation to reduce manipulation of reward operations. Security mechanisms are intended to protect the integrity of the application and its reward system.',
    '12_f1_title': 'Authentication',
    '12_f1_desc':
        'Reward operations require an authenticated user session.',
    '12_f2_title': 'Duplicate Protection',
    '12_f2_desc':
        'Reward transactions can be protected against repeated processing.',
    '12_f3_title': 'Rate Limits',
    '12_f3_desc':
        'Daily limits and cooldown periods help reduce automated abuse.',
    '12_f4_title': 'Reward Validation',
    '12_f4_desc':
        'Server-side logic validates important reward conditions before recording them.',

    '13_title': 'Community',
    '13_text':
        'Community participation is an important part of the Stelluriini vision. The project aims to develop an environment where users can follow progress, provide feedback and participate in future ecosystem activities.',
    '13_b1':
        'Community feedback can influence future development.',
    '13_b2':
        'Future community features may expand the role of STL.',
    '13_b3':
        'Transparency is intended to remain an important project principle.',

    '14_title': 'Future Ecosystem',
    '14_text':
        'The future Stelluriini ecosystem may expand beyond the current application. Potential directions include new Stella experiences, games, applications, community features and additional Solana integrations.',
    '14_f1_title': 'Stella Games',
    '14_f1_desc':
        'Explore games and interactive experiences featuring Stella.',
    '14_f2_title': 'New Applications',
    '14_f2_desc':
        'Develop additional digital products and services around the Stelluriini identity.',
    '14_f3_title': 'STL Integrations',
    '14_f3_desc':
        'Explore useful integrations involving STL and the Solana ecosystem.',
    '14_f4_title': 'Community Activities',
    '14_f4_desc':
        'Potential events, challenges and community-focused reward experiences.',

    '15_title': 'Roadmap',
    '15_p1_title': 'The Beginning',
    '15_p1_status': 'IN PROGRESS',
    '15_p1_desc':
        'Establish the Stelluriini identity, develop Stella branding, build the application and prepare STL information.',
    '15_p2_title': 'Community',
    '15_p2_status': 'PLANNED',
    '15_p2_desc':
        'Grow the community, improve language support, develop daily activities and community features.',
    '15_p3_title': 'STL Ecosystem',
    '15_p3_status': 'FUTURE',
    '15_p3_desc':
        'Expand STL ecosystem functionality, blockchain information, statistics and additional Stelluriini features.',
    '15_p4_title': 'The Future',
    '15_p4_status': 'FUTURE',
    '15_p4_desc':
        'Continue ecosystem development, introduce new Stella experiences and explore new possibilities for STL.',

    '16_title': 'Transparency',
    '16_text':
        'Stelluriini aims to clearly distinguish existing functionality from future plans. The project documentation is intended to describe the current state of the project and its planned direction as accurately as possible.',
    '16_b1': 'The STL total supply is documented.',
    '16_b2': 'The token allocation structure is documented.',
    '16_b3':
        'The current application functionality is described separately from future plans.',
    '16_b4':
        'Roadmap priorities may change as development continues.',

    '17_title': 'Risks & Limitations',
    '17_text':
        'Digital assets and software projects involve technical, market, regulatory and operational risks. Users should understand these risks before interacting with any blockchain-based asset or application.',
    '17_b1': 'Cryptocurrency markets can be highly volatile.',
    '17_b2':
        'Blockchain transactions may involve irreversible actions.',
    '17_b3':
        'Software may contain bugs or technical limitations.',
    '17_b4':
        'Blockchain and regulatory environments may change.',
    '17_b5': 'Future roadmap items are not guaranteed.',
    '17_b6':
        'In-app virtual rewards should not be interpreted as guaranteed financial returns.',

    '18_title': '18 • DISCLAIMER',
    '18_text':
        'Stelluriini and STL are presented as a community-driven digital project. Information in this document is provided for informational purposes only and does not constitute financial, investment, legal or tax advice.',
    '18_text2':
        'Virtual points displayed in the application should not be interpreted as guaranteed cryptocurrency value or guaranteed financial returns.',

    '19_title': 'Official Information',
    '19_text':
        'The official Stelluriini application should be used together with verified project information. Always verify token addresses before interacting with blockchain assets.',
    '19_mint': 'STELLURIINI MINT',

    'closing': '🐱 Stella is just getting started.',
    'closingSub': 'Community • Curiosity • Creativity • Solana',
    'footer': '🐾 STELLA • STELLURIINI • STL • SOLANA 🐾',
    'footerSupply': '17 602 539 062 STL',
    'footerVersion': 'WHITE PAPER v1.0',
  },

  // ==========================================================
  // GERMAN
  // ==========================================================

  'de': {
    'pageTitle': 'WHITEPAPER',
    'communityToken': '🐾 SOLANA COMMUNITY TOKEN 🐾',
    'whitePaper': 'WHITEPAPER',
    'version': 'Version 1.0',

    '01_title': 'Zusammenfassung',
    '01_text':
        'Stelluriini ist ein gemeinschaftsorientiertes digitales Projekt rund um Stella, eine neugierige Katze, die Kreativität, Gemeinschaft und Entdeckung verkörpert. STL ist der Projekttoken auf der Solana-Blockchain. Die Stelluriini-Anwendung verbindet Stella-Branding, Mining-ähnliche Belohnungsmechaniken, tägliche Aktivitäten und Informationen über das STL-Ökosystem.',

    '02_title': 'Vision',
    '02_text':
        'Die Vision von Stelluriini ist ein erkennbares und gemeinschaftsorientiertes digitales Ökosystem zu schaffen, in dessen Mittelpunkt Stella steht.',
    '02_b1': 'Eine starke und erkennbare Stella-Identität aufbauen.',
    '02_b2':
        'Ansprechende Anwendungen und digitale Erlebnisse entwickeln.',
    '02_b3': 'Eine aktive und offene Community aufbauen.',
    '02_b4':
        'Nützliche und unterhaltsame Funktionen des STL-Ökosystems entwickeln.',
    '02_b5':
        'Spiele, Anwendungen und zukünftige Solana-Integrationen erkunden.',

    '03_title': 'Was ist Stelluriini?',
    '03_text':
        'Stelluriini ist mehr als ein Tokenname. Es ist eine Projektidentität rund um Stella und ein gemeinschaftsorientiertes digitales Erlebnis.',
    '03_f1_title': 'Stella',
    '03_f1_desc':
        'Das visuelle Maskottchen und die erkennbare Identität des Projekts.',
    '03_f2_title': 'STL',
    '03_f2_desc':
        'Der Stelluriini-Token im Zusammenhang mit dem Solana-Ökosystem.',
    '03_f3_title': 'Anwendung',
    '03_f3_desc':
        'Eine mobile Anwendung mit Mining-ähnlichen Belohnungen, täglichen Aktivitäten und Projektinformationen.',
    '03_f4_title': 'Community',
    '03_f4_desc':
        'Eine gemeinschaftsorientierte Umgebung, in der zukünftige Funktionen gemeinsam entwickelt werden können.',

    '04_title': 'Stella',
    '04_heading': 'Stella ist das Herz von Stelluriini.',
    '04_text':
        'Stella steht für Neugier, Freundlichkeit und Entdeckung. Ihre Aufgabe ist es, das Stelluriini-Erlebnis erkennbar zu machen und der Anwendung, Community und dem zukünftigen Ökosystem eine einheitliche Identität zu geben.',

    '05_title': 'STL Token',
    '05_name': 'Tokenname',
    '05_symbol': 'Symbol',
    '05_blockchain': 'Blockchain',
    '05_supply': 'Gesamtangebot',
    '05_decimals': 'Dezimalstellen',
    '05_mint': 'Mint-Adresse',

    '06_title': 'Tokenomics',
    '06_text':
        'Die geplante STL-Verteilung soll Community-Belohnungen, Liquidität, Ökosystemwachstum, Entwicklung und Marketing unterstützen.',
    '06_a1': 'Community & Belohnungen',
    '06_a2': 'Liquidität',
    '06_a3': 'Ökosystem',
    '06_a4': 'Entwicklung',
    '06_a5': 'Marketing',
    '06_total': 'Gesamtverteilung: 17 602 539 062 STL',

    '07_title': 'Stella Mining',
    '07_text':
        'Die Stelluriini-Anwendung enthält ein Mining-ähnliches Belohnungssystem. Es ist als In-App-Fortschrittsmechanik konzipiert, bei der Benutzer virtuelle STL-Punkte während eines Mining-Zyklus sammeln.',
    '07_f1_title': 'Hash Rate',
    '07_f1_desc':
        'Die Hash Rate eines Benutzers bestimmt die Geschwindigkeit, mit der virtuelle Mining-Punkte gesammelt werden.',
    '07_f2_title': 'Mining-Zyklus',
    '07_f2_desc':
        'Ein Mining-Zyklus läuft für einen festgelegten Zeitraum, bevor die angesammelte Belohnung beansprucht werden kann.',
    '07_f3_title': 'Belohnungsberechnung',
    '07_f3_desc':
        'Die virtuelle Belohnung wird anhand der Hash Rate und der vergangenen Mining-Zeit berechnet.',
    '07_f4_title': 'Gesperrte Mining-Rate',
    '07_f4_desc':
        'Die von einem aktiven Mining-Zyklus verwendete Hash Rate bleibt während dieses Zyklus stabil.',

    '08_title': 'Täglicher Bonus',
    '08_text':
        'Der tägliche Bonus fördert die regelmäßige Teilnahme an der Stelluriini-Anwendung. Ein erfolgreicher täglicher Check-in kann die Hash Rate erhöhen und zu einer aufeinanderfolgenden Tagesserie beitragen.',
    '08_b1':
        'Der tägliche Check-in ist auf eine erfolgreiche Einlösung pro Tag begrenzt.',
    '08_b2':
        'Eine Serie kann durch die Rückkehr an den folgenden Tagen aufrechterhalten werden.',
    '08_b3':
        'Der Bonus beeinflusst die Hash Rate für zukünftige Mining-Zyklen.',

    '09_title': 'Stella Power Boost',
    '09_text':
        'Das Stella Power Boost-System ermöglicht einen zusätzlichen Hash-Rate-Bonus durch Werbung. Limits und Abkühlzeiten helfen dabei, Missbrauch zu reduzieren.',
    '09_f1_title': 'Werbung',
    '09_f1_desc':
        'Benutzer können nach einer qualifizierenden Werbung einen In-App-Hash-Rate-Bonus erhalten.',
    '09_f2_title': 'Abkühlzeit',
    '09_f2_desc':
        'Eine Abkühlzeit begrenzt, wie häufig eine Werbeprämie beansprucht werden kann.',
    '09_f3_title': 'Tageslimit',
    '09_f3_desc':
        'Pro Tag kann eine maximale Anzahl von Werbungen gezählt werden.',

    '10_title': 'Anwendungsarchitektur',
    '10_text':
        'Die Stelluriini-Anwendung basiert auf einem mobilen Client und serverseitigen Diensten für authentifizierte Belohnungsaktionen und Transaktionshistorie.',
    '10_b1_title': 'Flutter-Anwendung',
    '10_b1_desc':
        'Benutzeroberfläche, Stella-Erlebnis, Mining-Dashboard und Projektinformationen.',
    '10_b2_title': 'Firebase-Dienste',
    '10_b2_desc':
        'Authentifizierung, Firestore-Daten und serverseitige Cloud Functions.',
    '10_b3_title': 'Serverseitige Validierung',
    '10_b3_desc':
        'Belohnungslimits, Abkühlzeiten, Schutz vor Duplikaten und authentifizierte Vorgänge.',
    '10_b4_title': 'Solana / STL',
    '10_b4_desc':
        'Der Stelluriini-Token existiert als Asset auf der Solana-Blockchain.',

    '11_title': 'Transaktionsverlauf',
    '11_text':
        'Die Anwendung bietet eine Transaktionsansicht, in der aufgezeichnete Belohnungsaktivitäten angezeigt werden können.',
    '11_b1': 'Mining-Belohnungen.',
    '11_b2': 'Tägliche Belohnungen.',
    '11_b3': 'Werbeaktivitäten.',
    '11_b4': 'Kontostand nach einer aufgezeichneten Belohnung.',
    '11_b5': 'Transaktionsdatum und Aktivitätstyp.',

    '12_title': 'Sicherheit & Missbrauchsschutz',
    '12_text':
        'Die Stelluriini-Anwendung verwendet serverseitige Validierung, um Manipulationen von Belohnungsvorgängen zu reduzieren. Die Sicherheitsmechanismen sollen die Integrität der Anwendung und des Belohnungssystems schützen.',
    '12_f1_title': 'Authentifizierung',
    '12_f1_desc':
        'Belohnungsvorgänge erfordern eine authentifizierte Benutzersitzung.',
    '12_f2_title': 'Duplikatschutz',
    '12_f2_desc':
        'Belohnungstransaktionen können vor mehrfacher Verarbeitung geschützt werden.',
    '12_f3_title': 'Ratenbegrenzungen',
    '12_f3_desc':
        'Tageslimits und Abkühlzeiten helfen, automatisierten Missbrauch zu reduzieren.',
    '12_f4_title': 'Belohnungsvalidierung',
    '12_f4_desc':
        'Serverseitige Logik überprüft wichtige Bedingungen vor der Speicherung.',

    '13_title': 'Community',
    '13_text':
        'Die Beteiligung der Community ist ein wichtiger Bestandteil der Stelluriini-Vision. Das Projekt möchte eine Umgebung entwickeln, in der Benutzer den Fortschritt verfolgen, Feedback geben und an zukünftigen Aktivitäten teilnehmen können.',
    '13_b1':
        'Community-Feedback kann die zukünftige Entwicklung beeinflussen.',
    '13_b2':
        'Zukünftige Community-Funktionen können die Rolle von STL erweitern.',
    '13_b3':
        'Transparenz soll ein wichtiges Projektprinzip bleiben.',

    '14_title': 'Zukünftiges Ökosystem',
    '14_text':
        'Das zukünftige Stelluriini-Ökosystem kann über die aktuelle Anwendung hinaus wachsen. Mögliche Richtungen sind neue Stella-Erlebnisse, Spiele, Anwendungen, Community-Funktionen und weitere Solana-Integrationen.',
    '14_f1_title': 'Stella-Spiele',
    '14_f1_desc':
        'Spiele und interaktive Erlebnisse mit Stella erkunden.',
    '14_f2_title': 'Neue Anwendungen',
    '14_f2_desc':
        'Weitere digitale Produkte und Dienste rund um Stelluriini entwickeln.',
    '14_f3_title': 'STL-Integrationen',
    '14_f3_desc':
        'Nützliche Integrationen mit STL und dem Solana-Ökosystem erkunden.',
    '14_f4_title': 'Community-Aktivitäten',
    '14_f4_desc':
        'Mögliche Events, Herausforderungen und gemeinschaftliche Belohnungserlebnisse.',

    '15_title': 'Roadmap',
    '15_p1_title': 'Der Anfang',
    '15_p1_status': 'IN ARBEIT',
    '15_p1_desc':
        'Stelluriini-Identität etablieren, Stella-Branding entwickeln, Anwendung erstellen und STL-Informationen vorbereiten.',
    '15_p2_title': 'Community',
    '15_p2_status': 'GEPLANT',
    '15_p2_desc':
        'Community wachsen lassen, Sprachunterstützung verbessern und tägliche sowie Community-Funktionen entwickeln.',
    '15_p3_title': 'STL-Ökosystem',
    '15_p3_status': 'ZUKUNFT',
    '15_p3_desc':
        'STL-Funktionen, Blockchain-Informationen, Statistiken und weitere Stelluriini-Funktionen erweitern.',
    '15_p4_title': 'Die Zukunft',
    '15_p4_status': 'ZUKUNFT',
    '15_p4_desc':
        'Ökosystem weiterentwickeln, neue Stella-Erlebnisse einführen und neue Möglichkeiten für STL erkunden.',

    '16_title': 'Transparenz',
    '16_text':
        'Stelluriini möchte bestehende Funktionen klar von zukünftigen Plänen unterscheiden. Die Dokumentation soll den aktuellen Projektstand und die geplante Richtung möglichst genau beschreiben.',
    '16_b1': 'Das STL-Gesamtangebot ist dokumentiert.',
    '16_b2': 'Die Token-Verteilungsstruktur ist dokumentiert.',
    '16_b3':
        'Aktuelle Funktionen werden getrennt von zukünftigen Plänen beschrieben.',
    '16_b4':
        'Roadmap-Prioritäten können sich während der Entwicklung ändern.',

    '17_title': 'Risiken & Einschränkungen',
    '17_text':
        'Digitale Assets und Softwareprojekte beinhalten technische, Markt-, regulatorische und operative Risiken. Benutzer sollten diese Risiken verstehen, bevor sie mit Blockchain-Assets oder Anwendungen interagieren.',
    '17_b1': 'Kryptowährungsmärkte können sehr volatil sein.',
    '17_b2':
        'Blockchain-Transaktionen können irreversible Aktionen beinhalten.',
    '17_b3':
        'Software kann Fehler oder technische Einschränkungen enthalten.',
    '17_b4':
        'Blockchain- und regulatorische Rahmenbedingungen können sich ändern.',
    '17_b5': 'Zukünftige Roadmap-Punkte sind nicht garantiert.',
    '17_b6':
        'Virtuelle In-App-Belohnungen sollten nicht als garantierte finanzielle Rendite verstanden werden.',

    '18_title': '18 • HAFTUNGSAUSSCHLUSS',
    '18_text':
        'Stelluriini und STL werden als gemeinschaftsorientiertes digitales Projekt präsentiert. Die Informationen in diesem Dokument dienen ausschließlich Informationszwecken und stellen keine Finanz-, Anlage-, Rechts- oder Steuerberatung dar.',
    '18_text2':
        'Virtuelle Punkte in der Anwendung sollten nicht als garantierter Kryptowährungswert oder garantierte finanzielle Rendite verstanden werden.',

    '19_title': 'Offizielle Informationen',
    '19_text':
        'Die offizielle Stelluriini-Anwendung sollte zusammen mit verifizierten Projektinformationen verwendet werden. Token-Adressen sollten vor Interaktionen mit Blockchain-Assets immer überprüft werden.',
    '19_mint': 'STELLURIINI MINT',

    'closing': '🐱 Stella fängt gerade erst an.',
    'closingSub': 'Community • Neugier • Kreativität • Solana',
    'footer': '🐾 STELLA • STELLURIINI • STL • SOLANA 🐾',
    'footerSupply': '17 602 539 062 STL',
    'footerVersion': 'WHITEPAPER v1.0',
  },

  // ==========================================================
  // SPANISH
  // ==========================================================

  'es': {
    'pageTitle': 'LIBRO BLANCO',
    'communityToken': '🐾 TOKEN COMUNITARIO DE SOLANA 🐾',
    'whitePaper': 'LIBRO BLANCO',
    'version': 'Versión 1.0',

    '01_title': 'Resumen ejecutivo',
    '01_text':
        'Stelluriini es un proyecto digital impulsado por la comunidad construido alrededor de Stella, una gata curiosa que representa creatividad, comunidad y exploración. STL es el token del proyecto en la cadena de bloques Solana. La aplicación Stelluriini combina la identidad de Stella, mecánicas de recompensas estilo minería, actividades diarias e información sobre el ecosistema STL.',

    '02_title': 'Visión',
    '02_text':
        'La visión de Stelluriini es crear un ecosistema digital reconocible y centrado en la comunidad donde Stella esté en el centro de la experiencia.',
    '02_b1': 'Construir una identidad Stella fuerte y reconocible.',
    '02_b2':
        'Crear aplicaciones y experiencias digitales atractivas.',
    '02_b3': 'Hacer crecer una comunidad activa y acogedora.',
    '02_b4':
        'Desarrollar funciones útiles y entretenidas para el ecosistema STL.',
    '02_b5':
        'Explorar juegos, aplicaciones e integraciones futuras con Solana.',

    '03_title': '¿Qué es Stelluriini?',
    '03_text':
        'Stelluriini es más que un nombre de token. Es una identidad de proyecto construida alrededor de Stella y una experiencia digital orientada a la comunidad.',
    '03_f1_title': 'Stella',
    '03_f1_desc':
        'La mascota visual y la identidad reconocible del proyecto.',
    '03_f2_title': 'STL',
    '03_f2_desc':
        'El token Stelluriini asociado al ecosistema Solana.',
    '03_f3_title': 'Aplicación',
    '03_f3_desc':
        'Una experiencia móvil con recompensas estilo minería, actividades diarias e información del proyecto.',
    '03_f4_title': 'Comunidad',
    '03_f4_desc':
        'Un entorno centrado en la comunidad donde las futuras funciones pueden desarrollarse juntos.',

    '04_title': 'Stella',
    '04_heading': 'Stella es el corazón de Stelluriini.',
    '04_text':
        'Stella representa curiosidad, amabilidad y exploración. Su función es hacer reconocible la experiencia Stelluriini y proporcionar una identidad coherente para la aplicación, la comunidad y el futuro ecosistema.',

    '05_title': 'Token STL',
    '05_name': 'Nombre del token',
    '05_symbol': 'Símbolo',
    '05_blockchain': 'Blockchain',
    '05_supply': 'Suministro total',
    '05_decimals': 'Decimales',
    '05_mint': 'Dirección Mint',

    '06_title': 'Tokenómica',
    '06_text':
        'La asignación prevista de STL está diseñada para apoyar recompensas comunitarias, liquidez, crecimiento del ecosistema, desarrollo y marketing.',
    '06_a1': 'Comunidad y recompensas',
    '06_a2': 'Liquidez',
    '06_a3': 'Ecosistema',
    '06_a4': 'Desarrollo',
    '06_a5': 'Marketing',
    '06_total': 'Asignación total: 17 602 539 062 STL',

    '07_title': 'Stella Mining',
    '07_text':
        'La aplicación Stelluriini incluye un sistema de recompensas estilo minería. Está diseñado como una mecánica de progreso dentro de la aplicación donde los usuarios acumulan puntos STL virtuales durante un ciclo de minería.',
    '07_f1_title': 'Hash Rate',
    '07_f1_desc':
        'El hash rate del usuario determina la velocidad a la que se acumulan los puntos virtuales.',
    '07_f2_title': 'Ciclo de minería',
    '07_f2_desc':
        'Un ciclo de minería funciona durante un período definido antes de poder reclamar la recompensa acumulada.',
    '07_f3_title': 'Cálculo de recompensa',
    '07_f3_desc':
        'La recompensa virtual se calcula según el hash rate y el tiempo de minería transcurrido.',
    '07_f4_title': 'Tasa de minería bloqueada',
    '07_f4_desc':
        'El hash rate utilizado por un ciclo de minería activo permanece estable durante ese ciclo.',

    '08_title': 'Bono diario',
    '08_text':
        'El bono diario fomenta la participación regular en la aplicación Stelluriini. Un registro diario exitoso puede aumentar el hash rate del usuario y contribuir a una racha consecutiva.',
    '08_b1':
        'El registro diario está limitado a una reclamación exitosa por día.',
    '08_b2':
        'La racha consecutiva puede mantenerse regresando los días siguientes.',
    '08_b3':
        'El bono afecta al hash rate utilizado para futuros ciclos de minería.',

    '09_title': 'Stella Power Boost',
    '09_text':
        'El sistema Stella Power Boost permite recibir un bono adicional de hash rate mediante anuncios recompensados. Existen límites y períodos de espera para ayudar a prevenir abusos.',
    '09_f1_title': 'Anuncios recompensados',
    '09_f1_desc':
        'Los usuarios pueden recibir un bono de hash rate dentro de la aplicación después de ver un anuncio recompensado válido.',
    '09_f2_title': 'Enfriamiento',
    '09_f2_desc':
        'Un período de espera limita la frecuencia con la que se puede reclamar una recompensa publicitaria.',
    '09_f3_title': 'Límite diario',
    '09_f3_desc':
        'Cada día se puede contabilizar un número máximo de anuncios recompensados.',

    '10_title': 'Arquitectura de la aplicación',
    '10_text':
        'La aplicación Stelluriini está diseñada alrededor de un cliente móvil y servicios del lado del servidor que gestionan operaciones de recompensas autenticadas e historial de transacciones.',
    '10_b1_title': 'Aplicación Flutter',
    '10_b1_desc':
        'Interfaz de usuario, experiencia Stella, panel de minería e información del proyecto.',
    '10_b2_title': 'Servicios Firebase',
    '10_b2_desc':
        'Autenticación, datos de Firestore y Cloud Functions del servidor.',
    '10_b3_title': 'Validación del servidor',
    '10_b3_desc':
        'Límites de recompensas, períodos de espera, protección contra duplicados y operaciones autenticadas.',
    '10_b4_title': 'Solana / STL',
    '10_b4_desc':
        'El token Stelluriini existe como activo en la cadena de bloques Solana.',

    '11_title': 'Historial de transacciones',
    '11_text':
        'La aplicación proporciona una vista del historial donde se puede mostrar al usuario la actividad de recompensas registrada.',
    '11_b1': 'Actividad de recompensas de minería.',
    '11_b2': 'Actividad de recompensas diarias.',
    '11_b3': 'Actividad de anuncios recompensados.',
    '11_b4': 'Saldo después de una recompensa registrada.',
    '11_b5': 'Fecha y tipo de actividad.',

    '12_title': 'Seguridad y prevención de abusos',
    '12_text':
        'La aplicación Stelluriini utiliza validación del lado del servidor para reducir la manipulación de las operaciones de recompensa. Los mecanismos de seguridad están destinados a proteger la integridad de la aplicación y su sistema de recompensas.',
    '12_f1_title': 'Autenticación',
    '12_f1_desc':
        'Las operaciones de recompensa requieren una sesión de usuario autenticada.',
    '12_f2_title': 'Protección contra duplicados',
    '12_f2_desc':
        'Las transacciones de recompensa pueden protegerse contra procesamiento repetido.',
    '12_f3_title': 'Límites de frecuencia',
    '12_f3_desc':
        'Los límites diarios y períodos de espera ayudan a reducir los abusos automatizados.',
    '12_f4_title': 'Validación de recompensas',
    '12_f4_desc':
        'La lógica del servidor valida condiciones importantes antes de registrar las recompensas.',

    '13_title': 'Comunidad',
    '13_text':
        'La participación de la comunidad es una parte importante de la visión de Stelluriini. El proyecto busca crear un entorno donde los usuarios puedan seguir el progreso, aportar comentarios y participar en futuras actividades del ecosistema.',
    '13_b1':
        'Los comentarios de la comunidad pueden influir en el desarrollo futuro.',
    '13_b2':
        'Las futuras funciones comunitarias pueden ampliar el papel de STL.',
    '13_b3':
        'La transparencia seguirá siendo un principio importante del proyecto.',

    '14_title': 'Futuro ecosistema',
    '14_text':
        'El futuro ecosistema Stelluriini puede expandirse más allá de la aplicación actual. Las posibles direcciones incluyen nuevas experiencias de Stella, juegos, aplicaciones, funciones comunitarias e integraciones adicionales con Solana.',
    '14_f1_title': 'Juegos de Stella',
    '14_f1_desc':
        'Explorar juegos y experiencias interactivas protagonizadas por Stella.',
    '14_f2_title': 'Nuevas aplicaciones',
    '14_f2_desc':
        'Desarrollar productos y servicios digitales adicionales alrededor de Stelluriini.',
    '14_f3_title': 'Integraciones STL',
    '14_f3_desc':
        'Explorar integraciones útiles relacionadas con STL y el ecosistema Solana.',
    '14_f4_title': 'Actividades comunitarias',
    '14_f4_desc':
        'Posibles eventos, desafíos y experiencias de recompensas centradas en la comunidad.',

    '15_title': 'Hoja de ruta',
    '15_p1_title': 'El comienzo',
    '15_p1_status': 'EN PROGRESO',
    '15_p1_desc':
        'Establecer la identidad Stelluriini, desarrollar la marca Stella, construir la aplicación y preparar la información de STL.',
    '15_p2_title': 'Comunidad',
    '15_p2_status': 'PLANIFICADO',
    '15_p2_desc':
        'Hacer crecer la comunidad, mejorar el soporte de idiomas y desarrollar actividades y funciones comunitarias.',
    '15_p3_title': 'Ecosistema STL',
    '15_p3_status': 'FUTURO',
    '15_p3_desc':
        'Ampliar la funcionalidad del ecosistema STL, la información blockchain, las estadísticas y otras funciones Stelluriini.',
    '15_p4_title': 'El futuro',
    '15_p4_status': 'FUTURO',
    '15_p4_desc':
        'Continuar el desarrollo del ecosistema, introducir nuevas experiencias Stella y explorar nuevas posibilidades para STL.',

    '16_title': 'Transparencia',
    '16_text':
        'Stelluriini busca distinguir claramente las funciones existentes de los planes futuros. La documentación pretende describir el estado actual del proyecto y su dirección prevista con la mayor precisión posible.',
    '16_b1': 'El suministro total de STL está documentado.',
    '16_b2': 'La estructura de asignación del token está documentada.',
    '16_b3':
        'La funcionalidad actual se describe por separado de los planes futuros.',
    '16_b4':
        'Las prioridades de la hoja de ruta pueden cambiar durante el desarrollo.',

    '17_title': 'Riesgos y limitaciones',
    '17_text':
        'Los activos digitales y los proyectos de software implican riesgos técnicos, de mercado, regulatorios y operativos. Los usuarios deben comprender estos riesgos antes de interactuar con cualquier activo o aplicación basada en blockchain.',
    '17_b1': 'Los mercados de criptomonedas pueden ser muy volátiles.',
    '17_b2':
        'Las transacciones blockchain pueden implicar acciones irreversibles.',
    '17_b3':
        'El software puede contener errores o limitaciones técnicas.',
    '17_b4':
        'Los entornos blockchain y regulatorios pueden cambiar.',
    '17_b5': 'Los elementos futuros de la hoja de ruta no están garantizados.',
    '17_b6':
        'Las recompensas virtuales dentro de la aplicación no deben interpretarse como rendimientos financieros garantizados.',

    '18_title': '18 • DESCARGO DE RESPONSABILIDAD',
    '18_text':
        'Stelluriini y STL se presentan como un proyecto digital impulsado por la comunidad. La información de este documento se proporciona únicamente con fines informativos y no constituye asesoramiento financiero, de inversión, legal o fiscal.',
    '18_text2':
        'Los puntos virtuales mostrados en la aplicación no deben interpretarse como un valor garantizado de criptomonedas ni como rendimientos financieros garantizados.',

    '19_title': 'Información oficial',
    '19_text':
        'La aplicación oficial de Stelluriini debe utilizarse junto con información verificada del proyecto. Verifica siempre las direcciones de los tokens antes de interactuar con activos blockchain.',
    '19_mint': 'STELLURIINI MINT',

    'closing': '🐱 Stella acaba de comenzar.',
    'closingSub': 'Comunidad • Curiosidad • Creatividad • Solana',
    'footer': '🐾 STELLA • STELLURIINI • STL • SOLANA 🐾',
    'footerSupply': '17 602 539 062 STL',
    'footerVersion': 'LIBRO BLANCO v1.0',
  },

  // ==========================================================
  // FRENCH
  // ==========================================================

  'fr': {
    'pageTitle': 'LIVRE BLANC',
    'communityToken': '🐾 TOKEN COMMUNAUTAIRE SOLANA 🐾',
    'whitePaper': 'LIVRE BLANC',
    'version': 'Version 1.0',

    '01_title': 'Résumé exécutif',
    '01_text':
        'Stelluriini est un projet numérique communautaire construit autour de Stella, une chatte curieuse représentant la créativité, la communauté et l’exploration. STL est le token du projet sur la blockchain Solana. L’application Stelluriini combine l’identité de Stella, des mécanismes de récompense inspirés du minage, des activités quotidiennes et des informations sur l’écosystème STL.',

    '02_title': 'Vision',
    '02_text':
        'La vision de Stelluriini est de créer un écosystème numérique reconnaissable et axé sur la communauté où Stella est au centre de l’expérience.',
    '02_b1': 'Construire une identité Stella forte et reconnaissable.',
    '02_b2':
        'Créer des applications et expériences numériques engageantes.',
    '02_b3': 'Développer une communauté active et accueillante.',
    '02_b4':
        'Développer des fonctionnalités utiles et divertissantes pour l’écosystème STL.',
    '02_b5':
        'Explorer les jeux, applications et futures intégrations Solana.',

    '03_title': 'Qu’est-ce que Stelluriini ?',
    '03_text':
        'Stelluriini est plus qu’un nom de token. C’est une identité de projet construite autour de Stella et une expérience numérique orientée communauté.',
    '03_f1_title': 'Stella',
    '03_f1_desc':
        'La mascotte visuelle et l’identité reconnaissable du projet.',
    '03_f2_title': 'STL',
    '03_f2_desc':
        'Le token Stelluriini associé à l’écosystème Solana.',
    '03_f3_title': 'Application',
    '03_f3_desc':
        'Une expérience mobile comprenant des récompenses inspirées du minage, des activités quotidiennes et des informations sur le projet.',
    '03_f4_title': 'Communauté',
    '03_f4_desc':
        'Un environnement communautaire où les futures fonctionnalités peuvent être développées ensemble.',

    '04_title': 'Stella',
    '04_heading': 'Stella est le cœur de Stelluriini.',
    '04_text':
        'Stella représente la curiosité, la gentillesse et l’exploration. Son rôle est de rendre l’expérience Stelluriini reconnaissable et de fournir une identité cohérente à l’application, à la communauté et au futur écosystème.',

    '05_title': 'Token STL',
    '05_name': 'Nom du token',
    '05_symbol': 'Symbole',
    '05_blockchain': 'Blockchain',
    '05_supply': 'Offre totale',
    '05_decimals': 'Décimales',
    '05_mint': 'Adresse Mint',

    '06_title': 'Tokenomics',
    '06_text':
        'L’allocation prévue de STL est conçue pour soutenir les récompenses communautaires, la liquidité, la croissance de l’écosystème, le développement et le marketing.',
    '06_a1': 'Communauté & récompenses',
    '06_a2': 'Liquidité',
    '06_a3': 'Écosystème',
    '06_a4': 'Développement',
    '06_a5': 'Marketing',
    '06_total': 'Allocation totale : 17 602 539 062 STL',

    '07_title': 'Stella Mining',
    '07_text':
        'L’application Stelluriini comprend un système de récompense inspiré du minage. Il est conçu comme une mécanique de progression dans l’application où les utilisateurs accumulent des points STL virtuels pendant un cycle de minage.',
    '07_f1_title': 'Hash Rate',
    '07_f1_desc':
        'Le hash rate de l’utilisateur détermine la vitesse à laquelle les points virtuels sont accumulés.',
    '07_f2_title': 'Cycle de minage',
    '07_f2_desc':
        'Un cycle de minage fonctionne pendant une période définie avant que la récompense accumulée puisse être réclamée.',
    '07_f3_title': 'Calcul de la récompense',
    '07_f3_desc':
        'La récompense virtuelle est calculée selon le hash rate et le temps de minage écoulé.',
    '07_f4_title': 'Taux de minage verrouillé',
    '07_f4_desc':
        'Le hash rate utilisé par un cycle de minage actif reste stable pendant ce cycle.',

    '08_title': 'Bonus quotidien',
    '08_text':
        'Le bonus quotidien encourage une participation régulière à l’application Stelluriini. Une connexion quotidienne réussie peut augmenter le hash rate de l’utilisateur et contribuer à une série de jours consécutifs.',
    '08_b1':
        'La connexion quotidienne est limitée à une réclamation réussie par jour.',
    '08_b2':
        'Une série consécutive peut être maintenue en revenant les jours suivants.',
    '08_b3':
        'Le bonus influence le hash rate utilisé pour les futurs cycles de minage.',

    '09_title': 'Stella Power Boost',
    '09_text':
        'Le système Stella Power Boost permet de recevoir un bonus supplémentaire de hash rate grâce aux publicités récompensées. Des limites et des périodes d’attente aident à réduire les abus.',
    '09_f1_title': 'Publicités récompensées',
    '09_f1_desc':
        'Les utilisateurs peuvent recevoir un bonus de hash rate dans l’application après une publicité récompensée valide.',
    '09_f2_title': 'Temps de recharge',
    '09_f2_desc':
        'Une période de recharge limite la fréquence à laquelle une récompense publicitaire peut être réclamée.',
    '09_f3_title': 'Limite quotidienne',
    '09_f3_desc':
        'Un nombre maximum de publicités récompensées peut être comptabilisé chaque jour.',

    '10_title': 'Architecture de l’application',
    '10_text':
        'L’application Stelluriini est conçue autour d’un client mobile et de services côté serveur qui gèrent les opérations de récompense authentifiées et l’historique des transactions.',
    '10_b1_title': 'Application Flutter',
    '10_b1_desc':
        'Interface utilisateur, expérience Stella, tableau de bord de minage et informations du projet.',
    '10_b2_title': 'Services Firebase',
    '10_b2_desc':
        'Authentification, données Firestore et Cloud Functions côté serveur.',
    '10_b3_title': 'Validation côté serveur',
    '10_b3_desc':
        'Limites de récompense, temps de recharge, protection contre les doublons et opérations authentifiées.',
    '10_b4_title': 'Solana / STL',
    '10_b4_desc':
        'Le token Stelluriini existe comme actif sur la blockchain Solana.',

    '11_title': 'Historique des transactions',
    '11_text':
        'L’application fournit une vue de l’historique des transactions où les activités de récompense enregistrées peuvent être affichées à l’utilisateur.',
    '11_b1': 'Activité des récompenses de minage.',
    '11_b2': 'Activité des récompenses quotidiennes.',
    '11_b3': 'Activité des publicités récompensées.',
    '11_b4': 'Solde après une récompense enregistrée.',
    '11_b5': 'Date et type d’activité.',

    '12_title': 'Sécurité & prévention des abus',
    '12_text':
        'L’application Stelluriini utilise une validation côté serveur pour réduire la manipulation des opérations de récompense. Les mécanismes de sécurité visent à protéger l’intégrité de l’application et de son système de récompenses.',
    '12_f1_title': 'Authentification',
    '12_f1_desc':
        'Les opérations de récompense nécessitent une session utilisateur authentifiée.',
    '12_f2_title': 'Protection contre les doublons',
    '12_f2_desc':
        'Les transactions de récompense peuvent être protégées contre les traitements répétés.',
    '12_f3_title': 'Limites de fréquence',
    '12_f3_desc':
        'Les limites quotidiennes et les périodes de recharge contribuent à réduire les abus automatisés.',
    '12_f4_title': 'Validation des récompenses',
    '12_f4_desc':
        'La logique serveur valide les conditions importantes avant leur enregistrement.',

    '13_title': 'Communauté',
    '13_text':
        'La participation de la communauté est une partie importante de la vision de Stelluriini. Le projet souhaite développer un environnement où les utilisateurs peuvent suivre les progrès, donner leur avis et participer aux futures activités de l’écosystème.',
    '13_b1':
        'Les retours de la communauté peuvent influencer le développement futur.',
    '13_b2':
        'Les futures fonctionnalités communautaires peuvent élargir le rôle de STL.',
    '13_b3':
        'La transparence doit rester un principe important du projet.',

    '14_title': 'Futur écosystème',
    '14_text':
        'Le futur écosystème Stelluriini pourrait s’étendre au-delà de l’application actuelle. Les directions possibles incluent de nouvelles expériences Stella, des jeux, des applications, des fonctionnalités communautaires et des intégrations Solana supplémentaires.',
    '14_f1_title': 'Jeux Stella',
    '14_f1_desc':
        'Explorer des jeux et expériences interactives mettant Stella en vedette.',
    '14_f2_title': 'Nouvelles applications',
    '14_f2_desc':
        'Développer des produits et services numériques supplémentaires autour de Stelluriini.',
    '14_f3_title': 'Intégrations STL',
    '14_f3_desc':
        'Explorer des intégrations utiles impliquant STL et l’écosystème Solana.',
    '14_f4_title': 'Activités communautaires',
    '14_f4_desc':
        'Événements, défis et expériences de récompense potentiels axés sur la communauté.',

    '15_title': 'Feuille de route',
    '15_p1_title': 'Le début',
    '15_p1_status': 'EN COURS',
    '15_p1_desc':
        'Établir l’identité Stelluriini, développer la marque Stella, construire l’application et préparer les informations STL.',
    '15_p2_title': 'Communauté',
    '15_p2_status': 'PLANIFIÉ',
    '15_p2_desc':
        'Développer la communauté, améliorer le support linguistique et créer des activités et fonctionnalités communautaires.',
    '15_p3_title': 'Écosystème STL',
    '15_p3_status': 'FUTUR',
    '15_p3_desc':
        'Étendre les fonctionnalités de l’écosystème STL, les informations blockchain, les statistiques et les autres fonctions Stelluriini.',
    '15_p4_title': 'Le futur',
    '15_p4_status': 'FUTUR',
    '15_p4_desc':
        'Poursuivre le développement de l’écosystème, introduire de nouvelles expériences Stella et explorer de nouvelles possibilités pour STL.',

    '16_title': 'Transparence',
    '16_text':
        'Stelluriini souhaite distinguer clairement les fonctionnalités existantes des projets futurs. La documentation vise à décrire l’état actuel du projet et sa direction prévue aussi précisément que possible.',
    '16_b1': 'L’offre totale de STL est documentée.',
    '16_b2': 'La structure d’allocation du token est documentée.',
    '16_b3':
        'Les fonctionnalités actuelles sont décrites séparément des projets futurs.',
    '16_b4':
        'Les priorités de la feuille de route peuvent changer pendant le développement.',

    '17_title': 'Risques & limitations',
    '17_text':
        'Les actifs numériques et les projets logiciels comportent des risques techniques, de marché, réglementaires et opérationnels. Les utilisateurs doivent comprendre ces risques avant d’interagir avec un actif ou une application blockchain.',
    '17_b1': 'Les marchés des cryptomonnaies peuvent être très volatils.',
    '17_b2':
        'Les transactions blockchain peuvent impliquer des actions irréversibles.',
    '17_b3':
        'Les logiciels peuvent contenir des bugs ou des limitations techniques.',
    '17_b4':
        'Les environnements blockchain et réglementaires peuvent changer.',
    '17_b5': 'Les éléments futurs de la feuille de route ne sont pas garantis.',
    '17_b6':
        'Les récompenses virtuelles de l’application ne doivent pas être interprétées comme des rendements financiers garantis.',

    '18_title': '18 • AVIS DE NON-RESPONSABILITÉ',
    '18_text':
        'Stelluriini et STL sont présentés comme un projet numérique communautaire. Les informations de ce document sont fournies uniquement à titre informatif et ne constituent pas un conseil financier, d’investissement, juridique ou fiscal.',
    '18_text2':
        'Les points virtuels affichés dans l’application ne doivent pas être interprétés comme une valeur garantie en cryptomonnaie ou comme des rendements financiers garantis.',

    '19_title': 'Informations officielles',
    '19_text':
        'L’application officielle Stelluriini doit être utilisée avec des informations de projet vérifiées. Vérifiez toujours les adresses des tokens avant toute interaction avec des actifs blockchain.',
    '19_mint': 'STELLURIINI MINT',

    'closing': '🐱 Stella ne fait que commencer.',
    'closingSub': 'Communauté • Curiosité • Créativité • Solana',
    'footer': '🐾 STELLA • STELLURIINI • STL • SOLANA 🐾',
    'footerSupply': '17 602 539 062 STL',
    'footerVersion': 'LIVRE BLANC v1.0',
  },

  // ==========================================================
  // CHINESE
  // ==========================================================

  'zh': {
    'pageTitle': '白皮书',
    'communityToken': '🐾 SOLANA 社区代币 🐾',
    'whitePaper': '白皮书',
    'version': '版本 1.0',

    '01_title': '执行摘要',
    '01_text':
        'Stelluriini 是一个以 Stella 这只充满好奇心的猫为核心的社区驱动数字项目。Stella 代表创造力、社区和探索。STL 是该项目在 Solana 区块链上的代币。Stelluriini 应用结合了 Stella 品牌、挖矿式奖励机制、每日活动以及 STL 生态系统信息。',

    '02_title': '愿景',
    '02_text':
        'Stelluriini 的愿景是建立一个具有辨识度、以社区为核心的数字生态系统，让 Stella 成为整个体验的中心。',
    '02_b1': '建立强大且具有辨识度的 Stella 品牌。',
    '02_b2': '创建有吸引力的应用和数字体验。',
    '02_b3': '发展积极且友好的社区。',
    '02_b4': '开发实用且有趣的 STL 生态系统功能。',
    '02_b5': '探索游戏、应用以及未来的 Solana 集成。',

    '03_title': '什么是 Stelluriini？',
    '03_text':
        'Stelluriini 不只是一个代币名称。它是围绕 Stella 建立的项目身份，也是一个以社区为核心的数字体验。',
    '03_f1_title': 'Stella',
    '03_f1_desc': '项目的视觉吉祥物和标志性身份。',
    '03_f2_title': 'STL',
    '03_f2_desc': '与 Solana 生态系统相关的 Stelluriini 代币。',
    '03_f3_title': '应用',
    '03_f3_desc': '包含挖矿式奖励、每日活动和项目资讯的移动应用体验。',
    '03_f4_title': '社区',
    '03_f4_desc': '一个可以共同开发未来功能的社区环境。',

    '04_title': 'Stella',
    '04_heading': 'Stella 是 Stelluriini 的核心。',
    '04_text':
        'Stella 代表好奇、友善和探索。她让 Stelluriini 的体验具有辨识度，并为应用、社区以及未来生态系统提供统一的品牌形象。',

    '05_title': 'STL 代币',
    '05_name': '代币名称',
    '05_symbol': '符号',
    '05_blockchain': '区块链',
    '05_supply': '总供应量',
    '05_decimals': '小数位',
    '05_mint': 'Mint 地址',

    '06_title': '代币经济学',
    '06_text':
        'STL 的计划分配用于支持社区奖励、流动性、生态系统增长、开发和市场推广。',
    '06_a1': '社区与奖励',
    '06_a2': '流动性',
    '06_a3': '生态系统',
    '06_a4': '开发',
    '06_a5': '市场推广',
    '06_total': '总分配量：17 602 539 062 STL',

    '07_title': 'Stella 挖矿',
    '07_text':
        'Stelluriini 应用包含挖矿式奖励系统。该系统被设计为应用内成长机制，用户可以在挖矿周期中积累虚拟 STL 积分。',
    '07_f1_title': '哈希率',
    '07_f1_desc': '用户的哈希率决定虚拟挖矿积分的累积速度。',
    '07_f2_title': '挖矿周期',
    '07_f2_desc': '挖矿周期持续指定时间，周期结束后可以领取累计奖励。',
    '07_f3_title': '奖励计算',
    '07_f3_desc': '虚拟奖励根据哈希率和经过的挖矿时间计算。',
    '07_f4_title': '锁定挖矿速率',
    '07_f4_desc': '活动挖矿周期使用的哈希率在该周期内保持稳定。',

    '08_title': '每日奖励',
    '08_text':
        '每日奖励鼓励用户定期参与 Stelluriini 应用。成功完成每日签到可以提高用户哈希率，并形成连续签到天数。',
    '08_b1': '每日签到每天最多成功领取一次。',
    '08_b2': '连续天数可以通过连续返回应用来保持。',
    '08_b3': '奖励会影响未来挖矿周期使用的用户哈希率。',

    '09_title': 'Stella Power Boost',
    '09_text':
        'Stella Power Boost 系统允许用户通过观看奖励广告获得额外哈希率奖励。系统包含限制和冷却规则，以帮助防止滥用。',
    '09_f1_title': '奖励广告',
    '09_f1_desc': '用户观看符合条件的奖励广告后可以获得应用内哈希率奖励。',
    '09_f2_title': '冷却时间',
    '09_f2_desc': '冷却时间限制广告奖励的领取频率。',
    '09_f3_title': '每日限制',
    '09_f3_desc': '每天最多可以计算指定数量的奖励广告。',

    '10_title': '应用架构',
    '10_text':
        'Stelluriini 应用由移动客户端和服务器端服务组成，用于处理经过身份验证的奖励操作和交易历史。',
    '10_b1_title': 'Flutter 应用',
    '10_b1_desc': '用户界面、Stella 体验、挖矿面板和项目信息。',
    '10_b2_title': 'Firebase 服务',
    '10_b2_desc': '身份验证、Firestore 数据以及服务器端 Cloud Functions。',
    '10_b3_title': '服务器端验证',
    '10_b3_desc': '奖励限制、冷却时间、防重复处理以及经过身份验证的操作。',
    '10_b4_title': 'Solana / STL',
    '10_b4_desc': 'Stelluriini 代币作为资产存在于 Solana 区块链上。',

    '11_title': '交易历史',
    '11_text':
        '应用提供交易历史页面，可以向用户显示已经记录的奖励活动。',
    '11_b1': '挖矿奖励活动。',
    '11_b2': '每日奖励活动。',
    '11_b3': '奖励广告活动。',
    '11_b4': '记录奖励后的余额。',
    '11_b5': '交易日期和活动类型。',

    '12_title': '安全与防滥用',
    '12_text':
        'Stelluriini 应用使用服务器端验证来减少奖励操作被篡改的风险。安全机制旨在保护应用及奖励系统的完整性。',
    '12_f1_title': '身份验证',
    '12_f1_desc': '奖励操作需要经过身份验证的用户会话。',
    '12_f2_title': '重复保护',
    '12_f2_desc': '奖励交易可以防止重复处理。',
    '12_f3_title': '速率限制',
    '12_f3_desc': '每日限制和冷却时间有助于减少自动化滥用。',
    '12_f4_title': '奖励验证',
    '12_f4_desc': '服务器端逻辑会在记录奖励之前验证重要条件。',

    '13_title': '社区',
    '13_text':
        '社区参与是 Stelluriini 愿景的重要组成部分。项目希望建立一个用户可以关注进展、提供反馈并参与未来生态活动的环境。',
    '13_b1': '社区反馈可以影响未来开发。',
    '13_b2': '未来的社区功能可能扩展 STL 的作用。',
    '13_b3': '透明度将继续作为重要的项目原则。',

    '14_title': '未来生态系统',
    '14_text':
        '未来的 Stelluriini 生态系统可能扩展到当前应用之外。潜在方向包括新的 Stella 体验、游戏、应用、社区功能以及更多 Solana 集成。',
    '14_f1_title': 'Stella 游戏',
    '14_f1_desc': '探索以 Stella 为主题的游戏和互动体验。',
    '14_f2_title': '新应用',
    '14_f2_desc': '围绕 Stelluriini 身份开发更多数字产品和服务。',
    '14_f3_title': 'STL 集成',
    '14_f3_desc': '探索 STL 与 Solana 生态系统之间的实用集成。',
    '14_f4_title': '社区活动',
    '14_f4_desc': '潜在的活动、挑战和社区奖励体验。',

    '15_title': '路线图',
    '15_p1_title': '开始',
    '15_p1_status': '进行中',
    '15_p1_desc':
        '建立 Stelluriini 身份、开发 Stella 品牌、构建应用并准备 STL 信息。',
    '15_p2_title': '社区',
    '15_p2_status': '计划中',
    '15_p2_desc':
        '扩大社区、改善语言支持、开发每日活动和社区功能。',
    '15_p3_title': 'STL 生态系统',
    '15_p3_status': '未来',
    '15_p3_desc':
        '扩展 STL 生态功能、区块链信息、统计数据和其他 Stelluriini 功能。',
    '15_p4_title': '未来',
    '15_p4_status': '未来',
    '15_p4_desc':
        '继续开发生态系统，引入新的 Stella 体验并探索 STL 的新可能性。',

    '16_title': '透明度',
    '16_text':
        'Stelluriini 致力于清楚地区分现有功能与未来计划。项目文档旨在尽可能准确地描述项目当前状态和未来方向。',
    '16_b1': 'STL 总供应量已记录。',
    '16_b2': '代币分配结构已记录。',
    '16_b3': '当前应用功能与未来计划分开说明。',
    '16_b4': '路线图重点可能随着开发进展而改变。',

    '17_title': '风险与限制',
    '17_text':
        '数字资产和软件项目涉及技术、市场、监管和运营风险。用户在使用任何基于区块链的资产或应用之前，应了解这些风险。',
    '17_b1': '加密货币市场可能高度波动。',
    '17_b2': '区块链交易可能涉及不可逆操作。',
    '17_b3': '软件可能存在错误或技术限制。',
    '17_b4': '区块链和监管环境可能发生变化。',
    '17_b5': '未来路线图项目并不保证实现。',
    '17_b6': '应用中的虚拟奖励不应被理解为保证的金融回报。',

    '18_title': '18 • 免责声明',
    '18_text':
        'Stelluriini 和 STL 是一个社区驱动的数字项目。本文件中的信息仅用于提供信息，不构成金融、投资、法律或税务建议。',
    '18_text2':
        '应用中显示的虚拟积分不应被理解为有保证的加密货币价值或有保证的金融回报。',

    '19_title': '官方信息',
    '19_text':
        'Stelluriini 官方应用应与经过验证的项目信息一起使用。在与区块链资产交互之前，请务必验证代币地址。',
    '19_mint': 'STELLURIINI MINT',

    'closing': '🐱 Stella 才刚刚开始。',
    'closingSub': '社区 • 好奇 • 创意 • Solana',
    'footer': '🐾 STELLA • STELLURIINI • STL • SOLANA 🐾',
    'footerSupply': '17 602 539 062 STL',
    'footerVersion': '白皮书 v1.0',
  },

  // ==========================================================
  // VIETNAMESE
  // ==========================================================

  'vi': {
    'pageTitle': 'SÁCH TRẮNG',
    'communityToken': '🐾 TOKEN CỘNG ĐỒNG SOLANA 🐾',
    'whitePaper': 'SÁCH TRẮNG',
    'version': 'Phiên bản 1.0',

    '01_title': 'Tóm tắt',
    '01_text':
        'Stelluriini là một dự án kỹ thuật số do cộng đồng xây dựng xoay quanh Stella, một chú mèo tò mò đại diện cho sự sáng tạo, cộng đồng và khám phá. STL là token của dự án trên blockchain Solana. Ứng dụng Stelluriini kết hợp thương hiệu Stella, cơ chế phần thưởng kiểu khai thác, hoạt động hàng ngày và thông tin về hệ sinh thái STL.',

    '02_title': 'Tầm nhìn',
    '02_text':
        'Tầm nhìn của Stelluriini là tạo ra một hệ sinh thái kỹ thuật số dễ nhận biết và tập trung vào cộng đồng, nơi Stella là trung tâm của trải nghiệm.',
    '02_b1': 'Xây dựng bản sắc Stella mạnh mẽ và dễ nhận biết.',
    '02_b2': 'Tạo các ứng dụng và trải nghiệm kỹ thuật số hấp dẫn.',
    '02_b3': 'Phát triển một cộng đồng tích cực và thân thiện.',
    '02_b4':
        'Phát triển các tính năng hữu ích và thú vị cho hệ sinh thái STL.',
    '02_b5':
        'Khám phá trò chơi, ứng dụng và các tích hợp Solana trong tương lai.',

    '03_title': 'Stelluriini là gì?',
    '03_text':
        'Stelluriini không chỉ là tên của một token. Đây là bản sắc dự án được xây dựng xoay quanh Stella và một trải nghiệm kỹ thuật số hướng đến cộng đồng.',
    '03_f1_title': 'Stella',
    '03_f1_desc':
        'Linh vật trực quan và bản sắc dễ nhận biết của dự án.',
    '03_f2_title': 'STL',
    '03_f2_desc':
        'Token Stelluriini gắn liền với hệ sinh thái Solana.',
    '03_f3_title': 'Ứng dụng',
    '03_f3_desc':
        'Trải nghiệm di động với phần thưởng kiểu khai thác, hoạt động hàng ngày và thông tin dự án.',
    '03_f4_title': 'Cộng đồng',
    '03_f4_desc':
        'Môi trường tập trung vào cộng đồng nơi các tính năng tương lai có thể được phát triển cùng nhau.',

    '04_title': 'Stella',
    '04_heading': 'Stella là trái tim của Stelluriini.',
    '04_text':
        'Stella đại diện cho sự tò mò, thân thiện và khám phá. Vai trò của Stella là làm cho trải nghiệm Stelluriini dễ nhận biết và tạo bản sắc thống nhất cho ứng dụng, cộng đồng và hệ sinh thái tương lai.',

    '05_title': 'Token STL',
    '05_name': 'Tên token',
    '05_symbol': 'Ký hiệu',
    '05_blockchain': 'Blockchain',
    '05_supply': 'Tổng nguồn cung',
    '05_decimals': 'Số thập phân',
    '05_mint': 'Địa chỉ Mint',

    '06_title': 'Tokenomics',
    '06_text':
        'Phân bổ STL dự kiến được thiết kế để hỗ trợ phần thưởng cộng đồng, thanh khoản, tăng trưởng hệ sinh thái, phát triển và tiếp thị.',
    '06_a1': 'Cộng đồng & Phần thưởng',
    '06_a2': 'Thanh khoản',
    '06_a3': 'Hệ sinh thái',
    '06_a4': 'Phát triển',
    '06_a5': 'Tiếp thị',
    '06_total': 'Tổng phân bổ: 17 602 539 062 STL',

    '07_title': 'Stella Mining',
    '07_text':
        'Ứng dụng Stelluriini bao gồm hệ thống phần thưởng kiểu khai thác. Hệ thống được thiết kế như một cơ chế tiến trình trong ứng dụng, nơi người dùng tích lũy điểm STL ảo trong một chu kỳ khai thác.',
    '07_f1_title': 'Hash Rate',
    '07_f1_desc':
        'Hash rate của người dùng xác định tốc độ tích lũy điểm khai thác ảo.',
    '07_f2_title': 'Chu kỳ khai thác',
    '07_f2_desc':
        'Một chu kỳ khai thác chạy trong khoảng thời gian xác định trước khi phần thưởng tích lũy có thể được nhận.',
    '07_f3_title': 'Tính phần thưởng',
    '07_f3_desc':
        'Phần thưởng ảo được tính dựa trên hash rate và thời gian khai thác đã trôi qua.',
    '07_f4_title': 'Tốc độ khai thác cố định',
    '07_f4_desc':
        'Hash rate được sử dụng trong chu kỳ khai thác đang hoạt động được giữ ổn định trong chu kỳ đó.',

    '08_title': 'Thưởng hàng ngày',
    '08_text':
        'Thưởng hàng ngày khuyến khích người dùng tham gia thường xuyên vào ứng dụng Stelluriini. Điểm danh hàng ngày thành công có thể tăng hash rate của người dùng và tạo chuỗi ngày liên tiếp.',
    '08_b1':
        'Điểm danh hàng ngày chỉ cho phép nhận thành công một lần mỗi ngày.',
    '08_b2':
        'Chuỗi liên tiếp có thể được duy trì bằng cách quay lại vào các ngày tiếp theo.',
    '08_b3':
        'Phần thưởng ảnh hưởng đến hash rate được sử dụng cho các chu kỳ khai thác trong tương lai.',

    '09_title': 'Stella Power Boost',
    '09_text':
        'Hệ thống Stella Power Boost cho phép người dùng nhận thêm phần thưởng hash rate thông qua quảng cáo có thưởng. Hệ thống có giới hạn và thời gian chờ để giúp ngăn chặn lạm dụng.',
    '09_f1_title': 'Quảng cáo có thưởng',
    '09_f1_desc':
        'Người dùng có thể nhận phần thưởng hash rate trong ứng dụng sau khi xem quảng cáo có thưởng hợp lệ.',
    '09_f2_title': 'Thời gian chờ',
    '09_f2_desc':
        'Thời gian chờ giới hạn tần suất nhận phần thưởng quảng cáo.',
    '09_f3_title': 'Giới hạn hàng ngày',
    '09_f3_desc':
        'Mỗi ngày chỉ có thể tính tối đa một số lượng quảng cáo có thưởng nhất định.',

    '10_title': 'Kiến trúc ứng dụng',
    '10_text':
        'Ứng dụng Stelluriini được xây dựng dựa trên ứng dụng di động và các dịch vụ phía máy chủ để xử lý hoạt động phần thưởng đã xác thực và lịch sử giao dịch.',
    '10_b1_title': 'Ứng dụng Flutter',
    '10_b1_desc':
        'Giao diện người dùng, trải nghiệm Stella, bảng điều khiển khai thác và thông tin dự án.',
    '10_b2_title': 'Dịch vụ Firebase',
    '10_b2_desc':
        'Xác thực, dữ liệu Firestore và Cloud Functions phía máy chủ.',
    '10_b3_title': 'Xác thực phía máy chủ',
    '10_b3_desc':
        'Giới hạn phần thưởng, thời gian chờ, chống trùng lặp và các hoạt động đã xác thực.',
    '10_b4_title': 'Solana / STL',
    '10_b4_desc':
        'Token Stelluriini tồn tại dưới dạng tài sản trên blockchain Solana.',

    '11_title': 'Lịch sử giao dịch',
    '11_text':
        'Ứng dụng cung cấp chế độ xem lịch sử giao dịch, nơi hoạt động phần thưởng đã ghi nhận có thể được hiển thị cho người dùng.',
    '11_b1': 'Hoạt động phần thưởng khai thác.',
    '11_b2': 'Hoạt động phần thưởng hàng ngày.',
    '11_b3': 'Hoạt động quảng cáo có thưởng.',
    '11_b4': 'Số dư sau phần thưởng được ghi nhận.',
    '11_b5': 'Ngày giao dịch và loại hoạt động.',

    '12_title': 'Bảo mật & chống lạm dụng',
    '12_text':
        'Ứng dụng Stelluriini sử dụng xác thực phía máy chủ để giảm việc thao túng các hoạt động phần thưởng. Các cơ chế bảo mật nhằm bảo vệ tính toàn vẹn của ứng dụng và hệ thống phần thưởng.',
    '12_f1_title': 'Xác thực',
    '12_f1_desc':
        'Các hoạt động phần thưởng yêu cầu phiên người dùng đã được xác thực.',
    '12_f2_title': 'Chống trùng lặp',
    '12_f2_desc':
        'Các giao dịch phần thưởng có thể được bảo vệ khỏi việc xử lý lặp lại.',
    '12_f3_title': 'Giới hạn tốc độ',
    '12_f3_desc':
        'Giới hạn hàng ngày và thời gian chờ giúp giảm lạm dụng tự động.',
    '12_f4_title': 'Xác thực phần thưởng',
    '12_f4_desc':
        'Logic phía máy chủ xác minh các điều kiện quan trọng trước khi ghi nhận.',

    '13_title': 'Cộng đồng',
    '13_text':
        'Sự tham gia của cộng đồng là một phần quan trọng trong tầm nhìn Stelluriini. Dự án hướng đến việc phát triển môi trường nơi người dùng có thể theo dõi tiến trình, gửi phản hồi và tham gia các hoạt động hệ sinh thái trong tương lai.',
    '13_b1':
        'Phản hồi cộng đồng có thể ảnh hưởng đến phát triển trong tương lai.',
    '13_b2':
        'Các tính năng cộng đồng tương lai có thể mở rộng vai trò của STL.',
    '13_b3':
        'Tính minh bạch sẽ tiếp tục là một nguyên tắc quan trọng của dự án.',

    '14_title': 'Hệ sinh thái tương lai',
    '14_text':
        'Hệ sinh thái Stelluriini trong tương lai có thể mở rộng vượt ra ngoài ứng dụng hiện tại. Các hướng tiềm năng bao gồm trải nghiệm Stella mới, trò chơi, ứng dụng, tính năng cộng đồng và các tích hợp Solana bổ sung.',
    '14_f1_title': 'Trò chơi Stella',
    '14_f1_desc':
        'Khám phá các trò chơi và trải nghiệm tương tác có Stella.',
    '14_f2_title': 'Ứng dụng mới',
    '14_f2_desc':
        'Phát triển thêm các sản phẩm và dịch vụ kỹ thuật số xoay quanh Stelluriini.',
    '14_f3_title': 'Tích hợp STL',
    '14_f3_desc':
        'Khám phá các tích hợp hữu ích liên quan đến STL và hệ sinh thái Solana.',
    '14_f4_title': 'Hoạt động cộng đồng',
    '14_f4_desc':
        'Các sự kiện, thử thách và trải nghiệm phần thưởng cộng đồng tiềm năng.',

    '15_title': 'Lộ trình',
    '15_p1_title': 'Khởi đầu',
    '15_p1_status': 'ĐANG THỰC HIỆN',
    '15_p1_desc':
        'Thiết lập bản sắc Stelluriini, phát triển thương hiệu Stella, xây dựng ứng dụng và chuẩn bị thông tin STL.',
    '15_p2_title': 'Cộng đồng',
    '15_p2_status': 'ĐÃ LÊN KẾ HOẠCH',
    '15_p2_desc':
        'Phát triển cộng đồng, cải thiện hỗ trợ ngôn ngữ, phát triển hoạt động hàng ngày và tính năng cộng đồng.',
    '15_p3_title': 'Hệ sinh thái STL',
    '15_p3_status': 'TƯƠNG LAI',
    '15_p3_desc':
        'Mở rộng chức năng hệ sinh thái STL, thông tin blockchain, thống kê và các tính năng Stelluriini bổ sung.',
    '15_p4_title': 'Tương lai',
    '15_p4_status': 'TƯƠNG LAI',
    '15_p4_desc':
        'Tiếp tục phát triển hệ sinh thái, giới thiệu trải nghiệm Stella mới và khám phá những khả năng mới cho STL.',

    '16_title': 'Tính minh bạch',
    '16_text':
        'Stelluriini hướng tới việc phân biệt rõ ràng các chức năng hiện tại với kế hoạch tương lai. Tài liệu dự án nhằm mô tả trạng thái hiện tại và hướng phát triển dự kiến một cách chính xác nhất có thể.',
    '16_b1': 'Tổng nguồn cung STL được ghi rõ.',
    '16_b2': 'Cấu trúc phân bổ token được ghi rõ.',
    '16_b3':
        'Chức năng hiện tại được mô tả riêng với kế hoạch tương lai.',
    '16_b4':
        'Ưu tiên của lộ trình có thể thay đổi trong quá trình phát triển.',

    '17_title': 'Rủi ro & giới hạn',
    '17_text':
        'Tài sản kỹ thuật số và dự án phần mềm có các rủi ro về kỹ thuật, thị trường, quy định và vận hành. Người dùng nên hiểu những rủi ro này trước khi tương tác với tài sản hoặc ứng dụng blockchain.',
    '17_b1': 'Thị trường tiền điện tử có thể biến động mạnh.',
    '17_b2':
        'Giao dịch blockchain có thể bao gồm các hành động không thể đảo ngược.',
    '17_b3':
        'Phần mềm có thể có lỗi hoặc giới hạn kỹ thuật.',
    '17_b4':
        'Môi trường blockchain và quy định có thể thay đổi.',
    '17_b5': 'Các mục trong lộ trình tương lai không được đảm bảo.',
    '17_b6':
        'Phần thưởng ảo trong ứng dụng không nên được hiểu là lợi nhuận tài chính được đảm bảo.',

    '18_title': '18 • TUYÊN BỐ MIỄN TRỪ',
    '18_text':
        'Stelluriini và STL được giới thiệu như một dự án kỹ thuật số do cộng đồng xây dựng. Thông tin trong tài liệu này chỉ nhằm mục đích cung cấp thông tin và không cấu thành tư vấn tài chính, đầu tư, pháp lý hoặc thuế.',
    '18_text2':
        'Điểm ảo hiển thị trong ứng dụng không nên được hiểu là giá trị tiền điện tử được đảm bảo hoặc lợi nhuận tài chính được đảm bảo.',

    '19_title': 'Thông tin chính thức',
    '19_text':
        'Ứng dụng Stelluriini chính thức nên được sử dụng cùng với thông tin dự án đã được xác minh. Luôn kiểm tra địa chỉ token trước khi tương tác với tài sản blockchain.',
    '19_mint': 'STELLURIINI MINT',

    'closing': '🐱 Stella chỉ mới bắt đầu.',
    'closingSub': 'Cộng đồng • Tò mò • Sáng tạo • Solana',
    'footer': '🐾 STELLA • STELLURIINI • STL • SOLANA 🐾',
    'footerSupply': '17 602 539 062 STL',
    'footerVersion': 'SÁCH TRẮNG v1.0',
  },

  // ==========================================================
  // JAPANESE
  // ==========================================================

  'ja': {
    'pageTitle': 'ホワイトペーパー',
    'communityToken': '🐾 SOLANA コミュニティトークン 🐾',
    'whitePaper': 'ホワイトペーパー',
    'version': 'バージョン 1.0',

    '01_title': 'エグゼクティブサマリー',
    '01_text':
        'Stelluriini は、創造性、コミュニティ、探求を象徴する好奇心旺盛な猫 Stella を中心としたコミュニティ主導のデジタルプロジェクトです。STL は Solana ブロックチェーン上のプロジェクトトークンです。Stelluriini アプリは、Stella のブランド、マイニング型の報酬システム、毎日のアクティビティ、STL エコシステムの情報を組み合わせています。',

    '02_title': 'ビジョン',
    '02_text':
        'Stelluriini のビジョンは、Stella を体験の中心に置いた、認識しやすくコミュニティを重視したデジタルエコシステムを作ることです。',
    '02_b1': '強く認識しやすい Stella ブランドを構築する。',
    '02_b2':
        '魅力的なアプリケーションとデジタル体験を作る。',
    '02_b3': '活発で温かいコミュニティを成長させる。',
    '02_b4':
        '便利で楽しい STL エコシステム機能を開発する。',
    '02_b5':
        'ゲーム、アプリケーション、将来の Solana 統合を探求する。',

    '03_title': 'Stelluriini とは？',
    '03_text':
        'Stelluriini は単なるトークン名ではありません。Stella を中心に構築されたプロジェクトのアイデンティティであり、コミュニティを重視したデジタル体験です。',
    '03_f1_title': 'Stella',
    '03_f1_desc':
        'プロジェクトのビジュアルマスコットと認識しやすいアイデンティティ。',
    '03_f2_title': 'STL',
    '03_f2_desc':
        'Solana エコシステムに関連する Stelluriini トークン。',
    '03_f3_title': 'アプリケーション',
    '03_f3_desc':
        'マイニング型報酬、毎日のアクティビティ、プロジェクト情報を含むモバイル体験。',
    '03_f4_title': 'コミュニティ',
    '03_f4_desc':
        '将来の機能を一緒に開発できるコミュニティ中心の環境。',

    '04_title': 'Stella',
    '04_heading': 'Stella は Stelluriini の中心です。',
    '04_text':
        'Stella は好奇心、親しみやすさ、探求を象徴しています。Stelluriini の体験を認識しやすくし、アプリ、コミュニティ、将来のエコシステムに一貫したアイデンティティを提供します。',

    '05_title': 'STL トークン',
    '05_name': 'トークン名',
    '05_symbol': 'シンボル',
    '05_blockchain': 'ブロックチェーン',
    '05_supply': '総供給量',
    '05_decimals': '小数点以下',
    '05_mint': 'Mint アドレス',

    '06_title': 'トークノミクス',
    '06_text':
        'STL の予定配分は、コミュニティ報酬、流動性、エコシステムの成長、開発、マーケティングを支援するよう設計されています。',
    '06_a1': 'コミュニティ＆報酬',
    '06_a2': '流動性',
    '06_a3': 'エコシステム',
    '06_a4': '開発',
    '06_a5': 'マーケティング',
    '06_total': '総配分量：17 602 539 062 STL',

    '07_title': 'Stella Mining',
    '07_text':
        'Stelluriini アプリにはマイニング型の報酬システムがあります。これはアプリ内の進行システムとして設計されており、ユーザーはマイニングサイクル中に仮想 STL ポイントを蓄積できます。',
    '07_f1_title': 'ハッシュレート',
    '07_f1_desc':
        'ユーザーのハッシュレートによって仮想マイニングポイントの蓄積速度が決まります。',
    '07_f2_title': 'マイニングサイクル',
    '07_f2_desc':
        'マイニングサイクルは一定期間実行され、その後、蓄積された報酬を受け取ることができます。',
    '07_f3_title': '報酬計算',
    '07_f3_desc':
        '仮想報酬はハッシュレートと経過したマイニング時間から計算されます。',
    '07_f4_title': '固定マイニングレート',
    '07_f4_desc':
        'アクティブなマイニングサイクルで使用されるハッシュレートは、そのサイクル中安定して維持されます。',

    '08_title': 'デイリーボーナス',
    '08_text':
        'デイリーボーナスは Stelluriini アプリへの継続的な参加を促します。毎日のチェックインに成功するとユーザーのハッシュレートが上昇し、連続日数に貢献できます。',
    '08_b1':
        'デイリーチェックインは1日1回のみ成功して受け取ることができます。',
    '08_b2':
        '翌日以降も戻ってくることで連続日数を維持できます。',
    '08_b3':
        'ボーナスは今後のマイニングサイクルで使用されるハッシュレートに影響します。',

    '09_title': 'Stella Power Boost',
    '09_text':
        'Stella Power Boost システムでは、リワード広告を通じて追加のハッシュレートボーナスを受け取ることができます。不正利用を防ぐため、制限とクールダウンルールが設定されています。',
    '09_f1_title': 'リワード広告',
    '09_f1_desc':
        '条件を満たすリワード広告を視聴すると、アプリ内ハッシュレートボーナスを受け取れます。',
    '09_f2_title': 'クールダウン',
    '09_f2_desc':
        'クールダウン期間により広告報酬を受け取れる頻度が制限されます。',
    '09_f3_title': '1日の上限',
    '09_f3_desc':
        '1日にカウントできるリワード広告には上限があります。',

    '10_title': 'アプリケーションアーキテクチャ',
    '10_text':
        'Stelluriini アプリは、認証された報酬操作と取引履歴を処理するモバイルクライアントおよびサーバー側サービスを中心に設計されています。',
    '10_b1_title': 'Flutter アプリ',
    '10_b1_desc':
        'ユーザーインターフェース、Stella 体験、マイニングダッシュボード、プロジェクト情報。',
    '10_b2_title': 'Firebase サービス',
    '10_b2_desc':
        '認証、Firestore データ、サーバー側 Cloud Functions。',
    '10_b3_title': 'サーバー側検証',
    '10_b3_desc':
        '報酬制限、クールダウン、重複防止、認証済み操作。',
    '10_b4_title': 'Solana / STL',
    '10_b4_desc':
        'Stelluriini トークンは Solana ブロックチェーン上の資産として存在します。',

    '11_title': '取引履歴',
    '11_text':
        'アプリには取引履歴画面があり、記録された報酬アクティビティをユーザーに表示できます。',
    '11_b1': 'マイニング報酬アクティビティ。',
    '11_b2': 'デイリー報酬アクティビティ。',
    '11_b3': 'リワード広告アクティビティ。',
    '11_b4': '記録された報酬後の残高。',
    '11_b5': '取引日とアクティビティタイプ。',

    '12_title': 'セキュリティ＆不正利用防止',
    '12_text':
        'Stelluriini アプリは、報酬操作の改ざんを減らすためサーバー側検証を使用しています。セキュリティ機構はアプリと報酬システムの完全性を保護することを目的としています。',
    '12_f1_title': '認証',
    '12_f1_desc':
        '報酬操作には認証されたユーザーセッションが必要です。',
    '12_f2_title': '重複防止',
    '12_f2_desc':
        '報酬取引は繰り返し処理されることを防止できます。',
    '12_f3_title': 'レート制限',
    '12_f3_desc':
        '1日の上限とクールダウン期間により自動化された不正利用を減らします。',
    '12_f4_title': '報酬検証',
    '12_f4_desc':
        'サーバー側ロジックが重要な報酬条件を記録前に検証します。',

    '13_title': 'コミュニティ',
    '13_text':
        'コミュニティへの参加は Stelluriini のビジョンにおいて重要です。ユーザーが進捗を確認し、フィードバックを提供し、将来のエコシステム活動に参加できる環境を目指しています。',
    '13_b1':
        'コミュニティからのフィードバックは将来の開発に影響する可能性があります。',
    '13_b2':
        '将来のコミュニティ機能によって STL の役割が拡大する可能性があります。',
    '13_b3':
        '透明性は重要なプロジェクト原則として維持される予定です。',

    '14_title': '未来のエコシステム',
    '14_text':
        '将来の Stelluriini エコシステムは現在のアプリを超えて拡大する可能性があります。新しい Stella 体験、ゲーム、アプリ、コミュニティ機能、追加の Solana 統合などが考えられます。',
    '14_f1_title': 'Stella ゲーム',
    '14_f1_desc':
        'Stella が登場するゲームやインタラクティブな体験を探求します。',
    '14_f2_title': '新しいアプリ',
    '14_f2_desc':
        'Stelluriini のアイデンティティを中心に新しいデジタル製品やサービスを開発します。',
    '14_f3_title': 'STL 統合',
    '14_f3_desc':
        'STL と Solana エコシステムに関する有用な統合を探求します。',
    '14_f4_title': 'コミュニティ活動',
    '14_f4_desc':
        'イベント、チャレンジ、コミュニティ向け報酬体験などを検討します。',

    '15_title': 'ロードマップ',
    '15_p1_title': '始まり',
    '15_p1_status': '進行中',
    '15_p1_desc':
        'Stelluriini のアイデンティティ確立、Stella ブランド開発、アプリ構築、STL 情報の準備。',
    '15_p2_title': 'コミュニティ',
    '15_p2_status': '計画中',
    '15_p2_desc':
        'コミュニティの成長、言語サポートの改善、デイリー活動とコミュニティ機能の開発。',
    '15_p3_title': 'STL エコシステム',
    '15_p3_status': '未来',
    '15_p3_desc':
        'STL エコシステム機能、ブロックチェーン情報、統計、その他の Stelluriini 機能を拡張します。',
    '15_p4_title': '未来',
    '15_p4_status': '未来',
    '15_p4_desc':
        'エコシステム開発を継続し、新しい Stella 体験を導入して STL の新しい可能性を探ります。',

    '16_title': '透明性',
    '16_text':
        'Stelluriini は既存の機能と将来の計画を明確に区別することを目指しています。プロジェクト文書では、現在の状態と予定されている方向性をできる限り正確に説明します。',
    '16_b1': 'STL の総供給量を記載しています。',
    '16_b2': 'トークン配分構造を記載しています。',
    '16_b3':
        '現在のアプリ機能と将来の計画を分けて説明しています。',
    '16_b4':
        '開発の進行に伴いロードマップの優先事項が変更される場合があります。',

    '17_title': 'リスクと制限',
    '17_text':
        'デジタル資産とソフトウェアプロジェクトには、技術、マーケット、規制、運用上のリスクがあります。ブロックチェーン資産やアプリケーションを利用する前に、これらのリスクを理解してください。',
    '17_b1': '暗号資産市場は非常に変動する可能性があります。',
    '17_b2':
        'ブロックチェーン取引には取り消せない操作が含まれる場合があります。',
    '17_b3':
        'ソフトウェアにはバグや技術的制限が存在する可能性があります。',
    '17_b4':
        'ブロックチェーンおよび規制環境は変化する可能性があります。',
    '17_b5':
        '将来のロードマップ項目は保証されていません。',
    '17_b6':
        'アプリ内の仮想報酬を保証された金融リターンとして解釈しないでください。',

    '18_title': '18 • 免責事項',
    '18_text':
        'Stelluriini と STL はコミュニティ主導のデジタルプロジェクトとして紹介されています。本書の情報は情報提供のみを目的としており、金融、投資、法律、税務に関する助言を構成するものではありません。',
    '18_text2':
        'アプリに表示される仮想ポイントは、保証された暗号資産価値または保証された金融リターンとして解釈しないでください。',

    '19_title': '公式情報',
    '19_text':
        'Stelluriini の公式アプリは、確認済みのプロジェクト情報と併用してください。ブロックチェーン資産を操作する前には、必ずトークンアドレスを確認してください。',
    '19_mint': 'STELLURIINI MINT',

    'closing': '🐱 Stella はまだ始まったばかりです。',
    'closingSub': 'コミュニティ • 好奇心 • 創造性 • Solana',
    'footer': '🐾 STELLA • STELLURIINI • STL • SOLANA 🐾',
    'footerSupply': '17 602 539 062 STL',
    'footerVersion': 'ホワイトペーパー v1.0',
  },
};

// ============================================================
// WHITE PAPER PAGE
// ============================================================

class WhitePaperPage extends StatelessWidget {
  const WhitePaperPage({
    super.key,
  });

  static const String tokenName = 'Stelluriini';
  static const String tokenSymbol = 'STL';
  static const String blockchain = 'Solana';
  static const String totalSupply = '17 602 539 062';
  static const String decimals = '9';

  static const String mintAddress =
      'AyZun5s9tEJDeHTNPrVbaYpqjWdSKHx25M3kfVFjbdas';

  // ==========================================================
  // TRANSLATION HELPER
  // ==========================================================

  String _t(
    String languageCode,
    String key,
  ) {
    return _whitePaperTranslations[languageCode]?[key] ??
        _whitePaperTranslations['en']?[key] ??
        key;
  }

  // ==========================================================
  // SECTION
  // ==========================================================

  Widget _section({
    required String number,
    required IconData icon,
    required String title,
    required Widget child,
    Color accent = whitePaperAccentColor,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 18,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: whitePaperCardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accent.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(
                    alpha: 0.11,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accent.withValues(
                      alpha: 0.15,
                    ),
                  ),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      number,
                      style: TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  // ==========================================================
  // PARAGRAPH
  // ==========================================================

  Widget _paragraph(
    String text,
  ) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
        height: 1.65,
      ),
    );
  }

  // ==========================================================
  // BULLET
  // ==========================================================

  Widget _bullet(
    String text, {
    Color accent = whitePaperAccentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(
              top: 7,
            ),
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // FEATURE ROW
  // ==========================================================

  Widget _featureRow({
    required IconData icon,
    required String title,
    required String description,
    Color accent = whitePaperAccentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: accent,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TOKEN INFO ROW
  // ==========================================================

  Widget _tokenInfoRow(
    String label,
    String value, {
    Color accent = whitePaperAccentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: accent,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ALLOCATION ROW
  // ==========================================================

  Widget _allocationRow({
    required String title,
    required String percentage,
    required String amount,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: whitePaperBackgroundColor.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withValues(
            alpha: 0.16,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  amount,
                  style: const TextStyle(
                    color: Color.fromRGBO(
                      255,
                      255,
                      255,
                      0.50,
                    ),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            percentage,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PHASE ROW
  // ==========================================================

  Widget _phaseRow({
    required String phase,
    required String title,
    required String status,
    required String description,
    required Color accent,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: whitePaperBackgroundColor.withValues(
          alpha: 0.42,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accent.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: accent.withValues(
                alpha: 0.11,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withValues(
                  alpha: 0.28,
                ),
              ),
            ),
            child: Center(
              child: Text(
                phase,
                style: TextStyle(
                  color: accent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(
                          alpha: 0.10,
                        ),
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: accent,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ARCHITECTURE BOX
  // ==========================================================

  Widget _architectureBox({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: whitePaperBackgroundColor.withValues(
          alpha: 0.42,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ARCHITECTURE ARROW
  // ==========================================================

  Widget _architectureArrow() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Icon(
        Icons.arrow_downward_rounded,
        color: whitePaperAccentColor.withValues(
          alpha: 0.45,
        ),
        size: 20,
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final localization = AppLocalizations.of(context);
    final languageCode = localization.languageCode;

    String t(String key) {
      return _t(languageCode, key);
    }

    return Scaffold(
      backgroundColor:
          whitePaperBackgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            whitePaperBackgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          t('pageTitle'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.8,
            fontSize: 16,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            36,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // COVER
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  24,
                  30,
                  24,
                  28,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF21113B),
                      Color(0xFF2A1648),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.circular(28),
                  border: Border.all(
                    color:
                        whitePaperAccentColor.withValues(
                      alpha: 0.30,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          whitePaperAccentColor.withValues(
                        alpha: 0.10,
                      ),
                      blurRadius: 26,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const CatAvatar(
                      size: 125,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'STELLURIINI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: whitePaperPinkColor,
                        fontSize: 29,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3.2,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'STL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 13),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            whitePaperAccentColor.withValues(
                          alpha: 0.10,
                        ),
                        borderRadius:
                            BorderRadius.circular(30),
                        border: Border.all(
                          color:
                              whitePaperAccentColor.withValues(
                            alpha: 0.22,
                          ),
                        ),
                      ),
                      child: Text(
                        t('communityToken'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color:
                              whitePaperAccentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      t('whitePaper'),
                      style: const TextStyle(
                        color: whitePaperGoldColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      t('version'),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // 01
              // ==================================================

              _section(
                number: '01',
                icon: Icons.auto_awesome_rounded,
                title: t('01_title'),
                child: _paragraph(
                  t('01_text'),
                ),
              ),

              // ==================================================
              // 02
              // ==================================================

              _section(
                number: '02',
                icon: Icons.visibility_rounded,
                title: t('02_title'),
                accent: whitePaperPinkColor,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      t('02_text'),
                    ),
                    const SizedBox(height: 18),
                    _bullet(
                      t('02_b1'),
                      accent: whitePaperPinkColor,
                    ),
                    _bullet(
                      t('02_b2'),
                      accent: whitePaperPinkColor,
                    ),
                    _bullet(
                      t('02_b3'),
                      accent: whitePaperPinkColor,
                    ),
                    _bullet(
                      t('02_b4'),
                      accent: whitePaperPinkColor,
                    ),
                    _bullet(
                      t('02_b5'),
                      accent: whitePaperPinkColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 03
              // ==================================================

              _section(
                number: '03',
                icon: Icons.pets_rounded,
                title: t('03_title'),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      t('03_text'),
                    ),
                    const SizedBox(height: 18),
                    _featureRow(
                      icon: Icons.pets_rounded,
                      title: t('03_f1_title'),
                      description: t('03_f1_desc'),
                      accent: whitePaperPinkColor,
                    ),
                    _featureRow(
                      icon: Icons.currency_bitcoin_rounded,
                      title: t('03_f2_title'),
                      description: t('03_f2_desc'),
                      accent: whitePaperGoldColor,
                    ),
                    _featureRow(
                      icon: Icons.phone_android_rounded,
                      title: t('03_f3_title'),
                      description: t('03_f3_desc'),
                      accent: whitePaperAccentColor,
                    ),
                    _featureRow(
                      icon: Icons.groups_rounded,
                      title: t('03_f4_title'),
                      description: t('03_f4_desc'),
                      accent: whitePaperPinkColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 04
              // ==================================================

              _section(
                number: '04',
                icon: Icons.favorite_rounded,
                title: t('04_title'),
                accent: whitePaperPinkColor,
                child: Column(
                  children: [
                    const StelluriiniLogo(
                      size: 80,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      t('04_heading'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: whitePaperPinkColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _paragraph(
                      t('04_text'),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 05
              // ==================================================

              _section(
                number: '05',
                icon: Icons.monetization_on_rounded,
                title: t('05_title'),
                accent: whitePaperGoldColor,
                child: Column(
                  children: [
                    _tokenInfoRow(
                      t('05_name'),
                      tokenName,
                      accent: whitePaperPinkColor,
                    ),
                    _tokenInfoRow(
                      t('05_symbol'),
                      tokenSymbol,
                      accent: whitePaperPinkColor,
                    ),
                    _tokenInfoRow(
                      t('05_blockchain'),
                      blockchain,
                    ),
                    _tokenInfoRow(
                      t('05_supply'),
                      totalSupply,
                      accent: whitePaperGoldColor,
                    ),
                    _tokenInfoRow(
                      t('05_decimals'),
                      decimals,
                    ),
                    const SizedBox(height: 5),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color:
                            whitePaperBackgroundColor
                                .withValues(
                          alpha: 0.45,
                        ),
                        borderRadius:
                            BorderRadius.circular(15),
                        border: Border.all(
                          color:
                              whitePaperGoldColor.withValues(
                            alpha: 0.16,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('05_mint'),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const SelectableText(
                            mintAddress,
                            style: TextStyle(
                              color:
                                  whitePaperPinkColor,
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 06
              // ==================================================

              _section(
                number: '06',
                icon: Icons.pie_chart_rounded,
                title: t('06_title'),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      t('06_text'),
                    ),
                    const SizedBox(height: 18),
                    _allocationRow(
                      title: t('06_a1'),
                      percentage: '40%',
                      amount: '7 041 015 625 STL',
                      color: whitePaperAccentColor,
                    ),
                    _allocationRow(
                      title: t('06_a2'),
                      percentage: '20%',
                      amount: '3 520 507 812 STL',
                      color: const Color(0xFF72B7FF),
                    ),
                    _allocationRow(
                      title: t('06_a3'),
                      percentage: '15%',
                      amount: '2 640 380 859 STL',
                      color: const Color(0xFFC084FC),
                    ),
                    _allocationRow(
                      title: t('06_a4'),
                      percentage: '15%',
                      amount: '2 640 380 859 STL',
                      color: whitePaperGoldColor,
                    ),
                    _allocationRow(
                      title: t('06_a5'),
                      percentage: '10%',
                      amount: '1 760 253 907 STL',
                      color: whitePaperPinkColor,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:
                            whitePaperAccentColor.withValues(
                          alpha: 0.07,
                        ),
                        borderRadius:
                            BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              whitePaperAccentColor.withValues(
                            alpha: 0.16,
                          ),
                        ),
                      ),
                      child: Text(
                        t('06_total'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: whitePaperGoldColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 07
              // ==================================================

              _section(
                number: '07',
                icon: Icons.bolt_rounded,
                title: t('07_title'),
                accent: whitePaperAccentColor,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      t('07_text'),
                    ),
                    const SizedBox(height: 18),
                    _featureRow(
                      icon: Icons.speed_rounded,
                      title: t('07_f1_title'),
                      description: t('07_f1_desc'),
                    ),
                    _featureRow(
                      icon: Icons.timer_rounded,
                      title: t('07_f2_title'),
                      description: t('07_f2_desc'),
                    ),
                    _featureRow(
                      icon: Icons.calculate_rounded,
                      title: t('07_f3_title'),
                      description: t('07_f3_desc'),
                    ),
                    _featureRow(
                      icon: Icons.lock_clock_rounded,
                      title: t('07_f4_title'),
                      description: t('07_f4_desc'),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 08
              // ==================================================

              _section(
                number: '08',
                icon: Icons.card_giftcard_rounded,
                title: t('08_title'),
                accent: whitePaperGoldColor,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      t('08_text'),
                    ),
                    const SizedBox(height: 16),
                    _bullet(
                      t('08_b1'),
                      accent: whitePaperGoldColor,
                    ),
                    _bullet(
                      t('08_b2'),
                      accent: whitePaperGoldColor,
                    ),
                    _bullet(
                      t('08_b3'),
                      accent: whitePaperGoldColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 09
              // ==================================================

              _section(
                number: '09',
                icon: Icons.flash_on_rounded,
                title: t('09_title'),
                accent: whitePaperPinkColor,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      t('09_text'),
                    ),
                    const SizedBox(height: 16),
                    _featureRow(
                      icon: Icons.ondemand_video_rounded,
                      title: t('09_f1_title'),
                      description: t('09_f1_desc'),
                      accent: whitePaperPinkColor,
                    ),
                    _featureRow(
                      icon: Icons.av_timer_rounded,
                      title: t('09_f2_title'),
                      description: t('09_f2_desc'),
                      accent: whitePaperPinkColor,
                    ),
                    _featureRow(
                      icon: Icons.today_rounded,
                      title: t('09_f3_title'),
                      description: t('09_f3_desc'),
                      accent: whitePaperPinkColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 10
              // ==================================================

              _section(
                number: '10',
                icon: Icons.account_tree_rounded,
                title: t('10_title'),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      t('10_text'),
                    ),
                    const SizedBox(height: 18),
                    _architectureBox(
                      icon: Icons.phone_android_rounded,
                      title: t('10_b1_title'),
                      description: t('10_b1_desc'),
                      color: whitePaperPinkColor,
                    ),
                    _architectureArrow(),
                    _architectureBox(
                      icon: Icons.cloud_rounded,
                      title: t('10_b2_title'),
                      description: t('10_b2_desc'),
                      color: whitePaperAccentColor,
                    ),
                    _architectureArrow(),
                    _architectureBox(
                      icon: Icons.security_rounded,
                      title: t('10_b3_title'),
                      description: t('10_b3_desc'),
                      color: whitePaperGoldColor,
                    ),
                    _architectureArrow(),
                    _architectureBox(
                      icon: Icons.link_rounded,
                      title: t('10_b4_title'),
                      description: t('10_b4_desc'),
                      color: whitePaperPinkColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 11
              // ==================================================

              _section(
                number: '11',
                icon: Icons.history_rounded,
                title: t('11_title'),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      t('11_text'),
                    ),
                    const SizedBox(height: 16),
                    _bullet(t('11_b1')),
                    _bullet(t('11_b2')),
                    _bullet(t('11_b3')),
                    _bullet(t('11_b4')),
                    _bullet(t('11_b5')),
                  ],
                ),
              ),

              // ==================================================
              // 12
              // ==================================================

              _section(
                number: '12',
                icon: Icons.security_rounded,
                title: t('12_title'),
                accent: whitePaperGoldColor,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      t('12_text'),
                    ),
                    const SizedBox(height: 18),
                    _featureRow(
                      icon: Icons.verified_user_rounded,
                      title: t('12_f1_title'),
                      description: t('12_f1_desc'),
                      accent: whitePaperGoldColor,
                    ),
                    _featureRow(
                      icon: Icons.block_rounded,
                      title: t('12_f2_title'),
                      description: t('12_f2_desc'),
                      accent: whitePaperGoldColor,
                    ),
                    _featureRow(
                      icon: Icons.speed_rounded,
                      title: t('12_f3_title'),
                      description: t('12_f3_desc'),
                      accent: whitePaperGoldColor,
                    ),
                    _featureRow(
                      icon: Icons.verified_rounded,
                      title: t('12_f4_title'),
                      description: t('12_f4_desc'),
                      accent: whitePaperGoldColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 13
              // ==================================================

              _section(
                number: '13',
                icon: Icons.groups_rounded,
                title: t('13_title'),
                accent: whitePaperPinkColor,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      t('13_text'),
                    ),
                    const SizedBox(height: 18),
                    _bullet(
                      t('13_b1'),
                      accent: whitePaperPinkColor,
                    ),
                    _bullet(
                      t('13_b2'),
                      accent: whitePaperPinkColor,
                    ),
                    _bullet(
                      t('13_b3'),
                      accent: whitePaperPinkColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 14
              // ==================================================

              _section(
                number: '14',
                icon: Icons.rocket_launch_rounded,
                title: t('14_title'),
                accent: whitePaperAccentColor,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      t('14_text'),
                    ),
                    const SizedBox(height: 18),
                    _featureRow(
                      icon: Icons.sports_esports_rounded,
                      title: t('14_f1_title'),
                      description: t('14_f1_desc'),
                      accent: whitePaperPinkColor,
                    ),
                    _featureRow(
                      icon: Icons.apps_rounded,
                      title: t('14_f2_title'),
                      description: t('14_f2_desc'),
                      accent: whitePaperAccentColor,
                    ),
                    _featureRow(
                      icon: Icons.link_rounded,
                      title: t('14_f3_title'),
                      description: t('14_f3_desc'),
                      accent: whitePaperGoldColor,
                    ),
                    _featureRow(
                      icon: Icons.emoji_events_rounded,
                      title: t('14_f4_title'),
                      description: t('14_f4_desc'),
                      accent: whitePaperPinkColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 15
              // ==================================================

              _section(
                number: '15',
                icon: Icons.map_rounded,
                title: t('15_title'),
                child: Column(
                  children: [
                    _phaseRow(
                      phase: '01',
                      title: t('15_p1_title'),
                      status: t('15_p1_status'),
                      description: t('15_p1_desc'),
                      accent: whitePaperPinkColor,
                    ),
                    _phaseRow(
                      phase: '02',
                      title: t('15_p2_title'),
                      status: t('15_p2_status'),
                      description: t('15_p2_desc'),
                      accent: whitePaperAccentColor,
                    ),
                    _phaseRow(
                      phase: '03',
                      title: t('15_p3_title'),
                      status: t('15_p3_status'),
                      description: t('15_p3_desc'),
                      accent: whitePaperGoldColor,
                    ),
                    _phaseRow(
                      phase: '04',
                      title: t('15_p4_title'),
                      status: t('15_p4_status'),
                      description: t('15_p4_desc'),
                      accent: whitePaperPinkColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 16
              // ==================================================

              _section(
                number: '16',
                icon: Icons.visibility_rounded,
                title: t('16_title'),
                accent: whitePaperGoldColor,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      t('16_text'),
                    ),
                    const SizedBox(height: 18),
                    _bullet(
                      t('16_b1'),
                      accent: whitePaperGoldColor,
                    ),
                    _bullet(
                      t('16_b2'),
                      accent: whitePaperGoldColor,
                    ),
                    _bullet(
                      t('16_b3'),
                      accent: whitePaperGoldColor,
                    ),
                    _bullet(
                      t('16_b4'),
                      accent: whitePaperGoldColor,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 17
              // ==================================================

              _section(
                number: '17',
                icon: Icons.warning_amber_rounded,
                title: t('17_title'),
                accent: Colors.orangeAccent,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      t('17_text'),
                    ),
                    const SizedBox(height: 18),
                    _bullet(
                      t('17_b1'),
                      accent: Colors.orangeAccent,
                    ),
                    _bullet(
                      t('17_b2'),
                      accent: Colors.orangeAccent,
                    ),
                    _bullet(
                      t('17_b3'),
                      accent: Colors.orangeAccent,
                    ),
                    _bullet(
                      t('17_b4'),
                      accent: Colors.orangeAccent,
                    ),
                    _bullet(
                      t('17_b5'),
                      accent: Colors.orangeAccent,
                    ),
                    _bullet(
                      t('17_b6'),
                      accent: Colors.orangeAccent,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 18 DISCLAIMER
              // ==================================================

              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(
                  bottom: 18,
                ),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(
                    alpha: 0.07,
                  ),
                  borderRadius:
                      BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.orangeAccent.withValues(
                      alpha: 0.24,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.gavel_rounded,
                      color: Colors.orangeAccent,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t('18_title'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t('18_text'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t('18_text2'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.55,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // 19
              // ==================================================

              _section(
                number: '19',
                icon: Icons.link_rounded,
                title: t('19_title'),
                accent: whitePaperPinkColor,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _paragraph(
                      t('19_text'),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color:
                            whitePaperBackgroundColor
                                .withValues(
                          alpha: 0.45,
                        ),
                        borderRadius:
                            BorderRadius.circular(15),
                        border: Border.all(
                          color:
                              whitePaperPinkColor.withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('19_mint'),
                            style: const TextStyle(
                              color:
                                  whitePaperPinkColor,
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const SelectableText(
                            mintAddress,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // STELLA CLOSING CARD
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  22,
                  24,
                  22,
                  24,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF21113B),
                      Color(0xFF281540),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.circular(24),
                  border: Border.all(
                    color:
                        whitePaperPinkColor.withValues(
                      alpha: 0.20,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    const CatAvatar(
                      size: 82,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      t('closing'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: whitePaperPinkColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t('closingSub'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // FOOTER
              // ==================================================

              Text(
                t('footer'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: whitePaperPinkColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t('footerSupply'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: whitePaperGoldColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                t('footerVersion'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}