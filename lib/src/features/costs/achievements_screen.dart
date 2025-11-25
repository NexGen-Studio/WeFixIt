import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../i18n/app_localizations.dart';
import '../../services/achievements_service.dart';
import '../../services/costs_service.dart';
import '../../models/cost_achievement.dart';

/// Screen zum Anzeigen aller Achievements
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late final AchievementsService _achievementsService;
  
  List<AchievementProgress> _progress = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _achievementsService = AchievementsService(CostsService());
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);

    try {
      // Achievements prüfen und aktualisieren
      await _achievementsService.checkAchievements();
      
      // Fortschritt laden
      final progress = await _achievementsService.getAllProgress();

      setState(() {
        _progress = progress;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading achievements: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F141A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151C23),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          t.tr('costs.achievements'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFFFFB129)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadProgress,
              color: const Color(0xFFFFB129),
              backgroundColor: const Color(0xFF151C23),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header mit Statistik
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFFB129).withOpacity(0.2),
                          const Color(0xFFFFB129).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFFB129).withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Color(0xFFFFB129),
                          size: 48,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.tr('costs.achievements_unlocked'),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_progress.where((p) => p.isUnlocked).length} / ${CostAchievements.all.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Achievement-Liste
                  ...CostAchievements.all.asMap().entries.map((entry) {
                    final achievement = entry.value;
                    final progress = _progress.firstWhere(
                      (p) => p.achievementId == achievement.id,
                      orElse: () => AchievementProgress(
                        achievementId: achievement.id,
                        currentCount: 0,
                        isUnlocked: false,
                      ),
                    );

                    return _buildAchievementCard(achievement, progress, t);
                  }).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildAchievementCard(
    CostAchievement achievement,
    AchievementProgress progress,
    AppLocalizations t,
  ) {
    final percentage = (progress.currentCount / achievement.requiredCount * 100).clamp(0, 100);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151C23),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: progress.isUnlocked
              ? achievement.color.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
          width: progress.isUnlocked ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: progress.isUnlocked
                      ? achievement.color.withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  achievement.icon,
                  color: progress.isUnlocked
                      ? achievement.color
                      : Colors.white30,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              
              // Titel & Beschreibung
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.tr(achievement.titleKey),
                            style: TextStyle(
                              color: progress.isUnlocked
                                  ? Colors.white
                                  : Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (progress.isUnlocked)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: achievement.color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.tr(achievement.descriptionKey),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${progress.currentCount} / ${achievement.requiredCount}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${percentage.toInt()}%',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: const Color(0xFF1A2028),
                  valueColor: AlwaysStoppedAnimation(
                    progress.isUnlocked
                        ? achievement.color
                        : Colors.white30,
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
          
          // Freischalt-Datum
          if (progress.isUnlocked && progress.unlockedAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white38, size: 12),
                const SizedBox(width: 6),
                Text(
                  t.tr('costs.unlocked_on').replaceAll(
                    '{date}',
                    DateFormat('dd.MM.yyyy').format(progress.unlockedAt!),
                  ),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
