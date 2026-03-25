import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/auth/data/dto/auth_response_dto.dart';
import 'package:soundcloud_clone/features/auth/data/dto/user_dto.dart';

void main() {
  group('AuthResponseDto', () {
    test('fromJson returns valid dto when json is complete', () {
      // Arrange
      final json = {
        'access_token': 'access_123',
        'refresh_token': 'refresh_456',
        'user': {
          'id': '1',
          'email': 'test@example.com',
          'handle': 'muslim',
          'display_name': 'Test User',
          'gender': 'MALE',
          'date_of_birth': '2000-01-01',
        },
      };

      // Act
      final result = AuthResponseDto.fromJson(json);

      // Assert
      expect(result, isA<AuthResponseDto>());
      expect(result.accessToken, 'access_123');
      expect(result.refreshToken, 'refresh_456');
      expect(result.user, isA<UserDto>());
      expect(result.user.id, '1');
      expect(result.user.email, 'test@example.com');
      expect(result.user.handle, 'muslim');
    });

    test('fromJson returns empty tokens when tokens are missing', () {
      // Arrange
      final json = {
        'user': {
          'id': '1',
          'email': 'test@example.com',
          'handle': 'muslim',
          'display_name': 'Test User',
        },
      };

      // Act
      final result = AuthResponseDto.fromJson(json);

      // Assert
      expect(result.accessToken, '');
      expect(result.refreshToken, '');
      expect(result.user.id, '1');
    });

    test('fromJson returns safe defaults when json is empty', () {
      // Act
      final result = AuthResponseDto.fromJson({});

      // Assert
      expect(result.accessToken, '');
      expect(result.refreshToken, '');
      expect(result.user, isA<UserDto>());
    });
  });
}
