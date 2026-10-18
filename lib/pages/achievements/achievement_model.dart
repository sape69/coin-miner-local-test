// ============================================================
// 🏆 STELLURIINI ACHIEVEMENT MODEL
// ============================================================

class Achievement {
  final String id;
  final String icon;
  final String title;
  final String description;
  final int target;
  final int reward;

  const Achievement({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.target,
    required this.reward,
  });
}

// ============================================================
// 🏆 STELLURIINI ACHIEVEMENTS
// ============================================================

class StelluriiniAchievements {
  const StelluriiniAchievements._();

  // ==========================================================
  // ⛏️ MINING CYCLES
  //
  // Kaikki louhintajaksoihin liittyvät saavutukset peräkkäin.
  // ==========================================================

  static const Achievement firstPaw = Achievement(
    id: 'first_paw',
    icon: '🐾',
    title: 'First Paw',
    description: 'Start mining for the first time.',
    target: 1,
    reward: 2,
  );

  static const Achievement dedicatedMiner = Achievement(
    id: 'dedicated_miner',
    icon: '⛏️',
    title: 'Dedicated Miner',
    description: 'Complete 25 mining cycles.',
    target: 25,
    reward: 30,
  );

  static const Achievement seasonedMiner = Achievement(
    id: 'seasoned_miner',
    icon: '⛏️',
    title: 'Seasoned Miner',
    description: 'Complete 50 mining cycles.',
    target: 50,
    reward: 40,
  );

  static const Achievement veteranMiner = Achievement(
    id: 'veteran_miner',
    icon: '🛠️',
    title: 'Veteran Miner',
    description: 'Complete 100 mining cycles.',
    target: 100,
    reward: 75,
  );

  // ==========================================================
  // 🔥 MINING STREAKS
  //
  // Kaikki louhintaputket peräkkäin.
  // ==========================================================

  static const Achievement hotStreak = Achievement(
    id: 'hot_streak',
    icon: '🔥',
    title: 'Hot Streak',
    description: 'Reach a 7 day mining streak.',
    target: 7,
    reward: 20,
  );

  static const Achievement stellaOnFire = Achievement(
    id: 'stella_on_fire',
    icon: '🔥',
    title: 'Stella on Fire',
    description: 'Reach a 14 day mining streak.',
    target: 14,
    reward: 25,
  );

  static const Achievement stellaLegend = Achievement(
    id: 'stella_legend',
    icon: '👑',
    title: 'Stella Legend',
    description: 'Reach a 30 day mining streak.',
    target: 30,
    reward: 50,
  );

  static const Achievement stellaEternal = Achievement(
    id: 'stella_eternal',
    icon: '🔥',
    title: 'Stella Eternal',
    description: 'Reach a 60 day mining streak.',
    target: 60,
    reward: 100,
  );

  static const Achievement stellaBeyond = Achievement(
    id: 'stella_beyond',
    icon: '🌌',
    title: 'Stella Beyond',
    description: 'Reach a 90 day mining streak.',
    target: 90,
    reward: 200,
  );

  // ==========================================================
  // 💎 STL AMOUNTS
  //
  // Kaikki louhitun STL-määrän saavutukset peräkkäin.
  // ==========================================================

  static const Achievement littleMiner = Achievement(
    id: 'little_miner',
    icon: '⛏️',
    title: 'Little Miner',
    description: 'Mine your first 10 STL.',
    target: 10,
    reward: 5,
  );

  static const Achievement growingMiner = Achievement(
    id: 'growing_miner',
    icon: '🌱',
    title: 'Growing Miner',
    description: 'Mine 25 STL.',
    target: 25,
    reward: 8,
  );

  static const Achievement stlHunter = Achievement(
    id: 'stl_hunter',
    icon: '💎',
    title: 'STL Hunter',
    description: 'Mine 100 STL.',
    target: 100,
    reward: 10,
  );

  static const Achievement stlCollector = Achievement(
    id: 'stl_collector',
    icon: '💰',
    title: 'STL Collector',
    description: 'Mine 500 STL.',
    target: 500,
    reward: 25,
  );

  static const Achievement stlMaster = Achievement(
    id: 'stl_master',
    icon: '💎',
    title: 'STL Master',
    description: 'Mine 1,000 STL.',
    target: 1000,
    reward: 50,
  );

  static const Achievement stlHoarder = Achievement(
    id: 'stl_hoarder',
    icon: '💎',
    title: 'STL Hoarder',
    description: 'Mine 2,500 STL.',
    target: 2500,
    reward: 40,
  );

