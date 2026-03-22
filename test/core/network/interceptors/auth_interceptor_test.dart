import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/network/interceptors/auth_interceptor.dart';
import 'package:soundcloud_clone/core/storage/secure_storage.dart';

class MockSecureStorage extends Mock implements SecureStorage {}

class FakeDioException extends Fake implements DioException {
  @override
  RequestOptions get requestOptions => RequestOptions(path: '');
}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

void main() {
  late AuthInterceptor authInterceptor;
  late MockSecureStorage mockSecureStorage;

  setUpAll(() {
    registerFallbackValue(FakeDioException());
  });

  setUp(() {
    mockSecureStorage = MockSecureStorage();
    authInterceptor = AuthInterceptor(secureStorage: mockSecureStorage);

    when(() => mockSecureStorage.read(any())).thenAnswer((_) async => null);
  });

  group('onRequest', () {
    test('should add token to request headers when available', () async {
      const token = 'test-token-123';
      final options = RequestOptions(path: '/protected');
      final handler = RequestInterceptorHandler();

      when(() => mockSecureStorage.read('auth_token'))
          .thenAnswer((_) async => token);

      await authInterceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], 'Bearer $token');
      verify(() => mockSecureStorage.read('auth_token')).called(1);
    });

    test('should NOT add token for auth endpoints', () async {
      final options = RequestOptions(path: '/auth/login');
      final handler = RequestInterceptorHandler();

      await authInterceptor.onRequest(options, handler);

      expect(options.headers.containsKey('Authorization'), false);
      verifyNever(() => mockSecureStorage.read(any()));
    });

    test('should NOT add token when no token exists', () async {
      final options = RequestOptions(path: '/protected');
      final handler = RequestInterceptorHandler();

      when(() => mockSecureStorage.read('auth_token'))
          .thenAnswer((_) async => null);

      await authInterceptor.onRequest(options, handler);

      expect(options.headers.containsKey('Authorization'), false);
      verify(() => mockSecureStorage.read('auth_token')).called(1);
    });
  });

  group('onError', () {
    test('should handle 401 error', () async {
      final error = DioException(
        requestOptions: RequestOptions(path: '/protected'),
        response: Response(
          requestOptions: RequestOptions(path: '/protected'),
          statusCode: 401,
        ),
      );
      final handler = MockErrorInterceptorHandler();

      when(() => handler.next(any())).thenReturn(null);

      authInterceptor.onError(error, handler);

      verify(() => handler.next(error)).called(1);
    });

    test('should pass through non-401 errors', () async {
      final error = DioException(
        requestOptions: RequestOptions(path: '/protected'),
        response: Response(
          requestOptions: RequestOptions(path: '/protected'),
          statusCode: 500,
        ),
      );
      final handler = MockErrorInterceptorHandler();

      when(() => handler.next(any())).thenReturn(null);

      authInterceptor.onError(error, handler);

      verify(() => handler.next(error)).called(1);
    });
  });
}
