

/// Visibility options that match the API values PUBLIC / PRIVATE.
enum ProfileVisibility {
  PUBLIC,
  PRIVATE,
}

/// Account tier that matches the API values ARTIST / LISTENER.
enum AccountTier {
  ARTIST,
  LISTENER,
}

/// Pure Dart model representing a user profile.
class ProfileEntity {
  final String id;
  final String displayName;
  final String handle;
  final String? bio;
  final String? location;
  final String? avatarUrl;
  final String? coverPhotoUrl;
  final AccountTier accountTier;
  final List<String> favoriteGenres;
  final Map<String, String> externalLinks;
  final ProfileVisibility visibility;

  const ProfileEntity({
    required this.id,
    required this.displayName,
    required this.handle,
    this.bio,
    this.location,
    this.avatarUrl,
    this.coverPhotoUrl,
    required this.accountTier,
    required this.favoriteGenres,
    required this.externalLinks,
    required this.visibility,
  });

  /// Creates a copy of this entity with certain fields replaced.
  ProfileEntity copyWith({
    String? displayName,
    String? bio,
    String? location,
    String? avatarUrl,
    String? coverPhotoUrl,
    List<String>? favoriteGenres,
    Map<String, String>? externalLinks,
    ProfileVisibility? visibility,
  }) {
    return ProfileEntity(
      id: id,
      displayName: displayName ?? this.displayName,
      handle: handle,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      accountTier: accountTier,
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
      externalLinks: externalLinks ?? this.externalLinks,
      visibility: visibility ?? this.visibility,
    );
  }
}