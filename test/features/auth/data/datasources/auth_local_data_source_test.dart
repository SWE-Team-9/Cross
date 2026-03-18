import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/data/datasources/auth_local_data_source.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage secureStorage;
  late AuthLocalDataSourceImpl dataSource;

  setUp(() {
    secureStorage = MockFlutterSecureStorage();
    dataSource = AuthLocalDataSourceImpl(secureStorage);
  });

  group('saveToken', () {
    test('writes token to secure storage', () async {
      when(() => secureStorage.write(
            key: 'auth_token',
            value: 'token_123',
          )).thenAnswer((_) async {});

      await dataSource.saveToken('token_123');

      verify(() => secureStorage.write(
            key: 'auth_token',
            value: 'token_123',
          )).called(1);
      verifyNoMoreInteractions(secureStorage);
    });
  });

  group('getToken', () {
    test('reads token from secure storage', () async {
      when(() => secureStorage.read(key: 'auth_token'))
          .thenAnswer((_) async => 'token_123');

      final result = await dataSource.getToken();

      expect(result, 'token_123');
      verify(() => secureStorage.read(key: 'auth_token')).called(1);
      verifyNoMoreInteractions(secureStorage);
    });

    test('returns null when no token exists', () async {
      when(() => secureStorage.read(key: 'auth_token'))
          .thenAnswer((_) async => null);

      final result = await dataSource.getToken();

      expect(result, isNull);
      verify(() => secureStorage.read(key: 'auth_token')).called(1);
      verifyNoMoreInteractions(secureStorage);
    });
  });

  group('clearToken', () {
    test('deletes token from secure storage', () async {
      when(() => secureStorage.delete(key: 'auth_token'))
          .thenAnswer((_) async {});

      await dataSource.clearToken();

      verify(() => secureStorage.delete(key: 'auth_token')).called(1);
      verifyNoMoreInteractions(secureStorage);
    });
  });
}
