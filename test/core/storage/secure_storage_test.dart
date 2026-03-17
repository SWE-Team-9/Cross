import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/storage/secure_storage.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecureStorage secureStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    secureStorage = SecureStorage(mockStorage);
  });

  group('SecureStorage', () {
    test('write delegates to FlutterSecureStorage.write', () async {
      when(() => mockStorage.write(key: 'token', value: 'abc'))
          .thenAnswer((_) async {});

      await secureStorage.write('token', 'abc');

      verify(() => mockStorage.write(key: 'token', value: 'abc')).called(1);
    });

    test('read delegates to FlutterSecureStorage.read', () async {
      when(() => mockStorage.read(key: 'token')).thenAnswer((_) async => 'abc');

      final result = await secureStorage.read('token');

      expect(result, 'abc');
      verify(() => mockStorage.read(key: 'token')).called(1);
    });

    test('delete delegates to FlutterSecureStorage.delete', () async {
      when(() => mockStorage.delete(key: 'token')).thenAnswer((_) async {});

      await secureStorage.delete('token');

      verify(() => mockStorage.delete(key: 'token')).called(1);
    });

    test('containsKey returns true when value exists', () async {
      when(() => mockStorage.read(key: 'token')).thenAnswer((_) async => 'abc');

      final result = await secureStorage.containsKey('token');

      expect(result, isTrue);
    });

    test('containsKey returns false when value does not exist', () async {
      when(() => mockStorage.read(key: 'token')).thenAnswer((_) async => null);

      final result = await secureStorage.containsKey('token');

      expect(result, isFalse);
    });

    test('readAll delegates to FlutterSecureStorage.readAll', () async {
      when(() => mockStorage.readAll())
          .thenAnswer((_) async => {'token': 'abc'});

      final result = await secureStorage.readAll();

      expect(result, {'token': 'abc'});
      verify(() => mockStorage.readAll()).called(1);
    });

    test('clear delegates to FlutterSecureStorage.deleteAll', () async {
      when(() => mockStorage.deleteAll()).thenAnswer((_) async {});

      await secureStorage.clear();

      verify(() => mockStorage.deleteAll()).called(1);
    });
  });
}
