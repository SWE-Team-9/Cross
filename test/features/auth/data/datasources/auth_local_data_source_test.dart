import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:soundcloud_clone/core/storage/secure_storage.dart';

// بنعمل Mock للكلاس الوسيط اللي الـ DataSource بتستخدمه فعلياً
class MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  late MockSecureStorage mockSecureStorage;
  late AuthLocalDataSourceImpl dataSource;

  setUp(() {
    mockSecureStorage = MockSecureStorage();
    dataSource = AuthLocalDataSourceImpl(mockSecureStorage);
  });

  group('AuthLocalDataSource - Tokens Management', () {
    const tAccessToken = 'access_123';
    const tRefreshToken = 'refresh_456';

    test('saveTokens should call write on secureStorage for both tokens',
        () async {
      // Arrange
      when(() => mockSecureStorage.write(SecureStorage.accessTokenKey, any()))
          .thenAnswer((_) async => {});
      when(() => mockSecureStorage.write(SecureStorage.refreshTokenKey, any()))
          .thenAnswer((_) async => {});

      // Act
      await dataSource.saveTokens(access: tAccessToken, refresh: tRefreshToken);

      // Assert
      verify(() => mockSecureStorage.write(
          SecureStorage.accessTokenKey, tAccessToken)).called(1);
      verify(() => mockSecureStorage.write(
          SecureStorage.refreshTokenKey, tRefreshToken)).called(1);
    });

    test('getAccessToken should return token from secureStorage', () async {
      // Arrange
      when(() => mockSecureStorage.read(SecureStorage.accessTokenKey))
          .thenAnswer((_) async => tAccessToken);

      // Act
      final result = await dataSource.getAccessToken();

      // Assert
      expect(result, tAccessToken);
      verify(() => mockSecureStorage.read(SecureStorage.accessTokenKey))
          .called(1);
    });

    test('getRefreshToken should return token from secureStorage', () async {
      // Arrange
      when(() => mockSecureStorage.read(SecureStorage.refreshTokenKey))
          .thenAnswer((_) async => tRefreshToken);

      // Act
      final result = await dataSource.getRefreshToken();

      // Assert
      expect(result, tRefreshToken);
      verify(() => mockSecureStorage.read(SecureStorage.refreshTokenKey))
          .called(1);
    });
  });

  group('clearAll', () {
    test('should call clearAuthData on secureStorage', () async {
      // Arrange
      when(() => mockSecureStorage.clearAuthData()).thenAnswer((_) async => {});

      // Act
      await dataSource.clearAll();

      // Assert
      verify(() => mockSecureStorage.clearAuthData()).called(1);
    });
  });
}
