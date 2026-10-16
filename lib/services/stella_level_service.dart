// ============================================================
// 🐱 STELLURIINI - STELLA LEVEL SERVICE
// ============================================================
//
// Stella saa tasonsa saavutettujen saavutusten perusteella.
//
// Taso ei vaikuta:
// - STL-määrään
// - hash rateen
// - louhinnan nopeuteen
// - Power Boostiin
//
// Se on pelaajalle näkyvä etenemisjärjestelmä.
// ============================================================

class StellaLevelInfo {
  final int level;
  final String name;
  final String icon;
  final int completedAchievements;
  final int currentLevelRequirement;
  final int nextLevelRequirement;

  const StellaLevelInfo({
    required this.level,
    required this.name,
    required this.icon,
    required this.completedAchievements,
    required this.currentLevelRequirement,
    required this.nextLevelRequirement,
  });

  // ============================================================
  // 📊 PROGRESS
  // ============================================================

  double get progress {
    if (nextLevelRequirement <= currentLevelRequirement) {
      return 1.0;
    }

    final int progressAmount =
        completedAchievements - currentLevelRequirement;

    final int levelRange =
        nextLevelRequirement - currentLevelRequirement;

    final double value =
        progressAmount / levelRange;

    if (value < 0) {
      return 0.0;
    }

    if (value > 1) {
      return 1.0;
    }

    return value;
  }

  // ============================================================
  // 🔢 SAAVUTUKSET SEURAAVAAN TASOON
  // ============================================================

  int get achievementsToNextLevel {
    final int remaining =
        nextLevelRequirement - completedAchievements;

    if (remaining < 0) {
      return 0;
    }

    return remaining;
  }

  // ============================================================
  // ⭐ ONKO MAKSIMITASO
  // ============================================================

  bool get isMaxLevel {
    return level >= StellaLevelService.maxLevel;
  }
}

class StellaLevelService {
  StellaLevelService._();

  // ============================================================
  // ⭐ LEVELIT
  // ============================================================

  static const int maxLevel = 6;

  // ============================================================
  // 🐱 LEVEL-RAJAT
  // ============================================================
  //
  // 0  saavutusta → Level 1
  // 1  saavutus    → Level 2
  // 3  saavutusta  → Level 3
  // 6  saavutusta  → Level 4
  // 10 saavutusta  → Level 5
  // 13 saavutusta  → Level 6
  //
  // Stella Legend vaatii kaikki nykyiset 13 achievementia.
  //
  // Taso ei vaikuta mihinkään pelilliseen arvoon.
  // ============================================================

  static StellaLevelInfo calculate(
    int completedAchievements,
  ) {
    final int safeCompleted =
        completedAchievements < 0
            ? 0
            : completedAchievements;

    // ----------------------------------------------------------
    // 👑 LEVEL 6 - STELLA LEGEND
    // ----------------------------------------------------------

    if (safeCompleted >= 13) {
      return StellaLevelInfo(
        level: 6,
        name: 'Stella Legend',
        icon: '👑',
        completedAchievements: safeCompleted,
        currentLevelRequirement: 13,
        nextLevelRequirement: 13,
      );
    }

    // ----------------------------------------------------------
    // 💎 LEVEL 5 - MASTER STELLA
    // ----------------------------------------------------------

    if (safeCompleted >= 10) {
      return StellaLevelInfo(
        level: 5,
        name: 'Master Stella',
        icon: '💎',
        completedAchievements: safeCompleted,
        currentLevelRequirement: 10,
        nextLevelRequirement: 13,
      );
    }

    // ----------------------------------------------------------
    // ⚡ LEVEL 4 - POWER STELLA
    // ----------------------------------------------------------

    if (safeCompleted >= 6) {
      return StellaLevelInfo(
        level: 4,
        name: 'Power Stella',
        icon: '⚡',
        completedAchievements: safeCompleted,
        currentLevelRequirement: 6,
        nextLevelRequirement: 10,
      );
    }

    // ----------------------------------------------------------
    // ⛏️ LEVEL 3 - MINING STELLA
    // ----------------------------------------------------------

    if (safeCompleted >= 3) {
      return StellaLevelInfo(
        level: 3,
        name: 'Mining Stella',
        icon: '⛏️',
        completedAchievements: safeCompleted,
        currentLevelRequirement: 3,
        nextLevelRequirement: 6,
      );
    }

    // ----------------------------------------------------------
    // 🐾 LEVEL 2 - CURIOUS STELLA
    // ----------------------------------------------------------

    if (safeCompleted >= 1) {
      return StellaLevelInfo(
        level: 2,
        name: 'Curious Stella',
        icon: '🐾',
        completedAchievements: safeCompleted,
        currentLevelRequirement: 1,
        nextLevelRequirement: 3,
      );
    }

    // ----------------------------------------------------------
    // 🐱 LEVEL 1 - LITTLE STELLA
    // ----------------------------------------------------------

    return StellaLevelInfo(
      level: 1,
      name: 'Little Stella',
      icon: '🐱',
      completedAchievements: safeCompleted,
      currentLevelRequirement: 0,
      nextLevelRequirement: 1,
    );
  }

  // ============================================================
  // 📝 LEVELINIMI
  // ============================================================

  static String levelName(int level) {
    switch (level) {
      case 6:
        return 'Stella Legend';

      case 5:
        return 'Master Stella';

      case 4:
        return 'Power Stella';

      case 3:
        return 'Mining Stella';

      case 2:
        return 'Curious Stella';

      default:
        return 'Little Stella';
    }
  }

  // ============================================================
  // 🐾 LEVELIN IKONI
  // ============================================================

  static String levelIcon(int level) {
    switch (level) {
      case 6:
        return '👑';

      case 5:
        return '💎';

      case 4:
        return '⚡';

      case 3:
        return '⛏️';

      case 2:
        return '🐾';

      default:
        return '🐱';
    }
  }
}