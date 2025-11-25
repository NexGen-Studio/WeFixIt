import 'package:flutter/material.dart';

/// Achievement für Kosten-Tracker (Gamification)
class CostAchievement {
  final String id;
  final String titleKey; // i18n key
  final String descriptionKey; // i18n key
  final IconData icon;
  final Color color;
  final int requiredCount;
  final AchievementType type;

  const CostAchievement({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
    required this.color,
    required this.requiredCount,
    required this.type,
  });
}

enum AchievementType {
  firstEntry,
  tankPro,
  sparfuchs,
  ordnungsfan,
  yearComplete,
}

/// Vordefinierte Achievements
class CostAchievements {
  static const firstEntry = CostAchievement(
    id: 'first_entry',
    titleKey: 'costs.achievement_first_entry_title',
    descriptionKey: 'costs.achievement_first_entry_desc',
    icon: Icons.celebration,
    color: Color(0xFFFFB129),
    requiredCount: 1,
    type: AchievementType.firstEntry,
  );

  static const tankPro = CostAchievement(
    id: 'tank_pro',
    titleKey: 'costs.achievement_tank_pro_title',
    descriptionKey: 'costs.achievement_tank_pro_desc',
    icon: Icons.local_gas_station,
    color: Color(0xFFE53935),
    requiredCount: 10,
    type: AchievementType.tankPro,
  );

  static const sparfuchs = CostAchievement(
    id: 'sparfuchs',
    titleKey: 'costs.achievement_sparfuchs_title',
    descriptionKey: 'costs.achievement_sparfuchs_desc',
    icon: Icons.savings,
    color: Color(0xFF4CAF50),
    requiredCount: 1,
    type: AchievementType.sparfuchs,
  );

  static const ordnungsfan = CostAchievement(
    id: 'ordnungsfan',
    titleKey: 'costs.achievement_ordnungsfan_title',
    descriptionKey: 'costs.achievement_ordnungsfan_desc',
    icon: Icons.folder_special,
    color: Color(0xFF2196F3),
    requiredCount: 10,
    type: AchievementType.ordnungsfan,
  );

  static const yearComplete = CostAchievement(
    id: 'year_complete',
    titleKey: 'costs.achievement_year_complete_title',
    descriptionKey: 'costs.achievement_year_complete_desc',
    icon: Icons.emoji_events,
    color: Color(0xFF9C27B0),
    requiredCount: 1,
    type: AchievementType.yearComplete,
  );

  static const List<CostAchievement> all = [
    firstEntry,
    tankPro,
    sparfuchs,
    ordnungsfan,
    yearComplete,
  ];
}

/// User Achievement Progress (in SharedPreferences gespeichert)
class AchievementProgress {
  final String achievementId;
  final int currentCount;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const AchievementProgress({
    required this.achievementId,
    required this.currentCount,
    required this.isUnlocked,
    this.unlockedAt,
  });

  Map<String, dynamic> toJson() => {
        'achievementId': achievementId,
        'currentCount': currentCount,
        'isUnlocked': isUnlocked,
        'unlockedAt': unlockedAt?.toIso8601String(),
      };

  factory AchievementProgress.fromJson(Map<String, dynamic> json) {
    return AchievementProgress(
      achievementId: json['achievementId'] as String,
      currentCount: json['currentCount'] as int,
      isUnlocked: json['isUnlocked'] as bool,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
    );
  }

  AchievementProgress copyWith({
    int? currentCount,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return AchievementProgress(
      achievementId: achievementId,
      currentCount: currentCount ?? this.currentCount,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}
