// Dart SDK
// Flutter
// Third-party
// Project
import '../../domain/entities/profile_entity.dart';

/// Maps raw JSON from GET /api/v1/profiles/:handle to ProfileEntity.
///
/// Actual API response shape:
/// {
///   "handle": "eyad",
///   "display_name": "Eyad",
///   "bio": null,
///   "location": null,
///   "avatar_url": null,
///   "cover_photo_url": null,
///   "account_type": "LISTENER",
///   "visibility": "PUBLIC",
///   "favorite_genres": [],
///   "social_links": [],
///   "track_count": 0
/// }
class ProfileDto {
  final String? id; // Make nullable - API might not return it
  final String displayName;
  final String handle;
  final String? bio;
  final String? location;
  final String? avatarUrl;
  final String? coverPhotoUrl;
  final String accountType; // Changed from accountTier to match API
  final List<String> favoriteGenres;
  final Map<String, String> socialLinks; // Changed from externalLinks
  final String visibility;
  final int trackCount;
  final int? followersCount;
  final int? followingCount;

  const ProfileDto({
    this.id,
    required this.displayName,
    required this.handle,
    this.bio,
    this.location,
    this.avatarUrl,
    this.coverPhotoUrl,
    required this.accountType,
    required this.favoriteGenres,
    required this.socialLinks,
    required this.visibility,
    required this.trackCount,
    this.followersCount,
    this.followingCount,
  });

factory ProfileDto.fromJson(Map<String, dynamic> json) {
  final rawLinks = json['social_links'] ?? json['socialLinks'];
  Map<String, String> links = {};

  if (rawLinks is Map<String, dynamic>) {
    links = rawLinks.map((k, v) => MapEntry(k, v.toString()));
  } else if (rawLinks is List) {
    links = {};
  }

  final rawGenres =
      (json['favorite_genres'] ?? json['favoriteGenres']) as List<dynamic>? ?? [];
  final genres = rawGenres.map((e) {
    if (e is Map<String, dynamic>) {
      return (e['slug'] ?? e['name'] ?? e.toString()).toString();
    }
    return e.toString();
  }).toList();

  return ProfileDto(
    id: (json['id'] ?? json['userId']) as String?,
    displayName: (json['display_name'] ?? json['displayName']) as String? ?? '',
    handle: (json['handle']) as String? ?? '',
    bio: (json['bio']) as String?,
    location: (json['location']) as String?,
    avatarUrl: (json['avatar_url'] ?? json['avatarUrl']) as String?,
    coverPhotoUrl:
        (json['cover_photo_url'] ?? json['coverPhotoUrl']) as String?,
    accountType:
        (json['account_type'] ?? json['accountType']) as String? ?? 'LISTENER',
    favoriteGenres: genres,
    socialLinks: links,
    visibility: (json['visibility']) as String? ?? 'PUBLIC',
    trackCount: (json['track_count'] ?? json['trackCount']) as int? ?? 0,
    followersCount:
        (json['followers_count'] ?? json['followersCount']) as int?,
    followingCount:
        (json['following_count'] ?? json['followingCount']) as int?,
  );
}

  ProfileEntity toEntity() {
    // Generate a temporary ID if none exists
    final entityId = id ?? handle;

    return ProfileEntity(
      id: entityId,
      displayName: displayName,
      handle: handle,
      bio: bio,
      location: location,
      avatarUrl: avatarUrl,
      coverPhotoUrl: coverPhotoUrl,
      accountTier:
          accountType == 'ARTIST' ? AccountTier.ARTIST : AccountTier.LISTENER,
      favoriteGenres: favoriteGenres,
      externalLinks: socialLinks,
      visibility: visibility == 'PRIVATE'
          ? ProfileVisibility.PRIVATE
          : ProfileVisibility.PUBLIC,
      followersCount: followersCount ?? 0,
      followingCount: followingCount ?? 0,
    );
  }
}
