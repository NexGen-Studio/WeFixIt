import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cost_achievement.dart';
import 'costs_service.dart';

/// Service für Achievement-Tracking (Gamification)
class AchievementsService {
  static const String _keyPrefix = 'achievement_';
  final CostsService _costsService;

  AchievementsService(this._costsService);

  // ============================================================================
  // Progress Tracking
  // ============================================================================

  /// Fortschritt für Achievement laden
  Future<AchievementProgress> getProgress(String achievementId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('$_keyPrefix$achievementId');
      
      if (json != null) {
        return AchievementProgress.fromJson(jsonDecode(json));
      }

      // Noch nicht vorhanden - initialisieren
      return AchievementProgress(
        achievementId: achievementId,
        currentCount: 0,
        isUnlocked: false,
      );
    } catch (e) {
      print('Error loading achievement progress: $e');
      return AchievementProgress(
        achievementId: achievementId,
        currentCount: 0,
        isUnlocked: false,
      );
    }
  }

  /// Fortschritt speichern
  Future<void> saveProgress(AchievementProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_keyPrefix${progress.achievementId}',
        jsonEncode(progress.toJson()),
      );
    } catch (e) {
      print('Error saving achievement progress: $e');
    }
  }

  /// Alle Achievement-Fortschritte laden
  Future<List<AchievementProgress>> getAllProgress() async {
    final List<AchievementProgress> progress = [];
    
    for (final achievement in CostAchievements.all) {
      progress.add(await getProgress(achievement.id));
    }

    return progress;
  }

  // ============================================================================
  // Achievement Checks
  // ============================================================================

  /// Prüft alle Achievements und aktualisiert Fortschritt
  Future<List<CostAchievement>> checkAchievements() async {
    final List<CostAchievement> newlyUnlocked = [];

    for (final achievement in CostAchievements.all) {
      final progress = await getProgress(achievement.id);
      
      if (progress.isUnlocked) continue; // Bereits freigeschaltet

      final currentCount = await _getCurrentCount(achievement.type);
      
      if (currentCount != progress.currentCount) {
        // Fortschritt hat sich geändert
        final newProgress = progress.copyWith(currentCount: currentCount);
        
        if (currentCount >= achievement.requiredCount) {
          // Achievement freigeschaltet!
          final unlockedProgress = newProgress.copyWith(
            isUnlocked: true,
            unlockedAt: DateTime.now(),
          );
          await saveProgress(unlockedProgress);
          newlyUnlocked.add(achievement);
        } else {
          await saveProgress(newProgress);
        }
      }
    }

    return newlyUnlocked;
  }

  /// Zählt aktuellen Stand für Achievement-Typ
  Future<int> _getCurrentCount(AchievementType type) async {
    try {
      switch (type) {
        case AchievementType.firstEntry:
          // Mindestens 1 Eintrag
          final costs = await _costsService.fetchAllCosts();
          return costs.isNotEmpty ? 1 : 0;

        case AchievementType.tankPro:
          // Anzahl Betankungen
          final costs = await _costsService.fetchAllCosts();
          return costs.where((c) => c.isRefueling).length;

        case AchievementType.ordnungsfan:
          // Anzahl Einträge mit Belegen
          final costs = await _costsService.fetchAllCosts();
          return costs.where((c) => c.photos.isNotEmpty).length;

        case AchievementType.sparfuchs:
          // Kosten unter Durchschnitt (diesen vs letzten Monat)
          final thisMonth = await _costsService.getCostsThisMonth();
          
          final now = DateTime.now();
          final lastMonthStart = DateTime(now.year, now.month - 1, 1);
          final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
          final lastMonth = await _costsService.getTotalCosts(
            startDate: lastMonthStart,
            endDate: lastMonthEnd,
          );

          if (lastMonth > 0 && thisMonth < lastMonth) {
            return 1; // Ziel erreicht
          }
          return 0;

        case AchievementType.yearComplete:
          // Mindestens 1 Jahr lang Einträge (min. 1 Eintrag pro Monat für 12 Monate)
          final costs = await _costsService.fetchAllCosts();
          if (costs.isEmpty) return 0;

          final oldestCost = costs.last;
          final now = DateTime.now();
          final daysSinceFirst = now.difference(oldestCost.date).inDays;
          
          if (daysSinceFirst >= 365) {
            // Prüfen ob wirklich regelmäßig Einträge (min. 10 Monate)
            final monthsWithEntries = <String>{};
            for (final cost in costs) {
              final key = '${cost.date.year}-${cost.date.month}';
              monthsWithEntries.add(key);
            }
            
            return monthsWithEntries.length >= 10 ? 1 : 0;
          }
          return 0;
      }
    } catch (e) {
      print('Error getting current count: $e');
      return 0;
    }
  }

  /// Neu freigeschaltete Achievements seit letztem Check
  Future<List<CostAchievement>> getNewlyUnlockedAchievements() async {
    return await checkAchievements();
  }

  /// Alle freigeschalteten Achievements
  Future<List<CostAchievement>> getUnlockedAchievements() async {
    final List<CostAchievement> unlocked = [];
    
    for (final achievement in CostAchievements.all) {
      final progress = await getProgress(achievement.id);
      if (progress.isUnlocked) {
        unlocked.add(achievement);
      }
    }

    return unlocked;
  }

  /// Fortschritt für UI anzeigen (z.B. "7 / 10")
  Future<String> getProgressText(CostAchievement achievement) async {
    final progress = await getProgress(achievement.id);
    return '${progress.currentCount} / ${achievement.requiredCount}';
  }

  /// Fortschritt in Prozent
  Future<double> getProgressPercentage(CostAchievement achievement) async {
    final progress = await getProgress(achievement.id);
    final percentage = (progress.currentCount / achievement.requiredCount) * 100;
    return percentage.clamp(0, 100);
  }
}
