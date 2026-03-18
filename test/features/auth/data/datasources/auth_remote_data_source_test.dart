import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:soundcloud_clone/features/auth/data/dto/auth_response_dto.dart';
import 'package:soundcloud_clone/features/auth/data/dto/user_dto.dart';

class MockDioClient extends Mock implements DioClient {}

class MockDio extends Mock implements Dio {}

void main() {
  late MockDioClient mockDioClient;
  late MockDio mockDio;
  late AuthRemoteDataSourceImpl dataSource;

  setUp(() {
    mockDioClient = MockDioClient();
    mockDio = MockDio();

    when(() => mockDioClient.dio).thenReturn(mockDio);

    dataSource = AuthRemoteDataSourceImpl(mockDioClient);
  });

  group('checkEmailExists', () {
    test('returns exists value from response dto', () async {
      when(() => mockDio.post(
            '/auth/check-email',
            data: {
              'email': 'test@example.com',
            },
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/auth/check-email'),
          data: {
            'exists': true,
          },
        ),
      );

      final result = await dataSource.checkEmailExists(
        email: 'test@example.com',
      );

      expect(result, true);
      verify(() => mockDio.post(
            '/auth/check-email',
            data: {
              'email': 'test@example.com',
            },
          )).called(1);
    });
  });

  group('login', () {
    test('returns AuthResponseDto from API response', () async {
      when(() => mockDio.post(
            '/auth/login',
            data: {
              'email': 'test@example.com',
              'password': '12345678',
            },
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          data: {
            'token': 'token_123',
            'user': {
              'id': '1',
              'email': 'test@example.com',
              'username': 'muslim',
              'display_name': 'Muslim',
              'avatar_url': 'https://example.com/avatar.png',
              'bio': 'Hello world',
              'gender': 'Male',
              'date_of_birth': '2000-05-15T00:00:00.000',
              'is_pro': true,
              'is_profile_completed': true,
            },
          },
        ),
      );

      final result = await dataSource.login(
        email: 'test@example.com',
        password: '12345678',
      );

      expect(result, isA<AuthResponseDto>());
      expect(result.token, 'token_123');
      expect(result.user, isA<UserDto>());
      expect(result.user.id, '1');
      expect(result.user.email, 'test@example.com');
      verify(() => mockDio.post(
            '/auth/login',
            data: {
              'email': 'test@example.com',
              'password': '12345678',
            },
          )).called(1);
    });
  });

  group('register', () {
    test('returns AuthResponseDto from API response', () async {
      when(() => mockDio.post(
            '/auth/register',
            data: {
              'email': 'new@example.com',
              'password': '12345678',
            },
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/auth/register'),
          data: {
            'token': 'register_token',
            'user': {
              'id': '2',
              'email': 'new@example.com',
              'username': 'new_user',
              'display_name': 'New User',
              'avatar_url': null,
              'bio': null,
              'gender': 'Female',
              'date_of_birth': '1999-06-20T00:00:00.000',
              'is_pro': false,
              'is_profile_completed': false,
            },
          },
        ),
      );

      final result = await dataSource.register(
        email: 'new@example.com',
        password: '12345678',
      );

      expect(result, isA<AuthResponseDto>());
      expect(result.token, 'register_token');
      expect(result.user, isA<UserDto>());
      expect(result.user.id, '2');
      expect(result.user.email, 'new@example.com');
      verify(() => mockDio.post(
            '/auth/register',
            data: {
              'email': 'new@example.com',
              'password': '12345678',
            },
          )).called(1);
    });
  });

  group('forgotPassword', () {
    test('posts forgot password request', () async {
      when(() => mockDio.post(
            '/auth/forgot-password',
            data: {
              'email': 'test@example.com',
            },
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/auth/forgot-password'),
        ),
      );

      await dataSource.forgotPassword(email: 'test@example.com');

      verify(() => mockDio.post(
            '/auth/forgot-password',
            data: {
              'email': 'test@example.com',
            },
          )).called(1);
    });
  });

  group('resetPassword', () {
    test('posts reset password request', () async {
      when(() => mockDio.post(
            '/auth/reset-password',
            data: {
              'email': 'test@example.com',
              'code': '123456',
              'new_password': 'newpass123',
            },
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/auth/reset-password'),
        ),
      );

      await dataSource.resetPassword(
        email: 'test@example.com',
        code: '123456',
        newPassword: 'newpass123',
      );

      verify(() => mockDio.post(
            '/auth/reset-password',
            data: {
              'email': 'test@example.com',
              'code': '123456',
              'new_password': 'newpass123',
            },
          )).called(1);
    });
  });

  group('sendEmailVerification', () {
    test('posts send verification email request', () async {
      when(() => mockDio.post(
            '/auth/send-verification-email',
            data: {
              'email': 'test@example.com',
            },
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/auth/send-verification-email',
          ),
        ),
      );

      await dataSource.sendEmailVerification(email: 'test@example.com');

      verify(() => mockDio.post(
            '/auth/send-verification-email',
            data: {
              'email': 'test@example.com',
            },
          )).called(1);
    });
  });

  group('verifyEmail', () {
    test('posts verify email request', () async {
      when(() => mockDio.post(
            '/auth/verify-email',
            data: {
              'email': 'test@example.com',
              'code': '123456',
            },
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/auth/verify-email'),
        ),
      );

      await dataSource.verifyEmail(
        email: 'test@example.com',
        code: '123456',
      );

      verify(() => mockDio.post(
            '/auth/verify-email',
            data: {
              'email': 'test@example.com',
              'code': '123456',
            },
          )).called(1);
    });
  });

  group('completeProfile', () {
    test('posts complete profile request with auth header', () async {
      when(() => mockDio.post(
            '/auth/complete-profile',
            data: {
              'display_name': 'Muslim',
              'birth_month': 5,
              'birth_day': 15,
              'birth_year': 2000,
              'gender': 'Male',
            },
            options: any(named: 'options'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/auth/complete-profile'),
          data: {
            'id': '1',
            'email': 'test@example.com',
            'username': 'muslim',
            'display_name': 'Muslim',
            'avatar_url': null,
            'bio': null,
            'gender': 'Male',
            'date_of_birth': '2000-05-15T00:00:00.000',
            'is_pro': false,
            'is_profile_completed': true,
          },
        ),
      );

      final result = await dataSource.completeProfile(
        token: 'token_123',
        displayName: 'Muslim',
        birthMonth: 5,
        birthDay: 15,
        birthYear: 2000,
        gender: 'Male',
      );

      expect(result, isA<UserDto>());
      expect(result.id, '1');
      expect(result.email, 'test@example.com');

      final captured = verify(() => mockDio.post(
            '/auth/complete-profile',
            data: {
              'display_name': 'Muslim',
              'birth_month': 5,
              'birth_day': 15,
              'birth_year': 2000,
              'gender': 'Male',
            },
            options: captureAny(named: 'options'),
          )).captured;

      final options = captured.single as Options;
      expect(options.headers?['Authorization'], 'Bearer token_123');
    });
  });

  group('getCurrentUser', () {
    test('gets current user with auth header', () async {
      when(() => mockDio.get(
            '/auth/me',
            options: any(named: 'options'),
          )).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/auth/me'),
          data: {
            'id': '1',
            'email': 'test@example.com',
            'username': 'muslim',
            'display_name': 'Muslim',
            'avatar_url': 'https://example.com/avatar.png',
            'bio': 'Hello world',
            'gender': 'Male',
            'date_of_birth': '2000-05-15T00:00:00.000',
            'is_pro': true,
            'is_profile_completed': true,
          },
        ),
      );

      final result = await dataSource.getCurrentUser(
        token: 'token_123',
      );

      expect(result, isA<UserDto>());
      expect(result.id, '1');
      expect(result.email, 'test@example.com');

      final captured = verify(() => mockDio.get(
            '/auth/me',
            options: captureAny(named: 'options'),
          )).captured;

      final options = captured.single as Options;
      expect(options.headers?['Authorization'], 'Bearer token_123');
    });
  });
}
