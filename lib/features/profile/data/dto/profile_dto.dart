import '../../domain/entities/profile_entity.dart';

class ProfileDto {
  final String? id;
  final String displayName;
  final String handle;
  final String? bio;
  final String? location;
  final String? website;
  final String? avatarUrl;
  final String? coverPhotoUrl;
  final String accountType;
  final List<String> favoriteGenres;
  final Map<String, String> socialLinks;
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
    this.website,
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
    final rawLinks =
        json['social_links'] ?? json['socialLinks'] ?? json['links'];
    final Map<String, String> links = _parseLinks(rawLinks);

    final rawGenres =
        (json['favorite_genres'] ?? json['favoriteGenres']) as List<dynamic>? ??
            <dynamic>[];
    final genres = rawGenres.map((e) {
      if (e is Map<String, dynamic>) {
        return (e['slug'] ?? e['name'] ?? e.toString()).toString();
      }
      return e.toString();
    }).toList();

    final bool isPrivate = json['is_private'] == true;
    final String visibility =
        isPrivate ? 'PRIVATE' : ((json['visibility']) as String? ?? 'PUBLIC');

    return ProfileDto(
      id: (json['id'] ?? json['userId'])?.toString(),
      displayName:
          (json['display_name'] ?? json['displayName']) as String? ?? '',
      handle: (json['handle']) as String? ?? '',
      bio: (json['bio']) as String?,
      location: (json['location']) as String?,
      website: (json['website']) as String?,
      avatarUrl: (json['avatar_url'] ?? json['avatarUrl']) as String?,
      coverPhotoUrl:
          (json['cover_photo_url'] ?? json['coverPhotoUrl']) as String?,
      accountType: (json['account_type'] ?? json['accountType']) as String? ??
          'LISTENER',
      favoriteGenres: genres,
      socialLinks: links,
      visibility: visibility,
      trackCount: (json['track_count'] ?? json['trackCount']) as int? ?? 0,
      followersCount:
          (json['followers_count'] ?? json['followersCount']) as int?,
      followingCount:
          (json['following_count'] ?? json['followingCount']) as int?,
    );
  }

  ProfileEntity toEntity() {
    final entityId = id ?? handle;

    return ProfileEntity(
      id: entityId,
      displayName: displayName,
      handle: handle,
      bio: bio,
      location: location,
      website: website,
      avatarUrl: avatarUrl,
      coverPhotoUrl: coverPhotoUrl,
      accountTier: accountType.toUpperCase() == 'ARTIST'
          ? AccountTier.ARTIST
          : AccountTier.LISTENER,
      favoriteGenres: favoriteGenres,
      externalLinks: socialLinks,
      visibility: visibility.toUpperCase() == 'PRIVATE'
          ? ProfileVisibility.PRIVATE
          : ProfileVisibility.PUBLIC,
      followersCount: followersCount ?? 0,
      followingCount: followingCount ?? 0,
    );
  }

  static Map<String, String> _parseLinks(dynamic rawLinks) {
    if (rawLinks is Map<String, dynamic>) {
      return rawLinks.map(
        (key, value) => MapEntry(
          key.toString().trim().toLowerCase(),
          value.toString(),
        ),
      );
    }

    if (rawLinks is List) {
      final Map<String, String> parsed = {};
      for (final item in rawLinks) {
        if (item is Map<String, dynamic>) {
          final platform =
              (item['platform'] ?? '').toString().trim().toLowerCase();
          final url = (item['url'] ?? '').toString().trim();
          if (platform.isNotEmpty && url.isNotEmpty) {
            parsed[platform] = url;
          }
        }
      }
      return parsed;
    }

    return {};
  }
}
