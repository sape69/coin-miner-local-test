import 'package:flutter/material.dart';

import '../../localization/achievements/achievements_localization.dart';
import '../../widgets/cat_avatar.dart';
import 'achievement_card.dart';
import 'achievement_model.dart';
import 'achievements_service.dart';

// ============================================================
// 🏆 STELLURIINI ACHIEVEMENTS PAGE
// ============================================================

class AchievementsPage extends StatefulWidget {
  final String languageCode;

  const AchievementsPage({
    super.key,
    this.languageCode = 'en',
  });

  @override
  State<AchievementsPage> createState() =>
      _AchievementsPageState();
}

class _AchievementsPageState
    extends State<AchievementsPage> {
  // ==========================================================
  // 🔧 SERVICE
  // ==========================================================

  final AchievementsService _service =
      AchievementsService();

  // ==========================================================
  // 📊 STATE
  // ==========================================================

  bool _loading = true;

  String? _error;

  Map<String, AchievementProgress> _progress = {};

  // ==========================================================
  // 🎨 STELLA COLORS
  // ==========================================================

  static const Color backgroundColor =
      Color(0xFF120B24);

  static const Color cardColor =
      Color(0xFF21113B);

  static const Color accentColor =
      Color(0xFFB58CFF);

  static const Color pinkColor =
      Color(0xFFFFB7E8);

  static const Color goldColor =
      Color(0xFFFFD166);

  static const Color secondaryTextColor =
      Color(0xFFBFAEDB);

  // ==========================================================
  // 🌍 LOCALIZATION
  // ==========================================================

  AchievementsLocalization get _localization =>
      AchievementsLocalization(
        widget.languageCode,
      );

  // ==========================================================
  // 🚀 INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _loadAchievements();
  }

  // ==========================================================
  // 📥 LOAD ACHIEVEMENTS
  // ==========================================================

  Future<void> _loadAchievements() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      await _service.initializeAchievements();

      final List<AchievementProgress> achievements =
          await _service.getAchievements();

      final Map<String, AchievementProgress>
          progressMap = {
        for (final AchievementProgress achievement
            in achievements)
          achievement.achievementId: achievement,
      };

      if (!mounted) {
        return;
      }

      setState(() {
        _progress = progressMap;
        _loading = false;
      });
    } catch (error) {
      debugPrint(
        'Achievements load error: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  // ==========================================================
  // 📊 GET PROGRESS
  // ==========================================================

  AchievementProgress _getProgress(
    Achievement achievement,
  ) {
    return _progress[achievement.id] ??
        AchievementProgress.empty(
          achievementId: achievement.id,
          target: achievement.target,
          reward: achievement.reward,
        );
  }

  // ==========================================================
  // 🏆 COMPLETED COUNT
  // ==========================================================

  int get _completedCount {
    return StelluriiniAchievements.all
        .where(
          (Achievement achievement) =>
              _getProgress(
                achievement,
              ).unlocked,
        )
        .length;
  }

  // ==========================================================
  // 🏆 TOTAL COUNT
  // ==========================================================

  int get _totalCount {
    return StelluriiniAchievements.all.length;
  }

  // ==========================================================
  // 📊 COMPLETION
  // ==========================================================

  double get _completion {
    if (_totalCount == 0) {
      return 0;
    }

    return _completedCount / _totalCount;
  }

  // ==========================================================
  // 🏆 HEADER
  // ==========================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF34204F),
            Color(0xFF1D1034),
          ],
        ),
        border: Border.all(
          color: accentColor.withValues(
            alpha: 0.30,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(
              alpha: 0.08,
            ),
            blurRadius: 22,
            offset: const Offset(
              0,
              8,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          // ====================================================
          // 🐱 STELLA
          // ====================================================

          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(
                alpha: 0.12,
              ),
              border: Border.all(
                color: pinkColor.withValues(
                  alpha: 0.30,
                ),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: pinkColor.withValues(
                    alpha: 0.10,
                  ),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Center(
              child: CatAvatar(
                size: 82,
              ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          // ====================================================
          // TITLE
          // ====================================================

          Text(
            _localization.get(
              'achievementsTitle',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          Text(
            _localization.get(
              'achievementsSubtitle',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 13,
              height: 1.4,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          // ====================================================
          // 📊 COMPLETION
          // ====================================================

          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value: _completion,
                    backgroundColor:
                        Colors.white.withValues(
                      alpha: 0.08,
                    ),
                    valueColor:
                        const AlwaysStoppedAnimation<
                            Color>(
                      goldColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Text(
                '$_completedCount/$_totalCount',
                style: const TextStyle(
                  color: goldColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            _localization.get(
              'achievementsCompleted',
            ),
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 🏆 ACHIEVEMENT LIST
  // ==========================================================

  Widget _buildAchievementList() {
    return Column(
      children: StelluriiniAchievements.all
          .map(
            (
              Achievement achievement,
            ) {
              final AchievementProgress progress =
                  _getProgress(
                achievement,
              );

              return AchievementCard(
                achievement: achievement,
                progress: progress.safeProgress,
                unlocked: progress.unlocked,
                localization: _localization,
              );
            },
          )
          .toList(),
    );
  }

  // ==========================================================
  // ❌ ERROR
  // ==========================================================

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: Colors.redAccent.withValues(
            alpha: 0.25,
          ),
        ),
      ),
      child: Column(
        children: [
          const Text(
            '🐱💔',
            style: TextStyle(
              fontSize: 38,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            _localization.get(
              'achievementsLoadError',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          OutlinedButton.icon(
            onPressed: _loadAchievements,
            icon: const Icon(
              Icons.refresh,
            ),
            label: Text(
              _localization.get(
                'retry',
              ),
            ),
            style:
                OutlinedButton.styleFrom(
              foregroundColor:
                  accentColor,
              side: BorderSide(
                color:
                    accentColor.withValues(
                  alpha: 0.40,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 🔙 BACK BUTTON
  // ==========================================================

  void _goBack() {
    Navigator.of(context).pop();
  }

  // ==========================================================
  // 🏗️ BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
          ),
        ),
        title: Text(
          _localization.get(
            'achievementsTitle',
          ),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadAchievements,
            icon: const Icon(
              Icons.refresh,
              color: accentColor,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child:
                    CircularProgressIndicator(
                  color: accentColor,
                ),
              )
            : RefreshIndicator(
                color: accentColor,
                backgroundColor: cardColor,
                onRefresh: _loadAchievements,
                child: SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    30,
                  ),
                  child: Column(
                    children: [
                      _buildHeader(),

                      const SizedBox(
                        height: 22,
                      ),

                      if (_error != null)
                        _buildError()
                      else
                        _buildAchievementList(),

                      const SizedBox(
                        height: 8,
                      ),

                      // ====================================
                      // 🐾 STELLA FOOTER
                      // ====================================

                      Text(
                        _localization.get(
                          'achievementsStellaProud',
                        ),
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color:
                              pinkColor.withValues(
                            alpha: 0.70,
                          ),
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}