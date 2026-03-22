import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:soundcloud_clone/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:soundcloud_clone/features/auth/data/dto/auth_response_dto.dart';
import 'package:soundcloud_clone/features/auth/data/dto/user_dto.dart';
import 'package:soundcloud_clone/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class MockAuthResponseDto extends Mock implements AuthResponseDto {}

class MockUserDto extends Mock implements UserDto {}

class FakeUser extends Fake implements User {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;
  late MockAuthResponseDto mockAuthResponseDto;
  late MockUserDto mockUserDto;
  late User testUser;

  setUpAll(() {
    registerFallbackValue(FakeUser());
  });

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    mockAuthResponseDto = MockAuthResponseDto();
    mockUserDto = MockUserDto();
    testUser = FakeUser();

    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
  });

  group('login', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';
    const tCaptcha = 'captcha_token';
    const tAccess = 'access_123';
    const tRefresh = 'refresh_456';

    test('should save tokens and return user when login is successful',
        () async {
      // Arrange
      when(() => mockRemoteDataSource.login(
            email: tEmail,
            password: tPassword,
            captchaToken: tCaptcha,
          )).thenAnswer((_) async => mockAuthResponseDto);

      when(() => mockAuthResponseDto.accessToken).thenReturn(tAccess);
      when(() => mockAuthResponseDto.refreshToken).thenReturn(tRefresh);
      when(() => mockAuthResponseDto.user).thenReturn(mockUserDto);
      when(() => mockUserDto.toEntity()).thenReturn(testUser);
      when(() => mockLocalDataSource.saveTokens(
          access: any(named: 'access'),
          refresh: any(named: 'refresh'))).thenAnswer((_) async => {});

      // Act
      final result = await repository.login(
        email: tEmail,
        password: tPassword,
        captchaToken: tCaptcha,
      );

      // Assert
      expect(result, same(testUser));
      verify(() => mockLocalDataSource.saveTokens(
          access: tAccess, refresh: tRefresh)).called(1);
      verify(() => mockUserDto.toEntity()).called(1);
    });
  });

  group('register', () {
    test('should save tokens and return user when registration is successful',
        () async {
      // Arrange
      when(() => mockRemoteDataSource.register(
            email: any(named: 'email'),
            password: any(named: 'password'),
            passwordConfirm: any(named: 'passwordConfirm'),
            displayName: any(named: 'displayName'),
            dateOfBirth: any(named: 'dateOfBirth'),
            gender: any(named: 'gender'),
            captchaToken: any(named: 'captchaToken'),
          )).thenAnswer((_) async => mockAuthResponseDto);

      when(() => mockAuthResponseDto.accessToken).thenReturn('acc');
      when(() => mockAuthResponseDto.refreshToken).thenReturn('ref');
      when(() => mockAuthResponseDto.user).thenReturn(mockUserDto);
      when(() => mockUserDto.toEntity()).thenReturn(testUser);
      when(() => mockLocalDataSource.saveTokens(access: 'acc', refresh: 'ref'))
          .thenAnswer((_) async => {});

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
      verify(() =>
              mockLocalDataSource.saveTokens(access: 'acc', refresh: 'ref'))
          .called(1);
    });
  });

  group('getCurrentUser', () {
    test('should return user entity when remote data source succeeds',
        () async {
      // Arrange
      when(() => mockRemoteDataSource.getCurrentUser())
          .thenAnswer((_) async => mockUserDto);
      when(() => mockUserDto.toEntity()).thenReturn(testUser);

      // Act
      final result = await repository.getCurrentUser();

      // Assert
      expect(result, same(testUser));
      verify(() => mockRemoteDataSource.getCurrentUser()).called(1);
    });

    test('should return null when remote data source fails', () async {
      // Arrange
      when(() => mockRemoteDataSource.getCurrentUser()).thenThrow(Exception());

      // Act
      final result = await repository.getCurrentUser();

      // Assert
      expect(result, isNull);
    });
  });

  group('logout', () {
    test('should call remote logout and clear local storage', () async {
      // Arrange
      when(() => mockRemoteDataSource.logout()).thenAnswer((_) async => {});
      when(() => mockLocalDataSource.clearAll()).thenAnswer((_) async => {});

      // Act
      await repository.logout();

      // Assert
      verify(() => mockRemoteDataSource.logout()).called(1);
      verify(() => mockLocalDataSource.clearAll()).called(1);
    });
  });

  group('isLoggedIn', () {
    test('should return true when access token exists', () async {
      // Arrange
      when(() => mockLocalDataSource.getAccessToken())
          .thenAnswer((_) async => 'valid_token');

      // Act
      final result = await repository.isLoggedIn();

      // Assert
      expect(result, true);
    });

    test('should return false when access token is null', () async {
      // Arrange
      when(() => mockLocalDataSource.getAccessToken())
          .thenAnswer((_) async => null);

      // Act
      final result = await repository.isLoggedIn();

      // Assert
      expect(result, false);
    });
  });
}
