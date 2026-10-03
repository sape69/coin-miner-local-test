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
  // 🐾 FIRST PAW
  // ==========================================================

  static const Achievement firstPaw = Achievement(
    id: 'first_paw',
    icon: '🐾',
    title: 'First Paw',
    description: 'Start mining for the first time.',
    target: 1,
    reward: 2,
  );

  // ==========================================================
  // ⛏️ LITTLE MINER
  // ==========================================================

  static const Achievement littleMiner = Achievement(
    id: 'little_miner',
    icon: '⛏️',
    title: 'Little Miner',
    description: 'Mine your first 10 STL.',
    target: 10,
    reward: 5,
  );

  // ==========================================================
  // 💎 STL HUNTER
  // ==========================================================

  static const Achievement stlHunter = Achievement(
    id: 'stl_hunter',
    icon: '💎',
    title: 'STL Hunter',
    description: 'Mine 100 STL.',
    target: 100,
    reward: 10,
  );

  // ==========================================================
  // 🔥 HOT STREAK
  // ==========================================================

  static const Achievement hotStreak = Achievement(
    id: 'hot_streak',
    icon: '🔥',
    title: 'Hot Streak',
    description: 'Reach a 7 day mining streak.',
    target: 7,
    reward: 20,
  );

  // ==========================================================
  // 🐱 STELLA'S FRIEND
  // ==========================================================

  static const Achievement stellasFriend = Achievement(
    id: 'stellas_friend',
    icon: '🐱',
    title: "Stella's Friend",
    description: 'Complete 10 daily check-ins.',
    target: 10,
    reward: 15,
  );

  // ==========================================================
  // 🌱 GROWING MINER
  // ==========================================================

  static const Achievement growingMiner = Achievement(
    id: 'growing_miner',
    icon: '🌱',
    title: 'Growing Miner',
    description: 'Mine 25 STL.',
    target: 25,
    reward: 8,
  );

  // ==========================================================
  // 💰 STL COLLECTOR
  // ==========================================================

  static const Achievement stlCollector = Achievement(
    id: 'stl_collector',
    icon: '💰',
    title: 'STL Collector',
    description: 'Mine 500 STL.',
    target: 500,
    reward: 25,
  );

  // ==========================================================
  // 💎 STL MASTER
  // ==========================================================

  static const Achievement stlMaster = Achievement(
    id: 'stl_master',
    icon: '💎',
    title: 'STL Master',
    description: 'Mine 1,000 STL.',
    target: 1000,
    reward: 50,
  );

  // ==========================================================
  // ⛏️ DEDICATED MINER
  // ==========================================================

  static const Achievement dedicatedMiner = Achievement(
    id: 'dedicated_miner',
    icon: '⛏️',
    title: 'Dedicated Miner',
    description: 'Complete 25 mining cycles.',
    target: 25,
    reward: 30,
  );

  // ==========================================================
  // 🔥 STELLA ON FIRE
  // ==========================================================

  static const Achievement stellaOnFire = Achievement(
    id: 'stella_on_fire',
    icon: '🔥',
    title: 'Stella on Fire',
    description: 'Reach a 14 day mining streak.',
    target: 14,
    reward: 50,
  );

  // ==========================================================
  // 👑 STELLA LEGEND
  // ==========================================================

  static const Achievement stellaLegend = Achievement(
    id: 'stella_legend',
    icon: '👑',
    title: 'Stella Legend',
    description: 'Reach a 30 day mining streak.',
    target: 30,
    reward: 100,
  );

  // ==========================================================
  // ⚡ POWER PAWS
  // ==========================================================

  static const Achievement powerPaws = Achievement(
    id: 'power_paws',
    icon: '⚡',
    title: 'Power Paws',
    description: 'Use Power Boost 5 times.',
    target: 5,
    reward: 20,
  );

  // ==========================================================
  // ⚡⚡ SUPER PAWS
  // ==========================================================

  static const Achievement superPaws = Achievement(
    id: 'super_paws',
    icon: '⚡⚡',
    title: 'Super Paws',
    description: 'Use Power Boost 25 times.',
    target: 25,
    reward: 75,
  );

  // ==========================================================
  // 📋 ALL ACHIEVEMENTS
  // ==========================================================

  static const List<Achievement> all = [
    firstPaw,
    littleMiner,
    stlHunter,
    hotStreak,
    stellasFriend,
    growingMiner,
    stlCollector,
    stlMaster,
    dedicatedMiner,
    stellaOnFire,
    stellaLegend,
    powerPaws,
    superPaws,
  ];
}