// Dart SDK
// Flutter
// Third-party
// Project
import '../../domain/entities/profile_entity.dart';

/// Maps raw JSON from GET /api/v1/profiles/:handle to ProfileEntity.
///
/// API response shape:
/// {
///   "id": "uuid",
///   "display_name": "Ahmed Hassan",
///   "handle": "ahmed-hassan-beats",
///   "bio": "...",
///   "location": "Cairo, Egypt",
///   "avatar_url": "https://...",
///   "cover_photo_url": "https://...",
///   "account_tier": "ARTIST",
///   "favorite_genres": ["Oriental", "Electronic"],
///   "external_links": {"instagram": "@ahmed"},
///   "visibility": "PUBLIC"
/// }
class ProfileDto {
  final String id;
  final String displayName;
  final String handle;
  final String? bio;
  final String? location;
  final String? avatarUrl;
  final String? coverPhotoUrl;
  final String accountTier;
  final List<String> favoriteGenres;
  final Map<String, String> externalLinks;
  final String visibility;

  const ProfileDto({
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

  factory ProfileDto.fromJson(Map<String, dynamic> json) {
    final rawLinks = json['external_links'] as Map<String, dynamic>? ?? {};
    final links = rawLinks.map((k, v) => MapEntry(k, v.toString()));

    final rawGenres = json['favorite_genres'] as List<dynamic>? ?? [];
    final genres = rawGenres.map((e) => e.toString()).toList();

    return ProfileDto(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      handle: json['handle'] as String,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      coverPhotoUrl: json['cover_photo_url'] as String?,
      accountTier: json['account_tier'] as String? ?? 'LISTENER',
      favoriteGenres: genres,
      externalLinks: links,
      visibility: json['visibility'] as String? ?? 'PUBLIC',
    );
  }

  ProfileEntity toEntity() {
    return ProfileEntity(
      id: id,
      displayName: displayName,
      handle: handle,
      bio: bio,
      location: location,
      avatarUrl: avatarUrl,
      coverPhotoUrl: coverPhotoUrl,
      accountTier:
          accountTier == 'ARTIST' ? AccountTier.ARTIST : AccountTier.LISTENER,
      favoriteGenres: favoriteGenres,
      externalLinks: externalLinks,
      visibility: visibility == 'PRIVATE'
          ? ProfileVisibility.PRIVATE
          : ProfileVisibility.PUBLIC,
    );
  }
}
