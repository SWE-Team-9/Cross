import 'package:soundcloud_clone/features/profile/domain/entities/profile_entity.dart';

/// A fully populated ProfileEntity for use across all profile tests.
final tProfileEntity = ProfileEntity(
  id: 'user-uuid-123',
  displayName: 'Ahmed Hassan',
  handle: 'ahmed-hassan-beats',
  bio: 'Indie producer from Cairo.',
  location: 'Cairo, Egypt',
  avatarUrl: 'https://s3.aws.com/ahmed-avatar.jpg',
  coverPhotoUrl: 'https://s3.aws.com/ahmed-cover.jpg',
  accountTier: AccountTier.ARTIST,
  favoriteGenres: ['Oriental', 'Electronic'],
  externalLinks: {'instagram': '@ahmed_hassan_music'},
  visibility: ProfileVisibility.PUBLIC,
);

/// Raw JSON that the API returns for GET /api/v1/profiles/:handle.
final tProfileJson = <String, dynamic>{
  'id': 'user-uuid-123',
  'display_name': 'Ahmed Hassan',
  'handle': 'ahmed-hassan-beats',
  'bio': 'Indie producer from Cairo.',
  'location': 'Cairo, Egypt',
  'avatar_url': 'https://s3.aws.com/ahmed-avatar.jpg',
  'cover_photo_url': 'https://s3.aws.com/ahmed-cover.jpg',
  'account_tier': 'ARTIST',
  'favorite_genres': ['Oriental', 'Electronic'],
  'external_links': {'instagram': '@ahmed_hassan_music'},
  'visibility': 'PUBLIC',
};
