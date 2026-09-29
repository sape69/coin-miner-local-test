// ============================================================
// 🐱 STELLURIINI - ROADMAP LOCALIZATION
// ============================================================
//
// Supported languages:
//
// fi = Finnish
// en = English
// de = German
// es = Spanish
// fr = French
// zh = Chinese
// vi = Vietnamese
// ja = Japanese
//
// ============================================================

class RoadmapLocalization {
  final String languageCode;

  const RoadmapLocalization(
    this.languageCode,
  );

  // ==========================================================
  // 🌍 LANGUAGE
  // ==========================================================

  String get _language {
    final String normalized =
        languageCode.toLowerCase().trim();

    switch (normalized) {
      case 'fi':
        return 'fi';

      case 'en':
        return 'en';

      case 'de':
        return 'de';

      case 'es':
        return 'es';

      case 'fr':
        return 'fr';

      case 'zh':
        return 'zh';

      case 'vi':
        return 'vi';

      case 'ja':
        return 'ja';

      default:
        return 'en';
    }
  }

  // ==========================================================
  // 🔑 GET
  // ==========================================================

  String get(
    String key,
  ) {
    final Map<String, String>? translations =
        _translations[_language];

    return translations?[key] ??
        _translations['en']?[key] ??
        key;
  }

  // ==========================================================
  // 📚 TRANSLATIONS
  // ==========================================================

