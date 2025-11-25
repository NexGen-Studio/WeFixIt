import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile.dart';

class ProfileCacheService {
  static String _profileKey(String userId) => 'cached_profile_$userId';
  static String _vehicleKey(String userId) => 'cached_vehicle_$userId';

  static Future<UserProfile?> getProfile(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey(userId));
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserProfile.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveProfile(String userId, UserProfile? profile) async {
    final prefs = await SharedPreferences.getInstance();
    if (profile == null) {
      await prefs.remove(_profileKey(userId));
      return;
    }
    final map = profile.toMap();
    await prefs.setString(_profileKey(userId), jsonEncode(map));
  }

  static Future<Map<String, dynamic>?> getVehicle(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_vehicleKey(userId));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return _restoreTypes(decoded);
      }
    } catch (_) {}
    return null;
  }

  static Future<void> saveVehicle(String userId, Map<String, dynamic>? vehicle) async {
    final prefs = await SharedPreferences.getInstance();
    if (vehicle == null) {
      await prefs.remove(_vehicleKey(userId));
      return;
    }
    final sanitized = _sanitize(vehicle);
    await prefs.setString(_vehicleKey(userId), jsonEncode(sanitized));
  }

  static Map<String, dynamic> _sanitize(Map<String, dynamic> source) {
    return source.map((key, value) => MapEntry(key, _sanitizeValue(value)));
  }

  static dynamic _sanitizeValue(dynamic value) {
    if (value is DateTime) return value.toIso8601String();
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _sanitizeValue(v)));
    }
    if (value is Iterable) {
      return value.map(_sanitizeValue).toList();
    }
    return value;
  }

  static Map<String, dynamic> _restoreTypes(Map<String, dynamic> source) {
    return source.map((key, value) => MapEntry(key, _restoreValue(value)));
  }

  static dynamic _restoreValue(dynamic value) {
    if (value is String) {
      // Try to parse ISO8601 timestamps back to DateTime
      final isoMatch = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}').hasMatch(value);
      if (isoMatch) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      return value;
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _restoreValue(v)));
    }
    if (value is List) {
      return value.map(_restoreValue).toList();
    }
    return value;
  }

  static Future<void> clear(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey(userId));
    await prefs.remove(_vehicleKey(userId));
  }
}
