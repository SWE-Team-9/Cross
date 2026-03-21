import 'package:flutter_test/flutter_test.dart';

// Third-party
// Project
import 'package:soundcloud_clone/features/profile/domain/entities/profile_entity.dart';
import '../../helpers/profile_test_fixtures.dart';

void main() {
  group('ProfileEntity', () {
    group('copyWith', () {
      test(
        'returns identical entity when no fields are provided',
        () {
          // arrange
          final entity = tProfileEntity;

          // act
          final result = entity.copyWith();

          // assert
          // Every field should be the same as the original
          expect(result.id, entity.id);
          expect(result.displayName, entity.displayName);
          expect(result.handle, entity.handle);
          expect(result.bio, entity.bio);
          expect(result.location, entity.location);
          expect(result.avatarUrl, entity.avatarUrl);
          expect(result.coverPhotoUrl, entity.coverPhotoUrl);
          expect(result.accountTier, entity.accountTier);
          expect(result.favoriteGenres, entity.favoriteGenres);
          expect(result.externalLinks, entity.externalLinks);
          expect(result.visibility, entity.visibility);
        },
      );

      test(
        'replaces only displayName when only displayName is provided',
        () {
          // arrange
          const newName = 'Ahmed Hassan Official';

          // act
          final result = tProfileEntity.copyWith(displayName: newName);

          // assert
          expect(result.displayName, newName);
          // Everything else must be untouched
          expect(result.id, tProfileEntity.id);
          expect(result.handle, tProfileEntity.handle);
          expect(result.bio, tProfileEntity.bio);
          expect(result.location, tProfileEntity.location);
          expect(result.avatarUrl, tProfileEntity.avatarUrl);
        },
      );

      test(
        'replaces only avatarUrl when only avatarUrl is provided',
        () {
          // arrange
          const newUrl = 'https://s3.aws.com/new-avatar.jpg';

          // act
          final result = tProfileEntity.copyWith(avatarUrl: newUrl);

          // assert
          expect(result.avatarUrl, newUrl);
          // Cover photo must be untouched
          expect(result.coverPhotoUrl, tProfileEntity.coverPhotoUrl);
          expect(result.displayName, tProfileEntity.displayName);
        },
      );

      test(
        'replaces only coverPhotoUrl when only coverPhotoUrl is provided',
        () {
          // arrange
          const newUrl = 'https://s3.aws.com/new-cover.jpg';

          // act
          final result = tProfileEntity.copyWith(coverPhotoUrl: newUrl);

          // assert
          expect(result.coverPhotoUrl, newUrl);
          // Avatar must be untouched
          expect(result.avatarUrl, tProfileEntity.avatarUrl);
        },
      );

      test(
        'replaces visibility when visibility is provided',
        () {
          // act
          final result = tProfileEntity.copyWith(
            visibility: ProfileVisibility.PRIVATE,
          );

          // assert
          expect(result.visibility, ProfileVisibility.PRIVATE);
          // Original was PUBLIC — make sure it actually changed
          expect(tProfileEntity.visibility, ProfileVisibility.PUBLIC);
        },
      );

      test(
        'id and handle are never changed by copyWith',
        () {
          // act — try to change multiple fields but id/handle have no param
          final result = tProfileEntity.copyWith(
            displayName: 'New Name',
            bio: 'New bio',
          );

          // assert — identifiers are immutable
          expect(result.id, tProfileEntity.id);
          expect(result.handle, tProfileEntity.handle);
        },
      );

      test(
        'replaces favoriteGenres list correctly',
        () {
          // arrange
          final newGenres = ['Lo-Fi', 'Jazz'];

          // act
          final result = tProfileEntity.copyWith(favoriteGenres: newGenres);

          // assert
          expect(result.favoriteGenres, ['Lo-Fi', 'Jazz']);
          expect(result.favoriteGenres.length, 2);
        },
      );
    });
  });
}
