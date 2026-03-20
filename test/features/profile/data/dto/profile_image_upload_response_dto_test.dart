import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/profile/data/dto/ProfileImageUploadResponseDto.dart';
import 'package:soundcloud_clone/features/profile/domain/entities/ProfileImageUploadResult.dart';

void main() {
  group('ProfileImageUploadResponseDto', () {
    test('fromJson maps values correctly', () {
      final dto = ProfileImageUploadResponseDto.fromJson(
        {
          'url': 'https://cdn.example.com/avatar.jpg',
          'key': 'avatar-key',
        },
      );

      expect(dto.url, 'https://cdn.example.com/avatar.jpg');
      expect(dto.key, 'avatar-key');
    });

    test('fromJson falls back to empty strings for missing values', () {
      final dto = ProfileImageUploadResponseDto.fromJson(
        <String, dynamic>{},
      );

      expect(dto.url, '');
      expect(dto.key, '');
    });

    test('toEntity maps dto to ProfileImageUploadResult', () {
      const dto = ProfileImageUploadResponseDto(
        url: 'https://cdn.example.com/cover.jpg',
        key: 'cover-key',
      );

      final result = dto.toEntity(ProfileImageType.cover);

      expect(
        result,
        const ProfileImageUploadResult(
          type: ProfileImageType.cover,
          url: 'https://cdn.example.com/cover.jpg',
          key: 'cover-key',
        ),
      );
    });
  });
}
