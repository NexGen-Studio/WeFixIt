import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import '../services/profile_cache_service.dart';
import '../services/supabase_service.dart';

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
  return ProfileController(ref);
});

class ProfileState {
  final bool isLoading;
  final bool isRefreshing;
  final UserProfile? profile;
  final Map<String, dynamic>? vehicle;
  final String? avatarUrlUi;
  final DateTime? lastSyncedAt;

  const ProfileState({
    this.isLoading = true,
    this.isRefreshing = false,
    this.profile,
    this.vehicle,
    this.avatarUrlUi,
    this.lastSyncedAt,
  });

  ProfileState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    UserProfile? profile,
    Map<String, dynamic>? vehicle,
    String? avatarUrlUi,
    DateTime? lastSyncedAt,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      profile: profile ?? this.profile,
      vehicle: vehicle ?? this.vehicle,
      avatarUrlUi: avatarUrlUi ?? this.avatarUrlUi,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController(this._ref) : super(const ProfileState()) {
    _init();
  }

  final Ref _ref;
  bool _initialized = false;
  String? _currentUserId;

  Future<void> _init() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      state = const ProfileState(isLoading: false);
      _initialized = true;
      return;
    }

    _currentUserId = user.id;
    final cachedProfile = await ProfileCacheService.getProfile(user.id);
    final cachedVehicle = await ProfileCacheService.getVehicle(user.id);

    String? avatarUrlUi;
    if (cachedProfile?.avatarUrl != null && cachedProfile!.avatarUrl!.isNotEmpty) {
      final svc = SupabaseService(client);
      avatarUrlUi = await svc.getSignedAvatarUrl(cachedProfile.avatarUrl!);
    }

    if (cachedProfile != null || cachedVehicle != null) {
      state = state.copyWith(
        isLoading: false,
        profile: cachedProfile ?? state.profile,
        vehicle: cachedVehicle ?? state.vehicle,
        avatarUrlUi: avatarUrlUi ?? state.avatarUrlUi,
      );
    }

    _initialized = true;
    await refreshFromRemote();
  }

  Future<void> ensureLoaded() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      if (_currentUserId != null) {
        await clear();
      }
      return;
    }

    if (_currentUserId != user.id) {
      _initialized = false;
    }

    if (!_initialized) {
      await _init();
    }
  }

  Future<void> refreshFromRemote({bool force = false}) async {
    if (_currentUserId == null) return;
    if (!force && state.isRefreshing) return;

    state = state.copyWith(isRefreshing: true);
    final client = Supabase.instance.client;
    final supabaseService = SupabaseService(client);

    final profile = await supabaseService.fetchUserProfile();
    Map<String, dynamic>? vehicle;
    String? avatarUrlUi;

    if (profile != null) {
      await ProfileCacheService.saveProfile(_currentUserId!, profile);
      if ((profile.avatarUrl ?? '').isNotEmpty) {
        avatarUrlUi = await supabaseService.getSignedAvatarUrl(profile.avatarUrl!);
      }
    } else {
      await ProfileCacheService.saveProfile(_currentUserId!, null);
    }

    vehicle = await supabaseService.fetchPrimaryVehicle();
    await ProfileCacheService.saveVehicle(_currentUserId!, vehicle);

    if (!mounted) return;
    state = state.copyWith(
      isLoading: false,
      isRefreshing: false,
      profile: profile,
      vehicle: vehicle,
      avatarUrlUi: avatarUrlUi,
      lastSyncedAt: DateTime.now(),
    );
  }

  Future<void> updateProfile({UserProfile? profile, Map<String, dynamic>? vehicle}) async {
    if (_currentUserId == null) return;

    final mergedProfile = profile ?? state.profile;
    final mergedVehicle = vehicle ?? state.vehicle;

    state = state.copyWith(profile: mergedProfile, vehicle: mergedVehicle);

    if (mergedProfile != null) {
      await ProfileCacheService.saveProfile(_currentUserId!, mergedProfile);
    } else {
      await ProfileCacheService.saveProfile(_currentUserId!, null);
    }

    if (vehicle != null) {
      await ProfileCacheService.saveVehicle(_currentUserId!, vehicle);
    }
  }

  Future<void> setAvatarUrlUi(String? url) async {
    state = state.copyWith(avatarUrlUi: url);
  }

  Future<void> clear() async {
    final userId = _currentUserId;
    state = const ProfileState(isLoading: false);
    if (userId != null) {
      await ProfileCacheService.clear(userId);
    }
    _initialized = false;
    _currentUserId = null;
  }
}
