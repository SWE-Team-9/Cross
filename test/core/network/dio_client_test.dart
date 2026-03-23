import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/core/storage/secure_storage.dart';

class MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DioClient dioClient;
  late MockSecureStorage mockSecureStorage;
  late PersistCookieJar cookieJar;

  setUp(() {
    mockSecureStorage = MockSecureStorage();
    cookieJar = PersistCookieJar(
      storage: FileStorage(
        '${Directory.systemTemp.path}/cross_dio_client_test_cookies',
      ),
    );

    dioClient = DioClient(
      baseUrl: 'https://api.test.com',
      secureStorage: mockSecureStorage,
      cookieJar: cookieJar,
    );
  });

  group('DioClient Integration Tests', () {
    test('Dio instance should be initialized with interceptors', () {
      expect(dioClient.dio, isNotNull);
      expect(dioClient.dio.interceptors.length, isNot(0));
    });

    test('get request should use the correct baseUrl', () {
      expect(dioClient.dio.options.baseUrl, 'https://api.test.com');
    });
  });
}