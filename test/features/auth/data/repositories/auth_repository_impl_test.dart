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

  group('checkEmailExists', () {
    const email = 'test@example.com';

    test('returns result from remote data source', () async {
      when(() => mockRemoteDataSource.checkEmailExists(email: email))
          .thenAnswer((_) async => true);

      final result = await repository.checkEmailExists(email: email);

      expect(result, true);
      verify(() => mockRemoteDataSource.checkEmailExists(email: email))
          .called(1);
      verifyNoMoreInteractions(mockRemoteDataSource);
    });
  });

  group('login', () {
    const email = 'test@example.com';
    const password = 'password123';
    const token = 'token_123';

    test('saves token and returns mapped user when login succeeds', () async {
      when(() => mockRemoteDataSource.login(
            email: email,
            password: password,
          )).thenAnswer((_) async => mockAuthResponseDto);
      when(() => mockAuthResponseDto.token).thenReturn(token);
      when(() => mockAuthResponseDto.user).thenReturn(mockUserDto);
      when(() => mockUserDto.toEntity()).thenReturn(testUser);
      when(() => mockLocalDataSource.saveToken(token)).thenAnswer((_) async {});

      final result = await repository.login(
        email: email,
        password: password,
      );

      expect(result, same(testUser));
      verify(() => mockRemoteDataSource.login(
            email: email,
            password: password,
          )).called(1);
      verify(() => mockLocalDataSource.saveToken(token)).called(1);
      verify(() => mockUserDto.toEntity()).called(1);
    });

    test('throws when remote login throws', () async {
      when(() => mockRemoteDataSource.login(
            email: email,
            password: password,
          )).thenThrow(Exception('login failed'));

      expect(
        () => repository.login(email: email, password: password),
        throwsA(isA<Exception>()),
      );

      verify(() => mockRemoteDataSource.login(
            email: email,
            password: password,
          )).called(1);
      verifyNever(() => mockLocalDataSource.saveToken(any()));
    });
  });

  group('register', () {
    const email = 'new@example.com';
    const password = 'password123';
    const token = 'register_token';

    test('saves token and returns mapped user when register succeeds',
        () async {
      when(() => mockRemoteDataSource.register(
            email: email,
            password: password,
          )).thenAnswer((_) async => mockAuthResponseDto);
      when(() => mockAuthResponseDto.token).thenReturn(token);
      when(() => mockAuthResponseDto.user).thenReturn(mockUserDto);
      when(() => mockUserDto.toEntity()).thenReturn(testUser);
      when(() => mockLocalDataSource.saveToken(token)).thenAnswer((_) async {});

      final result = await repository.register(
        email: email,
        password: password,
      );

      expect(result, same(testUser));
      verify(() => mockRemoteDataSource.register(
            email: email,
            password: password,
          )).called(1);
      verify(() => mockLocalDataSource.saveToken(token)).called(1);
      verify(() => mockUserDto.toEntity()).called(1);
    });

    test('throws when remote register throws', () async {
      when(() => mockRemoteDataSource.register(
            email: email,
            password: password,
          )).thenThrow(Exception('register failed'));

      expect(
        () => repository.register(email: email, password: password),
        throwsA(isA<Exception>()),
      );

      verify(() => mockRemoteDataSource.register(
            email: email,
            password: password,
          )).called(1);
      verifyNever(() => mockLocalDataSource.saveToken(any()));
    });
  });

  group('forgotPassword', () {
    const email = 'forgot@example.com';

    test('delegates to remote data source', () async {
      when(() => mockRemoteDataSource.forgotPassword(email: email))
          .thenAnswer((_) async {});

      await repository.forgotPassword(email: email);

      verify(() => mockRemoteDataSource.forgotPassword(email: email)).called(1);
    });
  });

  group('resetPassword', () {
    const email = 'reset@example.com';
    const code = '123456';
    const newPassword = 'newPassword123';

    test('delegates to remote data source', () async {
      when(() => mockRemoteDataSource.resetPassword(
            email: email,
            code: code,
            newPassword: newPassword,
          )).thenAnswer((_) async {});

      await repository.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );

      verify(() => mockRemoteDataSource.resetPassword(
            email: email,
            code: code,
            newPassword: newPassword,
          )).called(1);
    });
  });

  group('sendEmailVerification', () {
    const email = 'verify@example.com';

    test('delegates to remote data source', () async {
      when(() => mockRemoteDataSource.sendEmailVerification(email: email))
          .thenAnswer((_) async {});

      await repository.sendEmailVerification(email: email);

      verify(() => mockRemoteDataSource.sendEmailVerification(email: email))
          .called(1);
    });
  });

  group('verifyEmail', () {
    const email = 'verify@example.com';
    const code = '999999';

    test('delegates to remote data source', () async {
      when(() => mockRemoteDataSource.verifyEmail(
            email: email,
            code: code,
          )).thenAnswer((_) async {});

      await repository.verifyEmail(email: email, code: code);

      verify(() => mockRemoteDataSource.verifyEmail(
            email: email,
            code: code,
          )).called(1);
    });
  });

  group('completeProfile', () {
    const token = 'auth_token';
    const displayName = 'Muslim';
    const birthMonth = 5;
    const birthDay = 15;
    const birthYear = 2000;
    const gender = 'male';

    test('throws when token is null', () async {
      when(() => mockLocalDataSource.getToken()).thenAnswer((_) async => null);

      expect(
        () => repository.completeProfile(
          displayName: displayName,
          birthMonth: birthMonth,
          birthDay: birthDay,
          birthYear: birthYear,
          gender: gender,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('No auth token found'),
          ),
        ),
      );

      verify(() => mockLocalDataSource.getToken()).called(1);
      verifyNever(() => mockRemoteDataSource.completeProfile(
            token: any(named: 'token'),
            displayName: any(named: 'displayName'),
            birthMonth: any(named: 'birthMonth'),
            birthDay: any(named: 'birthDay'),
            birthYear: any(named: 'birthYear'),
            gender: any(named: 'gender'),
          ));
    });

    test('throws when token is empty', () async {
      when(() => mockLocalDataSource.getToken()).thenAnswer((_) async => '');

      expect(
        () => repository.completeProfile(
          displayName: displayName,
          birthMonth: birthMonth,
          birthDay: birthDay,
          birthYear: birthYear,
          gender: gender,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('No auth token found'),
          ),
        ),
      );

      verify(() => mockLocalDataSource.getToken()).called(1);
    });

    test('returns mapped user when token exists', () async {
      when(() => mockLocalDataSource.getToken()).thenAnswer((_) async => token);
      when(() => mockRemoteDataSource.completeProfile(
            token: token,
            displayName: displayName,
            birthMonth: birthMonth,
            birthDay: birthDay,
            birthYear: birthYear,
            gender: gender,
          )).thenAnswer((_) async => mockUserDto);
      when(() => mockUserDto.toEntity()).thenReturn(testUser);

      final result = await repository.completeProfile(
        displayName: displayName,
        birthMonth: birthMonth,
        birthDay: birthDay,
        birthYear: birthYear,
        gender: gender,
      );

      expect(result, same(testUser));
      verify(() => mockLocalDataSource.getToken()).called(1);
      verify(() => mockRemoteDataSource.completeProfile(
            token: token,
            displayName: displayName,
            birthMonth: birthMonth,
            birthDay: birthDay,
            birthYear: birthYear,
            gender: gender,
          )).called(1);
      verify(() => mockUserDto.toEntity()).called(1);
    });
  });

  group('getCurrentUser', () {
    const token = 'auth_token';

    test('returns null when token is null', () async {
      when(() => mockLocalDataSource.getToken()).thenAnswer((_) async => null);

      final result = await repository.getCurrentUser();

      expect(result, isNull);
      verify(() => mockLocalDataSource.getToken()).called(1);
      verifyNever(() => mockRemoteDataSource.getCurrentUser(
            token: any(named: 'token'),
          ));
    });

    test('returns null when token is empty', () async {
      when(() => mockLocalDataSource.getToken()).thenAnswer((_) async => '');

      final result = await repository.getCurrentUser();

      expect(result, isNull);
      verify(() => mockLocalDataSource.getToken()).called(1);
      verifyNever(() => mockRemoteDataSource.getCurrentUser(
            token: any(named: 'token'),
          ));
    });

    test('returns mapped user when token exists', () async {
      when(() => mockLocalDataSource.getToken()).thenAnswer((_) async => token);
      when(() => mockRemoteDataSource.getCurrentUser(token: token))
          .thenAnswer((_) async => mockUserDto);
      when(() => mockUserDto.toEntity()).thenReturn(testUser);

      final result = await repository.getCurrentUser();

      expect(result, same(testUser));
      verify(() => mockLocalDataSource.getToken()).called(1);
      verify(() => mockRemoteDataSource.getCurrentUser(token: token)).called(1);
      verify(() => mockUserDto.toEntity()).called(1);
    });
  });

  group('logout', () {
    test('clears token from local data source', () async {
      when(() => mockLocalDataSource.clearToken()).thenAnswer((_) async {});

      await repository.logout();

      verify(() => mockLocalDataSource.clearToken()).called(1);
    });
  });

  group('isLoggedIn', () {
    test('returns false when token is null', () async {
      when(() => mockLocalDataSource.getToken()).thenAnswer((_) async => null);

      final result = await repository.isLoggedIn();

      expect(result, false);
      verify(() => mockLocalDataSource.getToken()).called(1);
    });

    test('returns false when token is empty', () async {
      when(() => mockLocalDataSource.getToken()).thenAnswer((_) async => '');

      final result = await repository.isLoggedIn();

      expect(result, false);
      verify(() => mockLocalDataSource.getToken()).called(1);
    });

    test('returns true when token exists and is not empty', () async {
      when(() => mockLocalDataSource.getToken())
          .thenAnswer((_) async => 'valid_token');

      final result = await repository.isLoggedIn();

      expect(result, true);
      verify(() => mockLocalDataSource.getToken()).called(1);
    });
  });
}