  static const Achievement stlTycoon = Achievement(
    id: 'stl_tycoon',
    icon: '🏦',
    title: 'STL Tycoon',
    description: 'Mine 5,000 STL.',
    target: 5000,
    reward: 75,
  );

  // ==========================================================
  // ⚡ POWER BOOST
  //
  // Kaikki Power Boost -saavutukset peräkkäin.
  // ==========================================================

  static const Achievement powerPaws = Achievement(
    id: 'power_paws',
    icon: '⚡',
    title: 'Power Paws',
    description: 'Use Power Boost 5 times.',
    target: 5,
    reward: 10,
  );

  static const Achievement superPaws = Achievement(
    id: 'super_paws',
    icon: '⚡⚡',
    title: 'Super Paws',
    description: 'Use Power Boost 25 times.',
    target: 25,
    reward: 20,
  );

  static const Achievement powerHunter = Achievement(
    id: 'power_hunter',
    icon: '⚡',
    title: 'Power Hunter',
    description: 'Use Power Boost 50 times.',
    target: 50,
    reward: 30,
  );

  static const Achievement powerMaster = Achievement(
    id: 'power_master',
    icon: '⚡⚡',
    title: 'Power Master',
    description: 'Use Power Boost 100 times.',
    target: 100,
    reward: 50,
  );

  // ==========================================================
  // 🐱 DAILY CHECK-INS
  //
  // Kaikki päivittäisiin kirjautumisiin liittyvät saavutukset.
  // ==========================================================

  static const Achievement stellasFriend = Achievement(
    id: 'stellas_friend',
    icon: '🐱',
    title: "Stella's Friend",
    description: 'Complete 10 daily check-ins.',
    target: 10,
    reward: 15,
  );

  static const Achievement stellaCompanion = Achievement(
    id: 'stella_companion',
    icon: '🐾',
    title: 'Stella Companion',
    description: 'Complete 30 daily check-ins.',
    target: 30,
    reward: 30,
  );

  static const Achievement stellaDevotee = Achievement(
    id: 'stella_devotee',
    icon: '🌟',
    title: 'Stella Devotee',
    description: 'Complete 60 daily check-ins.',
    target: 60,
    reward: 60,
  );

  // ==========================================================
  // 🐾 REFERRALS
  //
  // Kaikki käyttäjien kutsumiseen liittyvät saavutukset.
  // ==========================================================

  static const Achievement firstInvitation = Achievement(
    id: 'first_invitation',
    icon: '🐾',
    title: 'First Invitation',
    description: 'Invite your first user.',
    target: 1,
    reward: 5,
  );

  static const Achievement friendCircle = Achievement(
    id: 'friend_circle',
    icon: '👥',
    title: 'Friend Circle',
    description: 'Invite 5 users.',
    target: 5,
    reward: 10,
  );

  static const Achievement stellasCommunity = Achievement(
    id: 'stellas_community',
    icon: '👑',
    title: "Stella's Community",
    description: 'Invite 10 users.',
    target: 10,
    reward: 20,
  );

  // ==========================================================
  // 📋 ALL ACHIEVEMENTS
  //
  // Järjestys:
  //
  // 1. Louhintajaksot
  // 2. Louhintaputket
  // 3. STL-määrät
  // 4. Power Boost
  // 5. Päivittäiset kirjautumiset
  // 6. Kutsut
  //
  // Yhteensä 30 saavutusta.
  // ==========================================================

  static const List<Achievement> all = [
    // ----------------------------------------------------------
    // ⛏️ MINING CYCLES
    // ----------------------------------------------------------

    firstPaw,
    dedicatedMiner,
    seasonedMiner,
    veteranMiner,

    // ----------------------------------------------------------
    // 🔥 MINING STREAKS
    // ----------------------------------------------------------

    hotStreak,
    stellaOnFire,
    stellaLegend,
    stellaEternal,
    stellaBeyond,

    // ----------------------------------------------------------
    // 💎 STL AMOUNTS
    // ----------------------------------------------------------

    littleMiner,
    growingMiner,
    stlHunter,
    stlCollector,
    stlMaster,
    stlHoarder,
    stlTycoon,

    // ----------------------------------------------------------
    // ⚡ POWER BOOST
    // ----------------------------------------------------------

    powerPaws,
    superPaws,
    powerHunter,
    powerMaster,

    // ----------------------------------------------------------
    // 🐱 DAILY CHECK-INS
    // ----------------------------------------------------------

    stellasFriend,
    stellaCompanion,
    stellaDevotee,

    // ----------------------------------------------------------
    // 🐾 REFERRALS
    // ----------------------------------------------------------

    firstInvitation,
    friendCircle,
    stellasCommunity,
  ];
}