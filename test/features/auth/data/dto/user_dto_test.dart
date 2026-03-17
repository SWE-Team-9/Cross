import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/auth/data/dto/user_dto.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';

void main() {
  group('UserDto', () {
    test('fromJson returns valid dto when json is complete', () {
      final json = {
        'id': 1,
        'email': 'test@example.com',
        'username': 'muslim',
        'display_name': 'Muslim',
        'avatar_url': 'https://example.com/avatar.png',
        'bio': 'Hello world',
        'gender': 'Male',
        'date_of_birth': '2000-05-15T00:00:00.000',
        'is_pro': true,
        'is_profile_completed': true,
      };

      final result = UserDto.fromJson(json);

      expect(result.id, '1');
      expect(result.email, 'test@example.com');
      expect(result.username, 'muslim');
      expect(result.displayName, 'Muslim');
      expect(result.avatarUrl, 'https://example.com/avatar.png');
      expect(result.bio, 'Hello world');
      expect(result.gender, 'Male');
      expect(result.dateOfBirth, DateTime.parse('2000-05-15T00:00:00.000'));
      expect(result.isPro, true);
      expect(result.isProfileCompleted, true);
    });

    test('fromJson returns safe defaults when optional fields are missing', () {
      final json = {
        'id': '2',
        'email': 'test2@example.com',
      };

      final result = UserDto.fromJson(json);

      expect(result.id, '2');
      expect(result.email, 'test2@example.com');
      expect(result.username, isNull);
      expect(result.displayName, isNull);
      expect(result.avatarUrl, isNull);
      expect(result.bio, isNull);
      expect(result.gender, isNull);
      expect(result.dateOfBirth, isNull);
      expect(result.isPro, false);
      expect(result.isProfileCompleted, false);
    });

    test('fromJson returns null dateOfBirth when date is invalid', () {
      final json = {
        'id': '3',
        'email': 'test3@example.com',
        'date_of_birth': 'invalid-date',
      };

      final result = UserDto.fromJson(json);

      expect(result.dateOfBirth, isNull);
    });

    test('toEntity maps dto to User entity correctly', () {
      final dto = UserDto(
        id: '1',
        email: 'test@example.com',
        username: 'muslim',
        displayName: 'Muslim',
        avatarUrl: 'https://example.com/avatar.png',
        bio: 'Hello world',
        gender: 'Male',
        dateOfBirth: DateTime.parse('2000-05-15T00:00:00.000'),
        isPro: true,
        isProfileCompleted: true,
      );

      final result = dto.toEntity();

      expect(result, isA<User>());
      expect(result.id, '1');
      expect(result.email, 'test@example.com');
      expect(result.username, 'muslim');
      expect(result.displayName, 'Muslim');
      expect(result.avatarUrl, 'https://example.com/avatar.png');
      expect(result.bio, 'Hello world');
      expect(result.gender, 'Male');
      expect(result.dateOfBirth, DateTime.parse('2000-05-15T00:00:00.000'));
      expect(result.isPro, true);
      expect(result.isProfileCompleted, true);
    });
  });
}
