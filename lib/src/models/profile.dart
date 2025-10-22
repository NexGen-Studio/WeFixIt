class UserProfile {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final String? nickname;
  final String? avatarUrl;
  final String? emailObfuscated;
  final String? vehiclePhotoUrl;

  const UserProfile({
    required this.id,
    this.firstName,
    this.lastName,
    this.displayName,
    this.nickname,
    this.avatarUrl,
    this.emailObfuscated,
    this.vehiclePhotoUrl,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      displayName: map['display_name'] as String?,
      nickname: map['nickname'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      emailObfuscated: map['email_obfuscated'] as String?,
      vehiclePhotoUrl: map['vehicle_photo_url'] as String?,
    );
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (displayName != null) 'display_name': displayName,
      if (nickname != null) 'nickname': nickname,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (vehiclePhotoUrl != null) 'vehicle_photo_url': vehiclePhotoUrl,
    };
  }
}
