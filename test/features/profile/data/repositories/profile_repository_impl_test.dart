import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:soundcloud_clone/features/profile/data/dto/profile_dto.dart';
import 'package:soundcloud_clone/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:soundcloud_clone/features/profile/domain/entities/profile_entity.dart';
import '../../helpers/profile_test_fixtures.dart';
import 'package:soundcloud_clone/features/profile/domain/repositories/profile_repository.dart';

class MockProfileRemoteDataSource extends Mock
    implements ProfileRemoteDataSource {}

void main() {
  late MockProfileRemoteDataSource mockRemoteDataSource;
  late ProfileRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockProfileRemoteDataSource();
    repository = ProfileRepositoryImpl(mockRemoteDataSource);
  });

  group('getProfile', () {
    test('returns ProfileEntity from remote dto', () async {
      final dto = ProfileDto.fromJson(<String, dynamic>{
        'id': 'user-uuid-123',
        'display_name': 'Ahmed Hassan',
        'handle': 'ahmed-hassan-beats',
        'bio': 'Indie producer from Cairo.',
        'location': 'Cairo, Egypt',
        'avatar_url': 'https://s3.aws.com/ahmed-avatar.jpg',
        'cover_photo_url': 'https://s3.aws.com/ahmed-cover.jpg',
        'account_type': 'ARTIST',
        'favorite_genres': ['Oriental', 'Electronic'],
        'social_links': <String, dynamic>{
          'instagram': '@ahmed_hassan_music',
        },
        'visibility': 'PUBLIC',
        'track_count': 0,
        'followers_count': 123,
        'following_count': 456,
      });

      when(() => mockRemoteDataSource.getProfile('ahmed-hassan-beats'))
          .thenAnswer((_) async => dto);

      final result = await repository.getProfile('ahmed-hassan-beats');

      expect(result.id, tProfileEntity.id);
      expect(result.displayName, tProfileEntity.displayName);
      expect(result.handle, tProfileEntity.handle);
      expect(result.bio, tProfileEntity.bio);
      expect(result.location, tProfileEntity.location);
      expect(result.avatarUrl, tProfileEntity.avatarUrl);
      expect(result.coverPhotoUrl, tProfileEntity.coverPhotoUrl);
      expect(result.accountTier, AccountTier.ARTIST);
      expect(result.favoriteGenres, tProfileEntity.favoriteGenres);
      expect(result.externalLinks, tProfileEntity.externalLinks);
      expect(result.visibility, ProfileVisibility.PUBLIC);
      expect(result.followersCount, 123);
      expect(result.followingCount, 456);

      verify(() => mockRemoteDataSource.getProfile('ahmed-hassan-beats'))
          .called(1);
    });
  });

  group('updateProfile', () {
    test('builds partial body with only provided fields', () async {
      final dto = ProfileDto.fromJson(<String, dynamic>{
        'id': 'user-uuid-123',
        'display_name': 'Ahmed Official',
        'handle': 'ahmed-hassan-beats',
        'bio': 'New bio',
        'location': 'Giza, Egypt',
        'avatar_url': 'https://s3.aws.com/ahmed-avatar.jpg',
        'cover_photo_url': 'https://s3.aws.com/ahmed-cover.jpg',
        'account_type': 'ARTIST',
        'favorite_genres': ['Electronic'],
        'social_links': <String, dynamic>{},
        'visibility': 'PRIVATE',
        'track_count': 0,
      });

      when(() => mockRemoteDataSource.updateProfile(any()))
          .thenAnswer((_) async => dto);

      final result = await repository.updateProfile(
        displayName: 'Ahmed Official',
        bio: 'New bio',
        location: 'Giza, Egypt',
        favoriteGenres: const ['Electronic'],
        visibility: ProfileVisibility.PRIVATE,
      );

      expect(result.displayName, 'Ahmed Official');
      expect(result.bio, 'New bio');
      expect(result.location, 'Giza, Egypt');
      expect(result.favoriteGenres, const ['Electronic']);
      expect(result.visibility, ProfileVisibility.PRIVATE);

      verify(
        () => mockRemoteDataSource.updateProfile(<String, dynamic>{
          'display_name': 'Ahmed Official',
          'bio': 'New bio',
          'location': 'Giza, Egypt',
          'favorite_genres': const ['Electronic'],
          'visibility': 'PRIVATE',
        }),
      ).called(1);
    });

    test('passes empty body when no optional fields are provided', () async {
      final dto = ProfileDto.fromJson(<String, dynamic>{
        'id': 'user-uuid-123',
        'display_name': 'Ahmed Hassan',
        'handle': 'ahmed-hassan-beats',
        'account_type': 'LISTENER',
        'favorite_genres': <String>[],
        'social_links': <String, dynamic>{},
        'visibility': 'PUBLIC',
        'track_count': 0,
      });

      when(() => mockRemoteDataSource.updateProfile(any()))
          .thenAnswer((_) async => dto);

      await repository.updateProfile();

      verify(
        () => mockRemoteDataSource.updateProfile(<String, dynamic>{}),
      ).called(1);
    });

    test('maps public visibility correctly', () async {
      final dto = ProfileDto.fromJson(<String, dynamic>{
        'id': 'user-uuid-123',
        'display_name': 'Ahmed Hassan',
        'handle': 'ahmed-hassan-beats',
        'account_type': 'LISTENER',
        'favorite_genres': <String>[],
        'social_links': <String, dynamic>{},
        'visibility': 'PUBLIC',
        'track_count': 0,
      });

      when(() => mockRemoteDataSource.updateProfile(any()))
          .thenAnswer((_) async => dto);

      await repository.updateProfile(
        visibility: ProfileVisibility.PUBLIC,
      );

      verify(
        () => mockRemoteDataSource.updateProfile(<String, dynamic>{
          'visibility': 'PUBLIC',
        }),
      ).called(1);
    });
  });

  group('uploadProfileImage', () {
    test('delegates avatar upload to remote datasource', () async {
      when(
        () => mockRemoteDataSource.uploadProfileImage(
          imageType: ProfileImageType.AVATAR,
          filePath: '/tmp/avatar.png',
        ),
      ).thenAnswer((_) async => 'https://cdn.example.com/avatar.png');

      final result = await repository.uploadProfileImage(
        imageType: ProfileImageType.AVATAR,
        filePath: '/tmp/avatar.png',
      );

      expect(result, 'https://cdn.example.com/avatar.png');
      verify(
        () => mockRemoteDataSource.uploadProfileImage(
          imageType: ProfileImageType.AVATAR,
          filePath: '/tmp/avatar.png',
        ),
      ).called(1);
    });
  });

  group('checkHandleAvailable', () {
    test('delegates handle availability check to remote datasource', () async {
      when(() => mockRemoteDataSource.checkHandleAvailable('ali-mahmoud'))
          .thenAnswer((_) async => true);

      final result = await repository.checkHandleAvailable('ali-mahmoud');

      expect(result, isTrue);
      verify(() => mockRemoteDataSource.checkHandleAvailable('ali-mahmoud'))
          .called(1);
    });
  });
}
