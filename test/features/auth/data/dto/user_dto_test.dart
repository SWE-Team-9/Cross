import 'package:flutter_test/flutter_test.dart';

// Third-party
// Project
import 'package:soundcloud_clone/features/auth/data/dto/user_dto.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';

void main() {
  group('UserDto', () {
    final tFullJson = <String, dynamic>{
      'id': 'user-uuid-123',
      'email': 'ahmed@test.com',
      'username': 'ahmed123',
      'display_name': 'Ahmed Hassan',
      'handle': 'ahmed-hassan-beats',
      'avatar_url': 'https://s3.aws.com/ahmed-avatar.jpg',
      'bio': 'Producer from Cairo',
      'gender': 'MALE',
      'date_of_birth': '2000-01-15',
      'is_pro': true,
      'is_profile_completed': true,
    };

    group('fromJson', () {
      test('parses all fields correctly from a full JSON response', () {
        final dto = UserDto.fromJson(tFullJson);

        expect(dto.id, 'user-uuid-123');
        expect(dto.email, 'ahmed@test.com');
        expect(dto.username, 'ahmed123');
        expect(dto.displayName, 'Ahmed Hassan');
        expect(dto.handle, 'ahmed-hassan-beats');
        expect(dto.avatarUrl, 'https://s3.aws.com/ahmed-avatar.jpg');
        expect(dto.bio, 'Producer from Cairo');
        expect(dto.gender, 'MALE');
        expect(dto.isPro, isTrue);
        expect(dto.isProfileCompleted, isTrue);
      });

      test('uses handle field when present in JSON', () {
        final json = Map<String, dynamic>.from(tFullJson)
          ..['handle'] = 'ahmed-hassan-beats'
          ..['username'] = 'ahmed123';

        final dto = UserDto.fromJson(json);

        expect(dto.handle, 'ahmed-hassan-beats');
      });

      test('falls back to username when handle is absent from JSON', () {
        final json = Map<String, dynamic>.from(tFullJson)
          ..remove('handle')
          ..['username'] = 'ahmed123';

        final dto = UserDto.fromJson(json);

        expect(dto.handle, 'ahmed123');
      });

      test('handle is empty string when both handle and username are absent',
          () {
        final json = Map<String, dynamic>.from(tFullJson)
          ..remove('handle')
          ..remove('username');

        final dto = UserDto.fromJson(json);

        expect(dto.handle, '');
      });

      test('sets optional fields to null when absent from JSON', () {
        final json = <String, dynamic>{
          'id': 'user-uuid-123',
          'email': 'ahmed@test.com',
          'handle': 'ahmed-hassan-beats',
        };

        final dto = UserDto.fromJson(json);

        expect(dto.username, isNull);
        expect(dto.displayName, isNull);
        expect(dto.avatarUrl, isNull);
        expect(dto.bio, isNull);
        expect(dto.gender, isNull);
        expect(dto.dateOfBirth, isNull);
      });

      test('defaults isPro to false when absent from JSON', () {
        final json = Map<String, dynamic>.from(tFullJson)..remove('is_pro');

        final dto = UserDto.fromJson(json);

        expect(dto.isPro, isFalse);
      });

      test('defaults isProfileCompleted to false when absent from JSON', () {
        final json = Map<String, dynamic>.from(tFullJson)
          ..remove('is_profile_completed');

        final dto = UserDto.fromJson(json);

        expect(dto.isProfileCompleted, isFalse);
      });

      test('parses dateOfBirth as DateTime when present', () {
        final dto = UserDto.fromJson(tFullJson);

        expect(dto.dateOfBirth, isA<DateTime>());
        expect(dto.dateOfBirth?.year, 2000);
        expect(dto.dateOfBirth?.month, 1);
        expect(dto.dateOfBirth?.day, 15);
      });

      test('sets dateOfBirth to null when date_of_birth is null in JSON', () {
        final json = Map<String, dynamic>.from(tFullJson)
          ..['date_of_birth'] = null;

        final dto = UserDto.fromJson(json);

        expect(dto.dateOfBirth, isNull);
      });
    });

    group('toEntity', () {
      test('converts UserDto to User with all fields preserved', () {
        final dto = UserDto.fromJson(tFullJson);

        final user = dto.toEntity();

        expect(user, isA<User>());
        expect(user.id, dto.id);
        expect(user.email, dto.email);
        expect(user.handle, dto.handle);
        expect(user.displayName, dto.displayName);
        expect(user.avatarUrl, dto.avatarUrl);
        expect(user.isPro, dto.isPro);
        expect(user.isProfileCompleted, dto.isProfileCompleted);
      });

      test('handle is preserved correctly through toEntity()', () {
        final dto = UserDto.fromJson(tFullJson);

        final user = dto.toEntity();

        expect(user.handle, 'ahmed-hassan-beats');
      });
    });
  });
}
