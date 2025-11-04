import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile.dart';

class SupabaseService {
  final SupabaseClient client;
  SupabaseService(this.client);

  Future<AuthResponse> signIn({required String email, required String password}) {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({required String email, required String password}) {
    return client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    final res = await client.from('profiles').select().eq('id', user.id).maybeSingle();
    return res;
  }

  Future<void> upsertProfile(Map<String, dynamic> profile) async {
    await client.from('profiles').upsert(profile);
  }

  Future<UserProfile?> fetchUserProfile() async {
    final data = await getProfile();
    if (data == null) return null;
    return UserProfile.fromMap(data);
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final user = client.auth.currentUser;
    if (user == null) return;
    final update = profile.toUpdateMap()..['id'] = user.id;
    await upsertProfile(update);
  }

  Future<String?> uploadVehiclePhoto(String path) async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    try {
      final key = 'vehicle_${user.id}.jpg';
      // Overwrite same key for single vehicle photo per user
      await client.storage
          .from('vehicle_photos')
          .upload(key, File(path), fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'));
      // Return public URL (keine Cache-Buster anhängen)
      final publicUrl = client.storage.from('vehicle_photos').getPublicUrl(key);
      final finalUrl = publicUrl;
      // Update profile immediately
      await client.from('profiles').upsert({
        'id': user.id,
        'vehicle_photo_url': finalUrl,
      });
      return finalUrl;
    } catch (e) {
      print('Error uploading vehicle photo: $e');
      return null;
    }
  }
  
  Future<String?> copyAvatarToVehiclePhoto() async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    try {
      // Download avatar
      final avatarKey = 'avatar_${user.id}.jpg';
      final avatarData = await client.storage.from('avatars').download(avatarKey);
      // Upload as vehicle photo
      final vehicleKey = 'vehicle_${user.id}.jpg';
      await client.storage
          .from('vehicle_photos')
          .uploadBinary(vehicleKey, avatarData, fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'));
      final publicUrl = client.storage.from('vehicle_photos').getPublicUrl(vehicleKey);
      // Update profile immediately
      await client.from('profiles').upsert({
        'id': user.id,
        'vehicle_photo_url': publicUrl,
      });
      return publicUrl;
    } catch (e) {
      print('Error copying avatar to vehicle: $e');
      return null;
    }
  }

  Future<String?> uploadAvatarPhoto(String path) async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    final key = 'avatar_${user.id}.jpg';
    // Overwrite same key for single avatar per user
    await client.storage
        .from('avatars')
        .upload(key, File(path), fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'));
    // Store the key in profiles.avatar_url (used as storage key)
    await client.from('profiles').upsert({'id': user.id, 'avatar_url': key});
    // Return a short-lived signed URL für UI (bucket ist privat). Cache diese URL lokal.
    final signed = await client.storage.from('avatars').createSignedUrl(key, 60 * 60);
    // Cache aktualisieren (55 Minuten TTL)
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'avatar_signed_url_'+key;
      final expKey = 'avatar_signed_exp_'+key;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final ttlMs = 55 * 60 * 1000; // 55 Minuten
      await prefs.setString(cacheKey, signed);
      await prefs.setInt(expKey, nowMs + ttlMs);
    } catch (_) {}
    return signed;
  }

  Future<String?> getSignedAvatarUrl(String key) async {
    try {
      // Bereits vollständige URL? Dann direkt verwenden (kein erneutes Signieren)
      if (key.startsWith('http://') || key.startsWith('https://')) {
        return key;
      }

      // SharedPreferences-Cache prüfen
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'avatar_signed_url_'+key;
      final expKey = 'avatar_signed_exp_'+key;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final cachedUrl = prefs.getString(cacheKey);
      final expMs = prefs.getInt(expKey) ?? 0;
      if (cachedUrl != null && nowMs < expMs) {
        return cachedUrl;
      }

      // Neue Signierung (1 Stunde gültig), aber wir cachen nur 55 Minuten
      final signed = await client.storage.from('avatars').createSignedUrl(key, 60 * 60);
      final ttlMs = 55 * 60 * 1000; // 55 Minuten
      await prefs.setString(cacheKey, signed);
      await prefs.setInt(expKey, nowMs + ttlMs);
      return signed;
    } catch (_) {
      return null;
    }
  }

  // Vehicles (MVP: ein Hauptfahrzeug)
  Future<Map<String, dynamic>?> fetchPrimaryVehicle() async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    final res = await client
        .from('vehicles')
        .select()
        .eq('user_id', user.id)
        .order('created_at')
        .limit(1)
        .maybeSingle();
    return res;
  }

  Future<void> savePrimaryVehicle(Map<String, dynamic> vehicle) async {
    final user = client.auth.currentUser;
    if (user == null) return;
    // upsert by id if present, otherwise insert with user_id
    final data = {
      'user_id': user.id,
      ...vehicle,
    };
    await client.from('vehicles').upsert(data);
  }

  // Quick tips
  Future<List<Map<String, dynamic>>> fetchTips() async {
    final res = await client
        .from('tips')
        .select()
        .order('created_at')
        .limit(50);
    return (res as List).cast<Map<String, dynamic>>();
  }
}
