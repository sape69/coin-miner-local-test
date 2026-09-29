// ============================================================
// 🐱 STELLURIINI - ROADMAP LOCALIZATION
// ============================================================
//
// Supported languages:
// 🇫🇮 Finnish
// 🇬🇧 English
// 🇩🇪 German
// 🇪🇸 Spanish
// 🇫🇷 French
// 🇨🇳 Chinese
// 🇻🇳 Vietnamese
// 🇯🇵 Japanese
//
// ============================================================

class RoadmapLocalization {
  final String languageCode;

  const RoadmapLocalization(
    this.languageCode,
  );

  // ==========================================================
  // 🌍 TRANSLATION
  // ==========================================================

  String get(String key) {
    final Map<String, String> translations =
        _translations[languageCode] ??
            _translations['en']!;

    return translations[key] ??
        _translations['en']![key] ??
        key;
  }

  // ==========================================================
  // 🌍 ALL TRANSLATIONS
  // ==========================================================

  static const Map<String, Map<String, String>>
      _translations = {
    // ========================================================
    // 🇫🇮 FINNISH
    // ========================================================

    'fi': {
      'roadmapTitle': 'Stelluriini Roadmap',
      'journeyTitle': 'Stelluriinin matka',
      'journeyDescription':
          'Stelluriinin kehitys etenee vaiheittain kohti laajempaa yhteisöä, ekosysteemiä ja uusia käyttötapoja.',

      'phase1': 'Vaihe 1 – Perusta',
      'phase1Title': 'Stelluriinin rakentaminen',
      'phase1Description':
          'Stelluriini-projektin, STL-tokenin ja Stella-ekosysteemin rakentaminen.',
      'phase1Status': 'Käynnissä',

      'phase2': 'Vaihe 2 – Sovellus',
      'phase2Title': 'Stelluriini-sovelluksen kehitys',
      'phase2Description':
          'Louhinta, Stellan Power Boost, käyttäjän eteneminen ja tapahtumahistoria.',
      'phase2Status': 'Käynnissä',

      'phase3': 'Vaihe 3 – Yhteisö',
      'phase3Title': 'Yhteisön kasvattaminen',
      'phase3Description':
          'Yhteisön rakentaminen, palautteen kerääminen ja Stelluriini-brändin kehittäminen.',
      'phase3Status': 'Suunniteltu',

      'phase4': 'Vaihe 4 – Ekosysteemi',
      'phase4Title': 'STL-ekosysteemin laajentaminen',
      'phase4Description':
          'STL-tokenin käyttötapojen kehittäminen ja Stelluriini-ekosysteemin laajentaminen.',
      'phase4Status': 'Suunniteltu',

      'phase5': 'Vaihe 5 – Testnet',
      'phase5Title': 'Solana Testnet',
      'phase5Description':
          'STL-siirtojen, lompakkoyhteyksien, transaktioiden ja nostotoimintojen testaaminen ennen Mainnetiä.',
      'phase5Status': 'Testauksessa',

      'phase6': 'Vaihe 6 – Pitkän aikavälin kehitys',
      'phase6Title': 'Stelluriinin seuraava vaihe',
      'phase6Description':
          'Stelluriini-ekosysteemin jatkuva kehittäminen, uudet ominaisuudet ja yhteisön tarpeisiin vastaaminen.',
      'phase6Status': 'Tulevaisuus',

      'phase7': 'Vaihe 7 – Mainnet',
      'phase7Title': 'Solana Mainnet & STL-nostot',
      'phase7Description':
          'Stelluriinin Solana Mainnet -vaiheen avaaminen sekä STL-nostojen käyttöönotto testauksen ja turvallisuustarkistusten jälkeen.',
      'phase7Status': 'Tulevaisuus',

      'phase8': 'Vaihe 8 – Ekosysteemi',
      'phase8Title': 'Pörssit ja ekosysteemi',
      'phase8Description':
          'DEX- ja CEX-mahdollisuuksien, likviditeettiratkaisujen, kumppanuuksien ja tulevien STL-käyttötapojen tutkiminen.',
      'phase8Status': 'Tulevaisuus',

      'miningBalanceTitle': 'Louhintatalouden tasapaino',
      'miningBalanceDescription':
          'Louhintajärjestelmän tavoitteena ei ole kasvattaa päivittäistä STL-määrää rajattomasti. Hash Rate, Power Boost ja Referral-bonukset suunnitellaan yhdessä niin, että kokonaisuus pysyy hallittavana.',

      'hashRateTitle': 'Hash Rate',
      'hashRateDescription':
          'Peruslouhinta muodostaa käyttäjän normaalin Hash Rate -tason.',

      'powerBoostTitle': 'Power Boost',
      'powerBoostDescription':
          'Power Boost tarjoaa määräaikaisen lisäyksen käyttäjän louhintatehoon.',

      'referralTitle': 'Referral',
      'referralDescription':
          'Referral-bonukset suunnitellaan kasvun mukana tasapainottuviksi.',

      'mainnetNoticeTitle':
          'Mainnet = tuleva julkaisu • Ei vielä käytössä',
      'mainnetNoticeDescription':
          'Ennen käyttöönottoa Solana-integraatio, lompakot, STL-siirrot, nostot ja turvallisuusratkaisut testataan.',

      'ecosystemTitle': 'Pörssi ja ekosysteemi',
      'ecosystemDex':
          'DEX- ja CEX-mahdollisuuksien tutkiminen',
      'ecosystemLiquidity':
          'Likviditeettiratkaisujen valmistelu',
      'ecosystemExpansion':
          'STL-ekosysteemin laajentaminen',
      'ecosystemPartnerships':
          'Kumppanuuksien kehittäminen',
      'ecosystemStella':
          'Uusien Stella-kokemusten esittely',
      'ecosystemUseCases':
          'STL:n tulevien käyttötapojen tutkiminen',

      'withdrawalTitle':
          'Mahdolliset tulevat nostot',
      'withdrawalDescription':
          'Mahdollinen tuleva nostojärjestelmä suunnitellaan erikseen ja sen ehdot ilmoitetaan ennen käyttöönottoa.',
      'minimumWithdrawal':
          'Suunniteltu vähimmäisnosto',
      'userPaysFee':
          'Käyttäjä maksaa Solana-verkon transaktiomaksun.',

      'stellaJourneyTitle':
          'Stellan matka 🐾',
      'stellaJourneyDescription':
          'Stelluriini-ekosysteemiä kehitetään vaiheittain yhteisön, sovelluksen ja STL-tokenin ympärille.',

      'developmentPrinciplesTitle':
          'Kehitysperiaatteet',

      'communityTitle': 'Yhteisö',
      'communityDescription':
          'Yhteisö on Stelluriinin kehityksen ytimessä. Palaute ja käyttäjien ideat auttavat ohjaamaan tulevaa kehitystä.',

      'securityTitle': 'Turvallisuus',
      'securityDescription':
          'Turvallisuutta, palvelininfrastruktuuria ja sovelluksen luotettavuutta parannetaan jatkuvasti.',

      'antiBotTitle': 'Botintorjunta',
      'antiBotDescription':
          'Järjestelmässä huomioidaan botit, automaatio ja väärinkäytösten tunnistaminen.',

      'innovationTitle': 'Innovaatio',
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
    // 🇬🇧 ENGLISH
    // ========================================================

    'en': {
      'roadmapTitle': 'Stelluriini Roadmap',
      'journeyTitle': 'The Stelluriini Journey',
      'journeyDescription':
          'Stelluriini development progresses step by step toward a broader community, ecosystem and new use cases.',

      'phase1': 'Phase 1 – Foundation',
      'phase1Title': 'Building Stelluriini',
      'phase1Description':
          'Building the Stelluriini project, STL token and Stella ecosystem.',
      'phase1Status': 'In Progress',

      'phase2': 'Phase 2 – App',
      'phase2Title': 'Stelluriini App Development',
      'phase2Description':
          'Mining, Stella Power Boost, user progress and transaction history.',
      'phase2Status': 'In Progress',

      'phase3': 'Phase 3 – Community',
      'phase3Title': 'Growing the Community',
      'phase3Description':
          'Building the community, collecting feedback and developing the Stelluriini brand.',
      'phase3Status': 'Planned',

      'phase4': 'Phase 4 – Ecosystem',
      'phase4Title': 'Expanding the STL Ecosystem',
      'phase4Description':
          'Developing STL token use cases and expanding the Stelluriini ecosystem.',
      'phase4Status': 'Planned',

      'phase5': 'Phase 5 – Testnet',
      'phase5Title': 'Solana Testnet',
      'phase5Description':
          'Testing STL transfers, wallet connections, transactions and withdrawal functionality before Mainnet.',
      'phase5Status': 'Testing',

      'phase6': 'Phase 6 – Long-Term Development',
      'phase6Title': 'The Next Stage of Stelluriini',
      'phase6Description':
          'Continuous development of the Stelluriini ecosystem, new features and responses to community needs.',
      'phase6Status': 'Future',

      'phase7': 'Phase 7 – Mainnet',
      'phase7Title': 'Solana Mainnet & STL Withdrawals',
      'phase7Description':
          'Opening the Stelluriini Solana Mainnet phase and introducing STL withdrawals after testing and security checks.',
      'phase7Status': 'Future',

      'phase8': 'Phase 8 – Ecosystem',
      'phase8Title': 'Exchange & Ecosystem',
      'phase8Description':
          'Exploring DEX and CEX opportunities, liquidity solutions, partnerships and future STL use cases.',
      'phase8Status': 'Future',

      'miningBalanceTitle': 'Mining Economy Balance',
      'miningBalanceDescription':
          'The mining system is not designed to increase daily STL production without limits. Hash Rate, Power Boost and Referral bonuses are designed together to keep the overall system manageable.',

      'hashRateTitle': 'Hash Rate',
      'hashRateDescription':
          'Base mining establishes the user’s normal Hash Rate level.',

      'powerBoostTitle': 'Power Boost',
      'powerBoostDescription':
          'Power Boost provides a temporary increase to the user’s mining power.',

      'referralTitle': 'Referral',
      'referralDescription':
          'Referral bonuses will be designed to remain balanced as the community grows.',

      'mainnetNoticeTitle':
          'Mainnet = Future Release • Not Active Yet',
      'mainnetNoticeDescription':
          'Before launch, Solana integration, wallets, STL transfers, withdrawals and security solutions will be tested.',

      'ecosystemTitle': 'Exchange & Ecosystem',
      'ecosystemDex':
          'Exploring DEX and CEX opportunities',
      'ecosystemLiquidity':
          'Preparing liquidity solutions',
      'ecosystemExpansion':
          'Expanding the STL ecosystem',
      'ecosystemPartnerships':
          'Developing partnerships',
      'ecosystemStella':
          'Introducing new Stella experiences',
      'ecosystemUseCases':
          'Exploring future STL use cases',

      'withdrawalTitle':
          'Potential Future Withdrawals',
      'withdrawalDescription':
          'A possible future withdrawal system will be designed separately and its terms will be announced before implementation.',
      'minimumWithdrawal':
          'Planned minimum withdrawal',
      'userPaysFee':
          'User pays the Solana network transaction fee.',

      'stellaJourneyTitle':
          'Stella’s Journey 🐾',
      'stellaJourneyDescription':
          'The Stelluriini ecosystem will be developed step by step around the community, app and STL token.',

      'developmentPrinciplesTitle':
          'Development Principles',

      'communityTitle': 'Community',
      'communityDescription':
          'The community is at the heart of Stelluriini development. Feedback and user ideas help guide future development.',

      'securityTitle': 'Security',
      'securityDescription':
          'Security, server infrastructure and application reliability will be continuously improved.',

      'antiBotTitle': 'Bot Protection',
      'antiBotDescription':
          'The system will account for bots, automation and detection of abuse.',

      'innovationTitle': 'Innovation',
      'innovationDescription':
          'New use cases, features and technologies will be explored as the project develops.',

      'longTermGrowthTitle':
          'Long-Term Growth',
      'longTermGrowthDescription':
          'The goal is to build a sustainable and gradually evolving Stelluriini ecosystem.',

      'importantNoticeTitle':
          'Important Notice',
      'importantNoticeDescription':
          'The roadmap describes the planned development direction of Stelluriini. Phases, features and timelines may change during project development.',

      'footer':
          'STELLA • STELLURIINI • STL • SOLANA',
    },

    // ========================================================
    // 🇩🇪 GERMAN
    // ========================================================

    'de': {
      'roadmapTitle': 'Stelluriini Roadmap',
      'journeyTitle': 'Die Stelluriini-Reise',
      'journeyDescription':
          'Die Entwicklung von Stelluriini schreitet Schritt für Schritt zu einer größeren Community, einem erweiterten Ökosystem und neuen Anwendungsfällen voran.',

      'phase1': 'Phase 1 – Grundlage',
      'phase1Title': 'Stelluriini aufbauen',
      'phase1Description':
          'Aufbau des Stelluriini-Projekts, des STL-Tokens und des Stella-Ökosystems.',
      'phase1Status': 'In Arbeit',

      'phase2': 'Phase 2 – App',
      'phase2Title': 'Entwicklung der Stelluriini-App',
      'phase2Description':
          'Mining, Stella Power Boost, Benutzerfortschritt und Transaktionshistorie.',
      'phase2Status': 'In Arbeit',

      'phase3': 'Phase 3 – Community',
      'phase3Title': 'Aufbau der Community',
      'phase3Description':
          'Aufbau der Community, Sammeln von Feedback und Entwicklung der Stelluriini-Marke.',
      'phase3Status': 'Geplant',

      'phase4': 'Phase 4 – Ökosystem',
      'phase4Title': 'Erweiterung des STL-Ökosystems',
      'phase4Description':
          'Entwicklung von STL-Anwendungsfällen und Erweiterung des Stelluriini-Ökosystems.',
      'phase4Status': 'Geplant',

      'phase5': 'Phase 5 – Testnet',
      'phase5Title': 'Solana Testnet',
      'phase5Description':
          'Testen von STL-Transfers, Wallet-Verbindungen, Transaktionen und Auszahlungen vor dem Mainnet.',
      'phase5Status': 'Testphase',

      'phase6': 'Phase 6 – Langfristige Entwicklung',
      'phase6Title': 'Die nächste Phase von Stelluriini',
      'phase6Description':
          'Kontinuierliche Entwicklung des Stelluriini-Ökosystems, neue Funktionen und Reaktionen auf die Bedürfnisse der Community.',
      'phase6Status': 'Zukunft',

      'phase7': 'Phase 7 – Mainnet',
      'phase7Title': 'Solana Mainnet & STL-Auszahlungen',
      'phase7Description':
          'Start der Solana-Mainnet-Phase von Stelluriini und Einführung von STL-Auszahlungen nach Tests und Sicherheitsprüfungen.',
      'phase7Status': 'Zukunft',

      'phase8': 'Phase 8 – Ökosystem',
      'phase8Title': 'Börsen & Ökosystem',
      'phase8Description':
          'Untersuchung von DEX- und CEX-Möglichkeiten, Liquiditätslösungen, Partnerschaften und zukünftigen STL-Anwendungsfällen.',
      'phase8Status': 'Zukunft',

      'miningBalanceTitle': 'Balance der Mining-Ökonomie',
      'miningBalanceDescription':
          'Das Mining-System soll die tägliche STL-Produktion nicht unbegrenzt erhöhen. Hash Rate, Power Boost und Referral-Boni werden gemeinsam entwickelt, damit das Gesamtsystem kontrollierbar bleibt.',

      'hashRateTitle': 'Hash Rate',
      'hashRateDescription':
          'Das Basis-Mining bestimmt das normale Hash-Rate-Niveau des Benutzers.',

      'powerBoostTitle': 'Power Boost',
      'powerBoostDescription':
          'Power Boost bietet eine zeitlich begrenzte Erhöhung der Mining-Leistung.',

      'referralTitle': 'Referral',
      'referralDescription':
          'Referral-Boni werden so gestaltet, dass sie mit dem Wachstum der Community ausgewogen bleiben.',

      'mainnetNoticeTitle':
          'Mainnet = Zukünftige Veröffentlichung • Noch nicht aktiv',
      'mainnetNoticeDescription':
          'Vor dem Start werden Solana-Integration, Wallets, STL-Transfers, Auszahlungen und Sicherheitslösungen getestet.',

      'ecosystemTitle': 'Börsen & Ökosystem',
      'ecosystemDex':
          'DEX- und CEX-Möglichkeiten untersuchen',
      'ecosystemLiquidity':
          'Liquiditätslösungen vorbereiten',
      'ecosystemExpansion':
          'STL-Ökosystem erweitern',
      'ecosystemPartnerships':
          'Partnerschaften entwickeln',
      'ecosystemStella':
          'Neue Stella-Erlebnisse vorstellen',
      'ecosystemUseCases':
          'Zukünftige STL-Anwendungsfälle untersuchen',

      'withdrawalTitle':
          'Mögliche zukünftige Auszahlungen',
      'withdrawalDescription':
          'Ein mögliches zukünftiges Auszahlungssystem wird separat entwickelt und seine Bedingungen werden vor der Einführung bekannt gegeben.',
      'minimumWithdrawal':
          'Geplante Mindestauszahlung',
      'userPaysFee':
          'Der Benutzer bezahlt die Solana-Netzwerkgebühr.',

      'stellaJourneyTitle':
          'Stellas Reise 🐾',
      'stellaJourneyDescription':
          'Das Stelluriini-Ökosystem wird Schritt für Schritt rund um Community, App und STL-Token entwickelt.',

      'developmentPrinciplesTitle':
          'Entwicklungsprinzipien',

      'communityTitle': 'Community',
      'communityDescription':
          'Die Community steht im Mittelpunkt der Stelluriini-Entwicklung. Feedback und Benutzerideen helfen bei der zukünftigen Entwicklung.',

      'securityTitle': 'Sicherheit',
      'securityDescription':
          'Sicherheit, Server-Infrastruktur und Zuverlässigkeit der Anwendung werden kontinuierlich verbessert.',

      'antiBotTitle': 'Bot-Schutz',
      'antiBotDescription':
          'Das System berücksichtigt Bots, Automatisierung und die Erkennung von Missbrauch.',

      'innovationTitle': 'Innovation',
      'innovationDescription':
          'Neue Anwendungsfälle, Funktionen und Technologien werden während der Projektentwicklung untersucht.',

      'longTermGrowthTitle':
          'Langfristiges Wachstum',
      'longTermGrowthDescription':
          'Ziel ist der Aufbau eines nachhaltigen und sich schrittweise entwickelnden Stelluriini-Ökosystems.',

      'importantNoticeTitle':
          'Wichtiger Hinweis',
      'importantNoticeDescription':
          'Die Roadmap beschreibt die geplante Entwicklungsrichtung von Stelluriini. Phasen, Funktionen und Zeitpläne können sich während der Entwicklung ändern.',

      'footer':
          'STELLA • STELLURIINI • STL • SOLANA',
    },

    // ========================================================
    // 🇪🇸 SPANISH
    // ========================================================

    'es': {
      'roadmapTitle': 'Hoja de ruta de Stelluriini',
      'journeyTitle': 'El viaje de Stelluriini',
      'journeyDescription':
          'El desarrollo de Stelluriini avanza paso a paso hacia una comunidad más amplia, un ecosistema mayor y nuevos casos de uso.',

      'phase1': 'Fase 1 – Fundación',
      'phase1Title': 'Construyendo Stelluriini',
      'phase1Description':
          'Construcción del proyecto Stelluriini, el token STL y el ecosistema Stella.',
      'phase1Status': 'En progreso',

      'phase2': 'Fase 2 – Aplicación',
      'phase2Title': 'Desarrollo de la aplicación Stelluriini',
      'phase2Description':
          'Minería, Stella Power Boost, progreso del usuario e historial de transacciones.',
      'phase2Status': 'En progreso',

      'phase3': 'Fase 3 – Comunidad',
      'phase3Title': 'Crecimiento de la comunidad',
      'phase3Description':
          'Construcción de la comunidad, recopilación de comentarios y desarrollo de la marca Stelluriini.',
      'phase3Status': 'Planificado',

      'phase4': 'Fase 4 – Ecosistema',
      'phase4Title': 'Expansión del ecosistema STL',
      'phase4Description':
          'Desarrollo de casos de uso del token STL y expansión del ecosistema Stelluriini.',
      'phase4Status': 'Planificado',

      'phase5': 'Fase 5 – Testnet',
      'phase5Title': 'Solana Testnet',
      'phase5Description':
          'Pruebas de transferencias STL, conexiones de wallets, transacciones y retiros antes de Mainnet.',
      'phase5Status': 'En pruebas',

      'phase6': 'Fase 6 – Desarrollo a largo plazo',
      'phase6Title': 'La siguiente etapa de Stelluriini',
      'phase6Description':
          'Desarrollo continuo del ecosistema Stelluriini, nuevas funciones y respuestas a las necesidades de la comunidad.',
      'phase6Status': 'Futuro',

      'phase7': 'Fase 7 – Mainnet',
      'phase7Title': 'Solana Mainnet y retiros STL',
      'phase7Description':
          'Apertura de la fase Solana Mainnet de Stelluriini e introducción de retiros STL después de las pruebas y verificaciones de seguridad.',
      'phase7Status': 'Futuro',

      'phase8': 'Fase 8 – Ecosistema',
      'phase8Title': 'Exchanges y ecosistema',
      'phase8Description':
          'Exploración de oportunidades DEX y CEX, soluciones de liquidez, asociaciones y futuros casos de uso de STL.',
      'phase8Status': 'Futuro',

      'miningBalanceTitle': 'Equilibrio de la economía de minería',
      'miningBalanceDescription':
          'El sistema de minería no está diseñado para aumentar la producción diaria de STL sin límites. Hash Rate, Power Boost y bonos de referidos se diseñan juntos para mantener el sistema controlable.',

      'hashRateTitle': 'Hash Rate',
      'hashRateDescription':
          'La minería básica establece el nivel normal de Hash Rate del usuario.',

      'powerBoostTitle': 'Power Boost',
      'powerBoostDescription':
          'Power Boost proporciona un aumento temporal de la potencia de minería del usuario.',

      'referralTitle': 'Referidos',
      'referralDescription':
          'Los bonos de referidos se diseñarán para mantener el equilibrio a medida que crezca la comunidad.',

      'mainnetNoticeTitle':
          'Mainnet = Lanzamiento futuro • Aún no activo',
      'mainnetNoticeDescription':
          'Antes del lanzamiento se probarán la integración con Solana, wallets, transferencias STL, retiros y soluciones de seguridad.',

      'ecosystemTitle': 'Exchange y ecosistema',
      'ecosystemDex':
          'Explorar oportunidades DEX y CEX',
      'ecosystemLiquidity':
          'Preparar soluciones de liquidez',
      'ecosystemExpansion':
          'Expandir el ecosistema STL',
      'ecosystemPartnerships':
          'Desarrollar asociaciones',
      'ecosystemStella':
          'Presentar nuevas experiencias de Stella',
      'ecosystemUseCases':
          'Explorar futuros casos de uso de STL',

      'withdrawalTitle':
          'Posibles retiros futuros',
      'withdrawalDescription':
          'Un posible sistema de retiros futuro se diseñará por separado y sus condiciones se anunciarán antes de su implementación.',
      'minimumWithdrawal':
          'Retiro mínimo previsto',
      'userPaysFee':
          'El usuario paga la comisión de la red Solana.',

      'stellaJourneyTitle':
          'El viaje de Stella 🐾',
      'stellaJourneyDescription':
          'El ecosistema Stelluriini se desarrollará paso a paso alrededor de la comunidad, la aplicación y el token STL.',

      'developmentPrinciplesTitle':
          'Principios de desarrollo',

      'communityTitle': 'Comunidad',
      'communityDescription':
          'La comunidad está en el centro del desarrollo de Stelluriini. Los comentarios e ideas de los usuarios ayudan a orientar el desarrollo futuro.',

      'securityTitle': 'Seguridad',
      'securityDescription':
          'La seguridad, la infraestructura del servidor y la fiabilidad de la aplicación se mejorarán continuamente.',

      'antiBotTitle': 'Protección contra bots',
      'antiBotDescription':
          'El sistema tendrá en cuenta los bots, la automatización y la detección de abusos.',

      'innovationTitle': 'Innovación',
      'innovationDescription':
          'Se explorarán nuevos casos de uso, funciones y tecnologías a medida que avance el proyecto.',

      'longTermGrowthTitle':
          'Crecimiento a largo plazo',
      'longTermGrowthDescription':
          'El objetivo es construir un ecosistema Stelluriini sostenible y en evolución gradual.',

      'importantNoticeTitle':
          'Aviso importante',
      'importantNoticeDescription':
          'La hoja de ruta describe la dirección de desarrollo prevista de Stelluriini. Las fases, funciones y plazos pueden cambiar durante el desarrollo.',

      'footer':
          'STELLA • STELLURIINI • STL • SOLANA',
    },

    // ========================================================
    // 🇫🇷 FRENCH
    // ========================================================

    'fr': {
      'roadmapTitle': 'Feuille de route Stelluriini',
      'journeyTitle': 'Le parcours de Stelluriini',
      'journeyDescription':
          'Le développement de Stelluriini progresse étape par étape vers une communauté plus large, un écosystème étendu et de nouveaux cas d’utilisation.',

      'phase1': 'Phase 1 – Fondation',
      'phase1Title': 'Construire Stelluriini',
      'phase1Description':
          'Construction du projet Stelluriini, du token STL et de l’écosystème Stella.',
      'phase1Status': 'En cours',

      'phase2': 'Phase 2 – Application',
      'phase2Title': 'Développement de l’application Stelluriini',
      'phase2Description':
          'Minage, Stella Power Boost, progression utilisateur et historique des transactions.',
      'phase2Status': 'En cours',

      'phase3': 'Phase 3 – Communauté',
      'phase3Title': 'Développer la communauté',
      'phase3Description':
          'Développer la communauté, recueillir les retours et développer la marque Stelluriini.',
      'phase3Status': 'Prévu',

      'phase4': 'Phase 4 – Écosystème',
      'phase4Title': 'Étendre l’écosystème STL',
      'phase4Description':
          'Développer les cas d’utilisation du token STL et étendre l’écosystème Stelluriini.',
      'phase4Status': 'Prévu',

      'phase5': 'Phase 5 – Testnet',
      'phase5Title': 'Solana Testnet',
      'phase5Description':
          'Tester les transferts STL, les connexions de wallets, les transactions et les retraits avant le Mainnet.',
      'phase5Status': 'Tests',

      'phase6': 'Phase 6 – Développement à long terme',
      'phase6Title': 'La prochaine étape de Stelluriini',
      'phase6Description':
          'Développement continu de l’écosystème Stelluriini, nouvelles fonctionnalités et réponses aux besoins de la communauté.',
      'phase6Status': 'Futur',

      'phase7': 'Phase 7 – Mainnet',
      'phase7Title': 'Solana Mainnet et retraits STL',
      'phase7Description':
          'Ouverture de la phase Solana Mainnet de Stelluriini et introduction des retraits STL après les tests et contrôles de sécurité.',
      'phase7Status': 'Futur',

      'phase8': 'Phase 8 – Écosystème',
      'phase8Title': 'Exchange et écosystème',
      'phase8Description':
          'Étude des possibilités DEX et CEX, solutions de liquidité, partenariats et futurs cas d’utilisation de STL.',
      'phase8Status': 'Futur',

      'miningBalanceTitle':
          'Équilibre de l’économie du minage',
      'miningBalanceDescription':
          'Le système de minage n’est pas conçu pour augmenter la production quotidienne de STL sans limite. Hash Rate, Power Boost et bonus de parrainage sont conçus ensemble afin de maintenir un système contrôlable.',

      'hashRateTitle': 'Hash Rate',
      'hashRateDescription':
          'Le minage de base définit le niveau normal de Hash Rate de l’utilisateur.',

      'powerBoostTitle': 'Power Boost',
      'powerBoostDescription':
          'Power Boost fournit une augmentation temporaire de la puissance de minage.',

      'referralTitle': 'Parrainage',
      'referralDescription':
          'Les bonus de parrainage seront conçus pour rester équilibrés avec la croissance de la communauté.',

      'mainnetNoticeTitle':
          'Mainnet = Publication future • Pas encore actif',
      'mainnetNoticeDescription':
          'Avant le lancement, l’intégration Solana, les wallets, les transferts STL, les retraits et les solutions de sécurité seront testés.',

      'ecosystemTitle':
          'Exchange et écosystème',
      'ecosystemDex':
          'Explorer les possibilités DEX et CEX',
      'ecosystemLiquidity':
          'Préparer les solutions de liquidité',
      'ecosystemExpansion':
          'Étendre l’écosystème STL',
      'ecosystemPartnerships':
          'Développer des partenariats',
      'ecosystemStella':
          'Présenter de nouvelles expériences Stella',
      'ecosystemUseCases':
          'Explorer les futurs cas d’utilisation de STL',

      'withdrawalTitle':
          'Retraits futurs possibles',
      'withdrawalDescription':
          'Un éventuel système de retrait futur sera conçu séparément et ses conditions seront annoncées avant sa mise en œuvre.',
      'minimumWithdrawal':
          'Retrait minimum prévu',
      'userPaysFee':
          'L’utilisateur paie les frais du réseau Solana.',

      'stellaJourneyTitle':
          'Le voyage de Stella 🐾',
      'stellaJourneyDescription':
          'L’écosystème Stelluriini sera développé progressivement autour de la communauté, de l’application et du token STL.',

      'developmentPrinciplesTitle':
          'Principes de développement',

      'communityTitle': 'Communauté',
      'communityDescription':
          'La communauté est au cœur du développement de Stelluriini. Les retours et les idées des utilisateurs contribuent à orienter le développement futur.',

      'securityTitle': 'Sécurité',
      'securityDescription':
          'La sécurité, l’infrastructure serveur et la fiabilité de l’application seront améliorées en continu.',

      'antiBotTitle': 'Protection contre les bots',
      'antiBotDescription':
          'Le système prendra en compte les bots, l’automatisation et la détection des abus.',

      'innovationTitle': 'Innovation',
      'innovationDescription':
          'De nouveaux cas d’utilisation, fonctionnalités et technologies seront explorés au fur et à mesure du développement du projet.',

      'longTermGrowthTitle':
          'Croissance à long terme',
      'longTermGrowthDescription':
          'L’objectif est de construire un écosystème Stelluriini durable et évoluant progressivement.',

      'importantNoticeTitle':
          'Avis important',
      'importantNoticeDescription':
          'La feuille de route décrit la direction de développement prévue de Stelluriini. Les phases, fonctionnalités et calendriers peuvent changer pendant le développement.',

      'footer':
          'STELLA • STELLURIINI • STL • SOLANA',
    },

    // ========================================================
    // 🇨🇳 CHINESE
    // ========================================================

    'zh': {
      'roadmapTitle': 'Stelluriini 路线图',
      'journeyTitle': 'Stelluriini 的发展之旅',
      'journeyDescription':
          'Stelluriini 将逐步发展，迈向更大的社区、更完整的生态系统以及新的应用场景。',

      'phase1': '阶段 1 – 基础建设',
      'phase1Title': '建设 Stelluriini',
      'phase1Description':
          '建设 Stelluriini 项目、STL 代币以及 Stella 生态系统。',
      'phase1Status': '进行中',

      'phase2': '阶段 2 – 应用',
      'phase2Title': 'Stelluriini 应用开发',
      'phase2Description':
          '挖矿、Stella Power Boost、用户进度以及交易记录。',
      'phase2Status': '进行中',

      'phase3': '阶段 3 – 社区',
      'phase3Title': '发展社区',
      'phase3Description':
          '建设社区、收集反馈并发展 Stelluriini 品牌。',
      'phase3Status': '计划中',

      'phase4': '阶段 4 – 生态系统',
      'phase4Title': '扩展 STL 生态系统',
      'phase4Description':
          '开发 STL 代币的应用场景并扩展 Stelluriini 生态系统。',
      'phase4Status': '计划中',

      'phase5': '阶段 5 – 测试网',
      'phase5Title': 'Solana 测试网',
      'phase5Description':
          '在主网上线前测试 STL 转账、钱包连接、交易以及提现功能。',
      'phase5Status': '测试中',

      'phase6': '阶段 6 – 长期发展',
      'phase6Title': 'Stelluriini 的下一阶段',
      'phase6Description':
          '持续开发 Stelluriini 生态系统、新功能并响应社区需求。',
      'phase6Status': '未来',

      'phase7': '阶段 7 – 主网',
      'phase7Title': 'Solana 主网与 STL 提现',
      'phase7Description':
          '在完成测试和安全检查后开启 Stelluriini Solana 主网阶段并推出 STL 提现。',
      'phase7Status': '未来',

      'phase8': '阶段 8 – 生态系统',
      'phase8Title': '交易所与生态系统',
      'phase8Description':
          '探索 DEX 和 CEX、流动性方案、合作伙伴以及未来 STL 应用场景。',
      'phase8Status': '未来',

      'miningBalanceTitle': '挖矿经济平衡',
      'miningBalanceDescription':
          '挖矿系统并非为了无限增加每日 STL 产量。Hash Rate、Power Boost 和推荐奖励将共同设计，以保持系统的可控性。',

      'hashRateTitle': 'Hash Rate',
      'hashRateDescription':
          '基础挖矿决定用户正常的 Hash Rate 水平。',

      'powerBoostTitle': 'Power Boost',
      'powerBoostDescription':
          'Power Boost 可在限定时间内提高用户的挖矿能力。',

      'referralTitle': '推荐奖励',
      'referralDescription':
          '推荐奖励将随着社区增长进行平衡设计。',

      'mainnetNoticeTitle':
          'Mainnet = 未来发布 • 尚未启用',
      'mainnetNoticeDescription':
          '正式上线前将测试 Solana 集成、钱包、STL 转账、提现以及安全方案。',

      'ecosystemTitle': '交易所与生态系统',
      'ecosystemDex':
          '探索 DEX 和 CEX 机会',
      'ecosystemLiquidity':
          '准备流动性解决方案',
      'ecosystemExpansion':
          '扩展 STL 生态系统',
      'ecosystemPartnerships':
          '发展合作伙伴关系',
      'ecosystemStella':
          '推出新的 Stella 体验',
      'ecosystemUseCases':
          '探索 STL 的未来应用场景',

      'withdrawalTitle': '未来可能的提现',
      'withdrawalDescription':
          '未来可能的提现系统将单独设计，并在实施前公布相关规则。',
      'minimumWithdrawal': '计划最低提现额度',
      'userPaysFee':
          '用户承担 Solana 网络交易费用。',

      'stellaJourneyTitle': 'Stella 的旅程 🐾',
      'stellaJourneyDescription':
          'Stelluriini 生态系统将围绕社区、应用和 STL 代币逐步发展。',

      'developmentPrinciplesTitle': '开发原则',

      'communityTitle': '社区',
      'communityDescription':
          '社区是 Stelluriini 开发的核心。用户反馈和想法将帮助指导未来的发展。',

      'securityTitle': '安全',
      'securityDescription':
          '我们将持续改进安全性、服务器基础设施和应用可靠性。',

      'antiBotTitle': '防机器人',
      'antiBotDescription':
          '系统将考虑机器人、自动化以及滥用行为的检测。',

      'innovationTitle': '创新',
      'innovationDescription':
          '随着项目发展，我们将探索新的应用场景、功能和技术。',

      'longTermGrowthTitle': '长期发展',
      'longTermGrowthDescription':
          '目标是建立一个可持续并逐步发展的 Stelluriini 生态系统。',

      'importantNoticeTitle': '重要提示',
      'importantNoticeDescription':
          '路线图描述了 Stelluriini 计划中的发展方向。阶段、功能和时间表可能会在项目开发过程中发生变化。',

      'footer':
          'STELLA • STELLURIINI • STL • SOLANA',
    },

    // ========================================================
    // 🇻🇳 VIETNAMESE
    // ========================================================

    'vi': {
      'roadmapTitle': 'Lộ trình Stelluriini',
      'journeyTitle': 'Hành trình Stelluriini',
      'journeyDescription':
          'Stelluriini sẽ phát triển từng bước hướng tới cộng đồng lớn hơn, hệ sinh thái mở rộng và các trường hợp sử dụng mới.',

      'phase1': 'Giai đoạn 1 – Nền tảng',
      'phase1Title': 'Xây dựng Stelluriini',
      'phase1Description':
          'Xây dựng dự án Stelluriini, token STL và hệ sinh thái Stella.',
      'phase1Status': 'Đang thực hiện',

      'phase2': 'Giai đoạn 2 – Ứng dụng',
      'phase2Title': 'Phát triển ứng dụng Stelluriini',
      'phase2Description':
          'Khai thác, Stella Power Boost, tiến trình người dùng và lịch sử giao dịch.',
      'phase2Status': 'Đang thực hiện',

      'phase3': 'Giai đoạn 3 – Cộng đồng',
      'phase3Title': 'Phát triển cộng đồng',
      'phase3Description':
          'Xây dựng cộng đồng, thu thập phản hồi và phát triển thương hiệu Stelluriini.',
      'phase3Status': 'Đã lên kế hoạch',

      'phase4': 'Giai đoạn 4 – Hệ sinh thái',
      'phase4Title': 'Mở rộng hệ sinh thái STL',
      'phase4Description':
          'Phát triển các trường hợp sử dụng token STL và mở rộng hệ sinh thái Stelluriini.',
      'phase4Status': 'Đã lên kế hoạch',

      'phase5': 'Giai đoạn 5 – Testnet',
      'phase5Title': 'Solana Testnet',
      'phase5Description':
          'Kiểm thử chuyển STL, kết nối ví, giao dịch và chức năng rút trước Mainnet.',
      'phase5Status': 'Đang kiểm thử',

      'phase6': 'Giai đoạn 6 – Phát triển dài hạn',
      'phase6Title': 'Giai đoạn tiếp theo của Stelluriini',
      'phase6Description':
          'Tiếp tục phát triển hệ sinh thái Stelluriini, các tính năng mới và đáp ứng nhu cầu cộng đồng.',
      'phase6Status': 'Tương lai',

      'phase7': 'Giai đoạn 7 – Mainnet',
      'phase7Title': 'Solana Mainnet & Rút STL',
      'phase7Description':
          'Mở giai đoạn Solana Mainnet và giới thiệu rút STL sau khi hoàn tất kiểm thử và kiểm tra bảo mật.',
      'phase7Status': 'Tương lai',

      'phase8': 'Giai đoạn 8 – Hệ sinh thái',
      'phase8Title': 'Sàn giao dịch & Hệ sinh thái',
      'phase8Description':
          'Khám phá DEX, CEX, giải pháp thanh khoản, đối tác và các trường hợp sử dụng STL trong tương lai.',
      'phase8Status': 'Tương lai',

      'miningBalanceTitle':
          'Cân bằng kinh tế khai thác',
      'miningBalanceDescription':
          'Hệ thống khai thác không được thiết kế để tăng sản lượng STL hàng ngày không giới hạn. Hash Rate, Power Boost và phần thưởng giới thiệu sẽ được thiết kế cùng nhau để duy trì hệ thống có thể kiểm soát.',

      'hashRateTitle': 'Hash Rate',
      'hashRateDescription':
          'Khai thác cơ bản tạo ra mức Hash Rate thông thường của người dùng.',

      'powerBoostTitle': 'Power Boost',
      'powerBoostDescription':
          'Power Boost cung cấp mức tăng tạm thời cho sức mạnh khai thác của người dùng.',

      'referralTitle': 'Giới thiệu',
      'referralDescription':
          'Phần thưởng giới thiệu sẽ được thiết kế cân bằng khi cộng đồng phát triển.',

      'mainnetNoticeTitle':
          'Mainnet = Phát hành trong tương lai • Chưa hoạt động',
      'mainnetNoticeDescription':
          'Trước khi ra mắt, tích hợp Solana, ví, chuyển STL, rút tiền và các giải pháp bảo mật sẽ được kiểm thử.',

      'ecosystemTitle':
          'Sàn giao dịch & Hệ sinh thái',
      'ecosystemDex':
          'Khám phá cơ hội DEX và CEX',
      'ecosystemLiquidity':
          'Chuẩn bị giải pháp thanh khoản',
      'ecosystemExpansion':
          'Mở rộng hệ sinh thái STL',
      'ecosystemPartnerships':
          'Phát triển quan hệ đối tác',
      'ecosystemStella':
          'Giới thiệu trải nghiệm Stella mới',
      'ecosystemUseCases':
          'Khám phá các trường hợp sử dụng STL trong tương lai',

      'withdrawalTitle':
          'Khả năng rút tiền trong tương lai',
      'withdrawalDescription':
          'Một hệ thống rút tiền trong tương lai có thể sẽ được thiết kế riêng và các điều khoản sẽ được công bố trước khi triển khai.',
      'minimumWithdrawal':
          'Mức rút tối thiểu dự kiến',
      'userPaysFee':
          'Người dùng thanh toán phí mạng Solana.',

      'stellaJourneyTitle':
          'Hành trình của Stella 🐾',
      'stellaJourneyDescription':
          'Hệ sinh thái Stelluriini sẽ được phát triển từng bước xoay quanh cộng đồng, ứng dụng và token STL.',

      'developmentPrinciplesTitle':
          'Nguyên tắc phát triển',

      'communityTitle': 'Cộng đồng',
      'communityDescription':
          'Cộng đồng là trung tâm của quá trình phát triển Stelluriini. Phản hồi và ý tưởng của người dùng giúp định hướng phát triển trong tương lai.',

      'securityTitle': 'Bảo mật',
      'securityDescription':
          'Bảo mật, cơ sở hạ tầng máy chủ và độ tin cậy của ứng dụng sẽ được liên tục cải thiện.',

      'antiBotTitle': 'Chống bot',
      'antiBotDescription':
          'Hệ thống sẽ tính đến bot, tự động hóa và phát hiện hành vi lạm dụng.',

      'innovationTitle': 'Đổi mới',
      'innovationDescription':
          'Các trường hợp sử dụng, tính năng và công nghệ mới sẽ được khám phá khi dự án phát triển.',

      'longTermGrowthTitle':
          'Tăng trưởng dài hạn',
      'longTermGrowthDescription':
          'Mục tiêu là xây dựng một hệ sinh thái Stelluriini bền vững và phát triển từng bước.',

      'importantNoticeTitle':
          'Thông báo quan trọng',
      'importantNoticeDescription':
          'Lộ trình mô tả hướng phát triển dự kiến của Stelluriini. Các giai đoạn, tính năng và thời gian có thể thay đổi trong quá trình phát triển.',

      'footer':
          'STELLA • STELLURIINI • STL • SOLANA',
    },

    // ========================================================
    // 🇯🇵 JAPANESE
    // ========================================================

    'ja': {
      'roadmapTitle': 'Stelluriini ロードマップ',
      'journeyTitle': 'Stelluriini の旅',
      'journeyDescription':
          'Stelluriini は、より大きなコミュニティ、エコシステム、新しいユースケースに向けて段階的に発展していきます。',

      'phase1': 'フェーズ 1 – 基盤',
      'phase1Title': 'Stelluriini の構築',
      'phase1Description':
          'Stelluriini プロジェクト、STL トークン、Stella エコシステムを構築します。',
      'phase1Status': '進行中',

      'phase2': 'フェーズ 2 – アプリ',
      'phase2Title': 'Stelluriini アプリ開発',
      'phase2Description':
          'マイニング、Stella Power Boost、ユーザー進行状況、取引履歴を開発します。',
      'phase2Status': '進行中',

      'phase3': 'フェーズ 3 – コミュニティ',
      'phase3Title': 'コミュニティの成長',
      'phase3Description':
          'コミュニティを構築し、フィードバックを集め、Stelluriini ブランドを発展させます。',
      'phase3Status': '予定',

      'phase4': 'フェーズ 4 – エコシステム',
      'phase4Title': 'STL エコシステムの拡大',
      'phase4Description':
          'STL トークンのユースケースを開発し、Stelluriini エコシステムを拡大します。',
      'phase4Status': '予定',

      'phase5': 'フェーズ 5 – テストネット',
      'phase5Title': 'Solana Testnet',
      'phase5Description':
          'Mainnet の前に STL 転送、ウォレット接続、取引、出金機能をテストします。',
      'phase5Status': 'テスト中',

      'phase6': 'フェーズ 6 – 長期開発',
      'phase6Title': 'Stelluriini の次の段階',
      'phase6Description':
          'Stelluriini エコシステム、新機能、コミュニティのニーズへの対応を継続的に開発します。',
      'phase6Status': '将来',

      'phase7': 'フェーズ 7 – Mainnet',
      'phase7Title': 'Solana Mainnet & STL 出金',
      'phase7Description':
          'テストとセキュリティ確認の後、Stelluriini の Solana Mainnet フェーズと STL 出金を開始します。',
      'phase7Status': '将来',

      'phase8': 'フェーズ 8 – エコシステム',
      'phase8Title': '取引所 & エコシステム',
      'phase8Description':
          'DEX、CEX、流動性ソリューション、パートナーシップ、将来の STL ユースケースを検討します。',
      'phase8Status': '将来',

      'miningBalanceTitle':
          'マイニング経済のバランス',
      'miningBalanceDescription':
          'マイニングシステムは、1日の STL 生成量を無制限に増やすことを目的としていません。Hash Rate、Power Boost、Referral ボーナスを組み合わせ、システム全体を管理可能な状態にします。',

      'hashRateTitle': 'Hash Rate',
      'hashRateDescription':
          '基本マイニングによってユーザーの通常の Hash Rate が決まります。',

      'powerBoostTitle': 'Power Boost',
      'powerBoostDescription':
          'Power Boost は一定時間、ユーザーのマイニング能力を向上させます。',

      'referralTitle': 'Referral',
      'referralDescription':
          'コミュニティの成長に合わせてバランスを保てるよう Referral ボーナスを設計します。',

      'mainnetNoticeTitle':
          'Mainnet = 将来の公開 • 現在は未稼働',
      'mainnetNoticeDescription':
          '公開前に Solana 統合、ウォレット、STL 転送、出金、セキュリティ対策をテストします。',

      'ecosystemTitle':
          '取引所 & エコシステム',
      'ecosystemDex':
          'DEX と CEX の可能性を調査',
      'ecosystemLiquidity':
          '流動性ソリューションを準備',
      'ecosystemExpansion':
          'STL エコシステムを拡大',
      'ecosystemPartnerships':
          'パートナーシップを開発',
      'ecosystemStella':
          '新しい Stella 体験を提供',
      'ecosystemUseCases':
          '将来の STL ユースケースを調査',

      'withdrawalTitle':
          '将来の出金の可能性',
      'withdrawalDescription':
          '将来の出金システムは別途設計され、実装前に条件が発表されます。',
      'minimumWithdrawal':
          '予定されている最低出金額',
      'userPaysFee':
          'Solana ネットワーク手数料はユーザーが負担します。',

      'stellaJourneyTitle':
          'Stella の旅 🐾',
      'stellaJourneyDescription':
          'Stelluriini エコシステムは、コミュニティ、アプリ、STL トークンを中心に段階的に開発されます。',

      'developmentPrinciplesTitle':
          '開発原則',

      'communityTitle': 'コミュニティ',
      'communityDescription':
          'コミュニティは Stelluriini 開発の中心です。ユーザーからのフィードバックやアイデアが今後の開発を導きます。',

      'securityTitle': 'セキュリティ',
      'securityDescription':
          'セキュリティ、サーバーインフラ、アプリの信頼性を継続的に改善します。',

      'antiBotTitle': 'ボット対策',
      'antiBotDescription':
          'ボット、自動化、不正利用の検出をシステムで考慮します。',

      'innovationTitle': 'イノベーション',
      'innovationDescription':
          'プロジェクトの発展に合わせて、新しいユースケース、機能、技術を検討します。',

      'longTermGrowthTitle':
          '長期的な成長',
      'longTermGrowthDescription':
          '持続可能で段階的に発展する Stelluriini エコシステムの構築を目指します。',

      'importantNoticeTitle':
          '重要なお知らせ',
      'importantNoticeDescription':
          'このロードマップは Stelluriini の予定されている開発方針を示しています。開発中にフェーズ、機能、スケジュールが変更される場合があります。',

      'footer':
          'STELLA • STELLURIINI • STL • SOLANA',
    },
  };
}