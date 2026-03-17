import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/auth/data/dto/auth_response_dto.dart';
import 'package:soundcloud_clone/features/auth/data/dto/user_dto.dart';

void main() {
  group('AuthResponseDto', () {
    test('fromJson returns valid dto when json is complete', () {
      final json = {
        'token': 'token_123',
        'user': {
          'id': '1',
          'email': 'test@example.com',
          'display_name': 'Muslim',
          'birth_month': 5,
          'birth_day': 15,
          'birth_year': 2000,
          'gender': 'Male',
        },
      };

      final result = AuthResponseDto.fromJson(json);

      expect(result, isA<AuthResponseDto>());
      expect(result.token, 'token_123');
      expect(result.user, isA<UserDto>());
      expect(result.user.id, '1');
      expect(result.user.email, 'test@example.com');
      expect(result.user.displayName, 'Muslim');
      expect(result.user.gender, 'Male');
    });

    test('fromJson returns empty token when token is missing', () {
      final json = {
        'user': {
          'id': '1',
          'email': 'test@example.com',
          'display_name': 'Muslim',
          'gender': 'Male',
        },
      };

      final result = AuthResponseDto.fromJson(json);

      expect(result.token, '');
      expect(result.user.id, '1');
      expect(result.user.email, 'test@example.com');
    });

    test('fromJson returns default user values when user is missing', () {
      final json = {
        'token': 'token_123',
      };

      final result = AuthResponseDto.fromJson(json);

      expect(result.token, 'token_123');
      expect(result.user, isA<UserDto>());
    });

    test('fromJson returns safe defaults when json is empty', () {
      final result = AuthResponseDto.fromJson({});

      expect(result.token, '');
      expect(result.user, isA<UserDto>());
    });
  });
}