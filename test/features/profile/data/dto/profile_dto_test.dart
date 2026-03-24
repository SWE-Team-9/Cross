import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/profile/data/dto/profile_dto.dart';
import 'package:soundcloud_clone/features/profile/domain/entities/profile_entity.dart';

void main() {
  group('ProfileDto.fromJson', () {
    test('parses snake_case API response correctly', () {
      final json = <String, dynamic>{
        'id': 'user-1',
        'handle': 'eyad',
        'display_name': 'Eyad',
        'bio': 'Artist bio',
        'location': 'Cairo, Egypt',
        'avatar_url': 'https://cdn.example.com/avatar.png',
        'cover_photo_url': 'https://cdn.example.com/cover.png',
        'account_type': 'ARTIST',
        'favorite_genres': ['rock', 'pop'],
        'social_links': <String, dynamic>{
          'twitter': 'https://x.com/eyad',
        },
        'visibility': 'PRIVATE',
        'track_count': 12,
        'followers_count': 100,
        'following_count': 80,
      };

      final dto = ProfileDto.fromJson(json);

      expect(dto.id, 'user-1');
      expect(dto.handle, 'eyad');
      expect(dto.displayName, 'Eyad');
      expect(dto.bio, 'Artist bio');
      expect(dto.location, 'Cairo, Egypt');
      expect(dto.avatarUrl, 'https://cdn.example.com/avatar.png');
      expect(dto.coverPhotoUrl, 'https://cdn.example.com/cover.png');
      expect(dto.accountType, 'ARTIST');
      expect(dto.favoriteGenres, ['rock', 'pop']);
      expect(dto.socialLinks['twitter'], 'https://x.com/eyad');
      expect(dto.visibility, 'PRIVATE');
      expect(dto.trackCount, 12);
      expect(dto.followersCount, 100);
      expect(dto.followingCount, 80);
    });

    test('parses camelCase API response correctly', () {
      final json = <String, dynamic>{
        'userId': 'user-2',
        'handle': 'ali',
        'displayName': 'Ali',
        'bio': 'Flutter dev',
        'location': 'Giza, Egypt',
        'avatarUrl': 'https://cdn.example.com/avatar2.png',
        'coverPhotoUrl': 'https://cdn.example.com/cover2.png',
        'accountType': 'LISTENER',
        'favoriteGenres': ['electronic'],
        'socialLinks': <String, dynamic>{
          'github': 'https://github.com/ali',
        },
        'visibility': 'PUBLIC',
        'trackCount': 3,
        'followersCount': 10,
        'followingCount': 20,
      };

      final dto = ProfileDto.fromJson(json);

      expect(dto.id, 'user-2');
      expect(dto.handle, 'ali');
      expect(dto.displayName, 'Ali');
      expect(dto.bio, 'Flutter dev');
      expect(dto.location, 'Giza, Egypt');
      expect(dto.avatarUrl, 'https://cdn.example.com/avatar2.png');
      expect(dto.coverPhotoUrl, 'https://cdn.example.com/cover2.png');
      expect(dto.accountType, 'LISTENER');
      expect(dto.favoriteGenres, ['electronic']);
      expect(dto.socialLinks['github'], 'https://github.com/ali');
      expect(dto.visibility, 'PUBLIC');
      expect(dto.trackCount, 3);
      expect(dto.followersCount, 10);
      expect(dto.followingCount, 20);
    });

    test('handles social_links as list by converting to empty map', () {
      final json = <String, dynamic>{
        'handle': 'eyad',
        'display_name': 'Eyad',
        'account_type': 'LISTENER',
        'favorite_genres': [],
        'social_links': [],
      };

      final dto = ProfileDto.fromJson(json);

      expect(dto.socialLinks, isEmpty);
    });

    test('maps genre objects to slug when favorite_genres contains maps', () {
      final json = <String, dynamic>{
        'handle': 'eyad',
        'display_name': 'Eyad',
        'account_type': 'ARTIST',
        'favorite_genres': [
          {'slug': 'rock', 'name': 'Rock'},
          {'slug': 'pop', 'name': 'Pop'},
        ],
        'social_links': <String, dynamic>{},
      };

      final dto = ProfileDto.fromJson(json);

      expect(dto.favoriteGenres, ['rock', 'pop']);
    });

    test('falls back to name when slug is missing in genre maps', () {
      final json = <String, dynamic>{
        'handle': 'eyad',
        'display_name': 'Eyad',
        'account_type': 'ARTIST',
        'favorite_genres': [
          {'name': 'Rock'},
        ],
        'social_links': <String, dynamic>{},
      };

      final dto = ProfileDto.fromJson(json);

      expect(dto.favoriteGenres, ['Rock']);
    });

    test('uses defaults when optional fields are missing', () {
      final json = <String, dynamic>{};

      final dto = ProfileDto.fromJson(json);

      expect(dto.id, isNull);
      expect(dto.handle, '');
      expect(dto.displayName, '');
      expect(dto.bio, isNull);
      expect(dto.location, isNull);
      expect(dto.avatarUrl, isNull);
      expect(dto.coverPhotoUrl, isNull);
      expect(dto.accountType, 'LISTENER');
      expect(dto.favoriteGenres, isEmpty);
      expect(dto.socialLinks, isEmpty);
      expect(dto.visibility, 'PUBLIC');
      expect(dto.trackCount, 0);
      expect(dto.followersCount, isNull);
      expect(dto.followingCount, isNull);
    });
  });

  group('ProfileDto.toEntity', () {
    test(
        'maps ARTIST account type to AccountTier.artist and PRIVATE visibility',
        () {
      const dto = ProfileDto(
        id: 'user-1',
        displayName: 'Eyad',
        handle: 'eyad',
        bio: 'Artist bio',
        location: 'Cairo, Egypt',
        avatarUrl: 'https://cdn.example.com/avatar.png',
        coverPhotoUrl: 'https://cdn.example.com/cover.png',
        accountType: 'ARTIST',
        favoriteGenres: ['rock'],
        socialLinks: {'twitter': 'https://x.com/eyad'},
        visibility: 'PRIVATE',
        trackCount: 9,
        followersCount: 14,
        followingCount: 20,
      );

      final entity = dto.toEntity();

      expect(entity.id, 'user-1');
      expect(entity.displayName, 'Eyad');
      expect(entity.handle, 'eyad');
      expect(entity.bio, 'Artist bio');
      expect(entity.location, 'Cairo, Egypt');
      expect(entity.avatarUrl, 'https://cdn.example.com/avatar.png');
      expect(entity.coverPhotoUrl, 'https://cdn.example.com/cover.png');
      expect(entity.accountTier, AccountTier.ARTIST);
      expect(entity.favoriteGenres, ['rock']);
      expect(entity.externalLinks['twitter'], 'https://x.com/eyad');
      expect(entity.visibility, ProfileVisibility.PRIVATE);
      expect(entity.followersCount, 14);
      expect(entity.followingCount, 20);
    });

    test(
        'maps non-ARTIST account type to AccountTier.listener and PUBLIC visibility',
        () {
      const dto = ProfileDto(
        id: 'user-2',
        displayName: 'Ali',
        handle: 'ali',
        accountType: 'LISTENER',
        favoriteGenres: [],
        socialLinks: {},
        visibility: 'PUBLIC',
        trackCount: 0,
      );

      final entity = dto.toEntity();

      expect(entity.accountTier, AccountTier.LISTENER);
      expect(entity.visibility, ProfileVisibility.PUBLIC);
      expect(entity.followersCount, 0);
      expect(entity.followingCount, 0);
    });

    test('uses handle as fallback id when dto id is null', () {
      const dto = ProfileDto(
        displayName: 'Ali',
        handle: 'ali',
        accountType: 'LISTENER',
        favoriteGenres: [],
        socialLinks: {},
        visibility: 'PUBLIC',
        trackCount: 0,
      );

      final entity = dto.toEntity();

      expect(entity.id, 'ali');
    });
  });
}
