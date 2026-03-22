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

    test('should return user when login is successful', () async {
      when(() => mockRemoteDataSource.login(
            email: tEmail,
            password: tPassword,
            captchaToken: tCaptcha,
          )).thenAnswer((_) async => mockAuthResponseDto);

      when(() => mockAuthResponseDto.user).thenReturn(mockUserDto);
      when(() => mockUserDto.toEntity()).thenReturn(testUser);

      final result = await repository.login(
        email: tEmail,
        password: tPassword,
        captchaToken: tCaptcha,
      );

      expect(result, same(testUser));
      verifyNever(() => mockLocalDataSource.saveTokens(
            access: any(named: 'access'),
            refresh: any(named: 'refresh'),
          ));
      verify(() => mockUserDto.toEntity()).called(1);
    });
  });

  group('register', () {
    test('should return user when registration is successful', () async {
      when(() => mockRemoteDataSource.register(
            email: any(named: 'email'),
            password: any(named: 'password'),
            passwordConfirm: any(named: 'passwordConfirm'),
            displayName: any(named: 'displayName'),
            dateOfBirth: any(named: 'dateOfBirth'),
            gender: any(named: 'gender'),
            captchaToken: any(named: 'captchaToken'),
          )).thenAnswer((_) async => mockAuthResponseDto);

      when(() => mockAuthResponseDto.user).thenReturn(mockUserDto);
      when(() => mockUserDto.toEntity()).thenReturn(testUser);

      final result = await repository.register(
        email: 'a@b.com',
        password: '123',
        passwordConfirm: '123',
        displayName: 'Name',
        dateOfBirth: '2000-01-01',
        gender: 'MALE',
        captchaToken: 'cap',
      );

      expect(result, same(testUser));
      verifyNever(() => mockLocalDataSource.saveTokens(
            access: any(named: 'access'),
            refresh: any(named: 'refresh'),
          ));
      verify(() => mockUserDto.toEntity()).called(1);
    });
  });

  group('getCurrentUser', () {
    test('should return user entity when remote data source succeeds',
        () async {
      when(() => mockRemoteDataSource.getCurrentUser())
          .thenAnswer((_) async => mockUserDto);
      when(() => mockUserDto.toEntity()).thenReturn(testUser);

      final result = await repository.getCurrentUser();

      expect(result, same(testUser));
      verify(() => mockRemoteDataSource.getCurrentUser()).called(1);
    });

    test('should return null when remote data source fails', () async {
      when(() => mockRemoteDataSource.getCurrentUser()).thenThrow(Exception());

      final result = await repository.getCurrentUser();

      expect(result, isNull);
    });
  });

  group('logout', () {
    test('should call remote logout and clear local storage', () async {
      when(() => mockRemoteDataSource.logout()).thenAnswer((_) async {});
      when(() => mockLocalDataSource.clearAll()).thenAnswer((_) async {});

      await repository.logout();

      verify(() => mockRemoteDataSource.logout()).called(1);
      verify(() => mockLocalDataSource.clearAll()).called(1);
    });
  });

  group('isLoggedIn', () {
    test('should return true when getCurrentUser succeeds', () async {
      when(() => mockRemoteDataSource.getCurrentUser())
          .thenAnswer((_) async => mockUserDto);

      final result = await repository.isLoggedIn();

      expect(result, true);
      verify(() => mockRemoteDataSource.getCurrentUser()).called(1);
      verifyNever(() => mockLocalDataSource.getAccessToken());
    });

    test('should return false when getCurrentUser throws', () async {
      when(() => mockRemoteDataSource.getCurrentUser()).thenThrow(Exception());

      final result = await repository.isLoggedIn();

      expect(result, false);
      verify(() => mockRemoteDataSource.getCurrentUser()).called(1);
      verifyNever(() => mockLocalDataSource.getAccessToken());
    });
  });
}