  static const Map<String, Map<String, String>>
      _translations = {
    // ========================================================
    // 🇬🇧 ENGLISH
    // ========================================================

    'en': {
      'pageTitle':
          'Stelluriini Roadmap',

      'journeyTitle':
          'The Stelluriini Journey',

      'journeyDescription':
          'Stelluriini development progresses step by step toward a broader community, ecosystem and new use cases.',

      // ------------------------------------------------------
      // PHASES
      // ------------------------------------------------------

      'phase1':
          'Phase 1 – Foundation',

      'phase1Title':
          'Building Stelluriini',

      'phase1Description':
          'Building the Stelluriini project, STL token and Stella ecosystem.',

      'phase2':
          'Phase 2 – App',

      'phase2Title':
          'Stelluriini App Development',

      'phase2Description':
          'Mining, Stella Power Boost, user progress and transaction history.',

      'phase3':
          'Phase 3 – Community',

      'phase3Title':
          'Growing the Community',

      'phase3Description':
          'Building the community, collecting feedback and developing the Stelluriini brand.',

      'phase4':
          'Phase 4 – Ecosystem',

      'phase4Title':
          'Expanding the STL Ecosystem',

      'phase4Description':
          'Developing STL token use cases and expanding the Stelluriini ecosystem.',

      'phase5':
          'Phase 5 – Testnet',

      'phase5Title':
          'Solana Testnet',

      'phase5Description':
          'Testing STL transfers, wallet connections, transactions and withdrawal functionality before Mainnet.',

      'phase6':
          'Phase 6 – Long-Term Development',

      'phase6Title':
          'The Next Stage of Stelluriini',

      'phase6Description':
          'Continuous development of the Stelluriini ecosystem, new features and responses to community needs.',

      'phase7':
          'Phase 7 – Mainnet',

      'phase7Title':
          'Solana Mainnet & STL Withdrawals',

      'phase7Description':
          'Opening the Stelluriini Solana Mainnet phase and introducing STL withdrawals after testing and security checks.',

      'phase8':
          'Phase 8 – Ecosystem',

      'phase8Title':
          'Exchange & Ecosystem',

      'phase8Description':
          'Exploring DEX and CEX opportunities, liquidity solutions, partnerships and future STL use cases.',

      // ------------------------------------------------------
      // STATUS
      // ------------------------------------------------------

      'statusInProgress':
          'In Progress',

      'statusTesting':
          'Testing',

      'statusPlanned':
          'Planned',

      'statusFuture':
          'Future',

      // ------------------------------------------------------
      // MINING ECONOMY
      // ------------------------------------------------------

      'miningBalanceTitle':
          'Mining Economy Balance',

      'miningBalanceDescription':
          'The goal of the mining system is not to increase daily STL production without limits. Hash Rate, Power Boost and Referral bonuses are designed together so the overall system remains manageable.',

      'hashRateTitle':
          'Hash Rate',

      'hashRateDescription':
          'Basic mining forms the user’s normal Hash Rate level.',

      'powerBoostTitle':
          'Power Boost',

      'powerBoostDescription':
          'Power Boost provides a temporary increase to the user’s mining power.',

      'referralTitle':
          'Referral',

      'referralDescription':
          'Referral bonuses will be designed to remain balanced as the community grows.',

      // ------------------------------------------------------
      // WITHDRAWALS
      // ------------------------------------------------------

      'withdrawalTitle':
          'Potential Future Withdrawals',

      'withdrawalDescription':
          'A possible future withdrawal system will be designed separately and its terms will be announced before implementation.',

      'plannedMinimumWithdrawal':
          'Planned minimum withdrawal',

      'networkFee':
          'User pays the Solana network fee.',

      // ------------------------------------------------------
      // STELLA
      // ------------------------------------------------------

      'stellaJourneyTitle':
          'Stella’s Journey 🐾',

      'stellaJourneyDescription':
          'The Stelluriini ecosystem will be developed step by step around the community, app and STL token.',

      // ------------------------------------------------------
      // DEVELOPMENT PRINCIPLES
      // ------------------------------------------------------

      'developmentPrinciplesTitle':
          'Development Principles',

      'communityTitle':
          'Community',

      'communityDescription':
          'The community is at the heart of Stelluriini development. Feedback and user ideas help guide future development.',

      'securityTitle':
          'Security',

      'securityDescription':
          'Security, server infrastructure and application reliability will be continuously improved.',

      'antiBotTitle':
          'Bot Protection',

      'antiBotDescription':
          'The system will account for bots, automation and the detection of abuse.',

      'innovationTitle':
          'Innovation',

      'innovationDescription':
          'New use cases, features and technologies will be explored as the project develops.',

      'longTermGrowthTitle':
          'Long-Term Growth',

      'longTermGrowthDescription':
          'The goal is to build a sustainable and gradually evolving Stelluriini ecosystem.',

      // ------------------------------------------------------
      // NOTICE
      // ------------------------------------------------------

      'importantNoticeTitle':
          'Important Notice',

      'importantNoticeDescription':
          'The roadmap describes the planned development direction of Stelluriini. Phases, features and timelines may change during project development.',

      // ------------------------------------------------------
      // FOOTER
      // ------------------------------------------------------

      'footer':
          'STELLA • STELLURIINI • STL • SOLANA',
    },

    // ========================================================
    // 🇫🇮 FINNISH
    // ========================================================

    'fi': {
      'pageTitle':
          'Stelluriini Roadmap',

      'journeyTitle':
          'Stelluriinin matka',

      'journeyDescription':
          'Stelluriinin kehitys etenee vaiheittain kohti laajempaa yhteisöä, ekosysteemiä ja uusia käyttötapoja.',

      'phase1':
          'Vaihe 1 – Perusta',

      'phase1Title':
          'Stelluriinin rakentaminen',

      'phase1Description':
          'Stelluriini-projektin, STL-tokenin ja Stella-ekosysteemin rakentaminen.',

      'phase2':
          'Vaihe 2 – Sovellus',

      'phase2Title':
          'Stelluriini-sovelluksen kehitys',

      'phase2Description':
          'Louhinta, Stellan Power Boost, käyttäjän eteneminen ja tapahtumahistoria.',

      'phase3':
          'Vaihe 3 – Yhteisö',

      'phase3Title':
          'Yhteisön kasvattaminen',

      'phase3Description':
          'Yhteisön rakentaminen, palautteen kerääminen ja Stelluriini-brändin kehittäminen.',

      'phase4':
          'Vaihe 4 – Ekosysteemi',

      'phase4Title':
          'STL-ekosysteemin laajentaminen',

      'phase4Description':
          'STL-tokenin käyttötapojen kehittäminen ja Stelluriini-ekosysteemin laajentaminen.',

      'phase5':
          'Vaihe 5 – Testnet',

      'phase5Title':
          'Solana Testnet',

      'phase5Description':
          'STL-siirtojen, lompakkoyhteyksien, transaktioiden ja nostotoimintojen testaaminen ennen Mainnetia.',

      'phase6':
          'Vaihe 6 – Pitkän aikavälin kehitys',

      'phase6Title':
          'Stelluriinin seuraava vaihe',

      'phase6Description':
          'Stelluriini-ekosysteemin jatkuva kehitys, uudet ominaisuudet ja yhteisön tarpeisiin vastaaminen.',

      'phase7':
          'Vaihe 7 – Mainnet',

      'phase7Title':
          'Solana Mainnet ja STL-nostot',

      'phase7Description':
          'Stelluriinin Solana Mainnet -vaiheen avaaminen sekä STL-nostojen käyttöönotto testausten ja turvallisuustarkistusten jälkeen.',

      'phase8':
          'Vaihe 8 – Ekosysteemi',

      'phase8Title':
          'Pörssit ja ekosysteemi',

      'phase8Description':
          'DEX- ja CEX-mahdollisuuksien, likviditeettiratkaisujen, kumppanuuksien ja tulevien STL-käyttötapojen tutkiminen.',

      'statusInProgress':
          'Käynnissä',

      'statusTesting':
          'Testauksessa',

      'statusPlanned':
          'Suunniteltu',

      'statusFuture':
          'Tulevaisuudessa',

      'miningBalanceTitle':
          'Louhintatalouden tasapaino',

      'miningBalanceDescription':
          'Louhintajärjestelmän tavoitteena ei ole kasvattaa päivittäistä STL-tuotantoa rajattomasti. Hash Rate, Power Boost ja Referral-bonukset suunnitellaan yhdessä niin, että kokonaisuus pysyy hallittavana.',

      'hashRateTitle':
          'Hash Rate',

      'hashRateDescription':
          'Peruslouhinta muodostaa käyttäjän normaalin Hash Rate -tason.',

      'powerBoostTitle':
          'Power Boost',

      'powerBoostDescription':
          'Power Boost tarjoaa määräaikaisen lisäyksen käyttäjän louhintatehoon.',

      'referralTitle':
          'Referral',

      'referralDescription':
          'Referral-bonukset suunnitellaan kasvun mukana tasapainottuviksi.',

      'withdrawalTitle':
          'Mahdolliset tulevat nostot',

      'withdrawalDescription':
          'Mahdollinen tuleva nostojärjestelmä suunnitellaan erikseen, ja sen ehdot ilmoitetaan ennen käyttöönottoa.',

      'plannedMinimumWithdrawal':
          'Suunniteltu vähimmäisnosto',

      'networkFee':
          'Käyttäjä maksaa Solanan verkkomaksun.',

      'stellaJourneyTitle':
          'Stellan matka 🐾',

      'stellaJourneyDescription':
          'Stelluriini-ekosysteemiä kehitetään vaiheittain yhteisön, sovelluksen ja STL-tokenin ympärille.',

      'developmentPrinciplesTitle':
          'Kehitysperiaatteet',

      'communityTitle':
          'Yhteisö',

      'communityDescription':
          'Yhteisö on Stelluriinin kehityksen keskiössä. Palaute ja käyttäjien ideat auttavat ohjaamaan tulevaa kehitystä.',

      'securityTitle':
          'Turvallisuus',

      'securityDescription':
          'Turvallisuutta, palvelininfrastruktuuria ja sovelluksen luotettavuutta kehitetään jatkuvasti.',

      'antiBotTitle':
          'Botintorjunta',

      'antiBotDescription':
          'Järjestelmässä huomioidaan botit, automaatio ja väärinkäytösten tunnistaminen.',

      'innovationTitle':
          'Innovaatio',

      'innovationDescription':
          'Uusia käyttötapoja, ominaisuuksia ja teknologioita tutkitaan projektin kehittyessä.',

      'longTermGrowthTitle':
          'Pitkän aikavälin kasvu',

      'longTermGrowthDescription':
          'Tavoitteena on rakentaa kestävä ja asteittain kehittyvä Stelluriini-ekosysteemi.',

      'importantNoticeTitle':
          'Tärkeä huomautus',

      'importantNoticeDescription':
          'Roadmap kuvaa Stelluriinin suunniteltua kehityssuuntaa. Vaiheet, ominaisuudet ja aikataulut voivat muuttua projektin kehityksen aikana.',

      'footer':
          'STELLA • STELLURIINI • STL • SOLANA',
    },

    // ========================================================
    // 🇩🇪 GERMAN
    // ========================================================

    'de': {
      'pageTitle':
          'Stelluriini Roadmap',

      'journeyTitle':
          'Die Reise von Stelluriini',

      'journeyDescription':
          'Die Entwicklung von Stelluriini schreitet Schritt für Schritt zu einer größeren Community, einem erweiterten Ökosystem und neuen Anwendungsfällen voran.',

      'phase1':
          'Phase 1 – Grundlage',

      'phase1Title':
          'Stelluriini aufbauen',

      'phase1Description':
          'Aufbau des Stelluriini-Projekts, des STL-Tokens und des Stella-Ökosystems.',

      'phase2':
          'Phase 2 – App',

      'phase2Title':
          'Entwicklung der Stelluriini-App',

      'phase2Description':
          'Mining, Stella Power Boost, Benutzerfortschritt und Transaktionsverlauf.',

      'phase3':
          'Phase 3 – Community',

      'phase3Title':
          'Aufbau der Community',

      'phase3Description':
          'Aufbau der Community, Sammlung von Feedback und Entwicklung der Stelluriini-Marke.',

      'phase4':
          'Phase 4 – Ökosystem',

      'phase4Title':
          'Erweiterung des STL-Ökosystems',

      'phase4Description':
          'Entwicklung von Anwendungsfällen für den STL-Token und Erweiterung des Stelluriini-Ökosystems.',

      'phase5':
          'Phase 5 – Testnet',

      'phase5Title':
          'Solana Testnet',

      'phase5Description':
          'Testen von STL-Transfers, Wallet-Verbindungen, Transaktionen und Auszahlungsfunktionen vor dem Mainnet.',

      'phase6':
          'Phase 6 – Langfristige Entwicklung',

      'phase6Title':
          'Die nächste Phase von Stelluriini',

      'phase6Description':
          'Kontinuierliche Entwicklung des Stelluriini-Ökosystems, neue Funktionen und Reaktionen auf die Bedürfnisse der Community.',

      'phase7':
          'Phase 7 – Mainnet',

      'phase7Title':
          'Solana Mainnet & STL-Auszahlungen',

      'phase7Description':
          'Start der Stelluriini-Solana-Mainnet-Phase und Einführung von STL-Auszahlungen nach Tests und Sicherheitsprüfungen.',

      'phase8':
          'Phase 8 – Ökosystem',

      'phase8Title':
          'Börsen & Ökosystem',

      'phase8Description':
          'Erkundung von DEX- und CEX-Möglichkeiten, Liquiditätslösungen, Partnerschaften und zukünftigen STL-Anwendungsfällen.',

      'statusInProgress':
          'In Bearbeitung',

      'statusTesting':
          'Testphase',

      'statusPlanned':
          'Geplant',

      'statusFuture':
          'Zukunft',

      'miningBalanceTitle':
          'Gleichgewicht der Mining-Wirtschaft',

      'miningBalanceDescription':
          'Das Mining-System soll die tägliche STL-Produktion nicht unbegrenzt erhöhen. Hash Rate, Power Boost und Referral-Boni werden gemeinsam so gestaltet, dass das Gesamtsystem kontrollierbar bleibt.',

      'hashRateTitle':
          'Hash Rate',

      'hashRateDescription':
          'Das normale Mining bildet die reguläre Hash-Rate des Benutzers.',

      'powerBoostTitle':
          'Power Boost',

      'powerBoostDescription':
          'Power Boost bietet eine zeitlich begrenzte Erhöhung der Mining-Leistung.',

      'referralTitle':
          'Referral',

      'referralDescription':
          'Referral-Boni werden so gestaltet, dass sie mit dem Wachstum der Community ausgewogen bleiben.',

      'withdrawalTitle':
          'Mögliche zukünftige Auszahlungen',

      'withdrawalDescription':
          'Ein mögliches zukünftiges Auszahlungssystem wird separat entwickelt. Die Bedingungen werden vor der Einführung bekannt gegeben.',

      'plannedMinimumWithdrawal':
          'Geplante Mindestauszahlung',

      'networkFee':
          'Der Benutzer trägt die Solana-Netzwerkgebühr.',

      'stellaJourneyTitle':
          'Stellas Reise 🐾',

      'stellaJourneyDescription':
          'Das Stelluriini-Ökosystem wird Schritt für Schritt rund um Community, App und STL-Token entwickelt.',

      'developmentPrinciplesTitle':
          'Entwicklungsprinzipien',

      'communityTitle':
          'Community',

      'communityDescription':
          'Die Community steht im Mittelpunkt der Stelluriini-Entwicklung. Feedback und Benutzerideen helfen bei der zukünftigen Entwicklung.',

      'securityTitle':
          'Sicherheit',

      'securityDescription':
          'Sicherheit, Serverinfrastruktur und Zuverlässigkeit der Anwendung werden kontinuierlich verbessert.',

      'antiBotTitle':
          'Bot-Schutz',

      'antiBotDescription':
          'Das System berücksichtigt Bots, Automatisierung und die Erkennung von Missbrauch.',

      'innovationTitle':
          'Innovation',

      'innovationDescription':
          'Neue Anwendungsfälle, Funktionen und Technologien werden während der Projektentwicklung untersucht.',

      'longTermGrowthTitle':
          'Langfristiges Wachstum',

      'longTermGrowthDescription':
          'Ziel ist der Aufbau eines nachhaltigen und sich schrittweise entwickelnden Stelluriini-Ökosystems.',

      'importantNoticeTitle':
          'Wichtiger Hinweis',

      'importantNoticeDescription':
          'Die Roadmap beschreibt die geplante Entwicklungsrichtung von Stelluriini. Phasen, Funktionen und Zeitpläne können sich während der Projektentwicklung ändern.',

      'footer':
          'STELLA • STELLURIINI • STL • SOLANA',
    },

    // ========================================================
    // 🇪🇸 SPANISH
    // ========================================================

    'es': {
      'pageTitle':
          'Hoja de ruta de Stelluriini',

      'journeyTitle':
          'El viaje de Stelluriini',

      'journeyDescription':
          'El desarrollo de Stelluriini avanza paso a paso hacia una comunidad más amplia, un ecosistema mayor y nuevos casos de uso.',

      'phase1':
          'Fase 1 – Fundación',

      'phase1Title':
          'Construyendo Stelluriini',

      'phase1Description':
          'Construcción del proyecto Stelluriini, el token STL y el ecosistema de Stella.',

      'phase2':
          'Fase 2 – App',

      'phase2Title':
          'Desarrollo de la aplicación Stelluriini',

      'phase2Description':
          'Minería, Stella Power Boost, progreso del usuario e historial de transacciones.',

      'phase3':
          'Fase 3 – Comunidad',

      'phase3Title':
          'Crecimiento de la comunidad',

      'phase3Description':
          'Construcción de la comunidad, recopilación de comentarios y desarrollo de la marca Stelluriini.',

      'phase4':
          'Fase 4 – Ecosistema',

      'phase4Title':
          'Expansión del ecosistema STL',

      'phase4Description':
          'Desarrollo de casos de uso del token STL y expansión del ecosistema Stelluriini.',

      'phase5':
          'Fase 5 – Testnet',

      'phase5Title':
          'Solana Testnet',

      'phase5Description':
          'Pruebas de transferencias STL, conexiones de wallets, transacciones y funciones de retiro antes de Mainnet.',

      'phase6':
          'Fase 6 – Desarrollo a largo plazo',

      'phase6Title':
          'La siguiente etapa de Stelluriini',

      'phase6Description':
          'Desarrollo continuo del ecosistema Stelluriini, nuevas funciones y respuesta a las necesidades de la comunidad.',

      'phase7':
          'Fase 7 – Mainnet',

      'phase7Title':
          'Solana Mainnet y retiros STL',

      'phase7Description':
          'Apertura de la fase Solana Mainnet de Stelluriini e introducción de retiros STL después de las pruebas y controles de seguridad.',

      'phase8':
          'Fase 8 – Ecosistema',

      'phase8Title':
          'Exchange y ecosistema',

      'phase8Description':
          'Exploración de oportunidades DEX y CEX, soluciones de liquidez, asociaciones y futuros casos de uso de STL.',

      'statusInProgress':
          'En progreso',

      'statusTesting':
          'En pruebas',

      'statusPlanned':
          'Planificado',

      'statusFuture':
          'Futuro',

      'miningBalanceTitle':
          'Equilibrio de la economía de minería',

      'miningBalanceDescription':
          'El objetivo del sistema de minería no es aumentar la producción diaria de STL sin límites. Hash Rate, Power Boost y las bonificaciones de Referral se diseñan conjuntamente para mantener el sistema controlado.',

      'hashRateTitle':
          'Hash Rate',

      'hashRateDescription':
          'La minería básica establece el nivel normal de Hash Rate del usuario.',

      'powerBoostTitle':
          'Power Boost',

      'powerBoostDescription':
          'Power Boost proporciona un aumento temporal de la potencia de minería del usuario.',

      'referralTitle':
          'Referral',

      'referralDescription':
          'Las bonificaciones de Referral se diseñarán para mantenerse equilibradas a medida que crezca la comunidad.',

      'withdrawalTitle':
          'Posibles retiros futuros',

      'withdrawalDescription':
          'Un posible sistema de retiros futuro se diseñará por separado y sus condiciones se anunciarán antes de su implementación.',

      'plannedMinimumWithdrawal':
          'Retiro mínimo previsto',

      'networkFee':
          'El usuario paga la comisión de red de Solana.',

      'stellaJourneyTitle':
          'El viaje de Stella 🐾',

      'stellaJourneyDescription':
          'El ecosistema Stelluriini se desarrollará paso a paso alrededor de la comunidad, la aplicación y el token STL.',

      'developmentPrinciplesTitle':
          'Principios de desarrollo',

      'communityTitle':
          'Comunidad',

      'communityDescription':
          'La comunidad está en el centro del desarrollo de Stelluriini. Los comentarios y las ideas de los usuarios ayudan a orientar el desarrollo futuro.',

      'securityTitle':
          'Seguridad',

      'securityDescription':
          'La seguridad, la infraestructura del servidor y la fiabilidad de la aplicación se mejorarán continuamente.',

      'antiBotTitle':
          'Protección contra bots',

      'antiBotDescription':
          'El sistema tendrá en cuenta los bots, la automatización y la detección de abusos.',

      'innovationTitle':
          'Innovación',

      'innovationDescription':
          'Se explorarán nuevos casos de uso, funciones y tecnologías a medida que el proyecto avance.',

      'longTermGrowthTitle':
          'Crecimiento a largo plazo',

      'longTermGrowthDescription':
          'El objetivo es construir un ecosistema Stelluriini sostenible y en evolución gradual.',

      'importantNoticeTitle':
          'Aviso importante',

      'importantNoticeDescription':
          'La hoja de ruta describe la dirección de desarrollo prevista de Stelluriini. Las fases, funciones y fechas pueden cambiar durante el desarrollo del proyecto.',

      'footer':
          'STELLA • STELLURIINI • STL • SOLANA',
    },

    // ========================================================
    // 🇫🇷 FRENCH
    // ========================================================

    'fr': {
      'pageTitle':
          'Feuille de route Stelluriini',

      'journeyTitle':
          'Le voyage de Stelluriini',

      'journeyDescription':
          'Le développement de Stelluriini progresse étape par étape vers une communauté plus large, un écosystème étendu et de nouveaux cas d’utilisation.',

      'phase1':
          'Phase 1 – Fondation',

      'phase1Title':
          'Construire Stelluriini',

      'phase1Description':
          'Construction du projet Stelluriini, du token STL et de l’écosystème Stella.',

      'phase2':
          'Phase 2 – Application',

      'phase2Title':
          'Développement de l’application Stelluriini',

      'phase2Description':
          'Mining, Stella Power Boost, progression utilisateur et historique des transactions.',

      'phase3':
          'Phase 3 – Communauté',

      'phase3Title':
          'Développer la communauté',

      'phase3Description':
          'Construire la communauté, recueillir les retours et développer la marque Stelluriini.',

      'phase4':
          'Phase 4 – Écosystème',

      'phase4Title':
          'Étendre l’écosystème STL',

      'phase4Description':
          'Développer les cas d’utilisation du token STL et étendre l’écosystème Stelluriini.',

      'phase5':
          'Phase 5 – Testnet',

      'phase5Title':
          'Solana Testnet',

      'phase5Description':
          'Tester les transferts STL, les connexions de wallets, les transactions et les retraits avant le Mainnet.',

      'phase6':
          'Phase 6 – Développement à long terme',

      'phase6Title':
          'La prochaine étape de Stelluriini',

      'phase6Description':
          'Développement continu de l’écosystème Stelluriini, nouvelles fonctionnalités et réponse aux besoins de la communauté.',

      'phase7':
          'Phase 7 – Mainnet',

      'phase7Title':
          'Solana Mainnet et retraits STL',

      'phase7Description':
          'Ouverture de la phase Solana Mainnet de Stelluriini et introduction des retraits STL après les tests et contrôles de sécurité.',

      'phase8':
          'Phase 8 – Écosystème',

      'phase8Title':
          'Exchange et écosystème',

      'phase8Description':
          'Exploration des opportunités DEX et CEX, solutions de liquidité, partenariats et futurs cas d’utilisation du STL.',

      'statusInProgress':
          'En cours',

      'statusTesting':
          'En test',

      'statusPlanned':
          'Prévu',

      'statusFuture':
          'Futur',

      'miningBalanceTitle':
          'Équilibre de l’économie du mining',

      'miningBalanceDescription':
          'Le système de mining n’a pas pour objectif d’augmenter indéfiniment la production quotidienne de STL. Hash Rate, Power Boost et les bonus Referral sont conçus ensemble afin de maintenir un système équilibré.',

      'hashRateTitle':
          'Hash Rate',

      'hashRateDescription':
          'Le mining de base constitue le niveau normal de Hash Rate de l’utilisateur.',

      'powerBoostTitle':
          'Power Boost',

      'powerBoostDescription':
          'Power Boost fournit une augmentation temporaire de la puissance de mining de l’utilisateur.',

      'referralTitle':
          'Referral',

      'referralDescription':
          'Les bonus Referral seront conçus pour rester équilibrés avec la croissance de la communauté.',

      'withdrawalTitle':
          'Retraits futurs possibles',

      'withdrawalDescription':
          'Un éventuel système de retrait futur sera conçu séparément et ses conditions seront annoncées avant sa mise en œuvre.',

      'plannedMinimumWithdrawal':
          'Retrait minimum prévu',

      'networkFee':
          'L’utilisateur paie les frais du réseau Solana.',

      'stellaJourneyTitle':
          'Le voyage de Stella 🐾',

      'stellaJourneyDescription':
          'L’écosystème Stelluriini sera développé progressivement autour de la communauté, de l’application et du token STL.',

      'developmentPrinciplesTitle':
          'Principes de développement',

      'communityTitle':
          'Communauté',

      'communityDescription':
          'La communauté est au cœur du développement de Stelluriini. Les retours et les idées des utilisateurs contribuent à orienter le développement futur.',

      'securityTitle':
          'Sécurité',

      'securityDescription':
          'La sécurité, l’infrastructure serveur et la fiabilité de l’application seront améliorées continuellement.',

      'antiBotTitle':
          'Protection contre les bots',

      'antiBotDescription':
          'Le système prendra en compte les bots, l’automatisation et la détection des abus.',

      'innovationTitle':
          'Innovation',

      'innovationDescription':
          'De nouveaux cas d’utilisation, fonctionnalités et technologies seront explorés au fur et à mesure de l’évolution du projet.',

      'longTermGrowthTitle':
          'Croissance à long terme',

      'longTermGrowthDescription':
          'L’objectif est de construire un écosystème Stelluriini durable et évolutif.',

      'importantNoticeTitle':
          'Avis important',

      'importantNoticeDescription':
          'La feuille de route décrit l’orientation prévue du développement de Stelluriini. Les phases, fonctionnalités et calendriers peuvent changer au cours du développement du projet.',

      'footer':
          'STELLA • STELLURIINI • STL • SOLANA',
    },

    // ========================================================
    // 🇨🇳 CHINESE
    // ========================================================

    'zh': {
      'pageTitle':
          'Stelluriini 路线图',

      'journeyTitle':
          'Stelluriini 的发展之旅',

      'journeyDescription':
          'Stelluriini 将一步一步发展，逐渐建立更大的社区、生态系统以及新的应用场景。',

      'phase1':
          '阶段 1 – 基础建设',

      'phase1Title':
          '构建 Stelluriini',

      'phase1Description':
          '构建 Stelluriini 项目、STL 代币以及 Stella 生态系统。',

      'phase2':
          '阶段 2 – 应用程序',

      'phase2Title':
          'Stelluriini 应用开发',

      'phase2Description':
          '挖矿、Stella Power Boost、用户进度以及交易记录。',

      'phase3':
          '阶段 3 – 社区',

      'phase3Title':
          '发展社区',

      'phase3Description':
          '建设社区、收集用户反馈并发展 Stelluriini 品牌。',

      'phase4':
          '阶段 4 – 生态系统',

      'phase4Title':
          '扩展 STL 生态系统',

      'phase4Description':
          '开发 STL 代币的应用场景并扩展 Stelluriini 生态系统。',

      'phase5':
          '阶段 5 – 测试网',

      'phase5Title':
          'Solana 测试网',

      'phase5Description':
          '在主网上线之前测试 STL 转账、钱包连接、交易以及提现功能。',

      'phase6':
          '阶段 6 – 长期发展',

      'phase6Title':
          'Stelluriini 的下一阶段',

      'phase6Description':
          '持续发展 Stelluriini 生态系统、推出新功能并响应社区需求。',

      'phase7':
          '阶段 7 – 主网',

      'phase7Title':
          'Solana 主网与 STL 提现',

      'phase7Description':
          '在完成测试和安全检查后，开启 Stelluriini Solana 主网阶段并推出 STL 提现功能。',

      'phase8':
          '阶段 8 – 生态系统',

      'phase8Title':
          '交易所与生态系统',

      'phase8Description':
          '探索 DEX 和 CEX 机会、流动性方案、合作伙伴关系以及未来 STL 应用场景。',

      'statusInProgress':
          '进行中',

      'statusTesting':
          '测试中',

      'statusPlanned':
          '计划中',

      'statusFuture':
          '未来',

      'miningBalanceTitle':
          '挖矿经济平衡',

      'miningBalanceDescription':
          '挖矿系统的目标不是无限增加每日 STL 产出。Hash Rate、Power Boost 和 Referral 奖励将共同设计，以保持整体系统的可控性。',

      'hashRateTitle':
          'Hash Rate',

      'hashRateDescription':
          '基础挖矿形成用户正常的 Hash Rate 水平。',

      'powerBoostTitle':
          'Power Boost',

      'powerBoostDescription':
          'Power Boost 为用户提供临时的挖矿能力提升。',

      'referralTitle':
          'Referral',

      'referralDescription':
          'Referral 奖励将随着社区增长进行平衡设计。',

      'withdrawalTitle':
          '未来可能的提现',

      'withdrawalDescription':
          '未来可能推出的提现系统将单独设计，并在实施前公布具体条件。',

      'plannedMinimumWithdrawal':
          '计划中的最低提现额度',

      'networkFee':
          '用户承担 Solana 网络费用。',

      'stellaJourneyTitle':
          'Stella 的旅程 🐾',

      'stellaJourneyDescription':
          'Stelluriini 生态系统将围绕社区、应用程序和 STL 代币逐步发展。',

      'developmentPrinciplesTitle':
          '开发原则',

      'communityTitle':
          '社区',

      'communityDescription':
          '社区是 Stelluriini 开发的核心。用户反馈和想法将帮助指导未来的发展。',

      'securityTitle':
          '安全',

      'securityDescription':
          '系统安全、服务器基础设施以及应用可靠性将持续改进。',

      'antiBotTitle':
          '机器人防护',

      'antiBotDescription':
          '系统将考虑机器人、自动化操作以及滥用行为的检测。',

      'innovationTitle':
          '创新',

      'innovationDescription':
          '随着项目的发展，我们将探索新的应用场景、功能和技术。',

      'longTermGrowthTitle':
          '长期发展',

      'longTermGrowthDescription':
          '目标是建立一个可持续并逐步发展的 Stelluriini 生态系统。',

      'importantNoticeTitle':
          '重要说明',

      'importantNoticeDescription':
          '路线图描述了 Stelluriini 计划中的发展方向。项目开发过程中，阶段、功能和时间安排可能发生变化。',

      'footer':
          'STELLA • STELLURIINI • STL • SOLANA',
    },

    // ========================================================
    // 🇻🇳 VIETNAMESE
    // ========================================================

    'vi': {
      'pageTitle':
          'Lộ trình Stelluriini',

      'journeyTitle':
          'Hành trình Stelluriini',

      'journeyDescription':
          'Stelluriini sẽ phát triển từng bước hướng tới một cộng đồng lớn hơn, hệ sinh thái mở rộng và những trường hợp sử dụng mới.',

      'phase1':
          'Giai đoạn 1 – Nền tảng',

      'phase1Title':
          'Xây dựng Stelluriini',

      'phase1Description':
          'Xây dựng dự án Stelluriini, token STL và hệ sinh thái Stella.',

      'phase2':
          'Giai đoạn 2 – Ứng dụng',

      'phase2Title':
          'Phát triển ứng dụng Stelluriini',

      'phase2Description':
          'Khai thác, Stella Power Boost, tiến trình người dùng và lịch sử giao dịch.',

      'phase3':
          'Giai đoạn 3 – Cộng đồng',

      'phase3Title':
          'Phát triển cộng đồng',

      'phase3Description':
          'Xây dựng cộng đồng, thu thập phản hồi và phát triển thương hiệu Stelluriini.',

      'phase4':
          'Giai đoạn 4 – Hệ sinh thái',

      'phase4Title':
          'Mở rộng hệ sinh thái STL',

      'phase4Description':
          'Phát triển các trường hợp sử dụng của token STL và mở rộng hệ sinh thái Stelluriini.',

      'phase5':
          'Giai đoạn 5 – Testnet',

      'phase5Title':
          'Solana Testnet',

      'phase5Description':
          'Kiểm thử chuyển STL, kết nối ví, giao dịch và chức năng rút tiền trước Mainnet.',

      'phase6':
          'Giai đoạn 6 – Phát triển dài hạn',

      'phase6Title':
          'Giai đoạn tiếp theo của Stelluriini',

      'phase6Description':
          'Tiếp tục phát triển hệ sinh thái Stelluriini, các tính năng mới và đáp ứng nhu cầu của cộng đồng.',

      'phase7':
          'Giai đoạn 7 – Mainnet',

      'phase7Title':
          'Solana Mainnet & Rút STL',

      'phase7Description':
          'Mở giai đoạn Solana Mainnet của Stelluriini và giới thiệu chức năng rút STL sau khi hoàn tất kiểm thử và kiểm tra bảo mật.',

      'phase8':
          'Giai đoạn 8 – Hệ sinh thái',

      'phase8Title':
          'Sàn giao dịch & Hệ sinh thái',

      'phase8Description':
          'Nghiên cứu cơ hội DEX và CEX, giải pháp thanh khoản, quan hệ đối tác và các trường hợp sử dụng STL trong tương lai.',

      'statusInProgress':
          'Đang thực hiện',

      'statusTesting':
          'Đang kiểm thử',

      'statusPlanned':
          'Đã lên kế hoạch',

      'statusFuture':
          'Tương lai',

      'miningBalanceTitle':
          'Cân bằng kinh tế khai thác',

      'miningBalanceDescription':
          'Mục tiêu của hệ thống khai thác không phải là tăng sản lượng STL hàng ngày một cách không giới hạn. Hash Rate, Power Boost và phần thưởng Referral được thiết kế cùng nhau để giữ hệ thống trong tầm kiểm soát.',

      'hashRateTitle':
          'Hash Rate',

      'hashRateDescription':
          'Khai thác cơ bản tạo nên mức Hash Rate thông thường của người dùng.',

      'powerBoostTitle':
          'Power Boost',

      'powerBoostDescription':
          'Power Boost cung cấp mức tăng sức mạnh khai thác tạm thời cho người dùng.',

      'referralTitle':
          'Referral',

      'referralDescription':
          'Phần thưởng Referral sẽ được thiết kế cân bằng khi cộng đồng phát triển.',

      'withdrawalTitle':
          'Khả năng rút tiền trong tương lai',

      'withdrawalDescription':
          'Một hệ thống rút tiền trong tương lai nếu được triển khai sẽ được thiết kế riêng và các điều khoản sẽ được công bố trước khi thực hiện.',

      'plannedMinimumWithdrawal':
          'Mức rút tối thiểu dự kiến',

      'networkFee':
          'Người dùng thanh toán phí mạng Solana.',

      'stellaJourneyTitle':
          'Hành trình của Stella 🐾',

      'stellaJourneyDescription':
          'Hệ sinh thái Stelluriini sẽ được phát triển từng bước xoay quanh cộng đồng, ứng dụng và token STL.',

      'developmentPrinciplesTitle':
          'Nguyên tắc phát triển',

      'communityTitle':
          'Cộng đồng',

      'communityDescription':
          'Cộng đồng là trung tâm của quá trình phát triển Stelluriini. Phản hồi và ý tưởng của người dùng giúp định hướng phát triển trong tương lai.',

      'securityTitle':
          'Bảo mật',

      'securityDescription':
          'Bảo mật, cơ sở hạ tầng máy chủ và độ tin cậy của ứng dụng sẽ liên tục được cải thiện.',

      'antiBotTitle':
          'Bảo vệ chống bot',

      'antiBotDescription':
          'Hệ thống sẽ xem xét bot, tự động hóa và việc phát hiện hành vi lạm dụng.',

      'innovationTitle':
          'Đổi mới',

      'innovationDescription':
          'Các trường hợp sử dụng, tính năng và công nghệ mới sẽ được nghiên cứu khi dự án phát triển.',

      'longTermGrowthTitle':
          'Tăng trưởng dài hạn',

      'longTermGrowthDescription':
          'Mục tiêu là xây dựng một hệ sinh thái Stelluriini bền vững và phát triển từng bước.',

      'importantNoticeTitle':
          'Thông báo quan trọng',

      'importantNoticeDescription':
          'Lộ trình mô tả hướng phát triển dự kiến của Stelluriini. Các giai đoạn, tính năng và thời gian có thể thay đổi trong quá trình phát triển dự án.',

      'footer':
          'STELLA • STELLURIINI • STL • SOLANA',
    },

    // ========================================================
    // 🇯🇵 JAPANESE
    // ========================================================

    'ja': {
      'pageTitle':
          'Stelluriini ロードマップ',

      'journeyTitle':
          'Stelluriini の旅',

      'journeyDescription':
          'Stelluriini は、より大きなコミュニティ、エコシステム、そして新しい利用方法に向けて段階的に開発を進めます。',

      'phase1':
          'フェーズ 1 – 基盤',

      'phase1Title':
          'Stelluriini の構築',

      'phase1Description':
          'Stelluriini プロジェクト、STL トークン、Stella エコシステムを構築します。',

      'phase2':
          'フェーズ 2 – アプリ',

      'phase2Title':
          'Stelluriini アプリ開発',

      'phase2Description':
          'マイニング、Stella Power Boost、ユーザー進行状況、取引履歴を開発します。',

      'phase3':
          'フェーズ 3 – コミュニティ',

      'phase3Title':
          'コミュニティの成長',

      'phase3Description':
          'コミュニティの構築、フィードバックの収集、Stelluriini ブランドの開発を進めます。',

      'phase4':
          'フェーズ 4 – エコシステム',

      'phase4Title':
          'STL エコシステムの拡大',

      'phase4Description':
          'STL トークンの利用方法を開発し、Stelluriini エコシステムを拡大します。',

      'phase5':
          'フェーズ 5 – Testnet',

      'phase5Title':
          'Solana Testnet',

      'phase5Description':
          'Mainnet 前に STL の送金、ウォレット接続、取引、出金機能をテストします。',

      'phase6':
          'フェーズ 6 – 長期開発',

      'phase6Title':
          'Stelluriini の次のステージ',

      'phase6Description':
          'Stelluriini エコシステムを継続的に開発し、新機能を追加し、コミュニティのニーズに対応します。',

      'phase7':
          'フェーズ 7 – Mainnet',

      'phase7Title':
          'Solana Mainnet & STL 出金',

      'phase7Description':
          'テストとセキュリティ確認の完了後、Stelluriini Solana Mainnet フェーズを開始し、STL 出金機能を導入します。',

      'phase8':
          'フェーズ 8 – エコシステム',

      'phase8Title':
          '取引所 & エコシステム',

      'phase8Description':
          'DEX・CEX の可能性、流動性ソリューション、パートナーシップ、将来の STL 利用方法を検討します。',

      'statusInProgress':
          '進行中',

      'statusTesting':
          'テスト中',

      'statusPlanned':
          '予定',

      'statusFuture':
          '将来',

      'miningBalanceTitle':
          'マイニング経済のバランス',

      'miningBalanceDescription':
          'マイニングシステムの目的は、毎日の STL 生成量を無制限に増やすことではありません。Hash Rate、Power Boost、Referral ボーナスを組み合わせ、システム全体を管理可能な状態に保ちます。',

      'hashRateTitle':
          'Hash Rate',

      'hashRateDescription':
          '通常のマイニングによってユーザーの基本 Hash Rate が形成されます。',

      'powerBoostTitle':
          'Power Boost',

      'powerBoostDescription':
          'Power Boost は、ユーザーのマイニング能力を一定時間強化します。',

      'referralTitle':
          'Referral',

      'referralDescription':
          'Referral ボーナスは、コミュニティの成長に合わせてバランスを保つよう設計されます。',

      'withdrawalTitle':
          '将来の出金の可能性',

      'withdrawalDescription':
          '将来的に出金システムを導入する場合は別途設計し、実装前に条件を発表します。',

      'plannedMinimumWithdrawal':
          '予定されている最低出金額',

      'networkFee':
          'Solana ネットワーク手数料はユーザーが負担します。',

      'stellaJourneyTitle':
          'Stella の旅 🐾',

      'stellaJourneyDescription':
          'Stelluriini エコシステムは、コミュニティ、アプリ、STL トークンを中心に段階的に開発されます。',

      'developmentPrinciplesTitle':
          '開発方針',

      'communityTitle':
          'コミュニティ',

      'communityDescription':
          'コミュニティは Stelluriini 開発の中心です。ユーザーからのフィードバックやアイデアが今後の開発を導きます。',

      'securityTitle':
          'セキュリティ',

      'securityDescription':
          'セキュリティ、サーバーインフラ、アプリケーションの信頼性を継続的に改善します。',

      'antiBotTitle':
          'ボット対策',

      'antiBotDescription':
          'ボット、自動化、不正利用の検出をシステム設計に取り入れます。',

      'innovationTitle':
          'イノベーション',

      'innovationDescription':
          'プロジェクトの成長に合わせて、新しい利用方法、機能、技術を検討します。',

      'longTermGrowthTitle':
          '長期的な成長',

      'longTermGrowthDescription':
          '持続可能で段階的に成長する Stelluriini エコシステムの構築を目指します。',

      'importantNoticeTitle':
          '重要なお知らせ',

      'importantNoticeDescription':
          'このロードマップは Stelluriini の予定されている開発方針を示すものです。プロジェクトの開発中にフェーズ、機能、スケジュールが変更される場合があります。',

      'footer':
          'STELLA • STELLURIINI • STL • SOLANA',
    },
  };
}