import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:soundcloud_clone/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:soundcloud_clone/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:soundcloud_clone/features/auth/data/dto/auth_response_dto.dart';
import 'package:soundcloud_clone/features/auth/data/dto/user_dto.dart';
import 'package:soundcloud_clone/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class MockUserDto extends Mock implements UserDto {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;
  late MockUserDto mockUserDto;
  late User testUser;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    mockUserDto = MockUserDto();
    
    testUser = User(
      id: '123',
      email: 'test@example.com',
      handle: 'test-handle',
      displayName: 'Test User',
      isVerified: false,
    );

    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
  });

  group('login', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';
    const tCaptcha = 'captcha_token';

    test('should return user when login is successful (no token saving)', () async {
      // Arrange
      final authResponse = AuthResponseDto(
        accessToken: '',
        refreshToken: '',
        user: mockUserDto,
      );
      
      when(() => mockRemoteDataSource.login(
            email: tEmail,
            password: tPassword,
            captchaToken: tCaptcha,
          )).thenAnswer((_) async => authResponse);
      
      when(() => mockUserDto.toEntity()).thenReturn(testUser);

      // Act
      final result = await repository.login(
        email: tEmail,
        password: tPassword,
        captchaToken: tCaptcha,
      );

      // Assert
      expect(result, same(testUser));
      expect(result.id, '123');
      expect(result.email, 'test@example.com');
      expect(result.handle, 'test-handle');
      expect(result.displayName, 'Test User');
      
      verifyNever(() => mockLocalDataSource.saveTokens(
        access: any(named: 'access'),
        refresh: any(named: 'refresh'),
      ));
      
      verify(() => mockRemoteDataSource.login(
        email: tEmail,
        password: tPassword,
        captchaToken: tCaptcha,
      )).called(1);
    });
  });

  group('register', () {
    test('should return user when registration is successful (no token saving)', () async {
      // Arrange
      final authResponse = AuthResponseDto(
        accessToken: '',
        refreshToken: '',
        user: mockUserDto,
      );
      
      when(() => mockRemoteDataSource.register(
            email: any(named: 'email'),
            password: any(named: 'password'),
            passwordConfirm: any(named: 'passwordConfirm'),
            displayName: any(named: 'displayName'),
            dateOfBirth: any(named: 'dateOfBirth'),
            gender: any(named: 'gender'),
            captchaToken: any(named: 'captchaToken'),
          )).thenAnswer((_) async => authResponse);
      
      when(() => mockUserDto.toEntity()).thenReturn(testUser);

      // Act
      final result = await repository.register(
        email: 'a@b.com',
        password: '123',
        passwordConfirm: '123',
        displayName: 'Name',
        dateOfBirth: '2000-01-01',
        gender: 'MALE',
        captchaToken: 'cap',
      );

      // Assert
      expect(result, same(testUser));
      expect(result.id, '123');
      expect(result.email, 'test@example.com');
      expect(result.handle, 'test-handle');
      
      verifyNever(() => mockLocalDataSource.saveTokens(
        access: any(named: 'access'),
        refresh: any(named: 'refresh'),
      ));
      
      verify(() => mockRemoteDataSource.register(
        email: 'a@b.com',
        password: '123',
        passwordConfirm: '123',
        displayName: 'Name',
        dateOfBirth: '2000-01-01',
        gender: 'MALE',
        captchaToken: 'cap',
      )).called(1);
    });
  });

  group('getCurrentUser', () {
    test('should return user entity when remote data source succeeds', () async {
      // Arrange
      when(() => mockRemoteDataSource.getCurrentUser())
          .thenAnswer((_) async => mockUserDto);
      when(() => mockUserDto.toEntity()).thenReturn(testUser);

      // Act
      final result = await repository.getCurrentUser();

      // Assert
      expect(result, same(testUser));
      expect(result?.id, '123');
      expect(result?.email, 'test@example.com');
      expect(result?.handle, 'test-handle');
      verify(() => mockRemoteDataSource.getCurrentUser()).called(1);
    });

    test('should return null when remote data source fails', () async {
      // Arrange
      when(() => mockRemoteDataSource.getCurrentUser())
          .thenThrow(DioException(
            requestOptions: RequestOptions(path: '/me'),
            type: DioExceptionType.connectionTimeout,
          ));

      // Act
      final result = await repository.getCurrentUser();

      // Assert
      expect(result, isNull);
    });
  });

  group('logout', () {
    test('should call remote logout and clear local storage', () async {
      // Arrange
      when(() => mockRemoteDataSource.logout()).thenAnswer((_) async => Future.value());
      when(() => mockLocalDataSource.clearAll()).thenAnswer((_) async => Future.value());

      // Act
      await repository.logout();

      // Assert
      verify(() => mockRemoteDataSource.logout()).called(1);
      verify(() => mockLocalDataSource.clearAll()).called(1);
    });

    test('should clear local storage even if remote logout fails', () async {
      // Arrange
      // Setup mock to throw exception
      when(() => mockRemoteDataSource.logout()).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/logout'),
          type: DioExceptionType.connectionTimeout,
          message: 'Connection timeout',
        ),
      );
      
      // Setup clearAll to succeed
      when(() => mockLocalDataSource.clearAll()).thenAnswer((_) async => Future.value());

      // Act - This should NOT throw an exception
      await repository.logout();

      // Assert - Verify both were called
      verify(() => mockRemoteDataSource.logout()).called(1);
      verify(() => mockLocalDataSource.clearAll()).called(1);
    });
  });

  group('isLoggedIn', () {
    test('should return true when user is authenticated (cookie valid)', () async {
      // Arrange
      when(() => mockRemoteDataSource.getCurrentUser())
          .thenAnswer((_) async => mockUserDto);

      // Act
      final result = await repository.isLoggedIn();

      // Assert
      expect(result, true);
      verify(() => mockRemoteDataSource.getCurrentUser()).called(1);
      verifyNever(() => mockLocalDataSource.getAccessToken());
    });

    test('should return false when user is not authenticated (401 error)', () async {
      // Arrange
      when(() => mockRemoteDataSource.getCurrentUser()).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/me'),
          response: Response(
            requestOptions: RequestOptions(path: '/me'),
            statusCode: 401,
            statusMessage: 'Unauthorized',
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      // Act
      final result = await repository.isLoggedIn();

      // Assert
      expect(result, false);
      verify(() => mockRemoteDataSource.getCurrentUser()).called(1);
    });

    test('should return false when network error occurs', () async {
      // Arrange
      when(() => mockRemoteDataSource.getCurrentUser()).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/me'),
          type: DioExceptionType.connectionTimeout,
          message: 'Connection timeout',
        ),
      );

      // Act
      final result = await repository.isLoggedIn();

      // Assert
      expect(result, false);
      verify(() => mockRemoteDataSource.getCurrentUser()).called(1);
    });
  });
}