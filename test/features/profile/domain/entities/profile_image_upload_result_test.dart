import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/profile/domain/entities/ProfileImageUploadResult.dart';

void main() {
  group('ProfileImageTypeX', () {
    test('avatar properties are correct', () {
      expect(ProfileImageType.avatar.displayName, 'Avatar');
      expect(ProfileImageType.avatar.endpointSegment, 'avatar');
      expect(ProfileImageType.avatar.maxFileSizeInBytes, 5 * 1024 * 1024);
      expect(ProfileImageType.avatar.cropAspectRatio, 1.0);
    });

    test('cover properties are correct', () {
      expect(ProfileImageType.cover.displayName, 'Cover');
      expect(ProfileImageType.cover.endpointSegment, 'cover');
      expect(ProfileImageType.cover.maxFileSizeInBytes, 15 * 1024 * 1024);
      expect(ProfileImageType.cover.cropAspectRatio, closeTo(16 / 9, 0.0001));
    });
  });

  group('ProfileImageUploadResult', () {
    test('supports value equality', () {
      const first = ProfileImageUploadResult(
        type: ProfileImageType.avatar,
        url: 'https://cdn.example.com/avatar.jpg',
        key: 'avatar-key',
      );

      const second = ProfileImageUploadResult(
        type: ProfileImageType.avatar,
        url: 'https://cdn.example.com/avatar.jpg',
        key: 'avatar-key',
      );

      expect(first, second);
    });

    test('props contain all expected values', () {
      const result = ProfileImageUploadResult(
        type: ProfileImageType.cover,
        url: 'https://cdn.example.com/cover.jpg',
        key: 'cover-key',
      );

      expect(result.type, ProfileImageType.cover);
      expect(result.url, 'https://cdn.example.com/cover.jpg');
      expect(result.key, 'cover-key');
    });
  });
}
