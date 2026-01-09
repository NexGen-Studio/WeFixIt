import 'package:shared_preferences/shared_preferences.dart';

class CostsCounterService {
  static const String _keyCostsCount = 'costs_free_count';
  static const int _freeLimit = 3;

  /// Get current count
  Future<int> getCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCostsCount) ?? 0;
  }

  /// Increment count (call after creating cost)
  Future<void> incrementCount() async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getCount();
    await prefs.setInt(_keyCostsCount, current + 1);
  }

  /// Reset count (call after user watches ad)
  Future<void> resetCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCostsCount, 0);
  }

  /// Check if user needs to watch ad
  Future<bool> needsToWatchAd() async {
    final count = await getCount();
    return count >= _freeLimit;
  }

  /// Check if user has free cost slots left
  Future<int> getFreeRemaining() async {
    final count = await getCount();
    final remaining = _freeLimit - count;
    return remaining > 0 ? remaining : 0;
  }
}
