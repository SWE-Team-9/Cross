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

      final result = await dataSource.login(
        email: tEmail,
        password: tPassword,
        captchaToken: tCaptcha,
      );

      expect(result, isA<AuthResponseDto>());
      expect(result.accessToken, '');
      expect(result.refreshToken, '');
      expect(result.user, isA<UserDto>());
      expect(result.user.id, '1');
      expect(result.user.email, tEmail);
      expect(result.user.handle, 'muslim');

      verify(() => mockDio.post(
            '/api/v1/auth/login',
            data: {
              'email': tEmail,
              'password': tPassword,
              'remember_me': true,
            },
          )).called(1);
    });
  });

  group('register', () {
    test('should return AuthResponseDto after successful registration',
        () async {
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

      final result = await dataSource.register(
        email: 'new@example.com',
        password: 'password',
        passwordConfirm: 'password',
        displayName: 'New User',
        dateOfBirth: '1995-01-01',
        gender: 'FEMALE',
        captchaToken: 'token',
      );

      expect(result.accessToken, '');
      expect(result.refreshToken, '');
      expect(result.user.displayName, 'New User');

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
  });

  group('sendEmailVerification', () {
    test('should call correct endpoint for resending verification', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'))).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: '')),
      );

      await dataSource.sendEmailVerification(email: 'test@example.com');

      verify(() => mockDio.post(
            '/api/v1/auth/resend-verification',
            data: {'email': 'test@example.com'},
          )).called(1);
    });
  });

  group('getCurrentUser', () {
    test('should return UserDto from /me endpoint', () async {
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

      final result = await dataSource.getCurrentUser();

      expect(result.email, 'me@example.com');
      expect(result.handle, 'muslim');
      verify(() => mockDio.get('/api/v1/auth/me')).called(1);
    });
  });

  group('logout', () {
    test('should call logout endpoint', () async {
      when(() => mockDio.post(any())).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: '')),
      );

      await dataSource.logout();

      verify(() => mockDio.post('/api/v1/auth/logout')).called(1);
    });
  });
}
