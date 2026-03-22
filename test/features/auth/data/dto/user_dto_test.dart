import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/auth/data/dto/user_dto.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';

void main() {
  group('UserDto', () {
    test('fromJson returns valid dto when json is complete', () {
      // Arrange
      final json = {
        'id': 1,
        'email': 'test@example.com',
        'username': 'muslim',
        'display_name': 'Muslim',
        'avatar_url': 'https://example.com/avatar.png',
        'bio': 'Hello world',
        'gender': 'MALE',
        'date_of_birth': '2000-05-15',
        'is_pro': true,
        'is_verified': true,
      };

      // Act
      final result = UserDto.fromJson(json);

      // Assert
      expect(result.id, '1');
      expect(result.email, 'test@example.com');
      expect(result.username, 'muslim');
      expect(result.displayName, 'Muslim');
      expect(result.gender, 'MALE');
      expect(result.dateOfBirth, '2000-05-15');
      expect(result.isPro, true);
      expect(result.isVerified, true);
    });

    test('fromJson returns safe defaults when optional fields are missing', () {
      // Arrange
      final json = {
        'id': '2',
        'email': 'test2@example.com',
        // is_verified is required in constructor but safe in fromJson
      };

      // Act
      final result = UserDto.fromJson(json);

      // Assert
      expect(result.id, '2');
      expect(result.email, 'test2@example.com');
      expect(result.username, isNull);
      expect(result.isVerified, false); // Default from json parsing
      expect(result.isPro, false);
    });

    test('toEntity maps dto to User entity correctly', () {
      // Arrange
      const dto = UserDto(
        id: '1',
        email: 'test@example.com',
        username: 'muslim',
        displayName: 'Muslim',
        avatarUrl: 'https://example.com/avatar.png',
        bio: 'Hello world',
        gender: 'MALE',
        dateOfBirth: '2000-05-15',
        isPro: true,
        isVerified: true,
      );

      // Act
      final result = dto.toEntity();

      // Assert
      expect(result, isA<User>());
      expect(result.id, '1');
      expect(result.email, 'test@example.com');
      expect(result.isVerified, true);
      // التحقق من تحويل التاريخ من String إلى DateTime في الـ Entity
      expect(result.dateOfBirth, DateTime.parse('2000-05-15'));
    });

    test('toEntity handles null dateOfBirth gracefully', () {
      // Arrange
      const dto = UserDto(
        id: '1',
        email: 'test@example.com',
        isVerified: false,
        dateOfBirth: null,
      );

      // Act
      final result = dto.toEntity();

      // Assert
      expect(result.dateOfBirth, isNull);
    });
  });
}
