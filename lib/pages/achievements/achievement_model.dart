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
    reward: 5,
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
    reward: 10,
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
    reward: 25,
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
    reward: 50,
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
    reward: 30,
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
  ];
}