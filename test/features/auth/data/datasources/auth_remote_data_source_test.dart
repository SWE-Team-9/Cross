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

  group('login', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';
    const tCaptcha = 'captcha_token';

    test('should return AuthResponseDto and leave tokens empty for cookie auth',
        () async {
      // Arrange
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/auth/login'),
          data: {
            'user': {
              'id': '1',
              'email': tEmail,
              'handle': 'muslim',
              'display_name': 'Test User',
              'gender': 'MALE',
              'date_of_birth': '2000-01-01',
            }
          },
          headers: Headers.fromMap({
            'set-cookie': [
              'access_token=access_123; Path=/; HttpOnly',
              'refresh_token=refresh_456; Path=/; HttpOnly',
            ],
          }),
        ),
      );

      // Act
      final result = await dataSource.login(
        email: tEmail,
        password: tPassword,
        captchaToken: tCaptcha,
        rememberMe: true,
      );

      // Assert
      expect(result, isA<AuthResponseDto>());
      expect(result.accessToken, '');
      expect(result.refreshToken, '');
      expect(result.user, isA<UserDto>());
      expect(result.user.id, '1');
      expect(result.user.email, tEmail);
      expect(result.user.handle, 'muslim');
      expect(result.user.displayName, 'Test User');

      verify(() => mockDio.post(
            '/api/v1/auth/login',
            data: {
              'email': tEmail,
              'password': tPassword,
              'remember_me': true,
              'captcha_token': tCaptcha,
            },
          )).called(1);
    });
  });

  group('register', () {
    test('should return AuthResponseDto after successful registration',
        () async {
      // Arrange
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/auth/register'),
          data: {
            'user': {
              'id': '1',
              'email': 'new@example.com',
              'handle': 'new_user',
              'display_name': 'New User',
              'gender': 'FEMALE',
              'date_of_birth': '1995-01-01',
            }
          },
          headers: Headers.fromMap({
            'set-cookie': [
              'access_token=reg_access; Path=/',
              'refresh_token=reg_refresh; Path=/',
            ],
          }),
        ),
      );

      // Act
      final result = await dataSource.register(
        email: 'new@example.com',
        password: 'password',
        passwordConfirm: 'password',
        displayName: 'New User',
        dateOfBirth: '1995-01-01',
        gender: 'FEMALE',
        captchaToken: 'token',
      );

      // Assert
      expect(result, isA<AuthResponseDto>());
      expect(result.accessToken, '');
      expect(result.refreshToken, '');
      expect(result.user.id, '1');
      expect(result.user.email, 'new@example.com');
      expect(result.user.handle, 'new_user');
      expect(result.user.displayName, 'New User');
      expect(result.user.gender, 'FEMALE');

      verify(() => mockDio.post(
            '/api/v1/auth/register',
            data: {
              'email': 'new@example.com',
              'password': 'password',
              'password_confirm': 'password',
              'display_name': 'New User',
              'date_of_birth': '1995-01-01',
              'gender': 'FEMALE',
              'captcha_token': 'token',
            },
          )).called(1);
    });

    test('should parse register response when data is a JSON string', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/auth/register'),
          data:
              '{"user":{"id":"2","email":"json@example.com","handle":"json_user","display_name":"Json User","gender":"MALE","date_of_birth":"1999-02-02"}}',
        ),
      );

      final result = await dataSource.register(
        email: 'json@example.com',
        password: 'password',
        passwordConfirm: 'password',
        displayName: 'Json User',
        dateOfBirth: '1999-02-02',
        gender: 'MALE',
        captchaToken: 'token',
      );

      expect(result.user.id, '2');
      expect(result.user.email, 'json@example.com');
    });
  });

  group('forgotPassword', () {
    test('should call forgot password endpoint with email', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: '')),
      );

      await dataSource.forgotPassword(email: 'forgot@example.com');

      verify(() => mockDio.post(
            '/api/v1/auth/forgot-password',
            data: {'email': 'forgot@example.com'},
          )).called(1);
    });
  });

  group('resetPassword', () {
    test('should call reset password endpoint with expected payload', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: '')),
      );

      await dataSource.resetPassword(
        code: 'reset-token',
        newPassword: 'NewPassword123!',
        newPasswordConfirm: 'NewPassword123!',
      );

      verify(() => mockDio.post(
            '/api/v1/auth/reset-password',
            data: {
              'token': 'reset-token',
              'new_password': 'NewPassword123!',
              'new_password_confirm': 'NewPassword123!',
            },
          )).called(1);
    });
  });

  group('sendEmailVerification', () {
    test('should call correct endpoint for resending verification', () async {
      // Arrange
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: '')),
      );

      // Act
      await dataSource.sendEmailVerification(email: 'test@example.com');

      // Assert
      verify(() => mockDio.post(
            '/api/v1/auth/resend-verification',
            data: {'email': 'test@example.com'},
          )).called(1);
    });
  });

  group('getCurrentUser', () {
    test('should return UserDto from /me endpoint', () async {
      // Arrange
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {
            'user': {
              'id': '1',
              'email': 'me@example.com',
              'handle': 'muslim',
              'display_name': 'Me',
              'gender': 'MALE',
              'date_of_birth': '1990-01-01',
            }
          },
        ),
      );

      // Act
      final result = await dataSource.getCurrentUser();

      // Assert
      expect(result.email, 'me@example.com');
      expect(result.handle, 'muslim');
      verify(() => mockDio.get('/api/v1/auth/me')).called(1);
    });

    test('should parse getCurrentUser when data is a JSON string', () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data:
              '{"user":{"id":"2","email":"json-me@example.com","handle":"json_me","display_name":"Json Me","gender":"FEMALE","date_of_birth":"1991-01-01"}}',
        ),
      );

      final result = await dataSource.getCurrentUser();

      expect(result.id, '2');
      expect(result.email, 'json-me@example.com');
      expect(result.handle, 'json_me');
    });

    test('should parse direct user payload when user wrapper is absent',
        () async {
      when(() => mockDio.get(any())).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {
            'id': '3',
            'email': 'direct@example.com',
            'handle': 'direct_user',
            'display_name': 'Direct User',
            'gender': 'MALE',
            'date_of_birth': '1988-03-03',
          },
        ),
      );

      final result = await dataSource.getCurrentUser();

      expect(result.id, '3');
      expect(result.email, 'direct@example.com');
      expect(result.displayName, 'Direct User');
    });
  });

  group('verifyEmail', () {
    test('should call verify endpoint with token query parameter', () async {
      when(() => mockDio.get(any(),
          queryParameters: any(named: 'queryParameters'))).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: '')),
      );

      await dataSource.verifyEmail(code: 'verify-token');

      verify(() => mockDio.get(
            '/api/v1/auth/verify-email',
            queryParameters: {'token': 'verify-token'},
          )).called(1);
    });
  });

  group('requestEmailChange', () {
    test('should call email change endpoint with required fields', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: '')),
      );

      await dataSource.requestEmailChange(
        newEmail: 'new@example.com',
        currentPassword: 'Current123!',
      );

      verify(() => mockDio.post(
            '/api/v1/auth/email/change',
            data: {
              'new_email': 'new@example.com',
              'current_password': 'Current123!',
            },
          )).called(1);
    });
  });

  group('confirmEmailChange', () {
    test('should call confirm email change endpoint with token', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: '')),
      );

      await dataSource.confirmEmailChange(token: 'confirm-token');

      verify(() => mockDio.post(
            '/api/v1/auth/email/confirm-change',
            data: {'token': 'confirm-token'},
          )).called(1);
    });
  });

  group('logout', () {
    test('should call logout endpoint', () async {
      // Arrange
      when(() => mockDio.post(any())).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: '')),
      );

      // Act
      await dataSource.logout();

      // Assert
      verify(() => mockDio.post('/api/v1/auth/logout')).called(1);
    });
  });
}
