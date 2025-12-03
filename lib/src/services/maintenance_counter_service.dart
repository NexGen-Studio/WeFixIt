import 'package:shared_preferences/shared_preferences.dart';

class MaintenanceCounterService {
  static const String _keyMaintenanceCount = 'maintenance_free_count';
  static const int _freeLimit = 3;

  /// Get current count
  Future<int> getCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyMaintenanceCount) ?? 0;
  }

  /// Increment count (call after creating maintenance)
  Future<void> incrementCount() async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getCount();
    await prefs.setInt(_keyMaintenanceCount, current + 1);
  }

  /// Reset count (call after user watches ad)
  Future<void> resetCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMaintenanceCount, 0);
  }

  /// Check if user needs to watch ad
  Future<bool> needsToWatchAd() async {
    final count = await getCount();
    return count >= _freeLimit;
  }

  /// Check if user has free maintenance slots left
  Future<int> getFreeRemaining() async {
    final count = await getCount();
    final remaining = _freeLimit - count;
    return remaining > 0 ? remaining : 0;
  }
}
