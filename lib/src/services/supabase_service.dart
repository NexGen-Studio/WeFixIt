import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    final fileName = 'veh_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final response = await client.storage.from('vehicle_photos').upload(fileName, File(path));
    if (response.isNotEmpty) {
      final publicUrl = client.storage.from('vehicle_photos').getPublicUrl(fileName);
      return publicUrl;
    }
    return null;
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
    // Return a short-lived signed URL for UI display (bucket is private)
    final signed = await client.storage.from('avatars').createSignedUrl(key, 60 * 60);
    final bust = DateTime.now().millisecondsSinceEpoch;
    return '$signed&t=$bust';
  }

  Future<String?> getSignedAvatarUrl(String key) async {
    try {
      final signed = await client.storage.from('avatars').createSignedUrl(key, 60 * 60);
      final bust = DateTime.now().millisecondsSinceEpoch;
      return '$signed&t=$bust';
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
